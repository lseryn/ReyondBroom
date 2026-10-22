# When the sky went dark

[Русский](when-the-sky-went-dark.ru.md)

This game profile separates authoring assets from the installed FTE mod. Select it in **Game / resources**, available from **Build…** or Preferences, then click **Load resources and start**. Settings persist across editor launches.

- Authoring library: `C:/Games/fteqw/baseq3`. Original MAP files remain here or wherever you save them.
- Runtime mod: `C:/Games/fteqw/id1`.
- Runtime engine: `C:/Games/fteqw/fteqw64.exe`. Using the game's own executable preserves its engine version and renderer capabilities.
- Format/compiler: Quake 3 BSP / q3map2. Quake game logic is independent of the BSP format.
- Entity definitions: choose a DEF/FGD file, or point to the mod's QuakeC source directory. The local QUAKED-comment importer reads immediate `.qc` files and caches definitions locally; no mod code is bundled with the editor. Map-specific definitions still take precedence. Comments may be incomplete or stale; they are not proof that the corresponding class exists in the installed `progs.dat`.

## Build and preview

Choose BSP/VIS/LIGHT as usual. For this profile, q3map2 searches the runtime mod first and the authoring library second. Preview is strict: it uses the installed mod, its archives, shaders, GLSL, normal startup configuration, `progs.dat` and `csprogs.dat`; it does not mount the authoring library as a fallback.

**Open mod preview after Build** launches a separate FTE window after a successful build. Turn it off to use **Preview mod** manually. **Show BSP** remains the lightweight editor-only viewer and does not execute the mod.

The preview uses a temporary home under the build directory and FTE's `-readonly` option. Generated BSP/lightmap files are staged there, including an alias using the original map basename. The installed map and source MAP are not overwritten. Existing map-dependent resources in the mod can therefore still be found by the original name. Runtime writes such as saves are intentionally unavailable. Close the preview window, or use **Stop** in Compile / Launch, before the next build. Editor selection and Undo history remain in the editor process.

Actual entity spawn functions run in the mod, including model selection, floor placement, and delayed behavior. This is a running game session with normal mod controls, not a frozen scene or an editor free-camera mode. Skill/spawn flags and the installed gamecode determine which entities appear. Invalid classes and missing resources must be corrected in the map/mod. Merely loading GLSL does not guarantee identical appearance if external configs or launch arguments differ from the normal game launch.

## Current boundaries

This is the first runtime-profile implementation. Embedded viewport streaming, a dedicated free camera/time controls, automatic resource packaging/missing-resource reports, and installation into the mod are not implemented. The preview process has filesystem write protection, but is not a security sandbox for untrusted native plugins or game code. Use your trusted local FTE installation.

## Check

1. Select the profile, verify all paths, apply, restart twice, and confirm the profile and entity catalog persist.
2. Build a map containing `info_player_start`, a known mod item and a brush entity. Verify models, spawn positions and behavior in the separate mod window.
3. Compare the same camera/location in your normal game launch: wall/skin shading, animation and lighting. Verify your usual graphics configuration is loaded.
4. Use a material present only in baseq3: compilation may succeed, but strict preview should expose the missing runtime resource instead of silently loading it from baseq3.
5. Disable automatic preview; test manual Preview mod, Show BSP and returning to editing. Confirm Undo/Redo and unsaved edits survive.
6. Check the source MAP and installed BSP remain unchanged. Try a missing engine/progs.dat path: Build must report a readable error without launching anything.
