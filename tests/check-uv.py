from pathlib import Path
import re
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_UV_FAIL|CSQC_Abort|runaway loop|stack overflow',log),log[-18000:]
assert log.count('FTEBROOM_UV_PASS ')==11,log[-18000:]
assert (root/'uv.png').exists()
assert 'FTEBROOM_UV_NATIVE_FAIL' not in log and 'FTEBROOM_UV_NATIVE_PASS canvas_drag_dispatched' in log,log[-18000:]
def faces(name): return sorted(line for line in (root/'maps'/name).read_text().splitlines() if line.startswith('( '))
before,after,undo=[faces(name) for name in ('uv.map','uv-drag.map','uv-undo.map')]
assert before==undo, 'Canvas drag Undo changed the original document'
assert len(before)==len(after) and sum(a!=b for a,b in zip(before,after))==1, 'Canvas drag must modify one selected face'
assert all(re.findall(r'\([^)]*\)',a)==re.findall(r'\([^)]*\)',b) for a,b in zip(before,after)), 'Canvas drag changed geometry'
# The fixture has positive U along the canvas X axis. Dragging right must
# reduce U bias so the texture, rather than its UV coordinates, follows the mouse.
original, moved = next((a,b) for a,b in zip(before,after) if a!=b)
uv_rows = lambda line: [[float(v) for v in row.split()] for row in re.findall(r'\[([^]]*)\]',line)]
a,b=uv_rows(original),uv_rows(moved)
assert len(a)==len(b)==2 and b[0][3]<a[0][3], 'Texture moved opposite to the cursor'

print('PASS: UV offset, rotation, shear, geometry preservation, atomic Undo, cancellation and singular scale rejection')
