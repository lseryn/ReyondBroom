from pathlib import Path
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert '_FAIL' not in log, log[-24000:]
assert log.count('FTEBROOM_ENTITY_PASS ')==5, log[-24000:]
assert log.count('FTEBROOM_VERTEX_PASS ')==8, log[-24000:]
assert not any(x in log.lower() for x in ('runaway loop', 'mod by zero', 'overflowed', 'unable to load progs/player.mdl')), log[-24000:]
for name in ('point-visible','brush-entity-visible','cone32'):
    assert (root/(name+'.png')).is_file()
print('PASS: keyboard Delete/Undo for point and brush entities; cone32 topology, Undo, 2D and Alt vertical gestures.')
