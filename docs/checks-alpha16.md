# Combined alpha.16 manual checklist

[Русский](checks-alpha16.ru.md) · [Features](alpha16.md)

Extract the entire ZIP into a new folder. Use disposable maps. `Launch-Checks.cmd` provides existing test scenes; choose **B** for the new brush workflows. These checks supplement engine tests; none is required before downloading this build.

1. **Project/files:** select Quake 3 and a real baseq3 directory. Inspect loose/PK3 shaders. File → Open and Save As must show directory navigation. Cancel dialogs, reopen another map, save/reload and confirm the permanent workspace stays visible.
2. **Camera/views:** WASD/QX, RMB look, orbit/pan, wheel grid changes, grid visibility/snap, two/four views, linked views, divider resizing and focus. Typing in an inspector field must not move the camera.
3. **Selection:** Ctrl-click toggle, Ctrl-drag painting, depth drilling, groups and point entities; Shift-click face, Ctrl+Shift paint and coplanar flood. Try All/Invert/Siblings/Touching/Inside/Tall and Select by Line. Locked/hidden geometry must stay excluded.
4. **Creation:** clear selection and drag a box at grid 8/16/32. Height must equal one grid cell. Check square/cube modifiers, orthographic depth, open-group insertion, Escape and Undo/Redo.
5. **Movement/copies:** move multiple brushes together and mix brushes, patches and point entities. Test XY, Alt-Z and view-relative nudges. Ctrl-drag and Ctrl+D must produce independent copies; duplicate a nested group, then edit only one copy. Delete and Undo must restore all selected objects.
6. **Clipboard:** copy/cut/paste within the editor and between two editor instances; paste at original position. Copy a MAP fragment from a text editor. Check entity properties, groups and patches after save/reload. Copy one face's attributes onto another; Undo must restore them.
7. **Materials:** select one face and a whole brush, apply a tile, change offsets/X-Y scales/angle, test mixed values and relative steps. Test folder/used filters, multiword search, material selection/replacement, flags and exact 32-bit values. Save/reload and Undo/Redo must preserve the results.
8. **Texture alignment:** Left/Right/Top/Bottom, Edge, Fit H/V, Auto, repeated Fit, Ctrl fractional Fit and Shift reverse cycle. Test keyboard movement/rotation/flip/reset. With exactly one face selected, Alt-drag onto another face; compare Alt+Shift and Alt+Ctrl.
9. **Rotate:** select brushes, patches and entities; press R. Drag the ring by about 40° with a 15° step: expect 45°. Move/reset the pivot, enter a numeric rotation, cancel with Escape and Undo/Redo. Compare Texture Lock on/off. A light's `mangle` yaw must update.
10. **Extrude:** leave modal tools, select a cube, Shift-drag its top and side. Check yellow hover, grid snapping, live bounds, one Undo and cancellation. Push inward beyond the opposite face: it must stop before collapsing. In 2D, drag the projected side edge. Select two touching cubes and move their shared wall: their combined volume must stay unchanged.
11. **Split:** Shift+Ctrl-drag a face outward: the original remains and the new part is selected. Drag inward: the original shortens and the cut-off part is selected. Undo once restores the original geometry/selection. Repeat inside a group.
12. **Stamp:** Shift+Ctrl+Alt-drag a sloped face: a prism appears without changing the source. Compare with Split on the same shape. Opposing shared walls must not produce overlapping Split/Stamp pieces.
13. **Existing Clip:** select a brush, C, place two points on one face; check that a plane cuts through it. Cycle sides and check the discarded translucent part. Apply, Undo/Redo, Escape and Delete. The advanced Clip rewrite is still a later task.
14. **Regression:** save a map containing brushes, patches, groups and entities; reopen it and compare geometry, materials, flags, UV and properties. Check interface scaling at your usual Windows DPI.

If a check fails, record the operation, modifiers, view, grid, expected result and observed result. A small disposable MAP reproducer is especially useful.
