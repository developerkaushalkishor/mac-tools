import AppKit
import ScreenCaptureKit

enum ScreenshotDestination {
    case clipboard
    case pngFile
}

enum ScreenshotError: LocalizedError {
    case permissionDenied
    case displayUnavailable
    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Screen Recording permission is required. Enable ScreenInk in System Settings > Privacy & Security > Screen & System Audio Recording, then reopen the app."
        case .displayUnavailable:
            "The selected display is no longer available."
        case .pngEncodingFailed:
            "ScreenInk could not encode the screenshot as PNG."
        }
    }

    var requiresScreenRecordingPermission: Bool {
        if case .permissionDenied = self { return true }
        return false
    }
}

@MainActor
enum ScreenshotService {
    static func capture(screen: NSScreen, region: CGRect?, excludingWindowNumbers: Set<Int>) async throws -> CGImage {
        if !CGPreflightScreenCaptureAccess() {
            _ = CGRequestScreenCaptureAccess()
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false,
                onScreenWindowsOnly: true)
            guard let display = content.displays.first(where: { $0.displayID == screen.cgDisplayID }) else {
                throw ScreenshotError.displayUnavailable
            }
            let excludedWindows = content.windows.filter {
                excludingWindowNumbers.contains(Int($0.windowID))
            }
            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            let configuration = SCStreamConfiguration()
            let source = region ?? CGRect(origin: .zero, size: screen.frame.size)
            let captureRect = captureRect(for: source, screenSize: screen.frame.size)
            let scale = screen.backingScaleFactor
            configuration.sourceRect = captureRect
            configuration.width = max(1, Int((source.width * scale).rounded()))
            configuration.height = max(1, Int((source.height * scale).rounded()))
            configuration.showsCursor = false
            configuration.shouldBeOpaque = true
            return try await SCScreenshotManager.captureImage(contentFilter: filter,
                configuration: configuration)
        } catch {
            if !CGPreflightScreenCaptureAccess() {
                throw ScreenshotError.permissionDenied
            }
            throw error
        }
    }

    static func captureRect(for localRegion: CGRect, screenSize: CGSize) -> CGRect {
        CGRect(x: localRegion.minX, y: screenSize.height - localRegion.maxY,
            width: localRegion.width, height: localRegion.height)
    }

    static func copyToClipboard(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: image, size: .zero)])
    }

    static func pngData(for image: CGImage) throws -> Data {
        let representation = NSBitmapImageRep(cgImage: image)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.pngEncodingFailed
        }
        return data
    }
}
