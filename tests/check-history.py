from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_HISTORY_FAIL' not in log, log[-6000:]
for name in ('select_A', 'select_empty', 'select_B_redo', 'cancel_history',
             'entity_undo', 'entity_redo', 'flags_undo', 'tree_undo',
             'whole_transaction_eviction'):
    assert 'FTEBROOM_HISTORY_PASS ' + name in log, name
counts = {name: int(value) for name, value in re.findall(r'FTEBROOM_HISTORY_COUNT (\w+) (\d+)', log)}
assert counts['after_fast'] - counts['before_fast'] == 1, counts
assert counts['after_slow'] - counts['before_slow'] == 5, counts
def data(name):
    return (root / 'maps' / f'history_{name}.map').read_bytes()
def faces(name):
    return len(re.findall(rb'^\( ', data(name), re.M))
assert faces('original') == faces('restored') == 12
assert data('original') == data('restored') == data('input_guard')
for name in ('deleted', 'redeleted', 'deleted_brush_mode', 'deleted_clip_mode'):
    assert faces(name) == 6, name
assert data('before_fast') == data('fast_undo')
assert data('cancel_before') == data('cancel_after')
assert data('before_cancel_undo') == data('cancel_redo')
print('PASS: native Del/Undo/Redo, Brush/Clip mode deletion, selection history, fast/slow collation, byte-identical cancel, preserved redo, entity/flags/tree snapshots and whole-transaction eviction.')
