#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency build root}
bundle="$deps/smoke"
mkdir -p "$bundle"
cp -a "$src/runtime/." "$bundle/ftebroom/"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$bundle/"
cp "$src/csaddon.dat" "$src/tests/generators.cfg" "$bundle/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$bundle/"
cd "$bundle"
env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 timeout 50s xvfb-run -a -s '-screen 0 1280x800x24' ./fteqw-gl64 -ftebroom-child-processes -nohome -noupdates -window -width 1280 -height 800 -condebug +exec generators.cfg
if grep -E 'FTEBROOM_.*_FAIL|CSQC_Abort' ftebroom/qconsole.log; then exit 1; fi
grep 'PASS preview_cancel_restores_original' ftebroom/qconsole.log
