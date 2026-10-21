from pathlib import Path
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_ASSEMBLE_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_ASSEMBLE_PASS ') == 11, log[-24000:]
assert (root / 'assemble.png').exists()
assert (root / 'maps/assemble.map').exists()
print('PASS: 11 brush assembly, cancellation and history checks')
