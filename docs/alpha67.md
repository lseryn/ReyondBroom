# Alpha 67: compact packages and shader reload fix

- Fixed shader cvar metadata lifetime when changing resources or GLSL programs.
- Default grid size is 16; saved user overrides are retained.
- Windows launcher uses the FTE icon; the engine is under `bin`.
- A small root `fteqw64.exe` compatibility launcher allows older updaters to accept
  this release. `FTEBroom.exe` removes that byte-identical alias on first launch.
- Dependency and editor sources are separate platform Sources archives. Publish
  both Sources assets alongside the Windows/Linux runtime archives.
- Successful updates clean old download/staging files and keep the latest backup.
- Documentation is English-only; obsolete task notes and agent instructions are removed.

Check: launch FTEBroom, open hotel02 and reload Custom GLSL resources, verify grid
16 on a fresh install and persistence after changing it, compile a map, enter and
leave BSP/mod preview. After updating, verify settings and custom maps remain.

Embedded mod preview remains Windows-only. Linux tests run under Xvfb, not a
physical Arch Wayland desktop.
