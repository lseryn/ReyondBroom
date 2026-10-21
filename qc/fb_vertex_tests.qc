// SPDX-License-Identifier: GPL-2.0-or-later
void fb_vertex_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_VERTEX_PASS ":"FTEBROOM_VERTEX_FAIL ",label,"\n"));}
float fb_vertex_testcommand()
{
    if(argv(0)!="ftebroom_test_vertex" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();fb_createbox('0 0 64','128 128 128');
    fb_tool_activate(FB_TOOL_VERTEX);fb_vertex_expect(fb_vertex_count==8,"cube_eight_handles");
    int handle=-1;for(int h=0;h<fb_vertex_count;h++) if(fb_vertex_handles[h].point=='64 64 128') handle=h;
    fb_vertex_handles[handle].selected=TRUE;int marker=history;
    int valid=fb_vertex_build('0 0 -16',FALSE,0);
    fb_vertex_expect(valid && fb_vertex_brushes[0].preview.nf==7,"nonplanar_face_triangulated");
    fb_vertex_expect(history==marker,"preview_does_not_change_history");
    cvar_set("ftebroom_uv_lock","1");fb_vertex_build('0 0 -16',FALSE,0);
    brushface_t top={0};fb_poly_t *source=&fb_vertex_brushes[0].source;fb_poly_t *preview=&fb_vertex_brushes[0].preview;
    for(int f=0;f<source->nf;f++)if(source->faces[f].attr.planenormal=='0 0 1')top=source->faces[f].attr;
    int uvValid=TRUE,uvSamples=0;
    for(int f=0;f<preview->nf;f++) {
        fb_poly_face_t face=preview->faces[f];if(face.attr.planenormal[2]<0.5)continue;
        for(int p=0;p<face.count;p++) {
            vector point=preview->vertices[preview->indices[face.start+p]],original=point;
            if(vlen(point-'64 64 112')<0.01)original_z+=16;
            if(fabs(point*face.attr.sdir+face.attr.sbias-original*top.sdir-top.sbias)>0.01)uvValid=FALSE;
            if(fabs(point*face.attr.tdir+face.attr.tbias-original*top.tdir-top.tbias)>0.01)uvValid=FALSE;
            uvSamples++;
        }
    }
    fb_vertex_expect(uvValid && uvSamples==6,"uv_lock_preserves_triangle_corner_coordinates");cvar_set("ftebroom_uv_lock","0");

    fb_vertex_cancel();fb_vertex_expect(!fb_vertex_preview_valid && history==marker,"cancel_preview");
    valid=fb_vertex_build('-128 0 0',FALSE,0);
    fb_vertex_expect(valid && fb_vertex_brushes[0].preview.nv==7,"merge_vertices");fb_vertex_cancel();
    fb_vertex_drag=1;fb_vertex_build('-128 0 0',FALSE,0);
    valid=fb_vertex_build('-144 0 0',FALSE,0);
    fb_vertex_expect(valid && fb_vertex_brushes[0].preview.nv==7,"merged_vertex_continues_without_splitting");
    fb_vertex_cancel();fb_vertex_build('0 0 0',FALSE,0);
    fb_vertex_expect(fb_vertex_brushes[0].preview.nv==8,"cancel_restores_merged_pair");fb_vertex_cancel();
    valid=fb_vertex_build('-64 -64 -64',FALSE,0);
    fb_vertex_expect(valid && fb_vertex_brushes[0].preview.nv==7,"interior_vertex_disappears");fb_vertex_cancel();
    fb_vertex_drag=1;fb_vertex_build('-64 -64 -64',FALSE,0);fb_vertex_build('0 0 16',FALSE,0);
    fb_vertex_expect(fb_vertex_brushes[0].preview.nv==7,"collapsed_vertex_does_not_reappear_during_drag");
    fb_vertex_cancel();fb_vertex_build('0 0 16',FALSE,0);
    fb_vertex_expect(fb_vertex_brushes[0].preview.nv==8,"cancel_restores_collapsed_vertex");fb_vertex_cancel();
    valid=fb_vertex_build('0 0 -16',FALSE,0);fb_vertex_commit("Move Geometry");
    fb_vertex_expect(fb_vertex_brushes[0].source.nf==7,"commit_geometry");
    brush_undo();fb_vertex_rebuild();fb_vertex_expect(history==marker && fb_vertex_brushes[0].source.nf==6,"undo_geometry");
    fb_vertex_handles[0].selected=TRUE;fb_vertex_delete();fb_vertex_expect(fb_vertex_brushes[0].source.nv==7,"delete_one_vertex");
    brush_undo();fb_vertex_rebuild();
    for(int h=0;h<5;h++) fb_vertex_handles[h].selected=TRUE;
    marker=history;fb_vertex_delete();fb_vertex_expect(history==marker,"reject_flat_delete_atomically");
    fb_vertex_deselect();cvar_set("ca_brush_view","2");cvar_set("ca_brush_viewsize","512");fb_view_prepare();
    vector a=project('-80 -64 144'),b=project('80 -64 112');a_z=b_z=0;
    fb_vertex_down(a,0,2);fb_vertex_up(b,0,2);fb_vertex_expect(fb_vertex_selection_count()==4,"lasso_four_vertices");
    fb_vertex_down(a,0,2);fb_vertex_up(b,0,2);fb_vertex_expect(!fb_vertex_selection_count(),"lasso_toggles_selection");
    fb_tool_activate(FB_TOOL_EDGE);fb_vertex_expect(fb_vertex_count==12,"cube_twelve_edges");
    fb_tool_activate(FB_TOOL_FACE);fb_vertex_expect(fb_vertex_count==6,"cube_six_faces");
    for(int h=0;h<fb_vertex_count;h++) if(fb_vertex_handles[h].point[2]==128) fb_vertex_handles[h].selected=TRUE;
    valid=fb_vertex_build('16 0 0',FALSE,0);fb_vertex_expect(valid && fb_vertex_brushes[0].preview.nf==6,"move_face_shears_cube");
    fb_vertex_cancel();
    fb_tool_activate(FB_TOOL_VERTEX);
    fb_vertex_adding=TRUE;fb_vertex_add_point='0 0 128';
    valid=fb_vertex_build('0 0 32',FALSE,0);
    fb_vertex_expect(valid && fb_vertex_brushes[0].preview.nv==9,"add_roof_vertex");
    fb_vertex_commit("Add Vertex");fb_vertex_expect(fb_vertex_selection_count()==1,"new_vertex_stays_selected");
    brush_undo();fb_vertex_rebuild();
    fb_vertex_handles[0].selected=TRUE;fb_vertex_nudge('16 0 0');
    fb_vertex_expect(fb_vertex_selection_count()==1,"nudge_preserves_handle_selection");
    brush_undo();fb_vertex_rebuild();
    fb_vertex_handles[0].selected=TRUE;
    fb_tool_activate(FB_TOOL_SCALE);
    fb_vertex_expect(fb_vertex_scope && fb_vertex_selection_count()==1,"scale_retains_vertex_scope");
    fb_tool_activate(FB_TOOL_EDGE);
    fb_vertex_expect(!fb_vertex_scope && fb_vertex_count==12,"edge_exits_affine_scope");
    fb_tool_deactivate();fb_hit_t hit={0};hit.point='64 0 64';hit.normal='1 0 0';
    vector start=project(hit.point),end=project('64 0 80');start_z=end_z=0;
    marker=history;
    int prepared=fb_moveface_prepare(hit,start,2);fb_moveface_move(end,2);
    fb_vertex_expect(prepared && fb_vertex_preview_valid && history==marker,"move_face_preview");
    fb_tool_escape();fb_vertex_expect(!fb_moveface_active && !fb_vertex_scope && history==marker,"move_face_escape");
    fb_moveface_prepare(hit,start,2);fb_moveface_up(end,2);
    fb_poly_t moved={0};fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&moved);
    int sheared=moved.nv==8;
    for(int v=0;v<moved.nv;v++) if(moved.vertices[v][0]>0 && moved.vertices[v][2]!=16 && moved.vertices[v][2]!=144) sheared=FALSE;
    fb_poly_free(&moved);fb_vertex_expect(sheared,"move_face_2d_shear");
    brush_undo();fb_vertex_expect(history==marker,"move_face_single_undo");
    return TRUE;
}
