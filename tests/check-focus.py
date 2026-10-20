from pathlib import Path
import sys
r=Path(sys.argv[1]);log=(r/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_CAMERA_FAIL' not in log,log[-12000:]
checks=['focus_started','focus_halfway','focus_finished','focus_keeps_angles','focus_no_history','move_position','move_keeps_2d']+[f'focus_center_{i}' for i in range(1,4)]+[f'focus_corner_{i}' for i in range(8)]
for name in checks:assert log.count('FTEBROOM_CAMERA_PASS '+name)>= (2 if name.startswith('focus_') else 1),name
assert (r/'maps/focus_selected.map').read_bytes()==(r/'maps/focus_after.map').read_bytes()
print('PASS: 34 focus/position checks, all bbox corners inside viewport, unchanged MAP.')
