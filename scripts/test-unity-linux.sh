#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/unity51-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/tests/fixtures/unity.map" "$test/ftebroom/maps/unity.map"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/unity51.cfg" "$test/ftebroom/"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec unity51.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in manifest geometry_uv importer texture_copy lock_removed unowned_guard resync; do
 grep -q "DESKTOP_PASS unity51_$name" console.txt
done
test "$(grep -c '^f ' "$test/ftebroom/data/unity.obj")" -ge 128
echo "PASS: $test"
