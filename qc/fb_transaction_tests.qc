// SPDX-License-Identifier: GPL-2.0-or-later
void fb_test_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_HISTORY_PASS ":"FTEBROOM_HISTORY_FAIL ",name,"\n"));
}
void fb_test_select(int model,int id)
{
    fb_tx_begin("Select");brush_deselectall();brush_select(model,id);fb_tx_commit();
}
float fb_transaction_testcommand()
{
    if(argv(0)!="ftebroom_test_history") return FALSE;
    if(!cvar("ftebroom_skip_setup")) return TRUE;
    string mode=argv(1);
    if(mode=="state") {
        print(sprintf("FTEBROOM_DEBUG selected=%i context=%g tool=%g history=%i\n",selectedbrushcount,cvar("ftebroom_ctx_selection"),cvar("ftebroom_tool"),history));
        if(selectedbrushcount) {
            int *words=(int*)&selectedbrushes[0].facemask;
            print(sprintf("FTEBROOM_DEBUG maskwords=%i %i\n",words[0],words[1]));
        }
    } else if(mode=="selection") {
        int a=selectedbrushes[0].id,model=selectedbrushes[0].model;
        int b=fb_createbox('192 0 64','64 64 128');
        brush_deselectall();
        fb_test_select(model,a);fb_test_select(model,b);brush_undo();
        fb_test_expect(selectedbrushcount==1 && selectedbrushes[0].id==a,"select_A");
        brush_undo();fb_test_expect(selectedbrushcount==0,"select_empty");
        brush_redo();brush_redo();
        fb_test_expect(selectedbrushcount==1 && selectedbrushes[0].id==b,"select_B_redo");
    } else if(mode=="cancel") {
        int before=history,redo=history_max;
        fb_tx_begin("Cancelled compound edit");
        fb_move_numeric('32 0 0');
        fb_tx_begin("Nested");fb_move_numeric('0 32 0');fb_tx_commit();
        fb_move_numeric('0 0 32');
        fb_tx_cancel();
        fb_test_expect(history==before && history_max==redo,"cancel_history");
    } else if(mode=="count") {
        int count=0;float stamp=0;
        for(int i=history_min;i<history;i++) {
            float next=historyring[i&(historyring_length-1)].timestamp;
            if(i==history_min || stamp!=next) count++;
            stamp=next;
        }
        print(sprintf("FTEBROOM_HISTORY_COUNT %s %i\n",argv(2),count));
    } else if(mode=="entities") {
        string original=strzone(terrain_edit(TEREDIT_ENT_GET,0));
        fb_tx_begin("Entity property");fb_tx_entity_set(0,strcat(original,"\n\"test_key\" \"value\"\n"),HIST_ENTITY);fb_tx_commit();
        brush_undo();fb_test_expect(original==terrain_edit(TEREDIT_ENT_GET,0),"entity_undo");
        brush_redo();fb_test_expect(original!=terrain_edit(TEREDIT_ENT_GET,0),"entity_redo");
        brush_undo();
        fb_tx_begin("Layer flags");fb_tx_entity_set(0,strcat(original,"\n\"_tb_layer_hidden\" \"1\"\n"),HIST_NODEFLAGS);fb_tx_commit();
        brush_undo();fb_test_expect(original==terrain_edit(TEREDIT_ENT_GET,0),"flags_undo");
        fb_tx_begin("Parent group");fb_tx_entity_set(0,strcat(original,"\n\"_tb_group\" \"20\"\n"),HIST_TREE);fb_tx_commit();
        brush_undo();fb_test_expect(original==terrain_edit(TEREDIT_ENT_GET,0),"tree_undo");
        strunzone(original);
    } else if(mode=="large") {
        int largeBefore=history;
        fb_tx_begin("Large edit");
        // Exercise allocator growth without flooding FTE's brush-edit network queue.
        for(int i=0;i<600;i++) {
            history_t *entry=history_allocate();entry->kind=HIST_SELECTION;
            entry->entitybefore=-1;entry->entityafter=-1;
        }
        fb_move_numeric('16 0 0');
        fb_tx_commit();
        fb_test_expect(historyring_length>=1024,"ring_growth");
        brush_undo();fb_test_expect(history==largeBefore,"large_single_undo");
    } else if(mode=="multi") {
        int multiA=selectedbrushes[0].id,multiModel=selectedbrushes[0].model;
        fb_createbox('192 0 64','64 64 128');
        brush_select(multiModel,multiA);
        fb_test_expect(selectedbrushcount==2,"multi_selection");
    } else if(mode=="fixture") {
        string fixtureBefore=strzone(terrain_edit(TEREDIT_ENT_GET,3));
        fb_tx_set_key(3,"speed","200",HIST_ENTITY);
        brush_undo();fb_test_expect(fixtureBefore==terrain_edit(TEREDIT_ENT_GET,3),"door_property_undo");
        strunzone(fixtureBefore);
        fb_tx_set_key(2,"_tb_layer_hidden","0",HIST_NODEFLAGS);fb_document_rebuild();
        for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].name=="Test Layer")
            fb_test_expect(!(fb_nodes[i].flags&FB_NODE_HIDDEN),"layer_flag_changed");
        brush_undo();fb_document_rebuild();
        for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].name=="Test Layer")
            fb_test_expect(!!(fb_nodes[i].flags&FB_NODE_HIDDEN),"layer_flag_undo");
        fb_tx_set_key(4,"_tb_group","",HIST_TREE);fb_document_rebuild();
        for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].name=="info_player_deathmatch")
            fb_test_expect(fb_nodes[i].parent==1,"tree_reparented");
        brush_undo();fb_document_rebuild();
        for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].name=="info_player_deathmatch")
            fb_test_expect(fb_nodes[fb_nodes[i].parent].name=="Test Group","tree_parent_undo");
    } else if(mode=="overflow") {
        cvar_set("ftebroom_undo_levels","2");
        for(int i=0;i<4;i++) fb_move_numeric('16 0 0');
        int end=history;
        brush_undo();brush_undo();
        int oldest=history;brush_undo();
        fb_test_expect(history==oldest && history<end,"whole_transaction_eviction");
        brush_redo();brush_redo();cvar_set("ftebroom_undo_levels","512");
    }
    return TRUE;
}
