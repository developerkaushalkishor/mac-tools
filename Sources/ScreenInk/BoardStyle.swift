import AppKit

enum BoardStyle: Int, CaseIterable {
    case screen
    case whiteboard
    case blackboard

    var backgroundColor: NSColor? {
        switch self {
        case .screen: nil
        case .whiteboard: NSColor(srgbRed: 0.97, green: 0.97, blue: 0.96, alpha: 1)
        case .blackboard: NSColor(srgbRed: 0.055, green: 0.065, blue: 0.075, alpha: 1)
        }
    }
}

enum BoardScope: Int, CaseIterable {
    case currentDisplay
    case allDisplays
    case region
}
