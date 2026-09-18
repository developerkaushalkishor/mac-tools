# Developer guide: your first native Mac app

Start with the [installation guide](INSTALLATION.md) to get a working build. Swift is the programming language; AppKit provides native Mac windows and controls; Core Graphics renders strokes. Swift Package Manager organizes the targets and builds the executable.

## Open the source

### Xcode

Choose File → Open and select `Package.swift` inside your checkout. Xcode recognizes the Swift package; there is no `.xcodeproj`. Select the ScreenInk executable scheme and your Mac to debug. The package executable is a development target; `bash scripts/build.sh` creates the full `.app` bundle with its menu-bar metadata. Use that bundle for everyday usage checks.

### VS Code

Open the repository folder with File → Open Folder. You can read/edit code and review Git changes immediately. Swift-aware completion and debugging require the official Swift extension and a compatible toolchain. This repository does not install editor extensions. The terminal scripts remain the documented build/test path if your debugger configuration is not ready.

The checked-in `.vscode/launch.json` is an optional convenience for the Swift extension, not a substitute for installing the compiler or a guaranteed debugger setup on every machine.

## Follow the data flow

1. `Sources/ScreenInk/main.swift` starts the application and its event loop.
2. `AppDelegate.swift` owns windows, toolbar actions and input mode.
3. `CanvasView.swift` turns mouse down/drag/up into a stroke and renders it.
4. `Sources/InkCore/StrokeStore.swift` stores completed strokes and undo/redo history.
5. `ToolbarViews.swift` supplies icon buttons, the drag handle and vector menu-bar icon.
6. `Sources/InkCore/ToolbarVisibility.swift` decides visibility from pointer activity and elapsed time.

Drawing mode makes the overlay receive mouse events. Normal mode sets the overlay to ignore those events so other apps can receive clicks. The toolbar remains a separate native panel.

## Build and test

From the checkout root:

```bash
bash scripts/doctor.sh
bash scripts/test.sh
bash scripts/build.sh
open dist/ScreenInk.app
```

Scripts select the complete Xcode installation at `/Applications/Xcode.app` when available, unless you already supplied `DEVELOPER_DIR`. They do not change the system-wide toolchain selection.

Quit the running app before rebuilding. Reopening a running copy shows its toolbar but does not reload the executable. Keep build success, model-test success and desktop verification separate in your report.

## A first small exercise

Change a palette color in `AppDelegate.swift`, rebuild, and observe it. Then read the test that restores a cleared drawing. Before changing undo/redo behavior, describe the user-visible scenario and add a regression test for it. UI layout, drawing state and app packaging solve different parts of the application.

## Packaging and permissions

`Resources/Info.plist` describes the app identity and menu-bar behavior. The build script places the executable inside `dist/ScreenInk.app` and signs it with the configured identity or an ad-hoc fallback. `scripts/package-release.sh` creates a versioned ZIP and checksum and can use an existing Developer ID/notarization setup; no credentials are included here.

The app registers its drawing shortcut with the native hot-key API. Its experimental screenshot tool uses ScreenCaptureKit only after a user action and requires Screen Recording permission. Capture is still unreliable on the current test Mac, so contributors should keep permission behavior separate from coordinate and PNG tests.
