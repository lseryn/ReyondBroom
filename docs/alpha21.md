# ReyondBroom 0.5.0-alpha.21
[Verification checklist](checks-alpha21.md)

## Large maps and everyday editing

The brush renderer allocates storage for the actual polygon sizes, caches selection membership, and grows engine scene buffers geometrically. This addresses the allocation failure encountered with a 5,015-brush map and repeated buffer-copy stalls on large scenes. It does not guarantee the same frame rate as another editor on every map or GPU.

A selected brush can be dragged through an occluding brush. An ordinary click still selects the frontmost object; Ctrl/Shift retain their selection meanings. Surface-grid lines use screen-space derivatives so changing grid spacing does not change their intended pixel width. Class names, point bounds, group bounds and brush-entity bounds start disabled and remain available in View options. Every shared file browser has an explicit **Up one level** button.

## Linked groups

Group objects with Ctrl+G, then use **Edit → Create Linked Duplicate** (Ctrl+Shift+D). Move, rotate or scale a closed copy independently. Double-click a group to open it and edit its contents: committed changes propagate to other copies using their relative transformations. Ctrl+D also preserves an existing link. **Select Linked Groups**, **Separate Linked Groups**, and **Extract Linked Groups** operate on the linked set. Nested group edits propagate through their linked ancestors.

In an open linked group, the entity property table gains a **Protected** column. Protect a door's `targetname` to keep it local while shared properties such as `speed` synchronize. Removing a protected property suppresses its restoration by synchronization. Unprotecting restores an available unprotected peer value. **Clear Protected Properties** also accepts selected closed groups. Link identifiers, transformations and protected-property lists survive MAP save/load.

## Quake 3 patches

Select faces, or whole brushes, and press **Ctrl+P**. Each face becomes one or more quadratic patches; the original brushes are removed in the same undoable operation. Materials and UV coordinates follow the source faces.

Select patches and press **P** for control points. Click, Ctrl-click or lasso handles; coincident points move together. Drag in XY, hold Alt for Z, Ctrl for absolute snapping, or Shift for an axis constraint. Keyboard movement and affine transforms apply to selected points. **Rows / Columns** accept odd counts from 3 to 31. Increasing resolution subdivides the Bezier surface without changing its shape; decreasing approximates it. Delete does not remove individual patch control points. Save/load uses `patchDef2`.

## Sweep

Select a face with Shift+click and press **Y**. Move the destination cap, rotate its axis rings or drag its scale handle. Arrow keys and Page Up/Down move the cap; Alt rotates it; brackets adjust scale. Tool options expose **Straight**, **Arc**, **S-bend**, **Segments**, **Iterations**, integer snapping and Reset. Enter creates the validated convex segments in one transaction and selects them. Escape resets the cap; Escape again leaves the tool. Limits: 64 segments, 32 iterations and 512 generated brushes per operation.

## Graphical UV editor

Select exactly one face and open **Material**. Drag inside the UV canvas to offset its texture; Ctrl-drag or the yellow ring rotates it. Drag a tile line to scale; Alt-drag a tile line to shear. The yellow origin and its red axes move the scale/rotation pivot. Wheel zooms; RMB/MMB pans. Subdivisions support trim-sheet grids. Reset, world alignment, flips and quarter turns sit below the canvas; alignment/Fit controls remain in the surface inspector. A gesture has one Undo step; Escape cancels it. UV shear is represented by Valve 220 axes.

## Repeat, diagnostics and compiler overlays

**Ctrl+R** repeats the recorded duplication/transformation/texture-command sequence on the current selection. A genuine selection change or Ctrl+Shift+R clears it. An implicit rotation center follows the new selection; an explicitly chosen pivot stays fixed. UV-canvas transforms are repeatable too.

**View → Issues** shows map diagnostics with source lines when available. Select an issue, focus it with Ctrl+U, and right-click for Fix or Hide. Filter controls diagnostic types; Show hidden issues reveals suppressed rows. Fixes participate in Undo. Checks cover entity definitions and links, empty containers/properties, invalid UV bases, fractional vertices, bounds, quote/path problems, missing mods and mixed source brush contents. Mixed contents are reported from imported MAP metadata because the engine normalizes brush contents internally.

Use **File → Load Point File** for `.lin` leak paths and **Load Portal File** for `PRT1` portal polygons. Period/comma move along the leak path. Reload and Unload are available; a newer sibling `.lin` is loaded when opening a map. Overlays do not modify the map.

## Compile and launch profiles

**Run → Compile / Launch** edits profiles containing Export Map, Run Tool, Copy Files, Rename File and Delete Files tasks. Set the q3map2/bspc paths under tool variables. Profile variables include map name/path, game folder, CPU count, application folder and working folder. Relative file paths resolve inside the profile working folder. Copy/Delete accept `*` and `?` in the filename, without recursive traversal; a patterned copy's destination is a folder.

Output streams into the window. A nonzero exit stops the pipeline; Stop terminates its process group. Rerun repeats the last profile. The default export profile writes a build copy and runs q3map2 `-meta`; **Launch in FTE** starts the bundled engine in game mode. File tasks refuse to replace or delete the open source map. Quote path variables in tool arguments. Actual q3map2 compilation still requires an external compatible compiler and your game resources.

## Preferences, recovery and export

Preferences separates View, Mouse, Colors, Game, Backups, Keyboard and Update. Click a shortcut and press its replacement; overlapping conflicts are highlighted and must be resolved before closing. Settings are stored separately in `ftebroom-preferences.cfg`. The main workspace stays persistent as requested; F1 restores the inspector.

Autosave interval and copy count are configurable. Backups use a path-derived identity, so maps with the same filename in different folders do not share slots. A newer recoverable backup is offered on startup and opens as an untitled document, requiring Save As. Original files are not overwritten by recovery.

**Export Map** omits excluded layers while retaining included group/layer metadata. **Export OBJ** writes brush polygons, tessellated patches, UVs and a companion MTL with material names. Texture image files are not embedded or copied. Imported models may need material-to-image assignment in Blender.

## Practical limits

This is an experimental Windows release, with bounded convex brushes (64 faces), fixed patch preview tessellation and the existing entity-model descriptor limitations. The native external-process implementation is tested on Windows; no Linux build is supplied here. Process execution tests use disposable fixtures, not a claim that every third-party compiler works. Automated geometry and input tests supplement, rather than replace, the [manual checklist](checks-alpha21.md).
