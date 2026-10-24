# Alpha 50: subdivision alignment, brush conversion and generator controls

## Subdivision

Select complete brushes for the XY/XZ/YZ plane, or Shift-click a face to orient segment cuts along that face's longest edge and normal. With several selected faces on one brush, the first selected face in its face order supplies the basis. This divides the complete brush volume, not a separate surface shell.

World grid cells follow Grid rotation. For a selected face, the two grid axes least parallel to its normal are used. Texture alignment uses projected texture vectors, scale and offset; cell size is measured in texels. Without a selected face, the face most closely matching the chosen plane supplies the texture basis. Invalid coordinates and requests above 512 pieces are rejected without altering the map.

## Convert Triangulated Brushes

Choose **Edit → Convert Triangulated Brushes**. Individually selected brushes are rebuilt independently from their convex hulls, merging coplanar facets. A selected closed group or brush entity is treated as one cluster; its brushes become one convex brush in that container. Open a group to convert individual children instead. Material and texture coordinates are inherited from matching source planes, with nearest-normal attributes for other planes.

The converter checks the hull against the union of the source volumes. A cluster with cavities or disconnected parts is rejected instead of filling empty space. The entire request is atomic, with one Undo/Redo. Limits are 256 input brushes, 4096 vertices per cluster and the engine's 64-plane brush limit. This operation simplifies convex geometry; it does not create a concave brush.

## Generator settings

Terrain generator, Bevel, Fracture, Perforate, Inset, Subdivision and Rock have **Default**, **Undo settings** and **Redo settings**. Settings history is independent for each generator and retains 128 steps. A completed slider drag is one settings step; changing a value after Undo discards the old redo branch. Ctrl+Z / Ctrl+Shift+Z operate on settings while a generator window is open; close it to undo the document. Text fields retain their normal text editing behavior.

Preview updates after an edit settles; settings history does not create document undo entries. Apply remains one document transaction. Cancel, the window close button and Escape outside text input discard the preview. The legacy numeric Spin window uses the same controls; interactive Spin retains its own endpoint history.

Rock grouping now creates one group per source brush instead of collecting every generated rock in one group. Each group receives its own model and generated pieces. For a brush inside a gameplay entity, disable grouping: moving its geometry to an editor group would discard entity behavior, so that request is rejected.

## Verification checklist

1. Subdivide a complete brush in each world plane. Shift-click a vertical/sloping face and repeat; the orientation should follow that face, retaining the full original volume.
2. Rotate the grid, use cell-size subdivision and check that cut planes follow the grid. Return grid rotation to zero.
3. Use texture alignment with scaled/offset UVs, both with and without an explicitly selected face. Check texel-sized cells and unchanged exterior UVs.
4. Convert individual convex brushes: they stay independent. Group touching convex pieces and convert the closed group: they become one brush. Undo/Redo and save/reopen.
5. Try a group of disconnected or concave pieces: it must be rejected with the source unchanged. Open the group and convert children individually.
6. Generate grouped rocks from two selected brushes: each result has its own group and remains independently editable. Undo creation.
7. In each generator, change sliders and text, use settings Undo/Redo, Default, Preview, Apply, Cancel and Escape. Confirm preview-only changes do not alter the map's undo history.
8. Close the generator after Apply, then use document Undo/Redo. Check entity/container membership and exterior materials.
9. Repeat on Windows and Linux. The Spawn Master window should fit and start centered on small displays.

Full parity is still tracked in [the comparison ledger](reyond-parity.md). The referenced Subdivision source contains unused surface-panel and smoothing helpers; they are not exposed by its current rebuild path and are not reported as transferred UI features.
