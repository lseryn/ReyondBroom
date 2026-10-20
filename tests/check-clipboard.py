from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_TRANSFORM_FAIL' not in log,log
for name in ['parse_colored_patch_without_entity','patch_preserves_subdivisions_colors','parse_standard_map','parse_flags_values','reject_missing_value','reject_unterminated_comment','reject_malformed_number','parse_does_not_mutate_history','export_selection','parse_own_export','export_preserves_object_count','paste_insert','parse_fixture_before_insert','insert_fixture_entities']:
 assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
assert not any(x in log for x in ['Host_Error','QC error','Program error']),log
def tokens(name):
 return re.findall(r'"(?:\\.|[^"\\])*"|[{}()\[\]]|[^\s{}()\[\]"]+', (p/('maps/clipboard_'+name+'.map')).read_text())
assert tokens('before')==tokens('undone'),'undo changed MAP'
assert tokens('pasted')==tokens('redone'),'redo changed MAP'
assert (p/'maps/clipboard_pasted.map').read_text().count('\n( ')==12
fixture=(p/'maps/clipboard_fixture.map').read_text()
assert fixture.count('info_player_deathmatch')==2
assert '42 123' in fixture and '47 128' in fixture
print('PASS: clipboard parser, export, insertion, attributes and MAP undo/redo')

native=(p/'maps/clipboard_native.map').read_text()
assert native.count('\n( ')==24, 'Native clipboard geometry count'
assert native.count('info_player_deathmatch')==3, 'Native clipboard entity count'
assert '42 123' in native and '47 128' in native
print('PASS: clipboard native/QC transfer (OS clipboard preserved)')
