from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_REPEAT_FAIL|CSQC_Abort|runaway loop|stack overflow', log), log[-18000:]
assert log.count('FTEBROOM_REPEAT_PASS ') == 7, log[-18000:]
print('PASS: repeat sequence, ten duplicates, atomic Undo, selection reset, explicit reset')
