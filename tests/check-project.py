"""Validate exports and engine diagnostics from the Quake 3 fixture run."""
from pathlib import Path
import math
import re
import sys

game = Path(sys.argv[1])
for grid in (8, 32):
    text = (game / 'maps' / f'grid{grid}.map').read_text()
    faces = [line for line in text.splitlines() if line.startswith('( ')]
    assert len(faces) == 12, (grid, len(faces))
    points = [tuple(map(float, p)) for line in faces[6:]
              for p in re.findall(r'\( ([\d.e+-]+) ([\d.e+-]+) ([\d.e+-]+) \)', line)]
    height = max(p[2] for p in points) - min(p[2] for p in points)
    assert height == grid, (grid, height)
log = (game / 'qconsole.log').read_text(errors='replace')
log = log.rsplit('Engine Version:', 1)[-1]
for name in ('textures/loose/stone', 'textures/test/deep/stone', 'textures/test/custom'):
    assert f'ReyondBroom material: {name}' in log, name
assert 'from 1 shader files' in log
offsets = re.findall(r'ftebroom_camera_offset" is "\x27([^\x27]+)', log)
assert offsets, 'Missing camera diagnostics'
distance = math.sqrt(sum(float(v)**2 for v in offsets[-1].split()))
# One second of default flight is 500 units; allow scheduling/frame jitter.
assert 420 < distance < 580, distance
assert 'test/custom [' in (game / 'maps/resources.map').read_text()
assert 'with no passes' not in log
assert (game / 'grid-and-resources.png').is_file()
print('PASS: grid heights 8/32, nested PK3 + loose assets, shader discovery, WASD camera, material export')
