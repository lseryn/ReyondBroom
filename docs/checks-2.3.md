# Complete checks — alpha.12–15
[Changes](task-2.3.md)

Extract the whole ZIP into a new folder. Alpha.11 was accepted. Alpha.12, alpha.13 and alpha.14 remain untested; all their checks are retained below.

## Selection rendering — alpha.15

Run **Launch-Checks.cmd → A**. Three green brushes are editable; the reference brush with blue edges belongs to a locked layer. No layer or patch construction is required.

1. Click the central cube: its texture remains visible under a light red tint, red edges and bounds. Dimensions: X 128, Y 128, Z 128.
2. Ctrl+click the small right brush: combined bounds should read X 288, Y 128, Z 128. Deselecting one and Undo/Redo update immediately.
3. Hover a selected brush: fading alignment guides extend from the combined bounds. Move into empty space: they disappear. Hover adds no Undo step.
4. Hover an unselected brush: a light highlight appears without changing selection or its count.
5. The locked reference remains blue and cannot be selected. Orbit to inspect its tint; its material must remain visible.
6. Shift+click the central top face: only it has the 30% red fill; bounds are flat with Z 0. Add a side face: height becomes 128.
7. Switch to four views. 3D retains tint and three dimensions; XY/XZ/YZ have outlines and two relevant dimensions, without fill. Pan, zoom, resize panes and change selection: no stale bounds/labels or drawing outside panes.
8. Orbit and partly occlude the selected cube with another brush. Hidden edges remain visible but fainter. Labels from behind the camera must not appear.
9. Toggle Highlight hovered objects, Show selection dimensions and Show alignment guides on hover in File → Preferences…; each controls only its display feature.
10. Move a selected brush: no old surface, outline or bounds remain at its original position. Escape, Undo and Redo work.
11. Clear selection: bounds and labels disappear. Save/reopen a copy: geometry, materials and layer locking survive.
12. Also use scene 3's existing patch and point entity. Select each and both together; their outlines and combined bounds must fit the selection. No patch creation is needed.

## Faces — alpha.14

Start **Launch-Checks.cmd → 9** and wait for perspective. Four blue cubes touch in the centre. The red cube touches only a corner; green cubes have a gap or a different top height. No patch creation is needed.

1. Shift+click a blue top: only that face is highlighted; the inspector shows one face. Shift+click a side replaces it.
2. Ctrl+Shift+click adds/removes faces. Removing the last clears selection. Check Undo/Redo.
3. Select two whole blue brushes with click/Ctrl+click. Ctrl+Shift+click one face: 11 faces remain. Undo restores two whole brushes. Clicking an unselected brush with Ctrl+Shift selects only its clicked face.
4. Shift+double-click a cube selects six faces. Ctrl+Shift+double-click another adds six. Check Undo/Redo.
5. Shift+Alt+double-click a blue top selects exactly four blue tops, excluding red/green cubes. Ctrl+Shift+click removes one; Undo restores four.
6. Select an isolated green top, then Ctrl+Shift+Alt+double-click a blue top: five faces are selected.
7. Select one blue top, then Ctrl+Shift+drag over the other blue tops. One Undo reverts the entire stroke; Redo restores it. Escape during another stroke restores the original selection.
8. Change material, Scale X/Y and Angle on one face, then several faces. Other faces must remain unchanged. Repeat on a whole brush and check Undo/Redo.
9. Empty click and Ctrl+Shift+A clear selection. Shift gestures must not select faces in XY/XZ/YZ.
10. Save a copy and reopen: geometry, materials and entity properties survive. Selection itself is not stored in MAP.
11. If you have hidden/locked objects, verify flood and paint skip them. 64+ face brushes are covered automatically; no manual fixture is needed.

## Object selection (2.1)

Run **Launch-Checks.cmd → 8**. Wait for the four panes. Use the top/XY pane for the blue row and red stack, and repeat ordinary selection in perspective.

