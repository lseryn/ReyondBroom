// SPDX-License-Identifier: GPL-2.0-or-later
void fb_repeat_expect(int ok,string label){print(strcat(ok?"FTEBROOM_REPEAT_PASS ":"FTEBROOM_REPEAT_FAIL ",label,"\n"));}
int fb_repeat_testcommand()
{
    if(argv(0)!="ftebroom_test_repeat" || !cvar("ftebroom_skip_setup"))return FALSE;
    fb_tool_deactivate();int id=fb_createbox('0 0 0','64 32 16');
    fb_selection_clear();brush_select(1,id);fb_document_tick();fb_repeat_clear();
    fb_transform_capture();fb_transform_duplicate=TRUE;fb_transform_commit('0 0 16');fb_transform_clear();
    fb_document_tick();fb_transform_capture();fb_affine_rotate('0 0 1',15,fb_affine_center());fb_transform_clear();
    fb_repeat_expect(fb_repeat_count==2,"duplicate_rotate_recorded");
    int marker=history;fb_repeat_run();
    fb_repeat_expect(fb_repeat_count==2,"replay_does_not_record_itself");
    fb_transform_capture();vector center=(fb_transform_items[0].low+fb_transform_items[0].high)*0.5;fb_transform_clear();
    fb_repeat_expect(fabs(center_z-32)<0.001,"duplicate_moves_current_selection");
    brush_undo();fb_repeat_expect(history==marker,"replay_single_undo");brush_redo();
    for(int i=0;i<9;i++)fb_repeat_run();
    fb_transform_capture();center=(fb_transform_items[0].low+fb_transform_items[0].high)*0.5;fb_transform_clear();
    fb_repeat_expect(fabs(center_z-176)<0.001 && selectedbrushcount==1,"ten_replays_keep_latest_duplicate_selected");
    fb_tx_begin("Select original");fb_selection_clear();brush_select(1,id);fb_tx_commit();
    fb_repeat_expect(fb_repeat_count==0,"selection_change_clears_sequence");
    fb_repeat_move('1 0 0',FALSE);fb_repeat_clear();fb_repeat_expect(fb_repeat_count==0,"explicit_clear");
    return TRUE;
}
