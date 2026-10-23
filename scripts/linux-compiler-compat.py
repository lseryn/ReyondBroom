"""Apply allocation-equivalent GCC 13 fixes to the pinned compiler sources."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
changes = {
    'common/polylib.cc': [('offsetof(winding_t, p[w->numpoints])', 'offsetof(winding_t, p) + w->numpoints * sizeof(w->p[0])')],
    'qbsp/winding.cc': [('offsetof(winding_t, points[w->numpoints])', 'offsetof(winding_t, points) + w->numpoints * sizeof(w->points[0])')],
    'qbsp/util.cc': [('offsetof(winding_t, points[cElements])', 'offsetof(winding_t, points) + cElements * sizeof(((winding_t*)0)->points[0])')],
    'vis/vis.cc': [('offsetof(winding_t, points[points])', 'offsetof(winding_t, points) + points * sizeof(((winding_t*)0)->points[0])'), ('offsetof(winding_t, points[w->numpoints])', 'offsetof(winding_t, points) + w->numpoints * sizeof(w->points[0])')],
}
for name, replacements in changes.items():
    path = root / 'ericw-tools-0.18.1' / name
    text = path.read_text()
    for old, new in replacements:
        assert old in text or new in text, (path, old)
        text = text.replace(old, new)
    path.write_text(text)
path = root / 'netradiant-custom-20260114/tools/quake3/q3map2/q3map2.h'
text = path.read_text()
for member, kind in [('xyz', 'Vector3'), ('st', 'Vector2'), ('normal', 'Vector3')]:
    text = text.replace('.' + member + '{ 0 }', '.' + member + ' = ' + kind + '( 0 )')
path.write_text(text)
