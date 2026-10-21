from pathlib import Path
import re
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_SWEEP_FAIL|CSQC_Abort|runaway loop|stack overflow',log),log[-18000:]
assert log.count('FTEBROOM_SWEEP_PASS ')==10,log[-18000:]
print('PASS: Sweep straight volumes, path endpoints, shared arc caps, iterations, Undo and Escape cascade')
