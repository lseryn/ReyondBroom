#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/prefab56-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/prefab56.cfg" "$test/ftebroom/"
cp "$src/tests/fixtures/containers.map" "$test/collection.map"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +set ftebroom_test_import_root "$test" +vid_width 1280 +vid_height 800 +exec prefab56.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in collection one_instance two_unique_instances; do
 grep -q "DESKTOP_PASS prefab56_$name" console.txt
done
test "$(grep -c 'DESKTOP_PASS prefab56_two_unique_instances' console.txt)" = 3
echo "PASS: $test"
