from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
log = (root / "qconsole.log").read_text(errors="replace")
source = (Path(__file__).parents[1] / "qc/fb_extrude_tests.qc").read_text()
names = re.findall(r'fb_transform_expect\(.*?,"([a-z0-9_]+)"\);', source)
assert names
assert "FTEBROOM_TRANSFORM_FAIL" not in log, log
for name in names:
    assert "FTEBROOM_TRANSFORM_PASS " + name in log, name
assert not any(error in log for error in ("Host_Error", "QC error", "Program error")), log
print(f"PASS: {len(names)} extrude checks")
