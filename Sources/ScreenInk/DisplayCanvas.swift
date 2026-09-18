import AppKit

@MainActor
final class DisplayCanvas {
    let window: InkPanel
    let canvas = CanvasView()
    init(screen: NSScreen) {
        window = InkPanel(contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.title = "ScreenInk Canvas — \(screen.localizedName)"
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        canvas.frame = NSRect(origin: .zero, size: screen.frame.size)
        canvas.autoresizingMask = [.width, .height]
        canvas.setAccessibilityElement(true)
        canvas.setAccessibilityRole(.group)
        canvas.setAccessibilityLabel("ScreenInk canvas: normal mode")
        window.contentView = canvas
    }
    func setDrawing(_ enabled: Bool) {
        canvas.finishStroke()
        if !enabled { canvas.deactivateInteraction() }
        window.ignoresMouseEvents = !enabled
        canvas.setAccessibilityLabel(enabled ? "ScreenInk canvas: drawing mode" : "ScreenInk canvas: normal mode")
        if enabled {
            canvas.activateToolCursor()
        } else {
            window.resignKey()
            NSCursor.arrow.set()
        }
    }
}

extension NSScreen {
    var cgDisplayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! NSNumber).uint32Value
    }

    var inkDisplayID: String {
        let number = cgDisplayID
        if let uuid = CGDisplayCreateUUIDFromDisplayID(number)?.takeRetainedValue() {
            return CFUUIDCreateString(nil, uuid) as String
        }
        return "display-\(number)"
    }
}
