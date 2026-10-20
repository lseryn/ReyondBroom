# Multiple viewports — 0.5.0-alpha.10

[Русский](task-1.3.ru.md) · [Combined acceptance checklist](checks-1.3.md)

The toolbar Layout selector and File → Preferences → View layout provide one, two, three or four views. Default arrangements are:

| Layout | Arrangement | Space |
| --- | --- | --- |
| 1 | One view | 3D → XY → XZ → YZ → 3D |
| 2 | 3D left, XY right | Right: XY → XZ → YZ |
| 3 | 3D left, XY upper-right, XZ lower-right | Lower-right: XZ ↔ YZ |
| 4 | 3D / XY above XZ / YZ | No change |

After the first scene click, focus follows the pointer. An orange border identifies the focused pane. Keyboard actions target that pane; a drag or captured camera gesture keeps its original pane until release. Ctrl+Space maximizes/restores the focused pane. Divider dragging changes pane sizes without creating brushes. Layout and split ratios persist in `ftebroom/view-layout.cfg`; diagnostic launchers do not write preferences.

Orthographic views share a world-space center and zoom. Pan changes the visible world axes, leaving the hidden coordinate intact; the other views follow their shared axes. Ctrl+Shift+U centers all 2D views on selection, or world origin with no selection, and restores the default 1024-unit span. The 3D camera keeps its separate viewpoint. View settings do not modify MAP geometry or Undo history.

Native code publishes viewport rectangles/types and passes pane identity with pointer commands. CSQC establishes projection before input and renders each visible view separately. The engine patch `viewport-projection.patch` fixes stale project/unproject viewport coordinates before renderscene; regression tests switch rectangles before projecting a world point.

Unchanged 2D scenes are cached in render targets. Geometry/history, selection, center, zoom, rectangle, screen size, grid and bounds changes invalidate the cache. Active brush drags and Clip previews bypass it. A two-second refresh also recovers from renderer resource changes. This cache does not change map content.

Two-point Clip keeps the direction of the view where the first point was placed, so moving focus to another pane cannot change the cut plane. The alpha.9 side-face fix remains included. Alpha.9 has not yet been manually accepted by the user.

Full per-tool view parameters and all modal-tool movement constraints remain roadmap 1.4; Focus on Selection navigation remains 1.5. Patch creation and the unfinished modal tools are not implemented by this viewport stage.

![Four simultaneous views](../screenshots/layouts-four.png)

## Validation and performance

The real-engine suite covers viewport projection before rendering, layouts, cycling, maximize/restore, divider input, focus capture, linked pan, zoom reset and unchanged MAP geometry. Screenshot checks require visible perspective geometry and wireframes in all three cached panes. Existing Clip, gesture, navigation, picking, grid and document round-trips are also exercised.

On the generated 2000-brush scene, this machine (RTX 4060 Laptop GPU) measured about **30 FPS with surface grids**, and **198 FPS with grids hidden**, in the four-pane window. The remaining bottleneck is the existing per-face 3D surface-grid work; 2D render-target caching does not remove it. These are local measurements, not a universal performance guarantee. `tests/benchmark-layouts.cfg` measures eight seconds per case; generate its map with `tests/prepare-manual-fixtures.py --benchmark`.
