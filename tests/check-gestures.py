from pathlib import Path
import re
import sys
p=Path(sys.argv[1])
def faces(n): return [x for x in (p/('gesture_'+n+'.map')).read_text().splitlines() if x.startswith('( ')]
def bounds(lines):
    # MAP stores three arbitrary points on each plane, not polygon vertices.
    # This fixture contains axis-aligned boxes; extract their six plane positions.
    coordinates=[[] for _ in range(3)]
    for line in lines[6:12]:
        pts=[list(map(float,m)) for m in re.findall(r'\( ([\d.eE+-]+) ([\d.eE+-]+) ([\d.eE+-]+) \)',line)]
        axes=[a for a in range(3) if max(p[a] for p in pts)-min(p[a] for p in pts)<1e-5]
        assert len(axes)==1, 'Fixture is no longer axis aligned'
        coordinates[axes[0]].append(pts[0][axes[0]])
    assert all(len(c)==2 for c in coordinates)
    return [min(c) for c in coordinates],[max(c) for c in coordinates]
for n in ['start','click','xy','z','cancel','create','undo','redo']:
    f=faces(n); print(n,len(f),bounds(f))
assert faces('click')==faces('start'),'click altered geometry'
lo,hi=bounds(faces('start')); xlo,xhi=bounds(faces('xy')); zlo,zhi=bounds(faces('z'))
assert xlo[2]==lo[2] and xhi[2]==hi[2] and xlo[:2]!=lo[:2],'XY constraint failed'
assert zlo[:2]==xlo[:2] and zhi[:2]==xhi[:2] and zlo[2]==xlo[2]+32 and zhi[2]==xhi[2]+32,'Z constraint failed'
assert faces('cancel')==faces('z'),'cancel changed geometry'
assert len(faces('create'))==18,'drag did not create one box'
assert sorted(faces('undo'))==sorted(faces('z')),'create undo failed'
assert sorted(faces('redo'))==sorted(faces('create')),'create redo failed'
print('PASS: click, XY, Alt Z, cancel, drag-create, undo/redo')

