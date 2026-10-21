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
