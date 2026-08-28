//  Created by Sukhrob on 28/08/26.
//

import Foundation
import CoreGraphics

final class GazeSmoother {
    /// Roughly, how many seconds of recent history meaningfully influence
    /// the smoothed value. Larger = smoother but slower to react; smaller
    /// = snappier but noisier. Tune by watching how quickly a deliberate
    /// gaze shift should register.
    private let timeConstant: CFTimeInterval = 0.15

    /// If more time than this passes between updates — face was lost,
    /// app backgrounded, etc. — treat the next reading as a fresh start
    /// rather than smoothing across a meaningless gap.
    private let maxGapBeforeReset: CFTimeInterval = 1.0

    private var smoothedHorizontal: CGFloat = 0
    private var smoothedVertical: CGFloat = 0
    private var smoothedConfidence: Double = 0
    private var lastUpdateTime: CFTimeInterval?

    /// Feed one raw estimate in, get the smoothed estimate out.
    func update(with estimate: GazeEstimate, at timestamp: CFTimeInterval) -> GazeEstimate {
        defer { lastUpdateTime = timestamp }

        guard let lastTime = lastUpdateTime else {
            return resetTo(estimate)
        }

        let dt = timestamp - lastTime
        guard dt > 0, dt < maxGapBeforeReset else {
            return resetTo(estimate)
        }

        let alpha = 1 - exp(-dt / timeConstant)

        /// Scale by this frame's confidence: a shaky, low-confidence reading nudges the smoothed angle less than a clean one would.
        let effectiveAlpha = alpha * estimate.confidence

        smoothedHorizontal += (estimate.horizontalAngle - smoothedHorizontal) * effectiveAlpha
        smoothedVertical += (estimate.verticalAngle - smoothedVertical) * effectiveAlpha

        /// Confidence itself is deliberately NOT scaled by its own value here — doing so would
        /// create a feedback loop where a dip in confidence makes it harder for confidence to ever recover.
        smoothedConfidence += (estimate.confidence - smoothedConfidence) * alpha

        return GazeEstimate(
            horizontalAngle: smoothedHorizontal,
            verticalAngle: smoothedVertical,
            confidence: smoothedConfidence
        )
    }

    /// Call when the face is lost entirely (Stage 4 reported no usable eyes) so the next
    /// real reading starts fresh instead of smoothing from a stale last-known position.
    func reset() {
        lastUpdateTime = nil
    }

    private func resetTo(_ estimate: GazeEstimate) -> GazeEstimate {
        smoothedHorizontal = estimate.horizontalAngle
        smoothedVertical = estimate.verticalAngle
        smoothedConfidence = estimate.confidence
        return estimate
    }
}
