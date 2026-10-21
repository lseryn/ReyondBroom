// SPDX-License-Identifier: GPL-2.0-or-later
void fb_clip_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_CLIP_PASS ":"FTEBROOM_CLIP_FAIL ",label,"\n"));}
float fb_clip_interaction_testcommand()
{
    if(argv(0)!="ftebroom_test_clip_interaction" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();cvar_set("ca_grid","16");
    int id=fb_createbox('0 0 64','128 128 128');
    fb_tool_activate(FB_TOOL_CLIP);cvar_set("ca_brush_view","3");cvar_set("ca_brush_viewsize","512");fb_view_prepare();
    vector a=project('0 -48 64'),b=project('0 48 64');a_z=b_z=0;
    int marker=history;
    fb_tool_pointer_down(a,0,3);fb_tool_pointer_move(b,0,3);fb_tool_pointer_up(b,0,3);
    fb_clip_expect(fb_clip_count==2 && fb_clip_plane(),"drag_two_points");
    fb_clip_expect(history==marker,"points_do_not_edit_map");
    vector original=fb_clip_points[1],c=project('32 48 64');c_z=0;
    fb_clip_down(b,3);fb_clip_move(c,3);
    fb_clip_expect(fabs(fb_clip_points[1][0]-32)<0.01,"drag_existing_point");
    fb_tool_escape();fb_clip_expect(fb_clip_points[1]==original && fb_clip_count==2 && history==marker,"escape_restores_point_gesture");
    fb_clip_points[2]='32 32 64';fb_clip_count=3;fb_clip_pick(c,3);
    fb_clip_expect(fb_clip_count==3 && fb_clip_points[2]=='32 32 64',"fourth_point_ignored");
    fb_tool_key("back");fb_clip_expect(fb_clip_count==2,"delete_last_point");
    fb_clip_help[0]=fb_clip_help[1]='0 -1 0';fb_clip_points[0]='-32 -64 64';fb_clip_points[1]='32 -64 64';
    fb_clip_expect(fb_clip_plane() && fabs(fb_clip_normal_z)>0.99,"wall_help_vector");
    fb_clip_help[0]='0 0 1';fb_clip_help[1]='1 0 0';fb_clip_points[0]='0 -32 64';fb_clip_points[1]='0 32 64';
    fb_clip_expect(fb_clip_plane() && fabs(fb_clip_normal_x)>0.99,"help_tie_prefers_z");
    fb_clip_help[0]=fb_clip_help[1]='0 0 1';fb_clip_points[0]='0 0 0';fb_clip_points[1]='0 0 64';
    fb_clip_expect(!fb_clip_plane(),"collinear_help_rejected");
    fb_clip_points[0]='0 -32 64';fb_clip_points[1]='0 32 64';
    cvar_set("ftebroom_clip_keep","0");fb_tool_key("side");fb_tool_key("side");fb_tool_key("side");
    fb_clip_expect(cvar("ftebroom_clip_keep")==0,"side_cycle");
    static brushface_t faces[64],before[64];int n=brush_get(1,id,faces,64,__NULL__);
    for(int f=0;f<n;f++) {faces[f].surfacevalue=100+f;faces[f].sbias=3*f;faces[f].tbias=7*f;}
    fb_tx_begin("Clip fixture");brush_history_edit(1,id,faces,n,CONTENTBIT_SOLID);fb_tx_commit();
    id=selectedbrushes[0].id;brush_get(1,id,before,64,__NULL__);marker=history;
    cvar_set("ftebroom_clip_keep","1");fb_clip_apply();
    fb_clip_expect(selectedbrushcount==2 && cvar("ftebroom_tool")==FB_TOOL_CLIP && !fb_clip_count,"both_selected_and_tool_stays");
    float volume=0;int inherited=TRUE,caps=0;
    for(int brush=0;brush<selectedbrushcount;brush++) {
        fb_poly_t poly={0};fb_poly_from_brush(1,selectedbrushes[brush].id,&poly);volume+=poly.volume;
        for(int face=0;face<poly.nf;face++) if(fabs(poly.faces[face].attr.planedist)<0.001) {
            brushface_t *cap=&poly.faces[face].attr;int best=0;
            for(int candidate=1;candidate<n;candidate++) if(before[candidate].planenormal*cap->planenormal>before[best].planenormal*cap->planenormal) best=candidate;
            if(cap->surfacevalue!=before[best].surfacevalue || cap->sbias!=before[best].sbias || cap->tdir!=before[best].tdir) inherited=FALSE;
            if(fabs(cap->planenormal[0])>0.99) caps++;
        }
        fb_poly_free(&poly);
    }
    fb_clip_expect(fabs(volume-128*128*128)<2,"both_volume_conserved");
    fb_clip_expect(inherited && caps==2,"cut_attributes_from_nearest_normal");
    brush_undo();fb_clip_expect(history==marker && selectedbrushcount==1,"single_undo");
    brush_redo();fb_clip_expect(selectedbrushcount==2,"redo_two_halves");brush_undo();
    fb_clip_count=2;fb_tool_escape();fb_tool_escape();fb_tool_escape();
    fb_clip_expect(!fb_clip_count && !cvar("ftebroom_tool") && selectedbrushcount==1,"escape_tool_cascade");
    return TRUE;
}

