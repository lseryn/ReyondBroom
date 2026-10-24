#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/bend46-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/bend46.cfg" "$test/ftebroom/"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec bend46.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in autosnap46_integral autosnap46_one_undo autosnap46_preserves_thin_brush subtract46_regular_cells_volume subtract46_source_materials subtract46_single_undo subtract46_redo subtract46_rotated_fallback subtract46_grid_budget_fallback bend46_capture_straight bend46_subdivision_volume bend46_keep_joints_preview bend46_scale_rotation bend46_rigid_pieces bend46_apply bend46_single_undo bend46_cancel_handle bend46_cancel_tool bend46_drag_preview bend46_escape_drag bend46_release_keeps_preview bend46_local_undo bend46_local_redo bend46_gesture_cancel_tool; do
 grep -q "TRANSFORM_PASS $name" console.txt
done
echo "PASS: $test"
