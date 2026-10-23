#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency build root}
test=$(mktemp -d "$deps/build-test-XXXXXX")
editor="$test/editor"
mkdir -p "$editor/tools/q3map2" "$editor/tools/ericw"
cp -a "$src/runtime/." "$editor/ftebroom/"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$editor/"
cp "$src/csaddon.dat" "$editor/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$editor/"
cp "$deps/compilers/netradiant-custom-20260114/install/q3map2.x86_64" "$editor/tools/q3map2/q3map2"
for tool in qbsp vis light; do cp "$deps/compilers/ericw-build/$tool/$tool" "$editor/tools/ericw/"; done
cp "$deps/compilers/embree-build/libembree.so.2.17.7" "$editor/tools/ericw/libembree.so.2"
if [ -n "${FTEBROOM_PACKAGE:-}" ]; then cp -a "$FTEBROOM_PACKAGE/tools/." "$editor/tools/"; fi
python3 "$src/tests/make-linux-build-fixture.py" "$editor"
cd "$editor"
env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 timeout 70s xvfb-run -a -s '-screen 0 1280x800x24' ./fteqw-gl64 -ftebroom-child-processes -nohome -noupdates -window -width 1280 -height 800 -condebug +exec linux-build.cfg > "$test/q3-console.txt" 2>&1
if grep -E 'BUILD_FAIL|CSQC_Abort' ftebroom/qconsole.log; then exit 1; fi
grep 'BUILD_PASS automatic_bsp_preview_without_mod' ftebroom/qconsole.log
cp ftebroom/qconsole.log "$test/q3-checks.log"
cd "$src"
python3 tests/make-quake1-fixture.py "$test"
cd "$editor"
env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 timeout 95s xvfb-run -a -s '-screen 0 1280x800x24' ./fteqw-gl64 -ftebroom-child-processes -nohome -noupdates -window -width 1280 -height 800 -condebug +exec quake1-test.cfg > "$test/q1-console.txt" 2>&1
if grep -E 'BUILD_FAIL|CSQC_Abort' ftebroom/qconsole.log; then exit 1; fi
grep 'BUILD_PASS quake1_bsp2' ftebroom/qconsole.log
echo "PASS: native Linux Q3 and Q1 builds. $test"
