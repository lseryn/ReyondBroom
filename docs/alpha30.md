# Desktop integration, themes and textured model previews

## Appearance and cursors

Choose **View → Interface theme → Modern Dark** or **Windows 95 / 98**. The latter uses grey panels, white recessed fields, square raised buttons and navy title bars. Theme, UI scale and layout are saved separately from map data. Switching themes does not reset the workspace. Unlock panels before resizing them. Resize handles and splitters show horizontal, vertical or diagonal Windows cursors. Text fields show an I-beam.

The ImGui renderer now normalizes clipped triangle winding, including antialias geometry. This prevents missing fragments around button/field borders. Classic bevels use pixel-aligned strips instead of overlapping antialiased lines.

## External WADs and image import (Quake 1)

In the **Material** inspector, click **Add WAD(s)...** and select one or several WAD2 files. Alternatively, drop WAD files from Windows Explorer onto the editor. These external paths join the saved Quake 1 WAD list and appear in the material browser after reload. Existing automatic loose/PAK WAD discovery remains available. The Q3 profiles continue using their normal shader/image resources.

Drop one or more images onto the **Material / texture browser panel**. For each image, the import dialog asks for a texture name and destination WAD. **Choose / create WAD...** opens a file picker; select an existing loose WAD or enter a new filename, then click **Import**. Imported textures appear in the browser and can be applied normally.

- Input: PNG, JPEG, BMP, GIF, TIFF and true-colour TGA (including RLE). Animated/multipage formats use the first frame.
- Dimensions are rounded up to powers of two, with each axis limited to 16–512 pixels. This may change the aspect ratio; prepare the image beforehand if exact proportions matter.
- Colors use the currently loaded Quake palette, excluding fullbright indices 224–255. Alpha is composited over black. Four mip levels are written.
- Texture names have at most 15 ASCII letters/digits/underscores/dashes. Duplicate names, including case variants, are rejected rather than overwritten.
- Existing WAD entries are preserved. Before replacing an existing WAD, the editor creates an adjacent timestamped `.ftebroom-*.bak` backup. Allow space for it.
- Import writes to **loose WAD2 files**. WADs inside PAK archives can still be read, but are not image-import destinations. Choose a loose WAD instead.
- Explorer and the editor should run with the same privileges; Windows blocks ordinary Explorer drops into an elevated application.

## Textured entity models

The entity browser supports Quake MDL and multi-surface MD3 from mounted game/mod resources, including PAK/PK3 archives. Quake 3 and **When the sky went dark** can display MD3 models; the latter mounts the selected runtime mod for resource previews. MDL embedded palette skins are uploaded directly, fixing blank previews. External MDL replacement skins and MD3 shader image references / explicit `.skin` mappings are supported.

Each class still needs a model association in its entity definitions (or a bundled class hint). A `progs.dat` is not executed to discover arbitrary custom associations. Thumbnails show the first pose, not animation. Missing models, unresolved shader images, unsupported formats and brush entities retain a bounds icon. Shader thumbnails use their preview image, not the full animated multipass runtime effect.

## Movement

The original brush is hidden for the entire active move preview. The visible brush follows the drag immediately; releasing commits one transaction, Escape restores the source, and Undo/Redo retain their previous behavior. Duplicating intentionally keeps the original.

## Updates

From alpha.30 onward, startup checks this repository's published releases, including newer alpha builds. A newer complete Windows package downloads in the background. **Help → Updates** shows status and offers **Check for updates**. The ZIP is checked against the release SHA-256 before extraction.

Installation waits until the editor exits normally. There is no forced restart or interruption of an unsaved editing session. Launch normally afterwards. Appearance, workspace, profile paths and user documents are retained. Modified bundled CFG/WAD/definition files are protected by the installed distribution manifest. Old files and staging data stay in `updates/` for rollback/diagnosis; the updater rolls back copied files if installation fails. Network failures leave the existing version usable and appear in update status.

Install alpha.30 manually first: older releases do not contain this updater. The editor directory must be writable. The updater never installs into an external game/mod directory.

## Acceptance checklist

1. Switch both themes; resize/dock/undock panels and restart. Confirm theme, font scale and layout persist. Inspect buttons, text fields, tabs and popup corners at 100%, 125% and 200% UI scale.
2. Hover window edges/corners and viewport/panel dividers; verify resize cursors and normal cursor restoration. Type in a field; ensure camera controls still work in the viewport.
3. Quake 1: add two WADs at once; drop another from Explorer; search/apply their textures and restart. Check loose and packed existing resources still load.
4. Drop PNG/JPEG/TGA images onto Material. Choose an existing WAD and a new WAD; verify names, dimensions, colors and application to a brush. Check backup creation and preservation of previous textures. Try duplicate names and cancel a dialog.
5. Open the entity browser in Quake 1/LibreQuake, Quake 3 and When the sky went dark. Check model skins, MD3 surfaces, filtering, thumbnail size and definition-based model paths; reload resources after changing the mod.
6. Move a brush in perspective and 2D: no source ghost while holding the mouse. Check Alt vertical movement, Escape, Undo/Redo, multiple selection and duplication.
7. Help → Updates should report current version / connection error appropriately. When a newer release exists, let it download, save work and close; reopen and verify version, theme, layout, profile paths, WAD list and maps. Do not downgrade your working installation solely to test this.
8. Regression: open/save a map, compile, switch MAP/BSP, and enter/leave mod preview for your usual profiles.
