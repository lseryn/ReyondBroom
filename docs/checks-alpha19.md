# Alpha.19 — complete baseline acceptance checklist
[Changes](alpha19.md) · [Detailed geometry gestures](checks-alpha18.md)

Extract the release to a new folder. Keep a backup of real maps and use **Save As** for these checks. Run `Launch-FTEBroom.cmd`, choose Quake III and your `baseq3`. The source/build regression suite is described in [TESTING.md](../TESTING.md); this checklist covers behavior that benefits from human inspection.

## Reported bugs and data safety

1. Open `hotel02.map` through File → Open. Wait for the scene, orbit and pan. Open a different map, then return. Also use Select All and Invert. There should be no frozen workspace or QuakeC error.
2. Save As to a new path. Reopen that copy twice. Inspect thin bevels, angled faces and the existing patches; no disappearing corners or changed silhouettes. Confirm the original remains untouched.
3. With nothing selected, inspect groups, `func_wall`, `func_door` and other brush entities. Their surfaces must remain visible. Clicking elsewhere must not make them disappear.
4. Toggle point-model visibility: brush entities remain. Hide/show their class or layer: geometry disappears/returns intentionally. Repeat in perspective and XY/XZ/YZ. During a move, only the moving preview appears at the destination; Escape restores the original.

## Workspace, selection and basic editing (0–4)

5. Resize/dock the panels, increase font scale, switch between one/four views and restart. The workspace persists; F1 restores the inspector and opening another map keeps it available.
6. RMB-drag looks, Alt+RMB orbits, MMB pans; WASD and Q/X move the camera. Typing in any field must not move it. Ctrl+U frames selection; Ctrl+Alt+Z resets zoom. Space cycles views; Ctrl+Space maximizes/restores.
7. Mouse wheel changes grid size; 1–9 and +/− change it too. Test snap off and on, face-grid visibility, orthographic zoom/pan and linked panes.
8. Click/Ctrl-click, paint selection, drill through overlapping brushes, marquee selection and group opening/closing. Shift-click selects faces; connected-face selection works across adjacent coplanar faces. Hidden/locked objects cannot be picked.
9. With no selection, draw a brush: its initial thickness is one grid step. Test Shift square, Alt height and Shift+Alt cube; repeat in XY/XZ/YZ. Esc must cancel without a history change.
10. Move several objects together; Alt constrains vertical movement, Shift constrains an axis. Ctrl-drag duplicates, Ctrl+D duplicates in place, arrows/PgUp/PgDn nudge. Delete works; deleting the last brush removes its empty brush entity.
11. Copy/Paste and Paste at Original Position between maps, including a group, point entity and brush entity. Undo/Redo must restore geometry, ownership and selection. Open/Save As use a file browser; dirty-document prompts, recent files and recovery remain usable.

## Materials, transforms and geometry (5–13)

12. Material directory filters, text search and used-only mode show the expected shaders. The current material is visible. Applying a material changes the selected faces/brushes; mixed selections are indicated. Test X/Y scale, offsets, angle, flags and negative scale.
13. Test texture keyboard alignment, Alt-click attribute projection, Alt+Shift-click rotation across an edge, Alt+Ctrl material-only, painting and material replacement. Undo each operation. With Texture Lock on, moving/rotating/scaling preserves the intended texture alignment.
14. Rotate using rings and numeric angles; move/reset the pivot, test axis constraints and entity-property updates. Scale by handles, target size and factors; Shift makes proportional changes, Alt changes the anchor. Shear a side horizontally and vertically. Escape cancels previews.
15. Extrude, Split and Stamp a face; test inward/outward movement, 2D projected edges and Move Face. Verify original geometry is replaced only on commit and Undo is one step.
16. Clip using two points on one face, then a third point and a dragged clipping line. Check the kept/discarded preview, keep-both mode, Ctrl+Enter, Escape and Undo. The translucent discarded part must match the result.
17. Convex Merge, Subtract, Intersect and Hollow on overlapping boxes. Test invalid/no-overlap cases: clear feedback and no partial edits. Verify textures on retained and newly cut faces.
18. Vertex/Edge/Face modes: hover coordinates, yellow outlines, click/Ctrl-click, lasso, drag, Alt vertical, relative/absolute snap, vertex addition with Shift, merge/collapse, deletion, snapping and Undo. With UV Lock on, move a top corner down: the top splits into triangles while stationary texture corners stay fixed.
19. Use Rotate/Scale/Shear on selected handles; invalid or flattened hulls must be rejected. Escape restores the pre-drag shape and handle state.
20. Brush Tool: double-click a face, Shift-drag its planar polygon upward, Enter to create a prism. Three coplanar points cannot create a volume. Escape clears points before leaving the tool.
21. Create/replace cuboid, stairs, arch with spandrels, cylinder, hollow cylinder, cone, UV sphere and accuracy-0 icosphere. Test axes, edge/vertex/scalable circles, thickness, grouping, previews and Undo. An over-limit sphere/scalable circle must report the 64-face limit without changing the map.

## Entities and organization (14–15)

22. Load `.ent`, `.def` and `.fgd` definitions, including an external path. F6 reloads them. Browser name/prefix/usage filters work; drag a point entity onto a floor/wall and into a 2D view. It snaps using its bounds and is selected. Missing models use colored bounds; available models respect skin, frame, angles and scale descriptors.
23. Select several entities with different values. The table shows the union of keys, missing/default styling and empty mixed values. A first click selects; the second click/F2 edits. Test arrows, Tab/Shift+Tab, Enter, Escape and Ctrl+Enter. Rename a custom property, change classname and origin, then Undo each edit.
24. Ctrl/Shift-select several property rows; Delete/− removes them with one Undo. It must not delete brushes in the scene. Merely focusing/leaving an empty mixed-value cell must not overwrite it. Internal brush models and the classname key remain protected.
25. Select spawnflags, a choice property and `_color`. Smart controls appear below the table; flags preserve unrelated bits across entities. Test float/byte color storage, map swatches, defaults existing/missing/all and Undo.
26. Convert selected brushes into a brush entity, move brushes between entities, use Make Structural and delete the last brush. Reopen the saved map and inspect ownership/visibility. Target/killtarget arrows respect None/Direct/Transitive/All.
27. Create/nest/rename/merge/ungroup groups. A modal tool prevents Group; exit it and retry. Double-click opens a group, outside objects lock, new objects belong inside, and double-click outside closes it. Add/remove objects through context actions.
28. Create layers, move selection into them, hide/lock/omit, activate a layer and create new objects. Ctrl-select and remove several layers: objects move to Default Layer. Reorder layers; bulk hide/show/lock/unlock and Undo should act as single operations. Save/reopen preserves metadata.
29. Prefix/class filters and Trigger/Clip/Caulk/Hint/Detail/Liquid/Translucent/Areaportal/Clusterportal filters affect rendering and picking. Test flat/textured/wireframe, edges, shading, fog and bounds. Assign a key to a class filter, tag filter and Create Entity action.
30. Export Map to a separate file: omitted layers are absent, editor groups/layers are flattened, brush entities and patch data remain, and the editable document's path/dirty state is unchanged. Short RMB click opens the categorized context menu; RMB drag never opens it.

If anything fails, include the release number, exact gesture/keys, grid/tool/view, entity classname or shader, and whether it reproduces on a new map. Attach a minimal map only if it contains no private assets.
