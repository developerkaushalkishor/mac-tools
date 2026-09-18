import Foundation

public struct RecognizedShape: Equatable, Sendable {
    public var kind: StrokeKind
    public var start: InkPoint
    public var end: InkPoint

    public init(kind: StrokeKind, start: InkPoint, end: InkPoint) {
        self.kind = kind
        self.start = start
        self.end = end
    }
}

public enum ShapeRecognizer {
    /// Recognizes deliberately closed pen gestures while leaving ambiguous strokes untouched.
    public static func recognize(points: [InkPoint]) -> RecognizedShape? {
        guard points.count >= 12 else { return nil }
        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!
        let width = maxX - minX
        let height = maxY - minY
        let diagonal = hypot(width, height)
        guard width >= 24, height >= 24, diagonal > 0 else { return nil }

        let closure = distance(points.first!, points.last!) / diagonal
        guard closure <= 0.22 else { return nil }

        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        let radiusX = width / 2
        let radiusY = height / 2
        let normalized = points.map {
            InkPoint(x: ($0.x - centerX) / radiusX, y: ($0.y - centerY) / radiusY)
        }

        // The gesture must travel around the shape rather than make a small loop
        // near one edge of a large bounding box.
        let quadrants = Set(normalized.map { point -> Int in
            (point.x >= 0 ? 1 : 0) + (point.y >= 0 ? 2 : 0)
        })
        guard quadrants.count == 4 else { return nil }

        let ellipseError = mean(normalized.map { abs(hypot($0.x, $0.y) - 1) })
        let rectangleError = mean(normalized.map { min(abs(abs($0.x) - 1), abs(abs($0.y) - 1)) })
        let diamondError = mean(normalized.map { abs(abs($0.x) + abs($0.y) - 1) / sqrt(2) })
        let candidates: [(StrokeKind, Double)] = [
            (.ellipse, ellipseError), (.rectangle, rectangleError), (.diamond, diamondError)
        ]
        guard let best = candidates.min(by: { $0.1 < $1.1 }), best.1 <= 0.2 else { return nil }

        let pathLength = zip(points, points.dropFirst()).reduce(0) { total, pair in
            total + distance(pair.0, pair.1)
        }
        guard pathLength >= (width + height) * 1.25 else { return nil }
        return RecognizedShape(kind: best.0, start: InkPoint(x: minX, y: minY),
            end: InkPoint(x: maxX, y: maxY))
    }

    private static func mean(_ values: [Double]) -> Double {
        values.reduce(0, +) / Double(values.count)
    }

    private static func distance(_ lhs: InkPoint, _ rhs: InkPoint) -> Double {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
