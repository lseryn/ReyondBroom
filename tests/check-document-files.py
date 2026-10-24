from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
states = re.findall(r'FTEBROOM_DOCUMENT revision=(\d+) saved=(\d+) dirty=(\d+) nodes=(\d+)', log)
assert [int(s[2]) for s in states] == [0, 0, 1], states
assert states[0][3] == '2', 'New must create a genuinely empty document'
assert states[1][3] == states[2][3] == '3'
assert states[1][1] == states[2][1], 'Failed save changed the checkpoint'
assert 'ReyondBroom save failed:' in log
assert (root / 'maps/files_fail.map').is_dir(), 'Failed destination was modified'
assert len(re.findall(r'^\( ', (root / 'maps/files_checkpoint.map').read_text(), re.M)) == 6
print('PASS: New creates an empty document; failed atomic replacement preserves the dirty document and saved checkpoint.')
