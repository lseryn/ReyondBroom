#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/media42-XXXXXX")
echo "$test" > "$deps/media42-current"
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
python3 "$src/tests/make-media42-fixture.py" "$test"
cd "$test"
LIBGL_ALWAYS_SOFTWARE=1 timeout 50s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_renderer gl +exec media42.cfg > console.txt 2>&1
python3 "$src/tests/check-media42.py" "$test"
echo "Results: $test"
