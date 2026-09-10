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
//    private let scaleX: CGFloat
//    private let offsetX: CGFloat
//    private let scaleY: CGFloat
//    private let offsetY: CGFloat

    let x: (h: CGFloat, v: CGFloat, b: CGFloat)
    let y: (h: CGFloat, v: CGFloat, b: CGFloat)

    /// Returns nil if samples don't vary enough on an axis to fit (e.g. only ever looked at points
    /// with the same x — this would otherwise divide by zero).
    init?(samples: [CalibrationSample]) {
        guard samples.count >= 3 else {
            return nil
        }

        guard let xCoefficients = Self.fitAffine(
            samples: samples,
            target: { $0.screenPoint.x }
        ) else {
            return nil
        }

        guard let yCoefficients = Self.fitAffine(
            samples: samples,
            target: { $0.screenPoint.y }
        ) else {
            return nil
        }

        x = xCoefficients
        y = yCoefficients
    }

    func estimatedScreenPoint(
        horizontalAngle h: CGFloat,
        verticalAngle v: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: x.h * h + x.v * v + x.b,
            y: y.h * h + y.v * v + y.b
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

private extension GazeScreenCalibration {

    static func fitAffine(
        samples: [CalibrationSample],
        target: (CalibrationSample) -> CGFloat
    ) -> (h: CGFloat, v: CGFloat, b: CGFloat)? {

        // We are fitting:
        //
        // target = h * horizontalAngle
        //        + v * verticalAngle
        //        + b
        //
        // using least squares.

        let n = CGFloat(samples.count)

        var sumH: CGFloat = 0
        var sumV: CGFloat = 0
        var sumHH: CGFloat = 0
        var sumVV: CGFloat = 0
        var sumHV: CGFloat = 0
        var sumY: CGFloat = 0
        var sumHY: CGFloat = 0
        var sumVY: CGFloat = 0

        for sample in samples {
            let h = sample.horizontalAngle
            let v = sample.verticalAngle
            let y = target(sample)

            sumH += h
            sumV += v
            sumHH += h * h
            sumVV += v * v
            sumHV += h * v
            sumY += y
            sumHY += h * y
            sumVY += v * y
        }

        let matrix: [[CGFloat]] = [
            [sumHH, sumHV, sumH],
            [sumHV, sumVV, sumV],
            [sumH,  sumV,  n]
        ]

        let vector = [sumHY, sumVY, sumY]

        guard let coefficients = solve3x3(matrix, vector) else {
            return nil
        }

        return (
            h: coefficients[0],
            v: coefficients[1],
            b: coefficients[2]
        )
    }
}

private extension GazeScreenCalibration {

    static func solve3x3(
        _ matrix: [[CGFloat]],
        _ vector: [CGFloat]
    ) -> [CGFloat]? {
        guard matrix.count == 3,
              matrix.allSatisfy({ $0.count == 3 }),
              vector.count == 3 else {
            return nil
        }

        var a = matrix
        var b = vector

        for column in 0..<3 {
            var pivot = column

            for row in (column + 1)..<3 {
                if abs(a[row][column]) > abs(a[pivot][column]) {
                    pivot = row
                }
            }

            guard abs(a[pivot][column]) > 0.000001 else {
                return nil
            }

            if pivot != column {
                a.swapAt(pivot, column)
                b.swapAt(pivot, column)
            }

            for row in (column + 1)..<3 {
                let factor = a[row][column] / a[column][column]

                for col in column..<3 {
                    a[row][col] -= factor * a[column][col]
                }

                b[row] -= factor * b[column]
            }
        }

        var result = [CGFloat](repeating: 0, count: 3)

        for row in stride(from: 2, through: 0, by: -1) {
            var value = b[row]

            for col in (row + 1)..<3 {
                value -= a[row][col] * result[col]
            }

            result[row] = value / a[row][row]
        }

        return result
    }
}
