"""Validate grid input, snapping and exported geometry in a disposable engine."""
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
log = (root / "qconsole.log").read_text(errors="replace")
assert "FTEBROOM_GRID_FAIL" not in log, log[-12000:]
expected = [f"key_{i}" for i in range(1, 10)] + [
    "negative_fraction", "up_down", "inclined_plane", "plane_grid_axis",
    "extrude_vertex_candidate", "angle", "snap_disabled", "plane_disabled",
    "rounding_disabled", "extrude_disabled", "upper_bound", "keypad_minus",
    "keypad_plus", "minus", "shift_plus", "lower_bound", "fraction_step",
    "half_step", "plus", "legacy_wheel", "modified_wheel", "modified_down",
    "plain_wheel_disabled", "inverted_wheel", "toggles", "text_guard",
    "fractional_brush", "fractional_mouse_offset"]
for name in expected:
    assert "FTEBROOM_GRID_PASS " + name in log, name
def data(name):
    return (root / "maps" / f"grid_{name}.map").read_bytes()
assert data("before") == data("undo"), "Unsnapped movement Undo changed the MAP"
assert data("before") != data("after"), "Unsnapped movement did not move geometry"
faces = re.findall(rb"^\( .+$", data("fractional"), re.M)
assert len(faces) == 12, "Fractional brush missing"
points = [tuple(map(float, xyz)) for f in faces[6:] for xyz in
          re.findall(rb"\( ([-\d.]+) ([-\d.]+) ([-\d.]+) \)", f)]
for axis in range(3):
    assert abs(max(p[axis] for p in points)-min(p[axis] for p in points)-.125)<1e-5
assert "ambiguous shortcut" not in log
assert (root / "grid.png").is_file()
print(f"PASS: {len(expected)} grid checks, fractional brush, unsnapped gesture and byte-identical Undo.")
