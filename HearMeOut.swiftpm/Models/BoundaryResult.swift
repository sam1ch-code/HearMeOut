//  Created by Sam on 31/08/2026.
//

import Foundation

enum BoundaryResult {
    case withinBounds(estimatedPoint: CGPoint)
    case exceeded(estimatedPoint: CGPoint, direction: GazeZone)
}
