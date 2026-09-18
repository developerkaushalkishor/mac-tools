import Foundation
import CoreGraphics

public enum ToolbarGeometry {
    /// Reveal only at the physical top edge, centered across exactly one toolbar width.
    public static func isRevealPoint(_ point: CGPoint, frame: CGRect,
        visibleFrame _: CGRect, toolbarWidth: Double, toolbarHeight _: Double) -> Bool {
        let halfWidth = toolbarWidth / 2
        let bottom = frame.maxY - 4
        return point.x >= frame.minX && point.x <= frame.maxX
            && point.y >= frame.minY && point.y <= frame.maxY
            && abs(point.x - frame.midX) <= halfWidth && point.y >= bottom
    }
}
