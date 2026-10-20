// SPDX-License-Identifier: GPL-2.0-or-later
void fb_attributes_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_ATTRIBUTES_PASS ":"FTEBROOM_ATTRIBUTES_FAIL ",name,"\n"));
}
void fb_attributes_check(string label)
{
    static brushface_t faces[64];int flags=0,value=0;
    if(selectedbrushcount!=1) {fb_attributes_expect(FALSE,label);return;}
    int count=brush_get(selectedbrushes[0].model,selectedbrushes[0].id,faces,64,__NULL__);
    for(int f=0;f<count;f++) {flags+=faces[f].surfaceflags;value+=faces[f].surfacevalue;}
    fb_attributes_expect(count==6 && flags==267 && value==753,label);
}
float fb_attributes_testcommand()
{
    if(argv(0)!="ftebroom_test_attributes" || !cvar("ftebroom_skip_setup")) return FALSE;
    if(argv(1)=="load") {
        fb_document_tick();fb_selection_clear();
        for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_BRUSH) {brush_select(fb_nodes[n].model,fb_nodes[n].id);break;}
        fb_attributes_check("loaded_flags_values");
        fb_move_numeric('16 32 48');
    } else if(argv(1)=="moved") {
        fb_attributes_check("networked_move_preserves_attributes");
        brush_undo();fb_attributes_check("undo_attributes");
        brush_redo();fb_attributes_check("redo_attributes");
        brush_undo();fb_duplicate_numeric('32 0 0');
    } else if(argv(1)=="duplicated") {
        fb_attributes_check("networked_duplicate_attributes");
        brush_undo();fb_attributes_check("duplicate_undo_attributes");
    }
    return TRUE;
}
