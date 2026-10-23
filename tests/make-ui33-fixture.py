from pathlib import Path
import sys,runpy,struct
root=Path(sys.argv[1]).resolve()
runpy.run_path('tests/make-alpha30-fixture.py',run_name='__main__')
game=root/'id1';(game/'textures').mkdir(exist_ok=True)
# Valid frame bounds are required by the engine model viewer (tiles use mesh data).
p=game/'models/qa/test.md3';old=p.read_bytes();frame=struct.pack('<10f16s',-30,0,0,35,0,45,0,0,0,60,b'pose')
header=bytearray(old[:108]);struct.pack_into('<3i',header,96,164,164,len(old)+56);body=bytearray(old[108:])
# Front-facing triangles for the initial orbit camera.
for start in (0,236):struct.pack_into('<3i',body,start+108,2,1,0)
p.write_bytes(header+frame+body)
runpy.run_path('tests/make-model33.py')['write_model'](game/'models/qa/skeleton.iqm')
(root/'editor/ftebroom/ui33.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{root.as_posix()}"
in 4 ftebroom_test_desktop recent33
in 6 screenshot recent33.png
in 7 ftebroom_test_desktop viewer33
in 11 ftebroom_test_desktop viewer33check
in 12 screenshot viewer33.png
in 14 ftebroom_test_desktop viewer33iqm
in 18 ftebroom_test_desktop viewer33iqmcheck
in 19 screenshot bones33.png
in 20 ftebroom_test_desktop material33
in 25 ftebroom_test_desktop material33check
in 26 screenshot material33.png
in 27 ftebroom_test_desktop profile33
in 31 ftebroom_test_desktop profile33check
in 32 screenshot profile33.png
in 33 ftebroom_test_drag distance33
in 35 quit force
''')
