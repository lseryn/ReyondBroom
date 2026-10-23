"""Exercise actual textured thumbnails across the 16-bit ImGui index boundary."""
from pathlib import Path
import sys, runpy, struct
root = Path(sys.argv[1]).resolve()
runpy.run_path('tests/make-alpha30-fixture.py', run_name='__main__')
path = root/'id1/models/qa/test.md3'
old = path.read_bytes()
surfaces = []
for start in (108, 344):
    source = old[start:start+236]
    count = 12000
    triangles = source[108:120] * count
    surface = bytearray(source[:108])
    surface.extend(triangles)
    surface.extend(source[120:])
    struct.pack_into('<i', surface, 84, count)
    struct.pack_into('<5i', surface, 88, 108, 108+len(triangles), 176+len(triangles), 200+len(triangles), len(surface))
    surfaces.append(surface)
header = bytearray(old[:108])
struct.pack_into('<i', header, 104, 108+sum(map(len,surfaces)))
path.write_bytes(header+b''.join(surfaces))
runpy.run_path('tests/make-model33.py')['write_model'](root/'id1/models/qa/skeleton.iqm')
entries=[('models/qa/skeleton.iqm',(root/'id1/models/qa/skeleton.iqm').read_bytes()),('sound/ambient/test.wav',b'fixture')]
payload=b'';directory=b''
for name,content in entries:
    directory+=struct.pack('<56sII',name.encode(),12+len(payload),len(content));payload+=content
(root/'id1/explorer.pak').write_bytes(struct.pack('<4sII',b'PACK',12+len(payload),len(directory))+payload+directory)
(root/'id1/maps').mkdir(exist_ok=True)
(root/'id1/maps/wad-external.map').write_bytes((root/'editor/ftebroom/maps/build-fixture.map').read_bytes())
(root/'editor/ftebroom/ui34.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{root.as_posix()}"
in 7 ftebroom_test_desktop modelindices34
in 9 screenshot modelindices34.png
in 10 ftebroom_test_desktop viewer34
in 16 ftebroom_test_desktop viewer34check
in 17 screenshot animated34.png
in 18 ftebroom_test_desktop pak34
in 21 screenshot pak34.png
in 22 ftebroom_test_desktop recent33
in 24 screenshot recent34.png
in 25 quit force
''')
