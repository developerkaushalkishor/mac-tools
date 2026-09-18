# Setup status — 2026-09-18

## Completed

- Created `/Volumes/T7/workspace/mac-tools` and initialized a local Git repository on `main`; no remote, commit or push.
- Researched native annotation APIs and product scope using Exa; source links and deferred research are in `docs/RESEARCH.md`.
- Created the phased plan, beginner guide, usage-feedback template and verification checklist.
- Implemented the single-display ScreenInk starter: pen, six colors, three widths, undo/redo, clear, drawing/normal mode, menu item and floating toolbar.
- Installed Xcode 27.0 (27A266a) from the Mac App Store. The user accepted the Xcode agreement.
- Completed the Xcode welcome flow with built-in macOS SDK; optional simulator downloads were not requested.
- Verified `xcodebuild -checkFirstLaunchStatus` exits successfully using the full Xcode developer directory.
- Verified Swift 6.4 is available. Project scripts select full Xcode via DEVELOPER_DIR; system xcode-select remains on Command Line Tools.

## Verification actually performed

| Check | Result |
| --- | --- |
| `bash scripts/test.sh` using full Xcode | PASS: 3 Swift Testing regressions, zero failures |
| `bash scripts/build.sh` using full Xcode | PASS: release app bundle; latest build approximately 6 seconds |
| Initial Command Line Tools build | PASS with missing search-path warnings; those warnings did not appear in final full-Xcode build |
| Bundle signature | PASS: ad-hoc signature verified on disk |
| Source and bundled Info.plist | PASS: plutil validation |
| Shell scripts | PASS: bash syntax validation |
| GUI launch | Observed ScreenInk toolbar in both debug and release builds |
| Draw action | Observed canvas accessibility state changing to drawing mode |
| Continuous pen drag / Escape / underlying clicks | NOT fully verified: computer-use window/focus errors interrupted the smoke test |
| Fullscreen, multiple displays, screen sharing, long sessions | NOT verified |

The test app was closed after the interrupted smoke test. Open `dist/ScreenInk.app` to try it. If any input/focus issue occurs, use the toolbar Normal/Quit controls or Activity Monitor to quit ScreenInk, then record the exact steps.

## Current deliverable

`dist/ScreenInk.app` is a locally built, ad-hoc-signed prototype, not a notarized public release. It runs on the primary display, stores ink in memory, and currently has six colors. The remaining requested features are planned, not implemented.

## Next action

Run the short manual checklist in `docs/TESTING.md`, capture real usage feedback, then implement the stroke eraser. The initial GUI launch does not establish daily-use reliability.

## Toolbar update — 2026-09-18

Implemented a compact dark native icon toolbar with six color swatches, default top-center placement, drag handle, saved placement, reset command, manual hide, two-second auto-hide and top-center pointer reveal. Added an original vector pen-and-ink template icon to the macOS menu bar and SF Symbols for toolbar actions. The menu remains the recovery path when the toolbar is hidden.

Validation: all seven tests passed (three drawing-history tests and four toolbar-visibility tests); release build and signature verification passed. Updated app launch and normal-mode canvas were observed. Full desktop toolbar positioning/drag/hover/contrast checks are still pending; the computer-use surface selected the canvas instead of the transient toolbar. This update does not add shapes, eraser or other later roadmap features.
