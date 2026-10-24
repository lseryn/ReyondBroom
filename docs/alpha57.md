# Alpha 57: Entity List

Open **View → Entity list** to search objects already placed in the map. Groups use their names; entities use `targetname` when present, otherwise their class. The filter matches the name, class and Group/Entity type. Double-click a row to select its object and frame it in the viewport. A containing group opens when needed for access to a nested entity.

Hidden, locked or filtered objects are not silently enabled. The status line asks you to enable them first. Selection participates in Undo; camera movement itself does not modify geometry. The list refreshes after document changes, and visible rows are clipped rather than all drawn every frame. Sorting and filtering are cached.

## Checks

1. Find a named group, point entity and brush entity. Search by name and class; verify duplicate names still select the correct row.
2. Double-click an entity inside a closed group, then an object in another group. Check selection and camera framing in perspective and 2D views.
3. Rename or delete an entity and use Undo/Redo: the list should update. Save/reopen and repeat.
4. Hide or lock its layer, then double-click the entry. It must not become editable without enabling the layer.
5. Scroll/search a large map; confirm the list does not cause continuous filesystem reads or map scans while idle.

Windows and Arch Linux/Xvfb integration tests cover list population, class filtering, brush-entity/group selection and reload. MAP round-trip and gesture regressions are also run for this QC change.
