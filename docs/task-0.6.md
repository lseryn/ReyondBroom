# Picking foundation — 0.5.0-alpha.6

## Visible changes

- Scene clicks and Clip placement use the new picker. In perspective, the closest eligible surface wins.
- In orthographic views, overlapping brushes are ordered by the projected area of the intersected face. A small brush can be selected inside a larger overlapping brush.
- Patches are picked against the triangles of their evaluated surface, not their control-point box. They can be selected; moving or editing their control points remains later work.
- Point entities have visible bounding boxes. Clicking one selects it, highlights its box and shows its name in the inspector. Selection is undoable. Their movement/property editor is not part of this stage.
- Hidden/locked nodes and descendants of hidden/locked layers or groups are excluded from normal pick queries. This is a picking filter; general layer management and enforcement in every editing command remain later tasks.

## API

`fb_pick(pixel)` fills a dynamic `fb_hits` array with kind, model, object ID, face, distance, point, normal, document-node index and projected area. It returns the number of hits. `fb_pick_query(start,end,pixel,flags,kinds,orthographic)` exposes explicit rays and inclusion filters.

Brush queries first reject bounding boxes, then intersect the ray with all convex brush planes. Parallel rays, rays starting inside a brush and face IDs are handled explicitly. Patch queries reject bounds, then test both triangles of each evaluated mesh cell. Their 2D sorting area is accumulated over the patch, rather than taking an individual small triangle.

Point entities use the existing csaddon class bounds, translated by their origin; unknown classes use the existing ±8-unit fallback. This is bounding-box selection, not per-triangle picking of entity models. Brush entities use their raw MAP brush geometry.

Tools can register up to 256 handles through `fb_pick_handle(id,point,radius,node)` and clear them through `fb_pick_clear_handles()`. The default radius is six screen pixels. Handles take priority over scene geometry; a registered document parent supplies hidden/locked filtering. Registrations are cleared on tool refresh and document load. This stage provides the API, not Rotate/Scale/Vertex gizmos.

`fb_pick_near_face(pixel)` searches selected brush edges within eight pixels and returns a back-facing adjacent face for future Extrude. It is intended as a fallback when direct surface picking misses. Extrude and drill-selection controls are not implemented by this foundation stage.

Queries iterate the document's nodes with per-object bounds rejection. There is no spatial index yet; very large maps and dense patches still need performance testing.

## Verification

Run `scripts/test-pick-windows.ps1 -Bundle <bundle> -Python <python>`. The asset-free engine fixture checks three successive brushes and their distances, hidden/locked filtering and overrides, inherited locking, inside/parallel rays, a handle at five pixels and outside six pixels, curved-patch intersection, entity bounds, near-edge back faces, ordinary entity/patch clicks, selection Undo and actual orthographic clicks. Queries must leave exported MAP bytes unchanged.

Existing gesture, material/Clip, grid, document, history and tool-lifecycle tests remain required.

Please test:

1. Select ordinary brushes, Shift+click faces, move and cut them.
2. In a 2D view, click a small brush overlapping a larger one.
3. Click a curved Quake 3 patch and verify selection follows its surface.
4. Click a point-entity box, check the inspector name, then Undo.

## In-editor preview

![Selected point entity and its class in the inspector](../screenshots/picking.png)

Escape clears entity selection; Undo restores it. The automated regression covers 25 picking checks and an unchanged MAP round-trip.

