"""Check geometry acceptance, benchmark completion and document immutability."""
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
log = (root / "qconsole.log").read_text(errors="replace")
assert "FTEBROOM_GEOM_FAIL" not in log, log[-16000:]
assert "mod by zero" not in log
expected = [
    "cube_topology", "cube_volume", "cube_plane_and_uv_roundtrip",
    "hull_cube_interior_duplicate", "hull_fractional_coordinates",
    "split_equal_volumes", "split_preserves_uv_and_initializes_cut",
    "oblique_split_conserves_volume", "tangent_noop", "outside_noop",
    "zero_split_normal", "reject_flat", "reject_duplicate_plane",
    "reject_unbounded", "reject_face_limit", "reject_tiny_volume",
    "reject_zero_normal", "reject_world_bounds", "reject_collinear_hull",
    "reject_flat_hull", "tetrahedron_hull", "full_64_face_prism", "batch_500_boxes", "rotated_permuted_hull", "split_64_face_prism", "document_brush_conversion",
]
for check in expected:
    assert f"FTEBROOM_GEOM_PASS {check}" in log, check
assert "FTEBROOM_GEOM_COMPLETE" in log
assert (root / "maps/geometry_before.map").read_bytes() == (root / "maps/geometry_after.map").read_bytes()
benchmarks = re.findall(r"FTEBROOM_GEOM_BENCH ([^\r\n]+)", log)
assert len(benchmarks) == 2
assert "valid=10" in benchmarks[0] and "valid=500" in benchmarks[1]
print(f"PASS: {len(expected)} geometry checks and unchanged MAP bytes.")
print("\n".join(benchmarks))

