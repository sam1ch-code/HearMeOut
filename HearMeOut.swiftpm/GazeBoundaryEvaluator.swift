//  Created by Sam on 31/08/2026.
//

import Foundation

/// Uses a fitted calibration to decide whether a gaze reading falls
/// within the visible view's bounds, or has drifted past an edge.
final class GazeBoundaryEvaluator {
    private let calibration: GazeScreenCalibration
    
    /// Margin (points) added around the raw bounds before treating gaze
    /// as "exceeded" — without this, an estimate landing exactly on the
    /// edge pixel would flicker in/out on tiny noise, the same problem
    /// Stage 7's hysteresis solved for zone classification.
    private let margin: CGFloat = 24
    
    init(calibration: GazeScreenCalibration) {
        self.calibration = calibration
    }
    
    /// `viewBounds` is passed in fresh each call rather than cached — pass `view.bounds`
    /// from the caller so this stays correct across rotation/resizing, rather than
    /// repeating the earlier bug of capturing bounds once at setup time.
    func evaluate(_ reading: GazeReading, viewBounds: CGRect) -> BoundaryResult {
        let point = calibration.estimatedScreenPoint(
            horizontalAngle: reading.horizontalAngle,
            verticalAngle: reading.verticalAngle
        )
        
        let bounds = viewBounds.insetBy(dx: -margin, dy: -margin)
        
        guard bounds.contains(point) else {
            let direction: GazeZone
            if point.x < bounds.minX { direction = .left }
            else if point.x > bounds.maxX { direction = .right }
            else if point.y < bounds.minY { direction = .up }
            else { direction = .down }
            return .exceeded(estimatedPoint: point, direction: direction)
        }
        
        return .withinBounds(estimatedPoint: point)
    }
}

