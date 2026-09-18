# Use ScreenInk

ScreenInk runs in the macOS menu bar and starts in normal mouse mode. Its toolbar appears below the menu bar at the top center unless you previously moved it.

## Controls

| Control | Action |
| --- | --- |
| Dotted handle | Drag the toolbar; placement is saved between launches |
| Cursor | Return to normal mode so clicks interact with underlying apps; cyan means selected |
| Dashed rectangle | Select, move or resize any saved annotation or board |
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
| Cursor click | Toggle an expanding ripple for left clicks in ScreenInk and other apps |
| Eye slash | Temporarily hide/show all ink without deleting it |
| Board | Choose the live screen, a whiteboard or a blackboard background |
| Eye | Toggle toolbar auto-hide; cyan means enabled |
| Up-chevron | Hide the toolbar immediately and return to normal input |
| Menu-bar pen-and-ink icon | Show/Hide Toolbar, Reset Toolbar to Top Center, Auto-hide Toolbar, Toggle Drawing, Clear Drawing and Quit ScreenInk |

The toolbar uses icon tooltips and accessibility labels to explain actions.

While drawing mode is active, the pointer also identifies the selected tool. Pen, Highlighter, Eraser, Laser, Select and each shape use their own symbol cursor with a centered action point; Text uses the standard macOS I-beam. Returning to Cursor/normal mode restores the cursor behavior of the underlying app.

## Shapes

Open the Shapes button and choose Line, Arrow, Rectangle, Ellipse or Diamond, then drag on any display. Hold Shift while dragging to snap lines and arrows to 45-degree angles or constrain rectangles, ellipses and diamonds to equal width and height. Rectangle and diamond corners are softly rounded, and every closed shape has a subtle repeatable pen wobble for a natural hand-drawn feel while keeping the requested bounds accurate. Shapes use the selected color and width, can use fading ink, participate in whole-stroke erasing and share the normal Undo/Redo history.

The Pen tool also recognizes deliberate closed gestures. Draw a circle/ellipse, rectangle/square or diamond and release the pointer; when the gesture confidently matches one of those outlines, ScreenInk replaces it with the corresponding smooth hand-drawn shape. Open or ambiguous strokes remain unchanged.

## Text

Select Text, then click anywhere on a drawing canvas and type in the high-contrast editor. The editor shows a usage hint, keeps keyboard focus and widens as the content grows. Press Return to commit the annotation. Press Escape to cancel the current edit and return all displays to normal input. To edit existing text, keep Text selected and click the annotation. Text uses the selected ink color, the current 20, 28, 40 or 56 point size, and the saved font style.

Open the font button beside Text Size to choose System Rounded, Avenir Next or Helvetica Neue for clear teaching text, or Chalkboard, Noteworthy or Marker Felt for short handwriting-style notes. The menu previews every style in its own typeface. Choosing a font applies it to future text and to any currently selected text annotations; several selected text items change together in one Undo step. Non-text annotations in the same selection remain unchanged. Completed text participates in Undo/Redo, Clear, whole-annotation erasing and optional Fading Ink.

Choosing a font also activates Text mode automatically, so the next canvas click starts typing without another toolbar action. The cursor becomes the standard macOS I-beam. The editor begins at the exact clicked text origin and previews the final font and color with a compact “Type here…” placeholder; hover the editor for Return and Escape instructions.

Use the alignment button beside the font picker for Left, Center or Right alignment. The click point acts as the text's left edge, center anchor or right edge respectively, and the inline editor previews that placement before saving. Alignment is remembered for future text. When one or several text annotations are active in Select mode, choosing an alignment updates them together in one Undo step and leaves selected shapes unchanged.

## Select, move and resize

Choose the dashed-rectangle Select tool and click an individual pen stroke, highlighter stroke, line, arrow, rectangle, ellipse, diamond or text annotation. The topmost annotation under the exact click is selected, so overlapping items remain individually editable. Drag across empty canvas or a board interior to create a cyan marquee and select every annotation it touches. Drag selected content to move it, or drag a group corner handle to resize all selected annotations proportionally. A single freehand stroke or closed shape has four corner handles, a single line or arrow has endpoint handles, and single text has one proportional size handle. Freehand resizing preserves every sampled point, color and opacity while scaling its line width.

With one or several annotations selected, choose a quick dot or any color from the palette to recolor the complete selection in one Undo step. The chosen color also remains active for new ink.

Click only the visible frame of a whiteboard or blackboard to select the board itself. Its interior remains available for selecting annotations. Drag the frame to move the board or use any corner handle to resize it; annotations centered inside the board at the start of the gesture move or scale with it, while outside annotations remain unchanged. A full-display board becomes a movable custom board after the first transform. Boards stay within their display and keep a minimum size of 120 × 80 points. Annotation and contained-content transforms create one Undo step; the board frame itself remains presentation state. Selecting Cursor or exiting drawing mode removes all selection handles.

## Draw and return to work

Click the pen or highlighter, then drag on any connected display. Choose the eraser and drag across an annotation to remove the complete touched stroke; Undo restores an entire eraser gesture. Existing strokes retain their color, opacity and width when you choose new settings. Press Escape or right-click on a drawing canvas to return to normal clicks on all displays while keeping ink visible. The exit right-click is consumed; subsequent clicks work normally. The toolbar pen or menu's Toggle Drawing command also switches modes.

While the drawing canvas has keyboard focus, Command-Z undoes and Shift-Command-Z redoes. These are not global shortcuts. Use toolbar buttons if focus is elsewhere.

