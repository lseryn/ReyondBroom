# Combined manual checks: roadmap 0.6 and 0.7

## Preparation

Extract the **entire alpha.7 ZIP** into a new directory. Close other FTEBroom windows, then run **Launch-Checks.cmd** next to Launch-FTEBroom.cmd. Choose scene **1, 2, 3 or 4** and wait about 10 seconds for the test map and camera to settle. The fixtures use bundled textures; no Quake 3 assets or patch creation are required. Close the editor between scenes. Restarting a scene restores its original contents, unless you explicitly saved over the bundled map.

Use only these disposable maps for destructive checks. To test saving, choose a new name such as `qa_result`, not the supplied `qa_*` name. The regular launcher still opens the ordinary editor/project workflow.

An overlapping view means that several separate objects occupy the same screen position. It does **not** require intersecting solids. Scene 1/2 contains a large red box in front of a small blue box, with a gap between them. The two camera presets look along the same axis.

## 1. Perspective: closest object

Choose **1** in the launcher. The View dropdown should say **Perspective**.

1. Click the centre of the red rectangle once, without dragging. Only the large red brush should be selected. The small blue brush behind it must not be selected through it.
2. Open the **Material** inspector tab: the selected material should be `ftebroom/qa_red`.
3. Press Escape, then Ctrl+Z: selection should clear and return. Ctrl+Y should clear it again.
4. Move the camera sideways with A/D, using RMB to adjust the viewing direction, until the blue brush is exposed beside the red one. Click the exposed blue surface: it should now select normally, with material `ftebroom/qa_blue`.

This is ordinary nearest-surface selection, not cycling through objects behind one another.

## 2. 2D: smaller projected face

Close the editor, launch checks again and choose **2**. View should say **Y (front)**. You should see a small rectangle inside a large rectangle. These are the same separate boxes seen without perspective; the small one is behind the large one.

1. Click **inside the small rectangle**: only the small brush should be selected. Its material is `ftebroom/qa_blue`.
2. Click **inside the large rectangle but outside the small one**: the large brush should be selected. Its material is `ftebroom/qa_red`.
3. Repeat several times. Selection must follow the click, without moving or creating objects.
4. Test Ctrl+Z/Ctrl+Y for these selection changes.

The 2D rule chooses the smaller projected face under the cursor, even when that object is farther away. Wireframe appearance may not show material colours; the Material tab is the unambiguous check.

## 3. Curved patch and point entity

Choose **3**. The green curved sheet is a ready-made **patch** (a curved surface controlled by a grid of points), not a solid brush. The small wire box beside it is an `info_player_deathmatch` entity.

1. Click the middle of the green sheet: the patch should highlight. Click another visible part of the sheet; selection should remain on the patch.
2. Click empty space beside the sheet, without dragging: no object should be created.
3. Select the sheet and test Escape, Ctrl+Z and Ctrl+Y: selection should clear, return and clear.
4. Click the small wire entity box: its bounds should highlight and the inspector should display **Entity: info_player_deathmatch**.
5. Test Escape, Ctrl+Z and Ctrl+Y for that entity selection too.
6. Switch View to **Y (front)** or **Z (top)** and back to **Perspective**. The panel must remain usable and the scene must remain intact.

There is **no patch creation tool in this release**. You do not need to build the sheet yourself. Patch control-point editing, entity movement/properties and accurate picking of an entity's model mesh are not part of these stages. The generic brush selection counter may count a selected patch as one brush; this is not a request to convert it.

## 4. Clip and core editing

Choose **4**. There is one blue cube.

1. Click the cube; press **C**. Clip should activate and be visible on the toolbar.
2. Place two different points on the visible top face, making a line across its interior. Do not put both points on the same edge. A line parallel to the cube's X or Y edge is the simplest first cut.
3. Set **Keep → Front**, then **Back**. The side that will be removed should be translucent; changing the side should switch that preview. For **Both sides**, both halves are retained.
4. Press **Ctrl+Enter** to switch the retained side, then **Enter** (or Apply) to commit. Check that the preview agrees with the result.
5. Ctrl+Z should restore the whole cube; Ctrl+Y should restore the cut. Repeat with **Both sides**: there should be two separately selectable solid halves.
6. Escape exits Clip after clearing its points. Move one half away: the cut should be a closed face, with no hole. During dragging, the original-position copy must not remain visible. Undo the move.
7. Undo back to the whole cube. In the Material tab set **Scale X = 2**, **Scale Y = 4**, **Angle = 30** for the whole cube. Cut it again. Original outer surfaces must keep their mapping; the new cut surface uses the current material with default mapping. Undo/Redo must preserve the result.
8. Try a diagonal cut through the interior. Both halves must remain closed and selectable.
9. Try a line that only touches an outside edge, and a line completely outside the cube. The cube must stay unchanged; no thin duplicate or broken object should appear. Invalid cuts may be rejected.
10. Select a whole half and press **Delete** with the pointer in the scene and no text field being edited. Only that half should disappear. Ctrl+Z restores it; Ctrl+Y deletes it again.
11. Move a whole brush normally: X/Y change, height stays fixed. With Alt held, only height changes. Escape during a drag should cancel it.
12. Drag in empty space to create a brush. Its initial height should equal one grid step. Undo/Redo should remove/restore it.
13. Change the grid with the wheel and the Grid dropdown. Check visible grid lines on surfaces. With default settings the wheel changes grid size.
14. Save under **qa_result**, open another supplied `qa_*.map`, then reopen qa_result. Check the cut geometry, textures and scales. The permanent panel should remain visible after each map load.
15. Finally open one of your **copied** working maps with your Quake 3 project. Check textures, selecting/moving/clipping a simple brush, Undo/Redo, save under a new name and reopen.

## What is already automated

26 geometry checks and 25 picking checks cover hit ordering, hidden/locked ancestors, handle priority, topology, hulls, volume, invalid geometry, source UV preservation and 64-face input. Exported MAP data is compared before/after read-only checks. These API cases have no complete user-facing tools yet and do not need to be reproduced manually.

Report each scene as **OK** or describe the first failing step. Include the scene number, step number, expected/actual behaviour, Windows scaling, and a screenshot or short recording if useful. If a failure requires your own map, provide a small reproducer rather than the entire project.

## Reference screenshots

Perspective: selected red foreground brush.

![Perspective selection](../screenshots/qa-perspective.png)

2D: selected smaller blue brush behind the large one.

![2D selection](../screenshots/qa-2d.png)

Ready-made curved patch (green surface; red lines show its control cage).

![Curved patch](../screenshots/qa-patch.png)

Selected point entity and class name.

![Point entity](../screenshots/qa-entity.png)

Clip: orange translucent volume will be discarded.

![Clip preview](../screenshots/qa-clip.png)

