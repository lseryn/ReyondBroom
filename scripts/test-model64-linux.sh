#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
deps=${1:?Dependency directory}
if [ "${2:-}" != inside ]; then exec xvfb-run -a -s '-screen 0 1440x1000x24' bash "$0" "$deps" inside; fi
test=$(mktemp -d "$deps/model64-XXXXXX")
cp -a "$src/runtime" "$test/ftebroom"
cp "$src/runtime/default.fmf" "$src/runtime/installed.lst" "$test/"
cp "$src/csaddon.dat" "$test/ftebroom/"
cp "$deps/fteqw/engine/release-linux/fteqw-gl64" "$deps/fteplug_ftebroom_amd64.so" "$test/"
cp "$src/tests/model64.cfg" "$test/ftebroom/"
cp -a "$deps/model64-fixtures" "$test/ftebroom/fixtures"
mkdir -p "$test/ftebroom/models/qa" "$test/ftebroom/gfx"
cp "$deps/model64-fixtures/halflife.mdl" "$test/ftebroom/models/qa/"
python3 - "$test" <<'PY'
import sys
from pathlib import Path
root=Path(sys.argv[1])/'ftebroom'
palette=bytearray(768);palette[3]=255;palette[7]=255
(root/'gfx/palette.lmp').write_bytes(palette)
with (root/'model64.cfg').open('a') as f:f.write('set ftebroom_test_import_root "'+str(root)+'"\n')
PY
cd "$test"
openbox > wm.log 2>&1 &
wm=$!
trap 'kill "$wm" 2>/dev/null || true' EXIT
sleep 1
LIBGL_ALWAYS_SOFTWARE=1 timeout 150s ./fteqw-gl64 -nohome -noupdates -window -width 1280 -height 800 -condebug +vid_width 1280 +vid_height 800 +exec model64.cfg > console.txt 2>&1
if grep -E '_FAIL|CSQC_Abort|runaway loop error|mod by zero|Outgoing message overflow' console.txt; then exit 1; fi
for name in model64_blender_mdl_bounds_frames model64_embedded_texture model64_md3_texture_portable model64_halflife_converted model64_two_skins_detected model64_skin_selection; do
 grep -q "DESKTOP_PASS $name" console.txt
done
echo "PASS: $test"