## Presentation controls

Fading ink starts OFF each time ScreenInk launches and applies to new strokes only while the timer button is active. Choose a 2, 5 or 10 second delay from the menu-bar icon; after that delay the stroke fades smoothly over one second. ScreenInk remembers the selected delay, while the enabled state resets to OFF. Permanent strokes and fading strokes can coexist.

The laser-burst button activates an Excalidraw-style laser pointer. Drag to create a smooth red trail whose oldest tail progressively thins and fades toward the bright head. Like Excalidraw, the length limit uses the latest 50 pointer samples rather than a fixed pixel distance, so faster movement creates a naturally longer trail. Samples expire over one second and are never stored in Undo history. The cursor-rays button shows a yellow halo around the pointer on every connected display and increases pointer sampling to 60 FPS for smooth movement. The eye-slash button hides annotations without deleting their history; click it again to reveal them.

The cursor-click button enables Click Animations. Every left click shows a short cyan center flash and an expanding ring on the correct display, including clicks made in other apps while ScreenInk is in normal mode. The visual never blocks or replaces the original click, is excluded from drawing history and disappears after half a second. ScreenInk installs click monitoring only while this option is enabled and remembers the preference across launches.

The default system-wide drawing toggle is **Control-Option-Command-D**. Change it from **ScreenInk menu-bar icon → Global Drawing Shortcut**. Available choices use multiple modifiers to avoid common single-app shortcuts and work without Accessibility permission.

## Whiteboard and blackboard

Open the Board button, choose a scope from its second row, then choose Screen, Whiteboard or Blackboard from the first row. **Current Display** applies a full board only to the display containing the toolbar. **All Displays** applies the chosen background independently to every connected display. **Region** enters a crosshair mode; drag an area at least 120 × 80 points on the toolbar's display to place a custom-sized board. Screen removes the board from the selected display scope without changing or clearing annotations.

Whiteboards use a slim aluminum gradient, rounded corners, a subtle floating shadow and an integrated marker tray. Blackboards use a wider warm-wood frame with restrained grain, rounded corners, depth shadow and a chalk tray. Both are rendered as native vectors, so full-display and custom boards stay sharp at Retina resolutions. Background switches are presentation state and do not consume Undo/Redo history. If the active ink is white when Whiteboard is selected, ScreenInk switches new ink to dark gray; selecting Blackboard while dark-gray ink is active switches new ink to white.

ScreenInk uses the start of each drawing gesture to decide its boundary. If Pen, Highlighter, Laser, Line, Arrow, Rectangle, Ellipse or Diamond starts inside the board's writable surface, the complete gesture stays inside it even when the pointer accidentally crosses the frame. A gesture that starts outside the board remains unrestricted and can be drawn anywhere on the screen canvas.

## Screenshots

Open the camera button to choose one of four actions: copy the full toolbar display, copy a selected region, save the full display as PNG or save a selected region as PNG. Region actions switch the toolbar display into crosshair mode; drag at least 20 × 20 points and release to capture. Full-display actions use the display currently holding the toolbar.

Screenshots are currently experimental. The intended output includes visible ScreenInk ink and boards while excluding the toolbar and mouse pointer. Clipboard actions replace the current clipboard image, and Save actions open the native macOS Save panel with a timestamped PNG filename. ScreenInk requests Screen Recording permission only after the first screenshot action. Capture still fails on the current test Mac after the documented permission flow, so do not rely on it for important work yet.

## Hiding and revealing

Auto-hide is enabled by default. The toolbar hides after two seconds away; holding a mouse button or hovering over the toolbar, an open tool popover or the reveal area keeps it available. Move the pointer against the physical top edge at the center of any connected display to show it on the next pointer check, without a dwell delay. The toolbar then fades in while its internal content slides smoothly into place; its window position remains fixed so it cannot drift into the menu-bar area. The horizontal trigger is exactly as wide as the toolbar and the vertical trigger is only four points high. The menu's Show Toolbar command is always the alternative.

Dragging the toolbar preserves its chosen location. Hover-reveal on the same display keeps that location. Touching another display's top-center edge moves the toolbar to the top center of that display. Reset Toolbar to Top Center restores the default. The reveal region is centered on the physical display, is exactly one toolbar wide and covers only its top four points. A reveal request on another display moves the toolbar even when it is already visible. After manually hiding at the edge, leave the reveal area and re-enter to show it again.

**Auto-hide hides only the toolbar and keeps the drawing mode unchanged.** The manual Hide Toolbar command also exits drawing mode. Neither erases ink. Use Trash or Clear Drawing to clear annotations.

## Session limits

- Quit discards editable drawings; screenshots export only the current pixels and cannot restore annotation history.
- Every connected display has an independent canvas and undo history. Toolbar actions target the toolbar's display; keyboard undo/redo target the focused canvas.
- Color, thickness and drawing/normal mode are shared across displays.
- A display configuration change exits drawing mode safely. Ink is retained in memory by display identity across disconnect/reconnect during the same app session; replacing a monitor with a different identity starts a new canvas.
- Toolbar position, auto-hide, selected tool, ink color, thickness, text size, fading delay, cursor halo and global shortcut are saved across launches. Fading Ink itself starts OFF for each new session.
- Screenshot permission/capture, fullscreen, Spaces, screen sharing, physical display reconnection and long sessions need further real-world validation.

See the [testing checklist](TESTING.md). Report an issue with your OS, architecture, display arrangement, exact actions and expected/actual results. Crop private information from screenshots.
