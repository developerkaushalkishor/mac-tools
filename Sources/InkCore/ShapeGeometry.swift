import Foundation

public enum ShapeGeometry {
    public static func constrainedEnd(start: InkPoint, proposed: InkPoint,
        kind: StrokeKind, shiftPressed: Bool) -> InkPoint {
        guard shiftPressed else { return proposed }
        let dx = proposed.x - start.x
        let dy = proposed.y - start.y
        switch kind {
        case .rectangle, .ellipse, .diamond:
            let side = max(abs(dx), abs(dy))
            return InkPoint(x: start.x + (dx < 0 ? -side : side),
                y: start.y + (dy < 0 ? -side : side))
        case .line, .arrow:
            let distance = hypot(dx, dy)
            guard distance > 0 else { return proposed }
            let angle = atan2(dy, dx)
            let step = Double.pi / 4
            let snapped = (angle / step).rounded() * step
            return InkPoint(x: start.x + cos(snapped) * distance,
                y: start.y + sin(snapped) * distance)
        case .freehand, .text:
            return proposed
        }
    }

    public static func arrowHead(start: InkPoint, end: InkPoint, width: Double) -> [InkPoint] {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = max(10, width * 4)
        let spread = Double.pi / 7
        return [InkPoint(x: end.x - cos(angle - spread) * length,
                y: end.y - sin(angle - spread) * length),
            end,
            InkPoint(x: end.x - cos(angle + spread) * length,
                y: end.y - sin(angle + spread) * length)]
    }

    public static func handDrawnEllipsePoints(start: InkPoint, end: InkPoint,
        segmentCount: Int = 96) -> [InkPoint] {
        let center = InkPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let radiusX = abs(end.x - start.x) / 2
        let radiusY = abs(end.y - start.y) / 2
        let roughness = min(0.8, min(radiusX, radiusY) * 0.012)
        guard radiusX > 0, radiusY > 0 else { return [start, end] }
        return (0...segmentCount).map { index in
            let angle = Double(index) / Double(segmentCount) * 2 * Double.pi
            // Deterministic low-amplitude harmonics preserve a clean ellipse while
            // avoiding the mechanically perfect look of a generated oval.
            let wobble = roughness * (0.62 * sin(angle * 3 + 0.7)
                + 0.38 * sin(angle * 7 + 1.9))
            return InkPoint(x: center.x + cos(angle) * (radiusX + wobble),
                y: center.y + sin(angle) * (radiusY + wobble))
        }
    }

    public static func handDrawnRoundedRectanglePoints(start: InkPoint, end: InkPoint) -> [InkPoint] {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        let radius = min(18, min(maxX - minX, maxY - minY) * 0.18)
        let vertices = [InkPoint(x: minX, y: minY), InkPoint(x: maxX, y: minY),
            InkPoint(x: maxX, y: maxY), InkPoint(x: minX, y: maxY)]
        return roundedPolygonPoints(vertices: vertices, cornerDistance: radius)
    }

    public static func handDrawnDiamondPoints(start: InkPoint, end: InkPoint) -> [InkPoint] {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        let center = InkPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let vertices = [InkPoint(x: center.x, y: minY), InkPoint(x: maxX, y: center.y),
            InkPoint(x: center.x, y: maxY), InkPoint(x: minX, y: center.y)]
        let cornerDistance = min(22, min(maxX - minX, maxY - minY) * 0.12)
        return roundedPolygonPoints(vertices: vertices, cornerDistance: cornerDistance)
    }

    private static func roundedPolygonPoints(vertices: [InkPoint], cornerDistance: Double) -> [InkPoint] {
        guard vertices.count > 2 else { return vertices }
        var result: [InkPoint] = []
        for index in vertices.indices {
            let previous = vertices[(index - 1 + vertices.count) % vertices.count]
            let corner = vertices[index]
            let next = vertices[(index + 1) % vertices.count]
            let entry = point(from: corner, toward: previous, distance: cornerDistance)
            let exit = point(from: corner, toward: next, distance: cornerDistance)
            if result.isEmpty { result.append(entry) }
            else { appendLine(from: result.last!, to: entry, into: &result) }
            for step in 1...6 {
                let t = Double(step) / 6
                let inverse = 1 - t
                result.append(InkPoint(
                    x: inverse * inverse * entry.x + 2 * inverse * t * corner.x + t * t * exit.x,
                    y: inverse * inverse * entry.y + 2 * inverse * t * corner.y + t * t * exit.y))
            }
        }
        if let first = result.first, let last = result.last { appendLine(from: last, to: first, into: &result) }
        return addPenWobble(to: result)
    }

    private static func point(from origin: InkPoint, toward target: InkPoint, distance: Double) -> InkPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let length = max(0.001, hypot(dx, dy))
        let amount = min(distance, length / 2)
        return InkPoint(x: origin.x + dx / length * amount, y: origin.y + dy / length * amount)
    }

    private static func appendLine(from start: InkPoint, to end: InkPoint, into points: inout [InkPoint]) {
        let steps = max(1, Int(ceil(hypot(end.x - start.x, end.y - start.y) / 12)))
        for step in 1...steps {
            let t = Double(step) / Double(steps)
            points.append(InkPoint(x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t))
        }
    }

    private static func addPenWobble(to points: [InkPoint]) -> [InkPoint] {
        guard points.count > 2 else { return points }
        var adjusted = points.enumerated().map { index, point in
            let previous = points[max(0, index - 1)]
            let next = points[min(points.count - 1, index + 1)]
            let dx = next.x - previous.x
            let dy = next.y - previous.y
            let length = max(0.001, hypot(dx, dy))
            let offset = 0.42 * sin(Double(index) * 1.73 + 0.4)
            return InkPoint(x: point.x - dy / length * offset,
                y: point.y + dx / length * offset)
        }
        adjusted[adjusted.count - 1] = adjusted[0]
        return adjusted
    }
}
