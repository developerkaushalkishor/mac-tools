import Foundation

public enum StrokePointSampling {
    /// Appends a point only when it contributes visible movement. A forced append preserves
    /// the exact end of a gesture even when the final mouse event is very close to its predecessor.
    public static func append(_ point: InkPoint, to points: inout [InkPoint],
        minimumDistance: Double, force: Bool = false) {
        guard let last = points.last else {
            points.append(point)
            return
        }
        let distance = hypot(point.x - last.x, point.y - last.y)
        guard distance > 0, force || distance >= minimumDistance else { return }
        points.append(point)
    }
}
