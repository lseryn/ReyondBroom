// SPDX-License-Identifier: GPL-2.0-or-later
void fb_select_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_SELECT_COMMAND_PASS ":"FTEBROOM_SELECT_COMMAND_FAIL ",name,"\n"));
}
float fb_select_testcommand()
{
    if(argv(0)!="ftebroom_test_select_commands" || !cvar("ftebroom_skip_setup")) return FALSE;
    static int ids[10];
    if(argv(1)=="lines") {
        fb_select_expect(fb_line_count>1,"line_index_loaded");
        fb_select_line(3);
        fb_select_expect(selectedbrushcount==1,"select_source_brush_line");
        int prior=history;fb_select_line(999999);
        fb_select_expect(history==prior && selectedbrushcount==1,"unknown_line_preserves_selection");
        fb_move_numeric('16 0 0');fb_selection_clear();fb_select_line(3);
        fb_select_expect(selectedbrushcount==1,"source_line_survives_edit");
        fb_selection_clear();
    } else if(argv(1)=="setup") {
        selectedbrushmodel=1;
        static int previous[128];static vector axes[1];static float distances[1];
        int n=brush_findinvolume(1,axes,distances,0,previous,__NULL__,128);
        fb_tx_begin("Fixture");
        for(int d=0;d<n;d++) brush_history_delete(1,previous[d]);
        fb_tx_commit();
        for(int i=0;i<10;i++) ids[i]=fb_createbox([i*64,0,64],'32 32 32');
        fb_selection_clear();
    } else if(argv(1)=="run") {
        fb_select_command("all");fb_select_expect(selectedbrushcount==10,"all");
        fb_select_command("invert");fb_select_expect(selectedbrushcount==0,"invert_all");
        fb_select_command("invert");fb_select_expect(selectedbrushcount==10,"invert_empty");
        fb_selection_clear();brush_select(1,ids[4]);fb_select_command("siblings");
        fb_select_expect(selectedbrushcount==10,"siblings");
        int selector=fb_createbox('64 0 64','170 80 80');
        int before=history;
        fb_select_command("touching");
        fb_select_expect(selectedbrushcount==3 && brush_get(1,selector,__NULL__,0,__NULL__)==0,"touch_three_delete_selector");
        brush_undo();fb_select_expect(selectedbrushcount==1 && history==before,"touch_one_undo");
        selector=selectedbrushes[0].id;
        fb_select_expect(brush_get(1,selector,__NULL__,0,__NULL__)==6,"undo_restores_selector");
        brush_redo();fb_select_expect(selectedbrushcount==3,"touch_redo");
        brush_undo();
        fb_select_command("inside");fb_select_expect(selectedbrushcount==3,"inside_three");
        brush_undo();
        cvar_set("ca_brush_view","3");
        fb_select_command("tall");fb_select_expect(selectedbrushcount==3,"tall_three");
        brush_undo();
        cvar_set("ca_brush_view","0");before=history;
        fb_select_command("tall");fb_select_expect(history==before && selectedbrushcount==1,"tall_reject_3d");
        fb_selection_clear();before=history;fb_select_command("inside");
        fb_select_expect(history==before,"empty_noop");
        fb_document_tick();
        for(int node=0;node<fb_node_count;node++) if(fb_nodes[node].kind==FB_NODE_BRUSH) {
            fb_nodes[node].flags=FB_NODE_LOCKED;break;
        }
        fb_select_command("all");fb_select_expect(selectedbrushcount==10,"locked_excluded");
    }
    return TRUE;
}
