# Linux alpha.39: Wayland clipboard and one cursor

Fixes text clipboard integration on Linux. Text fields now request UTF-8 from the
OS asynchronously, preserving normal ImGui selection replacement, multiline paste
and Undo. A delayed reply is discarded if focus has moved to another field. Copy
and cut write to the system clipboard. Brush copy/paste uses the same Wayland bridge.
The bundled wl-clipboard helper avoids requiring an extra user-installed utility.

FTE now owns cursor rendering with explicit cursor images. ImGui's extra software
cursor is disabled; text and resize cursors remain available. Camera capture and
release now also clears Wayland relative-input state when a pointer lock is destroyed,
without waiting for an unlocked event that the compositor need not send.

Linux-only release; Windows stays alpha.37. Preserve your settings when updating,
extract the complete archive and launch Launch-FTEBroom.sh.

## Check on Arch Wayland

1. Copy Cyrillic/Latin text from another application into texture/entity search and
   file path fields with Ctrl+V. Try Shift+Insert, empty clipboard and repeated paste.
2. Select existing text and paste over it. Test Ctrl+Z, copy/cut back into another app.
3. Paste multiline text in a multiline field. Move focus while paste is pending: it
   must not appear in an unrelated field. Check brush copy/paste separately.
4. One pointer over scene, menus and browser; text/resize shapes change appropriately.
5. Hold camera look and release it; leave/re-enter the window, Alt+Tab and resize it.
6. Russian UI and all font scales remain usable. Open a map copy and Build to BSP.

See [Linux requirements](linux.md). Automated integration runs with a nested Weston
Wayland compositor and an external clipboard owner; it does not replace testing
on the user's Arch compositor.
