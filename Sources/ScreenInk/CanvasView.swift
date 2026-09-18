import AppKit
import InkCore

enum DrawingTool: String, CaseIterable {
    case select
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

private struct ClickRipple {
    var point: InkPoint
    var startedAt: Double
}

@MainActor
final class CanvasView: NSView, NSTextFieldDelegate {
    var store = StrokeStore()
    var color: UInt32 = 0xFF453A
    var penWidth: Double = 4
    var fontSize: Double = 28
    var fontStyleID = TextFontCatalog.defaultID
    var textAlignment: InkTextAlignment = .left
    var tool: DrawingTool = .pen {
        didSet {
            if oldValue == .text && tool != .text { commitTextEditing() }
            if oldValue == .select && tool != .select {
                finishSelectionTransform()
                selectedAnnotationIndices.removeAll()
                selectionPreviews.removeAll()
                boardIsSelected = false
                boardTransformPreview = nil
                needsDisplay = true
            }
            activateToolCursor()
        }
    }
    var fadingInkEnabled = false
    var fadeDelay: Double = 5
    var boardStyle: BoardStyle = .screen { didSet { needsDisplay = true } }
    var boardRegion: CGRect? { didSet { needsDisplay = true } }
    var inkVisible = true { didSet { needsDisplay = true } }
    var cursorHaloEnabled = false { didSet { needsDisplay = true } }
    var cursorPoint: NSPoint? { didSet { if cursorHaloEnabled { needsDisplay = true } } }
    var onEscape: (() -> Void)?
    var onBoardChanged: (() -> Void)?
    var onScreenshotRegionSelected: ((CGRect) -> Void)?
    private var current: Stroke?
    private var activeDrawingConstraint: CGRect?
    private var pendingErasures: Set<Int> = []
    private var previousEraserPoint: InkPoint?
    private var laserSamples: [LaserSample] = []
    private var laserIsActive = false
    private var clickRipples: [ClickRipple] = []
    var activeLaserSegmentCount: Int { laserSamples.count }
    var activeClickRippleCount: Int { clickRipples.count }
    var showsLaserHead: Bool { laserIsActive }
    private var wasAnimatingFade = false
    private var textEditor: NSTextField?
    private var editingTextIndex: Int?
    private var editingTextStyle: (color: UInt32, fontSize: Double, fontStyleID: String,
        textAlignment: InkTextAlignment, createdAt: Double, fadeAfter: Double?)?
    private var editingTextOrigin: InkPoint?
    private var selectedAnnotationIndices: Set<Int> = []
    private var selectionPreviews: [Int: Stroke] = [:]
    private var selectionDragStart: InkPoint?
    private var selectionOriginals: [Int: Stroke] = [:]
    private var selectionGroupBounds: InkBounds?
    private var resizingHandle: Int?
    private var selectionDidTransform = false
    private var marqueeStart: InkPoint?
    private var marqueePreview: CGRect?
    private var boardIsSelected = false
    private var boardTransformOriginal: CGRect?
    private var boardTransformPreview: CGRect?
    private var pendingBoardStyle: BoardStyle?
    private var boardSelectionStart: InkPoint?
    private var boardSelectionPreview: CGRect?
    private var screenshotSelectionStart: InkPoint?
    private var screenshotSelectionPreview: CGRect?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: activeToolCursor)
    }

    override func cursorUpdate(with event: NSEvent) {
        activeToolCursor.set()
    }

    var activeToolCursor: NSCursor {
        pendingBoardStyle == nil && screenshotSelectionStart == nil && screenshotSelectionPreview == nil
            ? ToolCursorFactory.cursor(for: tool) : .crosshair
    }

    func activateToolCursor() {
        window?.invalidateCursorRects(for: self)
        activeToolCursor.set()
    }

    func showClickAnimation(at point: InkPoint, time: Double = ProcessInfo.processInfo.systemUptime) {
        clickRipples.append(ClickRipple(point: point, startedAt: time))
        if clickRipples.count > 8 { clickRipples.removeFirst(clickRipples.count - 8) }
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        let location = point(event)
        if screenshotSelectionPreview != nil {
            screenshotSelectionStart = location
            screenshotSelectionPreview = CGRect(x: location.x, y: location.y, width: 0, height: 0)
        } else if pendingBoardStyle != nil {
            boardSelectionStart = location
            boardSelectionPreview = CGRect(x: location.x, y: location.y, width: 0, height: 0)
        } else if tool == .select {
            beginSelection(at: location)
        } else if tool == .text {
            beginTextEditing(at: location)
        } else if tool == .eraser {
            pendingErasures.removeAll()
            collectErasures(at: location)
            previousEraserPoint = location
        } else if tool == .laser {
            activeDrawingConstraint = drawingConstraint(startingAt: location, strokeWidth: penWidth)
            let point = constrainedDrawingPoint(location)
            laserIsActive = true
            laserSamples.append(LaserSample(point: point,
                timestamp: ProcessInfo.processInfo.systemUptime))
        } else if let kind = shapeKind {
            activeDrawingConstraint = drawingConstraint(startingAt: location, strokeWidth: penWidth)
            let point = constrainedDrawingPoint(location)
            current = Stroke(points: [point, point], color: color, width: penWidth,
                createdAt: ProcessInfo.processInfo.systemUptime,
                fadeAfter: fadingInkEnabled ? fadeDelay : nil, kind: kind)
        } else {
            let width = tool == .highlighter ? max(14, penWidth * 4) : penWidth
            let opacity = tool == .highlighter ? 0.28 : 1
            activeDrawingConstraint = drawingConstraint(startingAt: location, strokeWidth: width)
            current = Stroke(points: [constrainedDrawingPoint(location)], color: color,
                width: width, opacity: opacity,
                createdAt: ProcessInfo.processInfo.systemUptime,
                fadeAfter: fadingInkEnabled ? fadeDelay : nil)
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        if screenshotSelectionPreview != nil {
            updateScreenshotSelection(to: point(event))
        } else if pendingBoardStyle != nil {
            updateBoardSelection(to: point(event))
        } else if tool == .select {
            updateSelection(to: point(event))
        } else if tool == .text {
            return
        } else if tool == .eraser {
            let location = point(event)
            collectErasures(from: previousEraserPoint, to: location)
            previousEraserPoint = location
        } else if tool == .laser {
            appendLaserSamples(to: point(event))
        } else if shapeKind != nil {
            updateShape(to: point(event), shiftPressed: event.modifierFlags.contains(.shift))
        } else {
            appendCurrentPoint(constrainedDrawingPoint(point(event)))
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if screenshotSelectionPreview != nil {
            updateScreenshotSelection(to: point(event))
            finishScreenshotSelection()
        } else if pendingBoardStyle != nil {
            updateBoardSelection(to: point(event))
            finishBoardSelection()
        } else if tool == .select {
            updateSelection(to: point(event))
            finishSelectionTransform()
        } else if tool == .text {
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
            activeDrawingConstraint = nil
            needsDisplay = true
        } else if shapeKind != nil {
            updateShape(to: point(event), shiftPressed: event.modifierFlags.contains(.shift))
            finishStroke()
        } else {
            appendCurrentPoint(constrainedDrawingPoint(point(event)), force: true)
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
        activeDrawingConstraint = nil
        laserIsActive = false
        needsDisplay = true
    }

    private func appendCurrentPoint(_ point: InkPoint, force: Bool = false) {
        guard var activeStroke = current else { return }
        let minimumDistance = max(0.75, min(2, activeStroke.width * 0.2))
        StrokePointSampling.append(point, to: &activeStroke.points,
            minimumDistance: minimumDistance, force: force)
        current = activeStroke
    }

    func deactivateInteraction() {
        finishSelectionTransform()
        selectedAnnotationIndices.removeAll()
        selectionPreviews.removeAll()
        boardIsSelected = false
        boardTransformOriginal = nil
        boardTransformPreview = nil
        selectionOriginals.removeAll()
        selectionGroupBounds = nil
        marqueeStart = nil
        marqueePreview = nil
        pendingBoardStyle = nil
        boardSelectionStart = nil
        boardSelectionPreview = nil
        screenshotSelectionStart = nil
        screenshotSelectionPreview = nil
        activeDrawingConstraint = nil
        window?.invalidateCursorRects(for: self)
        needsDisplay = true
    }

    func setBoard(_ style: BoardStyle, region: CGRect? = nil) {
        boardStyle = style
        boardRegion = style == .screen ? nil : region
        pendingBoardStyle = nil
        boardSelectionStart = nil
        boardSelectionPreview = nil
        boardIsSelected = false
        boardTransformOriginal = nil
        boardTransformPreview = nil
        selectedAnnotationIndices.removeAll()
        selectionPreviews.removeAll()
        window?.invalidateCursorRects(for: self)
        onBoardChanged?()
    }

    func beginBoardRegionSelection(_ style: BoardStyle) {
        guard style != .screen else { setBoard(.screen); return }
        pendingBoardStyle = style
        boardSelectionStart = nil
        boardSelectionPreview = nil
        boardIsSelected = false
        selectedAnnotationIndices.removeAll()
        selectionPreviews.removeAll()
        window?.invalidateCursorRects(for: self)
        NSCursor.crosshair.set()
        needsDisplay = true
    }

    func beginScreenshotRegionSelection() {
        finishStroke()
        pendingBoardStyle = nil
        boardSelectionStart = nil
        boardSelectionPreview = nil
        screenshotSelectionStart = nil
        screenshotSelectionPreview = .zero
        activateToolCursor()
        needsDisplay = true
    }

    private func updateScreenshotSelection(to point: InkPoint) {
        guard let start = screenshotSelectionStart else { return }
        screenshotSelectionPreview = CGRect(x: min(start.x, point.x), y: min(start.y, point.y),
            width: abs(point.x - start.x), height: abs(point.y - start.y))
        needsDisplay = true
    }

    private func finishScreenshotSelection() {
        guard let preview = screenshotSelectionPreview else { return }
        screenshotSelectionStart = nil
        screenshotSelectionPreview = nil
        activateToolCursor()
        needsDisplay = true
        if preview.width >= 20, preview.height >= 20 {
            onScreenshotRegionSelected?(preview.intersection(bounds))
        }
    }

    private func updateBoardSelection(to point: InkPoint) {
        guard let start = boardSelectionStart else { return }
        boardSelectionPreview = CGRect(x: min(start.x, point.x), y: min(start.y, point.y),
            width: abs(point.x - start.x), height: abs(point.y - start.y))
        needsDisplay = true
    }

    private func finishBoardSelection() {
        guard let style = pendingBoardStyle, let preview = boardSelectionPreview else { return }
        if preview.width >= 120, preview.height >= 80 {
            setBoard(style, region: preview.intersection(bounds))
        } else {
            pendingBoardStyle = nil
            boardSelectionStart = nil
            boardSelectionPreview = nil
            window?.invalidateCursorRects(for: self)
            needsDisplay = true
        }
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
        let editorFontStyleID = existing?.fontStyleID ?? fontStyleID
        let editorTextAlignment = existing?.textAlignment ?? textAlignment
        let editorFont = TextFontCatalog.font(id: editorFontStyleID, size: editorFontSize)
        let field = NSTextField(frame: .zero)
        field.stringValue = existing?.text ?? ""
        field.placeholderAttributedString = NSAttributedString(string: "Type here…", attributes: [
            .font: editorFont,
            .foregroundColor: nsColor(editorColor, alpha: 0.62)
        ])
        field.font = editorFont
        field.textColor = nsColor(editorColor, alpha: 1)
        field.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.96)
        field.drawsBackground = true
        field.isBezeled = false
        field.focusRingType = .none
        field.cell?.usesSingleLineMode = true
        field.cell?.isScrollable = true
        field.alignment = nsTextAlignment(editorTextAlignment)
        field.wantsLayer = true
        field.layer?.cornerRadius = 9
        field.layer?.borderWidth = 2
        field.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.85).cgColor
        field.layer?.shadowColor = NSColor.black.cgColor
        field.layer?.shadowOpacity = 0.2
        field.layer?.shadowRadius = 8
        field.layer?.shadowOffset = CGSize(width: 0, height: -2)
        field.toolTip = "Type text, press Return to save, or Escape to cancel"
        field.setAccessibilityHelp("Type text. Press Return to save or Escape to cancel.")
        field.delegate = self
        field.target = self
        field.action = #selector(commitTextAction)
        addSubview(field)
        textEditor = field
        editingTextIndex = existingIndex
        editingTextOrigin = origin
        editingTextStyle = (editorColor, editorFontSize, editorFontStyleID, editorTextAlignment,
            existing?.createdAt ?? ProcessInfo.processInfo.systemUptime,
            existing?.fadeAfter ?? (fadingInkEnabled ? fadeDelay : nil))
        window?.makeFirstResponder(field)
        field.currentEditor()?.selectedRange = NSRange(location: 0, length: field.stringValue.utf16.count)
        resizeTextEditor()
    }

    @objc private func commitTextAction() { commitTextEditing() }

    private func commitTextEditing() {
        guard let field = textEditor else { return }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let origin = editingTextOrigin ?? InkPoint(x: field.frame.minX, y: field.frame.minY)
        let style = editingTextStyle ?? (color, fontSize, fontStyleID, textAlignment,
            ProcessInfo.processInfo.systemUptime, fadingInkEnabled ? fadeDelay : nil)
        if !value.isEmpty {
            let annotation = Stroke(points: [origin], color: style.color, width: 1,
                createdAt: style.createdAt, fadeAfter: style.fadeAfter,
                kind: .text, text: value, fontSize: style.fontSize,
                fontStyleID: style.fontStyleID, textAlignment: style.textAlignment)
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
        editingTextOrigin = nil
    }

    private func resizeTextEditor() {
        guard let field = textEditor, var origin = editingTextOrigin else { return }
        let size = editingTextStyle?.fontSize ?? fontSize
        let styleID = editingTextStyle?.fontStyleID ?? fontStyleID
        let measured = (field.stringValue as NSString).size(withAttributes: [
            .font: TextFontCatalog.font(id: styleID, size: size)
        ])
        let width = min(700, max(360, measured.width + 34))
        let height = max(44, size * 1.65)
        let alignment = editingTextStyle?.textAlignment ?? textAlignment
        let proposedX = switch alignment {
        case .left: origin.x
        case .center: origin.x - width / 2
        case .right: origin.x - width
        }
        let frameX = min(max(10, proposedX), max(10, Double(bounds.width) - width - 10))
        origin.x = switch alignment {
        case .left: frameX
        case .center: frameX + width / 2
        case .right: frameX + width
        }
        origin.y = min(max(10, origin.y), max(10, Double(bounds.height) - height - 10))
        editingTextOrigin = origin
        field.frame = NSRect(x: frameX, y: origin.y, width: width, height: height)
    }

    private func beginSelection(at location: InkPoint) {
        selectionPreviews.removeAll()
        selectionOriginals.removeAll()
        selectionGroupBounds = nil
        marqueeStart = nil
        marqueePreview = nil
        boardTransformPreview = nil
        selectionDidTransform = false
        if boardIsSelected {
            let rect = activeBoardRect
            if let handle = rectCorners(rect).firstIndex(where: {
                hypot($0.x - location.x, $0.y - location.y) <= 10
            }) {
                boardTransformOriginal = rect
                selectionDragStart = location
                resizingHandle = handle
                captureBoardContents(in: rect)
                return
            }
        }
        if !selectedAnnotationIndices.isEmpty,
            let bounds = annotationBounds(for: selectedAnnotationIndices) {
            let handles = selectionHandles(for: selectedAnnotationIndices, bounds: bounds)
            if let handle = handles.firstIndex(where: {
                hypot($0.x - location.x, $0.y - location.y) <= 10
            }) {
                selectionOriginals = selectedAnnotationIndices.reduce(into: [:]) {
                    if store.strokes.indices.contains($1) { $0[$1] = store.strokes[$1] }
                }
                selectionGroupBounds = bounds
                selectionDragStart = location
                resizingHandle = handle
                return
            }
        }
        if let index = store.strokes.indices.reversed().first(where: {
            isSelectable(store.strokes[$0]) && selectionHit(store.strokes[$0], at: location)
        }) {
            boardIsSelected = false
            boardTransformOriginal = nil
            if !selectedAnnotationIndices.contains(index) { selectedAnnotationIndices = [index] }
            selectionOriginals = selectedAnnotationIndices.reduce(into: [:]) {
                if store.strokes.indices.contains($1) { $0[$1] = store.strokes[$1] }
            }
            selectionGroupBounds = annotationBounds(for: selectedAnnotationIndices)
            selectionDragStart = location
            resizingHandle = nil
            return
        }
        selectedAnnotationIndices.removeAll()
        selectionOriginals.removeAll()
        resizingHandle = nil
        if boardStyle != .screen, boardFrameContains(location) {
            boardIsSelected = true
            boardTransformOriginal = activeBoardRect
            selectionDragStart = location
            captureBoardContents(in: activeBoardRect)
        } else {
            boardIsSelected = false
            boardTransformOriginal = nil
            selectionDragStart = location
            marqueeStart = location
            marqueePreview = CGRect(x: location.x, y: location.y, width: 0, height: 0)
        }
    }

    private func updateSelection(to location: InkPoint) {
        guard let start = selectionDragStart else { return }
        let distance = hypot(location.x - start.x, location.y - start.y)
        guard distance >= 0.5 else { return }
        if let marqueeStart {
            marqueePreview = CGRect(x: min(marqueeStart.x, location.x),
                y: min(marqueeStart.y, location.y), width: abs(location.x - marqueeStart.x),
                height: abs(location.y - marqueeStart.y))
            needsDisplay = true
            return
        }
        selectionDidTransform = true
        if let originalRect = boardTransformOriginal, boardIsSelected {
            if let handle = resizingHandle {
                boardTransformPreview = resizedBoardRect(originalRect, handle: handle, to: location)
            } else {
                boardTransformPreview = clampedBoardRect(originalRect.offsetBy(
                    dx: location.x - start.x, dy: location.y - start.y))
            }
            updateBoardContentPreviews(from: originalRect, to: boardTransformPreview!)
            needsDisplay = true
            return
        }
        guard !selectionOriginals.isEmpty else { return }
        if let handle = resizingHandle {
            if selectionOriginals.count == 1, let (index, original) = selectionOriginals.first,
                original.kind == .line || original.kind == .arrow || original.kind == .text {
                selectionPreviews[index] = AnnotationGeometry.resized(original,
                    handle: handle, to: location)
            } else if let source = selectionGroupBounds {
                let target = resizedBounds(source, handle: handle, to: location)
                selectionPreviews = selectionOriginals.mapValues {
                    AnnotationGeometry.transformed($0, from: source, to: target)
                }
            }
        } else {
            selectionPreviews = selectionOriginals.mapValues {
                AnnotationGeometry.moved($0, dx: location.x - start.x, dy: location.y - start.y)
            }
        }
        needsDisplay = true
    }

    private func finishSelectionTransform() {
        if let marquee = marqueePreview, marquee.width >= 3, marquee.height >= 3 {
            selectedAnnotationIndices = Set(store.strokes.indices.filter { index in
                guard let bounds = AnnotationGeometry.bounds(of: store.strokes[index]) else { return false }
                return marquee.intersects(bounds.cgRect)
            })
        }
        if selectionDidTransform, boardIsSelected, let preview = boardTransformPreview {
            boardRegion = preview
            if !selectionPreviews.isEmpty { store.replace(selectionPreviews) }
            onBoardChanged?()
        }
        if selectionDidTransform, !boardIsSelected, !selectionPreviews.isEmpty {
            store.replace(selectionPreviews)
        }
        selectionPreviews.removeAll()
        boardTransformPreview = nil
        boardTransformOriginal = nil
        selectionOriginals.removeAll()
        selectionGroupBounds = nil
        selectionDragStart = nil
        resizingHandle = nil
        selectionDidTransform = false
        marqueeStart = nil
        marqueePreview = nil
        needsDisplay = true
    }

    @discardableResult
    func applyColorToSelection(_ newColor: UInt32) -> Bool {
        let replacements = selectedAnnotationIndices.reduce(into: [Int: Stroke]()) { result, index in
            guard store.strokes.indices.contains(index) else { return }
            var stroke = store.strokes[index]
            stroke.color = newColor
            result[index] = stroke
        }
        guard !replacements.isEmpty else { return false }
        store.replace(replacements)
        needsDisplay = true
        return true
    }

    @discardableResult
    func applyFontToSelection(_ newFontStyleID: String) -> Bool {
        let replacements = selectedAnnotationIndices.reduce(into: [Int: Stroke]()) { result, index in
            guard store.strokes.indices.contains(index), store.strokes[index].kind == .text else { return }
            var stroke = store.strokes[index]
            stroke.fontStyleID = newFontStyleID
            result[index] = stroke
        }
        guard !replacements.isEmpty else { return false }
        store.replace(replacements)
        needsDisplay = true
        return true
    }

    @discardableResult
    func applyTextAlignmentToSelection(_ alignment: InkTextAlignment) -> Bool {
        let replacements = selectedAnnotationIndices.reduce(into: [Int: Stroke]()) { result, index in
            guard store.strokes.indices.contains(index), store.strokes[index].kind == .text else { return }
            var stroke = store.strokes[index]
            stroke.textAlignment = alignment
            result[index] = stroke
        }
        guard !replacements.isEmpty else { return false }
        store.replace(replacements)
        needsDisplay = true
        return true
    }

    private func isSelectable(_ stroke: Stroke) -> Bool {
        true
    }

    private func selectionHit(_ stroke: Stroke, at point: InkPoint) -> Bool {
        if stroke.kind == .freehand || stroke.kind == .line || stroke.kind == .arrow {
            return StrokeHitTesting.hits(stroke, point: point, tolerance: 10)
        }
        return AnnotationGeometry.bounds(of: stroke)?.contains(point, padding: 6) ?? false
    }

    private func selectionHandles(for stroke: Stroke) -> [InkPoint] {
        if stroke.kind == .line || stroke.kind == .arrow {
            guard let first = stroke.points.first, let last = stroke.points.last else { return [] }
            return [first, last]
        }
        guard let bounds = AnnotationGeometry.bounds(of: stroke) else { return [] }
        if stroke.kind == .text { return [bounds.corners[2]] }
        return bounds.corners
    }

    private func selectionHandles(for indices: Set<Int>, bounds: InkBounds) -> [InkPoint] {
        if indices.count == 1, let index = indices.first, store.strokes.indices.contains(index) {
            return selectionHandles(for: store.strokes[index])
        }
        return bounds.corners
    }

    private func annotationBounds(for indices: Set<Int>) -> InkBounds? {
        let bounds: [InkBounds] = indices.compactMap { index in
            store.strokes.indices.contains(index) ? AnnotationGeometry.bounds(of: store.strokes[index]) : nil
        }
        return bounds.reduce(Optional<InkBounds>.none) { partial, next in
            guard let partial else { return next }
            return InkBounds(minX: min(partial.minX, next.minX), minY: min(partial.minY, next.minY),
                maxX: max(partial.maxX, next.maxX), maxY: max(partial.maxY, next.maxY))
        }
    }

    private func resizedBounds(_ bounds: InkBounds, handle: Int, to point: InkPoint) -> InkBounds {
        let opposite = bounds.corners[(handle + 2) % 4]
        let minX = min(opposite.x, point.x)
        let minY = min(opposite.y, point.y)
        return InkBounds(minX: minX, minY: minY,
            maxX: max(max(opposite.x, point.x), minX + 1),
            maxY: max(max(opposite.y, point.y), minY + 1))
    }

    private func boardFrameContains(_ point: InkPoint) -> Bool {
        let outer = activeBoardRect
        let frameWidth: CGFloat = boardStyle == .whiteboard ? 10 : 16
        let expanded = outer.insetBy(dx: -6, dy: -6)
        let inner = outer.insetBy(dx: frameWidth + 3, dy: frameWidth + 3)
        let cgPoint = CGPoint(x: point.x, y: point.y)
        return expanded.contains(cgPoint) && !inner.contains(cgPoint)
    }

    private func captureBoardContents(in rect: CGRect) {
        selectionOriginals = store.strokes.indices.reduce(into: [:]) { result, index in
            guard let bounds = AnnotationGeometry.bounds(of: store.strokes[index]) else { return }
            let center = CGPoint(x: (bounds.minX + bounds.maxX) / 2,
                y: (bounds.minY + bounds.maxY) / 2)
            if rect.contains(center) { result[index] = store.strokes[index] }
        }
    }

    private func updateBoardContentPreviews(from source: CGRect, to target: CGRect) {
        let sourceBounds = InkBounds(source)
        let targetBounds = InkBounds(target)
        selectionPreviews = selectionOriginals.mapValues {
            AnnotationGeometry.transformed($0, from: sourceBounds, to: targetBounds)
        }
    }

    private var activeBoardRect: CGRect {
        boardTransformPreview ?? boardRegion ?? bounds.insetBy(dx: 28, dy: 28)
    }

    private var boardWritingRect: CGRect? {
        guard boardStyle != .screen else { return nil }
        let frameWidth: CGFloat = boardStyle == .whiteboard ? 10 : 16
        let rect = activeBoardRect.insetBy(dx: frameWidth, dy: frameWidth)
        return rect.width > 0 && rect.height > 0 ? rect : nil
    }

    private func drawingConstraint(startingAt point: InkPoint, strokeWidth: Double) -> CGRect? {
        guard let writingRect = boardWritingRect,
            writingRect.contains(CGPoint(x: point.x, y: point.y)) else { return nil }
        let margin = max(1, strokeWidth / 2)
        let constrained = writingRect.insetBy(dx: margin, dy: margin)
        return constrained.width > 0 && constrained.height > 0 ? constrained : writingRect
    }

    private func constrainedDrawingPoint(_ point: InkPoint) -> InkPoint {
        guard let rect = activeDrawingConstraint else { return point }
        return InkPoint(x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY))
    }

    private func rectCorners(_ rect: CGRect) -> [InkPoint] {
        [InkPoint(x: rect.minX, y: rect.minY), InkPoint(x: rect.maxX, y: rect.minY),
            InkPoint(x: rect.maxX, y: rect.maxY), InkPoint(x: rect.minX, y: rect.maxY)]
    }

    private func resizedBoardRect(_ rect: CGRect, handle: Int, to point: InkPoint) -> CGRect {
        let corners = rectCorners(rect)
        guard corners.indices.contains(handle) else { return rect }
        let opposite = corners[(handle + 2) % 4]
        let width = max(120, abs(point.x - opposite.x))
        let height = max(80, abs(point.y - opposite.y))
        let target = CGRect(x: point.x >= opposite.x ? opposite.x : opposite.x - width,
            y: point.y >= opposite.y ? opposite.y : opposite.y - height,
            width: width, height: height)
        return clampedBoardRect(target)
    }

    private func clampedBoardRect(_ rect: CGRect) -> CGRect {
        let width = min(rect.width, bounds.width)
        let height = min(rect.height, bounds.height)
        return CGRect(x: min(max(bounds.minX, rect.minX), bounds.maxX - width),
            y: min(max(bounds.minY, rect.minY), bounds.maxY - height),
            width: width, height: height)
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
        let rawPoint = constrainedDrawingPoint(rawPoint)
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
        let endpoint = ShapeGeometry.constrainedEnd(start: start,
            proposed: constrainedDrawingPoint(proposed), kind: current.kind,
            shiftPressed: shiftPressed)
        current.points = [start, constrainedDrawingPoint(endpoint)]
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

    func controlTextDidChange(_ notification: Notification) { resizeTextEditor() }

    private func point(_ event: NSEvent) -> InkPoint {
        let p = convert(event.locationInWindow, from: nil)
        return InkPoint(x: p.x, y: p.y)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(dirtyRect)
        renderBoard(in: context)
        let time = ProcessInfo.processInfo.systemUptime
        if inkVisible {
            for (index, stroke) in store.strokes.enumerated() where !pendingErasures.contains(index) {
                render(selectionPreviews[index] ?? stroke, at: time, in: context)
            }
            if let current { render(current, at: time, in: context) }
            renderLaserTrail(at: time, in: context)
            if tool == .select, !selectedAnnotationIndices.isEmpty {
                renderSelection(for: selectedAnnotationIndices, in: context)
            }
            if tool == .select, boardIsSelected, boardStyle != .screen {
                renderBoardTransformSelection(activeBoardRect, in: context)
            }
        }
        renderClickRipples(at: time, in: context)
        if cursorHaloEnabled, let cursorPoint { renderCursorHalo(at: cursorPoint, in: context) }
        if let preview = boardSelectionPreview { renderBoardSelection(preview, in: context) }
        if let preview = screenshotSelectionPreview, screenshotSelectionStart != nil {
            renderScreenshotSelection(preview, in: context)
        }
        if let marqueePreview { renderMarquee(marqueePreview, in: context) }
    }

    private func renderBoard(in context: CGContext) {
        guard boardStyle != .screen else { return }
        let outer = activeBoardRect.intersection(bounds)
        guard outer.width >= 60, outer.height >= 60 else { return }
        let frameWidth: CGFloat = boardStyle == .whiteboard ? 10 : 16
        let cornerRadius: CGFloat = boardStyle == .whiteboard ? 18 : 14
        let outerPath = CGPath(roundedRect: outer, cornerWidth: cornerRadius,
            cornerHeight: cornerRadius, transform: nil)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -7), blur: 16,
            color: NSColor.black.withAlphaComponent(0.34).cgColor)
        context.addPath(outerPath)
        context.setFillColor((boardStyle == .whiteboard ?
            NSColor(srgbRed: 0.68, green: 0.70, blue: 0.73, alpha: 1) :
            NSColor(srgbRed: 0.34, green: 0.19, blue: 0.10, alpha: 1)).cgColor)
        context.fillPath()
        context.restoreGState()

        let frameColors: [CGColor] = boardStyle == .whiteboard ? [
            NSColor(srgbRed: 0.94, green: 0.95, blue: 0.96, alpha: 1).cgColor,
            NSColor(srgbRed: 0.54, green: 0.57, blue: 0.61, alpha: 1).cgColor,
            NSColor(srgbRed: 0.82, green: 0.84, blue: 0.86, alpha: 1).cgColor
        ] : [
            NSColor(srgbRed: 0.50, green: 0.30, blue: 0.17, alpha: 1).cgColor,
            NSColor(srgbRed: 0.25, green: 0.12, blue: 0.065, alpha: 1).cgColor,
            NSColor(srgbRed: 0.42, green: 0.23, blue: 0.12, alpha: 1).cgColor
        ]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: frameColors as CFArray, locations: [0, 0.52, 1]) {
            context.saveGState()
            context.addPath(outerPath)
            context.clip()
            context.drawLinearGradient(gradient,
                start: CGPoint(x: outer.minX, y: outer.maxY),
                end: CGPoint(x: outer.maxX, y: outer.minY), options: [])
            if boardStyle == .blackboard {
                context.setStrokeColor(NSColor.white.withAlphaComponent(0.055).cgColor)
                context.setLineWidth(1)
                for offset in stride(from: outer.minX - outer.height, through: outer.maxX, by: 18) {
                    context.move(to: CGPoint(x: offset, y: outer.minY))
                    context.addLine(to: CGPoint(x: offset + outer.height, y: outer.maxY))
                }
                context.strokePath()
            }
            context.restoreGState()
        }

        let inner = outer.insetBy(dx: frameWidth, dy: frameWidth)
        let innerPath = CGPath(roundedRect: inner,
            cornerWidth: max(5, cornerRadius - frameWidth / 2),
            cornerHeight: max(5, cornerRadius - frameWidth / 2), transform: nil)
        context.addPath(innerPath)
        context.setFillColor((boardStyle.backgroundColor ?? .clear).cgColor)
        context.fillPath()
        context.addPath(innerPath)
        context.setStrokeColor(NSColor.black.withAlphaComponent(0.18).cgColor)
        context.setLineWidth(1)
        context.strokePath()

        let trayWidth = min(190, outer.width * 0.34)
        let tray = CGRect(x: outer.midX - trayWidth / 2, y: outer.minY + 3,
            width: trayWidth, height: boardStyle == .whiteboard ? 6 : 8)
        context.setFillColor((boardStyle == .whiteboard ?
            NSColor(srgbRed: 0.66, green: 0.68, blue: 0.71, alpha: 1) :
            NSColor(srgbRed: 0.24, green: 0.115, blue: 0.06, alpha: 1)).cgColor)
        context.fill(CGRect(x: tray.minX, y: tray.minY, width: tray.width, height: tray.height))
        context.setFillColor(NSColor.white.withAlphaComponent(0.22).cgColor)
        context.fill(CGRect(x: tray.minX, y: tray.maxY - 1, width: tray.width, height: 1))
    }

    private func renderBoardSelection(_ rect: CGRect, in context: CGContext) {
        context.saveGState()
        context.setFillColor(NSColor.systemCyan.withAlphaComponent(0.10).cgColor)
        context.fill(rect)
        context.setStrokeColor(NSColor.systemCyan.cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [8, 5])
        context.stroke(rect)
        context.restoreGState()
    }

    private func renderBoardTransformSelection(_ rect: CGRect, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(NSColor.systemCyan.withAlphaComponent(0.98).cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [7, 5])
        context.stroke(rect.insetBy(dx: -4, dy: -4))
        context.setLineDash(phase: 0, lengths: [])
        for handle in rectCorners(rect) {
            let handleRect = CGRect(x: handle.x - 6, y: handle.y - 6, width: 12, height: 12)
            context.setFillColor(NSColor.white.cgColor)
            context.fillEllipse(in: handleRect)
            context.setStrokeColor(NSColor.systemCyan.cgColor)
            context.strokeEllipse(in: handleRect.insetBy(dx: 1, dy: 1))
        }
        context.restoreGState()
    }

    func refreshFading(at time: Double) {
        let hadLaserSegments = !laserSamples.isEmpty
        let hadClickRipples = !clickRipples.isEmpty
        laserSamples.removeAll { time - $0.timestamp >= 1 }
        clickRipples.removeAll { time - $0.startedAt >= 0.5 }
        let isAnimating = store.strokes.contains(where: { $0.isActivelyFading(at: time) })
        let removedExpiredInk = store.removeExpiredFadingStrokes(at: time) > 0
        if isAnimating || wasAnimatingFade || hadLaserSegments || hadClickRipples || removedExpiredInk {
            needsDisplay = true
        }
        wasAnimatingFade = isAnimating
    }

    private func renderClickRipples(at time: Double, in context: CGContext) {
        for ripple in clickRipples {
            let progress = max(0, min(1, (time - ripple.startedAt) / 0.5))
            let eased = 1 - pow(1 - progress, 3)
            let radius = 7 + 24 * eased
            let alpha = 0.9 * pow(1 - progress, 1.7)
            let rect = CGRect(x: ripple.point.x - radius, y: ripple.point.y - radius,
                width: radius * 2, height: radius * 2)
            context.saveGState()
            context.setStrokeColor(NSColor.systemCyan.withAlphaComponent(alpha).cgColor)
            context.setLineWidth(max(1.5, 4 * (1 - progress)))
            context.strokeEllipse(in: rect)
            if progress < 0.22 {
                let centerRadius = 5 * (1 - progress / 0.22)
                context.setFillColor(NSColor.white.withAlphaComponent(alpha * 0.75).cgColor)
                context.fillEllipse(in: CGRect(x: ripple.point.x - centerRadius,
                    y: ripple.point.y - centerRadius, width: centerRadius * 2,
                    height: centerRadius * 2))
            }
            context.restoreGState()
        }
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
            let font = TextFontCatalog.font(id: stroke.fontStyleID, size: stroke.fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor(cgColor: color) ?? .white
            ]
            let width = (text as NSString).size(withAttributes: attributes).width
            let x = switch stroke.textAlignment {
            case .left: first.x
            case .center: first.x - width / 2
            case .right: first.x - width
            }
            (text as NSString).draw(at: NSPoint(x: x, y: first.y), withAttributes: attributes)
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

    private func nsTextAlignment(_ alignment: InkTextAlignment) -> NSTextAlignment {
        switch alignment {
        case .left: .left
        case .center: .center
        case .right: .right
        }
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

    private func renderSelection(_ stroke: Stroke, in context: CGContext) {
        guard let bounds = AnnotationGeometry.bounds(of: stroke) else { return }
        context.saveGState()
        context.setStrokeColor(NSColor.systemCyan.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(1.5)
        context.setLineDash(phase: 0, lengths: [5, 4])
        context.stroke(CGRect(x: bounds.minX - 5, y: bounds.minY - 5,
            width: bounds.width + 10, height: bounds.height + 10))
        context.setLineDash(phase: 0, lengths: [])
        for handle in selectionHandles(for: stroke) {
            let rect = CGRect(x: handle.x - 5, y: handle.y - 5, width: 10, height: 10)
            context.setFillColor(NSColor.white.cgColor)
            context.fillEllipse(in: rect)
            context.setStrokeColor(NSColor.systemCyan.cgColor)
            context.strokeEllipse(in: rect.insetBy(dx: 0.75, dy: 0.75))
        }
        context.restoreGState()
    }

    private func renderSelection(for indices: Set<Int>, in context: CGContext) {
        if indices.count == 1, let index = indices.first, store.strokes.indices.contains(index) {
            renderSelection(selectionPreviews[index] ?? store.strokes[index], in: context)
            return
        }
        let strokes = indices.compactMap { selectionPreviews[$0] ??
            (store.strokes.indices.contains($0) ? store.strokes[$0] : nil) }
        guard let first = strokes.first.flatMap(AnnotationGeometry.bounds) else { return }
        let bounds = strokes.dropFirst().compactMap(AnnotationGeometry.bounds).reduce(first) { result, next in
            InkBounds(minX: min(result.minX, next.minX), minY: min(result.minY, next.minY),
                maxX: max(result.maxX, next.maxX), maxY: max(result.maxY, next.maxY))
        }
        renderSelectionBounds(bounds, handles: bounds.corners, in: context)
    }

    private func renderSelectionBounds(_ bounds: InkBounds, handles: [InkPoint], in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(NSColor.systemCyan.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(1.5)
        context.setLineDash(phase: 0, lengths: [5, 4])
        context.stroke(CGRect(x: bounds.minX - 5, y: bounds.minY - 5,
            width: bounds.width + 10, height: bounds.height + 10))
        context.setLineDash(phase: 0, lengths: [])
        for handle in handles {
            let rect = CGRect(x: handle.x - 5, y: handle.y - 5, width: 10, height: 10)
            context.setFillColor(NSColor.white.cgColor)
            context.fillEllipse(in: rect)
            context.setStrokeColor(NSColor.systemCyan.cgColor)
            context.strokeEllipse(in: rect.insetBy(dx: 0.75, dy: 0.75))
        }
        context.restoreGState()
    }

    private func renderMarquee(_ rect: CGRect, in context: CGContext) {
        context.saveGState()
        context.setFillColor(NSColor.systemCyan.withAlphaComponent(0.08).cgColor)
        context.fill(rect)
        context.setStrokeColor(NSColor.systemCyan.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 3])
        context.stroke(rect)
        context.restoreGState()
    }

    private func renderScreenshotSelection(_ rect: CGRect, in context: CGContext) {
        context.saveGState()
        context.setFillColor(NSColor.black.withAlphaComponent(0.16).cgColor)
        context.fill(bounds)
        context.setBlendMode(.clear)
        context.fill(rect)
        context.setBlendMode(.normal)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [7, 5])
        context.stroke(rect.insetBy(dx: 1, dy: 1))
        context.restoreGState()
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
