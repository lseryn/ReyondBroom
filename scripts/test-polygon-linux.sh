#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/polygon47-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/polygon47.cfg" "$test/ftebroom/"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec polygon47.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in polygon47_convex_merge polygon47_spawn_volume polygon47_concave_partition polygon47_reverse_winding polygon47_reject_self_intersection polygon47_collinear_point polygon47_cut_preview polygon47_cut_depth polygon47_keep_cutout polygon47_apply polygon47_single_undo polygon47_spawn_apply polygon47_spawn_undo polygon47_pointer_points polygon47_click_close polygon47_drag_point polygon47_escape_drag polygon47_reopen_contour polygon47_remove_point polygon47_cancel_tool symmetry47_create symmetry47_four_sides symmetry47_single_undo symmetry47_edit_sync symmetry47_edit_single_undo symmetry47_reverse_edit symmetry47_reconfigure_rotation symmetry47_reconfigure_undo symmetry47_two_sides polygon47_persistent_preview symmetry47_reload_metadata symmetry47_reload_sync; do
 grep -q "TRANSFORM_PASS $name" console.txt
done
echo "PASS: $test"
