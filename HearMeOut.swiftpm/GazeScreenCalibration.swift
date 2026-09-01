//  Created by Sam on 31/08/2026.
//

import CoreGraphics

/// Fits a simple per-axis linear mapping from gaze angle to on-screen
/// position: screenX = m·horizontalAngle + b, and separately for Y.
/// Deliberately simpler than a full 2D affine fit — a small angular
/// range rarely needs cross-axis coupling modeled, and this keeps the
/// calibration flow short (two points per axis, not three-plus for a
/// full system solve).
struct GazeScreenCalibration {
    private let scaleX: CGFloat
    private let offsetX: CGFloat
    private let scaleY: CGFloat
    private let offsetY: CGFloat
    
    /// Returns nil if samples don't vary enough on an axis to fit (e.g. only ever looked at points
    /// with the same x — this would otherwise divide by zero).
    init?(samples: [CalibrationSample]) {
        guard samples.count >= 2,
              let (mX, bX) = Self.linearFit(xs: samples.map(\.horizontalAngle), ys: samples.map(\.screenPoint.x)),
              let (mY, bY) = Self.linearFit(xs: samples.map(\.verticalAngle), ys: samples.map(\.screenPoint.y))
        else { return nil }
        
        scaleX = mX; offsetX = bX
        scaleY = mY; offsetY = bY
    }
    
    func estimatedScreenPoint(horizontalAngle: CGFloat, verticalAngle: CGFloat) -> CGPoint {
        CGPoint(
            x: scaleX * horizontalAngle + offsetX,
            y: scaleY * verticalAngle + offsetY
        )
    }
    
    /// Ordinary least squares slope/intercept for y = m·x + b.
    private static func linearFit(xs: [CGFloat], ys: [CGFloat]) -> (CGFloat, CGFloat)? {
        let n = CGFloat(xs.count)
        let sumX = xs.reduce(0, +), sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        
        let detominator = n * sumXX - sumX * sumX
        guard detominator != 0 else { return nil }
        
        let m = (n * sumXY - sumX * sumY) / detominator
        let b = (sumY - m * sumX) / n

        return (m, b)
    }
}
