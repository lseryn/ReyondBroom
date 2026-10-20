# Task 0.2 — modal tool framework

Task 0.1 was accepted by the user on 2026-10-20. This preview introduces the lifecycle and toolbar required for 0.2. It is not the geometry implementation of every tool shown on that toolbar.

## Available now

- Default mode combines click selection, drag creation and moving the selected brush. The old Move/Box buttons are removed. File → Preferences exposes the legacy option to drag an unselected brush to move it.
- B/C/R/Y/T/G/V/E/F/P activate Brush/Clip/Rotate/Sweep/Scale/Shear/Vertex/Edge/Face/Control Point modes. Press the same shortcut again to return to Default. Switching mode clears the previous preview/state. Only one mode is active.
- Escape cancels an active brush drag; otherwise it removes the last Clip point, clears prepared Brush points or handle state, then exits an empty mode. In Default it deselects, with a separate Undo/Redo step. Shift+Escape exits the mode immediately. Escape inside dialogs closes the dialog without editing the scene.
- Clip: Enter applies, Ctrl+Enter cycles the retained side, Delete removes the last point. The information bar exposes the same side and Apply controls.
- Default: **Move objects by** applies a numeric XYZ displacement to selected whole brushes as one history step. A mixed face/patch selection is rejected before modification. Each offset component must be finite and within ±8192.
- TL keeps the texture attached during movement. UV Lock is a stored mode preference only; advanced transform behavior is a later task.
- Undo/Redo and map initialization clear stale tool previews. The status bar shows the current mode, selection count, grid and next action.

## Framework boundaries

Clip and the default brush workflows edit geometry. Brush mode currently prepares point count/cancellation; polygon construction is later work. Other modal modes expose activation/cancellation only and explicitly say **framework**: rotation, scaling, shearing, sweeping and handle manipulation are not implemented by this preview. The default input path preserves existing selection/move/shape gestures; Extrude and entity-drop behavior await their geometry/document tasks. Advanced mode parameter pages and View Options remain to be connected when those operations exist. Do not interpret toolbar presence as full TrenchBroom parity.

## Manual acceptance

1. Create a brush in Default. Press C twice: Clip, then Default. Press C then V: Vertex replaces Clip. Shift+Escape returns to Default.
2. In Clip place three points. Press Escape three times: 3 → 2 → 1 → 0. Press again to exit Clip; again to deselect. Ctrl+Z restores the selection, Ctrl+Y clears it again without changing geometry.
3. Preview a cut, use Ctrl+Enter to change side and Delete to remove a point. Apply, Undo, Redo.
4. Drag a brush and press Escape before releasing: no geometry or extra history step. Repeat with Alt-Z.
5. Select a whole brush, enter 32/0/0 in Move objects by, Apply, Undo and Redo. Compare TL enabled/disabled movement of a visibly patterned material.
6. Check popup Escape and typing in numeric/material fields do not trigger scene commands. Try the legacy drag option with an unselected brush.

Use copies of maps. The automated test injects handle-state fixtures; it does not claim interactive vertex-handle editing exists. Physical pointer, keyboard and Windows focus checks remain manual.
