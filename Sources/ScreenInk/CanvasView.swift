import AppKit
import InkCore

enum DrawingTool: String, CaseIterable {
    case pen
    case highlighter
    case eraser
    case laser
    case line
    case arrow
    case rectangle
    case ellipse
    case diamond
    case text
}

private struct LaserSample {
    var point: InkPoint
    var timestamp: Double
}

@MainActor
final class CanvasView: NSView, NSTextFieldDelegate {
    var store = StrokeStore()
    var color: UInt32 = 0xFF453A
    var penWidth: Double = 4
    var fontSize: Double = 28
    var tool: DrawingTool = .pen {
        didSet { if oldValue == .text && tool != .text { commitTextEditing() } }
    }
    var fadingInkEnabled = false
    var fadeDelay: Double = 5
    var inkVisible = true { didSet { needsDisplay = true } }
    var cursorHaloEnabled = false { didSet { needsDisplay = true } }
    var cursorPoint: NSPoint? { didSet { if cursorHaloEnabled { needsDisplay = true } } }
    var onEscape: (() -> Void)?
    private var current: Stroke?
    private var pendingErasures: Set<Int> = []
    private var previousEraserPoint: InkPoint?
    private var laserSamples: [LaserSample] = []
    private var laserIsActive = false
    var activeLaserSegmentCount: Int { laserSamples.count }
    var showsLaserHead: Bool { laserIsActive }
    private var wasAnimatingFade = false
    private var textEditor: NSTextField?
    private var editingTextIndex: Int?
    private var editingTextStyle: (color: UInt32, fontSize: Double, createdAt: Double, fadeAfter: Double?)?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        let location = point(event)
        if tool == .text {
            beginTextEditing(at: location)
        } else if tool == .eraser {
            pendingErasures.removeAll()
            collectErasures(at: location)
            previousEraserPoint = location
        } else if tool == .laser {
            laserIsActive = true
            laserSamples.append(LaserSample(point: location,
                timestamp: ProcessInfo.processInfo.systemUptime))
        } else if let kind = shapeKind {
            current = Stroke(points: [location, location], color: color, width: penWidth,
                createdAt: ProcessInfo.processInfo.systemUptime,
                fadeAfter: fadingInkEnabled ? fadeDelay : nil, kind: kind)
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
        if tool == .text {
            return
        } else if tool == .eraser {
            let location = point(event)
            collectErasures(from: previousEraserPoint, to: location)
            previousEraserPoint = location
        } else if tool == .laser {
            appendLaserSamples(to: point(event))
        } else if shapeKind != nil {
            updateShape(to: point(event), shiftPressed: event.modifierFlags.contains(.shift))
        } else { current?.points.append(point(event)) }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if tool == .text {
            return
        } else if tool == .eraser {
            collectErasures(from: previousEraserPoint, to: point(event))
            store.remove(at: pendingErasures)
            pendingErasures.removeAll()
            previousEraserPoint = nil
            needsDisplay = true
        } else if tool == .laser {
            appendLaserSamples(to: point(event))
            laserIsActive = false
            needsDisplay = true
        } else if shapeKind != nil {
            updateShape(to: point(event), shiftPressed: event.modifierFlags.contains(.shift))
            finishStroke()
        } else {
            current?.points.append(point(event))
            finishStroke()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        // Consume the exit click; do not forward an accidental context-menu action.
        laserIsActive = false
        finishStroke()
        onEscape?()
    }

    override func rightMouseUp(with event: NSEvent) {}

    func finishStroke() {
        commitTextEditing()
        if var current {
            if tool == .pen, current.kind == .freehand,
                let recognized = ShapeRecognizer.recognize(points: current.points) {
                current.kind = recognized.kind
                current.points = [recognized.start, recognized.end]
            }
            store.append(current)
        }
        current = nil
        laserIsActive = false
        needsDisplay = true
    }

    private func beginTextEditing(at location: InkPoint) {
        commitTextEditing()
        let existingIndex = store.strokes.indices.reversed().first {
            store.strokes[$0].kind == .text
                && StrokeHitTesting.hits(store.strokes[$0], point: location, tolerance: 6)
        }
        let existing = existingIndex.map { store.strokes[$0] }
        let origin = existing?.points.first ?? location
        let editorFontSize = existing?.fontSize ?? fontSize
        let editorColor = existing?.color ?? color
        let field = NSTextField(frame: NSRect(x: origin.x, y: origin.y,
            width: max(240, Double(existing?.text?.count ?? 0) * editorFontSize * 0.62 + 24),
            height: editorFontSize * 1.5))
        field.stringValue = existing?.text ?? ""
        field.font = .systemFont(ofSize: editorFontSize, weight: .medium)
        field.textColor = nsColor(editorColor, alpha: 1)
        field.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.88)
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.focusRingType = .exterior
        field.delegate = self
        field.target = self
        field.action = #selector(commitTextAction)
        addSubview(field)
        textEditor = field
        editingTextIndex = existingIndex
        editingTextStyle = (editorColor, editorFontSize,
            existing?.createdAt ?? ProcessInfo.processInfo.systemUptime,
            existing?.fadeAfter ?? (fadingInkEnabled ? fadeDelay : nil))
        window?.makeFirstResponder(field)
        field.currentEditor()?.selectedRange = NSRange(location: 0, length: field.stringValue.utf16.count)
    }

