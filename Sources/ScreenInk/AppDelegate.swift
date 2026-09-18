import AppKit
import InkCore
import QuartzCore

@MainActor
final class InkPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var displays = DisplayRegistry<DisplayCanvas>()
    private var selectedColor: UInt32 = 0xBF5AF2
    private var toolbar: ToolbarPanel!
    private var statusItem: NSStatusItem!
    private var normalButton: NSButton!
    private var modeButton: NSButton!
    private var highlighterButton: NSButton!
    private var eraserButton: NSButton!
    private var laserButton: NSButton!
    private var shapeButton: NSButton!
    private var textButton: NSButton!
    private var fontSizeButton: NSButton!
    private var paletteButton: NSButton!
    private var fadingButton: NSButton!
    private var haloButton: NSButton!
    private var inkVisibilityButton: NSButton!
    private let palettePopover = NSPopover()
    private let shapePopover = NSPopover()
    private var autoHideButton: NSButton!
    private var autoHideItem: NSMenuItem!
    private var swatches: [ColorButton] = []
    private var paletteSwatches: [ColorButton] = []
    private let colors: [UInt32] = [
        0xBF5AF2, 0xFF453A, 0xFFD60A, 0x30D158, 0x0A84FF, 0xFFFFFF,
        0xFF9F0A, 0xFF375F, 0x64D2FF, 0x5E5CE6, 0xAC8E68, 0x8E8E93,
        0x7D3CFF, 0xD70015, 0xFFB340, 0x00A83B, 0x007AFF, 0xE5E5EA,
        0x5B2C6F, 0x8B1A1A, 0x8A6D00, 0x1F6B3A, 0x003F88, 0x1C1C1E
    ]
    private var drawing = false
    private var widthIndex = 1
    private var fontSizeIndex = 1
    private var selectedTool: DrawingTool = .pen
    private var fadingInkEnabled = false
    private var fadeDelay: Double = 5
    private var cursorHaloEnabled = false
    private var inkVisible = true
    private var shortcutChoice = HotKeyChoice.choices[2]
    private var hotKey: GlobalHotKey?
    private var visibility = ToolbarVisibility(now: ProcessInfo.processInfo.systemUptime)
    private var timer: Timer?
    private var autoHide: Bool {
        get { UserDefaults.standard.object(forKey: "toolbarAutoHide") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "toolbarAutoHide") }
    }
    private var now: Double { ProcessInfo.processInfo.systemUptime }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard let screen = NSScreen.screens.first else { NSApp.terminate(nil); return }
        restoreDrawingPreferences()
        reconcileDisplays()
        createToolbar(on: screen)
        createMenu()
        hotKey = GlobalHotKey { [weak self] in self?.toggleDrawingState() }
        hotKey?.register(shortcutChoice)
        visibility.show(now: now)
        configurePointerTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(displayChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    private func createToolbar(on screen: NSScreen) {
        toolbar = ToolbarPanel(contentRect: NSRect(x: 0, y: 0, width: 544, height: 54),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        toolbar.title = "ScreenInk Toolbar"
        toolbar.isOpaque = false
        toolbar.backgroundColor = .clear
        toolbar.hasShadow = true
        toolbar.hidesOnDeactivate = false
        toolbar.level = .statusBar
        toolbar.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        toolbar.delegate = self
        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: toolbar.frame.size))
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.appearance = NSAppearance(named: .darkAqua)
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.layer?.masksToBounds = true
        background.layer?.borderWidth = 1
        background.layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor
        let row = NSStackView()
        row.spacing = 4
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 10),
            row.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -10),
            row.centerYAnchor.constraint(equalTo: background.centerYAnchor)
        ])
        let handle = DragHandle(frame: .zero)
        handle.toolTip = "Drag to move toolbar"
        handle.setAccessibilityElement(true)
        handle.setAccessibilityLabel("Move toolbar")
        handle.widthAnchor.constraint(equalToConstant: 22).isActive = true
        handle.heightAnchor.constraint(equalToConstant: 34).isActive = true
        handle.didDrag = { [weak self] in self?.savePosition() }
        row.addArrangedSubview(handle)
        normalButton = icon("cursorarrow", "Normal mode — interact with apps (Escape or right-click)",
            #selector(selectNormal))
        row.addArrangedSubview(normalButton)
        modeButton = icon("pencil.tip", "Pen — draw permanent ink", #selector(selectPen))
        row.addArrangedSubview(modeButton)
        highlighterButton = icon("highlighter", "Highlighter — broad translucent ink", #selector(selectHighlighter))
        row.addArrangedSubview(highlighterButton)
        eraserButton = icon("eraser", "Whole-stroke eraser", #selector(selectEraser))
        row.addArrangedSubview(eraserButton)
        laserButton = icon("laser.burst", "Laser pointer — progressive fading trail", #selector(selectLaser))
        row.addArrangedSubview(laserButton)
        shapeButton = icon("square.on.circle", "Shapes: line, arrow, rectangle, ellipse, diamond", #selector(showShapes(_:)))
        row.addArrangedSubview(shapeButton)
        createShapePicker()
        textButton = icon("textformat", "Text — click canvas to type", #selector(selectText))
        row.addArrangedSubview(textButton)
        divider(in: row)
        let names = ["Purple", "Red", "Yellow", "Green", "Blue", "White"]
        for (index, hex) in colors.enumerated() {
            guard index < 6 else { break }
            let button = ColorButton()
            button.inkColor = color(hex)
            button.tag = index
            button.isBordered = false
            button.title = ""
            button.selected = hex == selectedColor
            button.toolTip = names[index]
            button.setAccessibilityLabel("\(names[index]) ink")
            button.target = self
            button.action = #selector(changeColor(_:))
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            swatches.append(button)
            row.addArrangedSubview(button)
        }
        paletteButton = icon("paintpalette", "Open 24-color palette", #selector(showPalette(_:)))
        row.addArrangedSubview(paletteButton)
        createPalette()
        divider(in: row)
        row.addArrangedSubview(icon("lineweight", "Pen width: Medium — click to cycle", #selector(changeWidth(_:))))
        fontSizeButton = icon("textformat.size",
            "Text size: \(Int([20, 28, 40, 56][fontSizeIndex])) pt — click to cycle",
            #selector(changeFontSize(_:)))
        row.addArrangedSubview(fontSizeButton)
        row.addArrangedSubview(icon("arrow.uturn.backward", "Undo on toolbar display", #selector(undo)))
        row.addArrangedSubview(icon("arrow.uturn.forward", "Redo on toolbar display", #selector(redo)))
        row.addArrangedSubview(icon("trash", "Clear drawing on toolbar display", #selector(clear)))
        divider(in: row)
        fadingButton = icon("timer", "Toggle fading ink", #selector(toggleFadingInk))
        row.addArrangedSubview(fadingButton)
        haloButton = icon("cursorarrow.rays", "Toggle cursor halo", #selector(toggleCursorHalo))
        row.addArrangedSubview(haloButton)
        inkVisibilityButton = icon("eye.slash", "Show / hide ink", #selector(toggleInkVisibility))
        row.addArrangedSubview(inkVisibilityButton)
        divider(in: row)
        autoHideButton = icon("eye", "Toggle auto-hide (2 seconds)", #selector(toggleAutoHide))
        row.addArrangedSubview(autoHideButton)
        row.addArrangedSubview(icon("chevron.up", "Hide toolbar — hover at top-center to show", #selector(hideToolbar)))
        toolbar.contentView = background
        background.layoutSubtreeIfNeeded()
        toolbar.setContentSize(NSSize(width: row.fittingSize.width + 20, height: 54))
        restorePosition(on: screen)
        updateAutoHideControls()
        updateToolControls()
        updatePresentationControls()
        presentToolbar()
    }

    private func icon(_ symbol: String, _ label: String, _ action: Selector) -> NSButton {
        ScreenInkIcons.button(symbol, label: label, target: self, action: action)
    }

    private func divider(in row: NSStackView) {
        let line = NSBox()
        line.boxType = .separator
        line.widthAnchor.constraint(equalToConstant: 1).isActive = true
        line.heightAnchor.constraint(equalToConstant: 22).isActive = true
        row.addArrangedSubview(line)
    }

    private func createMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = ScreenInkIcons.menuBar()
        statusItem.button?.toolTip = "ScreenInk — screen annotation"
        statusItem.button?.setAccessibilityLabel("ScreenInk")
        let menu = NSMenu()
        for (title, action) in [("Show Toolbar", #selector(showToolbar)), ("Hide Toolbar", #selector(hideToolbar)),
            ("Reset Toolbar to Top Center", #selector(resetPosition)), ("Auto-hide Toolbar", #selector(toggleAutoHide)),
            ("Toggle Drawing", #selector(toggleDrawingState)), ("Clear Drawing on Toolbar Display", #selector(clear)),
            ("Show / Hide Ink", #selector(toggleInkVisibility))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            if action == #selector(toggleAutoHide) { autoHideItem = item }
        }
        menu.addItem(.separator())
        let fadingItem = NSMenuItem(title: "Fading Ink", action: #selector(toggleFadingInk), keyEquivalent: "")
        fadingItem.target = self
        menu.addItem(fadingItem)
        let fadeMenu = NSMenu(title: "Fade Delay")
        for seconds in [2, 5, 10] {
            let item = NSMenuItem(title: "\(seconds) seconds", action: #selector(changeFadeDelay(_:)), keyEquivalent: "")
            item.target = self
            item.tag = seconds
            item.state = Double(seconds) == fadeDelay ? .on : .off
            fadeMenu.addItem(item)
        }
        let fadeRoot = NSMenuItem(title: "Fade Delay", action: nil, keyEquivalent: "")
        fadeRoot.submenu = fadeMenu
        menu.addItem(fadeRoot)
        let haloItem = NSMenuItem(title: "Cursor Halo", action: #selector(toggleCursorHalo), keyEquivalent: "")
        haloItem.target = self
        menu.addItem(haloItem)
        let shortcutMenu = NSMenu(title: "Global Shortcut")
        for choice in HotKeyChoice.choices {
            let item = NSMenuItem(title: choice.title, action: #selector(changeShortcut(_:)), keyEquivalent: "")
            item.target = self
            item.tag = choice.id
            item.state = choice == shortcutChoice ? .on : .off
            shortcutMenu.addItem(item)
        }
        let shortcutRoot = NSMenuItem(title: "Global Drawing Shortcut", action: nil, keyEquivalent: "")
        shortcutRoot.submenu = shortcutMenu
        menu.addItem(shortcutRoot)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit ScreenInk", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        updateAutoHideControls()
    }

    private func createPalette() {
        let controller = NSViewController()
        let grid = NSGridView()
        grid.rowSpacing = 6
        grid.columnSpacing = 6
        var rows: [[NSView]] = []
        for rowIndex in 0..<4 {
            rows.append((0..<6).map { columnIndex in
                let index = rowIndex * 6 + columnIndex
                let button = ColorButton()
                let hex = colors[index]
                button.inkColor = color(hex)
                button.tag = index
                button.isBordered = false
                button.title = ""
                button.selected = hex == selectedColor
                button.toolTip = "Color \(index + 1)"
                button.setAccessibilityLabel("Ink color \(index + 1)")
                button.target = self
                button.action = #selector(changePaletteColor(_:))
                button.widthAnchor.constraint(equalToConstant: 30).isActive = true
                button.heightAnchor.constraint(equalToConstant: 30).isActive = true
                paletteSwatches.append(button)
                return button
            })
        }
        for row in rows { grid.addRow(with: row) }
        grid.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 150))
        container.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            grid.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            grid.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        controller.view = container
        controller.preferredContentSize = container.frame.size
        palettePopover.contentViewController = controller
        palettePopover.behavior = .transient
    }

    private func createShapePicker() {
        let controller = NSViewController()
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 6
        let choices: [(String, String, Selector)] = [
            ("line.diagonal", "Line", #selector(selectLine)),
            ("arrow.up.right", "Arrow", #selector(selectArrow)),
            ("rectangle", "Rectangle", #selector(selectRectangle)),
            ("circle", "Ellipse", #selector(selectEllipse)),
            ("diamond", "Diamond", #selector(selectDiamond))
        ]
        for (symbol, label, action) in choices {
            row.addArrangedSubview(icon(symbol, label, action))
        }
        row.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 206, height: 54))
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        controller.view = container
        controller.preferredContentSize = container.frame.size
        shapePopover.contentViewController = controller
        shapePopover.behavior = .transient
    }

    private func color(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }

    private func reconcileDisplays() {
        let screens = NSScreen.screens
        let screenByID = Dictionary(screens.map { ($0.inkDisplayID, $0) }, uniquingKeysWith: { first, _ in first })
        let detached = displays.reconcile(ids: screens.map(\.inkDisplayID)) { id in
            let display = DisplayCanvas(screen: screenByID[id]!)
            display.canvas.onEscape = { [weak self] in self?.setDrawing(false) }
            return display
        }
        for display in detached {
            display.setDrawing(false)
            display.window.orderOut(nil)
        }
        for id in displays.activeIDs {
            guard let display = displays[id], let screen = screenByID[id] else { continue }
            display.canvas.color = selectedColor
            display.canvas.penWidth = [2, 4, 8][widthIndex]
            display.canvas.fontSize = [20, 28, 40, 56][fontSizeIndex]
            display.canvas.tool = selectedTool
            display.canvas.fadingInkEnabled = fadingInkEnabled
            display.canvas.fadeDelay = fadeDelay
            display.canvas.cursorHaloEnabled = cursorHaloEnabled
            display.canvas.inkVisible = inkVisible
            display.window.setFrame(screen.frame, display: true)
            display.setDrawing(drawing)
            display.window.orderFrontRegardless()
        }
    }

    private var actionDisplay: DisplayCanvas? {
        let screen = toolbar?.screen ?? NSScreen.main ?? NSScreen.screens.first
        return screen.flatMap { displays[$0.inkDisplayID] } ?? displays.activeValues.first
    }

    private func setDrawing(_ enabled: Bool) {
        drawing = enabled
        for display in displays.activeValues { display.setDrawing(enabled) }
        normalButton.setAccessibilityValue(enabled ? "Inactive" : "Selected")
        modeButton.setAccessibilityValue(enabled && selectedTool == .pen ? "Selected" : "Inactive")
        if enabled, let display = actionDisplay {
            display.window.makeKeyAndOrderFront(nil)
            display.window.makeFirstResponder(display.canvas)
        }
        updateToolControls()
        configurePointerTimer()
        showToolbar()
    }

    private func topEdgeScreen(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { screen in
            ToolbarGeometry.isRevealPoint(point, frame: screen.frame, visibleFrame: screen.visibleFrame,
                toolbarWidth: toolbar.frame.width, toolbarHeight: toolbar.frame.height)
        }
    }

    private func atTopEdge(_ point: NSPoint) -> Bool { topEdgeScreen(point) != nil }

    @objc private func trackPointer() {
        let pointer = NSEvent.mouseLocation
        let currentTime = now
        for display in displays.activeValues {
            display.canvas.refreshFading(at: currentTime)
            if let screen = display.window.screen, screen.frame.contains(pointer) {
                let windowPoint = display.window.convertPoint(fromScreen: pointer)
                display.canvas.cursorPoint = display.canvas.convert(windowPoint, from: nil)
            } else {
                display.canvas.cursorPoint = nil
            }
        }
        let wasVisible = visibility.isVisible
        visibility.update(now: now, toolbarHovered: toolbar.frame.insetBy(dx: -8, dy: -8).contains(pointer),
            topEdgeHovered: atTopEdge(pointer), interacting: NSEvent.pressedMouseButtons != 0, autoHide: autoHide)
        // A visible toolbar must also follow an edge request on another display.
        // The old transition-only path left it stranded on the previous display.
        if visibility.isVisible {
            var moved = false
            if let screen = topEdgeScreen(pointer), NSEvent.pressedMouseButtons == 0,
               screen.inkDisplayID != toolbar.screen?.inkDisplayID {
                toolbar.setFrameOrigin(centeredOrigin(on: screen))
                savePosition()
                moved = true
            }
            if !wasVisible || !toolbar.isVisible {
                presentToolbar()
            } else if moved || !toolbar.isOnActiveSpace {
                toolbar.orderFrontRegardless()
            }
        } else if toolbar.isVisible {
            toolbar.alphaValue = 1
            toolbar.orderOut(nil)
        }
    }

    private func presentToolbar() {
        guard !toolbar.isVisible else {
            toolbar.alphaValue = 1
            toolbar.orderFrontRegardless()
            return
        }
        let finalOrigin = toolbar.frame.origin
        toolbar.alphaValue = 0
        toolbar.setFrameOrigin(NSPoint(x: finalOrigin.x, y: finalOrigin.y + 12))
        toolbar.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            toolbar.animator().alphaValue = 1
            toolbar.animator().setFrameOrigin(finalOrigin)
        }
    }

    @objc private func showToolbar() { visibility.show(now: now); presentToolbar() }
    @objc private func hideToolbar() {
        // Manual hiding also releases input so the user can immediately return to work.
        if drawing { setDrawing(false) }
        visibility.hide(topEdgeHovered: atTopEdge(NSEvent.mouseLocation))
        toolbar.alphaValue = 1
        toolbar.orderOut(nil)
    }
    @objc private func toggleAutoHide() { autoHide.toggle(); updateAutoHideControls(); showToolbar() }
    private func updateAutoHideControls() {
        autoHideItem?.state = autoHide ? .on : .off
        autoHideButton?.contentTintColor = autoHide ? .systemCyan : .white
        autoHideButton?.setAccessibilityValue(autoHide ? "On" : "Off")
    }
    @objc private func selectNormal() { setDrawing(false) }
    @objc private func selectPen() { selectTool(.pen) }
    @objc private func toggleDrawingState() { setDrawing(!drawing) }
    @objc private func selectHighlighter() { selectTool(.highlighter) }
    @objc private func selectEraser() { selectTool(.eraser) }
    @objc private func selectLaser() { selectTool(.laser) }
    @objc private func selectLine() { selectShape(.line) }
    @objc private func selectArrow() { selectShape(.arrow) }
    @objc private func selectRectangle() { selectShape(.rectangle) }
    @objc private func selectEllipse() { selectShape(.ellipse) }
    @objc private func selectDiamond() { selectShape(.diamond) }
    @objc private func selectText() { selectTool(.text) }
    @objc private func showShapes(_ sender: NSButton) {
        shapePopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }
    private func selectShape(_ tool: DrawingTool) {
        shapePopover.close()
        selectTool(tool)
    }
    private func selectTool(_ tool: DrawingTool) {
        selectedTool = tool
        UserDefaults.standard.set(tool.rawValue, forKey: "drawingTool")
        for display in displays.activeValues { display.canvas.tool = tool }
        setDrawing(true)
        updateToolControls()
    }
    private func updateToolControls() {
        normalButton?.contentTintColor = drawing ? .white : .systemCyan
        modeButton?.contentTintColor = drawing && selectedTool == .pen ? .systemCyan : .white
        highlighterButton?.contentTintColor = drawing && selectedTool == .highlighter ? .systemYellow : .white
        eraserButton?.contentTintColor = drawing && selectedTool == .eraser ? .systemCyan : .white
        laserButton?.contentTintColor = drawing && selectedTool == .laser ? .systemRed : .white
        let shapeTools: Set<DrawingTool> = [.line, .arrow, .rectangle, .ellipse, .diamond]
        shapeButton?.contentTintColor = drawing && shapeTools.contains(selectedTool) ? .systemCyan : .white
        textButton?.contentTintColor = drawing && selectedTool == .text ? .systemCyan : .white
    }
    @objc private func showPalette(_ sender: NSButton) {
        palettePopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }
    @objc private func changePaletteColor(_ sender: NSButton) {
        applyColor(at: sender.tag)
        palettePopover.close()
    }
    @objc private func changeColor(_ sender: NSButton) {
        applyColor(at: sender.tag)
    }
    private func applyColor(at index: Int) {
        guard colors.indices.contains(index) else { return }
        selectedColor = colors[index]
        UserDefaults.standard.set(Int(selectedColor), forKey: "inkColor")
        for display in displays.activeValues { display.canvas.color = selectedColor }
        for (quickIndex, button) in swatches.enumerated() { button.selected = quickIndex == index }
        for (paletteIndex, button) in paletteSwatches.enumerated() { button.selected = paletteIndex == index }
        if selectedTool == .eraser { selectTool(.pen) }
    }
    @objc private func changeWidth(_ sender: NSButton) {
        widthIndex = (widthIndex + 1) % 3
        UserDefaults.standard.set(widthIndex, forKey: "penWidthIndex")
        for display in displays.activeValues { display.canvas.penWidth = [2, 4, 8][widthIndex] }
        let label = "Pen width: \(["Thin", "Medium", "Thick"][widthIndex]) — click to cycle"
        sender.toolTip = label
        sender.setAccessibilityLabel(label)
    }
    @objc private func changeFontSize(_ sender: NSButton) {
        let sizes: [Double] = [20, 28, 40, 56]
        fontSizeIndex = (fontSizeIndex + 1) % sizes.count
        UserDefaults.standard.set(fontSizeIndex, forKey: "fontSizeIndex")
        for display in displays.activeValues { display.canvas.fontSize = sizes[fontSizeIndex] }
        let label = "Text size: \(Int(sizes[fontSizeIndex])) pt — click to cycle"
        sender.toolTip = label
        sender.setAccessibilityLabel(label)
    }
    @objc private func undo() { guard let canvas = actionDisplay?.canvas else { return }; canvas.finishStroke(); canvas.store.undo(); canvas.needsDisplay = true }
    @objc private func redo() { guard let canvas = actionDisplay?.canvas else { return }; canvas.finishStroke(); canvas.store.redo(); canvas.needsDisplay = true }
    @objc private func clear() { guard let canvas = actionDisplay?.canvas else { return }; canvas.finishStroke(); canvas.store.clear(); canvas.needsDisplay = true }
    @objc private func toggleFadingInk() {
        fadingInkEnabled.toggle()
        for display in displays.activeValues { display.canvas.fadingInkEnabled = fadingInkEnabled }
        updatePresentationControls()
    }
    @objc private func changeFadeDelay(_ sender: NSMenuItem) {
        fadeDelay = Double(sender.tag)
        UserDefaults.standard.set(fadeDelay, forKey: "fadeDelay")
        for display in displays.activeValues { display.canvas.fadeDelay = fadeDelay }
        sender.menu?.items.forEach { $0.state = $0 === sender ? .on : .off }
    }
    @objc private func toggleCursorHalo() {
        cursorHaloEnabled.toggle()
        UserDefaults.standard.set(cursorHaloEnabled, forKey: "cursorHaloEnabled")
        for display in displays.activeValues { display.canvas.cursorHaloEnabled = cursorHaloEnabled }
        updatePresentationControls()
        configurePointerTimer()
    }
    @objc private func toggleInkVisibility() {
        inkVisible.toggle()
        for display in displays.activeValues { display.canvas.inkVisible = inkVisible }
        updatePresentationControls()
    }
    @objc private func changeShortcut(_ sender: NSMenuItem) {
        guard let choice = HotKeyChoice.choices.first(where: { $0.id == sender.tag }) else { return }
        shortcutChoice = choice
        UserDefaults.standard.set(choice.id, forKey: "globalShortcut")
        hotKey?.register(choice)
        sender.menu?.items.forEach { $0.state = $0 === sender ? .on : .off }
    }
    private func updatePresentationControls() {
        fadingButton?.contentTintColor = fadingInkEnabled ? .systemCyan : .white
        haloButton?.contentTintColor = cursorHaloEnabled ? .systemCyan : .white
        inkVisibilityButton?.contentTintColor = inkVisible ? .white : .systemOrange
    }

    private func configurePointerTimer() {
        timer?.invalidate()
        let smoothTracking = cursorHaloEnabled || (drawing && selectedTool == .laser)
        let interval = smoothTracking ? 1.0 / 60.0 : 0.05
        timer = Timer(timeInterval: interval, target: self, selector: #selector(trackPointer),
            userInfo: nil, repeats: true)
        timer?.tolerance = smoothTracking ? 0.001 : 0.01
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }
    @objc private func quit() { NSApp.terminate(nil) }

    private func restoreDrawingPreferences() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "inkColor") != nil {
            let saved = UInt32(clamping: defaults.integer(forKey: "inkColor"))
            if colors.contains(saved) { selectedColor = saved }
        }
        if defaults.object(forKey: "penWidthIndex") != nil {
            widthIndex = min(2, max(0, defaults.integer(forKey: "penWidthIndex")))
        }
        if defaults.object(forKey: "fontSizeIndex") != nil {
            fontSizeIndex = min(3, max(0, defaults.integer(forKey: "fontSizeIndex")))
        }
        if let raw = defaults.string(forKey: "drawingTool"), let tool = DrawingTool(rawValue: raw) {
            selectedTool = tool
        }
        // Fading ink is intentionally opt-in for every new app session.
        fadingInkEnabled = false
        defaults.removeObject(forKey: "fadingInkEnabled")
        cursorHaloEnabled = defaults.bool(forKey: "cursorHaloEnabled")
        if defaults.object(forKey: "fadeDelay") != nil {
            let savedDelay = defaults.double(forKey: "fadeDelay")
            if [2.0, 5.0, 10.0].contains(savedDelay) { fadeDelay = savedDelay }
        }
        if let choice = HotKeyChoice.choices.first(where: { $0.id == defaults.integer(forKey: "globalShortcut") }) {
            shortcutChoice = choice
        }
    }

    private func centeredOrigin(on screen: NSScreen) -> NSPoint {
        NSPoint(x: screen.visibleFrame.midX - toolbar.frame.width / 2,
            y: screen.visibleFrame.maxY - toolbar.frame.height - 12)
    }
    private func restorePosition(on fallback: NSScreen) {
        let defaults = UserDefaults.standard
        var origin = centeredOrigin(on: fallback)
        if defaults.object(forKey: "toolbarX") != nil {
            let saved = NSPoint(x: defaults.double(forKey: "toolbarX"), y: defaults.double(forKey: "toolbarY"))
            let rect = NSRect(origin: saved, size: toolbar.frame.size)
            if NSScreen.screens.contains(where: { $0.visibleFrame.contains(rect) }) { origin = saved }
        }
        toolbar.setFrameOrigin(origin)
    }
    private func savePosition() {
        guard let screen = toolbar.screen ?? NSScreen.screens.first else { return }
        let bounds = screen.visibleFrame
        let position = NSPoint(x: max(bounds.minX, min(toolbar.frame.minX, bounds.maxX - toolbar.frame.width)),
            y: max(bounds.minY, min(toolbar.frame.minY, bounds.maxY - toolbar.frame.height)))
        toolbar.setFrameOrigin(position)
        UserDefaults.standard.set(position.x, forKey: "toolbarX")
        UserDefaults.standard.set(position.y, forKey: "toolbarY")
        visibility.show(now: now)
    }
    @objc private func resetPosition() {
        guard let screen = NSScreen.screens.first else { return }
        toolbar.setFrameOrigin(centeredOrigin(on: screen))
        savePosition()
        showToolbar()
    }
    @objc private func displayChanged() {
        setDrawing(false)
        reconcileDisplays()
        guard let screen = NSScreen.screens.first else { return }
        restorePosition(on: screen)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showToolbar()
        return true
    }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate() }
}
