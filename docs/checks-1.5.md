# Acceptance checklist — 0.5.0-alpha.12
[user manual](manual.md)

Extract the complete ZIP into a new folder. Use disposable copies of maps. Alpha.11 was accepted; its [earlier complete checklist](checks-1.4.md) remains available for regression checks.

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
