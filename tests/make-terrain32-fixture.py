from pathlib import Path
import sys,json,shutil
root=Path(sys.argv[1]);editor=root/'editor/ftebroom';game=root/'mod';(game/'maps').mkdir(parents=True);(game/'textures').mkdir()
source=game/'maps/combined.map';source.write_text('// FTEBroom profile=when-the-sky-went-dark format=quake3\n'+(editor/'maps/start.map').read_text())
for base in (root/'editor',editor):
 (base/'ftebroom-project.txt').write_text(game.as_posix())
 (base/'ftebroom-game-profile.txt').write_text('0 0 '+json.dumps(game.as_posix())+' "" '+json.dumps((editor/'entities.ent').as_posix())+' ""\n')
text=source.read_text();patch="\n{\npatchDef2\n{\nftebroom/grid\n( 3 3 0 0 0 )\n(\n"
for y in range(3):
 patch+='( '+' '.join(f'( {x*64} {y*64} {200+(40 if x==1 else 0)} {x/2} {y/2} )' for x in range(3))+' )\n'
patch+=")\n}\n}\n"
source.write_text(text.replace('{','{'+patch,1))
target=game/'maps/saved-combined.map'
(editor/'terrain32.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
in 5 ftebroom_test_filepath open "{source.as_posix()}"
in 9 ftebroom_test_terrain32 1
in 12 ftebroom_test_filepath save "{target.as_posix()}"
in 14 ftebroom_camera_restore 2560 1600 650 35 90 0 90
in 16 screenshot terrain32.png
in 18 ftebroom_test_filepath open "{target.as_posix()}"
in 23 ftebroom_test_terrain32 0
in 24 ftebroom_test_filepath save "{target.as_posix()}"
in 28 quit force
''')
print(root)
