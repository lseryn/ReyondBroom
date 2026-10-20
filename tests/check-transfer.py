from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_TRANSFORM_FAIL' not in log,log
names=re.findall(r'fb_transform_expect\(.*?,"([a-z0-9_]+)"\);',(Path(__file__).parents[1]/'qc/fb_material_transfer_tests.qc').read_text())
for name in names: assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
assert not any(x in log for x in ['Host_Error','QC error','Program error']),log
print('PASS:',len(names),'material transfer checks')
