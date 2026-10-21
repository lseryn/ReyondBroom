from pathlib import Path
import math
import re
import sys
root = Path(sys.argv[1])
log = (root/'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_(EXPORT|TRACE)_FAIL|CSQC_Abort|runaway loop|stack overflow',log), log[-16000:]
assert log.count('FTEBROOM_EXPORT_PASS ')==7 and log.count('FTEBROOM_TRACE_PASS ')==3,log[-16000:]
lines = (root/'data/export.obj').read_text().splitlines()
vertices = [tuple(map(float,l.split()[1:])) for l in lines if l.startswith('v ')]
uv = [tuple(map(float,l.split()[1:])) for l in lines if l.startswith('vt ')]
faces = [l.split()[1:] for l in lines if l.startswith('f ')]
assert vertices and len(vertices)==len(uv)
assert all(math.isfinite(c) for p in vertices+uv for c in p)
assert all(p[0] < 9000 for p in vertices), 'Omitted layer exported'
assert sum(len(f)==3 for f in faces)>=128, 'Patch not tessellated'
assert any(len(f)==4 for f in faces), 'Brush polygons absent'
for face in faces:
    assert all(1<=int(index)<=len(vertices) for item in face for index in item.split('/'))
materials = {l[7:] for l in (root/'data/export.mtl').read_text().splitlines() if l.startswith('newmtl ')}
assert materials and all(l[7:] in materials for l in lines if l.startswith('usemtl '))
assert (root/'trace.png').exists()
groups=[]
for line in lines:
    if line.startswith('o '): groups.append([])
    if line.startswith('f '): groups[-1].append([int(item.split('/')[0])-1 for item in line.split()[1:]])
for polygons in groups:
    if len(polygons)!=6: continue
    indices=set(sum(polygons,[]))
    center=[sum(vertices[i][a] for i in indices)/len(indices) for a in range(3)]
    for polygon in polygons:
        a,b,c=[vertices[i] for i in polygon[:3]]
        x=[b[i]-a[i] for i in range(3)];y=[c[i]-a[i] for i in range(3)]
        normal=[x[1]*y[2]-x[2]*y[1],x[2]*y[0]-x[0]*y[2],x[0]*y[1]-x[1]*y[0]]
        assert sum(normal[i]*(a[i]-center[i]) for i in range(3))>0, 'Inward OBJ winding'
print('PASS: leak/portal load, validation, navigation, unload; OBJ brush/patch geometry, UVs, materials, omitted layers')
