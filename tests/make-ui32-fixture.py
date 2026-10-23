from pathlib import Path
import sys,runpy,struct
root=Path(sys.argv[1]).resolve()
runpy.run_path('tests/make-alpha30-fixture.py',run_name='__main__')
image=root/'editor/ftebroom/textures/qa/tile.tga';image.parent.mkdir(parents=True,exist_ok=True)
image.write_bytes(bytes([0,0,2])+bytes(9)+struct.pack('<HHBB',16,16,24,32)+bytes([40,90,240])*256)
(root/'editor/ftebroom/ui32.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{root.as_posix()}"
in 7 ftebroom_test_desktop files32
in 9 screenshot files32.png
in 10 ftebroom_test_desktop new32
in 12 screenshot new32.png
in 13 ftebroom_test_filepath name created32.map
in 14 ftebroom_test_filepath browserclick primary 1
in 14.1 ftebroom_test_filepath browserclick primary 2
in 18 ftebroom_test_desktop new32result
in 20 ftebroom_test_desktop thumbnail32
in 22 screenshot thumbnail32.png
in 24 quit force
''')
