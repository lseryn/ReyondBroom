# Alpha 66 — filtering defaults, large groups and preview size

## Changes

- Escape returns from BSP preview to the editable MAP. An open dialog or active text field keeps its normal Escape handling. The mod controls menu has an explicit **Exit mod preview** button, translated into all supported UI languages.
- Group and brush-entity bounds use depth testing in the perspective viewport, so opaque brushes hide the covered portions. Orthographic outlines keep their existing behavior.
- New installations start with **8x MSAA**, **1.005 grid smoothing**, **16x texture anisotropy** and **trilinear filtering off**, matching the requested settings. Driver support still determines the effective MSAA level. Existing saved preferences are preserved; change them in Map → View options → Antialiasing and texture filtering if you want these values on an existing installation.
- Windows embedded mod preview requests a full-size game view, including after resizing the viewport. A mod's smaller `viewsize` setting no longer leaves a reduced game view inside the editor panel. The mod's configuration files are not rewritten.
- Group parent lookup now uses an ID index and cached layer ancestry. This removes the quadratic walk that could trigger the QuakeC instruction limit on large documents. Cyclic parent references are recovered into Default Layer. The unused per-frame copy of brush selection flags has also been removed; rendering and selection semantics are unchanged.
- Edit menu labels now read **CSG Convex Merge (Union)** and **CSG Subtract (Difference)**. These are naming changes: Convex Merge still creates a convex hull, not an arbitrary concave Boolean union. Commands and custom shortcut identifiers remain unchanged.

This release retains the already shipped [alpha 64](alpha64.md) and [alpha 65](alpha65.md) fixes, including UV dragging/snapping, compact Tools layout, Shift face perimeters, renderer restart recovery and mod input handling. It does not reimplement them.

## Verification

The filtering defaults and persistence test runs the engine twice, checks all four settings, then resolves a synthetic document with 56,603 nodes in reverse parent order and a cyclic hierarchy. Windows and Linux pass this test. The original supplied crash log contains a `fb_document_rebuild` / `runaway loop` stack in addition to the previously fixed model-registry overflow. The original E1M1 map was not supplied, so this is a regression for that code path, not a claim that the exact map was reproduced.

Windows also passed 19 group/layer/visibility/history checks, editing gestures and the hotel02 full MAP round-trip (2,394 brushes, two patches, unchanged input, maximum plane-coordinate drift 0.000533). Compilation tests cover BSP/VIS/LIGHT, LIGHT-only, Escape back to MAP, compiler failure/cancellation and retained Undo/Redo. The group-occlusion fixture creates a real group through the editor, compares covered/exposed rendered images, and runs on both platforms.

## Check after updating

1. On a fresh installation inspect the four filtering defaults. On an existing installation check that your saved values remain intact. Change the values, restart and check persistence. When applying MSAA to an editable MAP, confirm the UI, map and Undo/Redo remain available.
2. Open the previously crashing E1M1 map and hotel02. Navigate, select brushes, expand groups/layers, hide/show and lock/unlock groups, then save a copy and reopen it. Check responsiveness and geometry.
3. On Windows compile a map, open Preview mod and resize the editor and its side panels. The game image should fill the available 3D viewport. Test Free camera, Play mod, Escape controls, return to editing and closing the editor while preview is running.
4. Inspect distant brush outlines and surface grids with the new filtering settings. They should not change brush geometry, selection or texture alignment.
5. In Edit check the Union/Difference labels and use each on a disposable pair of overlapping brushes. Undo/Redo; confirm existing shortcuts still work.
6. For the retained alpha 65 changes, test horizontal and vertical Tools docks, collapsed extra tools and Shape / move controls, UV wheel zoom without inspector scrolling, and Shift hover without face triangulation diagonals.
7. In Show BSP press Escape and check that MAP editing, camera navigation and Undo/Redo are restored. In the mod Escape menu choose Exit mod preview.
8. Put a group behind a solid wall: its blue bounds must be hidden. Move around the wall and check the newly exposed outline. Repeat with a brush entity.

Embedded mod preview remains Windows-only; Linux retains BSP preview and external mod launch. Linux automated graphics tests use Xvfb/Mesa, not a physical Arch Wayland session. FPS and mouse feel on the user's hardware still need the checks above.
