"""Private custom-profile build without a runtime mod; Q1 uses the existing fixture."""
from pathlib import Path
import sys, subprocess, shutil, json
root = Path(sys.argv[1]).resolve()
src = Path(__file__).resolve().parents[1]
editor = root/'ftebroom'
game = root/'baseq3'
game.mkdir(exist_ok=True)
shutil.copytree(src/'runtime/textures',game/'textures',dirs_exist_ok=True)
subprocess.run([sys.executable,str(src/'tests/make-build-fixture.py'),str(editor/'maps/build-fixture.map')],check=True)
for base in (root,editor):
    (base/'ftebroom-project.txt').write_text(str(game))
    (base/'ftebroom-game-profile.txt').write_text('1 0 "" "" "" "" 1\n')
(editor/'linux-build.cfg').write_text('''set ftebroom_skip_setup 1
exec ftebroom.cfg
in 7 mapedit maps/build-fixture.map
in 9 ftebroom_camera_restore 0 -160 96 0 90 0 90
in 11 ftebroom_test_build 0
in 30 ftebroom_test_build 1
in 32 screenshot linux-bsp.png
in 33 ftebroom_test_build 2
in 36 quit force
''')
