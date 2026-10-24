// SPDX-License-Identifier: GPL-3.0-or-later
float fb_bevel_test_volume()
{
    float volume=0;for(int i=0;i<selectedbrushcount;i++){fb_poly_t poly={0};if(fb_poly_from_brush(selectedbrushes[i].model,selectedbrushes[i].id,&poly))volume+=poly.volume;fb_poly_free(&poly);}return volume;
}
void fb_bevel_extended_tests()
{
    fb_tool_deactivate();fb_selection_clear();fb_createbox('0 0 64','128 128 128');fb_document_tick();int originalHistory=history;
    cvar_set("ftebroom_bevel_radius","16");cvar_set("ftebroom_bevel_segments","3");cvar_set("ftebroom_bevel_profile","0.5");cvar_set("ftebroom_bevel_clamp","1");cvar_set("ftebroom_bevel_keep","0");cvar_set("ftebroom_bevel_extended","0");
    for(int mode=1;mode<=2;mode++){
        fb_tool_activate(mode==1?FB_TOOL_EDGE:FB_TOOL_VERTEX);fb_vertex_deselect();fb_vertex_handles[0].selected=TRUE;cvar_set("ftebroom_bevel_mode",itos(mode));
        tokenize("ftebroom_generator preview bevel");fb_generator_command();fb_transform_expect(fb_generator_count>0&&history==originalHistory,mode==1?"bevel53_edge_command_preview":"bevel53_vertex_command_preview");
        tokenize("ftebroom_generator preview bevel");fb_generator_command();fb_transform_expect(fb_generator_count>0,"bevel53_repeated_preview");fb_transform_expect(cvar("ftebroom_tool")==fb_vertex_mode&&!fb_vertex_scope,"bevel54_restored_tool");
        tokenize("ftebroom_generator apply bevel");fb_generator_command();fb_transform_expect(fb_bevel_test_volume()<128*128*128&&history!=originalHistory,"bevel53_command_apply");brush_undo();fb_transform_expect(history==originalHistory&&selectedbrushcount==1,"bevel53_command_undo");
    }
    fb_tool_deactivate();cvar_set("ftebroom_bevel_mode","0");cvar_set("ftebroom_bevel_keep","1");fb_tx_begin("Bevel offcuts");int valid=fb_bevel_apply();fb_transform_expect(valid&&selectedbrushcount>1&&fabs(fb_bevel_test_volume()-128*128*128)<16,"bevel53_legacy_offcuts_volume");fb_tx_cancel();
    fb_tool_activate(FB_TOOL_EDGE);fb_vertex_deselect();fb_vertex_handles[0].selected=TRUE;cvar_set("ftebroom_bevel_mode","1");cvar_set("ftebroom_bevel_extended","1");
    for(int curve=-1;curve<=1;curve++){
        fb_tool_activate(FB_TOOL_EDGE);fb_vertex_deselect();fb_vertex_handles[0].selected=TRUE;
        cvar_set("ftebroom_bevel_curve",itos(curve));cvar_set("ftebroom_bevel_proportion","0.35");fb_tx_begin("Extended bevel");valid=fb_bevel_apply();print(strcat("BEVEL53 ",fb_geom_error,"\n"));
        fb_transform_expect(valid&&selectedbrushcount>1&&fabs(fb_bevel_test_volume()-128*128*128)<16,"bevel53_extended_offcuts_volume");fb_tx_cancel();
    }
    fb_tool_activate(FB_TOOL_EDGE);fb_vertex_deselect();fb_vertex_handles[0].selected=TRUE;
    cvar_set("ftebroom_bevel_keep","0");cvar_set("ftebroom_bevel_curve","-1");tokenize("ftebroom_generator apply bevel");fb_generator_command();
    float carved=fb_bevel_test_volume();fb_transform_expect(history!=originalHistory&&carved>0&&carved<128*128*128,"bevel53_inward_apply");brush_undo();fb_transform_expect(history==originalHistory,"bevel53_inward_undo");brush_redo();fb_transform_expect(fabs(fb_bevel_test_volume()-carved)<16,"bevel53_inward_redo");
    brush_undo();fb_tool_deactivate();cvar_set("ftebroom_bevel_mode","0");cvar_set("ftebroom_bevel_radius","10000");cvar_set("ftebroom_bevel_keep","1");cvar_set("ftebroom_bevel_segments","2");cvar_set("ftebroom_bevel_curve","-0.5");cvar_set("ftebroom_bevel_proportion","0");
    fb_tx_begin("Clamp all edges");valid=fb_bevel_apply();print(strcat("BEVEL53 clamp ",fb_geom_error,"\n"));fb_transform_expect(valid&&fabs(fb_bevel_test_volume()-128*128*128)<32,"bevel53_clamp_volume");fb_tx_cancel();
    cvar_set("ftebroom_bevel_radius","16");cvar_set("ftebroom_bevel_segments","3");cvar_set("ftebroom_bevel_keep","0");
    fb_tool_activate(FB_TOOL_EDGE);fb_vertex_deselect();fb_vertex_handles[0].selected=TRUE;cvar_set("ftebroom_bevel_mode","1");tokenize("ftebroom_generator apply bevel");fb_generator_command();
    fb_camera_position('240 -280 220');setproperty(VF_CL_VIEWANGLES,'25 130 0');
}
