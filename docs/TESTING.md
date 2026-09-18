# Verification

## Automated

```bash
bash scripts/test.sh
bash scripts/build.sh
codesign --verify --strict --verbose=2 dist/ScreenInk.app
plutil -lint Resources/Info.plist
```

Model regressions cover restoring a cleared canvas, invalidating redo after a new stroke, and preserving redo after no-op operations. They do not verify window focus or visual rendering.

## Desktop smoke checklist

- [ ] Launch app; toolbar and ScreenInk menu-bar icon appear; underlying apps remain clickable by default.
- [ ] Click the pen icon; draw a line, curve and single dot. All appear under the mouse.
- [ ] Change color/width; existing strokes keep their original appearance.
- [ ] Undo and redo a stroke; clear then undo restores the drawing.
- [ ] Press Escape in drawing mode; click and type in an underlying app.
- [ ] Switch Draw/Normal several times; toolbar remains usable.
- [ ] Move toolbar by its dotted handle; the ScreenInk menu-bar icon > Show Toolbar restores visibility.
- [ ] Quit; all overlays disappear and no input remains intercepted.
- [ ] Switch Spaces and enter/exit a fullscreen app; record actual behavior.
- [ ] Change display resolution or reconnect the external display; normal mode is restored and toolbar is reachable.
- [ ] Use for 10 minutes; check memory, responsiveness and idle CPU.

## Current limitations

- Every connected display has a canvas; physical hot-plug and fullscreen interaction still need manual verification.
- Annotation positions do not rescale on display changes.
- Drawings are in memory only; quitting discards them.
- Stroke points and canvas redraw are not optimized for large drawings.
- Six quick colors and the complete 24-color palette are available.
- No eraser, highlighter, fade, cursor halo, shapes, text, boards, screenshots or global shortcuts yet.
- Fullscreen, multiple displays, screen sharing and long sessions remain unverified until explicitly checked.

See `STATUS.md` for the actual commands and desktop checks performed during setup.

## Toolbar update checks

- [ ] Fresh toolbar position is top-center below the menu bar.
- [ ] Hover each icon; readable tooltip and accessibility label identify its action.
- [ ] Selected ink has a ring; active pen and auto-hide controls are cyan.
- [ ] Move away for two seconds: only the toolbar disappears; existing ink is retained.
- [ ] Hover each display's top-center edge: toolbar appears on that display after a short dwell.
- [ ] Dragging or clicking controls does not hide the toolbar mid-interaction.
- [ ] Manual hide exits drawing and the menu-bar icon can always show the toolbar again.
- [ ] Turn auto-hide off: toolbar stays visible; manual hide and edge reveal still work.
- [ ] Move the toolbar, quit/relaunch, and verify saved position. Reset returns it to top-center.
- [ ] Disconnect a display: toolbar is restored to a reachable display position.
- [ ] The menu-bar nib icon has appropriate contrast on light and dark menu bars.

Automated visibility regressions cover idle timeout, delayed edge reveal, pointer/drag protection, manual-hide edge rearming, explicit show and disabling automatic hiding.

## Multi-display regression checks

Automated AppKit tests require a logged-in macOS desktop. They create native canvas windows without injecting system input. `DisplayCanvasTests` checks frame/local-coordinate alignment and mouse-event transparency for every actual connected screen, plus a simulated negative-origin layout. Display registry tests cover separate histories, reorder, detach/reconnect and an empty display list.

- [ ] Draw different marks on each display; check cursor alignment and shared color/width.
- [ ] Press Escape from each canvas and verify normal clicks work on all displays.
- [ ] Move/reveal the toolbar on each display; Undo/Redo/Clear affect only that display.
- [ ] Hide the toolbar and hover at another display's top center; verify relocation.
- [ ] Reorder displays or change resolution; retained ink remains on the same display, in local coordinates.
- [ ] Disconnect/reconnect a monitor during drawing; input is released and that monitor's ink returns within the same session.
- [ ] Repeat with mixed scaling and displays placed left, right, above and below the primary.

## Toolbar reveal and right-click regression

Automated coverage includes inclusive top-edge coordinates, negative display origins, side Dock geometry, twenty repeated hide/reveal cycles, and right-click releasing all active canvases while retaining undoable ink.

- [ ] Repeatedly reveal from the exact top-center pixel on each screen.
- [ ] Move from the reveal area down to Undo/Redo/Clear without the toolbar disappearing.
- [ ] With the toolbar visible on one display, hover at another display's top center.
- [ ] Repeat with fullscreen apps and after switching Spaces.
- [ ] While drawing, right-click on each display; verify ink remains and ordinary app clicks resume on all screens.
- [ ] Re-enable the pen and verify Undo/Redo still work.

## Milestone 1 essential drawing

- [ ] Draw with the highlighter across itself and verify one stroke remains consistently translucent.
- [ ] Drag the eraser across several strokes; verify complete touched strokes disappear together.
- [ ] Press Undo once and verify the entire last eraser drag is restored; Redo removes it again.
- [ ] Open the palette and select colors outside the six quick choices.
- [ ] Quit and reopen ScreenInk; verify the last selected tool, color and width are restored.
- [ ] Repeat pen, highlighter and eraser checks on every connected display.

## Milestone 2 presentation controls

- [ ] Enable fading ink, draw with each 2/5/10-second delay and verify a smooth one-second fade.
- [ ] Verify earlier permanent ink stays visible while later fading ink disappears.
- [ ] Enable the cursor halo and move across every display, fullscreen app and Space.
- [ ] Hide ink, verify history remains, then reveal and use Undo/Redo.
- [ ] Use the selected global shortcut while another app is active; verify drawing toggles without typing into that app.
- [ ] Change the global shortcut, restart ScreenInk and verify the new choice remains active.
- [ ] Leave ScreenInk idle with no fading strokes and check that CPU use remains low.
- [ ] Move near, but not against, the top-center edge and verify the toolbar stays hidden; touch the top four-point strip to reveal it.
- [ ] Enable Cursor Halo and verify it follows fast circles smoothly on every display.
- [ ] Use Laser Pointer for several long gestures; verify trails fade quickly and Undo affects only permanent ink.

## Milestone 3 shapes

- [ ] Draw lines and arrows in every direction and verify the arrowhead follows the endpoint.
- [ ] Hold Shift and verify lines/arrows snap to 45-degree increments.
- [ ] Draw rectangles and ellipses in all four drag directions.
- [ ] Hold Shift and verify rectangles become squares and ellipses become circles.
- [ ] Verify color, width and fading ink apply to every shape.
- [ ] Erase each shape by touching its outline or arrowhead, then Undo and Redo.
- [ ] Repeat shape drawing on every connected display.
- [ ] With the Pen tool, draw a rough closed circle, square and diamond. Verify each snaps to the expected softly rounded shape on pointer release.
- [ ] Draw open curves and handwriting with the Pen tool. Verify ambiguous strokes are not converted.

## Milestone 4 text

- [ ] Select Text, click each display, type and press Return. Verify the committed text stays at the chosen location.
- [ ] Cycle through 20, 28, 40 and 56 point sizes and verify new text uses each size.
- [ ] Change the ink color, place text and verify its color remains unchanged after selecting another color.
- [ ] Click existing text with Text selected, edit it, then verify Undo and Redo restore each version.
- [ ] Start typing and press Escape. Verify the draft is discarded and clicks reach the underlying app.
- [ ] Erase text, clear it and use Fading Ink with text; verify history and fade behavior match drawing annotations.
