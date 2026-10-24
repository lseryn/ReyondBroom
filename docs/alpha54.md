# Alpha 54: symmetry placement, guides and relinking

Open **Edit → Symmetry → Settings…**. Choose a plane angle in whole degrees, optionally enable a custom XYZ center, then choose 2/4/8 mirrored or rotated sides. Settings are saved. Existing symmetry sets retain their stored center when reconfigured without a custom center. The center and angle are saved in MAP metadata.

**Show symmetry guides** draws cyan rays and a vertical axis for the selected symmetry group or an opened side. The geometry/bounds cache refreshes on document, selection, filter or visibility changes; drawing does not rescan the map every frame. These guides represent the stored symmetry setup. Arbitrary later transforms of whole instances do not automatically redefine that setup.

**Relink matching existing groups** is enabled by default. Select exactly one unlinked group; matching sibling groups are searched before creating new copies. A complete set of 2/4/8 sides is required. Matching checks hierarchy, brush vertex positions, mirrored patch control points, entity class and transformed origin. Relinking changes metadata only and leaves existing geometry/IDs intact. Subsequent edits use the normal linked-group synchronization, including unprotected entity properties and materials. Thus groups with differing non-geometric properties can become synchronized after an edit. Turn relinking off when new copies are desired.

If a complete match is absent, the ordinary copy workflow runs. This is more conservative than Ultimate's bounds-only matching of some container types. Already-linked/nested linked sets are not automatically adopted. Limits: 8,192 document nodes for the matching attempt, 32 hierarchy levels, 1,024 siblings/control points, 16 bounds candidates per side, 20,000 node comparisons and a bounded scan budget. Exact interaction parity remains under review; this is not a claim that all upstream features have been transferred.

Bevel preview also restores the active edge/vertex tool, avoiding leftover inactive handles after closing its panel.

## Checks

1. Create symmetry with 2, 4 and 8 sides; test both mirror and rotation modes. Open any side and edit its contents. Other sides should update; Undo/Redo should restore changes.
2. Set a custom center away from the selection and angle 90 degrees. Inspect mirror placement. Reconfigure with custom center disabled: the stored center should remain fixed.
3. Save/reopen the MAP and check center metadata, guides and linked editing.
4. Select/open a symmetry group, then deselect it. Toggle guides, switch 2D/3D views and hide/show the group. Guides should follow visibility and selection without repeated map scans.
5. Create two separate matching groups across a chosen center. Select one and enable relinking. Applying two-sided symmetry should reuse both groups without duplicate geometry. Edit the opposite group and check synchronization. Undo should remove the link.
6. Try nonmatching groups or disable relinking: ordinary new-copy behavior should remain available. Check differing materials/entity properties before choosing to link them.
7. Test mirrored patches and nested groups. Repeat on Windows and Linux.

Automated tests cover existing symmetry regressions, custom placement, guide state, preserved pivots, metadata reload, relink identity preservation, reverse synchronization and patch match/mismatch. Arch Linux tests run under Xvfb; real Wayland interaction is not claimed tested here.
