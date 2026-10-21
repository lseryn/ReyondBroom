# FTEBroom — FTE-native map editor

[**Download Windows x64 · 0.5.0-alpha.17**](https://github.com/reyond9079/FTEBroom/releases/download/v0.5.0-alpha.17/FTEBroom-0.5.0-alpha.17-Windows-x64.zip) · [Русский](README.ru.md)

An independent map editor built on FTE Quake, csaddon and Dear ImGui. Menus and tools surround a live engine viewport, with a persistent inspector and one to four perspective/orthographic panes. The current game profile is Quake III Arena with Valve 220 brush mapping and Quake 3 patches.

**Experimental Windows preview.** This release adds a dark, dockable workspace with scalable fonts and persistent panel layouts. The tools from alpha.16 remain available. The complete parity roadmap is still in progress.

[**Workspace settings and checks**](docs/alpha17.md) · [Geometry tools](docs/alpha16.md) · [**Complete test checklist**](docs/checks-alpha16.md) · [Roadmap](docs/roadmap.ru.md)

![FTEBroom interface](screenshots/workspace.png)

## Available features

- Dark palette, dockable/resizable panels and tabs, 100–200% UI/font scaling, saved layouts, panel locking and reset.

- Quake 3 resource setup; loose textures, PK3 archives and shader previews. Resources are mounted read-only.
- Native file navigation for Open/Save As, dirty-state guards, MAP persistence, autosave and transaction-based Undo/Redo.
- WASD/QX navigation, relative mouse look, orbit/pan, saved viewpoints, orthographic views, linked cameras and resizable layouts.
- Grid 0.125–256, snapping, visible surface/background grids and configurable grid opacity.
- Brush, face, patch and point-entity selection; depth drilling, paint selection, groups, selection bounds/dimensions and locked-object visualization.
- All/Invert/Siblings/Touching/Inside/Tall selection and selection by MAP line.
- Box creation, mixed-object movement, independent duplication of nested groups/brush entities, deletion and clipboard MAP fragments.
- Material browser with folder/used filters, search and usage counts; material selection/replacement, UV fields, surface attributes, alignment/Fit and texture transfer.
- Keyboard rotation/flip and interactive Rotate with movable pivot, angle snapping and texture lock.
- Shift-drag Extrude; Shift+Ctrl Split; Shift+Ctrl+Alt Stamp, with scene previews, cancellation and single-step Undo.
- Existing Clip with two/three points, translucent discard preview and keep-side controls. The advanced Clip interaction rewrite remains pending.

## Start

Extract the ZIP completely and run **Launch-FTEBroom.cmd**. Select **Quake III Arena**, choose your **baseq3** directory and load resources. Retail assets are not included. The editor runs in its own directory and does not write into baseq3.

Run **Launch-Checks.cmd → B** for the new brush workflows. Use copies of maps while testing. The [combined checklist](docs/checks-alpha16.md) covers new features and regressions, including real cross-application clipboard use and Windows DPI scaling.

## Main controls

Click to select; drag a selected object to move. With no selection, drag empty space to create a box one grid cell thick. Normal movement follows XY; Alt constrains movement to Z. Shift+click selects a face, while Shift-drag on a selected whole brush resizes its face. In 2D, grab the face's projected edge.

Ctrl-drag duplicates; Ctrl+D duplicates in place. R activates Rotate, C activates Clip. Escape cancels a gesture; Shift+Escape leaves the modal tool. Delete removes selected objects; Ctrl+Z/Ctrl+Y undo/redo. The inspector remains visible; F1 restores it. Text entry and dialogs capture keyboard input without moving the camera.

The plain mouse wheel changes grid size by default; Preferences can switch to Ctrl+Alt+wheel. The Material tab applies a clicked material to selected faces/brushes. Edit offsets, X/Y scale and angle there; nonzero negative scales mirror the texture. Texture rotation preserves existing axis skew.

## Limits

This is not full TrenchBroom/ReyondBroom parity. CSG commands, vertex/edge/face geometry editing, Scale/Shear, point-based brush construction, primitive tools, entity-definition workflows, complete layer/linked-group editing, patch control points, Sweep and the UV editor remain future stages. Some toolbar entries are framework placeholders. Rotate pivot history and material-browser refinements are also pending.

The MAP writer uses Valve 220 texture axes and Quake 3 patch data. Use a compatible external compiler. Compile/play integration and a Linux package are not included in this release. The tested Windows renderer is OpenGL on an NVIDIA RTX 4060 Laptop GPU.

## Build

Install Git, PowerShell and MSYS2 at `C:/msys64`, with MinGW64 GCC/G++/make/zlib/libpng/libjpeg-turbo and standard MSYS tools. Run `scripts/build-windows.ps1`. The script fetches pinned FTE/ImGui sources, applies all engine patches and builds the engine, addon and plugin into `out/FTEBroom-Windows-x64`.

See [architecture](ARCHITECTURE.md), [verification](TESTING.md), [shortcuts](docs/shortcuts.md) and [third-party notices](THIRD-PARTY.md). Editor code is GPL-2.0-or-later; ImGui is MIT. Binary packages include corresponding source and upstream licenses. Preserve these when redistributing.
