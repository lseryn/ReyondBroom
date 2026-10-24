# Alpha 45: Rock, brush Sculpt and Array patterns

This is another tested transfer increment, not a claim of complete fork parity. See [the comparison ledger](reyond-parity.md).

## Rock

Select one or more solid brushes, then choose **Edit → Rock**. The source bounds determine the ellipsoid. Set detail and seed; enable Hollow and shell thickness for a shell. Preview shows the result without committing; Apply replaces the source in one Undo. Optional grouping collects the generated pieces.

Detailed rocks use convex tetrahedral pieces when their hull exceeds FTE's 64-plane brush limit. The exterior remains the computed rock hull. Internal faces may increase compile cost; Hollow instead builds a radial shell. Limits: 16 sources, 4096 samples and 2048 output pieces. An invalid operation is rolled back.

## Sculpt

Choose **Tools → Sculpt** or the mountain/arrow toolbar button. Drag on a brush surface. Raise and Lower displace nearby surface vertices along the hit normal with smooth falloff. Smooth averages neighbouring surface heights. Radius and intensity are adjustable in Tool options.

Prevent collapse keeps shared vertices consistent, preserves back surfaces and at least one map unit of thickness, and rejects a hull that loses vertices. Hidden/locked objects are excluded. Each stroke is one Undo. Escape or changing tools cancels the current stroke. Brushes must already have enough vertices; use terrain generation or subdivision first for detailed sculpting. This tool edits convex brushes, not FTE Engine terrain or patch control points.

A stroke touching more than 128 brushes or 4096 vertices is rejected; reduce its radius. Mouse sampling is limited to 30 Hz and movement, rather than applying once per rendered frame.

## Array additions

Open **Edit → Array**. In addition to existing linear, radial rotation and random-volume modes:

- **Lines / cross-lines:** multiple lines, forward or centred order, crossed lines, spacing, extra offset and mirrored offsets.
- **Concentric rings:** copies per ring, number of rings, spacing and per-ring offset.
- **Random radius:** deterministic seed and uniform-area distribution inside a disk in the chosen axis plane.
- **Face center:** choose which of ±X, ±Y or ±Z points toward the source center for rings/random radius.

The original is retained; created copies are selected. Apply is one Undo. At most 512 resulting objects across all bands. Array live preview and local settings undo remain on the transfer list.

## Engine robustness

Offline local brush/patch edits no longer retransmit every geometry change over the loopback reliable channel. Large generated operations previously could overflow that channel and disconnect/reload the editor. The optimization is opt-in for the editor, requires a local loopback server/client, and preserves network traffic when a remote client is present.

## User checks

1. Generate solid and hollow Rocks at low/high detail; change seed, Preview/Cancel, Apply, Undo/Redo. Check materials and optional group.
2. Sculpt a subdivided brush terrain across seams. Try Raise/Lower/Smooth, small/large radius, high intensity, protection on/off. Check hidden and locked objects remain unchanged.
3. Cancel a stroke with Escape and change tools mid-stroke; check ordinary brush movement still works. Undo/Redo whole strokes.
4. Array a brush, patch and point entity. Try multiple centred/crossed lines, mirrored offsets, concentric rings and random radius with each facing side. Check positions, materials, entity angles and Undo.
5. Save and reopen edited maps, then compile them. Check patches and brush entities remain present.
6. Repeat a dense generation operation and undo it several times; check for disconnects, crashes or console errors.
7. Compare the same operations on Windows and Linux. Existing mod preview and game profiles should still work.
