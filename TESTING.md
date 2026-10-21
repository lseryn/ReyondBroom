# Prototype checks

The smoke test intentionally compares complete exported face records, including texture axes and optional metadata. Do not weaken it to ignore differing surface flags: older FTE binaries can emit uninitialized flags even when geometry looks correct. A binary is not qualified for this preview until the complete round-trip passes.

The screenshot check verifies actual FTE/ImGui rendering. It is not a substitute for clicking controls, cancelling dialogs and checking focus. The user checklist in README covers those remaining interactive checks.

## Recorded verification, 2026-10-19

- Native Windows x64 plugin compiled with MinGW GCC 15.2; csaddon compiled with pinned FTEQCC, zero warnings.
- Actual FTE/OpenGL screenshot confirms readable ImGui, grid floor and generated cube on NVIDIA RTX 4060 Laptop GPU.
- The full export regression failed on the old supplied engine and on the unpatched pinned engine. The pinned engine plus the included two-field copy patch passes: 12 faces after create, 6 after undo, and identical complete face records after redo, rejected invalid input and reload.
- Manual pointer/keyboard focus, dialog cancellation and Windows scaling checks remain for the first user test. No parity claim is made for advanced tools or Q2/Q3 document metadata.

## Version 0.2

Gesture regression: click leaves geometry unchanged; XY moved a 128-unit cube by (48,-16,0); Alt-Z then moved it by (0,0,32); cancellation preserved the exact export; drag created exactly one six-plane box; one Undo removed only that box and Redo restored it. The native frontend routes to these same QC functions. To reproduce, copy tests/gestures.cfg to the runtime game folder, run FTE with +exec gestures.cfg, then run python tests/check-gestures.py <runtime-game-folder>/maps. Real pointer routing, F1 and modifier transitions still need manual checks.

## Version 0.3

- `scripts/test-project-windows.ps1 -Bundle <bundle>` creates original loose and PK3 fixtures in a disposable installation. It validates 8/32-unit drag heights, nested archive paths without directory entries, a shader with qer_editorimage and no matching image name, material assignment in the export, and a one-second W press routed through the native MenuEvent handler while the inspector is open. Source fixture hashes remain unchanged.
- The complete create/undo/redo/invalid-dimensions/MAP-reload smoke test passes. QC compilation reports zero warnings. Engine screenshots verify the startup dialog and depth-tested surface grid.
- Manual checklist: load your real baseq3, filter and preview several materials, create brushes at grid 8/32/64, fly with WASD without RMB, type a material filter without moving the camera, and verify restart remembers the path but still asks for a game. Full retail Quake 3 resources and BSP compilation were not tested.

## Version 0.4 — 2026-10-20

- `scripts/test-editing-windows.ps1 -Bundle <bundle> -Python <python>` checks one-face material assignment, scales 2/4, a 90-degree rotation, unchanged other faces, complete Undo/Redo and MAP reload, whole-brush material application, two-half clipping, front/back retention and rejection of tangent, missing and collinear cuts. Half-brush bounds verify the split preserves the original box volume. Each accepted cut is undone as one transaction.
- Native event routing changes grid 16 → 32 → 16 with wheel events and activates Clip with C. Engine logs and screenshots verify the permanent workspace returns after opening another map. Actual FTE screenshots show material tiles, selected material, UV controls and colored cut previews.
- Basic smoke and gesture tests pass: click selection, XY and Alt-Z movement, cancellation, drag creation, separate history steps and full face-record round trips. Project fixtures pass 8/32-unit heights, nested PK3 and loose resources, shader discovery, WASD routing and read-only source hashes. QC compilation reports zero warnings.
- Regression fixes cover brush identity remapping through successive history operations, ownership of material strings in snapshots and drag previews, and a mixed integer/float QC condition that incorrectly treated creation as movement.
- User checks still required: real mouse selection of cut points and single faces, typing/committing UV fields, filtering real baseq3 collections, scrolling a large library, Windows scaling and focus during dialogs. Automated commands exercise the native event handler and shared QC editing functions; they do not replace those interactive checks.

## 0.5.0-alpha.1 / roadmap task 0.1 — 2026-10-20

PASS: optimized native build; action routing (190 entries, disjoint chords, native Ctrl+Z/Ctrl+Y/Ctrl+Shift+Z, text/popup guards, C, reserved/unknown actions); editing/material/UV/clip round trips; smoke; gestures; project PK3/loose assets and WASD. The action reference was inspected in an actual FTE screenshot (`screenshots/actions.png`). Screenshots must be captured with only one test instance running: background rendering can otherwise leave a stale frame.

