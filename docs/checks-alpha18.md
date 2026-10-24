# Alpha.18 — complete manual checklist
[New tools and limitations](alpha18.md)

Use a fresh extraction and a copy of a map. Do not copy old binaries over the package. Keep the console/log if something fails. For a report include the action sequence, expected/actual result, view, grid, modifiers, map and screenshot. These checks do not gate development on your reply.

## Launch, files and workspace

1. Launch-ReyondBroom.cmd: choose Quake III, choose baseq3, load loose files/PK3/shaders. Search for a known shader and verify its preview and folder. Source game files must stay unchanged.
2. Open a MAP through File → Open. The inspector must remain available after switching maps. Cancel a dirty-map prompt; the current map must remain. Save As to a folder/name containing spaces and Cyrillic; reopen and compare geometry, entities, texture axes and patches.
3. Edit, Undo, Redo; confirm separate gestures are separate steps, cancelled gestures add no edit and do not discard the existing Redo branch. Confirm autosave and dirty indicators.
4. Resize/dock/undock panels, resize subpanels and the four view panes. Change font scale, restart, restore/reset the layout. Text entry in a field/dialog must not move the camera or invoke editing shortcuts.
5. F1 should restore/focus the persistent inspector. Try a small and a high-DPI display. Menus, file dialogs and the material list must remain reachable.

## Navigation, grid and selection

6. WASD/QX, RMB look, Alt+RMB orbit, MMB pan, wheel settings and saved viewpoint; lose/regain focus without stuck movement. In 2D verify pan/zoom, view switching, linked camera centers and divider dragging.
7. Grid size 0.125 through 256, wheel changes, snap on/off, visible grids on surfaces and the background. Drag a new cuboid: its default thickness must equal the grid. Move in XY, Alt in Z; check view-plane movement in 2D.
8. Click, Ctrl-toggle, paint selection, rectangle selection, Select All/Invert/Siblings/Touching/Inside/Tall and MAP line selection. Drill through overlapping objects with Ctrl+wheel. Overlap means two brushes cover the same screen position at different depths: test nearest selection in perspective, then the smaller projected face in 2D. The selected object must not flicker between them.
9. Shift-click a face, toggle/paint faces, double-click all brush faces, coplanar flood. Verify hover, selected outlines, dimensions and hidden/locked exclusions. Delete selected brushes, Undo/Redo. Duplicate/move, Ctrl+D and copy/paste a mixture of brushes, entities and a nested group.

## Materials and previous transforms

10. Material folders/search/used filter, selected material display and click-to-apply. Change offset, X/Y scale, negative scale and angle on one face and the whole brush. Other faces must remain unchanged. Verify Fit/alignment, replacement, attribute flags and material transfer. Save/reopen and Undo/Redo texture edits.
11. Rotate via keyboard and ring handles. Check angle snap, texture lock and the update-entity-properties option. Move the pivot; Escape restores it, Undo/Redo changes the pivot without rotating the brush.
12. Shift-drag Extrude, Shift+Ctrl Split, Shift+Ctrl+Alt Stamp in perspective and 2D. Check preview, Esc, one Undo and source texture attributes.

## New geometry tools

13. Clip: place two points on the same face, then points on different faces; try 2D and 3D. The preview must divide a crossing brush. Front/Both/Back must match the translucent orange discard preview. Drag a point; drag an empty area to place two; double-click a face. Escape cancels point dragging/removes the last point. Test three collinear points and a tangent plane: no damaged brush or extra Undo step.
14. CSG: overlap two boxes, test Merge and Intersect; select a smaller cutter for Subtract. Verify cutter/result selection and one Undo. Hide/lock another overlapping brush and ensure Subtract leaves it unchanged. Hollow a thick box and a box thinner than the grid; the latter must remain valid.
15. V/E/F: click/Ctrl-toggle handles and select with a rectangle. Drag in each view, use Alt in 3D, nudge and Delete. Create a non-planar face; the result must stay convex. Push a vertex inside its hull, continue dragging, then Escape. Invalid flattening must be rejected. Shift-drag a new vertex; Shift+Alt-click a target to merge. Start a new drag after a merge.
16. Shift+Alt-drag a selected whole brush face: in 2D it can shear in the view plane, in 3D it moves along the normal. Confirm unchanged neighboring objects, Esc and one Undo.
17. Scale by face/edge/corner, Alt from center, Shift proportions and numeric dimensions. Start with off-grid bounds to check absolute snapping. Try Shear in different views and both directions. Select geometry with V/E/F, then Rotate/Scale/Shear only that geometry. Esc and Undo must restore it.
18. Brush (B), perspective: click three points on a surface, add a point on another plane, Enter. Also drag a rectangle, Shift-drag it to add depth, Enter. Double-click a face as the starting polygon. An entirely flat set of points must not produce an invalid brush.
19. Shape settings: cylinder/cone on each axis; vertex/edge/scalable circle; hollow cylinder at valid and excessive thickness; UV sphere within/over the face limit; icosphere accuracy 0 and rejected accuracy 1; stairs, arch and spandrel. Test drag creation, Replace selection, grouping, Esc and one Undo. Save/reopen the results.

