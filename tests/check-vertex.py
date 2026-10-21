from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_VERTEX_FAIL' not in log, log[-26000:]
assert log.count('FTEBROOM_VERTEX_PASS ') == 28, log[-26000:]
assert (root / 'vertex.png').exists()
assert (root / 'maps/vertex.map').exists()
print('PASS: 28 vertex topology, selection and history checks')
