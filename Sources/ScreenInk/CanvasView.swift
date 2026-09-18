import AppKit
import InkCore

enum DrawingTool: String, CaseIterable {
    case pen
    case highlighter
    case eraser
    case laser
}

@MainActor
final class CanvasView: NSView {
    var store = StrokeStore()
    var color: UInt32 = 0xFF453A
    var penWidth: Double = 4
    var tool: DrawingTool = .pen
    var fadingInkEnabled = false
    var fadeDelay: Double = 5
    var inkVisible = true { didSet { needsDisplay = true } }
    var cursorHaloEnabled = false { didSet { needsDisplay = true } }
    var cursorPoint: NSPoint? { didSet { if cursorHaloEnabled { needsDisplay = true } } }
    var onEscape: (() -> Void)?
    private var current: Stroke?
    private var pendingErasures: Set<Int> = []
    private var previousEraserPoint: InkPoint?
    private var previousLaserPoint: InkPoint?
    private var laserSegments: [Stroke] = []
    var activeLaserSegmentCount: Int { laserSegments.count }
    private var wasAnimatingFade = false

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        let location = point(event)
        if tool == .eraser {
            pendingErasures.removeAll()
            collectErasures(at: location)
            previousEraserPoint = location
        } else if tool == .laser {
            previousLaserPoint = location
        } else {
            let width = tool == .highlighter ? max(14, penWidth * 4) : penWidth
            let opacity = tool == .highlighter ? 0.28 : 1
            current = Stroke(points: [location], color: color, width: width, opacity: opacity,
                createdAt: ProcessInfo.processInfo.systemUptime,
                fadeAfter: fadingInkEnabled ? fadeDelay : nil)
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        if tool == .eraser {
            let location = point(event)
            collectErasures(from: previousEraserPoint, to: location)
            previousEraserPoint = location
        } else if tool == .laser {
            appendLaserSegment(to: point(event))
        } else { current?.points.append(point(event)) }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if tool == .eraser {
            collectErasures(from: previousEraserPoint, to: point(event))
            store.remove(at: pendingErasures)
            pendingErasures.removeAll()
            previousEraserPoint = nil
            needsDisplay = true
        } else if tool == .laser {
            appendLaserSegment(to: point(event))
            previousLaserPoint = nil
            needsDisplay = true
        } else {
            current?.points.append(point(event))
            finishStroke()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        // Consume the exit click; do not forward an accidental context-menu action.
        finishStroke()
        onEscape?()
    }

    override func rightMouseUp(with event: NSEvent) {}

    func finishStroke() {
        if let current { store.append(current) }
        current = nil
        needsDisplay = true
    }

    private func collectErasures(at point: InkPoint) {
        for (index, stroke) in store.strokes.enumerated()
        where StrokeHitTesting.hits(stroke, point: point, tolerance: 9) {
            pendingErasures.insert(index)
        }
    }

    private func collectErasures(from start: InkPoint?, to end: InkPoint) {
        guard let start else { collectErasures(at: end); return }
        let distance = hypot(end.x - start.x, end.y - start.y)
        let steps = max(1, Int(ceil(distance / 4)))
        for step in 1...steps {
            let fraction = Double(step) / Double(steps)
            collectErasures(at: InkPoint(x: start.x + (end.x - start.x) * fraction,
                y: start.y + (end.y - start.y) * fraction))
        }
    }

    private func appendLaserSegment(to end: InkPoint) {
        guard let start = previousLaserPoint else { previousLaserPoint = end; return }
        laserSegments.append(Stroke(points: [start, end], color: color,
            width: max(4, penWidth * 1.5), createdAt: ProcessInfo.processInfo.systemUptime,
            fadeAfter: 0, fadeDuration: 0.65))
        previousLaserPoint = end
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
        let time = ProcessInfo.processInfo.systemUptime
        if inkVisible {
            for (index, stroke) in store.strokes.enumerated() where !pendingErasures.contains(index) {
                render(stroke, at: time, in: context)
            }
            if let current { render(current, at: time, in: context) }
            for segment in laserSegments { render(segment, at: time, in: context) }
        }
        if cursorHaloEnabled, let cursorPoint { renderCursorHalo(at: cursorPoint, in: context) }
    }

    func refreshFading(at time: Double) {
        let hadLaserSegments = !laserSegments.isEmpty
        laserSegments.removeAll { $0.visibleOpacity(at: time) <= 0 }
        let isAnimating = store.strokes.contains(where: { $0.isActivelyFading(at: time) })
        if isAnimating || wasAnimatingFade || hadLaserSegments { needsDisplay = true }
        wasAnimatingFade = isAnimating
    }

    private func render(_ stroke: Stroke, at time: Double, in context: CGContext) {
        guard let first = stroke.points.first else { return }
        let visibleOpacity = stroke.visibleOpacity(at: time)
        guard visibleOpacity > 0 else { return }
        let color = NSColor(
            srgbRed: CGFloat((stroke.color >> 16) & 255) / 255,
            green: CGFloat((stroke.color >> 8) & 255) / 255,
            blue: CGFloat(stroke.color & 255) / 255, alpha: visibleOpacity
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


    private func renderCursorHalo(at point: NSPoint, in context: CGContext) {
        let rect = CGRect(x: point.x - 18, y: point.y - 18, width: 36, height: 36)
        context.setFillColor(NSColor.systemYellow.withAlphaComponent(0.2).cgColor)
        context.fillEllipse(in: rect)
        context.setStrokeColor(NSColor.systemYellow.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: rect.insetBy(dx: 1, dy: 1))
    }
}
