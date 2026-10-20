# Architecture and research

[Русский](ARCHITECTURE.ru.md)

## Source baselines

- [FTE engine and csaddon](https://github.com/fte-team/fteqw/tree/f937b9d88f71fc4429db5fe56c6a98d922711b2e), pinned SDK/csaddon commit `f937b9d88f71fc4429db5fe56c6a98d922711b2e`.
- [Dear ImGui 1.91.9b](https://github.com/ocornut/imgui/tree/f5befd2d29e66809cd1110a152e375a7f1981f06).
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
