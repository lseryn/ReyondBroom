"""Verify unselected group/entity surfaces, visibility toggles and MAP reload."""
from pathlib import Path
import sys
from PIL import Image, ImageChops

root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_FILTER_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_FILTER_PASS ') == 10, log[-24000:]
assert 'runaway loop' not in log.lower(), log[-24000:]
images = {}
for name in ('visible', 'hidden', 'restored', 'reloaded'):
    images[name] = Image.open(root / f'submodels-{name}.png').convert('RGB').crop((70, 180, 900, 750))
assert ImageChops.difference(images['visible'], images['hidden']).getbbox(), 'No geometry rendered'
assert ImageChops.difference(images['visible'], images['restored']).getbbox() is None, 'Visibility toggle did not restore the scene'
for name in ('submodels', 'submodels-reloaded'):
    text = (root / f'maps/{name}.map').read_text()
    for token in ('"Visible group"', '"func_door"', '"func_wall"'):
        assert token in text, (name, token)
print('PASS: unselected group, func_door and func_wall; bounds, hide/show pixels and MAP reload')

assert 'FTEBROOM_VIEW_PASS surfacegrid_live_geometry' in log
for a,b in [('grid8','grid32'),('grid32','nogrid'),('nogrid','noedges')]:
    first=Image.open(root/f'submodels-{a}.png').convert('RGB').crop((380,390,630,550))
    second=Image.open(root/f'submodels-{b}.png').convert('RGB').crop((380,390,630,550))
    assert ImageChops.difference(first,second).getbbox(), (a,b)
print('PASS: live grid cache across submodels, spacing changes and independent edge/grid toggles')
