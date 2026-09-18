import AppKit
import InkCore

@MainActor
final class CanvasView: NSView {
    var store = StrokeStore()
    var color: UInt32 = 0xFF453A
    var penWidth: Double = 4
    var onEscape: (() -> Void)?
    private var current: Stroke?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        current = Stroke(points: [point(event)], color: color, width: penWidth)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        current?.points.append(point(event))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        current?.points.append(point(event))
        finishStroke()
    }

    func finishStroke() {
        if let current { store.append(current) }
        current = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onEscape?(); return }
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "z" {
            finishStroke()
            if event.modifierFlags.contains(.shift) { store.redo() } else { store.undo() }
            needsDisplay = true
            return
        }
        super.keyDown(with: event)
    }

    private func point(_ event: NSEvent) -> InkPoint {
        let p = convert(event.locationInWindow, from: nil)
        return InkPoint(x: p.x, y: p.y)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(dirtyRect)
        for stroke in store.strokes { render(stroke, in: context) }
        if let current { render(current, in: context) }
    }

    private func render(_ stroke: Stroke, in context: CGContext) {
        guard let first = stroke.points.first else { return }
        let color = NSColor(
            srgbRed: CGFloat((stroke.color >> 16) & 255) / 255,
            green: CGFloat((stroke.color >> 8) & 255) / 255,
            blue: CGFloat(stroke.color & 255) / 255, alpha: 1
        ).cgColor
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(stroke.width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        if stroke.points.allSatisfy({ $0 == first }) {
            context.fillEllipse(in: CGRect(x: first.x - stroke.width / 2,
                y: first.y - stroke.width / 2, width: stroke.width, height: stroke.width))
        } else {
            context.beginPath()
            context.move(to: CGPoint(x: first.x, y: first.y))
            for point in stroke.points.dropFirst() {
                context.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            context.strokePath()
        }
    }
}
