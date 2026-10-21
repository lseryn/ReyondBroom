"""Generate a sealed, lit room without reading user maps or game assets."""
from pathlib import Path
import sys

def box(lo, hi):
    x,y,z=lo; X,Y,Z=hi
    planes=[[(x,Y,Z),(x,y,Z),(x,y,z)],[(X,y,z),(X,y,Z),(X,Y,Z)],
            [(X,y,Z),(X,y,z),(x,y,z)],[(x,Y,z),(X,Y,z),(X,Y,Z)],
            [(X,Y,z),(x,Y,z),(x,y,z)],[(x,y,Z),(x,Y,Z),(X,Y,Z)]]
    return '{\n'+''.join(' '.join('( %s )'%(' '.join(map(str,p))) for p in plane)+' ftebroom/grid 0 0 0 1 1 0 0 0\n' for plane in planes)+'}\n'

walls=[((-272,-272,-16),(272,272,0)),((-272,-272,256),(272,272,272)),
       ((-272,-272,0),(-256,272,256)),((256,-272,0),(272,272,256)),
       ((-256,-272,0),(256,-256,256)),((-256,256,0),(256,272,256))]
text='{\n"classname" "worldspawn"\n'+''.join(box(*b) for b in walls)+'}\n'
text+='{\n"classname" "info_player_deathmatch"\n"origin" "0 -160 64"\n}\n'
text+='{\n"classname" "light"\n"origin" "0 0 192"\n"light" "500"\n}\n'
text+='{\n"classname" "func_door"\n'+box((-48,32,0),(48,48,128))+'}\n'
Path(sys.argv[1]).write_text(text,encoding='ascii')
