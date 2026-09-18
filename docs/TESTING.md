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

- [ ] Launch app; toolbar and Ink menu appear; underlying apps remain clickable by default.
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

- Only the primary display has a drawing canvas.
- Annotation positions do not rescale on display changes.
- Drawings are in memory only; quitting discards them.
- Stroke points and canvas redraw are not optimized for large drawings.
- Starter supports six colors, not the final 24-color palette.
- No eraser, highlighter, fade, cursor halo, shapes, text, boards, screenshots or global shortcuts yet.
- Fullscreen, multiple displays, screen sharing and long sessions remain unverified until explicitly checked.

See `STATUS.md` for the actual commands and desktop checks performed during setup.

## Toolbar update checks

- [ ] Fresh toolbar position is top-center below the menu bar.
- [ ] Hover each icon; readable tooltip and accessibility label identify its action.
- [ ] Selected ink has a ring; active pen and auto-hide controls are cyan.
- [ ] Move away for two seconds: only the toolbar disappears; existing ink is retained.
- [ ] Hover the top-center edge: toolbar appears after a short dwell.
- [ ] Dragging or clicking controls does not hide the toolbar mid-interaction.
- [ ] Manual hide exits drawing and the menu-bar icon can always show the toolbar again.
- [ ] Turn auto-hide off: toolbar stays visible; manual hide and edge reveal still work.
- [ ] Move the toolbar, quit/relaunch, and verify saved position. Reset returns it to top-center.
- [ ] Disconnect a display: toolbar is restored to a reachable display position.
- [ ] The menu-bar nib icon has appropriate contrast on light and dark menu bars.

Automated visibility regressions cover idle timeout, delayed edge reveal, pointer/drag protection, manual-hide edge rearming, explicit show and disabling automatic hiding.
