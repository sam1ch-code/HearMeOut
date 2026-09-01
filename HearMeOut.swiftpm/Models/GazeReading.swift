//  Created by Sam on 30/08/2026.
//

import Foundation

struct GazeReading: Sendable {
    let gaze: GazeZone
    let horizontalAngle: CGFloat
    let verticalAngle: CGFloat
    let confidence: Double
    /// Seconds since gaze was last centered; nil while currently centered.
    let timeSinceCentered: CFTimeInterval?
    let timestamp: CFTimeInterval
}

enum GazeObservation: Sendable {
    case detected(GazeReading)
    case noFace
}
