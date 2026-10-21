from pathlib import Path
import sys
root=Path(sys.argv[1]);log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_FILTER_FAIL' not in log,log[-24000:]
assert log.count('FTEBROOM_FILTER_PASS ')==19,log[-24000:]
assert 'FTEBROOM_EXPORT_PASS native_destination_preserves_document' in log, log[-24000:]
export=(root.parent/'exported map.map').read_text()
assert '"worldspawn"' in export and '"target_relay"' in export
assert '_tb_' not in export and 'Omitted geometry' not in export and '"func_group"' not in export
assert '"Omitted geometry"' in (root/'maps/filters.map').read_text()
assert (root/'filters.png').exists()
print('PASS: 19 filters, tags, entity links, group scope and export checks')
