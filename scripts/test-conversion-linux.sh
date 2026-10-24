#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/conversion50-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/conversion50.cfg" "$test/ftebroom/"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec conversion50.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in conversion50_face_segments conversion50_face_orientation_volume conversion50_rotated_grid conversion50_auto_texture_face conversion50_subdivision_cancel conversion50_independent_brushes conversion50_group_cluster conversion50_single_undo conversion50_redo conversion50_empty_space_rejected subdivision44_texture_cell_scale subdivision44_texture_volume conversion50_rock_per_source_group conversion50_rock_cancel conversion50_rock_entity_protected; do
 grep -q "TRANSFORM_PASS $name" console.txt
done
for name in undo redo branch history_budget defaults; do test "$(grep -c "DESKTOP_PASS generator50_$name" console.txt)" = 8; done
echo "PASS: $test"
