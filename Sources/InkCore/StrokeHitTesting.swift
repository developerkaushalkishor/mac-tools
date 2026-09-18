import Foundation

public enum StrokeHitTesting {
    public static func hits(_ stroke: Stroke, point: InkPoint, tolerance: Double) -> Bool {
        if stroke.kind == .text, let origin = stroke.points.first, let text = stroke.text {
            let width = max(stroke.fontSize * 0.6, Double(text.count) * stroke.fontSize * 0.58)
            let height = stroke.fontSize * 1.3
            let minX = switch stroke.textAlignment {
            case .left: origin.x
            case .center: origin.x - width / 2
            case .right: origin.x - width
            }
            return point.x >= minX - tolerance && point.x <= minX + width + tolerance
                && point.y >= origin.y - tolerance && point.y <= origin.y + height + tolerance
        }
        let radius = tolerance + stroke.width / 2
        let path = pathPoints(for: stroke)
        guard let first = path.first else { return false }
        if path.count == 1 { return distance(first, point) <= radius }
        for (start, end) in zip(path, path.dropFirst()) {
            if distanceToSegment(point, start, end) <= radius { return true }
        }
        if stroke.kind == .arrow, let start = stroke.points.first, let end = stroke.points.last {
            let head = ShapeGeometry.arrowHead(start: start, end: end, width: stroke.width)
            for (headStart, headEnd) in zip(head, head.dropFirst()) {
                if distanceToSegment(point, headStart, headEnd) <= radius { return true }
            }
        }
        return false
    }

    public static func pathPoints(for stroke: Stroke) -> [InkPoint] {
        guard let start = stroke.points.first, let end = stroke.points.last else { return [] }
        switch stroke.kind {
        case .freehand, .line, .arrow, .text:
            return stroke.points
        case .rectangle:
            return ShapeGeometry.handDrawnRoundedRectanglePoints(start: start, end: end)
        case .ellipse:
            return ShapeGeometry.handDrawnEllipsePoints(start: start, end: end)
        case .diamond:
            return ShapeGeometry.handDrawnDiamondPoints(start: start, end: end)
        }
    }

    private static func distance(_ a: InkPoint, _ b: InkPoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }

    private static func distanceToSegment(_ point: InkPoint, _ start: InkPoint, _ end: InkPoint) -> Double {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return distance(point, start) }
        let projection = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        let t = min(1, max(0, projection))
        return hypot(point.x - (start.x + t * dx), point.y - (start.y + t * dy))
    }
}
