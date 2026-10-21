from pathlib import Path
import re
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert not re.search(r'FTEBROOM_RUN_FAIL|CSQC_Abort|runaway loop|stack overflow',log),log[-18000:]
assert log.count('FTEBROOM_RUN_PASS ')==10,log[-18000:]
assert (root/'maps/run-test/build.map').stat().st_size>100
assert (root/'maps/run-test/source.txt').read_text()=='pipeline fixture'
assert (root/'run.png').exists()
print('PASS: export/run/copy/rename/delete pipeline, variables, streamed output, failure exit and Stop')