    @objc private func commitTextAction() { commitTextEditing() }

    private func commitTextEditing() {
        guard let field = textEditor else { return }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let origin = InkPoint(x: field.frame.minX, y: field.frame.minY)
        let style = editingTextStyle ?? (color, fontSize,
            ProcessInfo.processInfo.systemUptime, fadingInkEnabled ? fadeDelay : nil)
        if !value.isEmpty {
            let annotation = Stroke(points: [origin], color: style.color, width: 1,
                createdAt: style.createdAt, fadeAfter: style.fadeAfter,
                kind: .text, text: value, fontSize: style.fontSize)
            if let index = editingTextIndex { store.replace(at: index, with: annotation) }
            else { store.append(annotation) }
        }
        clearTextEditor()
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    private func cancelTextEditing() {
        clearTextEditor()
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    private func clearTextEditor() {
        textEditor?.removeFromSuperview()
        textEditor = nil
        editingTextIndex = nil
        editingTextStyle = nil
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

    private func appendLaserSamples(to rawPoint: InkPoint) {
        let now = ProcessInfo.processInfo.systemUptime
        guard let last = laserSamples.last else {
            laserSamples.append(LaserSample(point: rawPoint, timestamp: now))
            return
        }
        let distance = hypot(rawPoint.x - last.point.x, rawPoint.y - last.point.y)
        guard distance >= 1 else { return }
        // Excalidraw's decay length is measured in input points, not pixels.
        laserSamples.append(LaserSample(point: rawPoint, timestamp: now))
    }

    private var shapeKind: StrokeKind? {
        switch tool {
        case .line: .line
        case .arrow: .arrow
        case .rectangle: .rectangle
        case .ellipse: .ellipse
        case .diamond: .diamond
        default: nil
        }
    }

    private func updateShape(to proposed: InkPoint, shiftPressed: Bool) {
        guard var current, let start = current.points.first else { return }
        current.points = [start, ShapeGeometry.constrainedEnd(start: start, proposed: proposed,
            kind: current.kind, shiftPressed: shiftPressed)]
        self.current = current
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

    func control(_ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            commitTextEditing()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            cancelTextEditing()
            onEscape?()
            return true
        }
        return false
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
            renderLaserTrail(at: time, in: context)
        }
        if cursorHaloEnabled, let cursorPoint { renderCursorHalo(at: cursorPoint, in: context) }
    }

    func refreshFading(at time: Double) {
        let hadLaserSegments = !laserSamples.isEmpty
        laserSamples.removeAll { time - $0.timestamp >= 1 }
        let isAnimating = store.strokes.contains(where: { $0.isActivelyFading(at: time) })
        if isAnimating || wasAnimatingFade || hadLaserSegments { needsDisplay = true }
        wasAnimatingFade = isAnimating
    }

    private func renderLaserTrail(at time: Double, in context: CGContext) {
        guard laserSamples.count > 1 else { return }
        let laserColor = NSColor(srgbRed: 1, green: 0.18, blue: 0.33, alpha: 1)
        let baseWidth = max(5, penWidth * 1.6)
        var leftEdge: [CGPoint] = []
        var rightEdge: [CGPoint] = []
        for index in laserSamples.indices {
            let sample = laserSamples[index]
            let strength = LaserTrailMath.strength(age: time - sample.timestamp,
                pointsFromHead: Double(laserSamples.count - 1 - index))
            let previous = laserSamples[max(0, index - 1)].point
            let next = laserSamples[min(laserSamples.count - 1, index + 1)].point
            let dx = next.x - previous.x
            let dy = next.y - previous.y
            let length = max(0.001, hypot(dx, dy))
            let halfWidth = baseWidth * strength / 2
            let normalX = -dy / length * halfWidth
            let normalY = dx / length * halfWidth
            leftEdge.append(CGPoint(x: sample.point.x + normalX, y: sample.point.y + normalY))
            rightEdge.append(CGPoint(x: sample.point.x - normalX, y: sample.point.y - normalY))
        }
        guard let first = leftEdge.first else { return }
        let outline = CGMutablePath()
        outline.move(to: first)
        for point in leftEdge.dropFirst() { outline.addLine(to: point) }
        for point in rightEdge.reversed() { outline.addLine(to: point) }
        outline.closeSubpath()
        context.setFillColor(laserColor.withAlphaComponent(0.95).cgColor)
        context.addPath(outline)
        context.fillPath()

        // A round head is useful while pointing, but is removed on mouse-up so
        // the final fade cannot collapse into an isolated dot.
        if laserIsActive, let head = laserSamples.last {
            let strength = LaserTrailMath.strength(age: time - head.timestamp, pointsFromHead: 0)
            let diameter = baseWidth * strength
            context.fillEllipse(in: CGRect(x: head.point.x - diameter / 2,
                y: head.point.y - diameter / 2, width: diameter, height: diameter))
        }
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
        if stroke.kind == .text, let text = stroke.text {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: stroke.fontSize, weight: .medium),
                .foregroundColor: NSColor(cgColor: color) ?? .white
            ]
            (text as NSString).draw(at: NSPoint(x: first.x, y: first.y), withAttributes: attributes)
            return
        }
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(stroke.width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        if stroke.kind == .freehand && stroke.points.allSatisfy({ $0 == first }) {
            context.fillEllipse(in: CGRect(x: first.x - stroke.width / 2,
                y: first.y - stroke.width / 2, width: stroke.width, height: stroke.width))
        } else {
            let path = StrokeHitTesting.pathPoints(for: stroke)
            guard let pathStart = path.first else { return }
            context.beginPath()
            context.move(to: CGPoint(x: pathStart.x, y: pathStart.y))
            for point in path.dropFirst() { context.addLine(to: CGPoint(x: point.x, y: point.y)) }
            context.strokePath()
            if stroke.kind == .arrow { renderArrowHead(stroke, in: context) }
        }
    }

    private func nsColor(_ hex: UInt32, alpha: Double) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }

    private func renderArrowHead(_ stroke: Stroke, in context: CGContext) {
        guard let start = stroke.points.first, let end = stroke.points.last else { return }
        let head = ShapeGeometry.arrowHead(start: start, end: end, width: stroke.width)
        guard let first = head.first else { return }
        context.beginPath()
        context.move(to: CGPoint(x: first.x, y: first.y))
        for point in head.dropFirst() { context.addLine(to: CGPoint(x: point.x, y: point.y)) }
        context.strokePath()
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
