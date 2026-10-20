from pathlib import Path
import sys,re
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_FACES_FAIL' not in log,log[-20000:]
assert 'mod by zero' not in log
source=(Path(__file__).parents[1]/'qc/fb_faces_tests.qc').read_text(encoding='utf-8-sig')
names=re.findall(r'fb_faces_expect\([^;]*?,"([a-z0-9_]+)"\);',source)
for name in names: assert 'FTEBROOM_FACES_PASS '+name in log,name
# Preserve entity/brush ownership while allowing engine brush order to change.
def normalized(name):
 stack=[[]]
 for line in (root/'maps'/name).read_text().splitlines():
  line=line.strip()
  if not line or line.startswith('//'): continue
  if line=='{': stack.append([])
  elif line=='}':
   assert len(stack)>1, 'Unbalanced MAP'
   block=tuple(sorted(stack.pop(),key=repr));stack[-1].append(block)
  else: stack[-1].append(line)
 assert len(stack)==1, 'Unbalanced MAP'
 return tuple(sorted(stack[0],key=repr))
assert normalized('faces_before.map')==normalized('faces_after.map'),'Complete MAP content changed'
assert (root/'faces.png').exists()
print(f'PASS: {len(names)} face-selection checks, high mask bits, material isolation and complete MAP round-trip.')
