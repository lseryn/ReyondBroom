# Orthographic views and two-point Clip — 0.5.0-alpha.9

[Русский](task-1.2.ru.md) · [Complete acceptance checklist](checks-1.2.md)

Two-point Clip in Perspective previously extended its plane along world Z. On a side face this could produce a tangent plane or a zero normal, so neither preview nor a cut appeared. The first picked surface normal now defines the cut's inward direction. Three points still define an arbitrary plane; 2D cuts extend along the view depth. Coincident points and tangent/outside cuts remain invalid.

The new `fb_view.qc` module sets the orthographic projection before picking and gestures, supplies shared view axes, and implements:

- **XY (top):** right X, up Y; **XZ (front):** right X, up Z; **YZ (side):** right Y, up Z.
- RMB/MMB pan using relative capture. Wheel zoom keeps the world point under the pointer fixed. Ctrl+Alt+wheel changes grid. The old plain-wheel grid preference continues to apply in Perspective.
- Background grid with spacing coarsened below four pixels, coloured zero axes, an axis compass, grey brush outlines and red selected outlines.
- Point-entity bounds and class labels. Soft bounds are orange and editable in **Map → Soft map bounds**; they are visual guidance, not clipping planes.
- Creation and movement in the visible plane. A new brush inherits the last selected brush bounds along the hidden axis, even after deselection. Without a prior selection it uses depth 0…grid. Fractional selected depth is preserved.

The 3D XY/Alt-Z workflow remains unchanged. View centres and soft bounds are session settings in this iteration; they are not exported into MAP. Multiple viewports and linked cameras are roadmap 1.3. Patch creation and unfinished modal tools remain outside this stage. Current MAP writing, box-size and world limits are unchanged.

`scripts/test-views-windows.ps1` checks cuts from all six cube faces, actual projected side-face picking and preview, a committed two-half result and complete Undo, all three view orientations, cursor-anchored zoom (<0.5 pixel error), pan, inherited/default/fractional brush depth, and unchanged MAP geometry after navigation and cancelled previews. Existing editing, gesture, camera, picking, grid, document, history, tools and geometry regressions are also run.

![Front view, grid and bounds](../screenshots/views-front.png)
