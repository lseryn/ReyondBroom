# Alpha 63 — Quake mod loading

The engine model registry grows on demand instead of terminating at 8,192 names. Model addresses and model IDs remain stable while the registry grows. Hashed name lookup avoids scanning the full registry for every model request. Storage is released on renderer/engine shutdown; repeated requests for an existing name do not create new entries.

Changing Quake 1 resources now refreshes cached asset models, including previously missing models. Raw MAP geometry and brush submodels are retained. This fixes models that remained unavailable after their mod was connected, and prevents keeping an asset from the previous resource mount.

Quake 1 mapping falls back to the same standard palette used by FTE if the mod does not supply `gfx/palette.lmp`. A supplied palette still takes priority and must contain exactly 768 bytes. WAD browsing, model skins, image imports and MDL conversion use the same palette.

Choose the Arcane Dimensions folder with its PAK archives. Its `ad_1_8.def` is discovered automatically. A sibling `id1` folder is mounted as base resources, with the selected mod taking priority. There is still only one mod-directory field. No mod files are copied or modified. AD's release does not include mapping WADs: add the WADs used by your map separately. Mapping palette fallback is not a replacement for owning Quake; playing AD requires the base game resources.

## Regression checks

`scripts/test-mods63-windows.ps1` and `scripts/test-mods63-linux.sh` accept local AD and LibreQuake directories and use disposable editor installations. They exercise six alternating resource loads, material/definition availability, animated player-model frame counts, and a 20,000-name registry test twice. The registry test checks duplicate reuse and stable pointers/IDs. Real mods are test inputs and are not redistributed.

## Manual checklist

1. Choose Quake 1 and the AD directory. Load resources; verify the starter scene and AD entity definitions.
2. Open the player model and play its animation. Check geometry and skin.
3. Switch to LibreQuake, then back to AD several times. Models should correspond to the active mod and the editor should remain responsive.
4. Add a mapping WAD, create/save a small map, then build and view the BSP.
5. For game preview, keep the original Quake `id1` next to AD; verify spawn, movement and returning to editing.
6. Reopen a large MAP and existing Quake III/FTE Custom projects; verify geometry and model rendering.
