# Alpha 47: Polygon Cut/Spawn and linked symmetry

This is another transfer increment, not a claim of complete feature parity. See the [comparison ledger](reyond-parity.md) for outstanding work.

## Polygon Cut and Polygon Spawn

Choose **Tools → Polygon Cut** with 1–64 convex brushes selected, or **Tools → Polygon Spawn** to create geometry. Click to place a planar contour. In perspective the first hit establishes the brush face plane; an empty-space click uses a horizontal plane. In orthographic views the current view plane is used. Close the contour by clicking its first point or choosing **Close contour**. Drag the handles to adjust it.

Cut supports **Depth (grid steps)**: zero cuts through the source; a positive value cuts inward from the contour plane by that many grid cells. **Keep cutout** retains the removed volumes alongside the surrounding fragments. Spawn extrudes the contour by one grid cell along its normal, using the current new-brush material. It can decompose a concave outline into multiple convex brushes; it never creates a concave brush.

The valid result is previewed in the scene. Apply/Enter creates the output in one Undo. Escape during a handle drag restores the point; Escape outside a drag exits. Backspace first reopens a closed contour, then removes its last point. Reset removes the contour. Cancel leaves the document unchanged. Self-intersections, nonplanar/zero-area contours and excessive complexity are rejected. Limits: 64 points and 512 output brushes. Patches and entities are not cutter inputs. The generic convex decomposition can produce a different arrangement of pieces from UltimateTrenchBroom's specialized orthogonal decomposition.

## Symmetry

Select objects and choose **Edit → Symmetry → 2/4/8 sides (Mirror/Rotate)**. The selection becomes a linked source group; the other sides are transformed instances around its bounds center on the vertical axis. Mirror alternates reflections and rotations. Rotate uses rotations only.

Open any side's group and edit its contents: brush geometry, materials and entity changes synchronize through the linked-group system. Close the group to move an instance independently. Select a closed symmetry group and choose another side count/mode to rebuild its set. Create/reconfigure and synchronized edits each use document Undo. The group metadata and transforms are stored in MAP files. Use the existing **Separate Linked Groups** command to detach selected instances. The operation rejects more than 2048 input-instance objects.

This implements persistent synchronized sides. Ultimate's automatic relinking of pre-existing mirrored objects and live symmetry guide planes are still outstanding. Reconfiguration uses the selected side as the new source and the world horizontal axes as its reference.

## Stability

Offline editor entity-property changes no longer fill the loopback reliable-message queue during group generation. The local transaction path still updates the editor's entity cache. Networked editing retains its previous message path. An incoming entity update beyond the current cache now reloads that cache before indexing it.

Perspective panes now explicitly restore their near/far clipping range after orthographic rendering, preventing geometry from disappearing when switching from 2D.

## Checks to perform

1. Cut a box with a rectangular and a concave L-shaped outline in perspective and top/side views. Check that the intended plane is used.
2. Drag contour points, reopen with Backspace, remove points, cancel a drag with Escape and cancel the tool. The original must remain unchanged until Apply.
3. Try through-cut, a shallow depth, Keep cutout, different grid sizes, multiple selected brushes and a brush entity. Apply, Undo and Redo.
4. Spawn rectangular and concave outlines with a visible material. Check one-cell thickness, material and Undo. Try a self-crossing outline: it must report an error without changing the map.
5. Create 2/4/8-sided Mirror and Rotate symmetry from asymmetric geometry. Open each side's group and edit vertices/materials or add an entity. Check the other sides and Undo/Redo.
6. Close a group, select it and change the symmetry mode. Undo must restore the previous complete set. Save/reopen and edit an instance again; also test Separate Linked Groups.
7. Repeat normal selection, XY/Alt-Z movement, clip, delete and text entry on Windows and Linux. Ensure new tool contexts do not intercept text input. Switch repeatedly between 2D and perspective, including multi-pane layouts; nearby geometry must remain visible.
8. On large inputs, verify rejected operations leave the map intact and the console does not flood with reliable-message overflow errors.

Automated coverage includes polygon volumes, concave decomposition, winding, invalid contours, depth, retained cutouts, pointer gestures, Apply/Undo; symmetry counts, bidirectional edits and reconfiguration Undo; complete MAP attribute round-trip and gesture/action regression. Linux geometry checks run in Arch with Xvfb/software OpenGL, not a live Wayland desktop session.
