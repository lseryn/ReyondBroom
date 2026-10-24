# Alpha 56: prefab collections

Open **View → Prefab collections**. Browse to a collection MAP, including maps inside PAK/PK3 archives, then **Add / reload collection**. You can also drop a MAP from the Mod file manager onto that button. Named TrenchBroom/ReyondBroom groups become cards. The filter searches group names; Card size changes their width. Right-click a collection heading to remove its registration. Source files are never modified.

Drag a card into a 2D/3D viewport. Placement uses the normal MAP-import snapping and surface placement. Nested groups, brush entities, point entities and patches belonging to the chosen group are included; unrelated world geometry and source layers are excluded. Quake 1 rejects patches. Explicit game-family mismatches are rejected.

Each placement is independent: linked-group/symmetry metadata is removed, group IDs are remapped, and the top-level group name receives a suffix when necessary. Material names and entity properties remain; load the collection's resources in the destination profile. Gameplay target/targetname values are intentionally preserved, so adjust them if separate instances must not share triggers.

One Undo removes a placement; Redo restores it. Reload a collection after editing its source MAP. Registrations persist, but missing files display an error. Limits: 32 collections, 16 MiB and 8,192 entities per MAP, 64 hierarchy levels. Cards currently show names, not rendered geometry thumbnails; no live geometry ghost is shown during dragging.

## Checks

1. Add a MAP containing multiple named groups. Filter, resize cards, collapse collections, remove a registration, then restart and check persistence.
2. Drag a group into perspective and each 2D view. Verify snapping, materials and placement; check Undo/Redo.
3. Place the same group twice. Names must differ, and editing one must not change the other.
4. Use nested groups, brush entities, point entities and a patch. Unrelated collection geometry must not appear.
5. Save/reopen the destination and verify both instances. Check source MAP checksums remain unchanged.
6. Browse a collection inside PAK/PK3. Try missing files, malformed files and a mismatched game profile; the current map must remain intact.

Automated tests exercise hierarchy extraction, byte-preserved geometry, malformed input rejection, independent metadata, placement, unique names, Undo/Redo and destination reload on Windows and Arch Linux/Xvfb.
