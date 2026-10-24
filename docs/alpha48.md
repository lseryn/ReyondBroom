# Alpha 48: interactive Spin and live Array

This transfer increment does not complete the [comparison ledger](reyond-parity.md).

## Spin

Shift-click the brush faces to extrude, then choose **Tools → Spin** or **Edit → Spin**. A six-segment extrusion appears without changing the map. The original remains visible and is retained on Apply.

Drag the endpoint handle in Move, Scale or Rotate mode. Move uses the current 2D plane, or the horizontal plane in perspective; Alt switches perspective movement to vertical. Ctrl snaps movement to the grid. The constraint selects All/X/Y/Z; rotation uses Z when All is selected. Rotation by dragging uses whole degrees. Endpoint offset and end rotation can also be typed into Tool options.

Segments (1–64), Flex (-1–1) and End scale (0.05–8) update the preview. Default restores six segments, zero flex/rotation, unit scale and an endpoint six current grid cells along the average selected normal. Undo/Redo operate on the tool's settings while it is active. Escape during a drag restores its initial state; Escape again exits. Apply/Enter adds all pieces as one document Undo. Invalid or degenerate inputs do not modify the original. Limits: 1–32 source brushes, 512 generated pieces, the existing convex-plane limit.

## Array

**Edit → Array** now previews the result as settings change. It supports the existing linear, radial, random volume, line/cross-line, concentric ring and random-radius patterns. Brushes, patches and point-entity models/bounds participate. The original selection remains in place. The preview owns geometry rather than inserting temporary objects into the document.

Use **Undo settings**, **Redo settings**, **Default** or **Cancel**. Document Undo/Redo commands are routed to the settings history while Array is active. Apply creates and selects the copies in one document Undo. Close/Escape cancels the preview. Editing or changing the selection invalidates the preview; adjust settings to refresh it. The output limit is 512 objects; patch preview complexity has an additional 262144-vertex budget.

## Stability

Tool activation now explicitly gates geometry capture. The QuakeC compiler can evaluate both operands of a boolean expression, so the previous combined condition could invoke an inactive tool and overwrite the active preview. Spin, Bend, Polygon and Sweep captures are now isolated.

## Checks to perform

1. Shift-select a box face, activate Spin, and verify the preview immediately has six segments. Try multiple coplanar faces and differently oriented faces.
2. Drag the endpoint in perspective and top/front/side views. Check Alt-Z, Ctrl grid snapping, axis constraints, Move/Scale/Rotate and typed offsets/angles.
3. Change Spin segments/flex/scale, use Default and settings Undo/Redo, cancel a drag, cancel the tool, then Apply and document Undo/Redo. Try a zero-length endpoint: no map change or crash.
4. Open Array on a brush, a patch, a point entity and a mixed selection. Check live previews of every placement mode, rings, cross-lines, facing, seed and offsets.
5. Check Array settings Undo/Redo and Default; close/cancel without changing the map. Apply then document Undo/Redo. Change selection with the panel open and verify stale copies disappear.
6. Try more than 512 resulting objects and dense patches. Rejected previews must leave the map intact; reduce complexity and continue.
7. Switch repeatedly among Spin, Bend, Polygon Cut/Spawn, Sweep and ordinary selection. Their previews must not replace each other.
8. Recheck normal move/Alt-Z, clip, text entry, save/reopen, material scale and entity properties on Windows and Linux.

Automated geometry tests cover immutable preview, settings history, invalid input, Apply/Undo, patch/entity instances and stale selection. Complete MAP attribute round-trip, pointer gestures and action-routing regressions are also required. Linux coverage uses Arch with Xvfb/software OpenGL, not a live Wayland session.
