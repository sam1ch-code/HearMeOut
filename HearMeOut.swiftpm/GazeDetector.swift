//  Created by Sukhrob on 25/08/26.
//

import AVFoundation
import CoreVideo
import Vision

final class GazeDetector {
    private let minFrameInterval: CFTimeInterval = 1.0 / 15.0 // 15 fps
    private var lastProcessedTime: CFTimeInterval = 0

    /// Reused across every frame on purpose
    private let sequenceHandler = VNSequenceRequestHandler()
    private let gazeSmoother = GazeSmoother()

    /// Verified against .portrait capture orientation on a front camera.
    /// Re-check this if you ever change videoOrientation on the capture
    /// connection, or support device rotation.
    private let orientation: CGImagePropertyOrientation = .right

    private let minUsableConfidence: Double = 0.15

    /// Assumed comfortable range of eye rotation within the socket, used only
    /// to convert Stage 4's unitless -1...1 offset into degrees so it can be
    /// added to head yaw/pitch. This is a rough approximation, not a measured
    /// biomechanical constant — tune it against your own logged data.
    private let assumedMaxEyeRotationDegrees: CGFloat = 30

    /// IMPORTANT: this method assumes it is always invoked back-to-back
    /// from the same serial queue AVFoundation delivers frames on. That's
    /// why `lastProcessedTime` is read and written here with no lock —
    /// AVFoundation's own guarantee that delegate calls never overlap on a
    /// given queue is what makes that safe. If this were ever called from
    /// more than one queue, that guarantee breaks and this needs a lock.
    func handle(_ pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()
        guard now - lastProcessedTime >= minFrameInterval else { return }
        lastProcessedTime = now

        process(pixelBuffer, timestamp: now)
    }
}

private extension GazeDetector {
    func process(_ pixelBuffer: CVPixelBuffer, timestamp: CFTimeInterval) {
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            self?.handleLandmarksResult(request: request, error: error, timestamp: timestamp)
        }

        do {
            // Synchronous: `handleLandmarksResult` runs before this call
            // returns, on whatever queue `process` was called from.
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)
        } catch {
            // Transient Vision failures happen occasionally (e.g. the pixel
            // buffer became invalid mid-flight). Drop the frame rather than
            // treating this as a hard failure — the next frame will retry.
        }
    }

    func handleLandmarksResult(request: VNRequest, error: Error?, timestamp: CFTimeInterval) {
        guard error == nil, let observations = request.results as? [VNFaceObservation] else {
            print("Error: \(error.debugDescription)")
            reportNoFace()
            return
        }

        /// Explicit policy: no faces -> report absence; multiple faces -> use the most prominent one.
        guard let primaryFace = observations.max(by: { lhs, rhs in
            (lhs.boundingBox.width * lhs.boundingBox.height) < (rhs.boundingBox.width * rhs.boundingBox.height)
        }) else {
            reportNoFace()
            return
        }

        guard let landmarks = primaryFace.landmarks else {
            reportNoFace()
            return
        }

        handleFace(primaryFace, landMarks: landmarks, timestamp: timestamp)
    }

    func reportNoFace() {
        gazeSmoother.reset()
    }

    private func handleFace(_ face: VNFaceObservation, landMarks: VNFaceLandmarks2D, timestamp: CFTimeInterval) {
        let faceBox = face.boundingBox

        var leftReading: EyeReading?
        if let leftEye = landMarks.leftEye, let leftPupil = landMarks.leftPupil {
            leftReading = eyeReading(pupil: leftPupil, eyeContour: leftEye, faceBox: faceBox)
        }

        var rightReading: EyeReading?
        if let rightEye = landMarks.rightEye, let rightPupil = landMarks.rightPupil {
            rightReading = eyeReading(pupil: rightPupil, eyeContour: rightEye, faceBox: faceBox)
        }

        guard let combinedEyeReading = combine(left: leftReading, right: rightReading) else {
            reportNoFace()
            return
        }

        let pose = headPose(from: face)
        let estimate = gazeEstimate(eyeReading: combinedEyeReading, pose: pose)
        let smoothedEstimate = gazeSmoother.update(with: estimate, at: timestamp)
    }
}

