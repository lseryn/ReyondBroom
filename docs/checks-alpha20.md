# Alpha.20 verification checklist

Use a fresh extracted build and a copy of your map. Keep the original unchanged.

1. Open a large map. Compare stationary and moving-camera FPS at the same position, window size and resource settings. Try both one viewport and four viewports. Turn grid/edges off and back on; no geometry should disappear.
2. Open a folder with one click in File → Open. Navigate Up, across drives, and through folders with spaces/non-ASCII names. Select a MAP and open it. Repeat in Save As and Export; verify the chosen destination and reopen the saved map.
3. Select a point entity and press Delete over the scene; Undo/Redo must restore/delete it. Repeat with func_wall, func_door, a group and mixed selections. After clicking inspector properties, move back to the scene and retry. Delete inside a text field must only edit text.
4. Deselect groups/brush entities and inspect them from all sides: exterior surfaces must occlude their interiors. Move, hide/show, undo and reload them. Check transparent clip/trigger materials separately.
5. Place info_player_deathmatch and light in empty space outside a brush. Deselect them: class-colored boxes and names must remain visible. Test Show points, Show models and class filters. With valid baseq3 assets, inspect model-bearing classes as well.
6. Inspect white outlines: far edges must be hidden by opaque brushes. Change grid from 8 to 16 to 32; surface cells must change on both world and grouped brushes. Move geometry and Undo; there must be no old grid left behind. Toggle grid visibility and opacity.
7. Create a cone with 32 sides. Press V, select its apex, and drag upward in XZ/YZ. Repeat in perspective while holding Alt. Undo/Redo, save and reopen. Other vertices should remain stationary and the cone must stay closed.
8. Leave the editor idle, fly around, switch maps and edit repeatedly while checking the console. There should be no repeating VM errors, division/modulo errors or model-load warnings. Report the exact message if another one repeats.

Automated coverage includes native Delete/Undo and file-browser clicks, cone geometry and gestures, submodel visibility, render modes, filters, grid invalidation, geometry/CSG and MAP round-trips. FPS depends on hardware, assets and camera position; a synthetic/private-map result is not a guarantee for every map.
