//  Created by Sam on 29/08/2026.
//

import Foundation

final class GazeZoneClassifier {
    /// Angle (degrees) that must be exceeded to leave .center.
    private let enterThreshold: CGFloat = 12
    
    /// Angle (degrees) the reading must drop below to return to .center.
    private let exitThreshold: CGFloat = 8
    
    private var currentZone: GazeZone = .center
    private var lastCenteredTime: CFTimeInterval?
    
    func classify(
        horizontalAngle: CGFloat,
        verticalAngle: CGFloat,
        timestamp: CFTimeInterval
    ) -> GazeClassification {
        let threshold = (currentZone == .center) ? enterThreshold : exitThreshold
        
        let newZone = zone(horizontal: horizontalAngle, vertical: verticalAngle, threshold: threshold)
        currentZone = newZone
        
        if currentZone == .center {
            lastCenteredTime = timestamp
        }
        
        let timeSinceCentered: CFTimeInterval? = currentZone == .center
            ? nil
            : lastCenteredTime.map{ timestamp - $0 }
        
        return GazeClassification(zone: currentZone, timeSinceCentered: timeSinceCentered)
    }
    
    private func zone(horizontal: CGFloat, vertical: CGFloat, threshold: CGFloat) -> GazeZone {
        guard abs(horizontal) >= threshold || abs(vertical) >= threshold else {
            return .center
        }
        
        /// Off-center: exactly one axis wins — whichever deviates more. This is what
        /// keeps the result single-valued instead of letting horizontal and vertical
        /// checks independently fire, the way the legacy code's four separate trackers did.
        if abs(horizontal) >= abs(vertical) {
            return horizontal > 0 ? .right : .left
        } else {
            return vertical > 0 ? .down : .up
        }
    }
}

struct GazeClassification {
    let zone: GazeZone
    /// Seconds since gaze was last .center. nil while currently centered.
    /// This is the single timer that replaces the legacy code's four
    /// independent, occasionally-un-reset trackers.
    let timeSinceCentered: CFTimeInterval?
}
