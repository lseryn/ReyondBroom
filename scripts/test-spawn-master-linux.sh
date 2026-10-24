#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/spawn49-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/spawn49.cfg" "$test/ftebroom/"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec spawn49.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in spawn49_definition_cache spawn49_create spawn49_six_walls spawn49_source_link spawn49_destination_link spawn49_single_undo spawn49_redo spawn49_shared_expansion spawn49_unique_targets spawn49_expansion_undo spawn49_missing_destination spawn49_invalid_class spawn49_stale_selection spawn49_reconfigure spawn49_reload_metadata spawn49_reload_reconfigure; do
 grep -q "TRANSFORM_PASS $name" console.txt
done
echo "PASS: $test"
