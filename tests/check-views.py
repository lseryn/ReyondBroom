from pathlib import Path
import sys
import re
r=Path(sys.argv[1]);log=(r/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_VIEW_FAIL' not in log,log[-12000:]
checks=['side_face_picking','side_face_cut_plane','side_face_preview','default_depth','fractional_selection_depth']
checks += [f'face_split_{i}' for i in range(6)]
checks += ['entity_selection_depth']
checks += [f'{name}_{i}' for i in range(1,4) for name in ['axes','zoom_anchor','pan','selection_depth','shape_plane']]
for name in checks: assert 'FTEBROOM_VIEW_PASS '+name in log,name
def faces(name): return sorted(x for x in (r/'maps'/f'view_{name}.map').read_text().splitlines() if x.startswith('( '))
assert len(faces('clip'))==12
assert faces('before')==faces('undo')==faces('after')
assert faces('before')==faces('nudge_undo')
points=[tuple(map(float,p)) for line in faces('nudge') for p in re.findall(r'\( ([\d.e+-]+) ([\d.e+-]+) ([\d.e+-]+) \)',line)]
assert min(p[2] for p in points)==16 and max(p[2] for p in points)==144
for name in ('front','top','side'): assert (r/f'views-{name}.png').exists()
print(f'PASS: {len(checks)} view/Clip assertions, two solid halves, Undo and unchanged geometry after camera/preview operations.')
