#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
ad=${2:?Arcane Dimensions directory}
libre=${3:?LibreQuake directory}
if [ "${4:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" "$ad" "$libre" inside; fi
test=$(mktemp -d "$deps/mods63-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
python3 "$src/tests/make-mods63-test.py" "$test" "$ad" "$libre"
cd "$test"
openbox > wm.log 2>&1 &
wm=$!
trap 'kill "$wm" 2>/dev/null || true' EXIT
sleep 1
LIBGL_ALWAYS_SOFTWARE=1 timeout 120s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +exec mods63.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|MAX_MOD_KNOWN' console.txt; then exit 1; fi
for name in mods63_resources_ready mods63_model_rendered mods63_palette_and_materials mods63_player_resource; do
 test "$(grep -c "PASS $name" console.txt)" = 6
done
test "$(grep -c FTEBROOM_REGISTRY_PASS console.txt)" = 2
echo "PASS: $test"
