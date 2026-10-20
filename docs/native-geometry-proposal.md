# Follow-up proposal: native geometry buffer API

[Русский](native-geometry-proposal.ru.md)

Status: proposed, not implemented. Trigger: QC validation of a 64-face prism measured about 4.9 ms, exceeding task 0.7's 2 ms target.

Add a versioned engine builtin `brush_geometry_op(operation, inputPointer, inputBytes, outputPointer, outputCapacity)` with a separate required-size query. Never transfer face/vertex arrays through cvars. The engine must validate all QC pointer ranges, sizes, finite values and overflow before accessing the buffer.

Use fixed-width numeric records for positions, plane equations, topology and source-face indices. Do not pass QC string handles to worker code. Keep material strings, UV attributes and history ownership in QC; return a source-face index or "new face" so QC can assign attributes consistently.

First operations: reconstruct/validate a half-space polyhedron, build a convex hull and split a polyhedron. Return explicit status, required bytes, actual counts and an error code. Build the geometry in temporary storage; the operation must never mutate map objects. QC applies successful results inside the existing transaction.

Use double-precision calculations internally, then validate the float result using the documented merge/plane tolerances. Establish a maximum input/output budget and reject excess size instead of truncating. Keep the QC implementation as a reference and fallback.

Acceptance: run the same cube, rotated/fractional hull, malformed input, 64-face prism, UV/source-face and split-volume cases against both paths; add invalid-buffer/overflow tests; benchmark at least 100 complex-brush operations and 500 separate brushes. Measure API marshalling and allocation, not just the arithmetic. Target less than 2 ms per operation on the agreed Windows reference machine, with latency percentiles reported. Land the engine patch and regression tests together.
