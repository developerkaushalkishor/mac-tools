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
- Redundant sub-point samples and expired fading ink are bounded; extended-session profiling with very large permanent drawings remains pending.
- Six quick colors and the complete 24-color palette are available.
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
- [ ] Move the toolbar between a wide and narrow display: quick colors collapse on the narrow display, More exposes every secondary control, and the panel remains fully inside both screens.
- [ ] Keep the pointer over More and each nested control for more than two seconds: neither the toolbar nor the More popover auto-hides during interaction.
- [ ] The menu-bar nib icon has appropriate contrast on light and dark menu bars.
- [ ] Disable ScreenInk from the toolbar; verify all overlays disappear, ordinary input works and top-edge hover cannot reveal the toolbar.
- [ ] Enable ScreenInk from the menu-bar icon; verify existing annotations and the toolbar return. Restart once while disabled and verify the setting persists.

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
- [ ] Verify the text editor shows its hint, receives typing immediately and expands horizontally for longer text.
- [ ] Open the font picker and verify all six rows preview their own style; create text with every font, restart, and verify the last choice is restored.
- [ ] Select one and then several text annotations, change the font, and verify one Undo restores the previous fonts without changing selected shapes.
- [ ] Create Left, Center and Right text at the same anchor and verify the editor plus final annotation use that anchor correctly. Apply alignment to several selected texts and verify one Undo restores them without changing selected shapes.
- [ ] Select pen, highlighter, every shape type and text individually, then drag each selection to move it.
- [ ] Resize closed shapes from all four corners, lines/arrows from both endpoints and text from its size handle.
- [ ] Undo and Redo each transform and verify one drag produces exactly one history step.
- [ ] Draw overlapping annotations and verify clicking a particular visible stroke selects the topmost annotation at that exact point.
- [ ] Drag a marquee around several annotations, then move, resize and recolor the group. Verify outside annotations remain unchanged and each gesture is one Undo step.
- [ ] Click a board interior and verify the board is not selected; use that area to select one annotation or drag-select several.
- [ ] Select a custom or full-display board from its frame, then move and resize it. Verify contained annotations follow it while outside annotations stay fixed.
- [ ] Start every drawing tool inside a board and drag beyond each edge; verify rendered content stays inside the writable surface. Start outside and verify drawing remains unrestricted.
- [ ] Select every toolbar tool and verify the pointer immediately changes to its matching symbol; Text must show an I-beam and Normal mode must restore the underlying app cursor.

## Milestone 5 boards

- [ ] Draw annotations, switch among Screen, Whiteboard and Blackboard, and verify every annotation stays in place.
- [ ] Switch backgrounds several times, press Undo once and verify the last annotation operation is undone rather than a background change.
- [ ] Select white ink before Whiteboard and dark-gray ink before Blackboard; verify new ink changes to a readable contrasting color.
- [ ] Verify each connected display receives the same board background and returning to Screen reveals the underlying apps.
- [ ] Choose Current Display and verify the other display remains unchanged; then choose All Displays and verify both update.
- [ ] Choose Region, drag in every direction and verify a framed board appears only inside the selected area; drags smaller than 120 × 80 points must cancel.
- [ ] Visually inspect the aluminum whiteboard frame and wood-grain blackboard frame at normal and Retina scaling, including rounded corners, shadow and tray.

## Milestone 6 screenshots

- [ ] Deny Screen Recording permission on the first capture and verify ScreenInk explains the exact System Settings location without crashing.
- [ ] Grant permission, reopen ScreenInk if macOS requests it, and capture the full toolbar display to clipboard and PNG.
- [ ] Verify saved and copied images use Retina resolution, include ink/boards and underlying apps, and exclude the ScreenInk toolbar, popovers and pointer.
- [ ] Drag screenshot regions in every direction on each display and compare the selected rectangle with the captured pixels, especially displays with negative origins.
- [ ] Cancel a region smaller than 20 × 20 points and cancel the Save panel; verify neither action writes a file or changes drawing history.
- [ ] Open Palette, Shapes and Board popovers, keep the pointer over their items for more than two seconds and verify the toolbar remains visible.
- [ ] Interrupt reveal animations repeatedly and verify the toolbar's saved position never moves upward or overlaps the menu bar.

## Milestone 8 Presentify extras

- [ ] Enable Click Animations, return to normal mode and click several controls in another app; verify every click still works and a ripple appears on the correct display.
- [ ] Click rapidly across both displays and verify ripples remain smooth, expire after half a second and never enter Undo/Redo history.
- [ ] Disable Click Animations, restart ScreenInk and verify the saved setting is respected without displaying new ripples.

## Milestone 9 release packaging

- [x] Create a versioned host-architecture ZIP and SHA-256 checksum with `scripts/package-release.sh`.
- [x] Verify the local archive structure, checksum and ad-hoc app signature.
- [ ] Package with `REQUIRE_DISTRIBUTION_SIGNATURE=1` using a real Developer ID Application certificate.
- [ ] Submit with an existing `notarytool` keychain profile, staple the ticket and verify Gatekeeper on a clean Mac.
- [ ] Install the released build over an older version and confirm toolbar preferences plus normal click-through behavior.
