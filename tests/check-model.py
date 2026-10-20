from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_TRANSFORM_FAIL' not in log,log
for name in ['new_submodel_name','new_submodel_precache','new_submodel_geometry','new_submodel_undo_entity','new_submodel_redo_geometry']:
 assert 'FTEBROOM_TRANSFORM_PASS '+name in log,name
def tokens(name):
 return re.findall(r'"(?:\\.|[^"\\])*"|[{}()\[\]]|[^\s{}()\[\]"]+', (p/('maps/model_'+name+'.map')).read_text())
assert tokens('before')==tokens('undone')
assert tokens('created')==tokens('redone')
assert (p/'maps/model_created.map').read_text().count('\n( ')==12
print('PASS: new brush model, serialization and complete MAP undo/redo')
