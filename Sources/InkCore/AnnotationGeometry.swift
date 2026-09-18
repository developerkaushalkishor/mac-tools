import Foundation

public struct InkBounds: Equatable, Sendable {
    public var minX: Double
    public var minY: Double
    public var maxX: Double
    public var maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    public var width: Double { maxX - minX }
    public var height: Double { maxY - minY }
    public var corners: [InkPoint] {
        [InkPoint(x: minX, y: minY), InkPoint(x: maxX, y: minY),
            InkPoint(x: maxX, y: maxY), InkPoint(x: minX, y: maxY)]
    }

    public func contains(_ point: InkPoint, padding: Double = 0) -> Bool {
        point.x >= minX - padding && point.x <= maxX + padding
            && point.y >= minY - padding && point.y <= maxY + padding
    }
}

public extension InkBounds {
    init(_ rect: CGRect) {
        self.init(minX: rect.minX, minY: rect.minY, maxX: rect.maxX, maxY: rect.maxY)
    }

    var cgRect: CGRect {
        CGRect(x: minX, y: minY, width: width, height: height)
    }
}

public enum AnnotationGeometry {
    public static func bounds(of stroke: Stroke) -> InkBounds? {
        guard let first = stroke.points.first else { return nil }
        if stroke.kind == .text {
            let count = max(1, stroke.text?.count ?? 0)
            let width = max(stroke.fontSize * 0.6, Double(count) * stroke.fontSize * 0.58)
            let minX = switch stroke.textAlignment {
            case .left: first.x
            case .center: first.x - width / 2
            case .right: first.x - width
            }
            return InkBounds(minX: minX, minY: first.y,
                maxX: minX + width, maxY: first.y + stroke.fontSize * 1.3)
        }
        if [.rectangle, .ellipse, .diamond].contains(stroke.kind),
            let last = stroke.points.last {
            return InkBounds(minX: min(first.x, last.x), minY: min(first.y, last.y),
                maxX: max(first.x, last.x), maxY: max(first.y, last.y))
        }
        let path = StrokeHitTesting.pathPoints(for: stroke)
        guard !path.isEmpty else { return nil }
        return InkBounds(minX: path.map(\.x).min()!, minY: path.map(\.y).min()!,
            maxX: path.map(\.x).max()!, maxY: path.map(\.y).max()!)
    }

    public static func moved(_ stroke: Stroke, dx: Double, dy: Double) -> Stroke {
        var result = stroke
        result.points = stroke.points.map { InkPoint(x: $0.x + dx, y: $0.y + dy) }
        return result
    }

    public static func resized(_ stroke: Stroke, handle: Int, to point: InkPoint) -> Stroke {
        var result = stroke
        if stroke.kind == .line || stroke.kind == .arrow {
            guard result.points.count >= 2 else { return stroke }
            result.points[handle == 0 ? 0 : result.points.count - 1] = point
            return result
        }
        if stroke.kind == .text, let bounds = bounds(of: stroke) {
            let widthRatio = max(0.01, (point.x - bounds.minX) / max(1, bounds.width))
            let heightRatio = max(0.01, (point.y - bounds.minY) / max(1, bounds.height))
            result.fontSize = min(120, max(12, stroke.fontSize * max(widthRatio, heightRatio)))
            return result
        }
        if stroke.kind == .freehand, let bounds = bounds(of: stroke) {
            let corners = bounds.corners
            guard corners.indices.contains(handle) else { return stroke }
            let opposite = corners[(handle + 2) % 4]
            let newMinX = min(opposite.x, point.x)
            let newMaxX = max(opposite.x, point.x)
            let newMinY = min(opposite.y, point.y)
            let newMaxY = max(opposite.y, point.y)
            let newWidth = max(1, newMaxX - newMinX)
            let newHeight = max(1, newMaxY - newMinY)
            let oldWidth = max(1, bounds.width)
            let oldHeight = max(1, bounds.height)
            result.points = stroke.points.map { original in
                InkPoint(x: newMinX + (original.x - bounds.minX) / oldWidth * newWidth,
                    y: newMinY + (original.y - bounds.minY) / oldHeight * newHeight)
            }
            let scale = sqrt((newWidth / oldWidth) * (newHeight / oldHeight))
            result.width = min(40, max(1, stroke.width * scale))
            return result
        }
        guard let bounds = bounds(of: stroke), bounds.corners.indices.contains(handle) else { return stroke }
        let opposite = bounds.corners[(handle + 2) % 4]
        result.points = [opposite, point]
        return result
    }

    public static func transformed(_ stroke: Stroke, from source: InkBounds,
        to target: InkBounds) -> Stroke {
        var result = stroke
        let sourceWidth = max(1, source.width)
        let sourceHeight = max(1, source.height)
        let scaleX = target.width / sourceWidth
        let scaleY = target.height / sourceHeight
        result.points = stroke.points.map { point in
            InkPoint(x: target.minX + (point.x - source.minX) * scaleX,
                y: target.minY + (point.y - source.minY) * scaleY)
        }
        let scale = sqrt(max(0.01, scaleX * scaleY))
        if stroke.kind == .text { result.fontSize = min(120, max(12, stroke.fontSize * scale)) }
        else { result.width = min(40, max(1, stroke.width * scale)) }
        return result
    }
}
