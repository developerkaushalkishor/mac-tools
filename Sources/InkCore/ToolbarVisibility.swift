/// Time-based toolbar behavior, independent of AppKit and wall-clock changes.
public struct ToolbarVisibility {
    public private(set) var isVisible = true
    private var lastActivity: Double
    private var revealArmed = true
    public init(now: Double) { lastActivity = now }

    public mutating func show(now: Double) {
        isVisible = true
        lastActivity = now
    }

    public mutating func hide(topEdgeHovered: Bool) {
        isVisible = false
        revealArmed = !topEdgeHovered
    }

    public mutating func update(now: Double, toolbarHovered: Bool,
        topEdgeHovered: Bool, interacting: Bool, autoHide: Bool) {
        if !topEdgeHovered { revealArmed = true }
        if isVisible {
            if toolbarHovered || topEdgeHovered || interacting || !autoHide { lastActivity = now }
            if autoHide && now - lastActivity >= 2 { hide(topEdgeHovered: topEdgeHovered) }
        } else if topEdgeHovered && revealArmed && !interacting {
            show(now: now)
        }
    }
}
