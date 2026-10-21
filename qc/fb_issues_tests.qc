// SPDX-License-Identifier: GPL-2.0-or-later
string fb_entity_field(int id,string key);
void fb_issues_expect(int ok,string label){print(strcat(ok?"FTEBROOM_ISSUES_PASS ":"FTEBROOM_ISSUES_FAIL ",label,"\n"));}
int fb_issue_find(int entityId,int type)
{
    for(int i=0;i<fb_issue_count;i++)if(fb_issues[i].type==type && fb_nodes[fb_issues[i].node].id==entityId)return i;
    return -1;
}
int fb_issues_testcommand()
{
    if(argv(0)!="ftebroom_test_issues" || !cvar("ftebroom_skip_setup"))return FALSE;
    fb_tool_deactivate();fb_entity_create("light",FALSE,'128 0 128');int light=fb_selected_entity();
    fb_tx_set_key(light,"target","missing-target",HIST_ENTITY);
    fb_tx_set_key(light,"noise","sound\\test.wav",HIST_ENTITY);
    fb_tx_set_key(light,"message","A \"quoted\" message",HIST_ENTITY);
    fb_issues_scan();
    fb_issues_expect(fb_issue_find(light,11)>=0,"missing_link_detected");
    fb_issues_expect(fb_issue_find(light,10)>=0,"backslash_path_detected");
    fb_issues_expect(fb_issue_find(light,9)>=0,"quote_detected");
    int marker=history,index=fb_issue_find(light,11);
    tokenize(sprintf("ftebroom_issue fix %i %i",index,fb_issue_epoch));fb_issues_command();
    fb_issues_expect(fb_entity_field(light,"target")=="","delete_property_fix");
    brush_undo();fb_issues_expect(history==marker && fb_entity_field(light,"target")=="missing-target","fix_single_undo");
    fb_issues_scan();index=fb_issue_find(light,10);
    tokenize(sprintf("ftebroom_issue fix %i %i",index,fb_issue_epoch));fb_issues_command();
    fb_issues_expect(fb_entity_field(light,"noise")=="sound/test.wav","path_fix");
    fb_issues_scan();index=fb_issue_find(light,9);
    tokenize(sprintf("ftebroom_issue fix %i %i",index,fb_issue_epoch));fb_issues_command();
    fb_issues_expect(fb_entity_field(light,"message")=="A 'quoted' message","quote_fix");
    int id=fb_createbox('0.25 0 128','64 64 32');fb_issues_scan();
    fb_issues_expect(fb_issue_find(id,14)>=0,"fractional_vertices_detected");
    index=fb_issue_find(id,14);marker=history;int oldEpoch=fb_issue_epoch;
    fb_createbox('0 200 128','64 64 32');fb_document_tick();int current=history;
    tokenize(sprintf("ftebroom_issue fix %i %i",index,oldEpoch));fb_issues_command();
    fb_issues_expect(history==current,"stale_issue_does_not_modify_new_selection");
    string savedBounds=strzone(cvar_string("ftebroom_map_bounds"));
    cvar_set("ftebroom_map_bounds","-16 -16 -16 16 16 16");fb_issues_scan();
    fb_issues_expect(fb_issue_find(light,16)>=0,"soft_bounds_detected");
    cvar_set("ftebroom_map_bounds",savedBounds);strunzone(savedBounds);
    fb_tx_begin("Test mod list");fb_tx_set_key(0,"_tb_mod","missing-a;missing-b",HIST_ENTITY);fb_tx_commit();fb_issues_scan();
    marker=history;
    tokenize(sprintf("ftebroom_issue removemod missing-a %i",fb_issue_epoch));fb_issues_command();
    fb_issues_expect(fb_entity_field(0,"_tb_mod")=="missing-b","remove_missing_mod_preserves_other_mods");
    brush_undo();fb_issues_expect(history==marker && fb_entity_field(0,"_tb_mod")=="missing-a;missing-b","remove_mod_single_undo");
    fb_issues_scan();return TRUE;
}
