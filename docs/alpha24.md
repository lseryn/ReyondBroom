# Alpha 24 — stability, map paths and silhouette Extrude

[Русский](alpha24.ru.md)

## Changes

- Eliminates repeated group-selection scans when nothing is selected, caches container selection, and avoids unnecessary hover traces. In a fixed 1280×800 test of `hotel02.map` (2,394 brushes, 2 patches), the same scene increased from approximately 29 to 72 FPS. This is a local benchmark, not a guarantee for every camera position or computer.
- Fixes two engine crash paths identified from Windows crash reports: text-deformation shaders receiving a mesh without a tangent basis, and unbounded recursive patch flatness evaluation. Subdivision now has a finite limit of 64 steps per quadratic segment. Incomplete/invalid numerical input no longer triggers patch topology changes on every keystroke.
- Fixes material Scale X/Y commands being swallowed by the graphical UV editor. Native ImGui input is tested with X=0.375 and Y=1.75. Brush and patch material editing retain the existing Undo/Redo behavior.
- Open/Save As starts in the saved map's directory. For an untitled map it starts in configured `baseq3/maps`, otherwise the editor's maps directory. Resource setup is restored automatically after restarting.
- Uses bundled `tools/q3map2/q3map2.exe` by default while preserving a valid custom compiler. Build snapshots and compiler output live in `_ftebroom-build` beside the document. BSP viewing uses a separate runtime cache.
- Exports rectangular patches in the control-point order expected by q3map2. The original `hotel02.map` was opened at its original external path and compiled from an exported snapshot; its SHA-256 remained unchanged.
- Recognizes translucent content flags and `qer_trans`, and uses a shader's first image stage when no editor image is declared. Selected translucent brushes remain translucent.
- Darkens the default editor material. Backspace deletes selected brushes in addition to Delete, while text input retains its normal Backspace behavior.
- F1–F12 are not editor shortcuts. **Ctrl+Shift+B** builds; **Ctrl+Shift+P** switches BSP/editing. Build options remain available through **Build…**. Enter starts editing a selected property cell.

## Silhouette Extrude (task 7.1a)

Select brushes and hold **Shift**. In perspective, hovering directly over a selected brush chooses its visible face; dragging follows a line along the face normal. Outside the brush, the nearest silhouette edge chooses the reverse-facing face, even when the cursor is far from the brush. The small cross marks the edge handle; its drag uses a supporting plane.

In an orthographic view, start outside the outline. A direct face hit does nothing, except at a shared seam. Shared collinear edges between different selected brushes override the face hit within a three-pixel handle radius. Change `ftebroom_extrude_handle_radius` to adjust that radius.

All selected, visible, unlocked faces on the same plane and with the same outward normal move together, even when disconnected. Opposing faces move together only when their polygons overlap with positive area. Yellow outlines show the affected faces. Grid snapping chooses the nearest candidate from every moving face. Escape cancels; a committed drag is one Undo step. Faces numbered above 64 are excluded from this interaction.

A warm-cache test with 500 selected cubes averaged 1.76 ms per pick over 50 cursor positions on the test machine.

The diagnostic command `ftebroom_extrude_pick x y` prints the selected brush, face, support mode and handle position.

## What to test

1. Open your large maps in MAP mode; compare camera movement with and without selected brushes/groups. Search materials/entities and type patch row/column counts repeatedly; confirm no crash or repeated console errors.
2. Set baseq3 once and restart twice. Confirm setup does not reopen. On an untitled map, Open/Save As should start at baseq3/maps. Open a map elsewhere, then verify Open/Save As uses that folder.
3. Save As into another folder and build. Check compiler output is in that map folder's `_ftebroom-build`; verify bundled q3map2 is selected on a clean installation and a valid custom path survives a restart.
4. Open `hotel02.map`, build BSP, then VIS/LIGHT as needed. Inspect both patches in BSP preview; return to editing and check Undo/Redo. The editor must not overwrite the source merely to build.
5. Type Scale X=0.375, Scale Y=1.75 and an angle on a brush, individual face and patch. Leave the field, change selection, undo/redo and save/reopen.
6. Select glass/translucent brushes. Their textures and geometry behind them should remain visible; compare selected/unselected views. Confirm the default material is darker.
7. Delete brushes with Delete and Backspace, then undo. While editing a text field, Backspace must edit text without deleting geometry. F1–F12 must not activate editor tools; test the new Build/BSP shortcuts.
8. Shift-drag a visible face; then drag the hidden bottom face by starting below the silhouette. Try a cursor far outside the brush. Confirm the yellow outline identifies the face before dragging.
9. In XY, start outside the right edge and drag horizontally. Inside the face, Shift-drag should not start Extrude. At the shared seam of two selected touching cubes, both opposing faces should move together.
10. Select disconnected brushes with coplanar faces and extrude them together. Check grid on/off, cancel with Escape, one-step Undo/Redo, hidden/locked brushes and existing Split/Stamp gestures.

Run automated checks in disposable installations; user maps are never regression-test output destinations.
