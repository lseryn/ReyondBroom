#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/filters66-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$src"/tests/filters66*.cfg "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cd "$test"
openbox >wm.log 2>&1 &
wm=$!
trap 'kill "$wm" 2>/dev/null || true' EXIT
for cfg in filters66.cfg filters66-restart.cfg; do
    env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 timeout 120s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec "$cfg" >>console.txt 2>&1
done
python3 "$src/tests/check-filters66.py" "$test/ftebroom/qconsole.log"
echo "PASS: $test"
