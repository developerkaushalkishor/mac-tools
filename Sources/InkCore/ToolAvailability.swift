public struct ToolAvailability: Equatable, Sendable {
    public private(set) var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public mutating func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    public var permitsOverlayPresentation: Bool { isEnabled }
    public var permitsEdgeReveal: Bool { isEnabled }
    public var permitsInputMonitoring: Bool { isEnabled }
}
