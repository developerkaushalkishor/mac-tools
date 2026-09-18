import AppKit

@MainActor
final class ToolbarPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class DragHandle: NSView {
    var didDrag: (() -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
        didDrag?()
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.withAlphaComponent(0.45).setFill()
        for x in [7.0, 13.0] {
            for y in [11.0, 17.0, 23.0] {
                NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 2.5, height: 2.5)).fill()
            }
        }
    }
}

@MainActor
class FeedbackButton: NSButton {
    override func mouseDown(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.05
            animator().alphaValue = 0.45
        }
        super.mouseDown(with: event)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }
    }
}

@MainActor
final class ColorButton: FeedbackButton {
    var inkColor = NSColor.white
    var selected = false { didSet { needsDisplay = true } }
    override func draw(_ dirtyRect: NSRect) {
        let diameter: CGFloat = 18
        let circle = NSRect(x: bounds.midX - diameter / 2, y: bounds.midY - diameter / 2,
            width: diameter, height: diameter)
        inkColor.setFill()
        NSBezierPath(ovalIn: circle).fill()
        if selected {
            NSColor.white.withAlphaComponent(0.9).setStroke()
            let ring = NSBezierPath(ovalIn: circle.insetBy(dx: -3, dy: -3))
            ring.lineWidth = 1.5
            ring.stroke()
        }
    }
}

@MainActor
enum ScreenInkIcons {
    /// Original vector nib and ink curve. Template rendering follows menu-bar contrast.
    static func menuBar() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            let nib = NSBezierPath()
            nib.move(to: NSPoint(x: 4, y: 6))
            nib.line(to: NSPoint(x: 5.5, y: 11.5))
            nib.line(to: NSPoint(x: 12, y: 16))
            nib.line(to: NSPoint(x: 16, y: 12))
            nib.line(to: NSPoint(x: 10, y: 7))
            nib.close()
            nib.lineWidth = 1.35
            nib.lineJoinStyle = .round
            nib.stroke()
            let slit = NSBezierPath()
            slit.move(to: NSPoint(x: 4, y: 6))
            slit.line(to: NSPoint(x: 9, y: 11))
            slit.lineWidth = 1.2
            slit.stroke()
            let ink = NSBezierPath()
            ink.move(to: NSPoint(x: 2, y: 3))
            ink.curve(to: NSPoint(x: 16, y: 3), controlPoint1: NSPoint(x: 5, y: 6), controlPoint2: NSPoint(x: 11, y: 0))
            ink.lineWidth = 1.3
            ink.lineCapStyle = .round
            ink.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "ScreenInk"
        return image
    }

    static func button(_ symbol: String, label: String, target: AnyObject, action: Selector) -> NSButton {
        let button = FeedbackButton()
        button.title = ""
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.contentTintColor = .white
        button.toolTip = label
        button.setAccessibilityLabel(label)
        button.target = target
        button.action = action
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        return button
    }
}
