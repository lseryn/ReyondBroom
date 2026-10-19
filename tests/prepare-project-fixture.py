from pathlib import Path
import shutil, zipfile, sys
bundle=Path(sys.argv[1]).resolve()
src=Path(__file__).resolve().parents[1]
fixtures=bundle/'fixture assets/baseq3'
(fixtures/'textures/loose').mkdir(parents=True,exist_ok=True)
shutil.copy2(src/'runtime/textures/ftebroom/grid.tga',fixtures/'textures/loose/stone.tga')
with zipfile.ZipFile(fixtures/'pak0.pk3','w',zipfile.ZIP_DEFLATED) as z:
    z.write(src/'runtime/textures/ftebroom/grid.tga','textures/test/deep/stone.tga')
    z.writestr('scripts/test.shader','''// The shader does not have an identically named image.
textures/test/custom
{
 qer_editorimage textures/test/deep/stone.tga
 { map textures/test/deep/stone.tga
   rgbGen identity }
}
''')
cfg='exec ftebroom.cfg\nset ftebroom_skip_setup 1\n'
cfg+=f'in 7 ftebroom_project "{fixtures.as_posix()}"\n'
cfg+='''in 9 ftebroom_material_count
in 9 ftebroom_shader_file_count
in 10 set ca_grid 8
in 11 ftebroom_test_drag create
in 12 mod_terrain_save "" grid8
in 13 brushedit_undo
in 14 set ca_grid 32
in 15 ftebroom_test_drag create
in 16 mod_terrain_save "" grid32
in 17 ftebroom_test_camera 1
in 18 ftebroom_test_camera 0
in 19 ftebroom_camera_offset
in 20 set ca_newbrushtexture test/custom
in 21 ftebroom_box 0 0 64 128 128 128
in 22 mod_terrain_save "" resources
in 23 screenshot grid-and-resources.png
in 24 quit
'''
(bundle/'ftebroom/test03.cfg').write_text(cfg)
print(bundle)
