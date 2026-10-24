"""Compare saved brush half-spaces, entities and patches after an engine reload."""
from collections import Counter
from pathlib import Path
import math
import re
import sys

def geometry(path):
    text = Path(path).read_text(encoding='utf-8', errors='replace')
    # MAP braces need not occupy separate lines (the serializer may emit `}}`).
    text = re.sub(r'"(?:\\.|[^"\\])*"|[{}]',
                  lambda m: '\n' + m[0] + '\n' if m[0] in ('{', '}') else m[0], text)
    depth, brushes, faces = 0, [], []
    for line in text.splitlines():
        line = line.strip()
        if line == '{':
            depth += 1
            if depth == 2:
                faces = []
        elif line == '}':
            if depth == 2 and faces:
                brushes.append(faces)
            depth -= 1
        elif depth == 2 and line.startswith('('):
            points = [list(map(float, p.split())) for p in re.findall(r'\(([^)]+)\)', line)[:3]]
            a = [points[0][i] - points[1][i] for i in range(3)]
            b = [points[2][i] - points[1][i] for i in range(3)]
            n = [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
            length = math.sqrt(sum(x*x for x in n))
            assert length > 1e-10, 'Degenerate MAP plane'
            n = [x/length for x in n]
            faces.append((n, sum(n[i]*points[0][i] for i in range(3))))
    classes = Counter(re.findall(r'"classname"\s+"([^"]+)"', text))
    patches = re.findall(r'patchDef[23]', text)
    return brushes, classes, patches

if __name__ == '__main__':
    root = Path(sys.argv[1])
    a, ca, pa = geometry(root/'maps/roundtrip-first.map')
    b, cb, pb = geometry(root/'maps/roundtrip-second.map')
    assert len(a) == len(b) and ca == cb and pa == pb, 'Objects lost on reload'
    worst = 0
    for index, (before, after) in enumerate(zip(a, b)):
        assert len(before) == len(after), ('Face lost', index, len(before), len(after))
        for n, d in before:
            normal, dist = min(after, key=lambda p: sum((p[0][i]-n[i])**2 for i in range(3)))
            assert math.dist(n, normal) < 1e-6, ('Plane normal changed', index)
            worst = max(worst, abs(d-dist))
            assert abs(d-dist) < .005, ('Plane drift', index, d, dist)
    log = (root/'qconsole.log').read_text(errors='replace').lower()
    assert 'runaway loop' not in log and 'host_error' not in log, log[-20000:]
    counts = re.findall(r'"ftebroom_selection_count" is "(\d+)"', log)
    assert len(counts) == 2 and int(counts[0]) > 0 and counts[1] == '0', counts
    print(f'PASS: {len(a)} brushes, {len(pa)} patches; same entities/faces; maximum plane drift {worst:.6f}')