Run `scripts/test-actions-windows.ps1 -Bundle <bundle> -Python <python>`. To regenerate the shortcut reference, run `python tests/check-actions.py <test-game-dir> docs/shortcuts.md`. Catalogue edits belong in `tests/generate-actions.py`; regenerate both outputs with that script.

Physical input, OS focus loss, non-Latin keyboard layout and Windows DPI are **pending user acceptance**, not claimed as automated coverage. Follow [task 0.1 checklist](docs/task-0.1.md) before proceeding to 0.2. This version does not implement all reserved actions or change legacy wheel/camera behavior.

## 0.5.0-alpha.2 — tool lifecycle preview

Task 0.1 was accepted by the user on 2026-10-20. The 0.2 lifecycle test (`scripts/test-tools-windows.ps1`) drives native key events: C toggles, Escape removes three Clip points one by one, exits the mode and deselects; Ctrl+Z/Ctrl+Y restore/reapply deselection; V replaces Clip, and Shift+Escape clears synthetic handle state. The exported full MAP face records remain unchanged. Numeric Move by 32/0/0 verifies brush bounds and an exact Undo. This is a state test, not a claim of interactive vertex editing.

Manual acceptance remains [the task 0.2 checklist](docs/task-0.2.md), including physical drags, pointer hit testing of the new bar, modifier transitions and texture-lock behavior. Advanced geometry and its parameter pages remain later work; see the framework boundaries in that document.

PASS on the final QC/native build: tool lifecycle, action routing, gesture constraints, editing/UV/Clip round trips, smoke and project resource/WASD tests. QCC reports zero warnings. Actual FTE screenshot: `screenshots/tools.png`.

## Version 0.5.0-alpha.16 — 2026-10-20

The batch includes selection commands, box creation, mixed-object transforms, clipboard, material tools, Rotate and Extrude/Split/Stamp. Tests ran in disposable installations with the pinned engine and all eight patches. QC compiled with zero warnings; the native plugin compiled successfully.

Passing focused checks: 17 selection-command checks, 11 shape checks, 20 mixed-transform checks with complete MAP comparisons, 6 surface-metadata checks, independent group/model copies, clipboard parser/export/native-QC transfer, 17 material checks, 9 texture-transfer checks, 15 affine checks, 7 interactive Rotate checks and 20 Extrude/Split/Stamp checks. Extrude covers shared opposing faces, collapse limits, world-space UV, 2D gestures, split direction, prism volume and perpendicular sides on a sloped face.

Regression checks passed for 38 face-selection cases, 52 object-selection cases, 26 geometry cases, 37 grid cases, gesture constraints, 27 view/Clip assertions and 12 visual-state checks with complete unchanged MAP data. The old 2D creation assertions were updated for outward snapping and camera-side default thickness introduced in task 3.1; they no longer expect nearest-rounded endpoints.

Actual engine images were inspected for the alpha.16 Split preview and material inspector, including alignment buttons and attribute controls. The clipboard transport test uses an isolated fixture and preserves the OS clipboard; actual application-to-application paste remains in the manual checklist. The full roadmap is not complete. See [features](docs/alpha16.md) and [combined checks](docs/checks-alpha16.md).

## Alpha.17 workspace

Run `scripts/test-workspace-windows.ps1 -Bundle <bundle> -Python <python>` in addition to the layout/action/material/transform/extrude suites. The workspace runner uses two separate engine processes and a disposable installation: 14 assertions cover default docking, splitter drag, central scene input, floating panel input, rasterized font scaling, local persistence, restart and reset. It compares complete before/after MAP bytes and verifies screenshots contain the intended panel colors. Inspect `workspace-dark.png`, `workspace-floating.png`, `workspace-large.png` and the material screenshot visually. See [manual checks](docs/alpha17.md) / [проверки](docs/alpha17.ru.md).


## Alpha.18: convex editing, entities and organization

All tests use disposable installations. The native plugin and QC compile successfully; QC reports zero warnings. The engine includes the previous eight patches and `editor-fog-toggle.patch` (OpenGL global and local-volume fog control).

Focused passing suites: Clip interaction (16), CSG (13), Vertex (28), Rotate (10), Scale/Shear (13), Assemble (11), primitives (16), entity properties/ownership/defaults (24), groups/layers (17), filters/tags/links/export (19 plus native destination validation). The entity definition parser fixtures cover ENT/DEF/FGD and inheritance. Native property-input tests cover Tab commit, Ctrl+Enter creation, rename, value editing and Undo. Image comparisons cover patch textured/flat/shaded/wire modes and fog on/off; the MAP remains byte-identical.

Regression suites include full document MAP round-trips (brush/entity/patch), Unicode file browsing, clipboard transport, object selection (52), selection commands (17), materials (17), texture transfer (9), affine (15), Extrude (20), editing/UV/Clip history, camera input (41), rebindable action catalogue and workspace persistence (14). Run `scripts/test-<suite>-windows.ps1` with `-Bundle` and `-Python`; dedicated new runners are listed under `scripts/`.

