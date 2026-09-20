# Project status

Last reviewed: 2026-09-20. ScreenInk 0.15.3 is an early test candidate; the latest public preview remains 0.15.2.

## Repository

The repository is public at https://github.com/developerkaushalkishor/mac-tools. At the documentation audit, remote `main` and the local starting commit both resolved to `217e1a7dfd8b5c044f223277d34dc588e118d36f`. No GitHub releases were published at that time. Later documentation edits are not implied to be pushed by this snapshot.

## Implemented

- Per-display pen, translucent highlighter, whole-stroke eraser, 24 colors and three widths.
- Undo/redo and clear, with recoverable clear history.
- Drawing/normal mode and menu-bar controls.
- Fading ink, temporary laser pointer, smooth cursor halo, temporary ink visibility and configurable global drawing shortcut.
- Optional cross-app click animations with a smooth expanding ripple.
- Line, arrow, rounded rectangle, ellipse and diamond tools with Shift constraints and Pen shape recognition.
- Placeable and editable colored text with four sizes, six saved font styles and three alignments.
- Individual and marquee-group selection, recoloring, movement and resizing for all saved annotations.
- Frame-only board selection with contained annotations following board movement and resizing.
- Start-aware board drawing containment that prevents inside gestures from crossing the frame.
- Tool-specific cursors for every interactive drawing tool.
- Framed whiteboards and blackboards scoped to the current display, all displays or a custom region.
- On-demand full-display and region screenshots with Retina PNG save and clipboard output.
- Top-center icon toolbar, saved draggable placement, reset, manual hide, auto-hide and top-edge reveal.
- Original purple macOS application icon bundled at standard and Retina sizes.
- Persistent master enable/disable control with a menu-bar recovery path.
- Responsive compact toolbar with a More popover; quick colors collapse on narrow displays while all controls remain reachable.

See [usage](docs/USAGE.md) for the exact behavior and [roadmap](docs/PLAN.md) for future work.

## Verification evidence

| Check | Recorded result |
| --- | --- |
| Swift Testing suite | 51 tests passed: master disable/enable gating, click-animation lifetime/history isolation, long-session fading-ink cleanup and point sampling, screenshot region/coordinate/PNG behavior, text alignment geometry and multi-text changes, typography catalog and multi-text font changes, immediate tool-cursor activation, start-aware board drawing containment, group selection/color/movement, contained board transforms, universal annotation transforms, board scope/region/history behavior, text placement/edit/history/hit-testing, pen-shape recognition, rounded shape geometry, shapes/constraints, history/fading, progressive laser decay/lifecycle, eraser hit-testing, toolbar visibility/geometry, display registry and native AppKit canvas checks |
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

Version 0.15.3 adds the responsive toolbar layout. The complete suite now reports 51 tests: 17 AppKit canvas tests and 34 core tests, including narrow-display width and quick-color layout rules. The release build and ad-hoc signature verification pass; hands-on More-popover and cross-display layout confirmation is pending user testing.

## Current limitations and next work

Ink is stored only in memory; quitting loses drawings. Each connected screen has a canvas and independent history. Screenshot capture remains experimental because the Screen Recording permission path still fails on the current test Mac. Milestone 7 compatibility checks and the Developer ID/notarization gate for Milestone 9 remain pending; Spotlight and zoom are deferred optional work.

## Milestone 7 — Reliability — 2026-09-19

Started long-session reliability work. Pen and Highlighter now discard sub-point mouse samples that add no visible movement while preserving the exact gesture endpoint. Fully faded ink is removed from the live canvas and every Undo/Redo snapshot, preventing invisible temporary annotations from accumulating for the lifetime of the app. Deterministic tests cover both retention paths; fullscreen, Spaces, physical display reconnect and extended performance checks remain hands-on acceptance items.

## Milestone 8 — Presentify extras — 2026-09-19

Added optional Click Animations as the first Milestone 8 feature. A left click in ScreenInk or another app produces a cyan center flash and expanding ease-out ring on the correct display without entering drawing history or blocking the original click. The toolbar and menu-bar controls persist the preference, animation tracking runs at 60 FPS only while enabled, and ripple storage is capped and expires after half a second.

## Milestone 9 — Public binary distribution — 2026-09-19

Added reproducible versioned ZIP and SHA-256 packaging for local release candidates. The packaging script verifies the app signature and archive integrity, optionally submits through an existing `notarytool` keychain profile, staples the notarization ticket and refuses public mode without a Developer ID Application signature. The documented workflow keeps Apple credentials outside Git. A real public binary remains pending until a Developer ID identity is installed and the notarized artifact passes clean-Mac installation checks.

Version 0.15.1 adds an original ScreenInk macOS application icon with a purple screen, fountain-pen nib and ink trail. The transparent high-resolution master is converted into a standard multi-resolution `.icns`, copied into the app bundle and declared through `CFBundleIconFile`. Documentation now makes clear that GitHub's source ZIP is not an installable non-developer release.

### Group selection and board contents — 0.9.0

Select now supports a drag marquee for choosing several annotations, group movement and proportional corner resizing. Choosing any quick or palette color recolors the current single or multiple selection in one Undo step. Boards are selectable only from their visible frame, leaving the interior available for exact annotation clicks and marquee selection. Moving or resizing a selected board transforms annotations whose centers were inside the board when the gesture started; outside annotations remain unchanged. Automated native event tests cover group recoloring/movement, frame-only board selection and contained annotation movement.

Drawing containment now follows the gesture's starting location. Pen, Highlighter, Laser and shape gestures that begin on a board's writable interior are clamped inside that surface, including a stroke-width margin that keeps rendered ink away from the frame. Gestures that begin outside the board remain free to use the complete screen canvas.

