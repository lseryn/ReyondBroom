from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_SCALE_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_SCALE_PASS ') == 13, log[-24000:]
assert (root / 'scale.png').exists()
assert (root / 'maps/scale.map').exists()
print('PASS: 13 scale/shear geometry, modifiers and history checks')