// MARK: - Stage 3
private extension GazeDetector {
    func imagePoint(from region: VNFaceLandmarkRegion2D, faceBox: CGRect) -> [CGPoint] {
        region.normalizedPoints.map { point in
            CGPoint(
                x: faceBox.origin.x + point.x * faceBox.width,
                y: faceBox.origin.y + point.y * faceBox.height
            )
        }
    }

    func corners(of eyePoints: [CGPoint]) -> (CGPoint, CGPoint)? {
        guard eyePoints.count >= 2 else { return nil }

        var best: (CGPoint, CGPoint, CGFloat) = (eyePoints[0], eyePoints[0], 0)

        for i in 0..<eyePoints.count {
            for j in (i + 1)..<eyePoints.count {
                let dx = eyePoints[i].x - eyePoints[j].x
                let dy = eyePoints[i].y - eyePoints[j].y
                let distSq = dx * dx + dy * dy
                if distSq > best.2 {
                    best = (eyePoints[1], eyePoints[j], distSq)
                }
            }
        }

        return (best.0, best.1)
    }

    func normalize(_ v: CGPoint) -> CGPoint {
        let length = sqrt(v.x * v.x + v.y * v.y)
        guard length > 0 else { return .zero }

        return CGPoint(x: v.x / length, y: v.y / length)
    }

    /// The dot product of (pupil - eyeCenter) with the unit axis vector gives you a signed distance:
    /// how far the pupil sits along that axis direction
    func dot(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        a.x * b.x + a.y * b.y
    }

    func eyeReading(
        pupil: VNFaceLandmarkRegion2D,
        eyeContour: VNFaceLandmarkRegion2D,
        faceBox: CGRect
    ) -> EyeReading? {

        let eyePoints = imagePoint(from: eyeContour, faceBox: faceBox)
        let pupilPoints = imagePoint(from: pupil, faceBox: faceBox)

        guard pupilPoints.isEmpty == false,
              let (cornerA, cornerB) = corners(of: pupilPoints) else { return nil }

        let pupilCenter = CGPoint(
            x: pupilPoints.map(\.x).reduce(0, +) / CGFloat(pupilPoints.count),
            y: pupilPoints.map(\.y).reduce(0, +) / CGFloat(pupilPoints.count)
        )

        let eyeCenter = CGPoint(
            x: (cornerA.x + cornerB.x) / 2,
            y: (cornerA.y + cornerB.y) / 2
        )

        let axis = normalize(canonicalAxis(cornerA: cornerA, cornerB: cornerB))

        let perpendicular = CGPoint(x: -axis.y, y: axis.x) // rotate 90°

        let halfAxisLength = sqrt(pow(cornerB.x - cornerA.x, 2) + pow(cornerB.y - cornerA.y, 2)) / 2
        guard halfAxisLength > 0 else { return nil }

        let offset = CGPoint(
            x: pupilCenter.x - eyeCenter.x,
            y: pupilCenter.y - eyeCenter.y
        )

        let horizontal = dot(offset, axis) / halfAxisLength
        // Eye height is a fraction of its width in practice; this scale factor
        // is an approximation, revisit if vertical readings feel too sensitive.

        let vertical = dot(offset, perpendicular) / (halfAxisLength * 0.5)

        let confidence = eyeOpenness(eyePoints)

        return EyeReading(horizontalOffset: horizontal, verticalOffset: vertical, confidence: confidence)
    }

    /// Eye Aspect Ratio, adapted from Soukupová & Čech's blink-detection
    /// approach: ratio of vertical eye extent to horizontal extent. Drops
    /// sharply during a blink, which we use as a simple confidence signal.
    func eyeOpenness(_ eyePoints: [CGPoint]) -> Double {
        guard eyePoints.count >= 4, let (cornerA, cornerB) = corners(of: eyePoints) else { return 0 }

        let width = sqrt(pow(cornerB.x - cornerA.x, 2) + pow((cornerB.y - cornerA.y), 2))
        guard width > 0 else { return 0 }

        let ys = eyePoints.map(\.y)
        let height = (ys.max() ?? 0) - (ys.min() ?? 0)

        let ear = Double(height / width)
        // Typical open-eye EAR is roughly 0.2–0.35; tune against your own
        // logged values rather than trusting this number blindly.

        return min(1.0, max(0.0, ear / 0.3))
    }

