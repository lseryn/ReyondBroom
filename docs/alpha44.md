# Geometry tools: Inset, Subdivision, Spin and Settle

Alpha 44 adds these tools on Windows and Linux. These tools are part of the continuing ReyondBroom / UltimateTrenchBroom transfer, not a declaration of complete parity.

## Inset

Shift-click exactly one brush face, then choose **Edit > Inset**. Set a positive amount, optionally snap the inner contour to the current grid, and use **Preview** or **Apply**. The result consists of an inner volume and one border volume per face edge. It preserves the full original volume, including brushes that widen behind the selected face. Invalid, collapsed or non-convex snapped contours are rejected without replacing the source.

The amount follows the source tool's radial scaling convention: it is measured against the shortest corner-to-centre distance, not a uniform perpendicular edge offset. Existing surface attributes are retained; newly cut surfaces inherit source material settings.

## Subdivision

Select convex brushes and choose **Edit > Subdivision**. Choose U/V segment counts or a cell size and a world plane. With **Align to selected face texture**, select one face per brush; grid cell size is then measured in texels, so texture scale and orientation affect the cuts.

This operation divides entire brush volumes into convex cells. It does not yet implement Ultimate's separate face-only subdivision/smoothing workflow. A request may produce at most 512 pieces; overly dense requests fail atomically.

## Spin

Shift-click the faces to extrude and choose **Edit > Spin**. Select segment count, endpoint offset (or automatic face-normal direction), flexibility, final scale and final rotation. **Preview** leaves the original brush visible; **Apply** keeps the source and selects the new extrusion segments. One Undo removes the extrusion.

The path blends straight and quadratic interpolation and rotates/scales successive cross-sections. Each segment must be representable as a valid convex brush. Interactive endpoint handles are still pending; this version uses numeric endpoint controls. The operation is bounded to 512 generated pieces.

## Settle

Select whole convex brushes and choose **Edit > Settle**. Set friction, bounce, initial impulse, simulation duration and seed, then press **Simulate**. Bullet runs in a background worker and reports progress. The final result appears as a scene preview. **Apply** records one Undo step; **Cancel** discards the result.

Visible brush geometry and tessellated Quake 3 patches are static collision obstacles. Selected `func_wall` brushes still collide. Initial intersections are rejected; separate overlapping pieces first. No invisible floor is added. The current limits are 128 selected brushes, 4096 static brushes and 262144 patch triangles. The simulation uses gravity of 800 map units per second squared and 240 Hz substeps. Extreme trajectories and penetrating final contacts are rejected.

Editing the document or changing selection invalidates the result. Source materials and texture coordinates follow the editor's texture-lock setting. This tool transforms brush geometry; it does not run entity scripts or simulate point entities or FTE heightfield terrain.

## Regression coverage and manual checks

- `tests/test-settle.cpp`: brush/triangle-floor contact, initial overlap rejection, partial-construction cleanup, cancellation, bounds, deterministic seed and progress completion.
- `scripts/test-partitions-linux.sh` and `scripts/test-partitions-windows.ps1`: Inset volume, a widening brush, Subdivision world/texture cells, Spin geometry, Settle with an actual patch, Apply/Undo/Redo and stale-result rejection.
- Manually inspect textured results with texture lock on and off; preview/cancel and undo should preserve the source.
- Try several fragments over a sloped brush and a curved patch, then change the seed and friction. Check contacts and verify that cancelling leaves the map unchanged.
- Change selection during simulation; Apply must reject the old result. Keep the map editing and BSP/mod preview workflows separate while testing.
