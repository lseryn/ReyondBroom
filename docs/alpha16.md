# FTEBroom 0.5.0-alpha.16
[Manual checks](checks-alpha16.md)

This preview advances the roadmap through ordinary Extrude, Split and Stamp (7.1–7.2). It also includes the selection, creation, transformation, clipboard and material work developed after alpha.15. It does not claim full roadmap completion. Move Face (7.3) depends on the later vertex-editing kernel and remains pending.

## Features added in this batch

- Select All, Invert, Siblings, Touching, Inside and Tall; select an object by a structural line in a MAP file.
- Outward-snapped box creation, one-grid-cell default thickness, square/cube modifiers, world-bound validation and creation in an open group.
- Move a mixed selection of brushes, patches and point entities. Ctrl-drag duplicates; Ctrl+D duplicates in place. Numeric Move Objects, view-relative nudges, cancellation and one-step Undo/Redo.
- Duplicate nested groups and brush entities with independent geometry models and remapped group IDs.
- Copy/Cut/Paste and Paste at Original Position through the system clipboard. MAP fragments support standard/Valve 220 brushes, patchDef2/3, colored patches and entity/group properties. A single copied face can supply face attributes.
- Material usage filters/counts, folder filters, multiword search, material-based selection and material replacement.
- Per-field mixed texture values; offset, scale, angle and relative edits; named Quake 3 surface/content flags and 32-bit surface values.
- Keyboard texture movement, rotation, reflection and reset. Alignment, edge alignment, Fit H/V and Auto; repeated Fit changes repeats, Ctrl uses fractions, Shift reverses cycling.
- Alt-click/drag transfers texture projection from one selected face; Alt+Shift wraps across the edge; Alt+Ctrl transfers only the material.
- General affine transforms, texture lock, keyboard rotation/flip and an interactive Rotate tool. Editable pivot, angle step, numeric Apply and optional entity-angle updates. Light `mangle` uses yaw/pitch order.
- Shift-drag a selected brush face to resize it along its normal. Matching shared faces move together. The preview stops before a brush or neighboring face collapses. Texture projection stays fixed in world space.
- Shift+Ctrl-drag splits off a new brush. Drag outward to extend with a separate piece; drag inward to cut off a piece and shorten the source.
- Shift+Ctrl+Alt-drag stamps a prism from the face. Split/Stamp keep the source parent and select the new pieces. Opposing shared walls cannot be split/stamped.
- Engine fixes preserve surface flags/values through edits, network messages and Undo/Redo; new brush-model allocation supports independent group/entity copies.

## Using Extrude

Leave modal tools with Shift+Esc. Select a whole brush. Hold Shift and hover over a face: its border turns yellow. In 2D, grab a projected edge. Drag to resize; release to commit; Escape cancels. Choose Split or Stamp by holding their modifiers **before pressing the mouse button**. All modes snap to the grid and create one Undo transaction.

Ordinary resize preserves the number of faces. Split continues the source side planes; Stamp extrudes a prism perpendicular to the source face. These differ on sloped shapes. Very small or invalid results and geometry outside the world bounds are rejected.

## Limits and next work

The advanced Clip interaction rewrite, CSG commands, vertex/edge/face editing, Scale/Shear, point-based brush construction, primitive tools, entity definitions, complete layer/linked-group workflows, patch control-point editing, Sweep, UV editor and final productivity/export tasks remain on the roadmap. Toolbar entries for these tools are not a claim of implemented geometry editing.

Rotate is functional; pivot-history UI and some presentation refinements remain. Material collection persistence and additional browser refinements also remain. The clipboard regression exercises a native/QC transport fixture without replacing the user's OS clipboard; test actual cross-application clipboard use manually.

The package is a Windows x64/OpenGL preview. It includes no retail game assets. Quake 3 Valve 220 maps require a compatible external compiler; build/play integration is not included.
