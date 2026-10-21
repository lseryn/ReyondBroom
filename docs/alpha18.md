# Alpha.18: convex tools, entities and map organization

[Русский](alpha18.ru.md) · [Full manual checklist](checks-alpha18.md)

This batch implements the convex editing, entity and organization workflows from roadmap phases 8–15, plus Move Face and rotation-pivot history from earlier phases. It keeps Dear ImGui. Linked groups, patch editing tools, Sweep and the UV editor (phases 16–20) are outside this batch. Existing patches remain loadable, selectable, transformable and exportable.

## Geometry

- **Clip (C):** place two or three points. Two points use the clicked surfaces/view to determine a cutting plane. Drag existing points; drag empty space to place a pair. Double-click a face to use its plane. Escape removes the last point or cancels a drag. The discarded portion is orange and translucent. Choose Front / Both / Back, then apply. Invalid and tangent cuts do not destroy the source. The transaction is validated before replacement.
- **CSG:** Convex Merge (Ctrl+J), Subtract (Ctrl+K), Hollow (Ctrl+L), Intersect (Ctrl+Shift+K). Subtract uses selected brushes as cutters against other editable brushes; hidden/locked objects are excluded. Hollow thickness follows the grid and skips volumes too thin for the inset. Each operation is one Undo.
- **Vertex / Edge / Face (V/E/F):** shared position handles, click/Ctrl-click and rectangle selection, dragging, keyboard movement, Delete with convex-volume validation, snapping and convex merge. Non-planar faces are reconstructed by the hull kernel. Invalid movement keeps the last valid preview. Shift-drag from a surface adds a vertex; Shift+Alt-click a vertex merges selected vertices toward it. Esc cancels preview changes. Selected edge/face outlines are highlighted.
- **Move Face:** with a whole brush selected, Shift+Alt-drag a face. In 2D the face moves in the view plane; in 3D it follows its normal. The hull remains convex. Esc cancels; Undo restores the complete brush.
- **Scale / Shear:** drag bounding-box handles, edges or faces; numeric size/factor fields are also available. Scale anchors on the opposite side, Alt uses the center, Shift preserves proportions. Shear moves one side in its plane. Selected geometry can be passed from V/E/F into Rotate, Scale or Shear.
- **Rotate:** movement of the pivot now has Undo/Redo as well as Escape cancellation.
- **Brush (B):** in perspective, click surface points, drag a rectangle or double-click a face to collect its vertices. Shift-drag a planar polygon to give it thickness. Enter creates a convex brush after validation. Four non-coplanar points are required for a volume.
- **Shape settings:** cuboid, cylinder, hollow cylinder, cone, UV sphere, icosahedron, stairs, arch and spandrels. Choose axis, sides, circle mode, thickness and other shape-specific options. Edge/vertex circles and scalable 12/24/48/96-sided circles are available. Drag creation uses the selected shape; Replace selection uses its bounding box. Multi-part shapes can be grouped.
- New surfaces use texture scale **0.5** by default. Existing MAP texture axes are read without applying this default a second time.

## Entities

The Entity tab loads the bundled 53-class Quake 3 definition set, or game `scripts/entities.def`. Settings accepts external `.ent`, `.def` and `.fgd`; FGD includes and base classes are resolved. The chosen external path is stored in worldspawn `_tb_def`. F6 reloads definitions without reopening the map. A malformed file leaves the previous definitions available and displays the error.

Filter/sort classes and drag a point class from the browser into a viewport; a bounding-box preview shows placement. Double-clicking a class creates it at the numeric position. Brush classes use the selected brushes. The scene context menu also creates entities and moves brushes into an existing brush entity.

The property inspector edits selected point entities and owners of selected brushes; with no such selection it edits worldspawn. Mixed values are blank with a placeholder. Enter commits text and moves down the column; Tab commits and moves to the next cell. Ctrl+Enter or + New property adds a key for editing. Instantiate defaults on creation is optional and off by default for Quake 3. Right-click a field to remove, reset or rename it. Defaults appear subdued and can be instantiated with the existing/missing/all defaults commands. Flags preserve unrelated bits on each selected entity; choices and colors have dedicated controls. Internal brush-model references are protected. Undo restores property changes and ownership.

Entity models support literal resource paths and the entity's model, frame, skin, modelscale/modelscale_vec and angle/angles/mangle properties. Missing resources use class bounds. Target/killtarget links have arrowheads and None/Direct/Transitive/All display modes.

## Organization and export

Map → Groups and visibility provides Group, Ungroup, Rename, Hide, Isolate and Show All. Ctrl+G opens a naming dialog. Double-click opens a group; objects outside it are locked. Context actions add/remove objects, merge selected groups and move them between layers. New objects follow the open group or active layer. Empty containers are cleaned up when geometry is removed by organization/CSG operations.

Map → Layers provides an active layer, visibility, locking, omit-from-export, ordering and a context menu. Layer and group metadata stays in the editable MAP. Make Structural returns brush geometry to its enclosing world/group/layer and removes editable special tags.

**File → Export Map…** writes a separate compiler-facing file: groups/layers are flattened, `_tb_*` metadata is removed and omitted layers are excluded. Brush entities remain entities. Export does not rename the open document or mark it saved. Ordinary Save preserves all organization metadata.

Map → View options controls classes, brush tags, entity models/names/bounds, group/brush-entity bounds, textures/flat/wireframe, shading, edges, links and map bounds. Quake 3 shader surface parameters contribute tags. Common clip/caulk/hint/trigger surfaces receive translucent editor rendering. Tag actions and display actions are available in the rebindable catalogue.

Short RMB click opens the scene menu; RMB drag remains camera movement. Menus include context-sensitive group, layer, class, material and entity actions.

## Limits to understand

- This is an experimental implementation, not a claim of pixel-for-pixel or exhaustive behavioral parity. The entity inspector provides a resizable key/value table, Tab navigation, Enter to the next row and Ctrl+Enter to add a property. Arrow-key cell selection is not identical to the reference spreadsheet. The browser uses class-bounds previews rather than rendered model thumbnails. Arbitrary model-expression scripts in definitions are not evaluated.
- Convex brushes have a **64-face engine limit**. UV sphere settings are validated against it. Icosphere accuracy above zero is rejected (the next level needs 80 faces). No concave brush is written; multi-part shapes contain convex brushes.
- Point-based Brush assembly operates in perspective. Existing patches support textured, flat, shaded and wireframe display. Use fog controls engine global and volume fog.
- Vertices merged during a drag stay merged until release; Escape restores the original pair. Color-picker changes commit on release.
- The compiler-facing export uses Valve 220 texture axes plus Quake 3 patch syntax. Compile/play integration, linked groups, patch construction/control-point tools, Sweep and a UV editor are not part of this release.
- Automated engine checks exercise geometry, input routing, history and file output. Real baseq3 resources, mouse ergonomics and display scaling still require the [manual checklist](checks-alpha18.md).
