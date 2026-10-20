from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_TRANSFORM_FAIL' not in log,log
for name in ['group_fixture_exists','select_closed_group_members','duplicate_group_selection','duplicate_independent_group_entities','export_duplicated_group','parse_duplicated_group','parse_group_before_paste','paste_group','paste_preserves_group_entities']:
 assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
assert not any(x in log for x in ['Host_Error','QC error','Program error']),log
def tokens(name):
 return re.findall(r'"(?:\\.|[^"\\])*"|[{}()\[\]]|[^\s{}()\[\]"]+', (p/('maps/containers_'+name+'.map')).read_text())
assert tokens('before')==tokens('undone'),'undo changed MAP'
assert tokens('duplicated')==tokens('redone'),'redo changed MAP'
for name,expected in [('before',18),('duplicated',30),('pasted',42)]:
 text=(p/f'maps/containers_{name}.map').read_text()
 assert text.count('\n( ')==expected,(name,text.count('\n( '))
print('PASS: group duplication and clipboard preserve entities, geometry and complete undo/redo')
