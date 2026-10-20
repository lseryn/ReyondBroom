from pathlib import Path
import re,sys
from PIL import Image
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_VISUAL_FAIL' not in log,log[-12000:]
assert 'mod by zero' not in log
source=(Path(__file__).parents[1]/'qc/fb_visual_tests.qc').read_text()
names=re.findall(r'fb_visual_expect\([^;]*?,"([a-z0-9_]+)"\);',source)
for name in names: assert 'FTEBROOM_VISUAL_PASS '+name in log,name
assert (root/'maps/visual_before.map').read_bytes()==(root/'maps/visual_after.map').read_bytes(),'Rendering changed MAP bytes'
for name in ['single','hover','multi','face','off','2d','colors']:
 image=Image.open(root/f'visual-{name}.png').convert('RGB').crop((48,114,970,774))
 pixels=list(image.get_flattened_data())
 assert sum(r>100 and r>g*1.8 and r>b*1.8 for r,g,b in pixels)>30,name+' selected red missing'
 assert sum(b>80 and b>r*1.6 and b>g*1.2 for r,g,b in pixels)>30,name+' locked blue missing'
solid=Image.open(root/'visual-single.png').convert('RGB').crop((475,430,525,480))
assert sum(g>r and g>b and g>60 for r,g,b in solid.get_flattened_data())>500,'Selected brush lost its material surface'
assert 'FTEBROOM_MANUAL_PASS patch' in log and 'FTEBROOM_MANUAL_PASS entity' in log
assert (root/'maps/visual_patch_before.map').read_bytes()==(root/'maps/visual_patch_after.map').read_bytes()
for name in ['patch','entity']:
 pixels=Image.open(root/f'visual-{name}.png').convert('RGB').crop((48,114,970,774)).get_flattened_data()
 assert sum(r>100 and r>g*1.8 and r>b*1.8 for r,g,b in pixels)>20,name+' outline missing'
print(f'PASS: {len(names)} visual-state checks, nine rendered images and byte-identical complete MAP.')
