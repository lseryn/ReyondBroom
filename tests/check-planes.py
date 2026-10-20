from pathlib import Path
import re,sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_VIEW_FAIL' not in log,log[-15000:]
for view in range(1,4):
    for name in ('gesture_hit','alt_ignored','view_capture','shift_axis','shift_release','gesture_commit','clip_empty_plane'):
        assert f'FTEBROOM_VIEW_PASS {name}_{view}' in log,(name,view)
assert log.count('FTEBROOM_VIEW_PASS surfacegrid_live_geometry')==8
read=lambda name:(root/'maps'/f'plane_{name}.map').read_text()
faces=lambda text:sorted(line for line in text.splitlines() if line.startswith('( '))
def bounds(text):
    points=[tuple(map(float,p)) for p in re.findall(r'\( ([\d.e+-]+) ([\d.e+-]+) ([\d.e+-]+) \)',text)]
    return tuple(min(p[a] for p in points) for a in range(3)),tuple(max(p[a] for p in points) for a in range(3))
base=read('before');lo,hi=bounds(base)
for view,axis in ((1,1),(2,0),(3,0)):
    moved=read(f'move{view}');actual=bounds(moved)
    expected=tuple(tuple(b[a]+(64 if a==axis else 0) for a in range(3)) for b in (lo,hi))
    assert actual==expected,(view,actual,expected)
    assert faces(read(f'undo{view}'))==faces(base)
    assert faces(read(f'redo{view}'))==faces(moved)
print('PASS: 21 plane gesture assertions, 8 grid cache checks, MAP movement bounds and Undo/Redo in YZ/XZ/XY.')
