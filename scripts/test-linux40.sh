#!/usr/bin/env bash
# Run in an isolated Arch Linux userspace, with Weston nested on Xvfb.
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/linux40-XXXXXX")
echo "$test" > "$deps/linux40-current"
export XDG_RUNTIME_DIR="$test/session" WAYLAND_DISPLAY=ftebroom-test
mkdir -m 700 "$XDG_RUNTIME_DIR"
weston --backend=x11 --renderer=pixman --socket="$WAYLAND_DISPLAY" --width=1440 --height=1000 --log="$test/weston.log" > "$test/weston-console.txt" 2>&1 &
compositor=$!
trap 'kill "$compositor" 2>/dev/null || true' EXIT
for i in $(seq 1 50); do [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] && break; sleep .1; done
mkdir -p "$test/editor"
cp -a "$src/runtime" "$test/editor/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/editor/"
cp "$src/csaddon.dat" "$test/editor/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/editor/"
cd "$src"
python3 tests/make-linux40-fixture.py "$test"
cd "$test/editor"
LIBGL_ALWAYS_SOFTWARE=1 timeout 70s ./fteqw-gl64 -ftebroom-child-processes -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_renderer wlgl +exec linux40.cfg > "$test/console.txt" 2>&1 &
editor=$!
sleep 12
GDK_BACKEND=wayland python3 "$src/tests/wayland-drop-source.py" "$test/external Текстуры/drag test.wad" > "$test/drop-source.log" 2>&1 &
source=$!
sleep 3
magick import -window root "$test/desktop-before.png"
echo "DISPLAY=$DISPLAY TEST=$test" > "$deps/linux40-display"
# These coordinates match the fixed 1440x1000 nested Weston fixture above.
xdotool mousemove 920 580 mousedown 1 sleep .3 mousemove 900 560 sleep .3 mousemove 700 500 sleep .3 mousemove 500 400 sleep .5 mouseup 1
sleep 2
for i in $(seq 1 8); do
  xdotool mousemove 1011 350 sleep .1 mousemove 500 400 sleep .1 mousemove 500 646 sleep .1
done
xdotool mousemove 1011 350
sleep 1
magick import -window root "$test/cursor-resize.png"
sleep 10
magick import -window root "$test/desktop-after.png"
wait "$editor"
kill "$source" 2>/dev/null || true
if grep -E 'DESKTOP_FAIL|ENTITY_FAIL|CSQC_Abort|Unknown command' "$test/console.txt"; then exit 1; fi
grep 'DESKTOP_PASS single_mod_resources' "$test/console.txt"
grep 'DESKTOP_PASS palette_from_mod_pak' "$test/console.txt"
grep 'DESKTOP_PASS wayland_external_wad_imported' "$test/console.txt"
grep 'DESKTOP_PASS dropped_wad_material_indexed' "$test/console.txt"
echo "PASS $test"
