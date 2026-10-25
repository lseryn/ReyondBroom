#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/external69-XXXXXX")
mkdir "$test/editor"
cp -a "$src/runtime" "$test/editor/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/editor/"
cp "$src/csaddon.dat" "$test/editor/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/editor/"
python3 "$src/tests/make-external69-fixture.py" "$test"
cd "$test/editor"
for cfg in external69.cfg external69-restart.cfg; do
 env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 timeout 90s ./fteqw-gl64 -ftebroom-child-processes -nohome -noupdates -window -width 1280 -height 800 -condebug +exec "$cfg" >> console.txt 2>&1
done
python3 "$src/tests/check-external69.py" "$test"
echo "PASS: $test"
