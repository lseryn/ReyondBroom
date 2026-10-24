# UV dragging and edge snapping

Texture dragging follows the mouse in face space. Rotation, nonuniform scale,
mirrored axes and shear are included in the screen-to-UV conversion. The canvas
predicts the same transform sent to the editor, so it does not wait for the next
QC update to display the dragged texture. Releasing the button applies the final
cursor position; Escape cancels the gesture and Undo restores the whole gesture.

Offset snapping uses the closest face vertex to a texture-grid line on each axis,
with an eight-logical-pixel threshold, adjusted for canvas zoom and UI scale.
Movement beyond the snap threshold retains its fractional residual. Hold Ctrl to
move freely or disable scale snapping. At close zoom, movement outside the snap zone
uses subtexel steps sized to about one logical screen pixel, capped at one texel.
For precise placement beside a snap target, hold Ctrl to bypass snapping entirely. Drag the circular handle to rotate.
Scaling a texture grid line also snaps to the nearest face vertex within eight
logical pixels. Pan and zoom are suspended during a left-button gesture.

This behavior follows TrenchBroom's `UVOffsetDragTracker`, `UVViewHelper::snapDelta`
and the scale-handle snapping in `UVScaleTool`:
https://github.com/TrenchBroom/TrenchBroom/tree/master/lib/TbUiLib/src

## Checks

- Move UVs left/right/up/down: the texture must follow the cursor.
- Repeat at different canvas zoom levels, texture scales and rotations.
- Approach a face edge with a texture border: it should snap without precise aiming.
- Drag beyond the snap zone and return; there should be no accumulated drift.
- Hold/release Ctrl during the drag and verify free motion/snapping.
- Release while moving, then Undo/Redo. Press Escape during another drag.
- Drag a grid line to scale and the ring to rotate; inspect the saved MAP.

Automated math coverage: compile and run `tests/uv-math.cpp` with C++17.
Engine gesture/MAP coverage: `scripts/test-uv-windows.ps1`.