Fixed tool cursor activation for non-activating overlay panels. Selecting a drawing tool now installs its custom macOS cursor immediately without depending on the canvas becoming the key window, cursor updates reassert the selected icon, and returning to Normal mode restores the arrow cursor.

### Teaching typography — 0.10.0

Added a visual font picker with three clear teaching styles (System Rounded, Avenir Next and Helvetica Neue) and three handwriting styles (Chalkboard, Noteworthy and Marker Felt). The choice is saved for future text, used by both the inline editor and rendered annotation, and can be applied to one or several selected text annotations in one Undo step. These fonts are native macOS families with a safe system-font fallback, so the app gains no font-download, network or third-party licensing dependency. The selection follows Exa-reviewed accessibility guidance favoring legible sans-serif text for instructions while reserving decorative handwriting for short annotations.

### Text placement calibration — 0.10.1

Choosing any font now always activates Text mode, including when Text was the remembered tool but ScreenInk was in Normal mode. The canvas immediately uses the native I-beam cursor. The inline editor begins exactly at the clicked annotation origin, previews the chosen typeface and color, and uses a short high-contrast “Type here…” placeholder; Return/Escape guidance moved to the tooltip and accessibility help so it cannot overflow the field.

### Text alignment — 0.11.0

Added Left, Center and Right alignment controls beside the font picker. Each text annotation stores its alignment and treats its placement point as the matching left edge, center anchor or right edge, so alignment visibly changes without requiring an artificial text box. The current alignment is saved for future text. With Select active, the same control updates one or several selected text annotations in one Undo step while preserving the selection and ignoring non-text elements.

## Milestone 6 — Screenshots — 2026-09-19

Added a Screenshot picker with four actions: copy the toolbar display, copy a dragged region, save the toolbar display as PNG and save a dragged region as PNG. Captures use ScreenCaptureKit only after a user action, preserve Retina resolution, include ScreenInk canvas ink and boards, hide the pointer, and exclude the ScreenInk toolbar window through a display content filter. Region selection uses a dimmed crosshair overlay and converts AppKit's bottom-left canvas coordinates into ScreenCaptureKit display coordinates. Permission denial produces an actionable macOS Settings message; successful file actions use a native Save panel. Automated tests cover region input, coordinate conversion and PNG encoding without triggering Screen Recording permission; hands-on permission and pixel-output checks remain pending.

### 0.12.1 screenshot permission fix

ScreenInk now lets ScreenCaptureKit attempt capture after requesting access instead of stopping on the immediate Core Graphics request result. If macOS still denies access, the alert opens the Screen Recording privacy pane directly and explains the required app restart. This did not resolve capture on the current test Mac, so screenshot support remains experimental and requires further diagnosis.

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

### Text editing and annotation transforms — 0.6.0

Improved the inline text editor with a clear placeholder, larger high-contrast field, reliable focus and content-aware horizontal sizing. Added a dedicated Select tool with visual bounds and handles for moving and resizing lines, arrows, closed shapes and text. Shape transforms use stable logical bounds independent of the hand-drawn wobble; text scales proportionally between 12 and 120 points. Each completed drag creates one Undo step, with native AppKit and core geometry regression coverage.

### Tool-specific cursors — 0.6.1

Drawing mode now displays a distinct high-contrast cursor for Pen, Highlighter, Eraser, Laser, Select and every shape tool. Each custom cursor includes the selected tool symbol and a centered action point; Text uses the native I-beam. Cursor rectangles refresh immediately when the active tool changes, while Normal mode returns pointer ownership to the underlying application.

## Milestone 5 — Whiteboard and Blackboard — 2026-09-19

Added a Board picker for the transparent live screen, an off-white board and a near-black board. Background selection applies to every connected display and never mutates annotation history, so strokes and predictable Undo/Redo survive every switch. Board activation enters drawing mode, and exact white or dark-gray ink automatically changes to a readable contrasting color on the matching board. Automated coverage verifies annotations and Undo history remain intact; hands-on fullscreen and multi-display visual checks remain pending.

### Selective framed boards — 0.7.1

Expanded the Board picker with Current Display, All Displays and Region scopes. Region mode uses a crosshair drag to place a board within one display, while each display retains its own board state. Based on Exa research into premium physical boards, Whiteboard uses a slim aluminum gradient and floating shadow, while Blackboard uses a wider warm-wood frame with restrained grain; both include rounded corners and an integrated tray. The frames are native Core Graphics vectors rather than downloaded artwork, preserving Retina sharpness and avoiding external asset licensing. Native tests verify a custom region changes only its chosen canvas.

### Popover auto-hide and reveal-position fix — 0.7.2

Open Palette, Shapes and Board popovers now count as active toolbar interaction, preventing auto-hide while the pointer is choosing a sub-tool. The reveal slide moved from the toolbar window coordinates to a temporary Core Animation transform on its internal visual layer. Fade and motion remain, but the saved window origin never changes, eliminating interrupted-animation drift and top-edge/menu-bar overlap.

### Universal annotation and board transforms — 0.8.0

Select now considers every stored annotation, including Pen and Highlighter freehand strokes, and resolves overlapping content from topmost to bottommost at the exact click point. Freehand resizing applies an affine transform to every sampled point and scales stroke width while preserving color and opacity. If no annotation is hit, the active board can be selected, moved or resized with four handles and display-bound clamping. Native event tests cover freehand and board selection independently, while core tests verify freehand geometry and appearance survive resizing.
