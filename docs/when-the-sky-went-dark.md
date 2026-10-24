# FTE Custom game

The paths below are examples, not defaults. Build opens BSP by default; embedded mod preview is an explicit Windows-only action. See [current manual](manual.md).

Select this profile in **Game / resources**, available from **Build…** or Preferences. Click **Load resources and start**. Settings persist across launches.

- Authoring library: `C:/Games/fteqw/baseq3`; original MAP files stay where you save them.
- Runtime mod: `C:/Games/fteqw/id1`.
- Embedded preview engine: the FTE executable bundled with FTEBroom. It includes the viewport/camera bridge; the old external-engine setting is retained for settings compatibility but is not used by embedded preview.
- Format/compiler: Quake 3 BSP / q3map2. Quake game logic is independent of the BSP format.
- Entity definitions: choose DEF/FGD, or a QuakeC source folder. The importer reads local QUAKED comments and caches definitions; it does not publish your mod sources. Comments can be incomplete or stale and do not prove a class exists in the installed progs.dat.

## Build and embedded preview

Choose Geometry/BSP, VIS and LIGHT stages as usual. q3map2 searches the runtime mod first and the authoring library second. Preview uses only the installed mod: archives, shaders, GLSL, configuration, progs.dat and csprogs.dat. It does not mount baseq3 as a fallback.

Enable **Open mod preview after Build**, or click **Preview mod** after a successful build. The real mod runs in the editor's 3D viewport. **Show BSP** remains the lightweight viewer without mod execution.

- Hold RMB and move the mouse to look around.
- WASD flies horizontally relative to the camera; Q/X moves up/down. Shift increases speed. The wheel moves the camera using the normal editor navigation settings.
- The camera starts at the editor's position and passes through walls. It does not teleport or control the player.
- In Free camera, **Back to editing** or Escape stops the preview process and restores the editor camera and viewport layout. Editing controls are disabled during preview.
- Resize the editor or docked panels: the runtime viewport follows the available scene rectangle. A bottom strip remains available for preview status and exit. Overlapping editor dialogs temporarily hide the native render child.

Switch between **Free camera** and **Play mod** in the viewport status panel without restarting the map. In Play mod, click inside the scene to capture the mouse and keyboard. Movement, jumping, attacks and interactions use the mod's bindings and real player physics. **Escape releases input** so you can use editor panels; **Back to editing** stops the mod. Switching modes or losing focus releases held inputs. A captured game Escape is reserved for releasing input.

The game simulation keeps running: real spawn functions, models, floor placement, animations and delayed behavior come from the mod. The player remains at its spawn and can still be affected by the game. Server visibility follows the free camera without disabling visibility culling for the entire map. In Play mod it follows the player normally.

The runtime is isolated in another process with a native child render window, avoiding CPU framebuffer copies. The hidden editable MAP scene is not redrawn while preview is active. Selection and Undo history remain in the editor process.

Generated BSP/lightmaps are staged under `_ftebroom-build.../mod-preview/home`, with an alias for the original map basename. The original MAP and installed BSP are not overwritten. FTE uses a temporary home and `-readonly`; preview saves are unavailable. This is filesystem write protection, not a sandbox for untrusted game code/native plugins.

## Boundaries

Embedded preview currently supports Windows/OpenGL. It uses the bundled engine, which can differ from your normal game executable. Normal mod configuration is loaded, but identical appearance requires matching engine/render settings. The free-camera override affects the rendered world and shader eye position, not the mod's player state: CSQC effects explicitly calculated around the player may remain player-relative. The mod's own HUD/effects may still be visible. There is no pause/time slider, automatic asset packaging or installation into id1.

## Check alpha.27

1. Build a copy of a map with info_player_start, a known mod item and a brush entity. Confirm the mod appears inside the editor and no independent gameplay window remains.
2. Fly with RMB/WASD/Q/X/Shift, including through walls and into another room. Check models, floor placement, GLSL wall/skin effects and animated shaders.
3. Resize/maximize the editor and adjust docked panels. Confirm the image stays inside the viewport and the exit button remains accessible.
4. Return using the button and Escape on separate launches. Confirm the original camera, layout, selection, unsaved edits and Undo/Redo survive. Repeat Build/Preview twice.
5. Disable automatic preview and test Preview mod manually. Check Show BSP → Preview mod → editing.
6. Use a baseq3-only material: strict runtime preview should reveal the missing mod asset instead of silently mounting baseq3.
7. Close the editor while preview is running; confirm its child process closes. Try a missing progs.dat and check the readable error. Original MAP, installed BSP and mod files must remain unchanged.

Automated checks cover the engine camera gate/PVS/FOV/invalid inputs, embedded HWND ownership, acknowledged camera transport, actual render-camera movement, stop/restore, document preservation, MAP round-trip and editing gestures. Visual parity on your complete maps still needs the checks above.

## Alpha.27 fixes and additional checks

- Child window attachment and resize are performed by the runtime's own thread. Unchanged rectangles/cameras are no longer sent every frame; one acknowledged command batch is allowed in flight.
- MAP grid, contours and custom faces reuse cached vertex/index arrays. Grid density is calculated in the shader; camera motion no longer frees and rebuilds regional geometry.
- Test the same large map while stationary, flying, crossing room boundaries and changing grid size. Verify contours remain depth-tested, grid line width stays stable, and moving/hiding/deleting geometry plus Undo refreshes overlays.
- In Play mod, test movement, mouse look, jumping, firing and interactions; release Escape, switch to Free camera and back, then exit. Alt-Tab while holding a movement key and confirm no stuck movement on return.
- Resize/dock panels, cover the viewport with a dialog and repeat preview entry/exit. If a crash recurs, retain the Windows error details and describe the last action.

A local 1280x800 test on a disposable copy of the reported 3,492-brush map reduced the measured editor-frame section from about 14.8 to 8.0 ms. Overall FPS also depends on resource loading, GPU settings, foreground state and mod simulation; this is not a guarantee of a fixed frame rate.
