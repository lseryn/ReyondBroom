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
