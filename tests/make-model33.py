"""Synthetic two-bone, two-pose IQM; no third-party model assets."""
import struct
from pathlib import Path

def write_model(path: Path):
    data = bytearray(124)
    def lump(value):
        while len(data) % 4: data.append(0)
        offset = len(data)
        data.extend(value)
        return offset
    text = b'mesh\0models/qa/red\0root\0tip\0move\0'
    names = lambda name: text.index(name.encode()+b'\0')
    ot = lump(text)
    om = lump(struct.pack('<6I', names('mesh'), names('models/qa/red'), 0, 3, 0, 1))
    pos = lump(struct.pack('<9f', -25,0,0,25,0,0,0,0,45))
    uv = lump(struct.pack('<6f', 0,0,1,0,.5,1))
    normal = lump(struct.pack('<9f',0,-1,0,0,-1,0,0,-1,0))
    indices = lump(bytes([0,0,0,0,0,0,0,0,1,0,0,0]))
    weights = lump(bytes([255,0,0,0])*3)
    va = lump(b''.join(struct.pack('<5I', t,0,f,n,o) for t,f,n,o in [(0,7,3,pos),(1,7,2,uv),(2,7,3,normal),(4,1,4,indices),(5,1,4,weights)]))
    tri = lump(struct.pack('<3I',2,1,0))
    joints = lump(b''.join(struct.pack('<Ii10f',names(name),parent,0,0,z,0,0,0,1,1,1,1) for name,parent,z in [('root',-1,0),('tip',0,30)]))
    poses = lump(b''.join(struct.pack('<iI20f',parent,mask,0,0,z,0,0,0,1,1,1,1,0,0,scale,0,0,0,0,0,0,0) for parent,mask,z,scale in [(-1,0,0,0),(0,4,30,1)]))
    anim = lump(struct.pack('<3IfI',names('move'),0,2,5,1))
    frames = lump(struct.pack('<2H',0,20))
    bounds = lump(struct.pack('<8f',-25,0,0,25,0,65,50,80)*2)
    struct.pack_into('<16s27I',data,0,b'INTERQUAKEMODEL\0',2,len(data),0,len(text),ot,1,om,5,3,va,1,tri,0,2,joints,2,poses,1,anim,2,1,frames,bounds,0,0,0,0)
    path.write_bytes(data)
