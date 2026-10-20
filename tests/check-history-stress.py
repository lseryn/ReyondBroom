from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_HISTORY_FAIL' not in log, log[-8000:]
for name in ('ring_growth','large_single_undo','multi_selection','door_property_undo',
             'layer_flag_changed','layer_flag_undo','tree_reparented','tree_parent_undo'):
    assert 'FTEBROOM_HISTORY_PASS ' + name in log, name
def data(name):
    return (root / 'maps' / f'stress_{name}.map').read_bytes()
assert data('before') == data('after'), 'Large transaction undo changed the MAP'
assert data('multi') == data('restored'), 'Multi-delete Undo changed the MAP'
assert len(re.findall(rb'^\( ', data('deleted'), re.M)) == 6
assert 'setmodel on readonly entity' not in log
print('PASS: 600 synthetic selection records grow the ring and undo atomically; multi-delete, layer flags and entity/group membership round-trip.')
