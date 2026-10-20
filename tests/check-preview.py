from pathlib import Path
import sys

root = Path(sys.argv[1])
log = (root / 'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_PREVIEW moving=1 replaced=1' in log, log[-3000:]
assert (root / 'maps/preview_start.map').read_bytes() == (root / 'maps/preview_cancel.map').read_bytes()
for name in ('front', 'back', 'move', 'cancel'):
    assert (root / f'preview_{name}.png').stat().st_size > 1000
    assert f'Wrote $basedir/ftebroom/preview_{name}.png' in log
print('PASS: moving preview replaces the source; cancel preserves the complete MAP. Inspect four preview screenshots for visual acceptance.')
