from pathlib import Path
import sys,runpy,struct,zlib
root=Path(sys.argv[1]).resolve()
runpy.run_path('tests/make-quake1-fixture.py',run_name='__main__')
game=root/'id1';models=game/'models/qa';models.mkdir(parents=True,exist_ok=True)
def tga(rgb):return bytes([0,0,2])+bytes(9)+struct.pack('<HHBB',2,2,24,32)+bytes(rgb[::-1])*4
(models/'red.tga').write_bytes(tga((240,20,30)));(models/'green.tga').write_bytes(tga((20,240,50)))
def surface(name,shader,offset):
 data=bytearray(236);struct.pack_into('<4s64s10i',data,0,b'IDP3',name.encode(),0,1,1,3,1,108,120,188,212,236)
 struct.pack_into('<3i',data,108,0,1,2);struct.pack_into('<64si',data,120,shader.encode(),0);struct.pack_into('<6f',data,188,0,0,1,0,0,1)
 for i,p in enumerate([(offset,0,0),(offset+25,0,0),(offset,0,45)]):struct.pack_into('<3hH',data,212+i*8,*(int(v*64) for v in p),0)
 return data
body=surface('left','models/qa/red',-30)+surface('right','models/qa/green',10)
header=struct.pack('<4si64s9i',b'IDP3',15,b'fixture',0,1,0,2,0,108,108,108,108+len(body));(models/'test.md3').write_bytes(header+body)
# A first-pose MDL with a palette-indexed checker skin.
header=struct.pack('<4si3f3ff3f8if',b'IDPO',6,1,1,1,0,0,0,64,0,0,0,1,16,16,3,1,1,0,0,1)
skin=struct.pack('<i',0)+bytes(64 if (x//4+y//4)%2 else 200 for y in range(16) for x in range(16))
uv=b''.join(struct.pack('<3i',0,u,v) for u,v in [(0,0),(15,0),(0,15)])
tri=struct.pack('<4i',1,0,1,2);frame=struct.pack('<i',0)+bytes(8)+b'frame'+bytes(11)+bytes([0,0,0,0,40,0,0,0,0,0,60,0]);(models/'test.mdl').write_bytes(header+skin+uv+tri+frame)
def chunk(name,data):return struct.pack('>I',len(data))+name+data+struct.pack('>I',zlib.crc32(name+data)&0xffffffff)
pixels=b''.join(b'\0'+bytes((100,100,150))*30 for _ in range(14))
(root/'import.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',30,14,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(pixels))+chunk(b'IEND',b''))
(root/'target.wad').write_bytes((game/'test textures.wad').read_bytes())
(root/'editor/ftebroom/desktop-test.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{root.as_posix()}"
in 6 screenshot modern-panel.png
in 8 ftebroom_test_desktop ui
in 10 screenshot retro-panel.png
in 12 ftebroom_test_desktop drop
in 16 ftebroom_test_desktop models
in 18 screenshot model-tiles.png
in 20 quit force
''')
