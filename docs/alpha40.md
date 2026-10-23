# Alpha 40 — Quake 1 resources and Arch Linux desktop integration

## Changes

- Quake 1 setup explicitly separates **Base game directory (id1)** and optional
  **Mod directory**. Both directories and their PAK archives are mounted read-only;
  mod files override base files. A mod can inherit `gfx/palette.lmp` from base
  `pak0.pak`. LibreQuake can also supply the base resources. Existing settings are retained.
- Linux defaults to 100% UI scale on a fresh installation or appearance reset.
  An existing saved scale remains unchanged.
- Wayland cursor shapes share one cursor surface, including when crossing dock
  splitters. Cursor image allocations are released; ImGui does not draw a second cursor.
- External WAD drops work in native Wayland, including file URI percent encoding,
  spaces and UTF-8 names. X11 URI drops use the same editor import endpoint.
  A drop mounts the WAD; compilation stages a compiler-friendly copy as before.
  External image-to-WAD conversion remains Windows-only.
- Q3Map2 includes its compiler-only shared dependencies and their corresponding
  sources/notices. A private launcher keeps those libraries out of the editor's
  OpenGL/Wayland library search. This fixes `libassimp.so.5` and related ABI issues
  on Arch. The package is larger because it now includes these libraries and sources.
- The tool runner offers a Q1 `qbsp` profile, selects defaults by game profile,
  and refuses Q3Map2 for Q1 maps. **Build / Build...** continues to provide the full
  Q1 BSP/VIS/LIGHT pipeline and BSP viewport preview.
- Linux now checks/downloads matching updates through Python 3, verifies archive
  and file checksums, stages files, and installs after the editor exits. Settings,
  modified documents and external game files are preserved; backups remain under
  `updates/`. The Windows release selector now skips Linux-only releases.

## Validation

Tests run in an isolated Arch Linux userspace with Weston 15 on Xvfb and software
OpenGL, hosted in WSL2. This is an Arch/Wayland integration test, not a test on a
physical Arch desktop or every compositor/GPU.

- Base PAK palette inheritance, mod-over-base resource priority and WAD discovery.
- A real GTK Wayland drag of a WAD with spaces and Cyrillic in its path; material
  appears in the editor. Repeated dock boundary crossings and screenshot inspection.
- Q3 BSP build/viewport preview and Q1 BSP29/BSP2 plus LIGHT-only rebuilds, using the
  bundled compiler dependencies in Arch.
- UTF-8 clipboard paste/copy and single cursor ownership regression.
- Linux updater selection, delayed installation, preservation of settings/maps,
  executable permissions, rollback, and rejection of unsafe archive entries.

## Please check on your desktop

1. Select **Quake 1**; set the base game to `id1` and the mod to its separate folder.
   Open a map. Verify base textures, mod textures and overrides, then restart and
   confirm both paths persist. The mod itself need not contain a palette.
2. Cross all dock boundaries repeatedly; resize panels; move between text fields
   and the viewport; rotate the camera; Alt-Tab away/back. The pointer should stay
   visible when not controlling the camera, without a second cursor.
3. Drag one or several external WADs from your file manager onto the scene or
   Material panel. Try spaces/Cyrillic paths. Apply a texture, save and Build; the
   texture should remain present in the compiled result.
4. Build a Q1 map with BSP/VIS/LIGHT; then build a Q3 map. No missing-library error
   should appear. The tool runner should select the appropriate default profile.
5. Fresh Linux settings should start at 100%. Existing scale preferences should
   survive an update; use Preferences to change them if desired.
6. **Check for updates** should report a result on Linux. Installation of a future
   newer Linux release should occur only after exit and retain profiles, layout,
   scale, bindings, recent maps and favourites. Alpha 39 cannot install this first
   Linux-updater release automatically: extract alpha 40 manually, retaining settings.

Only a Linux binary is published with alpha 40. The latest published Windows
binary remains alpha 37; shared source changes are available in Git.

Scene checks: a player model loaded from the base PAK renders with a separate mod mounted. Missing models still require a valid model file and entity definition. Opaque-brush grid occlusion passed in the test scene; the reported grid bleed has not yet been reproduced and is not claimed fixed.
