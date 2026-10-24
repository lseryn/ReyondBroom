#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/wall59-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/wall59.cfg" "$src/tests/wall59-reload.cfg" "$test/ftebroom/"
cd "$test"
for config in wall59.cfg wall59-reload.cfg; do
LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec "$config" > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
if [ "$config" = wall59.cfg ]; then names="unicode_selection save override program source_unchanged missing empty q3_isolated q1_isolated"; else names="persisted_restart restart_apply"; fi
for name in $names; do grep -q "DESKTOP_PASS wall59_$name" console.txt; done
done
echo "PASS: $test"
