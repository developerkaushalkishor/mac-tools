# Use ScreenInk

ScreenInk runs in the macOS menu bar and starts in normal mouse mode. Its toolbar appears below the menu bar at the top center unless you previously moved it.

## Controls

| Control | Action |
| --- | --- |
| Dotted handle | Drag the toolbar; placement is saved between launches |
| Pen | Toggle drawing / normal mode; cyan means drawing is active |
| Highlighter | Draw a broad translucent stroke; cyan means selected |
| Eraser | Remove each complete stroke touched by the pointer; one drag is one undo step |
| Scope | Draw a short-lived laser-pointer trail that never enters drawing history |
| Color dots | Select one of six quick ink colors; purple is the default |
| Palette | Open all 24 preset colors; the selected color has a ring |
| Line-weight icon | Cycle Thin (2), Medium (4) and Thick (8) point strokes |
| Back / forward arrows | Undo / redo on the toolbar's display |
| Trash | Clear strokes on the toolbar's display; Undo can restore them |
| Timer | Toggle fading for newly drawn strokes; cyan means enabled |
| Cursor rays | Toggle the presentation cursor halo; cyan means enabled |
| Eye slash | Temporarily hide/show all ink without deleting it |
| Eye | Toggle toolbar auto-hide; cyan means enabled |
| Up-chevron | Hide the toolbar immediately and return to normal input |
| Menu-bar pen-and-ink icon | Show/Hide Toolbar, Reset Toolbar to Top Center, Auto-hide Toolbar, Toggle Drawing, Clear Drawing and Quit ScreenInk |

The toolbar uses icon tooltips and accessibility labels to explain actions.

## Draw and return to work

Click the pen or highlighter, then drag on any connected display. Choose the eraser and drag across an annotation to remove the complete touched stroke; Undo restores an entire eraser gesture. Existing strokes retain their color, opacity and width when you choose new settings. Press Escape or right-click on a drawing canvas to return to normal clicks on all displays while keeping ink visible. The exit right-click is consumed; subsequent clicks work normally. The toolbar pen or menu's Toggle Drawing command also switches modes.

While the drawing canvas has keyboard focus, Command-Z undoes and Shift-Command-Z redoes. These are not global shortcuts. Use toolbar buttons if focus is elsewhere.

## Presentation controls

Fading ink applies to new strokes while the timer button is active. Choose a 2, 5 or 10 second delay from the menu-bar icon; after that delay the stroke fades smoothly over one second. Permanent strokes and fading strokes can coexist.

The scope button activates an Excalidraw-style laser pointer. Drag to create a short red/color trail that fades in under a second and is never stored in Undo history. The cursor-rays button shows a yellow halo around the pointer on every connected display and increases pointer sampling to 60 FPS for smooth movement. The eye-slash button hides annotations without deleting their history; click it again to reveal them.

The default system-wide drawing toggle is **Control-Option-Command-D**. Change it from **ScreenInk menu-bar icon → Global Drawing Shortcut**. Available choices use multiple modifiers to avoid common single-app shortcuts and work without Accessibility permission.

## Hiding and revealing

Auto-hide is enabled by default. The toolbar hides after two seconds away; holding a mouse button or hovering over the toolbar or reveal area keeps it available. Move the pointer against the physical top edge at the center of any connected display to show it on the next pointer check, without a dwell delay. The horizontal trigger is exactly as wide as the toolbar and the vertical trigger is only four points high. The menu's Show Toolbar command is always the alternative.

Dragging the toolbar preserves its chosen location. Hover-reveal on the same display keeps that location. Touching another display's top-center edge moves the toolbar to the top center of that display. Reset Toolbar to Top Center restores the default. The reveal region is centered on the physical display, is exactly one toolbar wide and covers only its top four points. A reveal request on another display moves the toolbar even when it is already visible. After manually hiding at the edge, leave the reveal area and re-enter to show it again.

**Auto-hide hides only the toolbar and keeps the drawing mode unchanged.** The manual Hide Toolbar command also exits drawing mode. Neither erases ink. Use Trash or Clear Drawing to clear annotations.

## Session limits

- Quit discards drawings; no save, export or screenshot tool is implemented yet.
- Every connected display has an independent canvas and undo history. Toolbar actions target the toolbar's display; keyboard undo/redo target the focused canvas.
- Color, thickness and drawing/normal mode are shared across displays.
- A display configuration change exits drawing mode safely. Ink is retained in memory by display identity across disconnect/reconnect during the same app session; replacing a monitor with a different identity starts a new canvas.
- Toolbar position, auto-hide, selected tool, ink color, thickness, fading settings, cursor halo and global shortcut are saved across launches.
- Fullscreen, Spaces, screen sharing, display reconnection and long sessions need further real-world validation.

See the [testing checklist](TESTING.md). Report an issue with your OS, architecture, display arrangement, exact actions and expected/actual results. Crop private information from screenshots.
