# Project status

Last reviewed: 2026-09-19. ScreenInk is an early 0.5.2 prototype, distributed as source.

## Repository

The repository is public at https://github.com/developerkaushalkishor/mac-tools. At the documentation audit, remote `main` and the local starting commit both resolved to `217e1a7dfd8b5c044f223277d34dc588e118d36f`. No GitHub releases were published at that time. Later documentation edits are not implied to be pushed by this snapshot.

## Implemented

- Per-display pen, translucent highlighter, whole-stroke eraser, 24 colors and three widths.
- Undo/redo and clear, with recoverable clear history.
- Drawing/normal mode and menu-bar controls.
- Fading ink, temporary laser pointer, smooth cursor halo, temporary ink visibility and configurable global drawing shortcut.
- Line, arrow, rounded rectangle, ellipse and diamond tools with Shift constraints and Pen shape recognition.
- Placeable and editable colored text with four font sizes.
- Top-center icon toolbar, saved draggable placement, reset, manual hide, auto-hide and top-edge reveal.

See [usage](docs/USAGE.md) for the exact behavior and [roadmap](docs/PLAN.md) for future work.

## Verification evidence

| Check | Recorded result |
| --- | --- |
| Swift Testing suite | 30 tests passed: text placement/edit/history/hit-testing, pen-shape recognition, rounded shape geometry, shapes/constraints, history/fading, progressive laser decay/lifecycle, eraser hit-testing, toolbar visibility/geometry, display registry and native AppKit canvas checks |
| Release build | Passed with Xcode 27 / Swift 6.4 on Apple Silicon, macOS 26.6.2 |
| Bundle signature | Local ad-hoc signature verification passed |
| Fresh GitHub clone at `217e1a7` | Doctor, seven tests, release build and signature verification passed from a separate temporary checkout on the same Mac |
| Public documentation | Relative Markdown links and whitespace checks passed; personal machine paths removed from onboarding docs |
| GUI launch | Toolbar and canvas observed in earlier smoke checks |
| Complete pen drag, Escape and click-through flow | Not fully verified; computer-use focus errors interrupted checks |
| Toolbar drag, hover-reveal and menu-bar contrast | Full visual checklist pending |
| Fullscreen, Spaces, screen sharing, multiple displays and long sessions | Not verified |
| macOS 14 minimum target / Intel | Declared target or potential build support, not independently validated |

Automated model tests do not establish desktop compatibility. Use the [manual checklist](docs/TESTING.md) when contributing verification results.

## Current limitations and next work

Ink is stored only in memory; quitting loses drawings. Each connected screen has a canvas; the toolbar selects the target for Undo/Redo/Clear. There is no screenshot/export yet. Next work is hands-on validation of Milestone 4 before starting boards.

## Multi-display fix — 2026-09-18

Replaced the single primary-screen overlay with a display-identity registry of independent canvas panels. Drawing mode and pen settings apply to every active canvas. Display reconfiguration releases input, updates frames, hides disconnected panels and retains their session state for reconnection. Top-edge reveal can move the toolbar to another display.

Validation: 12 tests passed, including AppKit coverage of **two actual connected screens**, per-window input transparency, and local drawing coordinates with a negative window origin. Registry tests verify history isolation and reconnect/reorder behavior. Release build 0.1.1 and ad-hoc signature verification also passed. Full hands-on pointer movement and physical cable hot-plug are not claimed by these automated tests.

## Toolbar reveal and right-click fix — 2026-09-19

Expanded the reveal area to include the exact top pixel and the route to the toolbar; removed reveal dwell timing and increased pointer polling frequency. Edge requests relocate an already-visible toolbar between displays. Toolbar window level now keeps it above ordinary application windows. Right-click on a drawing canvas exits drawing across all displays and retains ink/history.

Validation: 16 tests passed, including twenty model hide/reveal cycles and native right-click input release on two connected displays. Full hands-on hover, fullscreen and Spaces behavior remains on the manual checklist.

## Toolbar polish — 2026-09-19

Color swatches now use an exact centered square drawing area so every fill and selection ring is circular. Purple is first and selected by default. Toolbar icons and color swatches provide immediate press-and-release visual feedback.

## Milestone 1 — Essential drawing — 2026-09-19

