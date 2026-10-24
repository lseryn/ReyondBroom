"""Compile disposable folder-import fixtures and compare BSP pixels to the generated WAD."""
from pathlib import Path
import struct,subprocess,sys
compiler=Path(sys.argv[1]).resolve();root=Path(sys.argv[2]).resolve();source=Path(sys.argv[3])
folder=root/'folder-test/compiler'
wads=sorted((folder/'_ftebroom-wads').glob('*.wad'))
assert wads,'Missing staged WADs'
expected={}
for wad in wads:
 data=wad.read_bytes();count,table=struct.unpack_from('<II',data,4)
 for i in range(count):
  pos,size=struct.unpack_from('<II',data,table+i*32);name=data[pos:pos+16].split(b'\0')[0].decode('ascii')
  if name in ('red','odd','odd-jpg','hires','{mask'):
   w,h,mip=struct.unpack_from('<III',data,pos+16);expected[name]=data[pos+mip:pos+mip+w*h]
assert len(expected)==5,expected.keys()
text=source.read_text(encoding='utf8').replace('"classname" "worldspawn"','"classname" "worldspawn"\n"wad" "'+';'.join(p.relative_to(folder).as_posix() for p in wads)+'"')
for name in ('red','odd','odd-jpg','hires','{mask')*2:text=text.replace('ftebroom/grid', '"'+name+'"',1)
(folder/'textures.map').write_text(text,encoding='utf8')
result=subprocess.run([str(compiler),'textures.map'],cwd=folder,capture_output=True)
(folder/'qbsp.log').write_bytes(result.stdout+result.stderr)
assert result.returncode==0,result.stdout.decode(errors='replace')+result.stderr.decode(errors='replace')
data=(folder/'textures.bsp').read_bytes();assert struct.unpack_from('<I',data)[0]==29
start,length=struct.unpack_from('<II',data,20);count=struct.unpack_from('<I',data,start)[0];actual={}
for i in range(count):
 offset=struct.unpack_from('<i',data,start+4+i*4)[0]
 if offset<0:continue
 at=start+offset;name=data[at:at+16].split(b'\0')[0].decode('ascii');w,h,mip=struct.unpack_from('<III',data,at+16)
 assert mip>0 and at+mip+w*h<=start+length
 actual[name]=data[at+mip:at+mip+w*h]
for name,pixels in expected.items():assert actual.get(name)==pixels,'BSP pixels differ: '+name
print('PASS: generated folder WAD pixels embedded unchanged by qbsp')
