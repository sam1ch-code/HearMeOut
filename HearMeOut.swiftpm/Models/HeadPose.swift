//  Created by Sukhrob on 28/08/26.
//

import Foundation

struct HeadPose {
    let roll: CGFloat?
    let yaw: CGFloat?
    let pitch: CGFloat?
}

struct GazeEstimate {
    /// Approximate total angular deviation from looking straight at the
    /// camera, in degrees. Positive/negative direction follows whatever
    /// Vision's own yaw/pitch sign convention is — verify this empirically
    let horizontalAngle: CGFloat
    let verticalAngle: CGFloat
    let confidence: Double
}
