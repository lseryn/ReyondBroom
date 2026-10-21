// SPDX-License-Identifier: GPL-2.0-or-later
void fb_scale_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_SCALE_PASS ":"FTEBROOM_SCALE_FAIL ",label,"\n"));}
float fb_scale_testcommand()
{
    if(argv(0)!="ftebroom_test_scale" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();cvar_set("ca_grid","16");fb_createbox('0 0 64','128 128 128');
    fb_tool_activate(FB_TOOL_SCALE);cvar_set("ca_brush_view","2");cvar_set("ca_brush_viewsize","512");fb_view_prepare();
    fb_scale_capture();fb_scale_make_handles(2);fb_scale_expect(fb_scale_count==8,"eight_2d_handles");
    fb_scale_make_handles(0);fb_scale_expect(fb_scale_count==26,"twenty_six_3d_handles");
    vector start=project('64 0 64'),end=project('96 0 64');start_z=end_z=0;int marker=history;
    fb_scale_down(start,0,2);fb_scale_move(end,0,2);
    fb_scale_expect(fb_scale_valid && history==marker,"preview_without_history");fb_tool_escape();
    fb_scale_expect(!fb_scale_drag && history==marker,"escape_cancels_scale");
    fb_scale_down(start,0,2);fb_scale_up(end,0,2);static vector bounds[2];
    brush_getfacepoints(1,selectedbrushes[0].id,0,bounds,2);
    fb_scale_expect(bounds[0]=='-64 -64 0' && bounds[1]=='96 64 128',"opposite_side_anchor");
    brush_undo();fb_scale_expect(history==marker,"scale_single_undo");
    fb_scale_down(start,1,2);fb_scale_up(end,1,2);brush_getfacepoints(1,selectedbrushes[0].id,0,bounds,2);
    fb_scale_expect(bounds[0]=='-96 -64 0' && bounds[1]=='96 64 128',"alt_center_anchor");brush_undo();
    cvar_set("ftebroom_shift","1");fb_scale_down(start,0,2);fb_scale_up(end,0,2);cvar_set("ftebroom_shift","0");
    brush_getfacepoints(1,selectedbrushes[0].id,0,bounds,2);
    fb_scale_expect(bounds[1]-bounds[0]=='160 128 160',"shift_proportional_2d");brush_undo();
    fb_scale_numeric('128 32 64',TRUE);brush_getfacepoints(1,selectedbrushes[0].id,0,bounds,2);
    fb_scale_expect(bounds[1]-bounds[0]=='128 32 64',"absolute_size");brush_undo();
    marker=history;fb_scale_numeric('0 1 1',FALSE);fb_scale_expect(history==marker,"zero_factor_rejected");
    fb_tool_activate(FB_TOOL_SHEAR);start=project('64 0 64');end=project('64 0 96');start_z=end_z=0;
    fb_scale_down(start,0,2);fb_scale_up(end,0,2);
    fb_poly_t poly={0};fb_poly_from_brush(1,selectedbrushes[0].id,&poly);int correct=TRUE;
    for(int v=0;v<poly.nv;v++) {
        vector p=poly.vertices[v];float offset=0;if(p_x>0) offset=32;
        if(fabs(p_z-offset)>0.01 && fabs(p_z-128-offset)>0.01) correct=FALSE;
    }
    fb_scale_expect(correct && poly.nv==8,"shear_opposite_side_fixed");fb_poly_free(&poly);brush_undo();
    fb_tool_activate(FB_TOOL_FACE);for(int h=0;h<fb_vertex_count;h++) if(fb_vertex_handles[h].point[2]==128) fb_vertex_handles[h].selected=TRUE;
    fb_vertex_selection_count();fb_tool_activate(FB_TOOL_SCALE);fb_scale_expect(fb_vertex_scope,"scale_selected_geometry_scope");
    fb_scale_numeric('0.5 0.5 1',FALSE);fb_poly_from_brush(1,selectedbrushes[0].id,&poly);correct=TRUE;
    for(int v=0;v<poly.nv;v++) {
        vector p=poly.vertices[v];float size=64;if(p_z>64) size=32;
        if(fabs(fabs(p_x)-size)>0.01 || fabs(fabs(p_y)-size)>0.01) correct=FALSE;
    }
    fb_scale_expect(correct && poly.nv==8,"scale_only_selected_face");fb_poly_free(&poly);brush_undo();
    fb_tool_deactivate();fb_tool_activate(FB_TOOL_SCALE);
    return TRUE;
}
