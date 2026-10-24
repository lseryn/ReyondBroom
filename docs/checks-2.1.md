# Full acceptance checklist — alpha.12 + alpha.13
[Changes](task-2.1.md)

Extract the complete ZIP into a new folder. Alpha.11 was accepted; alpha.12 is still awaiting manual testing.

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

## Pending alpha.12 checks

Complete **all items in [the alpha.12 checklist](checks-1.5.md)**: Open/Save As filesystem navigation (11 items), camera focus/coordinates (6 items), and the short regression list. Those items remain required, not previously accepted.

In particular: external paths with spaces/Cyrillic; Up/Drive/Folder+Go; Cancel; Save As to another folder; subsequent Ctrl+S; overwrite confirmation; unsaved-change warning; failed saves; text-input guards; Ctrl+U in all views; Move Camera to and Cancel.

## Short regression

Create/move/delete a brush and Undo/Redo; two-point side-face Clip and translucent discard preview; grid spacing/visibility; Alt/Shift movement constraints; texture scale/angle; permanent panel, four-pane dividers and camera WASD.

Report the checklist item, view, expected/actual result and, if helpful, a screenshot. Point-file navigation is still waiting for task 20.3.
