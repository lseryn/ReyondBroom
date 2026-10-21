from pathlib import Path
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_CLIP_FAIL' not in log,log[-16000:]
assert log.count('FTEBROOM_CLIP_PASS ')==16,log[-16000:]
assert (root/'clip-interaction.png').exists()
print('PASS: 16 clip interaction, topology, attributes and history checks')
