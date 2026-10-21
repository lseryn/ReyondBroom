# Implementation progress after alpha.15

The current release batch is documented in [alpha.16 features](alpha16.md), with a [combined manual checklist](checks-alpha16.md). The user requested finishing and publishing the current stage on 2026-10-20; development does not proceed into the next stage in this batch.

Implemented: selection commands, box creation, mixed-object transforms and duplication, group/model allocation, MAP clipboard, 32-bit surface metadata, material editing/replacement/transfer/alignment, affine transforms, interactive Rotate, ordinary Extrude, Split and Stamp. Tests and known limitations are recorded in [TESTING](../TESTING.md) and the release notes.

Pending: Move Face (7.3, requires the later vertex kernel), advanced Clip interactions, CSG commands, vertex/edge/face editing, Scale/Shear, point-based brush construction, primitive tools, entity definition workflows, full layers/groups/visibility workflows, linked groups, patch control-point editing, Sweep, UV editor and final productivity/export/preferences work. Rotate pivot history, some entity/model convention edge cases and material-browser refinements remain. Toolbar/menu placeholders are not implemented tools.

## Appearance update (alpha.17)

A separate UI update adds the dark palette, docking, scalable fonts, resizable dialogs and persistent workspace settings. See [usage and checks](alpha17.md). This does not advance the geometry roadmap.
