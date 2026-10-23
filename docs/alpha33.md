# FTEBroom alpha.33 — profiles, material search and model viewer

[Русский](alpha33.ru.md)

## Map profiles

Opening a MAP reads leading TrenchBroom `// Game:` and `// Format:` comments as well as FTEBroom headers. Quake + Standard/Valve selects Quake 1; Quake 3 + Quake3, Quake3 (Legacy), or Quake3 (Valve) selects Quake III Arena. The named When the sky went dark profile is also recognized. An explicit FTEBroom header takes precedence. Unsupported games are not guessed from shared brush syntax; Valve alone does not imply Quake 1. This selects the editor profile, not arbitrary external game configurations.

Choose **Edit → Preferences → Game profile**, select a profile, then **Switch profile**. Save/Don't Save/Cancel protects dirty documents. Switching opens an untitled starter scene and resets document history. Configure resource paths with **Game / resources…**; missing resources still require configuration. Original MAP files are not rewritten merely by opening them.

## Material search and inspector layout

In Material, enable **Advanced search**. Width and height each accept minimum/maximum pixel dimensions. Zero means no limit; matching minimum and maximum means exact size. These constraints combine with name, collection and used-material filters. For shaders the dimensions refer to the browser's editor/preview image. Dimensions are cached and loaded in small batches; results fill in as images are inspected.

The upper property areas in Material and Entity use compact spacing and independent scrolling. Drag the blue horizontal divider above each browser upward to give it more space; drag downward to enlarge properties. Thumbnail size controls remain available. Browser divider heights are currently session-local.

New installations default to **125%** UI/fonts. Existing saved scale preferences remain respected. Dark-theme buttons have a lighter slate background so popup actions are visible; retro styling remains available.

## Model viewer and file icons

Open **Workspace → Mod file manager**. Thumbnail mode shows MDL/MD3 model previews. Double-click MDL, MD3, MD2, IQM or MD5MESH to open **Model viewer** using the engine's model loader. Referenced materials/skins must be present in mounted mod resources. Images and sounds have distinct icons.

Drag the model viewport with the **left mouse button** to orbit; use the wheel to zoom. Select an animation/sequence, scrub its frame slider, or press Play and set frames per second. The current frame and final frame are shown. Skeletal models offer **Show bones** and a bone selector/name; vertex-animated models such as ordinary MDL/MD3 have no skeletal bone hierarchy. Available sequences depend on the model and its associated animation resources; the viewer does not execute game code or animation events.

The model viewport uses independent camera settings and fullbright lighting for material inspection. It does not change map geometry or selection.

## Brush movement

Dragging on the horizontal plane uses the actual grabbed surface depth. Alt-drag projects onto a vertical world-space line. Thus the same screen-space movement moves nearby objects less than distant ones, like a perspective construction plane in TrenchBroom. Grid snapping remains in world units. A depth-scaled screen-space fallback handles nearly top-down views where the vertical line projection is ill-conditioned.

## Test checklist

- Open TrenchBroom Quake Standard/Valve and Quake 3 MAPs: check profile, materials, entity definitions and compiler settings. Unsupported game headers must not force Quake 1. Save/reopen a disposable copy.
- Change profile through Preferences with a dirty map: test Cancel, Don't Save and Save; verify a clean starter scene, correct player entity and empty history after switching.
- Search materials by exact 64×64, width range and height-only range; combine with text and collection filters; turn Advanced search off.
- Drag both browser dividers upward/downward, resize the inspector and scroll the compact properties. Test 125% on a fresh configuration and retention of an existing custom scale.
- Check popup button contrast in dark theme and the existing Windows 95/98 theme.
- Double-click MDL/MD3/IQM models in the mod manager; check textures, orbit, zoom, animation selection, frame scrubbing/playback and skeletal bones. Close the viewer and verify map navigation/selection are unchanged.
- Verify sound/image icons, folder navigation and existing model drag-and-drop.
- Move brushes near/far with the same mouse displacement; test XY, Alt-Z, top-down views, grid snapping, Undo/Redo and cancellation.

## Startup map list

At startup, the welcome window lists successfully opened/saved maps with the last editing profile in muted text. Mark favorites with the checkbox and enable Favorites only to filter. Missing files remain visible but cannot be opened. Open another map and Create new map are below the list. History and favorites are stored alongside editor preferences and survive restarts. History starts accumulating after this update; older sessions cannot be reconstructed reliably.
