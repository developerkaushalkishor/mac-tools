import Foundation
import CoreGraphics

public enum ToolbarGeometry {
    public static let horizontalScreenMargin = 12.0
    public static let quickColorMinimumScreenWidth = 900.0

    public static func availableWidth(screenWidth: Double) -> Double {
        max(1, screenWidth - horizontalScreenMargin * 2)
    }

    public static func shouldShowQuickColors(screenWidth: Double) -> Bool {
        screenWidth >= quickColorMinimumScreenWidth
    }

    public static func fittedWidth(contentWidth: Double, screenWidth: Double) -> Double {
        min(contentWidth, availableWidth(screenWidth: screenWidth))
    }

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
