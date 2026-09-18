# Use ScreenInk

ScreenInk runs in the macOS menu bar and starts in normal mouse mode. Its toolbar appears below the menu bar at the top center unless you previously moved it.

## Controls

| Control | Action |
| --- | --- |
| Dotted handle | Drag the toolbar; placement is saved between launches |
| Pen | Toggle drawing / normal mode; cyan means drawing is active |
| Color dots | Select one of six ink colors; the selected color has a ring |
| Line-weight icon | Cycle Thin (2), Medium (4) and Thick (8) point strokes |
| Back / forward arrows | Undo / redo |
| Trash | Clear all strokes; Undo can restore them |
| Eye | Toggle toolbar auto-hide; cyan means enabled |
| Up-chevron | Hide the toolbar immediately and return to normal input |
| Menu-bar pen-and-ink icon | Show/Hide Toolbar, Reset Toolbar to Top Center, Auto-hide Toolbar, Toggle Drawing, Clear Drawing and Quit ScreenInk |

The toolbar uses icon tooltips and accessibility labels to explain actions.

## Draw and return to work

Click the pen, then drag on the primary display. Existing strokes retain their color and width when you choose new settings. Press Escape to return to normal clicks while keeping ink visible. The toolbar pen or menu's Toggle Drawing command also switches modes.

While the drawing canvas has keyboard focus, Command-Z undoes and Shift-Command-Z redoes. These are not global shortcuts. Use toolbar buttons if focus is elsewhere.

## Hiding and revealing

Auto-hide is enabled by default. The toolbar hides after two seconds away; holding a mouse button or hovering over the toolbar keeps it available. Hover near the top-center edge of the display containing the toolbar for approximately 0.25 seconds to show it again. The menu's Show Toolbar command is always the alternative.

Dragging the toolbar preserves its chosen location. Hover-reveal shows it at that location, not automatically back at the top. Reset Toolbar to Top Center restores the default. The reveal region spans 320 points around the display center and includes the menu-bar area and eight points below it.

**Auto-hide hides only the toolbar and keeps the drawing mode unchanged.** The manual Hide Toolbar command also exits drawing mode. Neither erases ink. Use Trash or Clear Drawing to clear annotations. Fading ink is not implemented.

## Session limits

- Quit discards drawings; no save, export or screenshot tool is implemented yet.
- Only the primary display has a drawing canvas, even if you move the toolbar to another display.
- Toolbar position and auto-hide preference are saved. Pen color and thickness are not currently saved across launches.
- Fullscreen, Spaces, screen sharing, display reconnection and long sessions need further real-world validation.

See the [testing checklist](TESTING.md). Report an issue with your OS, architecture, display arrangement, exact actions and expected/actual results. Crop private information from screenshots.
