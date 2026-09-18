import AppKit

@MainActor
enum ToolCursorFactory {
    private static var cache: [DrawingTool: NSCursor] = [:]

    static func cursor(for tool: DrawingTool) -> NSCursor {
        if tool == .text { return .iBeam }
        if let cached = cache[tool] { return cached }
        let appearance: (symbol: String, tint: NSColor) = switch tool {
        case .select: ("rectangle.dashed", .systemCyan)
        case .pen: ("pencil.tip", .systemPurple)
        case .highlighter: ("highlighter", .systemYellow)
        case .eraser: ("eraser", .systemPink)
        case .laser: ("laser.burst", .systemRed)
        case .line: ("line.diagonal", .systemCyan)
        case .arrow: ("arrow.up.right", .systemCyan)
        case .rectangle: ("rectangle", .systemCyan)
        case .ellipse: ("circle", .systemCyan)
        case .diamond: ("diamond", .systemCyan)
        case .text: ("textformat", .systemCyan)
        }
        let cursor = NSCursor(image: cursorImage(symbol: appearance.symbol, tint: appearance.tint),
            hotSpot: NSPoint(x: 16, y: 16))
        cache[tool] = cursor
        return cursor
    }

    private static func cursorImage(symbol: String, tint: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 32, height: 32), flipped: false) { rect in
            NSColor.black.withAlphaComponent(0.82).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2)).fill()
            NSColor.white.withAlphaComponent(0.9).setStroke()
            let border = NSBezierPath(ovalIn: rect.insetBy(dx: 2.5, dy: 2.5))
            border.lineWidth = 1
            border.stroke()

            let configuration = NSImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
                .applying(NSImage.SymbolConfiguration(paletteColors: [tint]))
            if let icon = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration) {
                icon.draw(in: NSRect(x: 7, y: 7, width: 18, height: 18))
            }
            NSColor.white.withAlphaComponent(0.95).setFill()
            NSBezierPath(ovalIn: NSRect(x: 14.5, y: 14.5, width: 3, height: 3)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
