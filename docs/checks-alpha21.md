# Alpha.21 verification checklist
[Feature guide](alpha21.md)

Use a fresh extracted bundle and disposable copies of maps. Do not save over your original maps during acceptance tests.

## Requested regressions

- Open a copy of `basement01.map`; inspect world geometry, groups, brush entities and point entities. Save As to another filename, reopen it, and compare. The original must remain untouched.
- Compare navigation responsiveness on a large map before/after Select All, deselecting and Undo. Watch the console for recurring errors. Record GPU, resolution, view count and approximate FPS if slow.
- Select a brush, position another brush between it and the camera, and drag the selected brush. Test XY and Alt-Z, then Undo. An ordinary click should still select the frontmost brush.
- Change grid size repeatedly: spacing changes, line thickness stays consistent. White outlines and the surface grid must remain depth-tested.
- On a clean installation, class names, point bounds, group bounds and brush-entity bounds are off; individually enable each option.
- Open, Save As, export and resource/definition browsing: enter a folder with one click, use Up one level, test drive roots and a Unicode path.
- Delete point and brush entities. Raise a 32-sided cone apex with V and Alt-drag (or in a side view). Check group front faces and point-entity visibility.

## Linked groups

1. Group a brush and a light. Ctrl+Shift+D, then move the closed copy 128 units and rotate it 90 degrees.
2. Open either group; edit geometry and a shared property. Both copies should update in their own coordinate systems. Undo/Redo must affect the whole change.
3. Protect one copy's `targetname`; edit the other copy's `targetname` and `speed`. Only speed should propagate. Delete a protected value, synchronize again, unprotect, and test Clear Protected Properties.
4. Test nested groups, ordinary Ctrl+D on a linked group, Select Linked, Separate and Extract. Save/reopen and repeat an edit.

## Patches

1. Shift-click a box face, Ctrl+P: it becomes a patch and the original brush is removed. Undo/Redo. Repeat on a whole box and an octagonal face.
2. Select a patch, P, select its center handle and Alt-drag up for a dome. Test Ctrl-multiselect, lasso, coincident points, keyboard movement, Rotate/Scale/Shear and Undo.
3. Change Columns 3→5 and Rows 3→5: shape should stay the same. Reduce to 3: inspect the approximation. Delete must not remove a control point.
4. Save/reopen; inspect curvature, UVs and point positions.

## Sweep

1. Select a square face, Y, Straight, 4 segments; move the cap 128 units. Enter should create four segments, select them and leave Sweep.
2. Test Arc with 90-degree rotation and 8 segments; inspect adjoining faces for cracks. Add vertical movement and 4 iterations for a spiral.
3. Test S-bend, taper/flare, integer snapping, cap drag, axis rings and scale handle. Escape resets, then exits; Undo removes the complete operation.

## UV and repeat

- Select one face: the Material UV canvas appears; multiple faces leave it inactive. Test offset, grid-line scale, Ctrl/ring rotation, Alt-grid shear, origin dragging, zoom and pan.
- Check snapping near face vertices/edges, subdivisions, Reset/World, flips, quarter turns and Fit. Each drag must undo in one step; Escape must cancel.
- Duplicate, move up and rotate a step, then Ctrl+R repeatedly. Check cumulative placement, selection of the newest copy, one-step Undo and clearing on selection change. Repeat a UV-canvas offset too.

## Issues, overlays and export

- Create a missing target link and a fractional vertex. Issues should list them; selection/focus, filters, Hide/Show, Fix and Undo should work. Repeat with a missing mod and soft-bound violation.
- Load a compiler `.lin`, step with period/comma, Reload and Unload. Load a `PRT1` `.prt` and inspect translucent portals.
- Omit a layer from export: Export Map must exclude it and retain included objects/groups. Reopen the exported copy.
- Export OBJ with brushes and curved patches; import in Blender. Inspect exterior face normals, UVs, material names and patch tessellation. Images are not included in the MTL.

## Profiles, recovery and settings

- Configure your actual q3map2 path. Run Export + `-meta`, inspect live output and the BSP. Test a deliberately invalid argument, Stop on a long task, Rerun, and Launch in FTE with a valid compiled map.
- Test Copy/Delete filename patterns in a disposable build folder, Rename, paths containing spaces, and profile persistence after restart.
- Set a short autosave interval and 2 copies, make 3 edits, and inspect rotation. Restart with a backup newer than the source; Recover should open an untitled map and Save should ask for a destination.
- Change Clip to Shift+C; test it in the scene. Create a conflicting shortcut, resolve the highlighted conflict, and restart. Check shortcuts, mouse settings, colors and backup settings persist.
- Resize/dock panels and test 125–200% font scaling. F1 must keep/restore the inspector after opening another map.

Baseline regression checklist: [alpha.20](checks-alpha20.md). Automated evidence and precise limits: [TESTING.md](../TESTING.md).
