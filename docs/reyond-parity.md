# ReyondBroom comparison ledger

Reference: [ReyondBroom](https://github.com/reyond9079/ReyondBroom/tree/08e26168364629c968875215803a4d9720714223), its README, feature manuals and `lib/TbMdlLib` / `lib/TbUiLib` implementations. The scope includes the fork's additions as well as editor behavior. A similarly named control is not proof of parity.

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

- Settle and Bullet collisions with brushes and tessellated Quake 3 patches.
- Dedicated Inset, Spin and Bezier Bend tools.
- Array now has linear, radial and seeded random placement with one undo. Multiple rings, cross-lines, mirror offsets, facing presets and live preview are still missing.
- Synchronized symmetry tooling; ordinary mirror and linked groups do not establish equivalent behavior.
- Rock generation and geometry Sculpt.
- Polygon Cut and Polygon Spawn.
- Subdivision and triangular-brush conversion.
- Subtract 2's distinct workflow, beyond ordinary CSG subtract.
- Spawn Master / teleport-closet generation.
- Unity Sync export and its Unity-side integration.
- Exact equivalence for AutoIntegerSnap, prefab collections, entity list and game-specific previews.
- Broader game/format support beyond the three FTEBroom profiles. Shared MAP syntax alone is not profile support.

## Cross-platform gaps

- Embedded child-process mod viewport: Windows only.
- Desktop import has shared handling now, but native file-picker integrations and decoder coverage differ.
- Linux audio helper is system ffmpeg; Windows packages its helper.
- Platform defaults intentionally differ: Linux UI scale 100%, Windows 125%.

## Model conversion scope

The engine's model reader list is larger than its writer list. The current conversion bridge samples loaded alias models and exposes MD3 and static OBJ writers. This is not an all-formats converter. Further target writers need their own limits, animation/texture conversion, warnings and round-trip tests. The agreed policy is to warn about losses and allow animation baking; never silently report a lost animation as preserved.
