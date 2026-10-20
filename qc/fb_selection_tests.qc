// SPDX-License-Identifier: GPL-2.0-or-later
int fb_selection_test_ids[5];
void fb_selection_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_SELECTION_PASS ":"FTEBROOM_SELECTION_FAIL ",name,"\n"));
}
vector fb_selection_test_pixel(int index)
{
    vector pixel=project([index*100-200,0,200]);pixel_z=0;return pixel;
}
void fb_selection_test_click(int index)
{
    vector pixel=fb_selection_test_pixel(index);
    fb_begin(pixel,0,cvar("ca_brush_view"));fb_finish(pixel,0,cvar("ca_brush_view"));
}
float fb_selection_testcommand()
{
    if(argv(0)!="ftebroom_test_selection") return FALSE;
    if(!cvar("ftebroom_skip_setup")) return TRUE;
    string mode=argv(1);
    if(mode=="setup") {
        selectedbrushmodel=1;
        static int oldids[128];static vector axes[1];static float distances[1];
        int oldcount=brush_findinvolume(1,axes,distances,0,oldids,__NULL__,128);
        fb_tx_begin("Selection fixture");
        for(int old=0;old<oldcount;old++) brush_history_delete(1,oldids[old]);
        fb_tx_commit();
        for(int i=0;i<5;i++) fb_selection_test_ids[i]=fb_createbox([i*100-200,0,200],'32 32 32');
        fb_selection_clear();
    } else if(mode=="gestures") {
        cvar_set("ftebroom_tool","0");cvar_set("ftebroom_shift","0");cvar_set("ftebroom_ctrl","1");
        fb_selection_clear();
        fb_selection_test_click(0);fb_selection_test_click(1);fb_selection_test_click(2);
        fb_selection_expect(selectedbrushcount==3,"ctrl_three");
        fb_selection_test_click(1);fb_selection_expect(selectedbrushcount==2,"ctrl_toggle");
        brush_undo();fb_selection_expect(selectedbrushcount==3,"toggle_undo");
        brush_redo();fb_selection_expect(selectedbrushcount==2,"toggle_redo");
        fb_selection_clear();brushface_select(1,fb_selection_test_ids[4],1);
        fb_selection_test_click(0);
        fb_selection_expect(selectedbrushcount==1 && selectedbrushes[0].id==fb_selection_test_ids[0] && selbrush_whole(&selectedbrushes[0]),"face_to_object");
        fb_selection_clear();int before=history;
        vector pixel=fb_selection_test_pixel(0);
        fb_begin(pixel,0,cvar("ca_brush_view"));
        for(int j=1;j<5;j++) fb_update(fb_selection_test_pixel(j),0,cvar("ca_brush_view"));
        fb_finish(fb_selection_test_pixel(4),0,cvar("ca_brush_view"));
        fb_selection_expect(selectedbrushcount==5 && history==before+1,"paint_one_transaction");
        brush_undo();fb_selection_expect(selectedbrushcount==0,"paint_undo");
        brush_redo();fb_selection_expect(selectedbrushcount==5,"paint_redo");
        brush_undo();int redoEnd=history_max;
        fb_begin(pixel,0,cvar("ca_brush_view"));fb_update(fb_selection_test_pixel(2),0,cvar("ca_brush_view"));fb_cancel();
        fb_selection_expect(!selectedbrushcount && history==before && history_max==redoEnd,"paint_cancel_preserves_redo");
        brush_redo();fb_selection_expect(selectedbrushcount==5,"cancel_redo");
        before=history;fb_begin(pixel,0,cvar("ca_brush_view"));fb_finish(pixel+'30 0 0',0,cvar("ca_brush_view"));
        fb_selection_expect(history>before && selectedbrushcount==5,"selected_ctrl_drag_duplicates");
        brush_undo();
        cvar_set("ftebroom_ctrl","0");fb_selection_test_click(0);
        fb_selection_expect(selectedbrushcount==1,"plain_click_replaces");
        fb_selection_clear();
        for(int step=0;step<3;step++) {
            fb_pick_query('-300 0 200','50 0 200',pixel,0,FB_HIT_BRUSH,FALSE);fb_selection_drill_hits(1);
            fb_selection_expect(selectedbrushcount==1 && selectedbrushes[0].id==fb_selection_test_ids[step],strcat("drill_forward_",itos(step)));
        }
        fb_pick_query('-300 0 200','50 0 200',pixel,0,FB_HIT_BRUSH,FALSE);fb_selection_drill_hits(-1);
        fb_selection_expect(selectedbrushcount==1 && selectedbrushes[0].id==fb_selection_test_ids[1],"drill_back");
        brush_undo();fb_selection_expect(selectedbrushcount==1 && selectedbrushes[0].id==fb_selection_test_ids[2],"drill_undo");
        fb_selection_clear();fb_entity_select(1,TRUE);fb_entity_select(2,TRUE);
        fb_tx_begin("Entity toggle");fb_entity_select(1,FALSE);fb_tx_commit();
        brush_undo();fb_selection_expect(fb_selected_entity_count==2 && fb_entity_selected(1) && fb_entity_selected(2),"entities_undo");
        brush_redo();fb_selection_expect(fb_selected_entity_count==1 && fb_entity_selected(2),"entities_redo");
        fb_selection_clear();
        for(int selected=0;selected<5;selected++) brush_select(1,fb_selection_test_ids[selected]);
    } else if(mode=="native") {
        fb_selection_clear();
    } else if(mode=="nativecheck") {
        fb_selection_expect(selectedbrushcount==2 && brush_isselected(1,fb_selection_test_ids[0]) && brush_isselected(1,fb_selection_test_ids[2]),"native_ctrl_clicks");
    } else if(mode=="doublecheck") {
        fb_selection_expect(selectedbrushcount>=5,"native_double_click");
    } else if(mode=="groups") {
        fb_document_tick();int group=-1,leaf=-1;
        for(int n=0;n<fb_node_count;n++) {
            fb_nodes[n].flags&=~(FB_NODE_HIDDEN|FB_NODE_LOCKED);
            if(fb_nodes[n].kind==FB_NODE_GROUP) group=n;
        }
        if(group>=0) for(int child=0;child<fb_node_count;child++) if(fb_nodes[child].kind==FB_NODE_BRUSH && fb_selection_descendant(child,group)) {leaf=child;break;}
        fb_selection_expect(group>=0 && leaf>=0,"group_fixture");
        if(leaf>=0) {
            fb_selection_expect(fb_selection_target(leaf)==group,"closed_group_target");
            fb_selection_click(group,0);
            fb_selection_expect(selectedbrushcount>=2 && fb_selected_entity_count==1,"group_select_descendants");
            fb_open_group=fb_nodes[group].id;
            fb_selection_expect(fb_selection_target(leaf)==leaf,"open_group_target");
            fb_open_group=0;
            vector groupPixel=project('0 -200 128');groupPixel_z=0;
            fb_selection_double(groupPixel,0);
            fb_selection_expect(fb_open_group==fb_nodes[group].id && !selectedbrushcount,"double_opens_group");
            fb_selection_double(groupPixel,0);
            fb_selection_expect(selectedbrushcount>=2 && fb_selected_entity_count==1,"double_selects_siblings");
            vector outside=project('-200 -200 128');outside_z=0;
            fb_selection_double(outside,0);
            fb_selection_expect(fb_open_group==0 && fb_selection_selected(group),"double_outside_closes");
            brush_undo();fb_selection_expect(fb_open_group==fb_nodes[group].id,"group_context_undo");
            brush_redo();fb_selection_expect(fb_open_group==0,"group_context_redo");
            fb_selection_clear();
            int entityA=-1,entityB=-1;
            for(int e=0;e<fb_node_count;e++) if(fb_nodes[e].kind==FB_NODE_ENTITY && fb_selection_leaf(e)) {
                if(entityA<0) entityA=fb_nodes[e].id;else entityB=fb_nodes[e].id;
            }
            fb_selection_expect(entityA>0 && entityB>0,"two_entity_fixture");
            fb_tx_begin("Select entities");fb_entity_select(entityA,TRUE);fb_entity_select(entityB,TRUE);fb_tx_commit();
            brush_undo();fb_selection_expect(fb_selected_entity_count==0,"real_entities_undo");
            brush_redo();fb_selection_expect(fb_entity_selected(entityA) && fb_entity_selected(entityB),"real_entities_redo");
        }
    }
    return TRUE;
}
