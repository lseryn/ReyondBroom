# Alpha.19 — baseline editor completion and large-map fixes

[Русский](alpha19.ru.md) · [Acceptance checklist](checks-alpha19.md)

This release finishes the remaining baseline work within roadmap phases 0–15. The frontend remains Dear ImGui. Linked groups, patch construction/control-point tools, Sweep, the UV editor and compile/play integration are outside this release.

## Loading, saving and scene visibility

- Container bounds are accumulated once and cached instead of repeatedly scanning the whole document for every group, label and viewport. Property-owner discovery also uses a single document pass. This fixes the QuakeC runaway encountered when opening `hotel02.map`.
- Unselected geometry belonging to groups and brush entities is explicitly submitted to the scene renderer. It no longer depends on selection highlighting or the point-model visibility option. Layer hiding, class filters, preview replacement and special-material transparency still apply.
- MAP saving generates well-separated points from each plane equation. The old first-three-winding-vertices approach could amplify rounding on thin faces and change a brush on reload. UV axes and surface metadata retain their existing representation.
- The supplied `hotel02.map` was tested only in disposable installations, with a hash check that the original was unchanged. The regression map in the repository is independently generated; the user's map is not distributed.

## Entity inspector

Click a property cell to select it; click it again or press F2 to edit. Arrow keys move between cells. Tab/Shift+Tab move between columns and rows; Enter advances down a column. Editing commits on leaving a cell; Escape cancels the current edit. Ctrl+Enter or **+ New property** creates an empty property and edits its key immediately.

Ctrl-click adds/removes rows from the property selection; Shift-click selects a range; Ctrl+A selects the displayed property rows. **− Remove** or Delete removes selected properties in one Undo transaction. Deleting in the inspector does not delete scene objects. `classname` cannot be removed/renamed as a key; edit its value to change class. Internal brush-model references remain protected.

Explicit properties precede definition defaults. Default-only rows are italic when the system italic font is available; properties missing on some selected entities are subdued. Mixed values display an empty cell and are not overwritten merely by focusing/leaving it.

The smart editor below the table follows the selected property: tri-state spawnflags, definition choices, or a color picker. Colors can be stored as floats or bytes, with swatches collected from the map's `color` and `_color` properties. Changing a flag preserves unrelated bits on each selected entity.

Definition models now carry skin, frame and scale descriptors in addition to paths/property references. Numeric literals and property names are supported for skin/frame. Scale accepts a literal scalar/vector or a comma-separated property fallback, such as `modelscale, modelscale_vec`; the last nonempty property wins. ENT attributes and FGD attributes/inheritance carry these descriptors. This is a bounded descriptor format, not a general scripting interpreter. Entity-browser tiles use the class-colored bounding-box preview allowed by the roadmap; loaded scene models use the engine renderer.

## Geometry and organization

- UV Lock in Vertex/Edge/Face editing fits texture coordinates to corresponding original corners, including newly triangulated faces. Stationary corners retain their UV coordinates.
- Hovered handles show coordinates beside the cursor; dragging shows yellow axis guides. Edge/face outlines are visible before selecting individual handles. Collinear Brush Tool points preview their full endpoint range.
- Entity creation menus and visibility filters group classes by prefix. Class visibility and point-class creation are rebindable actions generated from loaded definitions. All nine Quake 3 tag filters also have actions.
- Group creation requires leaving the active modal tool.
- Layers can be selected with Ctrl-click and removed together while retaining their objects. The context menu includes Hide, Lock and Omit from export. Reordering, bulk visibility/locking and removal are single Undo transactions.

## Scope and engine constraints

The documented 64-plane brush limit remains: unsupported sphere/scalable-circle resolutions are rejected without changing the map. The roadmap explicitly permits the native-geometry performance proposal as a follow-up; see [the proposal](native-geometry-proposal.md). Existing patch data is retained and displayed, but patch editing tools are not implemented. Browser previews use bounds when model thumbnails are unavailable. This release does not promise identical pixels or arbitrary definition-expression language compatibility with another editor.

See [TESTING.md](../TESTING.md) for automated evidence and the [complete manual checklist](checks-alpha19.md) for real-resource and mouse checks.

Large-map selection also avoids whole-document scans for individual leaves and skips unrelated container descendants before checking visibility. Select All and Invert were exercised on all 2396 brush/patch objects in the test map.
