# ReyondBroom alpha.36 — workspace, geometry and audio

## Workspace

The default layout places the Mod file manager below the central viewport,
between the tool strip and inspector. Existing customized layouts are retained;
use **Edit → Preferences → Reset panel layout** to apply the new default.

**View → Interface theme** adds **Windows 95 / 98 Dark** and **Modern Light**.
**View → Language** offers English, Russian, German, French, Simplified Chinese,
Japanese and Spanish. The choice is saved alongside the theme and scale. The
catalog translates the main menus, tools and controls; engine diagnostics,
some detailed help text and game-provided entity descriptions remain in their
source language. Translation changes displayed text, not widget IDs or asset names.

The Windows launcher now uses the engine's default **seamless window**:
borderless desktop-sized rendering without exclusive display-mode switching.
An explicitly saved video mode continues to take precedence.

## Geometry

**Edit → Terrain generator** operates on the selected brushes or patches.
Set U/V subdivisions, height, intensity, frequency, roughness, random seed and
the positive or negative X/Y/Z side. Brush output uses triangular prisms by
default, or flat-topped cells with *Triangular grid* disabled. It replaces each
source brush using its bounding box, as in the source generator; it is not a
surface-preserving sculpt operation on arbitrary brush topology. Results remain
convex. For patches, choose odd U/V control-point counts from 3 to 31. Reducing
the control grid approximates the original surface.

**Preview** draws the result in the scene without changing document history.
**Apply** commits one Undo step; **Cancel** removes the preview. Patch preview
tessellation is cached until regeneration. Large brush terrain operations are
limited to 2,048 output brushes.

**View → Grid → Grid rotation** rotates the XY construction grid about world Z.
Surface-grid coordinates, snapping and new perspective/XY-view shapes follow
the angle. Side views retain their editing planes. **Reset grid rotation**
returns to zero; the angle is persisted in preferences.

**Edit → Bevel** supports whole brushes, the outer boundary of selected faces,
selected edges from E mode and selected vertices from V mode. Set radius,
segment count and profile (0 flat, 0.5 round, approaching 1 square). Clamp
limits overlap inside each individual brush. Preview, Apply and Cancel work
like the terrain generator. Results stay convex. The engine has a 64-face
limit per brush: reduce segments or selected edges if an operation is rejected.

Vertex dragging now uses camera geometry for Alt-Z as well as horizontal
movement. The same mouse displacement moves vertices less when close and more
when far away. Orthographic movement keeps the hidden coordinate unchanged.

Shift face hover uses a yellow face perimeter instead of the hit-point cross.
The perimeter cache is invalidated by relevant geometry/selection/visibility
changes, not by every pointer movement. Entity-browser model and fallback
previews are clipped to their own tile. The patch-only Control Point tool is
hidden and unavailable in the Quake 1 profile.

## File and sound editing

Double-click a `.map` in the Mod file manager to open it, including a map inside
a PAK. If the current document is dirty, **Save / Don't Save / Cancel** guards
the switch. A failed or cancelled save does not open the requested map.

Double-click WAV, OGG, MP3 or FLAC to open **Sound editor**. Drag across the
waveform or enter start/end seconds, adjust volume and speed, and use Play/Stop.
Enable **Trim to selection** to keep only that range when saving. Speed changes
pitch as well as duration.

**Save with backup replaces the original sound**, including a PAK member; it
does not create a second working asset. A disk sound retains a timestamped
`.bak`; archive editing uses the existing PAK backup mechanism. Saving refuses
to overwrite a source modified externally since it was opened. Conversion
runs in the background through the bundled minimal FFmpeg helper.

This is a basic sample editor: audio is processed as 16-bit, 44.1-kHz stereo;
WAV export retains the source mono/stereo channel count and sample rate.
Compressed formats are re-encoded. Ancillary loop/cue metadata is not edited
or preserved; retain the backup if the original relies on such metadata.

## Complete manual test checklist

1. Start a fresh installation: desktop-sized borderless window; Alt-Tab works.
   Restart after choosing a different video mode and confirm that choice is kept.
2. Reset the layout: file manager occupies only the area below the viewport;
   the tool strip and right inspector remain unobstructed. Resize and restart.
3. Try all four themes and seven languages. Check menus, popups, text fields,
   Cyrillic/CJK labels and persistence after restart. File names must not change.
4. In Quake 1, verify that Control Point is absent and P cannot activate it;
   in Quake 3, create/select a patch and verify P still works.
5. Hold Shift over a brush face: yellow perimeter, no hit-point dot. Move across
   faces, undo geometry, hide/show brushes and check that the outline follows.
6. Resize entity thumbnails and scroll the browser. Large models and fallback
   bounds must stay within their own tiles, including selected tiles.
7. Generate terrain from a box with several seeds, axes and subdivisions. Try
   triangular and flat cells. Check Preview, Cancel, Apply, one Undo and Redo.
8. Generate terrain from a textured patch, change odd U/V counts and undo it.
   Check material retention, control-point editing and save/reopen.
9. Rotate the grid to 30° or 45°: create/move brushes, move vertices in 3D and
   all 2D views, inspect surface grids, then reset and restart.
10. Bevel a whole box, selected face boundary, an edge in E mode and a vertex
    in V mode. Change radius, segments, profile and Clamp. Check Cancel,
    Undo/Redo, textures, and safe rejection of overly complex results.
11. Move the same vertex near and far from the camera, horizontally and with
    Alt held. Switch Alt during a drag, cancel, undo, and repeat in side views.
12. Double-click a MAP in the file manager with clean and dirty documents.
    Exercise Save, Don't Save, Cancel, cancelling Save As and a failed save.
    Repeat with a MAP inside a disposable PAK.
13. Open disposable WAV/OGG/MP3/FLAC sounds. Inspect the waveform, select a
    range, play, change volume/speed, trim and save. Reopen the same file;
    verify duration, volume and backup. Repeat inside a disposable PAK.
14. On `hotel02.map`, navigate in 3D/2D, hover faces, select/move brushes and
    open model thumbnails. Check FPS and console errors. Compile a copy and
    confirm both patches remain present; do not overwrite the source for testing.

Automated checks cover vertex distance scaling, brush gestures, the hotel02
MAP round-trip, convex bevel modes/clamp, patch terrain material/grid retention
and Undo, preview cancellation, rotated-grid math, and audio overwrite/backup.
