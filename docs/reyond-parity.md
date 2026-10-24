# ReyondBroom and UltimateTrenchBroom comparison ledger

Reference: [ReyondBroom](https://github.com/reyond9079/ReyondBroom/tree/08e26168364629c968875215803a4d9720714223), its README, feature manuals and `lib/TbMdlLib` / `lib/TbUiLib` implementations. The scope includes the fork's additions as well as editor behavior. A similarly named control is not proof of parity.

Also audited directly: [UltimateTrenchBroom](https://github.com/dragxnd/UltimateTrenchBroom/tree/e093dc9cd41c2e9beb00a9ed0d0dfa2241e4a666). The full transfer scope includes this fork independently; features inherited by ReyondBroom are not assumed equivalent without checking their behavior.

## Added in alpha 50

- Subdivision face-oriented segment cuts, rotated world cells and automatic texture reference-face selection.
- Convert Triangulated Brushes, including selected-container clusters, source-union validation and atomic Undo/Redo.
- Independent 128-step generator settings histories, Default, settings Undo/Redo and Escape cancellation.
- Rock grouping per input brush; separate populated FTE models per group.

## Added in alpha 49

- Spawn Master: searchable target/class chooser, model tiles, shared teleport closet generation/expansion, definition-sized cells, collision-aware placement, persistent source metadata and atomic Undo/Redo. Runtime teleport semantics remain those of the selected game/mod.
- Reliable immediate delivery of entity definitions to QuakeC and integer point/brush kind values.

## Added in alpha 48

- Interactive Spin endpoint Move/Scale/Rotate, axis constraints, grid snapping, Default, settings Undo/Redo and one document Apply.
- Array live preview for brushes, patches and entity models/bounds, independent settings history, Default and Cancel. Preview is immutable and rejects stale selections or excessive complexity.
- Explicit tool-capture guards prevent inactive tools from replacing another tool's preview.

## Added in alpha 47

- Polygon Cut/Spawn: planar contours, concave decomposition, depth, retained cutouts, in-scene handles and transactional Apply. Orthogonal output topology can differ from Ultimate's specialized decomposition.
- Symmetry 2/4/8: mirrored/rotated persistent linked groups, bidirectional contents edits, reconfiguration and Undo. Automatic relinking and live guide planes remain open.

## Added in alpha 46

- Bezier Bend: Catmull–Rom controls, slice subdivision, per-point scale/rotation, shared joints, in-scene drag, settings Undo/Redo and transactional Apply. Convex pieces are validated; global self-intersection is not.
- Subtract 2: cuboid grid decomposition, ordinary subtraction fallback for complex cutters / excessive cell counts, material inheritance and Undo.
- Saved Auto Integer Snap, applied within geometry transactions with collapse protection.

## Added in alpha 45

- Seeded solid/hollow Rock with convex decomposition, grouping, preview and Undo. Grouping is per input brush since alpha 50.
- Brush Sculpt: Raise/Lower/Smooth, shared-vertex protection, stroke Undo/cancel, editable-only selection.
- Array line/cross-line patterns, rings, mirrored offsets, radius and facing presets. Live preview/settings history were added in alpha 48.

## Added in alpha 44; detailed parity remains under review

- Inset: selected-face inner contour and border volumes, grid snapping, preview and one Undo. Extended border sectors preserve volume when the source widens behind the selected face.
- Subdivision: whole-volume U/V cuts in world planes or a selected face's texture basis; segments or grid cells. The reference contains dormant surface-panel and smoothing helpers, but its current UI/rebuild path subdivides volumes.
- Spin: selected-face segmented extrusion, curved endpoint, scale and Euler rotation, preserving the original brush. Interactive endpoint handles were added in alpha 48.
- Settle: isolated Bullet 3.25 simulation, convex obstacles and tessellated patch triangles, cancellation, scene-change rejection and transactional result application. Windows and Linux integration tests cover brush and patch contact, Apply, Undo and Redo.

## Present counterparts; detailed parity must still be verified

- Convex Bevel: radius, segments, profile, face boundary/edge/vertex selection, per-brush clamp and in-scene preview.
- Terrain generator for convex brush grids and selected patches; grid rotation.
- Core selection, transforms, clip, CSG, vertex/edge/face editing, snapping and undo history.
- Entity/material browsers, texture collection filters, WAD loading and palette handling.
- Linked groups, layers, prefab insertion, patch controls, Sweep and UV editing.
- FTE runtime/BSP viewing provides a different architecture from ReyondBroom's Quake preview. Doors, trains, light/sky settings and camera behavior are not automatically equivalent.

## Added in alpha 42–43

- Fracture: convex seeded Voronoi cells, separation, cut material, optional separate `func_wall`, scene preview and transactional apply. FTE retains its 64-plane brush limit.
- Perforate: polygonal through-holes, diameter range, count, side count, spacing and optional selected `func_wall` plugs. Uses conservative rejection sampling rather than ReyondBroom's exact placement implementation.

- Array: original selection is duplicated independently for each sample; brush/entity transforms share the existing affine transaction path.

## Still missing or materially partial

- Spin and Bezier Bend interaction edge cases remain under review.
- Array now has linear, radial and seeded random placement with one undo. Multiple rings, cross-lines, mirror offsets and facing presets are present; live preview/settings history are present; exact interaction parity remains under review.
- Symmetry: automatic relinking of pre-existing counterparts and live guide planes remain missing; 2/4/8 synchronized side groups are present.
- Rock and Sculpt exact interaction parity and large-scene performance remain under review.
- Polygon Cut/Spawn specialized orthogonal decomposition and exact interaction parity remain under review.
- Subdivision exact interaction parity remains under review. Dormant surface/smoothing helpers are not exposed reference features; triangular-brush conversion is present in alpha 50.
- Spawn Master is present; runtime compatibility must be checked against each game/mod.
- Unity Sync export and its Unity-side integration.
- Exact equivalence for prefab collections, entity list and game-specific previews.
- Broader game/format support beyond the three FTEBroom profiles. Shared MAP syntax alone is not profile support.
- Ultimate's inner/asymmetric Bevel and offcut handling, beyond the current convex Bevel.
- Ultimate's texture-folder import, palette selection and compile-WAD workflow as a single integrated operation.
- Exact live-apply behavior across every generator, Russian keyboard-layout shortcuts and native guide capture. Shared Default/settings Undo/Redo/Escape controls are present in alpha 50.

## Cross-platform gaps

- Embedded child-process mod viewport: Windows only.
- Desktop import has shared handling now, but native file-picker integrations and decoder coverage differ.
- Linux audio helper is system ffmpeg; Windows packages its helper.
- Platform defaults intentionally differ: Linux UI scale 100%, Windows 125%.

## Model conversion scope

The engine's model reader list is larger than its writer list. The current conversion bridge samples loaded alias models and exposes MD3 and static OBJ writers. This is not an all-formats converter. Further target writers need their own limits, animation/texture conversion, warnings and round-trip tests. The agreed policy is to warn about losses and allow animation baking; never silently report a lost animation as preserved.
