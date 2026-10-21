from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_TRANSFORM_FAIL' not in log,log
source=(Path(__file__).parents[1]/'qc/fb_materials_tests.qc').read_text()
names=re.findall(r'fb_transform_expect\(.*?,"([a-z0-9_]+)"\);',source.split('if(argv(1)=="edit")',1)[1])
for name in names: assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
text=(p/'maps/materials_edited.map').read_text()
assert text.count('-2147483647 123456789')==3
print('PASS:',len(names),'material checks and serialized 32-bit attributes')
