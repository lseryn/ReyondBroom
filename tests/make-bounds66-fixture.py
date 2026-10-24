"""Create covered/exposed group bounds without external resources."""
from pathlib import Path
import sys

def box(lo, hi):
    x,y,z=lo; X,Y,Z=hi
    planes=[[(x,Y,Z),(x,y,Z),(x,y,z)],[(X,y,z),(X,y,Z),(X,Y,Z)],
            [(X,y,Z),(X,y,z),(x,y,z)],[(x,Y,z),(X,Y,z),(X,Y,Z)],
            [(X,Y,z),(x,Y,z),(x,y,z)],[(x,y,Z),(x,Y,Z),(X,Y,Z)]]
    return '{\n'+''.join(' '.join('( %s )'%(' '.join(map(str,p))) for p in plane)+' ftebroom/qa_green 0 0 0 1 1\n' for plane in planes)+'}\n'

root=Path(sys.argv[1]); root.mkdir(parents=True,exist_ok=True)
world='{\n"classname" "worldspawn"\n'+box((-64,16,32),(-32,80,96))+box((32,16,32),(64,80,96))+'}\n'
(root/'bounds66-0.map').write_text(world,encoding='ascii')
