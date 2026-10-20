from pathlib import Path
import sys,re
root=Path(sys.argv[1]);folder=root/'Map projects/Карты тест'
source=(Path(__file__).parent/'fixtures/document.map').read_bytes()
assert (folder/'исходная карта.map').read_bytes()==source,'Open modified the original'
saved=(folder/'новая карта.map').read_bytes()
normalize=lambda data:[line.rstrip() for line in data.splitlines()]
assert normalize(saved)==normalize((folder/'round trip.map').read_bytes()),'External full MAP round-trip differs'
assert len(re.findall(rb'^\s*\( [-+\d.]+ [-+\d.]+ [-+\d.]+ \) \(',saved,re.M))==len(re.findall(rb'^\s*\( [-+\d.]+ [-+\d.]+ [-+\d.]+ \) \(',source,re.M))+6,'Save did not target the selected external file'
assert b'patchDef2' in saved and b'worldspawn' in saved
assert (folder/'через браузер.map').exists(),'File browser Save button did not save in the navigated directory'
assert len(re.findall(rb'^\s*\( [-+\d.]+ [-+\d.]+ [-+\d.]+ \) \(',(folder/'через браузер.map').read_bytes(),re.M))==18,'Browser Open selected the wrong map'
assert not list(folder.glob('*.tmp')),'Temporary save files leaked'
log=(root/'ftebroom/qconsole.log').read_text(errors='replace')
assert 'save failed:' not in log and 'Unknown command "ftebroom_test_filepath"' not in log
assert (root/'ftebroom/file-browser.png').exists()
print('PASS: external Unicode/space paths, original unchanged, Save As, subsequent Save, complete brush/entity/patch round-trip.')
