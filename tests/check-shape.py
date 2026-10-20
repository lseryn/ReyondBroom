from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_SHAPE_FAIL' not in log,log
names=re.findall(r'fb_shape_expect\(.*?,"([a-z0-9_]+)"\);',(Path(__file__).parents[1]/'qc/fb_shape_tests.qc').read_text())
for name in names: assert 'FTEBROOM_SHAPE_PASS '+name in log,name
assert len(names)>=11
print('PASS:',len(names),'shape checks')
