# Architecture and research

## Source baselines

- [FTE engine and csaddon](https://github.com/fte-team/fteqw/tree/f937b9d88f71fc4429db5fe56c6a98d922711b2e), pinned SDK/csaddon commit `f937b9d88f71fc4429db5fe56c6a98d922711b2e`.
- [Dear ImGui 1.91.9b](https://github.com/ocornut/imgui/tree/4806a1924ff6181180bf5e4b8b79ab4394118875).
- [ReyondBroom reference](https://github.com/reyond9079/ReyondBroom/tree/08e26168364629c968875215803a4d9720714223).

The default engine is built from the pinned source plus the included metadata patch. An optional user-supplied binary is a separate dependency and must be qualified independently. The build records its SHA256.

## What csaddon provides

`csaddon.src` compiles an addon VM, loaded by FTE as `csaddon.dat`. `csfixups.qc` links shared VM state. `csaddon.qc` wraps scene rendering, routes input and switches editor modes. `editor_brushes.qc` implements brush selection and tool dispatch; brush utility/history files implement geometry operations and undo/redo. Other editors provide lights, entities, terrain and particles. Camera spline support is conditional.

The engine exposes `brush_create`, `brush_get`, `brush_getfacepoints`, `brush_delete` and patch operations. Editable brushes are plane-based convex solids. `mapedit maps/name.map` starts without normal game code and retains editable source geometry. `mod_terrain_save "" name` exports the current map to `maps/name.map`. A loaded BSP follows a different saving path (entity export); it is not an interchangeable editable document.

Existing capabilities are foundations, not proof of production-ready ReyondBroom parity. History, patches, materials and entity association need independent round-trip fixtures before migration claims.

## First implementation

`native/ftebroom.cpp` is a native FTE plugin. It obtains Core, Command, Cvar, 2D and Input interfaces. Dear ImGui receives MenuEvent input and draws through FTE's renderer-independent `Image2dQuad` API. ImGui triangles are clipped against command clip rectangles on the CPU and submitted as degenerate quads. This avoids a second graphics context and avoids tying the frontend to OpenGL. Vulkan/D3D behavior remains untested.

The plugin uploads a font atlas and explicitly loads its UI material: `LoadImageData` does not itself provide a usable shader handle in this FTE implementation. The plugin checks interface availability before loading. The small type declarations before `plugin.h` accommodate unused engine API types in the upstream plugin header; they are not substitute implementations of those APIs.

The panel sends commands and cvars to csaddon. `ftebroom_box` validates dimensions, builds six planes, initializes texture coordinates, adds the brush through existing history and selects it. Redo dispatch is corrected from the upstream accidental undo call. File names are restricted to prevent command/path injection; open and overwrite require confirmation.

Version 0.2 keeps the native menu overlay active and explicitly routes viewport gestures to QC while ImGui receives UI input. Mouse-down ownership is retained until release, so a drag crossing a panel does not become a UI click. Popups block viewport routing. F1 toggles the inspector rather than releasing all editor input. RMB look and held movement commands are forwarded separately. FTE's own update prompts remain under engine control.

## Next stages and acceptance gates

1. **Foundation (current):** buildable plugin/addon, box, history, map export/reopen. Gate: automated geometry round-trip and manual input/scaling checks.
2. **Editor shell:** persistent scene panel, input ownership via ImGui capture flags, camera focus, selection model, entity/material browser and explicit dirty state. Gate: no input leaks; non-destructive cancel and restart recovery.
3. **Core map workflow:** plane/vertex/edge editing, clipping, CSG, entities and patches with tested material coordinates. Gate: representative Quake/Valve220/Q3 fixtures preserve semantics after save/reload.
4. **Procedural geometry:** Fracture, Perforate, Bevel and arrays, one tool at a time. Port algorithms independently of Qt; expose atomic transactions to csaddon. Gate: valid convex outputs, volume/intersection checks, texture invariance and deterministic seeds.
5. **Physics:** Bullet-driven Settle with brush and tessellated patch collision. Gate: repeatable settling, collision filtering, no tunnelling in documented bounds, cancellable preview and one-step undo.
6. **Delivery:** Linux and Windows builds from pinned engine source, automated packaging, license/source bundles, performance and large-map tests.

## Risks

- FTE and ReyondBroom use different geometry, document, entity and history models. Copying Qt dialogs or whole model libraries into QC would not solve those differences.
- QC/native boundaries need explicit ownership and transaction rules; hundreds of VM calls per face can become expensive.
- Coplanar planes, tiny bevel faces, grid snapping and numerical tolerances can invalidate convex brushes.
- MAP dialects, shader names and UV mapping must be tested rather than inferred from appearance.
- FTE plugin API revisions and render restarts can invalidate assumptions or resources. Current preview targets the tested Windows/OpenGL combination.
- Save/open currently has confirmation but no dirty-state tracking or crash recovery. Startup camera positioning uses delayed commands and is provisional.
- CPU triangle clipping and per-triangle submission are sufficient for a small panel, not a demonstrated large-editor rendering budget.

### Engine correction

The round-trip regression exposed an upstream omission in Terr_Brush_Insert: surfaceflags and surfacevalue were not copied into the stored face. The bundled patch copies both fields alongside texture coordinates. The build applies it to the pinned engine source. Keep the patch together with the base source archive when rebuilding. This fixes uninitialized export metadata; it does not add missing Q2/Q3 metadata to the QC face API.

## Version 0.2 gestures

The default smart tool distinguishes clicks and drags with a four-pixel threshold. Selection starts a single-brush move; an unselected surface starts box creation on its height plane. Gestures keep an immutable copy of the original faces and render a preview; release commits through history and Escape discards it. XY ray-plane intersections control horizontal movement. Alt uses screen vertical movement for world Z and rebases the pointer on modifier transitions. Grid snapping is shared between numeric and gesture controls. History timestamps use gettime(0), avoiding merges when the game clock is paused.

## Version 0.3

Drag height starts at the current grid step. Surface grids are depth-tested transparent polygons with world-space dominant-axis UVs, independent of brush materials. Native WASD events drive editor cvars; QC advances the camera using real elapsed time, bypassing gameplay input suppression. Text fields, popups and brush drags clear movement.

The startup ImGui dialog validates a baseq3 path and sets a dedicated engine cvar. The readonly-project-assets.patch mounts that directory before editor paths and without SPF_WRITABLE, preserving editor-only save locations. fs_restart triggers shader discovery; native filesystem enumeration indexes loose files and PK3 contents, including ZIPs without directory entries. Shader parsing supports comments, quoted tokens, nested stages and qer_editorimage. No game configs are executed by the resource loader. Settings store only the resource path in a separate plain-text file.

## Action routing (roadmap 0.1)

`tests/generate-actions.py` owns the action catalogue and generates `native/ftebroom_actions.inc` and `tests/actions-catalog.json`. `native/ftebroom_actions.h` owns chord parsing, context matching, dispatch, menus and diagnostic dumping. Context groups are view (bits 0–1), selection (2–4), and tool (5–15): OR within a group, AND across groups; absent groups are wildcards. Modifiers match exactly. Physical FTE key codes are used, not text Unicode. Reserved actions have null commands and log without editing.

QC publishes view/selection state and consumes the Ctrl/Alt/Shift cvars. Legacy tool 3 maps to Clip; other legacy modes map to NoTool until 0.2. Camera key-up clears held state irrespective of context/modifiers. Plugin focus loss clears keys and cancels an active gesture. This is not OS-level focus verification: physical focus/scaling checks remain in the acceptance checklist.

Run `ftebroom_actions_dump` to inspect effective key codes. `ftebroom_action <quoted-id>` invokes a context-aware action. Native input test commands are available only in the disposable skip-setup test mode, not insecure command contexts. Mouse routing and legacy wheel behavior are deliberately unchanged until their roadmap tasks.

## Modal lifecycle (0.2 preview)

`ftebroom_tools.qc` precedes the gesture module and owns modal IDs, lifecycle callbacks and gesture ownership. Native camera routing takes priority; default QC routing chooses move, shape or selection, preserving ownership until release. Future Extrude/entity drag handlers do not yet claim input. Clip and default tools have geometry implementations; other modal slots are marked as framework.

`ftebroom_cancel` performs one cancellation layer; `ftebroom_tool_deactivate` clears the entire mode. `brush_history_deselect` stores the complete selected brush/face-mask list in a distinct ring entry. ID remapping updates those lists through geometry Undo/Redo. Selection entries cannot merge with geometry timestamps. Both raw history commands and frontend aliases refresh modal state. The full transaction/document model remains tasks 0.3/0.4.

Keep 64-bit face-mask checks separate from integer boolean chains: the pinned QCC can crash compiling a combined expression. Numeric move validates the complete selection before any edits and stores one transaction.

## Document storage (0.3)

FTE `Terr_ReformEntitiesLump` moves nested entity geometry into independent terrain submodels and records `model "*N"` in the editable entity lump. `terrain_edit(TEREDIT_ENT_GET, index)` supplies the fields; precaching the model resolves its QC model index. `brush_findinvolume` with zero planes enumerates brush and patch IDs. `Terr_WriteMapFile` follows the model references, emits geometry inside its owning entity, and preserves ordinary `_tb_*` fields. It does not flatten `func_group`; the synthetic round-trip test verifies this. A separate MAP serializer is therefore unnecessary. The document is represented by the `fb_node_t` array in `qc/ftebroom_document.qc`. Native file replacement, dialogs and backups live in `native/ftebroom_document.h`. The close-guard engine patch routes normal quit and window-close requests to the editor.

## Transaction history (task 0.4)

`fb_transaction.qc` owns nested transaction boundaries, saved redo branches during cancellation, selection snapshots, repeat collation, and whole-transaction eviction. `brush_history.qc` owns dynamically growing records and remaps resurrected geometry references. All current FTEBroom geometry/material operations use the transaction API. Native Edit/toolbar labels read the current history names from QC cvars. Whole-brush selection detection compares both 32-bit mask words because legacy FTE_5768 code generation does not reliably implement the equivalent 64-bit comparison. See `docs/task-0.4.md` for tests, entity/tree hooks and the engine's synchronous bulk-edit queue limitation.

## Grid foundation (task 0.5)

`fb_grid.qc` centralizes grid normalization, scalar/vector/delta snapping, plane-constrained points and future extrusion-distance candidates. `ca_grid` remains compatible with csaddon; its exponent is mirrored in `ftebroom_grid_exp`. Native controls and registered actions share QC grid commands. Current creation, movement and Clip use these helpers. Surface rendering independently chooses a coarser power-of-two spacing when projected tangent separation is below four pixels. The full orthographic background grid is deferred to task 1.2. See `docs/task-0.5.md`.

## Picking foundation (task 0.6)

`fb_pick.qc` returns typed hit records using the document tree, inherited visibility/locking, brush slab/plane intersection, evaluated patch triangles and point-entity class bounds. Screen-space handles take priority; orthographic geometry is sorted by projected area. Patch sorting uses accumulated surface area rather than one mesh triangle. Current pointer selection and Clip placement use this API. Point entities render selectable bounds; their selection participates in transaction history. Near-edge back-face queries support future Extrude. Spatial indexing and the corresponding transform gizmos remain future work.

## Geometry foundation (task 0.7)

`fb_geom.qc` owns temporary convex polyhedra, validates closed edge topology and supporting planes, builds incremental hulls, preserves matching source attributes and returns compact split halves. It never edits the map directly. Clip applies the validated output through existing history transactions. `fb_poly_free` releases vertex/index/edge/face buffers and owned material names. Engine seed-winding corners are refined before vertex merging; coordinates are not integer-rounded. The 64-face validation benchmark exceeds the 2 ms roadmap target; `docs/native-geometry-proposal.md` defines a buffer-based engine follow-up instead of encoding arrays in cvars.

## 3D camera (task 1.1)

`qc/fb_camera.qc` owns view-only position, orbit and FOV arithmetic. Native input sends `ftebroom_camera_input` events; `native/ftebroom_camera.h` owns preferences and per-map camera sidecars. `patches/relative-plugin-mouse.patch` implements relative MenuEvent type 3 and cursor restoration. QC respects the capture flag. Camera changes never enter document transactions. See `docs/task-1.1.md` and `tests/check-navigation.py`.

## Orthographic views (task 1.2)

`fb_view.qc` sets projection before picking, shares XY/XZ/YZ axes, pans and zooms around the cursor, remembers selection bounds and draws grid/axes/compass/soft bounds. Brush gestures and arrow nudges use the visible axes; depth inherits last selection bounds. Two-point Clip uses the first picked surface normal in Perspective and the view depth in 2D. See `docs/task-1.2.md`.

## Task 1.3: viewport routing and caching

`native/ftebroom_views.h` owns layout rectangles, focused/captured pane, maximize state and persistent divider ratios. It publishes per-pane rectangle/type cvars; pointer commands carry pane identity. `qc/csaddon.qc` steps the camera once, prepares focused input projection, then clears/adds/renders each visible scene with the focused pane last. `qc/fb_view.qc` provides linked orthographic cameras. The engine viewport-projection patch updates the render rectangle before project/unproject. Static orthographic geometry uses per-pane render targets; grid and entity labels are drawn in screen space. Active previews bypass the cache. See `docs/task-1.3.md` for validation and performance limits.

## View-aware gestures and surface-grid cache (1.4)

Gesture and modal pointer entry points take an explicit view type. Begin captures it; update/finish reject mismatched views. Native pane capture retains projection while dragging. Orthographic input ignores Alt and applies a latched dominant-axis Shift constraint after snapping; Shift at mouse-down retains face selection. Perspective XY/Alt-Z behaviour is unchanged.

Surface-grid faces are stored in a growable QC cache keyed by document generation, editable model and a 1024-unit camera region. A 5120-unit query cube covers the original 4096-unit vicinity throughout that region. Document rebuild/load invalidates geometry. Camera/projection/grid changes invalidate per-face spacing; opacity and preview suppression are evaluated live. The display-density estimate uses three projections rather than up to 37. Grid geometry remains separate from MAP geometry.

## File paths and automatic camera navigation (1.5)

The ImGui file browser uses native filesystem paths and tracks the original document separately from FTE's generated ASCII staging alias. Save As selects a native target; Save reuses it. Serialization stays with FTE, with adjacent temporary replacement to support different drives. Unicode names are displayed using the Windows-installed Segoe UI font when available. Camera persistence for external maps uses a key derived from their full path.

Camera focus derives a limiting angle from actual perspective viewport rays, fits the selection sphere, and interpolates over 150 ms without rotating. Orthographic centers interpolate to the same selection center. Manual input cancels animation. Coordinate movement leaves orthographic centers unchanged. Point-file navigation awaits the 20.3 loader.

## Object selection (2.1)

`fb_selection.qc` resolves hit nodes to closed groups, operates on brush/patch references and point-entity IDs, and tracks the open group by stable entity ID. Transaction markers own serialized entity-selection/group-context snapshots alongside geometry selection masks. Paint opens one transaction on crossing the drag threshold, samples the cursor path, commits on release and rolls back on Escape. Drill deduplicates group candidates after sorting by depth; normal 2D hits still sort by area.

The native frontend detects double-click using the OS interval (500 ms fallback), four-pixel tolerance and matching pane/modifiers. Pointer commands capture Ctrl/Shift so queued events do not depend on later key releases. Ctrl-wheel routes to selection before camera/grid handling. Test-only input injection remains guarded by skip-setup and command security checks.

## Face selection (2.2)

`selbrush_t.faceonly` distinguishes a full 64-face mask from a selected whole brush. Mask access/initialization uses two explicit 32-bit words because the legacy QC target mishandles some 64-bit operations. History stores both the flag and mask. `fb_faces.qc` owns 3D face gestures and bounded coplanar BFS; polygon adjacency uses SAT plus shared-segment tests. `test-faces-windows.ps1` covers high bits, conversion, material isolation, flood, painting, native double-click routing and complete MAP ownership-preserving round-trips. `brush-multicast-capacity.patch` enlarges the engine serialization scratch buffer for complex brush edits.

## Selection rendering (2.3)

`fb_visual.qc` computes selection bounds and read-only hover state once per frame, draws per-view brush/patch/entity overlays, and places clipped dimension labels after rendering. Selected engine surfaces must be explicitly restored before tinting. Visible edges use depth testing; a translucent pass keeps hidden edges readable. 2D cache keys include hover, colours, masks and lock flags. Stationary hover picking is reused for up to 100 ms; pointer/camera/document/history changes invalidate it. `test-visual-windows.ps1` checks bounds, locks, toggles, rendered colours and byte-identical MAP output.

## Baseline completion (alpha.19)

Container bounds aggregate each visible leaf through its ancestors once, cached by document revision, geometry epoch and filter epoch. Groups and brush-entity submodels are explicitly submitted by the custom scene renderer independently of point-model visibility.

The native property table tracks selected cells and rows separately from active text edits. Entity IDs and the map epoch invalidate this transient state. It handles keyboard navigation locally before scene actions, and batches property removal and layer operations into one QC transaction. Definition-derived class actions are rebuilt with stable backing strings.

MAP plane serialization constructs a well-separated double-precision point basis from the stored plane equation rather than choosing nearly collinear winding corners. The engine patch is tested with independently generated thin beveled brushes and a save/reload/save comparison of oriented half-spaces. Complete document tests still compare UV axes and surface metadata, entity membership, patches and history.
