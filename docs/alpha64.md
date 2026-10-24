# Alpha 64 — editing, UV precision and mod controls

## Changes

- UV dragging follows the pointer, including rotated, mirrored and nonuniformly scaled textures. Edge snapping uses an eight-logical-pixel radius, adjusted for zoom and interface scale. Close zoom allows fractional texel steps; Ctrl bypasses snapping. See [UV guide](uv-dragging.md).
- Escape in embedded mod preview opens an ImGui controls menu. Rebind movement, attack, jump, weapon cycling and swimming; adjust sensitivity and invert Y. Apply saves `mod-controls.txt` in the editor configuration directory. Continue resumes the view; Back to editing stops the preview. The simulation continues while the menu is open. Mod files are not edited.
- Brush idle picking and Scale/Shear capture are cached. Sweep and Assemble avoid rebuilding unchanged previews; vertex preview skips unchanged deltas. Bezier control-point motion updates without the previous throttle.
- Face, Rotate, Scale and Shear can select a brush directly while active, with transform handles taking priority. Face uses cached polygons for face picking. Spin has axis rotation rings. Grid rotation pivot has a ground guide and responds to arrow-key nudges.
- Tools and Tool options share the top dock. Build, Setup build, BSP and mod controls are in the top toolbar. File manager starts collapsed; Show files / Hide files toggles it. Map Groups, Layers and View options start collapsed. Saved custom layouts/settings are preserved: use Reset panel layout to obtain the new layout.
- Numpad digits select grid sizes; numpad +/- changes grid size. View options include surface-grid smoothing, MSAA and texture filtering controls. MSAA requires the provided Apply/restart action; driver support determines available levels.
- Class names and object bounds default on. Container bounds use depth testing, labels are raised above the object and occlusion-tested. Shift face hover is drawn after the selected-brush pass. Quake player model fallback is restored after definition reloads.
- BSP preview requests black clear color outside the world and restores the previous setting on return. RMB context menus are suppressed immediately after focus restoration. Closing the editor can terminate its mod preview. The parent editor is capped at 60 FPS during embedded preview to reduce competition with the child renderer; its previous limit is restored afterward.
- Run profiles retain ordered Export, Run, Copy, Rename and Delete tasks, variables, working directories, streamed logs and Stop. Individual stages can be disabled. New presets cover Q3 fast VIS/light, Q3 final light, and Q1 BSP/VIS/light. Build and Run logs have Copy log buttons.
- Sculpt reports when no vertices fall inside its radius. Brush Sculpt is available in Quake 1; a flat large brush without nearby vertices is not a tessellated terrain surface.

## Scope and limitations

Embedded mod preview (and its Escape menu) remains Windows-only; Linux still uses the existing external mod launch. No new game pause behavior is introduced. This release retains alpha 63's growing model registry fix for `MAX_MOD_KNOWN`; the supplied old crash log does not identify a separate new crash cause.

Performance work removes identified repeated calculations. It is not a promise of a particular FPS on every map. The broad rendering fixes still need visual checks on the user's shaders, transparency and mod. Existing saved preferences override new defaults.

## Check after updating

1. UV: drag in all directions; rotate/scale/mirror the texture and repeat. Zoom close, adjust by a fraction of a texel with Ctrl, approach a texture border without Ctrl, then Undo/Redo and Escape.
2. Mod preview (Windows): Escape opens controls in both Free camera and Play mod. Rebind Forward and Attack, apply, continue, test movement, restart and verify persistence. Return to editing and close the editor while preview is active.
3. Open hotel02, navigate, select brushes, activate Brush, Face, Rotate, Scale, Shear and Sweep. Verify responsiveness and ability to select without leaving the tool. Undo/Redo each edit.
4. Bezier: move control points and inspect live geometry; cancel and apply. Spin: use the rotation rings. Grid Rotate: locate/nudge pivot, rotate and reset.
5. Q1 Sculpt: use subdivided brush terrain, select it, set a radius that includes vertices, Raise/Lower/Smooth, then Undo/Redo. Patches remain unavailable in Q1.
6. Build a small sealed Q1 map and a Q3 map, inspect the BSP, return to MAP. In Run profiles disable a stage, copy the log, test Stop and confirm failed tools stop subsequent stages.
7. Inspect distant brush edges and textures with the View options AA/filter settings. Check Shift yellow face hover, player model, labels and bounds behind solid brushes. Fly outside a BSP and inspect its background.
8. Reset panel layout if desired. Check horizontal Tools/options, top build controls, collapsed files and Map foldouts. Test numpad and RMB after switching applications.

Automated results and remaining manual coverage are recorded in the release description. Original input maps and mod files are preserved by disposable-installation tests.

## Automated coverage

Windows: UV math/gesture and MAP persistence; Scale/Shear, Vertex, Sweep, Bend, Spin, Assemble; ordered run tasks including failure/Stop; complete BSP build, LIGHT-only and return to editing. hotel02 MAP round-trip preserved 2,394 brushes and two patches (maximum plane-coordinate drift 0.000533). Arch Linux under Xvfb: UV math/gesture/MAP checks and Rock/Sculpt/Array regressions. Embedded Windows preview checks confirmed child camera acknowledgement, Play input, Escape menu, free camera and restored editor camera. This is not a Wayland desktop interaction test.
