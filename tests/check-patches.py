from pathlib import Path
import re
import sys
root=Path(sys.argv[1])
log=(root/'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_PATCH_FAIL|CSQC_Abort|runaway loop|stack overflow',log),log[-18000:]
assert log.count('FTEBROOM_PATCH_PASS ')==10,log[-18000:]
assert 'patchDef2' in (root/'maps/patches.map').read_text()
print('PASS: patch conversion, control handles, dome edit, exact subdivision, reduction and Delete isolation')
