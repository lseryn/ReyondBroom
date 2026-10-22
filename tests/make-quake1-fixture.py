from pathlib import Path
import struct,runpy,sys,json
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path('../ftebroom-q1-test').resolve()
root.mkdir(exist_ok=True)
game=root/'id1';(game/'gfx').mkdir(parents=True,exist_ok=True)
(game/'gfx/palette.lmp').write_bytes(bytes(v for n in range(256) for v in (n,n,255-n)))
name=b'q1test'+b'\0'*10
pixels=b''.join(bytes(64 if ((x//8)^(y//8))&1 else 200 for y in range(64>>m) for x in range(64>>m)) for m in range(4))
lump=name+struct.pack('<6I',64,64,40,40+4096,40+4096+1024,40+4096+1024+256)+pixels
wad=struct.pack('<4s2I',b'WAD2',1,12+len(lump))+lump+struct.pack('<3I4B16s',12,len(lump),len(lump),68,0,0,0,name)
(game/'test textures.wad').write_bytes(wad)
editor=root/'editor/ftebroom';(editor/'maps').mkdir(parents=True,exist_ok=True)
sys.argv=['make-build-fixture.py',str(editor/'maps/build-fixture.map')];runpy.run_path('tests/make-build-fixture.py',run_name='__main__')
p=editor/'maps/build-fixture.map';p.write_text(p.read_text().replace('ftebroom/grid','q1test').replace('info_player_deathmatch','info_player_start').replace('1 1 0 0 0','1 1'))
for base in (root/'editor',editor):
 (base/'ftebroom-project.txt').write_text(game.as_posix())
 (base/'ftebroom-game-profile.txt').write_text('2 0 "" "" "" ""\n')
 vals=[str(game.as_posix()),'',str((game/'test textures.wad').as_posix()),'']
 (base/'ftebroom-quake1.txt').write_text(' '.join(json.dumps(s) for s in vals)+' 0 0 ""\n')
(editor/'quake1-test.cfg').write_text('''exec ftebroom.cfg
set ftebroom_skip_setup 1
in 7 mapedit maps/build-fixture.map
in 9 ftebroom_camera_restore 0 -160 96 0 90 0 90
in 10 screenshot quake1-map.png
in 11 ftebroom_test_build 40
in 25 ftebroom_test_build 41
in 28 screenshot quake1-bsp.png
in 29 ftebroom_test_build 42
in 32 ftebroom_test_build 43
in 42 ftebroom_test_build 44
in 55 ftebroom_test_build 45
in 56 screenshot quake1-final.png
in 58 quit force
''')
print(root)
