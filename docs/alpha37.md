# ReyondBroom alpha.37 — setup, profiles and native Linux preview

[User manual with pictures](manual.md)
- Windows launcher restores a maximized, decorated window.
- Grid rotation uses whole degrees; old fractional preferences round to the nearest degree.
- Fresh installations show language → game profile → authoring resources setup.
- Mapping-optional profile paths are labeled. New installations contain no personal game paths.
- The custom profile is named **FTE Custom game**. Existing MAP identifiers remain compatible.
- **FTE Engine terrain** creation is restricted to that profile, including direct commands.
  The separate brush/patch Terrain generator remains available for supported geometry.
- Successful Build opens the compiled BSP in the viewport by default. Mod launch is an
  explicit opt-in; previous implicit auto-launch settings migrate to off. Failed/cancelled
  jobs do not replace the last successful result. A runtime mod is no longer required
  for an ordinary custom-profile BSP build.
- The custom profile's file hierarchy exposes **Mod files** and **Map sources / authoring
  assets** separately. Browsing sources never changes the configured runtime mod.
- English and Russian illustrated manuals consolidate the editor's workflows and limits.
- First native Linux x86-64 build, including native Q3Map2 and Quake 1 compilers.
  Read [Linux requirements and platform differences](linux.md) before installing.

## What to test

1. Fresh Windows extraction: decorated window, language-first setup, Back/Next,
   all three profiles, optional paths left empty, invalid resource path and correction.
2. Restart: language and resources remain saved; setup is not repeated. Upgrade an
   existing installation and verify its paths, WAD list, appearance and recent maps.
3. Set grid rotation to 1°, 37° and -45°; Ctrl-click the slider to type an integer.
   Create/move a brush, switch views, restart and reset to zero.
4. Open old custom-profile maps. The UI says FTE Custom game and assets still load.
   Test profile switching with Save, Don't Save and Cancel.
5. In Quake 1/3, no FTE Engine terrain creation in Edit/context menus or via command.
   In Custom, create terrain on a disposable map, undo/redo, sculpt, exit and save/reopen.
6. Custom file manager: switch between mod and source trees, navigate folders/PAK,
   open a source MAP, and test Copy/Paste/Rename on disposable files. Mod preview must
   still use the mod root after browsing sources.
7. Build a saved map in each profile. Successful builds open BSP, not mod preview.
   Return to editing; check selection, geometry and history. Test the explicit mod
   auto-preview opt-in on Windows and confirm persistence.
8. Build with a custom profile and no runtime mod; authoring assets and compiler suffice.
   Try BSP-only, all stages, LIGHT-only after a matching build, Stop and invalid compiler.
9. Linux: install listed dependencies, start the launcher, complete setup, open/save,
   create/clip/undo/redo, compile Quake 1/3 and inspect BSP. Test sound editing with
   system FFmpeg on a copy. External desktop drops and embedded mod preview remain
   Windows-only; do not treat those as Linux parity features.
10. Navigate a large map in 3D/2D and check frame rate, models, material previews,
    patch rendering, input fields and console errors. No rendering-quality reduction
    is included in this update.
11. Open the illustrated manual from the README, follow profile, WAD, file-manager,
    terrain, Bevel, sound and build instructions; check images and internal links.
