# FTEBroom 0.2 — FTE-native map editor

[**Download Windows x64**](https://github.com/reyond9079/FTEBroom/releases/download/v0.2.0/FTEBroom-0.2-Windows-x64.zip) · [Русский](README.ru.md)

An independent editor project built on FTE Quake, csaddon and Dear ImGui. This repository contains the editor, its engine patch and build scripts; it contains no TrenchBroom/Qt application source. The interface follows TrenchBroom's familiar arrangement: menus and controls above the viewport, tools at the left, an inspector at the right and a status bar below.

**Experimental preview:** core brush workflows are implemented. This is not full ReyondBroom feature parity or a pixel-exact TrenchBroom UI.

![FTEBroom interface](screenshots/prototype.png)

## Run

Download the ZIP from the link above, extract it completely and run **Launch-FTEBroom.cmd**. No Quake game assets are needed for the included scene. If FTE shows an update-source prompt, choose **Later**. The launcher uses its own base directory and `-nohome`; your ordinary game installation is not modified.

The Windows package contains the engine built from pinned source plus the included surface-metadata fix, ImGui plugin, compiled csaddon, sample assets, licenses and sources. The preview engine disables Ogg playback and static voice codecs. This iteration is tested with Windows x64/OpenGL on an NVIDIA RTX 4060 Laptop GPU.

## Tools and input

The arrow **Smart** tool is selected by default:

- Click a brush without dragging to select it. A four-pixel threshold separates clicking from dragging.
- Drag on empty space or an unselected surface to create a box. Starting on a surface uses that surface's height; otherwise **Plane Z** supplies the construction height.
- Drag an already selected brush to move it. The Move tool also permits dragging an unselected brush directly. The Box tool always creates on a drag.
- Ordinary creation/movement uses world **XY**, preserving Z during movement. Hold **Alt** while moving to change only **Z**. Releasing Alt resumes XY from the current location. During creation Alt adjusts the new box's height.
- **Escape** cancels the live gesture without changing the map. Release the left button to commit one history operation.
- **RMB drag** looks around; hold RMB with **WASD** to move the camera. Pointer travel is currently bounded by the window; infinite mouse capture remains future work.
- **F1** hides/shows the inspector. Scene gestures continue while the inspector is open. UI clicks and popup dialogs are kept out of the scene input path.
- **Ctrl+Z / Ctrl+Y** undo/redo; Delete removes the selection. Undo history now uses editor time, so paused game time does not merge separate gestures.

Movement currently operates on the pointed brush. This is not a multi-object transform implementation. Save/open dialogs deliberately block scene input until confirmed or cancelled.

## Grid and inspector

Grid spacing is available in the top toolbar, **View → Grid size**, and **Map → Grid → Spacing**. Values are powers of two from 1 to 128. The construction-grid checkbox controls the visual overlay; snapping remains enabled. Very fine grids are drawn at a coarser visual interval for readability, while snapping uses the selected spacing.

The Map inspector supplies creation height, Plane Z, numeric box centre/size, selection count and file controls. The Material tab sets the material for new brushes. Perspective and X/Y/Z views are selected from the top toolbar. In side views, XY movement follows the visible horizontal axis; Alt controls height.

## Files

Use a simple ASCII name containing letters, numbers, `_` or `-`. **Save .map** writes `ftebroom/maps/<name>.map` after replacement confirmation. **Open .map** discards unsaved edits after confirmation. Work with disposable copies: dirty-state tracking, crash recovery and Q2/Q3 metadata preservation through every editing operation are not implemented.

## First test checklist for 0.2

1. With the inspector open, click the floor, then click empty space to clear selection. Drag across the floor to create a brush. One click must not create a brush.
2. Drag the selected brush: its height must remain unchanged. Hold Alt and drag upward/downward: X/Y must stay fixed. Release Alt during the same gesture and check for jumps.
3. Start a drag, press Escape and check that no geometry changed.
4. Undo/Redo several separate gestures; each press should affect one gesture.
5. Change grid spacing through the toolbar and the View menu. Check snap increments and the construction-grid visibility toggle.
6. Toggle F1 and verify the scene remains usable. Click/drag numeric fields: these interactions must not create or move scene brushes.
7. Save/open a disposable map. Cancel a file dialog once, then confirm it. Test Windows display scaling and report any pointer mismatch.

Automated coverage checks the gesture core, XY/Z constraints, click-versus-drag, cancellation, history and full exported face records. Manual native input/focus and scaling validation remains part of this checklist.

## Build on Windows

Install Git, PowerShell and MSYS2 at `C:/msys64`, including MinGW64 GCC/G++/make/zlib/libpng/libjpeg-turbo and standard MSYS shell tools.

```powershell
./scripts/build-windows.ps1
./scripts/smoke-windows.ps1 -Bundle ./out/FTEBroom-Windows-x64
```

The script fetches pinned FTE and ImGui revisions and builds engine, compiler, addon and plugin. An optional `-Engine <path>` skips the engine build; an external binary must pass the full smoke test independently. The output is `out/FTEBroom-Windows-x64`.

See [architecture](ARCHITECTURE.md), [verification](TESTING.md), and [third-party notices](THIRD-PARTY.md). New editor code is GPL-2.0-or-later; ImGui is MIT. Preserve base engine source and the adjacent patch when redistributing a build.

## Roadmap

Fracture, Perforate, Bevel, Bullet Settle, arrays, entity/material browsers, multiple simultaneous viewports and Linux packages remain future iterations. FTE/csaddon supplies the foundation; ReyondBroom serves as a workflow reference.