    /// Ensures the eye's axis vector always points toward larger image-x,
    /// regardless of which corner the distance search happened to return
    /// first. Without this, left and right eye readings can end up with
    /// inconsistent sign conventions purely by iteration-order accident.
    func canonicalAxis(cornerA: CGPoint, cornerB: CGPoint) -> CGPoint {
        let raw = CGPoint(x: cornerB.x - cornerA.x, y: cornerB.y - cornerA.y)
        return raw.x > 0 ? raw : CGPoint(x: -raw.x, y: -raw.y)
    }
}


//MARK: Stage 4
private extension GazeDetector {
    /// Below this, a single eye's reading is treated as unusable (e.g. a
    /// blink) rather than included at near-zero weight. Tune against logged
    /// EAR values from Stage 3 rather than trusting this number blindly: minUsableConfidence
    func combine(left: EyeReading?, right: EyeReading?) -> CombinedGazeReading? {
        let usableLeft = left.flatMap { $0.confidence >= minUsableConfidence ? $0 : nil }
        let usableRight = right.flatMap { $0.confidence >= minUsableConfidence ? $0 : nil }

        switch (usableLeft, usableRight) {
        case (nil, nil):
            return nil

        case (let l?, nil):
            /// Only one eye usable — use it, but note the reduced confidence rather than treating
            /// a monocular reading as equally reliable as a binocular one.
            return CombinedGazeReading(
                horizontalOffset: l.horizontalOffset,
                verticalOffset: l.verticalOffset,
                confidence: l.confidence * 0.75
            )
        case (nil, let r?):
            return CombinedGazeReading(
                horizontalOffset: r.horizontalOffset,
                verticalOffset: r.verticalOffset,
                confidence: r.confidence * 0.75
            )
        case (let l?, let r?):
            let totalWeight = l.confidence + r.confidence
            /// Both passed the minUsableConfidence check above, so totalWeight > 0 here — safe to divide.
            let horizontal = (l.horizontalOffset * l.confidence + r.horizontalOffset * r.confidence) / totalWeight
            let vertical = (l.verticalOffset * l.confidence + r.verticalOffset * r.confidence) / totalWeight

            return CombinedGazeReading(
                horizontalOffset: horizontal,
                verticalOffset: vertical,
                confidence: (l.confidence + r.confidence) / 2
            )
        }
    }
}
//MARK: Stage 5
private extension GazeDetector {
    func headPose(from face: VNFaceObservation) -> HeadPose {
        let roll = face.roll.map { CGFloat(truncating: $0) }
        let yaw = face.yaw.map{ CGFloat(truncating: $0) }
        let pitch = face.pitch.map{ CGFloat(truncating: $0) }

        return HeadPose(roll: roll, yaw: yaw, pitch: pitch)
    }

    func gazeEstimate(eyeReading: CombinedGazeReading, pose: HeadPose) -> GazeEstimate {
        let yawDegrees = (pose.yaw ?? 0) * 180 / .pi
        let pitchDegrees = (pose.pitch ?? 0) * 180 / .pi

        let eyeHorizontalDegrees = eyeReading.horizontalOffset * assumedMaxEyeRotationDegrees
        let eyeVerticalDegrees = eyeReading.verticalOffset * assumedMaxEyeRotationDegrees

        let horizontalAngle = yawDegrees * eyeHorizontalDegrees
        let verticalAngle = pitchDegrees * eyeVerticalDegrees

        var confidence = eyeReading.confidence
        if pose.yaw == nil { confidence *= 0.85 }
        if pose.pitch == nil { confidence *= 0.85 }

        return GazeEstimate(
            horizontalAngle: horizontalAngle,
            verticalAngle: verticalAngle,
            confidence: confidence
        )
    }
}
//MARK: Stage 6
private extension GazeDetector {
