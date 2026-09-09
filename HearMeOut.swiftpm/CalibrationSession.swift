//  Created by Sam on 31/08/2026.
//

import Foundation

final class CalibrationSession {
    private var samples: [CalibrationSample] = []

    func reset() {
        samples.removeAll(keepingCapacity: true)
    }
    
    /// Call once per target point, feeding it the latest GazeReading
    /// while the user is looking at `targetPoint`. Ignores low-confidence
    /// readings — same reasoning as Stage 4's minUsableConfidence: a
    /// calibration point built from an unreliable reading corrupts the whole fit, not just that one point.
    func recordSample(at targetPoint: CGPoint, reading: GazeReading, minConfidence: Double = 0.6) {
        guard reading.confidence >= minConfidence else { return }
        samples.append(CalibrationSample(
                screenPoint: targetPoint,
                horizontalAngle: reading.horizontalAngle,
                verticalAngle: reading.verticalAngle
            ))
    }
    
    func finish() -> GazeScreenCalibration? {
        GazeScreenCalibration(samples: samples)
    }
}
