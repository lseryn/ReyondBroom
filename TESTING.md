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
