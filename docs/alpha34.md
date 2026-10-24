# FTEBroom alpha.34 — model stability and file explorer

## Model viewer crash

The ImGui renderer now advertises its existing vertex-offset support. Large model
thumbnails can therefore split their 16-bit index batches instead of hitting the
65,535-vertex assertion, including when Model viewer animation runs alongside the
browser. Assertions remain enabled. A regression scene renders a 72,000-vertex
thumbnail and plays a skeletal animation; every draw command's index range is checked.
Please also retest the model that originally triggered the crash.

## Mod file explorer

The Mod file manager opens by default at the bottom in **Thumbnail view**. Drag its
divider to resize it or its tab to move it. Existing workspaces receive this bottom
placement once; subsequent saved docking choices are preserved. Wide docked panels
use tighter toolbar spacing without shrinking the folder tree or tiles. Thumbnail
size remains adjustable. Close the panel with its cross; reopen it from Workspace.

The left side contains an expandable folder/file hierarchy. Click a directory in
the tree or the tile/list view to navigate. **Up** returns to the parent directory;
**Mod root** returns to the selected mod. Refresh updates both views. Only expanded
branches are enumerated; symbolic links outside the mod are not traversed.

PAK files appear as folders with a blue archive stripe, and `[PAK]` in the tree.
Open them to browse nested paths. **Copy**, navigate to a disk directory, then
**Paste** extracts an individual file without replacing an existing file. Drop external
files into an open PAK or paste files there to import them. Name collisions receive a
numeric suffix; enable **Replace matching files on import (backup)** to replace entries.
Rename and internal drag/Cut/Paste move entries within the same PAK. Use Copy across
the PAK/disk boundary; cross-boundary Cut and copying whole packed folders are not supported.
PAK folders are implicit: **New... → Create file** with `folder/file.cfg` creates the
nested path. Empty folders cannot be stored in this format.

Right-click a text file → **Edit text... → Save with backup**. Text files up to 1 MiB
are supported; saving is refused if the file changed externally. Replace binary files
through import. PAK writes stage and validate a complete archive, preserve a timestamped
`.bak`, then atomically replace the original. Locked archives produce an error without
replacement. Reload mod resources after changes because models/materials may remain cached.
Existing MAP save-to-PAK functionality is unchanged. Model previews use
mod-relative resource names, so their model and skin resources must be mounted by FTE.

## Selection guides and interface

Selection guide rays stop at the nearest visible, non-selected brush and mark the
intersection with a red dot. Brush entities and locked brushes participate. Hidden
brushes and selected brushes do not block these rays; patches and models are not
brush colliders. Misses retain the existing guide length. Intersections are cached
until geometry, selection or visibility changes.

Leaving the Terrain tab, pressing Escape / **Exit terrain editing**, or selecting
another tool ends the current terrain stroke and releases terrain pointer ownership.
The finished stroke remains in the shared Undo/Redo history.

The startup map list uses one row per map: favorite star, filename, and muted game
profile. Hover the filename for the full path. Filled gold stars are favorites;
outline stars are not. The star above the list toggles Favorites only.

All eleven Tools-panel modes and the two texture-lock controls now have scalable
[Lucide](https://github.com/lucide-icons/lucide) line icons. Hover for the tool name
and shortcut. The icon colors follow the theme and the active tool remains highlighted.
SVG sources and ISC/Feather MIT notices are included under `assets/lucide`.

## What to test

- Open the previously crashing model; play/scrub animations, orbit and show bones.
  Keep model thumbnails visible simultaneously, then close/reopen the viewer.
- On startup check the bottom tile browser. Resize, undock, redock and restart;
  check the horizontal compact toolbar and unchanged tree/tile sizes.
- Expand nested folders and a PAK, navigate with tree/tiles/Up/Mod root, refresh,
  and copy one packed file to a disk folder. Browsing/extraction must leave the PAK unchanged.
- On a disposable PAK, import/replace a file, rename/move a member, create `folder/test.cfg`
  and edit/save its text. Check unaffected entries and timestamped backups.
- Sculpt terrain, leave its tab or select Clip/Move, and test Escape. The terrain cursor
  must disappear, ordinary tools must work, and the finished stroke must undo/redo.
- Select a brush near another brush or brush entity: guide rays should stop at the
  nearest surface with red dots. Move, Undo/Redo, hide/show obstacles and multi-select.
- Check one-line recent-map rows, muted profiles, filename path tooltips, favorites
  filtering and persistence across restarts.
- Hover and activate each tool icon; verify name, shortcut and active highlight.
  Check both dark and Windows 95/98 themes and different interface scales.

Automated checks cover the large draw list, animation, PAK enumeration/extraction,
favorite persistence, guide collisions/self exclusion, visual selection states,
MAP round trips and movement/creation/Undo/Redo gestures. All fixtures are disposable;
no user map or mod assets are changed by these tests.
