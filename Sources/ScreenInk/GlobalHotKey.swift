import AppKit
import Carbon

struct HotKeyChoice: Equatable {
    let id: Int
    let title: String
    let modifiers: UInt32

    static let choices = [
        HotKeyChoice(id: 1, title: "⌃⌥D", modifiers: UInt32(controlKey | optionKey)),
        HotKeyChoice(id: 2, title: "⇧⌘D", modifiers: UInt32(shiftKey | cmdKey)),
        HotKeyChoice(id: 3, title: "⌃⌥⌘D", modifiers: UInt32(controlKey | optionKey | cmdKey))
    ]
}

@MainActor
final class GlobalHotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    func register(_ choice: HotKeyChoice) {
        if let reference { UnregisterEventHotKey(reference) }
        let identifier = EventHotKeyID(signature: OSType(0x53494E4B), id: UInt32(choice.id))
        RegisterEventHotKey(UInt32(kVK_ANSI_D), choice.modifiers, identifier,
            GetApplicationEventTarget(), 0, &reference)
    }

    isolated deinit {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
    }
}
