# Quake 1 mapping

[Русский](quake1.ru.md)

Select **Quake 1** in **Game / resources**. Quake III Arena and When the sky went dark remain separate profiles. Changing a profile does not convert the current document: use **File → New** to begin a map for a different game.

## Resources

1. Set **Quake id1 / authoring directory** to your `id1` folder. The editor reads loose files and PAK archives, including `gfx/palette.lmp`. Supply your own game data; retail assets are not distributed.
2. Add WAD2 archive paths, one per line. Relative paths resolve against id1. The last archive wins duplicate texture names. The material browser can filter by WAD, search names, and apply materials to selected faces or brushes. A small original `fb_grey` texture is included for new geometry.
3. For a mod, set its runtime directory. A conventional installation has `id1` and the mod folder beside each other. Its files override base resources. Leave the field blank to play Quake from id1.
4. Optionally choose ENT, DEF or FGD entity definitions. The bundled Quake definitions cover 99 classes with descriptions, flags, bounds and model hints. A mod's executable `progs.dat` is used during play; it cannot replace editor definitions.
5. Click **Load resources and start**. Settings survive restart. Source archives and game files are mounted read-only; decoded editor previews are cached in the editor directory.

WAD material names retain Quake conventions, including `*water`, `sky...` and `+0...` animation families. The compiled BSP and actual game preview use FTE's Quake materials, lighting and animation. MAP mode displays the source texture for editing. The palette is refreshed for newly loaded BSPs without restarting the document VM.

## Map formats and tools

New projects default to **Valve 220**, which stores explicit UV axes. Existing standard Quake maps opened through File/Open retain standard output until you choose Valve 220 in Game/resources. Both formats compile to Quake BSP; Valve 220 is a source mapping format, not a different game.

Standard output preserves the effective texture mapping. If a shear or transformation produces UVs that standard MAP cannot express, saving stops before replacing the destination. Select Valve 220 and save again. Offsets, negative scales, non-axial planes, entity properties, groups and layers remain editable.

Brush creation, Clip, CSG, vertex/edge/face editing, Extrude, shapes, groups, layers, UV editing, entity placement and Undo/Redo are shared with the existing editor. Quake 3 patches cannot be created in this profile; saving or compiling a document containing patches is rejected. Q3 surface/content bitfields are hidden and excluded from Quake compiler input. Quake contents are determined by material conventions and entities.

## Build and preview

The Windows package includes **ericw-tools 0.18.1**: QBSP, VIS and LIGHT, with sources and licenses. Paths are selected automatically; each executable can be replaced in **Build…**. The upstream Windows tools require [Microsoft Visual C++ 2013 x64 runtime](https://www.microsoft.com/en-us/download/details.aspx?id=40784); install it if Windows reports missing MSVCR120/MSVCP120. The editor itself does not require that runtime.

- **BSP29** targets classic format limits. **BSP2** supports larger maps on compatible modern engines. FTE preview does not prove compatibility with every original-engine limit or third-party port.
- **Fast preset** uses fast VIS; **Final preset** uses full VIS and `-extra4` lighting. Each stage and its arguments can be changed independently.
- Build runs in the background from a private snapshot under `_ftebroom-build` beside the saved map. WAD paths are supplied to that snapshot. Stage status and log output remain visible in the viewport.
- VIS/LIGHT-only builds require the same document and an unchanged geometry snapshot. A failed build retains the last successful result. After Save As to another file, build Geometry again.
- **Show BSP** displays compiled geometry and lightmaps. **Back to editing** restores the editable document and history.
- **Preview mod** launches the selected Quake game in the viewport. Choose **Free camera** or **Play mod**; click the viewport to capture game input and use Escape to release it. BSP, LIT and LUX files are staged in an isolated preview home. Original `progs.dat`, game configuration and assets are not overwritten.

Use the existing leak-path and portal-file viewers for compiler diagnostics. Additional modern options such as coloured lighting or BSPX must match the intended runtime engine. Test player/monster collision, narrow passages and stairs in play mode: Quake uses collision hulls, unlike Quake 3.

## Acceptance checklist

- Configure id1, two WAD files and optional mod/definitions; restart and verify persistence.
- Filter WADs; assign materials; adjust X/Y scale, rotation and offsets. Check a sloped face and mirrored scale.
- Open a standard MAP, save and reopen it; compare geometry, entities and UVs. Repeat with Valve 220. Verify a nonrepresentable standard-map UV edit requests Valve 220 without replacing the old file.
- Create and edit brushes; Clip/Extrude/CSG, Undo/Redo, grouping, layers, clipboard and save/reopen.
- Place player starts, lights, monsters, items, doors, buttons, triggers and destinations. Check bounds/models, flags, target links and brush-entity visibility.
- Build BSP29 with all stages; inspect lightmaps and brush entities; return and Undo/Redo an edit. Rebuild LIGHT alone without changing the document, then verify that geometry edits require a new BSP stage.
- Build BSP2. Check water/lava/slime, sky, animated textures and fullbright pixels in BSP/game preview with suitable source textures.
- Play the map: movement, stairs, narrow doorways, doors/platforms, pickups, triggers, teleporters and enemies. Verify free-camera/play switching and return to editing.
- Test a leaking room and a missing WAD/compiler. Errors should be visible and the previous good BSP retained.
- Switch back to Quake III Arena: texture/shader browser, patches, q3map2 build and BSP preview. Then test When the sky went dark with its existing baseq3/id1 paths and free-camera/play preview.

Automated checks: `tests/quake1-unit.cpp` and `scripts/test-quake1-windows.ps1`. The integration fixture authors its own WAD and palette, runs actual compiler processes and inspects the result in FTE; it never modifies a user's game installation.
