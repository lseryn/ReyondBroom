#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 640x480x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/grid-depth-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/grid-depth.cfg" "$test/ftebroom/"
cp "$src/tests/fixtures/grid-depth.map" "$test/ftebroom/maps/"
cd "$test"
env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 timeout 60s ./fteqw-gl64 -ftebroom-child-processes -nohome -noupdates -window -width 640 -height 480 -condebug +vid_width 640 +vid_height 480 +exec grid-depth.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
python3 "$src/tests/check-grid-depth.py" "$test/ftebroom"
echo "PASS: $test"
