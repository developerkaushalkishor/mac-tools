# Project status

Last reviewed: 2026-09-18. ScreenInk is an early 0.1.0 prototype, distributed as source.

## Repository

The repository is public at https://github.com/developerkaushalkishor/mac-tools. At the documentation audit, remote `main` and the local starting commit both resolved to `217e1a7dfd8b5c044f223277d34dc588e118d36f`. No GitHub releases were published at that time. Later documentation edits are not implied to be pushed by this snapshot.

## Implemented

- Primary-display freehand pen, six colors and three widths.
- Undo/redo and clear, with recoverable clear history.
- Drawing/normal mode and menu-bar controls.
- Top-center icon toolbar, saved draggable placement, reset, manual hide, auto-hide and top-edge reveal.

See [usage](docs/USAGE.md) for the exact behavior and [roadmap](docs/PLAN.md) for future work.

## Verification evidence

| Check | Recorded result |
| --- | --- |
| Swift Testing suite | Seven tests passed: three history and four toolbar visibility regressions |
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

Ink is stored only in memory; quitting loses drawings. Moving the toolbar does not add drawing support to another screen. There is no screenshot/export or eraser yet. Next work is hands-on validation followed by a stroke eraser and highlighter.
