"""Create disposable, source-independent assets for repeated profile application."""
from pathlib import Path
import json, re, shutil, sys
bundle=Path(sys.argv[1]).resolve()
root=bundle/'resources'
(root/'textures').mkdir(parents=True,exist_ok=True)
shutil.copytree(bundle/'ftebroom/textures',root/'textures',dirs_exist_ok=True)
(bundle/'ftebroom-project.txt').write_text(root.as_posix(),encoding='utf-8')
(bundle/'ftebroom-game-profile.txt').write_text('1 0 "" "" "" "" 1 0 ""',encoding='utf-8')
lines=[line for line in (bundle/'ftebroom/maps/start.map').read_text().splitlines() if line.startswith('( ')]
brushes=[]
for y in range(20):
 for x in range(25):
  def point(match):
   a,b,c=map(float,match.groups())
   return '( %g %g %g )'%(a/16+x*48,b/16+y*48,c+32)
  brushes.append('{\n'+'\n'.join(re.sub(r'\( ([\d.-]+) ([\d.-]+) ([\d.-]+) \)',point,line) for line in lines)+'\n}')
(bundle/'ftebroom/maps/reload60.map').write_text('{\n"classname" "worldspawn"\n'+'\n'.join(brushes)+'\n}',encoding='utf-8')
(bundle/'ftebroom/reload60.cfg').write_text("""exec ftebroom.cfg
set ftebroom_skip_setup 0
in 12 mapedit maps/reload60.map
in 26 set ftebroom_skip_setup 1
in 27 ftebroom_test_desktop reload60capture
in 30 ftebroom_test_desktop reload60apply
in 38 set ftebroom_skip_setup 1
in 39 ftebroom_test_desktop reload60check
in 40 ftebroom_test_desktop reload60apply
in 48 set ftebroom_skip_setup 1
in 49 ftebroom_test_desktop reload60check
in 51 screenshot reload60.png
in 53 quit force
""",encoding='utf-8')
