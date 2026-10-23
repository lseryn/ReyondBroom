# FTEBroom alpha.32 — terrain, compilation and file navigation

[Русский](alpha32.ru.md)

## Terrain on the current map

In **When the sky went dark**, choose **Edit → Create terrain…**, or right-click the scene and choose **Create terrain here…**. Set the origin and material, then press **Add terrain**. The editor adds a two-by-two section area aligned to section boundaries; existing nonempty terrain sections and MAP objects are retained. The Terrain panel appears for terrain editing.

Each completed terrain stroke is one shared Undo/Redo transaction. Creation is undoable too. Heights, painted materials, holes and section data are captured before and after edits. Saving finishes an active stroke and writes the section files alongside the map. Keep the MAP and its terrain section directory together when moving the project. Save As copies section resources to the new destination.

Native terrain remains an FTE heightfield, not a Quake 3 patch or brush mesh. Q3Map2 does not compile it into a Q3 BSP; the existing build restriction for terrain documents remains. This release does not add terrain-to-BSP conversion.

## Compilation fixes

**Quake 1 external WADs:** the ordinary background Build queue now stages loaded WADs through the same path as explicit export. Byte-identical copies are stored in `_ftebroom-build/<job>/_ftebroom-wads/wad-N.wad`. The compiler receives ASCII relative WAD filenames, rather than the original Unicode desktop path. There is no need to modify the source WAD or copy it manually into the mod. Copying a WAD next to a MAP alone is insufficient: it must be loaded in Material → Add WAD(s), or by dropping it into the editor.

This fixes an alpha.31 gap: its export test passed, but the ordinary background Build path still used the original WAD list. The new regression drives that actual queue and checks embedded BSP texture pixels against the source WAD.

**Quake 3 patches:** compile export now accounts for the opposite front-face convention of native FTE MAP patches and Q3 BSP patches. The reported hotel02 patches were present in the BSP but faced the wrong way. The correction changes only compile export; editable control points and UV pairs remain intact.

**Material thumbnails:** the browser uses a separate clipped 2D preview shader and the material's editor image (or first image stage). World vertex deformation cannot displace a thumbnail outside its cell. World/BSP shader animation is unaffected; browser thumbnails intentionally show a static preview image.

## Mod file manager

Open **Workspace → Mod file manager**. Toggle **Thumbnail view** and adjust **Thumbnail size**. Folders and files have distinct icons; click a folder to enter it. Right-click an item for **Copy**, **Cut**, **Paste**, **Rename…**, or **Open containing directory**. Paste targets the currently displayed directory. A background right-click also offers Paste. Copies use a unique filename on collisions; moves and renames reject existing destinations. Operations remain confined to the mod root.

Drag an MDL, MD3, MD2 or IQM file from this panel into the scene to create a `func_model` with its mod-relative model path. Dropping onto another manager folder moves the file instead. Game code must support `func_model`; referenced skins must be available in the mod. External file drops still copy their source files.

## Menus and new maps

**Preferences…** is now in **Edit**. Terrain creation has moved from Workspace to Edit and the scene context menu.

**File → New** first asks for the game profile and destination in a file browser. It proposes that profile's authoring `maps` directory, lets you navigate/change the name, and creates a MAP with profile metadata. Quake 1 and When the sky went dark use `info_player_start`; Quake 3 uses `info_player_deathmatch`. Existing filenames are never silently replaced. Cancel leaves the current document intact.

## Verification

Automated checks cover real background WAD compilation with byte-exact embedded pixels, hotel02 patch control points/front-face orientation, terrain creation/stroke Undo/Redo/save/reopen with existing brush/patch/entity preservation, repeated terrain metadata saves, manager file copy/move, the new-map dialog, and standard gesture regressions. A separate hotel02 MAP round-trip retains 2,394 brushes and two patches. Original user MAP/WAD files are only read; test outputs use temporary installations.

## Manual checklist

Use a copy of a map and a disposable mod directory for file operations.

1. Add terrain to a populated When the sky went dark map from Edit and from right-click. Check cursor placement, existing objects, the Terrain panel and adding terrain next to existing terrain.
2. Raise/lower, smooth, flatten, paint and cut holes. Undo/Redo each stroke, then alternate a brush edit and terrain stroke and check their order. Undo terrain creation. Save, reopen and Save As to another folder; confirm terrain and ordinary objects survive.
3. Open hotel02, Build, and inspect both curved surfaces from their intended front side in BSP preview; switch back and inspect their materials/control points.
4. Load concrete_sh.wad from a Unicode desktop path (also try a copy beside the MAP), paint a Quake 1 brush, press ordinary Build and inspect its BSP texture. Confirm the source WAD is unchanged.
5. Browse materials with vertex deformation, scrolling and animation. Resize/scroll the browser; thumbnails must stay in their own cells, while scene effects remain live.
6. Switch file manager list/thumbnail modes, resize icons, navigate folders and use Copy/Cut/Paste/Rename. Try a conflicting name. Drag a model into the scene and Undo/Redo the entity. Drag a file into another manager folder, and copy an external file in.
7. Open Preferences from Edit. Use File → New for all three profiles; change folders, cancel, create, save and reopen. Confirm the profile, player-start class and subsequent Open/Save folder.
