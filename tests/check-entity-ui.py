from pathlib import Path
import re, sys
root = Path(sys.argv[1])
def text(name): return (root / ('maps/entity_ui_' + name + '.map')).read_text()
assert re.search(r'"message"\s+"Tabbed value"', text('tab')), text('tab')
assert re.search(r'"custom_key"\s+"custom_value"', text('added')), text('added')
assert not re.search(r'"custom_key"\s+"custom_value"', text('undo')), text('undo')
assert 'FTEBROOM_ENTITY_UI_FAIL' not in (root / 'qconsole.log').read_text(errors='replace')
print('PASS: native property Tab commit, Ctrl+Enter, key rename, value and Undo')

assert re.search(r'"custom_key"\s+"arrow_value"', text('arrow')), text('arrow')
assert '"custom_key"' not in text('removed'), text('removed')
assert re.search(r'"custom_key"\s+"arrow_value"', text('remove_undo'))
assert len(re.findall(r'^\( ', text('removed'), re.M)) == len(re.findall(r'^\( ', text('added'), re.M)), 'Delete in the property table deleted geometry'
print('PASS: arrow navigation, F2 editing, property Delete routing and Undo')
