# FTEBroom alpha.31 — resources, terrain and diagnostics

[Русский](alpha31.ru.md)

## External WADs and images

In the Quake 1 profile, drop a WAD anywhere in the editor, or use **Material → Add WAD(s)**. Build now refreshes the WAD list and stages byte-identical copies under `_ftebroom-build/<job>/_ftebroom-wads`, using ASCII relative filenames. External paths containing Cyrillic characters therefore do not enter the compiler's WAD search list. The source WAD is not modified. Later WADs retain priority for duplicate texture names.

Drop PNG, JPG/JPEG, BMP, GIF, TIFF or TGA files into the Material browser. A persistent **Import image into WAD** window asks for a destination. Choose a loaded loose WAD or **Choose / create WAD…**, check the texture name and press **Import**. Each queued image is imported individually. Images are resized to power-of-two dimensions between 16 and 512, quantized to the mounted Quake palette, and saved with four mip levels. Alpha is composited over black; fullbright palette entries are avoided. Existing names are not overwritten. A backup is kept when an existing WAD is extended. Packed WADs are read-only import destinations: choose a separate loose WAD.

The supplied 638×480 JPEG/PNG and external `concrete_sh.wad` were tested from a disposable Cyrillic directory. The resulting BSP29 was checked for embedded pixel data for all three imported materials.

## Collections

The Material collections dropdown has a search field and **Remove** buttons. Removal persists per profile/resource root. It removes the collection from the browser, without deleting files, disconnecting textures used by a map, or breaking compilation. **Restore removed collections** brings them back.

## Mod file manager and external models

Open **Workspace → Mod file manager**. Click a folder to enter it; **Up** goes to its parent. Drag a file or folder onto a listed folder to move it within the mod. Use **New file / folder** to create files with initial text or new folders. Existing destinations are never overwritten. **Refresh** reloads external changes. Right-click the window to open the displayed directory in the operating system's file manager.

External file drops into this panel copy regular files into the displayed directory. Filename collisions receive numeric suffixes. The original file remains in place. Operations cannot escape the configured mod root through `..` or symbolic links. PAK/PK3 files are displayed as archive files; this manager does not rewrite their internal contents.

MDL, MD3, MD2 and IQM files dropped elsewhere are copied to `models/imported` inside the active mod. A scene drop also creates a `func_model` at the drop position, using a relative model path; Undo removes the entity and Redo restores it. Drops outside the scene only copy the model. Files intentionally remain after Undo. External textures/skins referenced by a model must also be present under the paths expected by that model; use the file manager to copy them. Your game code must support `func_model` to use it at runtime.

## Map profiles

Saved MAP files include one header comment, for example:

```text
// FTEBroom profile=quake1 format=valve220
// FTEBroom profile=quake1 format=quake-standard
// FTEBroom profile=quake3 format=quake3
// FTEBroom profile=when-the-sky-went-dark format=quake3
```

On open, recognized metadata selects the profile before assets and entity definitions are loaded. Local resource paths remain in local settings. Unmarked maps keep the existing compatibility behavior; unknown identifiers are not executed or treated as configuration. This applies to ordinary saves, backups and packed MAP saves. Compiler exports remain plain compiler inputs.

Future profile implementations must extend this allowlist and test save/open round trips. Geometry format alone is not a game-profile identifier.

## Native FTE terrain

Choose **When the sky went dark**, then **Workspace → Create terrain…**. Enter a new map name, ground texture and starting height. The initial area is 2048×2048 units. A **Terrain** inspector tab appears for terrain documents; ordinary maps do not show it.

Enable **Sculpt / paint terrain**, choose Raise, Lower, Set height, Smooth, Spread, Flatten, material blending/painting, layer operations, Water height or Hole, then drag in the perspective viewport. Radius, amount/height, strength and square/circular brush shape are adjustable. **Use selected material** picks the Material browser's current material. Disable sculpting to edit brushes and entities normally.

**Save terrain and map** saves both the MAP and the sibling directory containing FTE `.hms` section files. Keep these together when moving the map. Opening and Save As copy these sections between the editing cache and the document directory. The header uses `format=fte-terrain`.

This is native csaddon/FTE heightfield terrain, not a tessellated Quake 3 patch or a Q3 BSP export. BSP Build is unavailable for terrain documents. Terrain strokes use csaddon's direct editing and currently do not participate in brush Undo; brush/entity editing retains its normal history. Native FTE section files can be substantially larger than a brush MAP.

## Sound preview

Select an entity and expand **Entity → Properties → Sound preview**. **Play sound** uses its `noise`, `sound`, `soundfile` or `noise1` property, or the known Quake ambient-class sound. Set the preview volume and use **Stop sound** to stop playback. For custom game logic, enter a relative sound path in the override field. Arbitrary sound choices made by `progs.dat` cannot be inferred automatically. Playback uses mounted resources and does not change entity properties.

## Crash diagnostics and performance

Windows fatal exceptions and engine fatal errors write `<map-name>_crash.txt` beside the map. Reports include the exception/reason, map/profile/revision context, recent editor commands, console tail and available native stack/module information. If the map directory is unwritable, the fallback is `ftebroom/diagnostics`. Unsaved maps use `untitled_crash.txt`. This does not edit the MAP. Power loss and forced process termination cannot guarantee a crash report.

2D contours now cache the original face loops and submit their edges in batches, invalidating after geometry changes. Off-screen brush bounds are also checked before individual custom 3D faces. No detail, line styling or texture quality was reduced. On the test copy of `basement01_backup.map`, the fixed 2D scene improved from about 37.5 to 60 FPS, and contour preparation from 17.3 to 8.5 ms/frame. The viewport screenshots matched pixel-for-pixel. Results depend on the map, view and hardware.

## What to test

1. Drop an external WAD from a Cyrillic path, apply its material, Build a Quake 1 map and inspect the BSP texture.
2. Drop multiple JPEG/PNG images into Material, choose/create a WAD, import each, apply them, restart and Build. Check the conversion and duplicate-name behavior.
3. Search, remove and restore collections; restart and verify removed collections remain absent while existing map textures still work.
4. In a disposable mod folder, create folders/files, drag files between folders, copy external files, repeat a same-name drop and open the directory in Explorer.
5. Drop a model onto the scene, check `func_model`, relative model path and placement; Undo/Redo. Drop outside the scene and confirm only the file is copied.
6. Save/reopen maps for Quake 1 standard, Valve 220, Quake 3 and When the sky went dark. Check automatic profile selection and retained resource settings.
7. Create native terrain, sculpt and paint, disable sculpting and add a brush/entity, Save As, close/reopen and confirm the terrain and its sections survive. Keep a backup before destructive strokes.
8. Select a sound entity, play/stop its sound, adjust volume and try a custom relative sound path.
9. Navigate the large map in 2D/3D, then edit geometry and Undo/Redo. Check that cached contours update and hidden/locked/group objects behave normally.
10. If an actual crash occurs, send the generated `_crash.txt`. Do not deliberately crash a session containing unsaved work.
