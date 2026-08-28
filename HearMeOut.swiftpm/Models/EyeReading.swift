//  Created by Sukhrob on 26/08/26.
//

import Foundation

struct EyeReading: Equatable {
    /// Signed offset along the eye's own corner-to-corner axis, roughly
    /// -1 (fully toward one corner) ... +1 (fully toward the other).
    let horizontalOffset: CGFloat

    /// Signed offset along the perpendicular axis, roughly -1...+1.
    let verticalOffset: CGFloat

    /// 0...1 — lower when the eye looks closed/occluded (see EAR below).
    let confidence: Double
}
