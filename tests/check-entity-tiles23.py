from pathlib import Path
import sys
root=Path(sys.argv[1])
def read(name): return (root/'maps'/('tiles23-'+name+'.map')).read_text()
assert 'FTEBROOM_ENTITY_UI_FAIL' not in (root/'qconsole.log').read_text(errors='replace')
assert '"classname" "ammo_bullets"' in read('replaced')
assert '"classname" "ammo_rockets"' in read('undo')
assert read('replaced')==read('redo')
assert read('drop').count('"classname" "ammo_bullets"')==2
print('PASS: tile class replacement, Undo/Redo, native ImGui drag/drop')
