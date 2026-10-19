from pathlib import Path
import re
import sys
p=Path(sys.argv[1])
def faces(n): return [x for x in (p/('gesture_'+n+'.map')).read_text().splitlines() if x.startswith('( ')]
def bounds(lines):
    pts=[list(map(float,m)) for line in lines[6:12] for m in re.findall(r'\( ([\d.-]+) ([\d.-]+) ([\d.-]+) \)',line)]
    return [min(q[a] for q in pts) for a in range(3)],[max(q[a] for q in pts) for a in range(3)]
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

