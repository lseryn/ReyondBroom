from pathlib import Path
import sys
root=Path(sys.argv[1])
log=(root/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_SELECTION_FAIL' not in log, log[-20000:]
assert 'mod by zero' not in log
names=['ctrl_three','ctrl_toggle','toggle_undo','toggle_redo','face_to_object','paint_one_transaction','paint_undo','paint_redo','paint_cancel_preserves_redo','cancel_redo','selected_ctrl_drag_reserved','plain_click_replaces','drill_forward_0','drill_forward_1','drill_forward_2','drill_back','drill_undo','entities_undo','entities_redo','group_fixture','closed_group_target','group_select_descendants','open_group_target']
for name in names:
    assert log.count('FTEBROOM_SELECTION_PASS '+name+'\n') >= (1 if name.startswith(('group','closed','open')) else 2),name
assert (root/'maps/selection_before.map').read_bytes()==(root/'maps/selection_after.map').read_bytes()
for name in ['native_ctrl_clicks','native_double_click','double_opens_group','double_selects_siblings','double_outside_closes','group_context_undo','group_context_redo','two_entity_fixture','real_entities_undo','real_entities_redo']:
    assert 'FTEBROOM_SELECTION_PASS '+name in log,name
assert (root/'maps/selection_groups_before.map').read_bytes()==(root/'maps/selection_groups_after.map').read_bytes()
assert (root/'selection.png').exists()
print('PASS: 52 selection checks, two projections, complete MAP bytes unchanged.')
