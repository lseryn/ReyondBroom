# Geometry foundation — 0.5.0-alpha.7
[Combined 0.6 + 0.7 manual checklist](checks-0.6-0.7.md)

## What changed

The new `qc/fb_geom.qc` module converts a convex brush into an owned polyhedron (vertices, edges, clockwise face loops and material/UV attributes), reconstructs face planes, builds an incremental convex hull from points, validates brush geometry and splits a brush into two compact convex halves.

Clip now commits through the shared split/validation code. Empty source planes are removed from each half; existing surface mapping is preserved and new cut faces receive the current material and default mapping. A tangent, outside or invalid cut leaves the brush unchanged. This stage does not add a hull button, vertex editing, patch creation or CSG tools.

Vertex merge distance is 1/32 unit, supporting-plane tolerance is 0.001, minimum accepted volume is greater than 0.1 cubic unit. Limits are 64 faces, 64 points per face and world coordinates within `ftebroom_world_bound` (default 65536). Fractional coordinates are not rounded to whole units. Engine-generated corners are refined against three independent supporting planes before merging; this avoids errors caused by clipping the engine's large seed winding.

Polyhedra must start zero-initialized and be released with `fb_poly_free`. Their material names are owned; face arrays returned by `fb_poly_to_faces` borrow material storage. Keep the source/polyhedron alive until the engine has consumed that array.

`Rebrushify` was inspected but not reused for the hull: it requires existing triangle connectivity and the companion extraction rounds to integer coordinates. The new hull accepts unordered points, ignores interior/duplicate points, rejects collinear/coplanar input, and merges coplanar hull triangles into supporting planes.

## Verification

Run `ftebroom_selftest` in the engine console, or use `scripts/test-geometry-windows.ps1` on a disposable bundle. The self-test does not create, edit or delete map objects.

26 checks cover cube topology/volume and plane+UV round-trip, duplicate/interior/fractional/rotated hull inputs, a tetrahedron, axial and oblique splits, preserved source mapping and initialized cut mapping, tangent/outside cuts, malformed/unbounded/tiny/over-limit/out-of-bounds brushes, a full 64-face prism and its split, real document extraction, and 500 cube validations. The test wrapper also compares exported MAP bytes before and after the self-test.

Existing editing, gesture, picking, document, history, tool lifecycle and grid tests are rerun for the release. This does not replace testing real mouse input, DPI and the user's game assets.

## Performance and follow-up

Measured in the Windows QC VM on this development machine: about 4.9 ms per 64-face prism validation (10 repetitions), and 24 ms for 500 cube validations. The timer has millisecond precision; these are local measurements, not universal guarantees. The complex-brush case exceeds the roadmap's 2 ms target. See the [native geometry API proposal](native-geometry-proposal.md). No new engine API or native geometry implementation is claimed in this release.

The hull is incremental, not a guaranteed worst-case fast QuickHull implementation. Inputs are bounded at 4096 points; performance at that upper bound is not certified. Near-coincident features below the merge tolerance may be rejected. The older legacy vertex-edit path is unchanged; this release routes Clip commits through the new core.
