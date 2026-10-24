# FTEBroom alpha.35 — MAP viewport performance

## Changes

- The Mod file manager validates tree entries when creating its directory snapshot instead of resolving every path on every frame. Refresh, navigation and file changes invalidate the snapshot; file operations still validate live paths. Expanding a newly opened folder validates it again.
- The ImGui renderer clips triangles using bounded stack storage, with fast rejection and containment tests. It no longer allocates several temporary vectors per triangle. UVs, colors, clipping, winding and antialiasing are preserved.
- MAP rendering skips the complete cached face range of a brush already rejected by the existing visibility tests. Visibility rules and rendered geometry are unchanged.

No texture, model, patch, grid or icon quality reduction is used. Selection guides and their collision dots remain enabled. Original user maps and mod assets are not modified by the tests.

## Verification

The clipping regression compares 100,000 randomized, degenerate and boundary triangles against alpha.34, including every submitted coordinate, UV and color. Large textured model thumbnails, animation, PAK editing, selection overlays and movement/Undo/Redo are exercised in disposable installations.

The performance script uses identical clean alpha.34 settings and resource paths for both runs, replacing only the native plugin and editor bytecode in the second run. Resource loading is excluded from the measured interval. Run the benchmarks without other rendering or build jobs active.

## hotel02 measurement

At 1280 × 800 with the baseq3 library and Mod file manager open, comparable stationary-camera captures measured **28.4 FPS on alpha.34 and 42.1 FPS on alpha.35** (about 48% faster). A 725 × 285 viewport crop was pixel-identical. These are samples, not a guaranteed minimum during flight. Runs with blank captures or changed window sizes were excluded; the benchmark now rejects those captures explicitly.

The real hotel02 round-trip preserved 2,394 brushes, two patches and entity/face contents; maximum plane rounding drift was 0.000533 units. The source MAP hash stayed unchanged.

## What to test

1. Open `hotel02.map` and fly through the same locations that previously slowed down. Compare with alpha.34 using the same window size, views and panels.
2. Keep the Mod file manager open; expand folders and PAKs, scroll tiles, navigate Up and Refresh. Check that newly imported/renamed files appear.
3. Select and move brushes, including groups and transparent materials. Check outlines, grid, selection guide collision dots and Undo/Redo.
4. Switch between perspective and 2D views; rotate the camera near walls and check that no visible faces disappear.
5. Open the model viewer, play animations and scroll model thumbnails. Check UI text, clipping at panel edges and popup borders.
