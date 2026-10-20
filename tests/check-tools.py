from pathlib import Path
import re,sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
states={m[0]:tuple(map(int,m[1:])) for m in re.findall(r'FTEBROOM_TOOLS (\w+) tool=(\d+) points=(\d+) handles=(\d+) selected=(\d+) active=(\d+)',log)}
expected={'clip':(2,0,0,1,0),'toggle_off':(0,0,0,1,0),'point2':(2,2,0,1,0),'point1':(2,1,0,1,0),'point0':(2,0,0,1,0),'default':(0,0,0,1,0),'deselected':(0,0,0,0,0),'undo_selection':(0,0,0,1,0),'redo_selection':(0,0,0,0,0),'vertex':(7,0,0,1,0),'forced_off':(0,0,0,1,0)}
assert states==expected,(states,expected)
def faces(name):return sorted(x for x in (root/'maps'/f'tools_{name}.map').read_text().splitlines() if x.startswith('( '))
assert len(faces('start'))==12 and faces('start')==faces('end')
assert faces('start')==faces('move_undo')
assert len(faces('moved'))==12 and faces('moved')!=faces('start')
def xs(name):
    lines=(root/'maps'/f'tools_{name}.map').read_text().splitlines()
    points=[float(x) for line in [l for l in lines if l.startswith('( ')][6:] for x in re.findall(r'\( ([\d.eE+-]+) ',line)]
    return min(points),max(points)
assert xs('moved')==(-32,96),xs('moved')
assert 'ambiguous shortcut'  not in log
assert (root/'tools.png').is_file()
print('PASS: modal toggles, Clip Escape cascade, selection Undo/Redo, handle-state Shift+Escape, unchanged full MAP face records')
