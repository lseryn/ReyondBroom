# Alpha 53: extended Bevel profiles

Open **Bevel** after selecting brushes, face boundaries or edges. The original profile still supports selected vertices. Repeated Preview now retains edge/vertex selections instead of losing them during temporary geometry rollback.

**Extended edge profile** adds **Curve** (-1 inward to +1 circular), **Proportion** (-0.95 to +0.95 asymmetric face widths), and the existing segment count (1–16). Radius / width is the distance along adjacent faces in this mode. A negative profile is decomposed into convex brushes; no concave brush is stored. Extended profiles are disabled for vertex mode. **Keep cut geometry** retains removed pieces in both profile modes, in the original entity container. All resulting pieces are selected. Apply is one document undo operation; Preview does not change document history.

Clamp is per source brush. The extended profile uses a conservative adjacent-face extent bound with clearance, rather than exact contact between arbitrary neighboring bevels. Decomposition topology can differ from UltimateTrenchBroom. The original profile still has its original convex half-space clamp. These differences remain in the parity ledger.

Limits: 32 source brushes, 16 segments per edge, 512 edge segments per brush, 10,000 partition operations and 2,048 resulting brushes. Individual brushes retain the engine's 64-plane limit. Rejected geometry rolls back the entire operation. Large selections can still take time; reduce segments or work on smaller selections.

## Checks

1. Select one edge with E, open Bevel, update Preview repeatedly, then Apply. Only that edge should be beveled. Undo/Redo restores the operation.
2. Repeat with a vertex selected in V and the original profile.
3. Select an entire brush or a face boundary. Test the original flat/round/square profile.
4. Enable Extended edge profile. Compare Curve -1, 0 and 1, and asymmetric Proportion values. Inspect the resulting convex pieces and materials.
5. Enable Keep cut geometry in both modes. Pieces should fill the original volume without duplicating intersecting volumes.
6. Try a very large width with Clamp enabled, then smaller widths. Clamp should preserve a valid result; unsupported cases report an error without partially editing the map.
7. Preview, cancel, select another brush and retry. Save/reopen the result. Repeat on Windows and Linux.

Automated engine checks cover actual generator command paths, repeated previews, edge/vertex selection, offcut volume conservation, inward Apply/Undo/Redo and large-width Clamp. Arch tests run under Xvfb, not a real Wayland desktop.
