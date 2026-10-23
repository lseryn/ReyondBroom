from pathlib import Path
import sys, shutil
root = Path(sys.argv[1]); editor = root/'editor/ftebroom'
folder = root/'Карты с пробелами'; folder.mkdir()
shutil.copyfile(sys.argv[2], folder/'concrete_sh.wad')
shutil.copyfile(editor/'maps/build-fixture.map', folder/'test.map')
(editor/'wad32.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{folder.as_posix()}"
in 5 ftebroom_test_filepath open "{(folder/'test.map').as_posix()}"
in 9 ftebroom_test_desktop wad32load
in 13 ftebroom_test_desktop wad32paint
in 16 ftebroom_test_desktop wad32build
in 28 ftebroom_test_desktop wad32result
in 30 quit force
''', encoding='utf-8')
