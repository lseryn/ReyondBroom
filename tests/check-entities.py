from pathlib import Path
import sys
root=Path(sys.argv[1])
log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_ENTITY_FAIL' not in log,log[-24000:]
assert log.count('FTEBROOM_ENTITY_PASS ')==28,log[-24000:]
assert (root/'entities.png').exists()
assert 'Entity test map' in (root/'maps/entities.map').read_text()
assert 'info_player_deathmatch' in (root/'data'/'ftebroom-entity-definitions.txt').read_text()
print('PASS: 28 entity creation, ownership, properties, bounds and history checks')
