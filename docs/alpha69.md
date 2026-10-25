# ReyondBroom alpha 69

## Quake 1 resource directories

The editor accepts a game root or a mod folder anywhere on disk:

1. If the chosen directory is named id1, use it directly.
2. Otherwise, if it contains an id1 directory, use that child.
3. Otherwise, use the chosen directory as the mod directory.

Copied paths may include surrounding double quotes or whitespace. Resolved paths are saved as absolute paths. Custom mod folders do not need an id1 child or top-level PAK/WAD files. WADs in nested folders are discovered. A sibling id1 continues to provide base assets for a custom mod; mod assets take priority. Resource directories are mounted read-only.

## Surface grid

Includes merged PR #1 by lseryn: remove the depth bias that let distant grid/brush edges draw over nearer geometry. The selection-depth shader is unchanged.

## Verify

- Choose an external Quake root containing id1, then id1 directly; both should load the same resources.
- Choose an external custom mod without an id1 child. Check WAD materials, packed models/palette and base-asset fallback.
- Restart the editor and check the saved directory/profile.
- Check Quake III and FTE Custom game resources still load.
- On a large map, verify distant grid lines do not show through nearer brushes.
