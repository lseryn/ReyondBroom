from pathlib import Path
import json, runpy, struct, sys
root=Path(sys.argv[1]).resolve()
runpy.run_path('tests/make-quake1-fixture.py',run_name='__main__')
game=root/'id1'
entries={'gfx/palette.lmp':(game/'gfx/palette.lmp').read_bytes(), 'profile-priority.txt':b'base'}
header=struct.pack('<4si3f3ff3f8if',b'IDPO',6,1,1,1,-20,0,0,64,0,0,0,1,16,16,3,2,1,0,0,1)
skin=struct.pack('<i',0)+bytes(64 if (x//4+y//4)%2 else 200 for y in range(16) for x in range(16))
uv=b''.join(struct.pack('<3i',0,u,v) for u,v in [(0,0),(15,0),(0,15)])
frame=struct.pack('<i',0)+bytes([0,0,0,0,40,0,60,0])+b'frame'+bytes(11)+bytes([0,0,0,0,40,0,0,0,0,0,60,0])
entries['progs/player.mdl']=header+skin+uv+struct.pack('<8i',1,0,1,2,1,2,1,0)+frame
payload=bytearray();directory=bytearray()
for name,data in entries.items():
    directory.extend(struct.pack('<56sII',name.encode(),12+len(payload),len(data)))
    payload.extend(data)
(game/'pak0.pak').write_bytes(struct.pack('<4sII',b'PACK',12+len(payload),len(directory))+payload+directory)
(game/'gfx/palette.lmp').unlink()
mod=root/'custom-mod';mod.mkdir(exist_ok=True)
(mod/'profile-priority.txt').write_text('mod')
(mod/'pak0.pak').write_bytes((game/'pak0.pak').read_bytes())
(mod/'test textures.wad').write_bytes((game/'test textures.wad').read_bytes())
external=root/'external Текстуры';external.mkdir(exist_ok=True)
# Replace both fixed-size texture names, preserving directory and mip offsets.
data=(game/'test textures.wad').read_bytes().replace(b'q1test'+b'\0'*10,b'droptest'+b'\0'*8)
(external/'drag test.wad').write_bytes(data)
for base in (root/'editor',root/'editor/ftebroom'):
    values=[str(game),str(mod),'','']
    (base/'ftebroom-quake1.txt').write_text(' '.join(json.dumps(s) for s in values)+' 0 0 "" 0\n')
(root/'editor/ftebroom/linux40.cfg').write_text('''set ftebroom_skip_setup 1
exec ftebroom.cfg
in 7 mapedit maps/build-fixture.map
in 10 ftebroom_test_desktop linux40
in 11 ftebroom_test_scene40
in 12 ftebroom_camera_restore 0 -220 120 10 90 0 90
in 45 ftebroom_test_desktop linux40drop
in 46 screenshot linux40.png
in 50 quit force
''')
