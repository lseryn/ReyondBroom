# Quake 1 resources, PAK documents and model thumbnails

[Русский](alpha29.ru.md)

In **Game / resources → Quake 1**, brush materials come exclusively from WAD2 mip textures. The editor's grey and utility materials are in `quake1-editor.wad`; the Quake starter uses `fb_grey` and `info_player_start`. New empty Quake maps also receive a player start. Quake 3 keeps its own starter and material browser.

WADs are discovered recursively in the authoring and selected mod directories, including WADs inside PAK archives. PAKs are read in sorted order, loose WADs follow them, mod resources follow base resources, and the explicit WAD list has final priority. WADs in an opened map's PAK are included too. The material browser identifies the source archive/member. Palette-decoded images are internal rendering caches, not additional selectable PNG/TGA brush materials. `gfx.wad` console graphics are not level textures.

## LibreQuake

Click **Download LibreQuake mod** beside the Quake game path. The progress bar reports received bytes and extraction. The installer fetches exactly [v0.09-beta/mod_lite.zip](https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/mod_lite.zip), verifies its pinned SHA-256 and rejects unsafe archive paths. Files and upstream license notices stay under the editor's `downloads/librequake-v0.09` directory; an existing game installation is not replaced.

After installation, the button becomes **Use LibreQuake mod**. Check it and click **Load resources and start**. A separate mod path is unnecessary; if the authoring path is blank, the downloaded data is used for that too. The checkbox persists across restarts. Uncheck it to return to the manually configured game/mod.

Quake uses its own definitions by default. LibreQuake uses definitions extracted from the pinned v0.09-beta QuakeC sources (96 unique classes). A custom definition path remains an explicit override. Quake 3 definitions saved in a map no longer override the Quake 1 profile defaults.

The Mod Lite package contains runtime PAKs, not level-source MAP/WAD libraries. To edit with additional LibreQuake level textures, obtain WADs from the upstream [Dev distribution](https://github.com/lavenderdotpet/LibreQuake/releases/tag/v0.09-beta). The editor does not silently download a second package or extract textures from compiled BSPs.

## PAK maps

In File/Open or Save As, click a **[PAK]** row to enter the archive, then navigate its folders. **Up** leaves an internal folder or returns from the archive to its disk directory. Open and save `.map` members, or save a new `.map` into an existing archive. A compiled `.bsp` is not an editable MAP source.

Saving stages a complete replacement archive, copies every unrelated entry byte-for-byte, keeps a timestamped `.ftebroom-*.bak` alongside the PAK, then atomically replaces the original. Each save creates a backup, so allow disk space for the archive and its copies. Malformed archives, duplicate member names, traversal paths and failed writes are rejected. Build snapshots are placed beside the physical PAK, not inside it; source MAPs remain in the archive.

## Entity thumbnails

The entity browser displays textured Quake MDL geometry from the selected mod's mounted resources, including PAK files. Models are resolved from definitions; standard Quake class hints are also available for LibreQuake. Only visible tiles load previews, and meshes/skins are cached until resources or definitions change. Thumbnail size, class replacement and drag/drop continue to work.

Thumbnails show the first model pose, not running game animation. Classes without a model, missing files, brush entities and unsupported model formats retain their coloured bounds icon. A `progs.dat` is not executed to guess arbitrary custom class/model associations; provide those in the mod's entity definitions.

## Check

1. Quake starter: `info_player_start`, grey WAD material, no Quake 3 materials/classes.
2. Download progress, interrupted/error retry, completed checkbox, restart persistence and launch with the mod path blank.
3. Loose and packed WADs, duplicate-name precedence, applying textures and compiling.
4. Enter a PAK, open/edit/save a MAP, reopen it, Save As another member and use Up. Check the backup and unrelated archive entries.
5. Build a PAK map, preview BSP, play LibreQuake, return to editing and save again.
6. Entity thumbnails from your own mod, resizing, filtering, class replacement and drag/drop. Reload after changing the selected mod and verify its skins/models are used.
7. Quake III Arena and When the sky went dark: normal resources, entities, builds and previews.
