# Mac Tools — ScreenInk

A small, offline macOS screen annotation app. Build a useful pen first, use it during real work, and add one feature at a time. ScreenInk is a working name.

## Start here

```bash
cd /Volumes/T7/workspace/mac-tools
bash scripts/doctor.sh
bash scripts/run.sh
```

The build produces `dist/ScreenInk.app`. After the first build, double-click that app in Finder to launch without rebuilding. Quit the running app before rebuilding. No server, API key, account, package download, or paid developer membership is needed for this local starter.

1. The icon toolbar starts at the top center, just below the menu bar. The pen-and-ink menu-bar icon stays available when the toolbar is hidden.
2. Click the pen icon to draw; its cyan state indicates drawing mode. Press Escape to return to normal clicks.
3. Click a color dot to select ink. The line-weight icon cycles Thin / Medium / Thick.
4. Use the undo, redo and trash icons. Clear itself can be undone.
5. Drag the dotted handle on the left to move the toolbar. Its position is remembered across launches; the menu offers **Reset Toolbar to Top Center**.
6. The eye icon toggles auto-hide (enabled by default). After two seconds away from the toolbar it hides; it stays visible during a mouse drag.
7. Hover for about a quarter-second near the **top-center edge of the display containing the toolbar** to reveal it. The trigger spans 320 points, including the menu-bar area and eight points below it. A moved toolbar reappears at its saved position.
8. The up-chevron hides the toolbar immediately and returns to normal clicks. Hide only affects the toolbar, not existing ink. Automatic hiding also preserves the current drawing mode.
9. The permanent menu-bar icon provides Show/Hide Toolbar, Reset Position, Auto-hide, Toggle Drawing, Clear and Quit. Relaunching the running app also reveals the toolbar.
10. Drawings remain temporary and disappear when the app quits.

This is an initial single-display prototype. Fullscreen/Spaces behavior, monitor changes, long sessions and screen sharing need the manual checks in `docs/TESTING.md`. Global shortcuts, eraser, highlighter and screenshots are not implemented yet. Cmd-Z / Shift-Cmd-Z apply while the drawing canvas has keyboard focus, not globally.

## Stack

| Part | Choice | Reason |
| --- | --- | --- |
| Language | Swift 6 | Native Apple APIs and compiler checks |
| Windowing and starter toolbar | AppKit | Transparent panels and explicit input control |
| Drawing | Core Graphics | Native stroke rendering without external dependencies |
| Build | Swift Package Manager + small app-bundle script | Works with the installed Command Line Tools |
| Tests | Swift Testing | Test drawing history without driving the desktop |
| Later settings UI | SwiftUI, if useful | Add when preferences justify it |
| Later screenshots | ScreenCaptureKit | Native screenshot capture |
| Later preferences | UserDefaults | Local settings, no database |

Deployment target: macOS 14+. Initial build targets this Mac's architecture (Apple Silicon). Older macOS versions and Intel are not validated.

## Project map

- `Package.swift`: build manifest, targets and minimum macOS version.
- `Sources/ScreenInk/main.swift`: app entry point and event loop.
- `Sources/ScreenInk/AppDelegate.swift`: overlay, toolbar, menu and mode switching.
- `Sources/ScreenInk/ToolbarViews.swift`: native icon buttons, draggable handle and original template menu-bar icon.
- `Sources/InkCore/ToolbarVisibility.swift`: tested auto-hide and hover-reveal behavior.
- `Sources/ScreenInk/CanvasView.swift`: mouse input and drawing.
- `Sources/InkCore/StrokeStore.swift`: stroke data and undo/redo history.
- `Tests/InkCoreTests`: history regression tests.
- `Resources/Info.plist`: app identity and menu-bar app behavior.
- `scripts`: environment check, build and launch.
- `docs/PLAN.md`: phased scope and acceptance gates.
- `docs/RESEARCH.md`: Exa research and source-backed decisions.
- `docs/FIRST_MAC_APP.md`: beginner setup and learning guide.
- `docs/TESTING.md`: verification checklist and limitations.

Full Xcode 27 is now installed and initialized. Project scripts use it automatically via `DEVELOPER_DIR`, without changing the system-wide developer directory. Run model tests with `bash scripts/test.sh`. The app is locally ad-hoc signed, not Developer ID signed or notarized. Do not treat this build as a public release.

## Review the code in Xcode or VS Code

Both editors can review these Swift source files and Git diffs.

- **Xcode:** File > Open > `/Volumes/T7/workspace/mac-tools/Package.swift`. Xcode recognizes the Swift package. Use it for native debugging, breakpoints and profiling. The source navigator shows the app, core model and tests.
- **VS Code:** File > Open Folder > `/Volumes/T7/workspace/mac-tools`. Editing and Git review work normally; the official Swift extension is optional for Swift language support. The integrated terminal can run `bash scripts/test.sh` and `bash scripts/run.sh`.
- Start with `AppDelegate.swift` for windows and toolbar interactions, `ToolbarViews.swift` for icons, and `ToolbarVisibility.swift` for auto-hide. There is no `.xcodeproj`; the package manifest is intentional.
