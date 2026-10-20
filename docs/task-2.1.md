# Object selection — 0.5.0-alpha.13

[Русский](task-2.1.ru.md) · [Combined checklist](checks-2.1.md)

In the default tool, click an object to select it, or empty space to clear selection. Ctrl+click adds/removes an object. Object selection clears any existing face selection. Brushes, patches and point entities can be selected together; the inspector reports geometry and point-entity counts separately. Hidden and locked nodes, including their descendants, are excluded.

Hold Ctrl and drag from an unselected object or empty space to paint selection. Objects crossed by the pointer are added, including the starting object. The path is sampled between mouse positions. Release commits one “Paint Selection” history step; Escape restores the previous selection and preserves Redo. Ctrl-drag starting on an already selected object is reserved for duplicate-and-move (4.1) and currently makes no change.

Ctrl+wheel in the viewport drills through overlapping objects in depth order. Wheel away moves deeper; wheel toward you moves closer. It stops at the first/last hit. With no hit selected, it starts at the nearest/farthest respectively. Closed groups collapse into one candidate. Each change is one “Drill Selection” Undo step. Ctrl+Alt+wheel still changes the grid. Ordinary 2D clicks continue to prefer the smallest projected face.

Clicking a member of a closed group selects its accessible contents. Double-click opens the outermost closed group; nested groups open one level at a time. Double-click inside the open group selects siblings (Ctrl adds). Double-click outside closes one level and selects the closed group. The inspector shows the current open group. Group context and entity multi-selection are restored by Undo/Redo. Group creation/reparenting UI remains task 15.2; multi-object transforms and duplication remain later roadmap work.

Selection does not modify serialized MAP geometry, materials, patches or entity fields. Point-entity selection is supported here; entity editing/deletion tools are separate roadmap tasks. Existing single-face Shift+click is retained; extended face selection is task 2.2.

An additional 2D visibility fix gives the wireframe query an explicit depth extent: objects away from the construction plane must remain visible.

Run **Launch-Checks.cmd → 8** for five blue brushes, three red overlapping brushes, a pair of green grouped brushes and two point entities. Alpha.12 file-browser/camera checks remain pending manual acceptance and are included in the combined checklist.

![Object selection](../screenshots/object-selection.png)
