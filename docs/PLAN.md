# ScreenInk implementation plan

Prepared: 2026-09-18. Goal: an MIT-licensed, offline macOS annotation utility inspired by Epic Pen and Presentify. Build the smallest usable version first, then ship one incremental feature after real use.

## Scope and sequencing

| Milestone | Deliverable | Acceptance gate | Estimated additional effort |
| --- | --- | --- | --- |
| 0 — Setup and starter | Swift package, app bundle, pen, six colors, width, normal mode, undo/redo, clear, menu and toolbar | Build/tests pass; complete desktop smoke checks before calling it daily-use ready | Implemented; allow time for hands-on feedback/fixes |
| 1 — Essential drawing | Whole-stroke eraser, highlighter, 24-color palette, saved preferences | Erasing restores via undo; highlighter does not turn opaque on self-overlap; restart retains settings | Implemented in 0.2.0; hands-on acceptance check pending |
| 2 — Presentation controls | Fading ink with delay, cursor halo, show/hide ink, configurable global toggle | Fade uses elapsed time; ordinary clicks work; shortcuts do not steal common app shortcuts; idle CPU stays low | Implemented in 0.3.0; hands-on acceptance check pending |
| 3 — Shapes | Line, arrow, rectangle and ellipse; Shift constraints | Correct previews in each drag direction; undo/redo and colors work consistently | 1–2 days |
| 4 — Text | Place/edit text, font size/color, commit/cancel | Typing focus returns to underlying app on normal mode; Escape behavior defined | 1–2 days |
| 5 — Boards | Whiteboard and blackboard toggle | Background changes preserve annotations; undo stays predictable | 0.5–1 day |
| 6 — Screenshots | Full display and region capture, PNG save, clipboard | Correct Retina output; toolbar excluded but ink included; denied permission handled | 1–2 days |
| 7 — Reliability | Per-display overlays implemented; remaining fullscreen/Spaces matrix, physical reconnect verification, performance and packaging | Manual compatibility checklist passes on actual hardware | 3–5 days |
| 8 — Optional Presentify extras | Click animations, spotlight, zoom | User confirms extras after using the core app; zoom feedback loop avoided | Re-estimate separately |
| 9 — Public binary distribution | Stable identity, Developer ID/notarization and documented release/update process | Install and update smoke checks pass on a clean Mac | Re-estimate when distribution is scoped |

These are planning ranges for focused implementation, not promises. Milestones 1–6 total approximately 6.5–12 days after the starter; reliability and first-time learning add time. The initial 2–4 week stable-app target remains a reasonable planning window, subject to hands-on findings.

ScreenInk is MIT-licensed. There is no planned activation server, subscription gate or per-device licence management for this open-source app. The software licence and Apple signing/notarization are separate concerns. “Great value” is a product goal, not a code feature.

## Development loop

1. Complete the starter's desktop checklist.
2. Use it during a real explanation, code review or tutorial.
3. Record the concrete inconvenience and reproduction steps in `docs/FEEDBACK.md`.
4. Select one feature from the next milestone.
5. Implement and test the behavior, including interactions with existing tools.
6. Use that build before starting the next feature.

Do not implement the complete roadmap in one pass. Initial next task: validate the starter during real use, then add the stroke eraser.

## Architecture and extension points

The app delegate owns native windows. The canvas converts window mouse coordinates to local points and renders strokes. `InkCore` owns platform-independent drawing history; it has no permission or windowing code. Normal mode makes the drawing panel transparent to mouse events while leaving the toolbar interactive.

For shapes/text, evolve `Stroke` into an annotation enum rather than spreading tool-specific state throughout the app delegate. Multi-display support now uses `DisplayCanvas` panels and a `DisplayRegistry`; drawings stay in display-local coordinates. When history becomes expensive, replace bounded snapshots with commands. Current history is capped at 100 operations, but point storage and long-session performance are not yet optimized.

Fading ink should use timestamps, with redraw scheduling only while fading content exists. Screenshot capture should exclude the toolbar window specifically; excluding the entire app would also exclude ink. Prefer no continuous screen capture until zoom is introduced.

## Risks to resolve through tests

- Fullscreen and Spaces flags express window behavior but do not replace validation across apps.
- Normal mode must release both mouse capture and drawing keyboard focus.
- A missing/disconnected display must not strand the toolbar or trap input.
- Newer SDK availability must not silently break the macOS 14 deployment target.
- Permission prompts are feature-specific; do not request screenshot access at startup.
- The prototype stores drawings only in memory. Persistent drawings are a separate feature.

## Completion definition for the first daily-use version

Drawing is responsive; a single action returns to ordinary work; undo and clear are reliable; toolbar stays reachable; no permissions are requested for unused features; build and regression tests pass; the user's actual screen arrangement is tested. Compilation alone does not meet this definition.
