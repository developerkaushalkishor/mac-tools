# ScreenInk

**Draw over your Mac screen with a small, offline annotation tool.**

ScreenInk is a native macOS menu-bar app built with Swift, AppKit and Core Graphics. Use it to mark up code, explain an idea or point out details during a presentation. The project is MIT-licensed, and contributions are welcome.

> **Early prototype · 0.5.2** — Build from source today. There is no published installer or notarized binary release yet. Drawing canvases are created on every connected display; see [known limitations](#known-limitations).

[Install](docs/INSTALLATION.md) · [Usage](docs/USAGE.md) · [Contribute](CONTRIBUTING.md) · [Roadmap](docs/PLAN.md) · [Report a bug](https://github.com/developerkaushalkishor/mac-tools/issues/new/choose)

## Features available now

- Pen, translucent highlighter and undoable whole-stroke eraser.
- 24-color palette, six quick colors and three widths, with saved tool settings.
- Optional fading ink, cursor halo, temporary ink visibility and configurable global drawing shortcut.
- Temporary laser-pointer trail for live presentation emphasis.
- Lines, arrows, rounded rectangles, ellipses and diamonds with Shift constraints, plus automatic closed-shape recognition for Pen strokes.
- Place and re-edit colored text at four font sizes.
- Undo, redo and clear; clearing a drawing can also be undone.
- Compact icon toolbar, initially centered below the macOS menu bar.
- Drag handle with remembered position and a reset command.
- Manual hide, automatic hiding after two seconds away, and top-center hover to reveal.
- Persistent menu-bar icon for controls and quitting.
- Normal mode for clicking underlying apps; drawing remains visible.
- Offline operation with no accounts, analytics, backend or third-party package dependencies.

Toolbar hiding does **not** erase ink. Fading Ink starts OFF each time the app launches.

## Quick start

You need a Mac with macOS 14 or later and a Swift 6-capable Apple toolchain. Full Xcode is recommended. The current build has been checked on Apple Silicon with macOS 26.6.2, Xcode 27 and Swift 6.4; the declared minimum OS and Intel have not been independently tested.

Install [Xcode from Apple](https://developer.apple.com/xcode/resources/), open it once, and finish its setup. Only macOS components are needed; mobile simulator downloads are optional.

```bash
git clone https://github.com/developerkaushalkishor/mac-tools.git
cd mac-tools
bash scripts/doctor.sh
bash scripts/test.sh
bash scripts/run.sh
```

The last command builds and opens `dist/ScreenInk.app`. For subsequent launches, open that app in Finder without rebuilding. No paid Apple Developer membership is needed for this local build.

See the [installation guide](docs/INSTALLATION.md) for installing to Applications, updating, alternate Xcode locations and troubleshooting. Build scripts locally ad-hoc sign the app; this is not Developer ID signing or notarization.

## Basic use

1. Find the pen-and-ink icon in the macOS menu bar. Choose **Show Toolbar** if necessary.
2. Click the toolbar Pen icon to draw. Click the separate Cursor icon to return to normal app interaction.
3. Choose a quick color or open the palette for all 24 colors; click the line-weight icon to cycle widths.
4. Press **Escape** or **right-click while drawing** to return to normal clicking, or use **Toggle Drawing** in the menu.
5. Drag the dotted handle to move the toolbar. The up-chevron hides it and exits drawing mode.
6. Hover at any display's top-center edge to reveal the toolbar there, or use the menu-bar icon. The eye icon toggles auto-hide.
7. Quit using **ScreenInk menu-bar icon → Quit ScreenInk**.

Drawings are temporary and are lost when the app quits. See the [control reference](docs/USAGE.md) for details and recovery steps.

## Known limitations

- Each display has its own drawing history. Toolbar Undo/Redo/Clear affect the display containing the toolbar.
- Text, boards and screenshots are **not implemented yet**.
- Undo/redo keyboard shortcuts work while the drawing canvas has focus; they are not global shortcuts.
- Display changes do not rescale existing annotations.
- Fullscreen/Spaces behavior, screen sharing and extended drawing sessions still need hands-on testing.
- GUI launch has been observed, but the full drag/hover/click-through checklist is not yet verified. Automated tests cover history and toolbar visibility rules, not complete desktop behavior.

See [verification status](STATUS.md) and the [manual checklist](docs/TESTING.md).

## Contributing

Bug reports, reproducible compatibility findings, documentation improvements and focused pull requests are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md). For a larger feature, discuss the scope in an issue first so work does not overlap.

```bash
bash scripts/test.sh
bash scripts/build.sh
```

Use **Xcode → File → Open → Package.swift** for native debugging, or open the repository folder in **VS Code** for editing and Git review. This is a Swift package, so no `.xcodeproj` is required. The [developer guide](docs/FIRST_MAC_APP.md) explains the code flow.

| Location | Responsibility |
| --- | --- |
| `Sources/ScreenInk` | Native windows, toolbar, menu icon and canvas |
| `Sources/InkCore` | Drawing history and toolbar visibility rules |
| `Tests/InkCoreTests` | Model regression tests |
| `scripts` | Environment selection, diagnostics, tests, build and launch |
| `Resources/Info.plist` | Application bundle metadata |

## Roadmap

The next steps are hands-on validation, a stroke eraser and a highlighter. Shapes, text, fading ink, cursor highlighting, boards, screenshots and further multi-display validation follow incrementally. These are plans, not features already shipped. See the [roadmap](docs/PLAN.md).

## License

ScreenInk's project code and documentation are available under the [MIT License](LICENSE). Apple frameworks and SF Symbols remain subject to Apple's applicable terms; the project license does not relicense those assets. ScreenInk is an independent project, not affiliated with Epic Pen or Presentify.
