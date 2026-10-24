from pathlib import Path
import sys,json
root=Path(sys.argv[1]);editor=root/'editor/ftebroom';game=root/'mod'
(game/'textures').mkdir(parents=True,exist_ok=True)
(game/'maps').mkdir(exist_ok=True)
source=game/'maps/terrain.map'
source.write_text('''// ReyondBroom profile=when-the-sky-went-dark format=fte-terrain
{
"classname" "worldspawn"
"_segmentsize" "1024"
"_forcedefault" "1"
"_minxsegment" "-1"
"_minysegment" "-1"
"_maxxsegment" "1"
"_maxysegment" "1"
"_defaultgroundtexture" "textures/ftebroom/grid"
"_defaultgroundheight" "0"
}
{
"classname" "info_player_start"
"origin" "0 -128 128"
}
''')
for base in (root/'editor',editor):
    (base/'ftebroom-project.txt').write_text(game.as_posix())
    (base/'ftebroom-game-profile.txt').write_text('0 0 '+json.dumps(game.as_posix())+' "" '+json.dumps((editor/'entities.ent').as_posix())+' ""\n')
target=game/'maps/saved-terrain.map'
(editor/'terrain31.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
in 6 ftebroom_test_filepath open "{source.as_posix()}"
in 10 ftebroom_camera_restore 0 -650 550 40 90 0 90
in 13 ftebroom_test_terrain 1
in 15 ftebroom_test_filepath save "{target.as_posix()}"
in 18 screenshot terrain31.png
in 19 ftebroom_test_filepath open "{target.as_posix()}"
in 24 ftebroom_test_terrain 0
in 26 ftebroom_terrain_edit 0
in 27 ftebroom_model_drop "models/qa/test.md3" 400 400
in 28 mod_terrain_save "" model-added
in 29 brushedit_undo
in 30 mod_terrain_save "" model-undo
in 31 brushedit_redo
in 32 mod_terrain_save "" model-redo
in 34 quit force
''')
