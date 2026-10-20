"""Validate entity membership, metadata, patches and history save checkpoints."""
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
states = re.findall(r'FTEBROOM_DOCUMENT revision=(\d+) saved=(\d+) dirty=(\d+) nodes=(\d+)', log)
assert [int(s[2]) for s in states] == [0, 0, 1, 0, 1, 0, 1, 1], states
assert states[4][0] != states[7][0], 'An edit after undo reused a saved revision'
assert 'name=Test Group' in log and 'name=Test Layer' in log
assert re.search(r'kind=5 model=\d+ id=\d+ parent=\d+', log), 'Patch node is missing'

def entities(path):
    result, depth, start = [], 0, 0
    text = path.read_text()
    for i, c in enumerate(text):
        if c == '{':
            if not depth:
                start = i
            depth += 1
        if c == '}':
            depth -= 1
            if not depth:
                block = text[start:i+1]
                keys = dict(re.findall(r'^"([^"]+)" "([^"]*)"$', block, re.M))
                faces = sorted(line.strip() for line in block.splitlines() if re.match(r'^\( [-+\d].*\) \( ', line))
                result.append((keys, faces, 'patchDef2' in block, block))
    return result

before = entities(root / 'maps/document.map')
after = entities(root / 'maps/document_roundtrip.map')
assert len(before) == len(after), (len(before), len(after))
for a, b in zip(before, after):
    assert a[:3] == b[:3], (a[:3], b[:3])
    if a[2]:
        # Numeric formatting may change but patch control points and UVs must not.
        values = lambda s: [float(x) for x in re.findall(r'[-+]?\d+(?:\.\d+)?', s.split('patchDef2')[1])]
        assert values(a[3])[:2] == values(b[3])[:2]
        assert values(a[3])[5:] == values(b[3])[5:]
backups = list((root / 'autosave').glob('document_checkpoint-*.map'))
assert backups and all(p.stat().st_size > 0 for p in backups)
assert 'FTEBroom save failed' not in log
print('PASS: complete entity/brush/patch round-trip, save checkpoints, undo/redo, history branching and autosave.')
