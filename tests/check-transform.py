from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_TRANSFORM_FAIL' not in log,log
names=re.findall(r'fb_transform_expect\(.*?,"([a-z0-9_]+)"\);',(Path(__file__).parents[1]/'qc/fb_transform_tests.qc').read_text())
for name in names: assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
assert len(names)>=11
print('PASS:',len(names),'transform checks')

def tokens(name):
    return re.findall(r'"(?:\\.|[^"\\])*"|[{}()\[\]]|[^\s{}()\[\]"]+', (p/('maps/transform_'+name+'.map')).read_text())
assert tokens('before')==tokens('after'), 'Complete MAP data changed after undo'
print('PASS: complete MAP tokens preserved, including entities and patch attributes')
