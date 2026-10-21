from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_PRIMITIVE_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_PRIMITIVE_PASS ') == 16, log[-24000:]
assert (root / 'primitives.png').exists()
assert (root / 'maps/primitives.map').exists()
print('PASS: 16 primitive geometry, limits and history checks')
