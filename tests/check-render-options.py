from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageStat
root = Path(sys.argv[1])
assert (root / 'maps/render_before.map').read_bytes() == (root / 'maps/render_after.map').read_bytes()
def scene(name):
    return Image.open(root / (name + '.png')).convert('RGB').crop((170, 220, 840, 700))
def differs(a, b):
    diff = ImageChops.difference(scene(a), scene(b))
    assert sum(ImageStat.Stat(diff).sum) > 10000, (a, b)
for a, b in [('render_flat', 'render_shaded'), ('render_flat', 'render_wire'),
             ('render_flat', 'render_textured'), ('render_fog', 'render_nofog')]:
    differs(a, b)
print('PASS: patch flat/shaded/wire/textured modes, fog toggle and unchanged MAP')
