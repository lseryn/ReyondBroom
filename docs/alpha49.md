# Alpha 49: Spawn Master and reliable entity-definition delivery

## Spawn Master

Select one trigger or button entity, then choose **Tools → Spawn Master**. Pick an existing destination `targetname` and the point entity to place in the teleport closet. Both lists have search; entity previews are clipped to their tiles and their size is adjustable. **Refresh selection / targets** reloads the dialog's source and destination list.

**Build / update closet** creates a shared `SpawnMasterCloset` group in free space below the source. It contains six enclosing wall brushes, one `trigger_teleport` per configured source, and one chosen point entity in each teleport cell. Cell dimensions account for the definition's bounds; the entity is aligned to the cell floor. The source's `target` activates the corresponding teleport, whose `target` references the chosen destination. Targetnames are allocated without colliding with existing names.

Configurations are stored on source entities using UltimateTrenchBroom's `_tb_spawn_master_*` keys. Configuring another source rebuilds and expands the shared closet; editing an existing source replaces its entry. The closet's generated contents are rebuilt, so custom edits inside that generated group are not preserved. The source itself and unrelated map objects are retained. The whole change is one Undo/Redo operation, including replacing the previous closet. Save/reopen retains the configuration.

The tool rejects an unknown/brush class, nonexistent destination, changed selection/document, more than 128 entries, or a closet that cannot be placed within the world bounds without intersecting existing geometry. Hidden objects are included in placement checks. Cancel does not change the map. Different mods may implement teleport triggers differently: this builds ordinary entities and brushes, not a new runtime spawning system. The mod must support teleporting the chosen entity; an empty closet does not automatically manufacture replacements.

## Entity definitions

The native interface now publishes its definition cache through FTE's filesystem API, so QuakeC can read a newly created cache immediately. The delivery notification is explicitly registered. Point/brush kinds are stored as integer values rather than floating-point bit patterns. This corrects class validation and the corresponding entity issue checks.

## Checks to perform

1. Create a destination with `targetname`, select a trigger/button and open Spawn Master. Search destinations and classes, resize thumbnails and cancel.
2. Build the closet. Check six walls, teleport target links, the chosen class and floor placement, especially with a large entity definition.
3. Add a second configured trigger. Check that a single closet expands and both sources have different teleport targetnames.
4. Reconfigure the first source. Check the second entry remains, then Undo/Redo creation and reconfiguration.
5. Save/reopen, select a configured source and rebuild: no duplicate closet or lost configuration.
6. Change selection while the dialog is open, choose an invalid destination/class, or exhaust free space/world bounds. The operation must fail without changing the map.
7. In a compatible Quake mod, compile and activate the source. Confirm the chosen entity teleports to the destination; repeat with the actual monster/item classes used by your mod.
8. Open a fresh editor installation/profile and check entity models, bounds, defaults and issue validation immediately, without restarting or reloading the map.
9. Recheck MAP saving, brush movement, text input and hotkeys on Windows and Linux.

Automated checks cover creation, links, six walls, shared expansion, unique targetnames, Undo/Redo, invalid/stale requests and save/reload reconfiguration. Runtime teleport behavior depends on game code and must be checked in the target mod.
