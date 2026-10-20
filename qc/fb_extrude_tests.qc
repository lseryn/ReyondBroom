// SPDX-License-Identifier: GPL-2.0-or-later
float fb_extrude_testcommand()
{
    if(argv(0)=="ftebroom_test_extrude_preview" && cvar("ftebroom_skip_setup")) {
        fb_cancel();fb_selection_clear();int previewId=fb_createbox('0 0 128','96 96 96');
        static brushface_t previewFaces[6];brush_get(1,previewId,previewFaces,6,__NULL__);int previewFace=0;
        for(int f=0;f<6;f++) if(previewFaces[f].planenormal[2]>0.99) previewFace=f+1;
        fb_extrude_prepare(1,previewId,previewFace);fb_extrude_mode=1;fb_extrude_set_distance(48);
        fb_owner=FB_OWNER_EXTRUDE;fb_active=TRUE;fb_dragged=TRUE;return TRUE;
    }
    if(argv(0)!="ftebroom_test_extrude" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();cvar_set("ca_grid","16");cvar_set("ftebroom_grid_snap","1");
    int id=fb_createbox('0 0 128','64 64 64'),marker=history;
    static brushface_t original[6],after[6];brush_get(1,id,original,6,__NULL__);
    int top=0;for(int f=0;f<6;f++) if(original[f].planenormal[2]>0.99) top=f+1;
    fb_transform_expect(fb_extrude_prepare(1,id,top),"extrude_captures_selected_face");
    fb_extrude_set_distance(30);
    fb_transform_expect(fb_extrude_distance==32 && history==marker,"extrude_preview_snaps_without_history");
    fb_extrude_commit();fb_cancel();
    brush_get(1,selectedbrushes[0].id,after,6,__NULL__);
    fb_poly_t poly={0};fb_poly_from_faces(after,6,&poly);
    fb_transform_expect(fabs(poly.volume-64*64*96)<1,"extrude_outward_volume");fb_poly_free(&poly);
    int uvSame=TRUE;for(int f=0;f<6;f++) if(after[f].sdir!=original[f].sdir || after[f].tdir!=original[f].tdir || after[f].sbias!=original[f].sbias || after[f].tbias!=original[f].tbias) uvSame=FALSE;
    fb_transform_expect(uvSame,"extrude_preserves_world_projection");
    brush_undo();fb_transform_expect(history==marker,"extrude_single_undo");
    id=selectedbrushes[0].id;fb_extrude_prepare(1,id,top);fb_extrude_set_distance(-100);
    fb_transform_expect(fb_extrude_distance==-48 && fb_extrude_valid(fb_extrude_distance),"extrude_clamps_before_collapse");
    fb_cancel();fb_transform_expect(history==marker && !fb_transform_preview,"extrude_cancel_no_change");
    int first=selectedbrushes[0].id,second=fb_createbox('64 0 128','64 64 64');
    brush_select(1,first);int common=0;brush_get(1,first,original,6,__NULL__);
    for(int f=0;f<6;f++) if(original[f].planenormal[0]>0.99) common=f+1;
    fb_extrude_prepare(1,first,common);int matched=0;
    for(int i=0;i<fb_transform_count;i++) if(fb_extrude_faces[i]>=0) matched++;
    fb_transform_expect(matched==2,"extrude_matches_opposing_shared_faces");
    fb_extrude_set_distance(16);fb_extrude_commit();fb_cancel();
    float total=0;
    for(int b=0;b<selectedbrushcount;b++) {fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&poly);total+=poly.volume;fb_poly_free(&poly);}
    fb_transform_expect(fabs(total-2*64*64*64)<1,"extrude_shared_wall_preserves_total_volume");
    fb_selection_clear();fb_createbox('0 0 128','64 64 64');
    cvar_set("ca_brush_view","3");cvar_set("ca_brush_viewsize","512");fb_view_prepare();
    cvar_set("ftebroom_shift","1");cvar_set("ftebroom_ctrl","0");cvar_set("ftebroom_alt","0");
    vector start=project('32 0 128'),end=project('64 0 128');start_z=end_z=0;
    marker=history;fb_begin(start,0,3);fb_update(end,0,3);
    fb_transform_expect(fb_owner==FB_OWNER_EXTRUDE && fb_extrude_distance==32 && history==marker,"extrude_2d_edge_gesture_preview");
    fb_finish(end,0,3);
    fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&poly);
    fb_transform_expect(fabs(poly.volume-96*64*64)<1,"extrude_2d_gesture_commits");fb_poly_free(&poly);
    brush_undo();fb_transform_expect(history==marker,"extrude_2d_gesture_undo");
    cvar_set("ftebroom_shift","0");cvar_set("ca_brush_view","0");
    fb_selection_clear();id=fb_createbox('256 0 128','64 64 64');marker=history;
    fb_extrude_prepare(1,id,top);fb_extrude_mode=1;fb_extrude_set_distance(32);fb_extrude_commit();fb_cancel();
    fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&poly);
    fb_transform_expect(selectedbrushcount==1 && fabs(poly.volume-64*64*32)<1,"split_outward_selects_new_cap");fb_poly_free(&poly);
    fb_poly_from_brush(1,id,&poly);fb_transform_expect(fabs(poly.volume-64*64*64)<1,"split_outward_keeps_original");fb_poly_free(&poly);
    brush_undo();fb_transform_expect(history==marker,"split_single_undo");
    id=selectedbrushes[0].id;fb_extrude_prepare(1,id,top);fb_extrude_mode=1;fb_extrude_set_distance(-16);fb_extrude_commit();fb_cancel();
    fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&poly);
    fb_transform_expect(fabs(poly.volume-64*64*16)<1,"split_inward_selects_cut_volume");fb_poly_free(&poly);
    brush_undo();
    id=selectedbrushes[0].id;fb_extrude_prepare(1,id,top);fb_extrude_mode=2;fb_extrude_set_distance(32);fb_extrude_commit();fb_cancel();
    fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&poly);
    fb_transform_expect(fabs(poly.volume-64*64*32)<1,"stamp_prism_volume");fb_poly_free(&poly);
    brush_undo();fb_transform_expect(history==marker,"stamp_single_undo");
    fb_transform_capture();fb_affine_t shear={0};shear.x='1 0 0';shear.y='0 1 0';shear.z='0.5 0 1';
    fb_affine_apply(&shear,"Sloped fixture");fb_transform_clear();
    id=selectedbrushes[0].id;brush_get(1,id,original,6,__NULL__);int slope=0;
    for(int f=0;f<6;f++) if(original[f].planenormal[0]>0.5) slope=f+1;
    fb_extrude_prepare(1,id,slope);fb_extrude_mode=2;float area=0;
    for(int p=1;p<fb_extrude_vertex_count-1;p++) area+=vlen(crossproduct(fb_extrude_vertices[p]-fb_extrude_vertices[0],fb_extrude_vertices[p+1]-fb_extrude_vertices[0]))*0.5;
    cvar_set("ftebroom_grid_snap","0");fb_extrude_set_distance(32);fb_extrude_commit();fb_cancel();
    fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&poly);
    fb_transform_expect(fabs(poly.volume-area*32)<2,"stamp_sloped_face_area_times_distance");
    int perpendicular=TRUE;
    vector slopeNormal=original[slope-1].planenormal;
    for(int f=0;f<poly.nf;f++) {
        float alignment=fabs(poly.faces[f].attr.planenormal*slopeNormal);
        if(alignment>0.001 && alignment<0.999) perpendicular=FALSE;
    }
    fb_transform_expect(perpendicular,"stamp_sides_perpendicular_to_source_face");fb_poly_free(&poly);
    brush_undo();brush_undo();cvar_set("ftebroom_grid_snap","1");
    return TRUE;
}
