from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_CSG_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_CSG_PASS ') == 13, log[-24000:]
assert (root / 'csg.png').exists()
assert (root / 'maps/csg.map').exists()
print('PASS: 13 CSG volume, selection, visibility and history checks')
