# Alpha 46: Bezier Bend, Subtract 2 and Auto Integer Snap

This is a transfer increment. The complete outstanding scope remains in [the comparison ledger](reyond-parity.md).

## Bezier Bend

Select 1–64 convex brushes and choose **Tools → Bezier Bend** (the curve with control points in the toolbar). Tool options provide the bend axis, 1–32 path segments and 0–6 subdivision levels. Each subdivision level doubles the number of slices per input brush, up to 512 output pieces overall.

Move a magenta control point in the scene, or choose its index and type Position, Scale and Rotation values. In perspective, dragging moves in XY; Alt moves vertically. Ctrl snaps a position to the grid. Choose Move, Scale or Rotate and an All/X/Y/Z constraint. Scale dragging is vertical; rotation dragging is horizontal in whole degrees. Keep joints maps shared boundary vertices consistently; disabling it transforms each slice rigidly. A highly twisted or collapsed shape can still be invalid or self-intersect; the tool validates convex pieces, not global self-intersection.

The path uses Catmull–Rom interpolation through the controls, matching the upstream tool named Bezier Bend. Original geometry is hidden only for a valid preview. A changed selection or document invalidates that preview. Increasing subdivisions gives the bend more geometric detail; increasing path segments gives more handles. These are separate controls.

Ctrl+Z/Ctrl+Y undo/redo path settings while the tool is active. Escape cancels a handle drag; Escape without a drag leaves the tool. Reset path straightens it. Apply Bend or Enter replaces the originals in one document Undo. Cancel leaves the source untouched. Patches and point entities are not bend inputs.

## Subtract 2

Select cutter brushes and choose **Edit → CSG Subtract 2**. Axis-aligned cuboid cutters divide intersecting targets on a regular grid defined by cutter bounds; occupied cells are removed. New internal faces inherit source face material/projection attributes. Cutters are consumed, and the resulting pieces are selected. Undo/Redo covers the complete operation.

If any cutter is not an axis-aligned cuboid, or a target would require more than 512 grid cells, the operation uses ordinary CSG subtraction instead. The existing 2048-result brush limit remains. Invalid geometry cancels the transaction. This mode can produce more pieces than ordinary subtraction; use the ordinary command when its output topology is preferable.

## Auto Integer Snap

The **Int** toolbar checkbox and **View → Options → Auto Integer Snap** enable a saved, opt-in preference. After brush geometry edits, selected brush vertices are rounded to integer coordinates before the transaction commits and before linked instances are synchronized. The edit and rounding share one Undo. Patches, point entities and selection-only operations are untouched. A brush that would become invalid is retained and a status message reports the skipped rounding. A reconstructed hull selects the whole brush because face ordering can change.

## Checks to perform

1. Bend a long textured brush with several subdivision levels. Move, scale and rotate controls in perspective and 2D; try XY, Alt-Z, Ctrl snapping and axis constraints.
2. Toggle Keep joints and check seams. Try several selected brushes, texture lock, a brush entity and near-limit geometry. Invalid previews must not delete the source.
3. Undo/Redo control edits, cancel a drag and cancel the tool. Apply, then undo/redo the complete bend. Change selection while previewing.
4. Subtract a small central cube from a larger cube. Compare Subtract 2 with ordinary Subtract; repeat with several cutters, a rotated cutter and a dense grid. Check materials, selection, Undo and saved MAP output.
5. Enable Int, move/rotate a brush to fractional coordinates and verify integer vertices. Undo once. Test a very thin brush and a patch; disabling Int restores ordinary editing. Restart to check preference persistence.
6. Save/reopen and compile modified maps. Recheck Rock, Sculpt, Array, Inset, Subdivision and Settle from alpha 44–45.
7. Repeat on Windows and Linux. Check existing Build/Toggle BSP shortcuts, Backspace deletion, text input and game profiles.
