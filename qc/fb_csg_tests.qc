// SPDX-License-Identifier: GPL-2.0-or-later
void fb_csg_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_CSG_PASS ":"FTEBROOM_CSG_FAIL ",label,"\n"));}
float fb_csg_selected_volume()
{
    float volume=0;
    for(int b=0;b<selectedbrushcount;b++) {fb_poly_t poly={0};fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&poly);volume+=poly.volume;fb_poly_free(&poly);}
    return volume;
}
float fb_csg_testcommand()
{
    if(argv(0)!="ftebroom_test_csg" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();cvar_set("ca_grid","16");
    int a=fb_createbox('0 0 256','256 256 256');int marker=history;
    fb_csg("hollow");
    fb_csg_expect(selectedbrushcount==6,"hollow_six_walls");
    fb_csg_expect(fabs(fb_csg_selected_volume()-(256*256*256-224*224*224))<8,"hollow_volume");
    brush_undo();fb_csg_expect(history==marker && selectedbrushcount==1,"hollow_single_undo");
    brush_redo();fb_csg_expect(selectedbrushcount==6,"hollow_redo");brush_undo();fb_delete_selection();
    a=fb_createbox('0 0 256','128 128 128');
    int b=fb_createbox('64 0 256','128 128 128');brush_select(1,a);marker=history;
    fb_csg("intersect");
    fb_csg_expect(selectedbrushcount==1 && fabs(fb_csg_selected_volume()-64*128*128)<2,"intersection_volume");
    brush_undo();fb_csg_expect(history==marker && selectedbrushcount==2,"intersection_undo");
    fb_csg("merge");fb_csg_expect(selectedbrushcount==1 && fabs(fb_csg_selected_volume()-192*128*128)<2,"merge_volume");
    brush_undo();fb_delete_selection();
    a=fb_createbox('0 0 256','128 128 128');b=fb_createbox('256 0 256','128 128 128');brush_select(1,a);marker=history;
    fb_csg("intersect");fb_csg_expect(history==marker && selectedbrushcount==2,"empty_intersection_no_change");fb_delete_selection();
    a=fb_createbox('0 0 256','256 256 256');b=fb_createbox('0 0 256','128 128 128');
    fb_document_tick();int hidden=-1;
    for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_BRUSH && fb_nodes[n].id!=a && fb_nodes[n].id!=b) {
        fb_nodes[n].flags|=FB_NODE_HIDDEN;hidden=n;
    }
    marker=history;fb_csg("subtract");
    fb_csg_expect(selectedbrushcount==6,"subtract_six_fragments");
    fb_csg_expect(fabs(fb_csg_selected_volume()-(256*256*256-128*128*128))<8,"subtract_volume");
    fb_csg_expect(!brush_get(1,b,__NULL__,0,__NULL__),"cutters_deleted");
    int untouched=TRUE;
    if(hidden>=0) untouched=brush_get(fb_nodes[hidden].model,fb_nodes[hidden].id,__NULL__,0,__NULL__)>0;
    fb_csg_expect(untouched,"hidden_brush_protected");
    brush_undo();fb_csg_expect(history==marker && selectedbrushcount==1,"subtract_single_undo");
    return TRUE;
}
