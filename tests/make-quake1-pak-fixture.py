from pathlib import Path
import json, struct, sys, runpy
root = Path(sys.argv[1]).resolve()
sys.argv = ['make-quake1-fixture.py', str(root)]
runpy.run_path('tests/make-quake1-fixture.py', run_name='__main__')
editor = root / 'editor/ftebroom'
entries = {
    'maps/room.map': (editor / 'maps/build-fixture.map').read_bytes(),
    'textures/test.wad': (root / 'id1/test textures.wad').read_bytes(),
    'other/keep.bin': b'unchanged\x00\xff payload',
}
data = bytearray(b'PACK' + bytes(8)); directory = bytearray()
for name, payload in entries.items():
    directory += struct.pack('<56sII', name.encode(), len(data), len(payload))
    data += payload
struct.pack_into('<II', data, 4, len(data), len(directory)); data += directory
(root / 'id1/pak2.pak').write_bytes(data)
(root / 'id1/test textures.wad').unlink()  # Fixture only: prove packed WAD discovery.
for base in (root/'editor', editor):
    values = [(root/'id1').as_posix(), '', '', '']
    (base/'ftebroom-quake1.txt').write_text(' '.join(json.dumps(v) for v in values)+' 0 0 "" 1\n')
(editor/'pak-test.cfg').write_text('set ftebroom_test_archive '+json.dumps((root/'id1/pak2.pak').as_posix())+'\n'+'''exec ftebroom.cfg
set ftebroom_skip_setup 1
in 8 mod_terrain_save "" starter-quake1
in 10 ftebroom_test_build 50
in 15 ftebroom_test_build 51
in 18 ftebroom_test_build 52
in 35 ftebroom_test_build 53
in 38 screenshot pak-entities.png
in 40 ftebroom_test_build 54
in 41 ftebroom_test_build 21
in 49 ftebroom_test_build 30
in 50 ftebroom_test_build 31
in 53 ftebroom_test_build 34
in 55 ftebroom_test_build 35
in 57 ftebroom_test_build 36
in 59 ftebroom_test_build 32
in 61 ftebroom_test_build 33
in 63 ftebroom_test_build 55
in 65 ftebroom_test_build 56
in 66 screenshot pak-browser.png
in 68 quit force
''')
