# Exa research: native screen annotation

Date: 2026-09-18. Method: two search workstreams requesting five results each, followed by direct Exa fetches of nine primary source pages. Search count: 10 result slots. Searches returned some third-party material despite primary-source ranking requests; it was excluded from technical conclusions. Direct Apple, Swift and product pages below form the decision record. No third-party implementation was copied.

## Findings and decisions

| Finding | Source | Project decision |
| --- | --- | --- |
| A native window can ignore mouse events | [Apple: ignoresMouseEvents](https://developer.apple.com/documentation/appkit/nswindow/ignoresmouseevents) | Use a transparent AppKit panel; normal mode passes clicks through |
| Window collection behaviors control Spaces, Mission Control and Stage Manager; some options are mutually exclusive | [Apple: CollectionBehavior](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct) | Keep flags explicit; validate fullscreen and monitor behavior instead of claiming universal support |
| Swift ships with Swift Package Manager | [Swift: build with SwiftPM](https://www.swift.org/getting-started/cli-swiftpm/) | Dependency-free Swift package, plus our own local app-bundle script |
| Xcode provides debugging and profiling; Apple also offers command-line tooling | [Apple: Xcode resources](https://developer.apple.com/xcode/resources/) | Use existing tools now; document full Xcode onboarding for later |
| ScreenCaptureKit has a single-frame capture API | [Apple: SCScreenshotManager](https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager) | Use it in the screenshot milestone; no screenshot implementation in the starter |
| Apple's capture sample requests Screen Recording permission | [Apple: capture sample](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos) | Add permission-denied and permission-retry paths with screenshots; sample-specific requirements are not framework minimum requirements |
| Notarization checks Developer ID-signed software before distribution | [Apple: notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) | Local ad-hoc build first; public distribution remains separate |
| Presentify includes annotation, cursor effects, spotlight and zoom | [Presentify](https://presentifyapp.com/) | Track spotlight, zoom and richer click effects as optional later scope |
| Epic Pen documents pen/highlighter, erasing, screenshots, shapes, text, fading and board modes | [Epic Pen user guide](https://epicpen.com/userguide) | Map requested tools to incremental milestones |

AppKit + Core Graphics is our engineering choice based on the required native window/input behavior, not a vendor statement that this is the only valid stack. SwiftUI is optional for later preferences. Electron, a web server and a database do not solve a current requirement.

## Research still needed at the relevant milestone

1. Global shortcuts: compare registered shortcuts with event monitoring, conflicts and actual permissions on the supported macOS versions.
2. Cursor effects: local/global mouse observation, monitor coordinate conversion, idle power use and permissions.
3. Screenshots: API availability, display scale, selected-region coordinates, toolbar-only exclusion, denied permission and screen-sharing behavior.
4. Fullscreen: validate supported collection behaviors on this Mac before adding newer availability-gated flags.
5. Distribution: compare local-only, direct Developer ID release and App Store constraints before choosing licensing technology.

The research establishes API feasibility. It does not demonstrate rendering latency, compatibility with every application, or successful screen sharing; those require running tests.
