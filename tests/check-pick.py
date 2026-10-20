"""Picking must preserve map data and respect geometry, hierarchy and screen size."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / "qconsole.log").read_text(errors="replace")
assert "mod by zero" not in log
assert "FTEBROOM_PICK_FAIL" not in log, log[-14000:]
checks = [
    "three_brushes", "distance_order", "entry_plane", "hidden_filter",
    "hidden_override", "locked_parent_filter", "locked_override",
    "inside_brush_exit", "parallel_miss", "handle_five_pixels",
    "handle_outside_radius", "curved_patch_surface", "patch_normal", "point_entity_bounds",
    "near_selected_edge", "near_back_face", "perspective_nearest",
    "orthographic_smallest", "entity_click", "entity_selection_undo", "patch_click", "orthographic_click", "entity_view_selection", "entity_escape", "entity_deselect_undo"]
for name in checks:
    assert "FTEBROOM_PICK_PASS " + name in log, name
assert (root / "maps/pick_before.map").read_bytes() == (root / "maps/pick_after.map").read_bytes()
assert (root / "pick.png").is_file()
assert (root / "pick-entity.png").is_file()
print(f"PASS: {len(checks)} picking checks and unchanged MAP bytes.")
