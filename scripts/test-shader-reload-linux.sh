#!/usr/bin/env bash
set -euo pipefail
bundle=$(realpath "$1")
engine=$(realpath "$2")
testdir=$(mktemp -d /tmp/ftebroom-shader-reload-XXXXXX)
cp -a "$bundle/." "$testdir/"
cp "$engine" "$testdir/fteqw64"
rm -f "$testdir/ftebroom/config.cfg" "$testdir/ftebroom/fte.cfg" "$testdir/ftebroom/qconsole.log"
cat > "$testdir/ftebroom/shader-reload.cfg" <<'EOF'
exec ftebroom.cfg
set ftebroom_skip_setup 1
in 8 echo SHADER_RELOAD_READY
in 14 set r_glsl_offsetmapping 1
in 17 echo SHADER_RELOAD_SURVIVED
in 18 quit
EOF
cd "$testdir"
xvfb-run -a timeout 45 ./fteqw64 -nohome -noupdates -basedir "$testdir" -window -width 1280 -height 800 -condebug +exec shader-reload.cfg > engine.log 2>&1 &
pid=$!
for ((i=0;i<120;i++)); do
    if grep -q SHADER_RELOAD_READY ftebroom/qconsole.log 2>/dev/null; then break; fi
    sleep .25
done
grep -q SHADER_RELOAD_READY ftebroom/qconsole.log
sed -i '/^!!cvarf/d' ftebroom/glsl/ftebroom_grid.glsl
wait "$pid"
grep -q SHADER_RELOAD_SURVIVED ftebroom/qconsole.log
echo "PASS: $testdir"
