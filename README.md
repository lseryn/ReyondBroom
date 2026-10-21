# FTEBroom — FTE-native map editor

[**Download Windows x64 · 0.5.0-alpha.18**](https://github.com/reyond9079/FTEBroom/releases/download/v0.5.0-alpha.18/FTEBroom-0.5.0-alpha.18-Windows-x64.zip) · [Русский](README.ru.md)

An independent map editor built on FTE Quake, csaddon and Dear ImGui. Menus and tools surround a live engine viewport, with a persistent inspector and one to four perspective/orthographic panes. The current game profile is Quake III Arena with Valve 220 brush mapping and Quake 3 patches.

**Experimental Windows preview.** This release adds convex geometry tools, entity definitions/properties, groups, layers, visibility filters and separate compiler-facing MAP export. See the documented behavior and limitations; phases 16–20 are excluded.

[**New tools and usage**](docs/alpha18.md) · [Workspace settings](docs/alpha17.md) · [**Complete test checklist**](docs/checks-alpha18.md) · [Roadmap](docs/roadmap.ru.md)

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
- Clip with movable two/three-point cuts, face-plane double click, translucent discard preview and validated multi-brush Apply.
- CSG Merge/Subtract/Intersect/Hollow, vertex/edge/face editing, Move Face, Scale/Shear and point-based convex brush construction.
- Cylinders/cones, hollow cylinders, UV spheres/icosahedra, stairs, arches/spandrels, scalable circles and grouped multi-part shapes.
- ENT/DEF/FGD entity definitions, 53 bundled Quake 3 classes, drag placement, properties/defaults/flags/colors, brush entities and target/killtarget links.
- Groups, layers, Hide/Isolate/Show All, locking, class/tag/display filters, scene context menus and omit-from-export MAP output.

## Start

Extract the ZIP completely and run **Launch-FTEBroom.cmd**. Select **Quake III Arena**, choose your **baseq3** directory and load resources. Retail assets are not included. The editor runs in its own directory and does not write into baseq3.

Run **Launch-Checks.cmd → B** for the new brush workflows. Use copies of maps while testing. The [combined checklist](docs/checks-alpha18.md) covers new features and regressions, including real cross-application clipboard use and Windows DPI scaling.

## Main controls

Click to select; drag a selected object to move. With no selection, drag empty space to create a box one grid cell thick. Normal movement follows XY; Alt constrains movement to Z. Shift+click selects a face, while Shift-drag on a selected whole brush resizes its face. In 2D, grab the face's projected edge.

Ctrl-drag duplicates; Ctrl+D duplicates in place. R activates Rotate, C activates Clip. Escape cancels a gesture; Shift+Escape leaves the modal tool. Delete removes selected objects; Ctrl+Z/Ctrl+Y undo/redo. The inspector remains visible; F1 restores it. Text entry and dialogs capture keyboard input without moving the camera.

The plain mouse wheel changes grid size by default; Preferences can switch to Ctrl+Alt+wheel. The Material tab applies a clicked material to selected faces/brushes. Edit offsets, X/Y scale and angle there; nonzero negative scales mirror the texture. Texture rotation preserves existing axis skew.

## Limits

The implementation has documented [limits](docs/alpha18.md#limits-to-understand), including the 64-face convex-brush limit, entity-inspector/browser differences and model-expression support. Linked groups, patch construction/control points, Sweep and the UV editor are not included. Toolbar entries for excluded geometry tools are hidden.

The MAP writer uses Valve 220 texture axes and Quake 3 patch data. Use a compatible external compiler. Compile/play integration and a Linux package are not included in this release. The tested Windows renderer is OpenGL on an NVIDIA RTX 4060 Laptop GPU.

## Build

Install Git, PowerShell and MSYS2 at `C:/msys64`, with MinGW64 GCC/G++/make/zlib/libpng/libjpeg-turbo and standard MSYS tools. Run `scripts/build-windows.ps1`. The script fetches pinned FTE/ImGui sources, applies all engine patches and builds the engine, addon and plugin into `out/FTEBroom-Windows-x64`.

See [architecture](ARCHITECTURE.md), [verification](TESTING.md), [shortcuts](docs/shortcuts.md) and [third-party notices](THIRD-PARTY.md). Editor code is GPL-2.0-or-later; ImGui is MIT. Binary packages include corresponding source and upstream licenses. Preserve these when redistributing.
