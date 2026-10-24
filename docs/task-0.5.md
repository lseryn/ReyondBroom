# Grid and snapping — 0.5.0-alpha.5

The grid now supports **0.125, 0.25, 0.5, 1, 2, 4, 8, 16, 32, 64, 128 and 256** map units. Set it in the toolbar, the Grid inspector or **View → Grid**. Grid size is separate from visibility and snapping.

| Input | Action |
|---|---|
| 1–9 over the scene | Set 1–256 |
| +, =, keypad + | Increase, up to 256 |
| −, keypad − | Decrease, down to 0.125 |
| 0 | Toggle visibility |
| Alt+0 | Toggle snapping |
| Ctrl+Alt+wheel | Down increases spacing; up decreases it |
| Plain wheel, legacy preference enabled | Up increases spacing; down decreases it |

For compatibility, plain-wheel grid control remains enabled by default. Disable **File → Preferences → Plain wheel changes grid (legacy)** to require Ctrl+Alt. **Invert grid wheel** reverses the chosen wheel direction. Scrolling over panels scrolls the UI; text fields and modal dialogs protect their input.

In the Grid inspector, **Snap to grid** controls creation anchors, movement deltas and Clip points. Disabling it permits fractional mouse movement without changing the configured grid or one-cell default brush height. **Show grid** controls both surface overlays and the construction plane; **Grid opacity** ranges from 0 to 1. Existing material textures, including the sample grid texture, are not altered by hiding the overlay.

Surface lines use a coarser power-of-two visual spacing when their projected separation at the face centre would be below four pixels. This is a readability measure; actual snapping still uses the selected grid. The construction-plane display uses the same density helper. The full orthographic background grid with major lines belongs to roadmap task 1.2.

**Plane Z** remains an FTEBroom option: it chooses the XY construction plane when a creation or Clip ray misses geometry. Starting a brush on a surface uses that surface's height. Clip points on inclined brush faces snap their two dominant coordinates and solve the third from the face plane.

## Implementation and verification

`qc/fb_grid.qc` provides scalar/up/down/vector/delta/angle snapping, plane-constrained snapping and a move-distance helper for future Extrude. The last helper compares the nearest grid distance with distances at which a vertex reaches a grid plane. All helpers bypass rounding when snapping is disabled. The Extrude UI itself is not implemented in this stage.

`ca_grid` remains the compatible size setting; `ftebroom_grid_exp` mirrors its clamped exponent, −3 through 8. Other settings: `ftebroom_grid_snap`, `ftebroom_grid_visible`, `ftebroom_grid_alpha`, `ftebroom_wheel_grid`, `ftebroom_wheel_invert`. Defaults are set in the runtime configuration.

Run `scripts/test-grid-windows.ps1 -Bundle <bundle> -Python <python>`. Its disposable engine test checks numeric hotkeys, both bounds, fractional steps, keypad aliases, wheel policies, text protection, snapping math, an inclined plane within 0.001 units, a 0.125-unit brush, unsnapped mouse movement and byte-identical MAP restoration through Undo. Existing gesture, action, material/Clip, document and history regressions are also required.

Please test:

1. Use 1–9, +/− and the toolbar to change grid size; try 0.125.
2. Toggle Alt+0 and drag a brush. With snapping disabled it should move smoothly.
3. Toggle 0 and adjust opacity. A material's own grid pattern may remain visible.
4. Switch the legacy wheel preference off and use Ctrl+Alt+wheel in the scene.
5. Place Clip points on an inclined face and check that the preview stays on that face.

![Grid controls and snapping disabled](../screenshots/grid.png)
