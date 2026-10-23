"""Disposable image/PAK and complete MAP import fixtures."""
from pathlib import Path
import struct
import sys

root = Path(sys.argv[1])
assets = root / 'assets'
(assets / 'images').mkdir(parents=True)
(assets / 'maps').mkdir()
header = bytearray(18)
header[2] = 2
struct.pack_into('<HH', header, 12, 64, 32)
header[16:18] = bytes([24, 32])
pixels = bytes(c for y in range(32) for x in range(64)
               for c in (64, y * 8, x * 4))
image = bytes(header) + pixels
(assets / 'images/test.tga').write_bytes(image)
name = b'images/test.tga'
directory = name.ljust(56, b'\0') + struct.pack('<II', 12, len(image))
(assets / 'images.pak').write_bytes(
    b'PACK' + struct.pack('<II', 12 + len(image), len(directory)) + image + directory)
(root / 'ftebroom/progs').mkdir(exist_ok=True)
(root / 'ftebroom/gfx').mkdir(exist_ok=True)
(root / 'ftebroom/gfx/palette.lmp').write_bytes(bytes(i for i in range(256) for _ in range(3)))
header=struct.pack('<4si3f3ff3f8if',b'IDPO',6,1,1,1,-20,0,0,64,0,0,0,1,16,16,3,2,2,0,0,1)
skin=struct.pack('<i',0)+bytes([64])*256
uv=b''.join(struct.pack('<3i',0,u,v) for u,v in [(0,0),(15,0),(0,15)])
frame=struct.pack('<i',0)+bytes([0,0,0,0,40,0,60,0])+b'frame'+bytes(11)+bytes([0,0,0,0,40,0,0,0,0,0,60,0])
(root / 'ftebroom/progs/convert.mdl').write_bytes(header+skin+uv+struct.pack('<8i',1,0,1,2,1,2,1,0)+frame+frame[:-12]+bytes([0,0,0,0,40,0,0,0,0,0,90,0]))
source = Path(__file__).parent / 'fixtures/attributes.map'
(assets / 'maps/other.map').write_bytes(source.read_bytes())
config = f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{assets.as_posix()}"
in 7 ftebroom_test_desktop images42
in 10 screenshot media42.png
in 11 mod_terrain_save "" import42_before
in 12 ftebroom_test_desktop import42
in 15 mod_terrain_save "" import42_after
in 16 ftebroom_test_clipboard undo
in 18 mod_terrain_save "" import42_undo
in 19 ftebroom_test_clipboard redo
in 21 mod_terrain_save "" import42_redo
in 22 ftebroom_test_generators fracture
in 26 ftebroom_test_generators perforate
in 30 ftebroom_test_desktop convert42
in 34 ftebroom_test_desktop convert42check
in 35 screenshot convert42.png
in 38 quit force
'''
(root / 'ftebroom/media42.cfg').write_text(config, encoding='utf-8')
