# Use ScreenInk

ScreenInk runs in the macOS menu bar and starts in normal mouse mode. Its toolbar appears below the menu bar at the top center unless you previously moved it.

## Controls

| Control | Action |
| --- | --- |
| Dotted handle | Drag the toolbar; placement is saved between launches |
| Cursor | Return to normal mode so clicks interact with underlying apps; cyan means selected |
| Pen | Select permanent freehand ink; cyan means selected |
| Highlighter | Select broad translucent ink; yellow means selected |
| Eraser | Remove each complete stroke touched by the pointer; one drag is one undo step |
| Laser burst | Draw a progressively fading laser-pointer trail that never enters drawing history |
| Shapes | Open line, arrow, rounded rectangle, ellipse and diamond tools |
| Text | Click the canvas to place text or click existing text to edit it |
| Color dots | Select one of six quick ink colors; purple is the default |
| Palette | Open all 24 preset colors; the selected color has a ring |
| Line-weight icon | Cycle Thin (2), Medium (4) and Thick (8) point strokes |
| Text-size icon | Cycle 20, 28, 40 and 56 point text |
| Back / forward arrows | Undo / redo on the toolbar's display |
| Trash | Clear strokes on the toolbar's display; Undo can restore them |
| Timer | Toggle fading for newly drawn strokes; cyan means enabled |
| Cursor rays | Toggle the presentation cursor halo; cyan means enabled |
| Eye slash | Temporarily hide/show all ink without deleting it |
| Eye | Toggle toolbar auto-hide; cyan means enabled |
| Up-chevron | Hide the toolbar immediately and return to normal input |
| Menu-bar pen-and-ink icon | Show/Hide Toolbar, Reset Toolbar to Top Center, Auto-hide Toolbar, Toggle Drawing, Clear Drawing and Quit ScreenInk |

The toolbar uses icon tooltips and accessibility labels to explain actions.

## Shapes

Open the Shapes button and choose Line, Arrow, Rectangle, Ellipse or Diamond, then drag on any display. Hold Shift while dragging to snap lines and arrows to 45-degree angles or constrain rectangles, ellipses and diamonds to equal width and height. Rectangle and diamond corners are softly rounded, and every closed shape has a subtle repeatable pen wobble for a natural hand-drawn feel while keeping the requested bounds accurate. Shapes use the selected color and width, can use fading ink, participate in whole-stroke erasing and share the normal Undo/Redo history.

The Pen tool also recognizes deliberate closed gestures. Draw a circle/ellipse, rectangle/square or diamond and release the pointer; when the gesture confidently matches one of those outlines, ScreenInk replaces it with the corresponding smooth hand-drawn shape. Open or ambiguous strokes remain unchanged.

## Text

Select Text, then click anywhere on a drawing canvas and type. Press Return to commit the annotation. Press Escape to cancel the current edit and return all displays to normal input. To edit existing text, keep Text selected and click the annotation. Text uses the selected ink color and the current 20, 28, 40 or 56 point size. Completed text participates in Undo/Redo, Clear, whole-annotation erasing and optional Fading Ink.

## Draw and return to work

Click the pen or highlighter, then drag on any connected display. Choose the eraser and drag across an annotation to remove the complete touched stroke; Undo restores an entire eraser gesture. Existing strokes retain their color, opacity and width when you choose new settings. Press Escape or right-click on a drawing canvas to return to normal clicks on all displays while keeping ink visible. The exit right-click is consumed; subsequent clicks work normally. The toolbar pen or menu's Toggle Drawing command also switches modes.

While the drawing canvas has keyboard focus, Command-Z undoes and Shift-Command-Z redoes. These are not global shortcuts. Use toolbar buttons if focus is elsewhere.

## Presentation controls

Fading ink starts OFF each time ScreenInk launches and applies to new strokes only while the timer button is active. Choose a 2, 5 or 10 second delay from the menu-bar icon; after that delay the stroke fades smoothly over one second. ScreenInk remembers the selected delay, while the enabled state resets to OFF. Permanent strokes and fading strokes can coexist.

The laser-burst button activates an Excalidraw-style laser pointer. Drag to create a smooth red trail whose oldest tail progressively thins and fades toward the bright head. Like Excalidraw, the length limit uses the latest 50 pointer samples rather than a fixed pixel distance, so faster movement creates a naturally longer trail. Samples expire over one second and are never stored in Undo history. The cursor-rays button shows a yellow halo around the pointer on every connected display and increases pointer sampling to 60 FPS for smooth movement. The eye-slash button hides annotations without deleting their history; click it again to reveal them.

The default system-wide drawing toggle is **Control-Option-Command-D**. Change it from **ScreenInk menu-bar icon → Global Drawing Shortcut**. Available choices use multiple modifiers to avoid common single-app shortcuts and work without Accessibility permission.

## Hiding and revealing

Auto-hide is enabled by default. The toolbar hides after two seconds away; holding a mouse button or hovering over the toolbar or reveal area keeps it available. Move the pointer against the physical top edge at the center of any connected display to show it on the next pointer check, without a dwell delay. The toolbar then fades in while sliding 12 points down from the top with a short ease-out animation. The horizontal trigger is exactly as wide as the toolbar and the vertical trigger is only four points high. The menu's Show Toolbar command is always the alternative.

Dragging the toolbar preserves its chosen location. Hover-reveal on the same display keeps that location. Touching another display's top-center edge moves the toolbar to the top center of that display. Reset Toolbar to Top Center restores the default. The reveal region is centered on the physical display, is exactly one toolbar wide and covers only its top four points. A reveal request on another display moves the toolbar even when it is already visible. After manually hiding at the edge, leave the reveal area and re-enter to show it again.

**Auto-hide hides only the toolbar and keeps the drawing mode unchanged.** The manual Hide Toolbar command also exits drawing mode. Neither erases ink. Use Trash or Clear Drawing to clear annotations.

## Session limits

- Quit discards drawings; no save, export or screenshot tool is implemented yet.
- Every connected display has an independent canvas and undo history. Toolbar actions target the toolbar's display; keyboard undo/redo target the focused canvas.
- Color, thickness and drawing/normal mode are shared across displays.
- A display configuration change exits drawing mode safely. Ink is retained in memory by display identity across disconnect/reconnect during the same app session; replacing a monitor with a different identity starts a new canvas.
- Toolbar position, auto-hide, selected tool, ink color, thickness, text size, fading delay, cursor halo and global shortcut are saved across launches. Fading Ink itself starts OFF for each new session.
- Fullscreen, Spaces, screen sharing, display reconnection and long sessions need further real-world validation.

See the [testing checklist](TESTING.md). Report an issue with your OS, architecture, display arrangement, exact actions and expected/actual results. Crop private information from screenshots.
