from pathlib import Path
import re
import sys
root=Path(sys.argv[1])
log=(root/'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_LINKED_FAIL|CSQC_Abort|runaway loop|stack overflow',log),log[-18000:]
assert log.count('FTEBROOM_LINKED_PASS ')==16,log[-18000:]
assert '_tb_transformation' in (root/'maps/linked.map').read_text()
print('PASS: linked duplicate, instance transforms, synchronization, atomic Undo and protected property merge')
