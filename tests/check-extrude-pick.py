from pathlib import Path
import re, sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
source=(Path(__file__).parents[1]/'qc/fb_extrude_pick_tests.qc').read_text()
names=re.findall(r'fb_transform_expect\(.*?,"([a-z0-9_]+)"\);',source)
assert names
assert not any(e in log for e in ('FTEBROOM_TRANSFORM_FAIL','CSQC_Abort','mod by zero','runaway loop')),log
for name in names: assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
print(f'PASS: {len(names)} silhouette pick checks')