Added a broad translucent highlighter, whole-stroke eraser with one undo checkpoint per drag, a compact 24-color palette, and persistent color, width and tool preferences. Tool selection applies to every active display. Automated coverage verifies segment hit-testing, multi-stroke eraser undo/redo and native highlighter/eraser input; hands-on rendering and restart checks remain pending.

## Milestone 2 — Presentation controls — 2026-09-19

Added elapsed-time fading ink with 2/5/10-second delays, a cross-display cursor halo, reversible ink visibility and a configurable native global drawing shortcut. Fading redraws are scheduled only while a stroke is actively fading. The shortcut uses the macOS hot-key API and does not require Accessibility permission. Automated fade timing is covered; hands-on shortcut, fullscreen, visual fade and idle-performance checks remain pending.

### Presentation follow-up — 0.3.1

Restricted hover reveal to the exact toolbar-width strip at the physical top-center edge. Cursor Halo now samples at 60 FPS while enabled and returns to the lower-frequency idle timer when disabled. Added an Excalidraw-style temporary laser trail that expires after 0.65 seconds and never enters permanent drawing history.

### Laser trail refinement — 0.3.2

Replaced independently fading line fragments with one timestamped, densely sampled trail. The renderer combines time decay and distance from the head using an ease-out curve, so the oldest tail becomes thinner and more transparent first while the head stays clear. The toolbar now uses the native `laser.burst` symbol. The implementation follows the behavior of Excalidraw's official laser-trail source while remaining native Core Graphics code.

### Excalidraw point-decay correction — 0.3.3

Corrected the trail-length unit after reviewing the laser-pointer package internals: Excalidraw's decay length counts pointer samples, not pixels. ScreenInk now retains up to 50 real input samples, applies the one-second timestamp decay to those samples and renders quadratic segments for smoothness. This removes the unintended short fixed-distance tail from 0.3.2.

### Continuous laser outline — 0.3.4

Replaced separately stroked laser segments and their round caps with one continuous tapered outline. The outline shrinks to zero width at the fading tail, preventing individual segments from ending as visible dots. A round head is drawn only while the mouse button is held and is removed immediately on release so the final fade stays continuous.

## Milestone 3 — Shapes — 2026-09-19

Added line, arrow, rectangle and ellipse tools in a compact Shapes popover. All shapes provide live drag previews, share the selected color/width and fading settings, and work with Undo/Redo and whole-stroke erasing. Holding Shift snaps lines/arrows to 45-degree increments and constrains rectangles/ellipses to squares/circles. Automated tests cover constraint geometry and eraser hit-testing for shape outlines and arrowheads; hands-on visual validation remains pending.

### Ellipse and fading defaults — 0.4.1

Fading Ink now starts OFF on every launch while retaining the selected delay. Ellipses use 96 outline segments instead of 48 and add a sub-pixel deterministic wobble, removing visible polygon facets while preserving accurate bounds and a natural pen-drawn character.

### Pen shape recognition and rounded geometry — 0.4.2

The Pen tool now recognizes confidently closed circle/ellipse, rectangle/square and diamond gestures when drawing ends. Ambiguous and open strokes remain freehand. Rectangle and diamond rendering uses rounded corners plus a sub-pixel deterministic wobble, and Diamond is available directly in the Shapes picker. Recognition and closed-path geometry are covered by automated regression tests; hands-on tuning with varied drawing styles remains pending.

## Milestone 4 — Text — 2026-09-19

Added a Text tool with inline single-line editing, four remembered font sizes and the selected ink color. Return commits a new or edited annotation; Escape cancels the draft and exits drawing mode so keyboard focus can return to the underlying app. Existing text can be clicked to edit and participates in Undo/Redo, Clear, erasing and Fading Ink. Core and native AppKit tests cover text hit-testing, placement, editing and undo; hands-on positioning, focus and multi-display checks remain pending.

### Drawing-mode control clarity — 0.5.1

Replaced the ambiguous Pen toggle with separate Cursor and Pen controls. Cursor always enters normal app-interaction mode, Pen always selects permanent freehand drawing, and Highlighter uses a distinct yellow selected state plus a descriptive tooltip. Escape, right-click and the global drawing toggle retain their existing behavior.

### Toolbar reveal animation — 0.5.2

Every hidden-to-visible toolbar transition now uses a 220-millisecond ease-out animation, combining a 12-point downward slide from the top with an opacity fade. Repeated visibility checks do not restart the animation, while launch, top-edge reveal and the Show Toolbar command share the same presentation path.
