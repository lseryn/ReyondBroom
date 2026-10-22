from pathlib import Path
import struct,sys
path=Path(sys.argv[1])
def entries(p):
    data=p.read_bytes();offset,length=struct.unpack_from('<II',data,4);result={}
    for at in range(offset,offset+length,64):
        name,start,size=struct.unpack_from('<56sII',data,at)
        result[name.rstrip(b'\0')]=data[start:start+size]
    return result
old=entries(next(path.parent.glob(path.name+'.ftebroom-*.bak')));new=entries(path)
assert old.keys()==new.keys()
for name in old:
    if name!=b'maps/room.map':assert old[name]==new[name],name
assert b'"wad"' in new[b'maps/room.map']
print('PASS: original PAK backup, same entry names, unchanged WAD and unrelated binary payload')
