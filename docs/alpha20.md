# ReyondBroom 0.5.0-alpha.20

## Rendering and performance

Custom brush surfaces now cache geometry, material coordinates and shaders instead of rebuilding them every frame. Rendering visibility is cached independently of interactive picking. Opaque faces write depth; transparent editor materials retain a separate pass. Back faces and off-screen face bounds are culled conservatively. Unselected target links no longer trigger needless selection traversals.

White, depth-tested brush edges are enabled by default. The surface grid covers world brushes and brushes belonging to groups/entities, follows the current grid spacing, and rebuilds after edits, Undo and map loading. Grid polygons and edges are submitted in separate batches. Distant grids still coarsen to avoid aliasing; changing the displayed grid does not change snapping. View options can hide edges; the grid visibility and opacity controls remain available.

Point entities without an available game model are shown as shaded, class-colored boxes. Their labels are drawn after the scene; bounds and models still respect visibility filters. Rendering entry points now require explicit geometry/label modes rather than omitted QuakeC arguments.

## Editing fixes

- Folder entries open with a single click in the shared Open, Save As, Export and entity-definition browser. Parent navigation, drives and Unicode paths remain supported.
- Delete recognizes a point-only scene selection. A previously focused property cell no longer intercepts Delete while the pointer is in the scene. Text editing and inspector property deletion keep their own contexts.
- Cone apex editing uses well-conditioned supporting-plane intersections and removes only collapsed consecutive winding edges. Closed topology, convexity and the original plane tolerance remain validated. A 32-sided cone can be raised in side view or with Alt in perspective, then undone.
- Startup no longer requests unrelated Quake 1 player models while waiting for Quake 3 definitions. MAP-line indexing diagnostics require `ftebroom_debug_lines 1`.

In perspective, ordinary dragging remains on XY; hold **Alt** to move vertically along Z. In an XZ/YZ view, drag upward directly.

This update stays within phases 0–15. It does not add linked groups, advanced patch tools, Sweep or a UV editor.

See [the verification checklist](checks-alpha20.md).
