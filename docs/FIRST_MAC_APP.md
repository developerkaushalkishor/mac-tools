# Your first native Mac app

## Environment observed on 2026-09-18

- macOS 26.6.2 (build 25G83).
- Apple Silicon / arm64.
- Apple Swift 6.4.
- Selected developer directory: `/Library/Developer/CommandLineTools`.
- Full Xcode 27.0 (27A266a) was installed during setup at `/Applications/Xcode.app`.
- The user accepted the Xcode agreement; first-launch setup completed.
- Optional iOS/watchOS/tvOS/visionOS simulator downloads were left off.
- No external-agent integration is required for this project.
- Project scripts select full Xcode using `DEVELOPER_DIR`; the system-wide developer directory remains unchanged.

Command Line Tools include the compiler and SDK used by this starter. Full Xcode is Apple's IDE: it adds a visual debugger, project interface and profiling tools. It is recommended for learning and later development, but the starter can be built with the installed tooling.

## First launch

Open Terminal and run:

```bash
cd /Volumes/T7/workspace/mac-tools
bash scripts/run.sh
```

The script compiles Swift, creates `dist/ScreenInk.app`, signs it locally, then opens it. A `.app` is a folder bundle containing the executable and metadata, presented by Finder as an application.

Look for the top-center icon toolbar and the pen-and-ink icon in the macOS menu bar. No Dock icon is expected. Click the pen tool to draw; press Escape to return to normal clicks. Use the menu-bar icon > Quit ScreenInk to exit. Quit before rebuilding. Reopening the running app shows its toolbar but does not replace the running code.

If no toolbar is visible, hover at the top-center edge or use the pen-and-ink menu-bar icon > Show Toolbar. If no icon exists, try opening `dist/ScreenInk.app` and capture any actual error message. Do not disable Gatekeeper or global macOS security settings to troubleshoot.

## Xcode setup reference

1. Download Xcode using [Apple's Xcode resources](https://developer.apple.com/xcode/resources/).
2. Open it once and complete its first-launch setup. System installation prompts require your action.
3. Open this project's `Package.swift` in Xcode. There is no `.xcodeproj` yet: this is an intentional Swift Package setup.
4. For daily use, continue using `scripts/run.sh` to create the complete app bundle. Xcode's package executable run is a development/debugging path.

Do not change the system-wide selected developer directory unless Xcode or a build actually requires it. Xcode was installed with the user's authorization. No paid enrollment or security bypass was performed.

## What to learn first

Follow the working app in this order:

1. `main.swift`: starts the app and its event loop.
2. `AppDelegate.swift`: creates windows, toolbar buttons and menu actions.
3. `CanvasView.mouseDown/mouseDragged/mouseUp`: turns a drag into points.
4. `StrokeStore.append`: saves a completed stroke and its undo state.
5. `CanvasView.draw`: renders those points as a line.
6. `setDrawing`: switches between drawing and clicking underlying apps.

First small exercise: change one color in the palette, rebuild, and see the result. Then inspect the test that restores a cleared drawing. UI code, drawing state and packaging solve different parts of the same app.

## Permissions and distribution

The starter does not capture the screen or monitor global keyboard input. Later screenshot work will add Screen Recording permission at the moment of use. Shortcut/cursor implementation must be audited for any Accessibility/Input Monitoring requirement rather than requesting everything in advance.

Local ad-hoc signing is not a public release identity. Sharing a polished app introduces Developer ID signing, notarization and a distribution decision. Those steps and any associated enrollment costs are deferred.

Keep the T7 drive mounted while building/running from this project. The generated app can later be copied to Applications when a stable build is ready.
