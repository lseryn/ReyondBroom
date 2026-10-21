// SPDX-License-Identifier: GPL-2.0-or-later
void fb_organize_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_ORGANIZE_PASS ":"FTEBROOM_ORGANIZE_FAIL ",label,"\n"));}
float fb_organize_testcommand()
{
    if(argv(0)!="ftebroom_test_organize" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();int a=fb_createbox('0 0 64','64 64 64'),b=fb_createbox('128 0 64','64 64 64');brush_select(1,a);
    int marker=history;fb_visibility_command("hide");fb_document_tick();
    fb_organize_expect(!selectedbrushcount && fb_visibility_get(1,a) && fb_visibility_get(1,b),"hide_deselects");
    brush_undo();fb_organize_expect(history==marker && selectedbrushcount==2 && !fb_visibility_get(1,a),"hide_single_undo");
    fb_visibility_command("isolate");fb_document_tick();int hidden=0;
    for(int n=2;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_BRUSH && !fb_pick_allowed(n,0)) hidden++;
    fb_organize_expect(hidden>0 && selectedbrushcount==2,"isolate_other_brushes");
    fb_visibility_command("showall");fb_organize_expect(!fb_visibility_get(1,a),"show_all");
    marker=history;fb_group_create("Test group");fb_document_tick();int group=-1;
    for(int n=2;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_GROUP && fb_nodes[n].name=="Test group") group=n;
    fb_organize_expect(group>=2 && selectedbrushcount==2 && selectedbrushes[0].model!=1,"group_moves_brushes_to_model");
    int groupEntity=-1;if(group>=2) groupEntity=fb_nodes[group].id;
    fb_organize_expect(group>=2 && fb_selection_selected(group),"group_selected_as_unit");
    brush_undo();fb_organize_expect(history==marker && selectedbrushcount==2 && selectedbrushes[0].model==1,"group_single_undo");brush_redo();
    fb_organize_action("ungroup",0,"");fb_document_tick();
    fb_organize_expect(selectedbrushcount==2 && selectedbrushes[0].model==1 && terrain_edit(TEREDIT_ENT_GET,groupEntity)=="","ungroup_returns_to_parent");
    fb_organize_action("layernew",0,"Details");int layer=fb_active_layer;
    fb_organize_action("move",layer,"");fb_document_tick();int node=fb_organize_node(layer);
    fb_organize_expect(node>=2 && selectedbrushcount==2 && selectedbrushes[0].model!=1,"move_selection_to_layer");
    fb_organize_action("layerhidden",layer,"1");fb_document_tick();fb_organize_expect(!selectedbrushcount && !fb_pick_allowed(fb_organize_node(layer),0),"hidden_layer_deselects");
    fb_organize_action("layerhidden",layer,"0");fb_organize_action("layerlocked",layer,"1");fb_document_tick();
    fb_organize_expect(!fb_pick_allowed(fb_organize_node(layer),0) && fb_pick_allowed(fb_organize_node(layer),FB_PICK_LOCKED),"locked_layer_not_pickable");
    fb_organize_action("layerlocked",layer,"0");fb_organize_action("layerselect",layer,"");
    fb_organize_expect(selectedbrushcount==2,"select_layer_contents");
    marker=history;fb_organize_action("layerremove",0,"");fb_organize_expect(history==marker,"default_layer_cannot_be_removed");
    fb_organize_action("layeromit",layer,"1");fb_document_tick();node=fb_organize_node(layer);
    fb_organize_expect(fb_nodes[node].fields["_tb_layer_omit_from_export"]=="1","omit_layer_property");
    fb_group_create("Layer group");fb_document_tick();
    fb_organize_expect(selectedbrushcount==2,"group_inside_active_layer");
    fb_selection_clear();fb_createbox('512 0 64','64 64 64');fb_group_create("Merge A");fb_document_tick();int groupA=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP && fb_nodes[n].name=="Merge A")groupA=fb_nodes[n].id;
    fb_selection_clear();fb_createbox('640 0 64','64 64 64');fb_group_create("Merge B");fb_document_tick();
    fb_selection_set(fb_organize_node(groupA),TRUE);marker=history;fb_organize_action("mergegroups",0,"");fb_document_tick();int groups=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP && (fb_nodes[n].name=="Merge A" || fb_nodes[n].name=="Merge B"))groups++;
    fb_organize_expect(groups==1 && selectedbrushcount==2,"merge_groups_preserves_selection");
    brush_undo();fb_organize_expect(history==marker,"merge_groups_single_undo");
    fb_organize_action("layernew",0,"Batch layer");int batchLayer=fb_active_layer;marker=history;
    tokenize(sprintf("ftebroom_layer_batch layerhidden %i 1 %i 1",layer,batchLayer));fb_entity_command();fb_document_tick();
    fb_organize_expect(!fb_pick_allowed(fb_organize_node(layer),0) && !fb_pick_allowed(fb_organize_node(batchLayer),0),"batch_hide_layers");
    brush_undo();fb_document_tick();fb_organize_expect(history==marker && fb_pick_allowed(fb_organize_node(layer),0) && fb_pick_allowed(fb_organize_node(batchLayer),0),"batch_layers_single_undo");
    return TRUE;
}
