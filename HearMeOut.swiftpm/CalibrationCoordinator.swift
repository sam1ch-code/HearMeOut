//  Created by Sam on 31/08/2026.
//

import CoreGraphics

final class CalibrationCoordinator {

    enum State: Equatable {
        case idle
        case awaitingStability(pointIndex: Int)
        case collecting(pointIndex: Int)
        case finished
        case failed
    }

    private(set) var state: State = .idle
    private var targets: [CGPoint] = []
    private var currentIndex = 0
    private let session = CalibrationSession()

    /// Ignore readings for this long after a new target appears — filters
    /// out the transition while eyes are still moving toward the dot.
    private let settleDuration: CFTimeInterval = 0.4
    /// Once settled, keep collecting readings for this long, then average
    /// them into the point's final sample.
    private let collectDuration: CFTimeInterval = 0.6
    /// If a point can't gather enough readings within this long overall
    /// (e.g. repeated face loss), bail out rather than stalling forever.
    private let perPointTimeout: CFTimeInterval = 4.0

    private var phaseStartTime: CFTimeInterval?
    private var pointStartTime: CFTimeInterval?
    private var collectedReadings: [GazeReading] = []

    var onTargetChanged: ((CGPoint) -> Void)?
    var onCollectingChanged: ((Bool) -> Void)?
    var onFinished: ((GazeScreenCalibration?) -> Void)?

    func begin(targets: [CGPoint]) {
        self.targets = targets
        currentIndex = 0
        moveToCurrentTarget()
    }

    private func moveToCurrentTarget() {
        guard currentIndex < targets.count else {
            state = .finished
            print("sample angles: \(collectedReadings.map { ($0.horizontalAngle, $0.verticalAngle) }.suffix(3))")
            onFinished?(session.finish())
            return
        }
        state = .awaitingStability(pointIndex: currentIndex)
        phaseStartTime = nil
        pointStartTime = nil
        collectedReadings = []
        onTargetChanged?(targets[currentIndex])
        onCollectingChanged?(false)
    }

    /// Feed every GazeReading here while calibration is running. Call
    /// `faceLost()` instead when an observation comes back as `.noFace`.
    func handle(_ reading: GazeReading, timestamp: CFTimeInterval) {
        if pointStartTime == nil { pointStartTime = timestamp }
        if let pointStart = pointStartTime, timestamp - pointStart > perPointTimeout {
            state = .failed
            onFinished?(nil)
            return
        }

        switch state {
        case .awaitingStability(let index):
            if phaseStartTime == nil { phaseStartTime = timestamp }
            guard let start = phaseStartTime, timestamp - start >= settleDuration else { return }
            state = .collecting(pointIndex: index)
            phaseStartTime = timestamp
            onCollectingChanged?(true)

        case .collecting(let index):
            collectedReadings.append(reading)
            guard let start = phaseStartTime, timestamp - start >= collectDuration else { return }
            recordAveragedSample(pointIndex: index)
            currentIndex += 1
            moveToCurrentTarget()

        case .idle, .finished, .failed:
            break
        }
    }

    /// Call when the Detector reports `.noFace` while calibrating — a
    /// gap here means whatever's been collected so far for this point is
    /// unreliable, so restart its settle phase rather than quietly
    /// averaging across a dropout.
    func faceLost() {
        guard case .collecting(let index) = state else { return }
        state = .awaitingStability(pointIndex: index)
        phaseStartTime = nil
        collectedReadings = []
        onCollectingChanged?(false)
    }

    private func recordAveragedSample(pointIndex: Int) {
        guard !collectedReadings.isEmpty else { return }
        let reading = GazeReading(
            gaze: .center, // unused for calibration fitting
            horizontalAngle: collectedReadings.map(\.horizontalAngle).reduce(0, +) / CGFloat(collectedReadings.count),
            verticalAngle: collectedReadings.map(\.verticalAngle).reduce(0, +) / CGFloat(collectedReadings.count),
            confidence: collectedReadings.map(\.confidence).reduce(0, +) / Double(collectedReadings.count),
            timeSinceCentered: nil,
            timestamp: 0
        )
        session.recordSample(at: targets[pointIndex], reading: reading)
    }
}
