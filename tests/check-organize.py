from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_ORGANIZE_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_ORGANIZE_PASS ') == 19, log[-24000:]
assert (root / 'organize.png').exists()
document = (root / 'maps/organize.map').read_text()
assert 'Details' in document and 'Layer group' in document
assert '_tb_layer_omit_from_export' in document
print('PASS: 19 grouping, layers, visibility and history checks')