## Entities and organization

20. Entity definitions: bundled Quake 3, external ENT/DEF/FGD, inherited FGD/include, F6 reload, invalid-file error. Reopen the map and verify the selected definition path persists.
21. Entity browser: filter/group/sort/used, drag a player spawn onto a floor and a raised brush, then into a 2D view. The preview and final bounds must match. Create a light numerically. Try a real MD3 model; verify origin, angles and model scale. Missing model resources must not crash the editor.
22. Select three lights with different intensities: mixed field, Enter 300, Undo. Add/remove/rename a property; edit worldspawn with no selection. Try missing/existing/all defaults. Toggle one spawnflag bit on entities with different other bits; unrelated bits must survive. Test choices and color.
23. Three brushes → func_door; edit its properties by selecting a child brush; move another brush into it. Make Structural and Undo. Remove its last brush. Save/reopen and inspect entity ownership in the MAP.
24. Build target/killtarget chain A→B→C; select A and compare Direct versus Transitive and All/None. Move a target and verify arrow endpoints in 2D/3D. Hide/filter a target and check the links disappear with it.
25. Group/rename/ungroup; nested groups; double-click to open one level and double-click outside to close. Objects outside an open group must be locked. Create geometry inside; add/remove objects via RMB; merge two groups. Undo and save/reopen.
26. Hide, Isolate, Show All and each Undo. Layers: create/rename, move selection, active layer, reorder, hide/lock, delete into Default. New objects must use the active layer, derivatives their source parent. Default cannot be removed. Save/reopen states.
27. View options: each class/tag, point/model/name/bounds, group/brush-entity bounds, textures/flat/wireframe, shade/edges and map bounds. Hide/filter an object and check it cannot be picked. Apply/remove trigger/clip/caulk/hint/detail tags and Undo. Special editor surfaces should be translucent.
28. Short RMB click → context menu; RMB drag or drag out-and-back → camera without a menu. Test Reveal material, Select class, Create entity, group/layer actions and Move brushes to entity.
29. Mark a layer Omit. Save the editable MAP, then Export Map to another file. The editable file must retain the layer; the export must omit it and flatten other groups/layers while keeping func_door. The open document name and dirty state must not change. Test spaces/Cyrillic paths and overwrite/cancel.
30. Reopen the exported file separately and compare visible geometry and texture axes. Use a compatible external compiler if available. Compiler launch is not integrated in this release.

## Existing patches and excluded tools

A new patch-creation tool is intentionally not included. For regression checks use **Launch-Checks.cmd → 3** (the supplied curved patch) or open an existing Quake 3 MAP. Select/move/duplicate/save/reopen it; do not look for a control-point editor. Linked groups, Sweep and a UV editor are also outside this batch. The Texture Lock / UV Lock preference buttons are not a UV editor.

Additional alpha.18 UI checks:

- Entity: edit a value and press Tab to commit. Ctrl+Enter creates a property; rename its key, Tab to its value, enter text and press Enter. Undo must revert the last edit.
- Enable Instantiate defaults on creation and create a light: light=300 should be explicit. Disable the preference: a new light should not instantiate that key.
- On Launch-Checks → 3, switch Flat/Textured/Wireframe and Shade faces. Existing patch geometry must remain unchanged.
- Use fog should disable/enable fog in ordinary textured rendering on a map that has fog. A map with no fog need not change visually.
- A planar Brush point cloud should show its outline and translucent fill before extrusion creates a volume.
