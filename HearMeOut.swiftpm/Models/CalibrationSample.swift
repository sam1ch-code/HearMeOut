//  Created by Sam on 31/08/2026.
//

import Foundation

/// One calibration sample: a known on-screen point, paired with the
/// gaze angles recorded while the user was looking at it.

struct CalibrationSample {
    let screenPoint: CGPoint
    let horizontalAngle: CGFloat
    let verticalAngle: CGFloat
}
