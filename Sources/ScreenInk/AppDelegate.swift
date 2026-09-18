import AppKit
import InkCore

@MainActor
final class InkPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var overlay: InkPanel!
    private var toolbar: ToolbarPanel!
    private var statusItem: NSStatusItem!
    private let canvas = CanvasView()
    private var modeButton: NSButton!
    private var autoHideButton: NSButton!
    private var autoHideItem: NSMenuItem!
    private var swatches: [ColorButton] = []
    private let colors: [UInt32] = [0xFF453A, 0xFFD60A, 0x30D158, 0x0A84FF, 0xBF5AF2, 0xFFFFFF]
    private var drawing = false
    private var widthIndex = 1
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
        overlay = InkPanel(contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        overlay.title = "ScreenInk Canvas"
        overlay.backgroundColor = .clear
        overlay.isOpaque = false
        overlay.hasShadow = false
        overlay.hidesOnDeactivate = false
        overlay.level = .floating
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlay.ignoresMouseEvents = true
        canvas.frame = CGRect(origin: .zero, size: screen.frame.size)
        canvas.autoresizingMask = [.width, .height]
        canvas.setAccessibilityElement(true)
        canvas.setAccessibilityRole(.group)
        canvas.setAccessibilityLabel("ScreenInk canvas: normal mode")
        canvas.onEscape = { [weak self] in self?.setDrawing(false) }
        overlay.contentView = canvas
        overlay.orderFrontRegardless()
        createToolbar(on: screen)
        createMenu()
        visibility.show(now: now)
        timer = Timer(timeInterval: 0.15, target: self, selector: #selector(trackPointer), userInfo: nil, repeats: true)
        timer?.tolerance = 0.05
        RunLoop.main.add(timer!, forMode: .common)
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
        toolbar.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
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
        modeButton = icon("pencil.tip.crop.circle", "Draw / Normal mode (Escape)", #selector(toggleDrawing))
        row.addArrangedSubview(modeButton)
        divider(in: row)
        let names = ["Red", "Yellow", "Green", "Blue", "Purple", "White"]
        for (index, hex) in colors.enumerated() {
            let button = ColorButton()
            button.inkColor = NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
            button.tag = index
            button.isBordered = false
            button.title = ""
            button.selected = index == 0
            button.toolTip = names[index]
            button.setAccessibilityLabel("\(names[index]) ink")
            button.target = self
            button.action = #selector(changeColor(_:))
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            swatches.append(button)
            row.addArrangedSubview(button)
        }
        divider(in: row)
        row.addArrangedSubview(icon("lineweight", "Pen width: Medium — click to cycle", #selector(changeWidth(_:))))
        row.addArrangedSubview(icon("arrow.uturn.backward", "Undo", #selector(undo)))
        row.addArrangedSubview(icon("arrow.uturn.forward", "Redo", #selector(redo)))
        row.addArrangedSubview(icon("trash", "Clear drawing", #selector(clear)))
        divider(in: row)
        autoHideButton = icon("eye", "Toggle auto-hide (2 seconds)", #selector(toggleAutoHide))
        row.addArrangedSubview(autoHideButton)
        row.addArrangedSubview(icon("chevron.up", "Hide toolbar — hover at top-center to show", #selector(hideToolbar)))
        toolbar.contentView = background
        background.layoutSubtreeIfNeeded()
        toolbar.setContentSize(NSSize(width: row.fittingSize.width + 20, height: 54))
        restorePosition(on: screen)
        updateAutoHideControls()
        toolbar.orderFrontRegardless()
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
            ("Toggle Drawing", #selector(toggleDrawing)), ("Clear Drawing", #selector(clear)),
            ("Quit ScreenInk", #selector(quit))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            if action == #selector(toggleAutoHide) { autoHideItem = item }
        }
        statusItem.menu = menu
        updateAutoHideControls()
    }

    private func setDrawing(_ enabled: Bool) {
        canvas.finishStroke()
        drawing = enabled
        canvas.setAccessibilityLabel(enabled ? "ScreenInk canvas: drawing mode" : "ScreenInk canvas: normal mode")
        overlay.ignoresMouseEvents = !enabled
        modeButton.contentTintColor = enabled ? .systemCyan : .white
        modeButton.setAccessibilityValue(enabled ? "Drawing" : "Normal")
        if enabled {
            overlay.makeKeyAndOrderFront(nil)
            overlay.makeFirstResponder(canvas)
        } else {
            overlay.resignKey()
        }
        showToolbar()
    }

    private func atTopEdge(_ point: NSPoint) -> Bool {
        guard let screen = toolbar.screen ?? NSScreen.screens.first else { return false }
        return abs(point.x - screen.visibleFrame.midX) <= 160
            && point.y >= screen.visibleFrame.maxY - 8 && point.y <= screen.frame.maxY
    }

    @objc private func trackPointer() {
        let pointer = NSEvent.mouseLocation
        let wasVisible = visibility.isVisible
        visibility.update(now: now, toolbarHovered: toolbar.frame.insetBy(dx: -8, dy: -8).contains(pointer),
            topEdgeHovered: atTopEdge(pointer), interacting: NSEvent.pressedMouseButtons != 0, autoHide: autoHide)
        if wasVisible != visibility.isVisible {
            if visibility.isVisible { toolbar.orderFrontRegardless() } else { toolbar.orderOut(nil) }
        }
    }

    @objc private func showToolbar() { visibility.show(now: now); toolbar.orderFrontRegardless() }
    @objc private func hideToolbar() {
        // Manual hiding also releases input so the user can immediately return to work.
        if drawing { setDrawing(false) }
        visibility.hide(topEdgeHovered: atTopEdge(NSEvent.mouseLocation))
        toolbar.orderOut(nil)
    }
    @objc private func toggleAutoHide() { autoHide.toggle(); updateAutoHideControls(); showToolbar() }
    private func updateAutoHideControls() {
        autoHideItem?.state = autoHide ? .on : .off
        autoHideButton?.contentTintColor = autoHide ? .systemCyan : .white
        autoHideButton?.setAccessibilityValue(autoHide ? "On" : "Off")
    }
    @objc private func toggleDrawing() { setDrawing(!drawing) }
    @objc private func changeColor(_ sender: NSButton) {
        canvas.color = colors[sender.tag]
        for (index, button) in swatches.enumerated() { button.selected = index == sender.tag }
    }
    @objc private func changeWidth(_ sender: NSButton) {
        widthIndex = (widthIndex + 1) % 3
        canvas.penWidth = [2, 4, 8][widthIndex]
        let label = "Pen width: \(["Thin", "Medium", "Thick"][widthIndex]) — click to cycle"
        sender.toolTip = label
        sender.setAccessibilityLabel(label)
    }
    @objc private func undo() { canvas.finishStroke(); canvas.store.undo(); canvas.needsDisplay = true }
    @objc private func redo() { canvas.finishStroke(); canvas.store.redo(); canvas.needsDisplay = true }
    @objc private func clear() { canvas.finishStroke(); canvas.store.clear(); canvas.needsDisplay = true }
    @objc private func quit() { NSApp.terminate(nil) }

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
        guard let screen = NSScreen.screens.first else { return }
        overlay.setFrame(screen.frame, display: true)
        restorePosition(on: screen)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showToolbar()
        return true
    }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate() }
}
