"""Check native patch control points and front-face orientation survive Q3 compilation."""
from pathlib import Path
from collections import Counter
import re, struct, sys
source = Path(sys.argv[1]).read_text(encoding='utf-8')
data = Path(sys.argv[2]).read_bytes()
patches = []
for match in re.finditer(r'patchDef[23](?:WS)?\s*\{\s*[^\n]+\n\s*\(\s*(\d+)\s+(\d+)[^\n]*\n(.*?)\n\s*\}', source, re.S):
    w, h = map(int, match.group(1, 2))
    points = [tuple(map(float, m.split()))[:3] for m in re.findall(r'\(\s*([^()]+)\s*\)', match.group(3)) if len(m.split()) >= 5]
    assert len(points) == w*h
    patches.append((w, h, points))
o, n = struct.unpack_from('<ii', data, 8+13*8)
vo, vn = struct.unpack_from('<ii', data, 8+10*8)
built = []
for i in range(o, o+n, 104):
    if struct.unpack_from('<i', data, i+8)[0] != 2:
        continue
    first, count = struct.unpack_from('<ii', data, i+12)
    built.append([(struct.unpack_from('<3f', data, vo+(first+j)*44), struct.unpack_from('<3f', data, vo+(first+j)*44+28)) for j in range(count)])
assert patches and len(patches) == len(built), (len(patches), len(built))
def key(points):
    return Counter(tuple(round(x, 3) for x in p) for p in points)
for w, h, points in patches:
    candidates = [b for b in built if key(p for p, n in b) == key(points)]
    assert len(candidates) == 1, 'Control points changed or missing'
    u = [points[1][i]-points[0][i] for i in range(3)]
    v = [points[w][i]-points[0][i] for i in range(3)]
    normal = [v[1]*u[2]-v[2]*u[1], v[2]*u[0]-v[0]*u[2], v[0]*u[1]-v[1]*u[0]]
    norm = next(n for p, n in candidates[0] if key([p]) == key([points[0]]))
    assert sum(a*b for a, b in zip(normal, norm)) > 0, 'BSP patch front face is inverted'
print(f'PASS: {len(patches)} patches retain control points and native front-face orientation')
