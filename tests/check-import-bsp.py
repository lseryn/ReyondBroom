"""Assert imported texture pixels are embedded, rather than just texture names."""
from pathlib import Path
import struct,sys
root=Path(sys.argv[1]);data=(root/'unicode.bsp').read_bytes()
assert struct.unpack_from('<i',data)[0]==29
start,length=struct.unpack_from('<ii',data,4+2*8)
count=struct.unpack_from('<i',data,start)[0];textures={}
for i in range(count):
 offset=struct.unpack_from('<i',data,start+4+i*4)[0]
 if offset<0:continue
 at=start+offset;name=data[at:at+16].split(b'\0')[0].decode('ascii');w,h,*mips=struct.unpack_from('<6I',data,at+16)
 assert mips[0]>0 and at+mips[0]+w*h<=start+length
 textures[name]=data[at+mips[0]:at+mips[0]+w*h]
for name in (root/'expected.txt').read_text().splitlines():
 assert name in textures, (name,list(textures))
 assert len(set(textures[name]))>1, f'{name}: placeholder instead of imported pixels'
print('PASS: all three source textures have embedded pixel data in BSP29')
