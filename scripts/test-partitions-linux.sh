#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/partitions44-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/partitions44.cfg" "$test/ftebroom/partitions44.cfg"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 60s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec partitions44.cfg > console.txt 2>&1
if grep -E 'TRANSFORM_FAIL|DESKTOP_FAIL|CSQC_Abort|runaway loop error|mod by zero' console.txt; then exit 1; fi
for name in inset44_wider_back_preserved subdivision44_texture_cell_scale subdivision44_texture_volume settle44_stale_result_rejected inset44_inner_and_four_borders inset44_volume_conserved inset44_undo inset44_invalid_atomic subdivision44_six_pieces subdivision44_world_cells subdivision44_budget spin44_segment_count spin44_straight_volume spin44_preserves_source spin44_undo spin44_curve_rotate_scale settle44_applied_contact settle44_single_undo settle44_redo; do
 grep -q "TRANSFORM_PASS $name" console.txt
done
grep -q 'FTEBROOM_DESKTOP_PASS settle44_async_preview' console.txt
echo "PASS: $test"
