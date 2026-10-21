# Implementation progress — alpha.20

Alpha.20 fixes baseline rendering and interaction regressions; see [release notes](alpha20.md) and [verification checklist](checks-alpha20.md).

Scope: roadmap phases **0–15**. Phases 16–20 remain excluded. Dear ImGui remains the frontend.

The baseline tools from alpha.18 remain available. Alpha.19 closes the property-table interaction, smart-color, definition-model parameter, filter/action, vertex UV/feedback and layer-control gaps and fixes large-map loading, unselected submodel visibility and unstable MAP plane serialization. See [the release guide](alpha19.md), [full acceptance checklist](checks-alpha19.md), and [verification record](../TESTING.md).

Coverage by phase:

- **0:** action registry/context routing, tool lifecycle, document tree, transactional history, grid, picking, convex geometry validation/hull/split. The native performance proposal is the nonblocking follow-up explicitly allowed by task 0.7.
- **1:** camera flight/orbit/pan/zoom/focus, orthographic views, synchronized multi-view layouts and gestures.
- **2:** object/face/group selection, overlapping-object drill, selection visualization and selection commands.
- **3–4:** constrained brush drawing, movement, duplication, keyboard transforms, deletion and system clipboard MAP transfer.
- **5:** material browser/filtering, face attributes, texture alignment, attribute transfer, replacement and alignment locks.
- **6–7:** rotation/flip/pivot, entity orientation rules, Extrude/Split/Stamp and Move Face.
- **8–9:** interactive Clip and convex CSG operations with previews and atomic history.
- **10–11:** vertex/edge/face hull editing, shared handles, additions/deletion/snap, UV Lock, Scale/Shear and handle-scoped affine transforms.
- **12–13:** point-based convex brush assembly and validated primitive generation/replacement.
- **14:** definition loading, entity browser/placement, brush entities, spreadsheet-style properties, smart controls, links and transforms.
- **15:** nested groups, layers, visibility/locking, class/tag filters, compiler-facing MAP export and context actions.

The 64-face limit and class-bounds browser previews follow the roadmap's permitted bounded implementations. Definition model descriptors are not an arbitrary expression-language interpreter. Existing patch data remains supported; no patch construction/control-point editor was added. Automated tests are evidence for the covered cases, not a claim that every possible map or mouse sequence is bug-free.