Actual engine screenshots were inspected for the entity property table and scene render modes. Automated coverage does not replace manual tests of real baseq3 resources, mouse ergonomics, drivers or DPI. [Complete checks](docs/checks-alpha18.md) / [Полный список проверок](docs/checks-alpha18.ru.md). No linked groups, patch editing tools, Sweep or UV editor were implemented.


## Alpha.19 — 2026-10-21

Native plugin and pinned engine rebuilt successfully; QC compiles with zero warnings. All ten engine patches apply in order to the pinned source and reproduce the files used for the engine build. The action generator reproduces the static catalogue; definition-derived class/create actions extend it at runtime (325 actions with the bundled definitions).

Focused passes: entity properties (28), extended native property-table input (Tab, Ctrl+Enter, rename, Enter, arrows, F2, Delete routing and Undo), Vertex (29, including UV coordinates on newly triangulated faces), organization (19, including one-step batch Undo), filters (19), unselected submodels (10 plus image/MAP comparisons), Assemble (11), primitives (16) and the native ENT/DEF/FGD parser fixtures. Actual engine screenshots were inspected for the property table and unselected group/brush-entity surfaces.

Regression passes include geometry (26), Clip interaction (16), CSG (13), Scale (13), Rotate (10), affine (15), materials (17), clipboard transfer, complete document round-trip, object selection (52), selection commands (17), external Unicode file browsing, render modes/fog, workspace persistence (14) and transaction history. The history fixture now respects phase 8: Delete belongs to the last Clip point; with no point it leaves geometry and history unchanged. The document test compares oriented plane equations instead of arbitrary point bases while retaining exact texture/surface attributes and entity/patch checks.

`test-map-roundtrip-windows.ps1` copies its input into a disposable installation, checks the original hash, saves/reloads/saves, compares plane counts and equations, then exercises Select All and Invert. An independently generated 16-brush thin-bevel fixture passes. The private `hotel02.map` test retains 2394 brushes and 2 patches through repeated saves, with maximum plane-distance drift below 0.001 units; all 2396 brush/patch objects can be selected and inverted without QuakeC runaway. The user's map and game assets are not distributed. FTE still applies its normal import tolerances to nearly degenerate source faces; this is not a byte-identical source-format promise.

The geometry benchmark measured approximately 6 ms for a 64-plane prism and 26 ms for 500 boxes on the development machine. The native-geometry proposal remains the follow-up allowed by task 0.7. Physical input ergonomics, real material libraries and Windows DPI remain manual acceptance items: [30 checks in English](docs/checks-alpha19.md) / [30 проверок на русском](docs/checks-alpha19.ru.md). Phases 16–20 were not implemented.

## Alpha.20 — 2026-10-21

The native plugin compiles successfully; QC compiles with zero warnings. The pinned engine and its ten patches are unchanged. Tests run in disposable installations without modifying game files.

Focused regressions pass: point and brush-entity Delete/Undo through native key routing (5 assertions), 32-sided cone apex reconstruction/commit/Undo and side-view/Alt gestures (8 assertions), single-click folder navigation with Unicode Open/Save As, and submodel visibility with surface-grid spacing/visibility and edge-toggle image comparisons. Actual engine screenshots were inspected for point-entity boxes/labels, group surfaces, grid/edges and the large-map scene. Render-mode and fog comparisons retain an unchanged MAP.

Regression passes: geometry (26), Vertex (29), primitives (16), CSG (13), filters (19), views/Clip (27), grid (37), entities (28), action catalogue/routing (325), file-browser full object round-trip and submodels (10 plus image checks). View/grid test readers now inspect actual axis-aligned planes instead of treating arbitrary plane point bases as brush corners. The private large map retains 2394 brushes and 2 patches through save/reload/save; maximum plane-distance drift is 0.000622 units and its original hash is unchanged.

At 1280x800 on an RTX 4060 Laptop, the same fixed large-map view measured 26.4 FPS in alpha.19 and 52.0 FPS in alpha.20 with visible surface grid and white edges. No retail texture library was mounted for this comparison. This is a local scene measurement, not a universal speed guarantee or a benchmark against TrenchBroom. Use `scripts/benchmark-map-windows.ps1` to repeat the measurement in a disposable copy. User maps and assets are not included in the release.

Final regression logs contain no repeated VM errors, modulo-by-zero or edit queue overflow. The engine may still report its optional missing server addon once when loading an editor map. MAP-line diagnostics now require explicit debug mode. Manual acceptance: [English](docs/checks-alpha20.md) / [Русский](docs/checks-alpha20.ru.md).