1. Ctrl+click three blue brushes: count 3. Ctrl+click the middle one again: count 2. Undo/Redo must restore 3/2. A plain click replaces the selection; clicking empty space clears it.
2. Shift+click a face in perspective, then Ctrl+click another brush. Only whole objects should remain selected.
3. Clear selection, hold Ctrl and drag across all five blue brushes, starting on the first unselected brush. Count 5; one Undo clears the entire painted selection, Redo restores all five. Repeat from empty space. Start another paint gesture and press Escape before releasing: the prior selection returns.
4. Ctrl-drag from an already selected brush: nothing moves or duplicates yet (task 4.1).
5. In XY, place the cursor on the three overlapping red brushes. Ctrl+wheel away steps deeper through three objects; toward you steps back. The other panes reveal which height is selected. Each transition has Undo/Redo; grid spacing must not change. Ctrl+Alt+wheel must still change grid spacing.
6. Click one green brush: both group members should select. Double-click opens the group (name appears in the inspector). A click can now select one member. Double-click a member selects both siblings. Double-click empty space outside the group closes it and selects the group. Check Undo/Redo.
7. Ctrl+click both point-entity boxes below the row, optionally adding a blue brush. Both boxes should highlight; entity count is 2. Check Undo/Redo and Ctrl+U framing of the complete selection. Entity deletion is not part of this stage.
8. In perspective and all 2D panes, check that selection matches the visible object and geometry remains visible away from the construction plane. Repeat on an existing patch (scene 3 provides one; no need to create a patch).
9. On a map with hidden/locked layers or groups, their children must not be picked by click, painting or drilling.
10. Save a copy, reopen it and verify geometry, textures, patches and entity properties. Selection itself is not saved into the MAP.

## Alpha.12 — still pending

## Open and Save As

1. Start the editor and choose File → Open, then repeat with Ctrl+O. A file browser must appear.
2. Use Up, double-click a folder, change drive, and enter a folder path with Go. Only folders and `.map` files should appear. Scroll a longer listing.
3. Choose a map outside the editor folder, preferably in a path with spaces and Cyrillic characters. Select it and click Open. Confirm geometry, materials, entities and patches load; the inspector displays the original path and file name.
4. Open the browser and Cancel. The current map, selection and unsaved state must remain unchanged.
5. Edit the map. Choose File → Save As or Ctrl+Shift+S. Navigate to another folder and enter a new file name without the extension. Save. Confirm the new `.map` exists and the original file was not modified.
6. Edit again and press Ctrl+S. It must save to the newly chosen file without opening a browser. Reopen that file and check the change.
7. Save As to an existing file. Check the replacement confirmation. Cancel must preserve that file; repeat and Replace must save the map.
8. Create a new document, add a box and press Ctrl+S. It must ask where to save. Cancel must leave the document unsaved.
9. Modify a document, then Open another map. Check all three choices: Save, Don't Save and Cancel. Save must complete before the other map opens; Cancel must retain the current map.
10. Enter a missing folder or select an invalid/missing map. An understandable error must appear without closing the current map. If possible, try saving into a folder you cannot write: the document must remain unsaved.
11. Check that typing file names does not move the camera, create/delete geometry, or trigger editor shortcuts.

## Focus and camera coordinates

Use Launch-Checks.cmd → 7 for four views.

1. Select a cube and press Ctrl+U. The camera should move smoothly in about 150 ms; its viewing direction must not rotate. The complete selection must fit in 3D.
2. Repeat after creating a long or tall brush, and after resizing the pane. Try the same command with focus in XY, XZ and YZ. All 2D views should center on the selection without changing their zoom.
3. Deselect everything and press Ctrl+U: the camera should not jump to stale selection coordinates.
4. Choose View → Move Camera to…, enter `111 -222 333`, and press Move. Only the 3D position changes. Cancel a second coordinate edit; the camera should stay put.
5. Try an out-of-range coordinate: Move should be disabled. Typing coordinates must not activate camera shortcuts.
6. After focusing, use normal camera controls. They must respond immediately. Save/reopen the map and verify geometry is unchanged; navigation must not add an Undo step.

## Short regression pass

- Create/move/delete a brush, Undo and Redo.
- Clip with two points on a side face; check translucent discard preview.
- Check grid spacing/visibility and 2D Alt/Shift movement.
- Check materials, scale/angle, four-view dividers and permanent inspector.

No patch creation or point-file navigation is required in this iteration. Report the failing step, expected/actual result and a screenshot if needed.
