from pathlib import Path
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_BACKUP_FAIL' not in log and 'FTEBROOM_BACKUP_PASS bounded_rotation_and_source' in log,log[-12000:]
copies=list((root/'autosave').glob('map-*.map'))
assert len(copies)==2
assert all(Path(p.with_suffix('.map.source').read_text())==root/'maps/qa_clip.map' for p in copies)
print('PASS: backup rotation, source manifests, nonempty saved maps')
