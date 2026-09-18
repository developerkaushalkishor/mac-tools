import Foundation

public enum StrokeHitTesting {
    public static func hits(_ stroke: Stroke, point: InkPoint, tolerance: Double) -> Bool {
        let radius = tolerance + stroke.width / 2
        guard let first = stroke.points.first else { return false }
        if stroke.points.count == 1 { return distance(first, point) <= radius }
        for (start, end) in zip(stroke.points, stroke.points.dropFirst()) {
            if distanceToSegment(point, start, end) <= radius { return true }
        }
        return false
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
