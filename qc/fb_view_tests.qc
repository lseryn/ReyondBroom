// SPDX-License-Identifier: GPL-2.0-or-later
void fb_view_expect(int ok,string name)
{
    print(strcat(ok?"FTEBROOM_VIEW_PASS ":"FTEBROOM_VIEW_FAIL ",name,"\n"));
}
float fb_view_testcommand()
{
    if(argv(0)!="ftebroom_test_view") return FALSE;
    if(!cvar("ftebroom_skip_setup")) return TRUE;
    if(argv(1)=="layout") {
        int saved=cvar("ca_brush_view");
        for(int pane=1;pane<4;pane++) {
            fb_view_rect(pane);int type=cvar(sprintf("ftebroom_view%i_type",pane));
            cvar_set("ca_brush_view",itos(type));fb_view_prepare();
            vector mn=getproperty(VF_MIN),size=getproperty(VF_SIZE),middle=mn+size*0.5;
            vector point=project(fb_view_centers[type]);point_z=middle_z=0;
            print(sprintf("LAYOUT_PROJECTION %i point=%v middle=%v min=%v size=%v\n",pane,point,middle,mn,size));
            fb_view_expect(vlen(point-middle)<1,sprintf("viewport_projection_%i",pane));
            cvar_set("ftebroom_mouse_x",ftos(middle_x));cvar_set("ftebroom_mouse_y",ftos(middle_y));
            fb_view_input("pan",21,-13,0);
            fb_view_expect(vlen(fb_view_centers[1]-fb_view_centers[2])<0.01 && vlen(fb_view_centers[2]-fb_view_centers[3])<0.01,sprintf("linked_pan_%i",pane));
        }
        fb_view_reset();fb_view_expect(cvar("ca_brush_viewsize")==1024,"reset_2d_zoom");
        cvar_set("ca_brush_view",itos(saved));return TRUE;
    }
    if(argv(1)=="entity") {
        cvar_set("ca_brush_view","2");fb_view_prepare();
        brush_deselectall();fb_restore_entity_selection(1);fb_view_remember_selection();
        static vector entityBounds[2];int foundEntity=fb_entity_bounds(1,entityBounds);
        fb_restore_entity_selection(-1);
        vector from=project('500 0 500'),to=project('564 0 596');from_z=to_z=0;
        fb_begin(from,0);fb_update(to,0);
        fb_view_expect(foundEntity && fabs(fb_boxsize_y-(entityBounds[1][1]-entityBounds[0][1]))<0.01,"entity_selection_depth");
        fb_cancel();return TRUE;
    }
    if(argv(1)=="clip") {
        cvar_set("ca_brush_view","0");cvar_set("ftebroom_tool","2");
        static brushface_t cube[6];fb_geom_testbox(cube,64);
        static vector normals[6]={'1 0 0','-1 0 0','0 1 0','0 -1 0','0 0 1','0 0 -1'};
        for(int face=0;face<6;face++) {
            vector tangent='1 0 0';if(face<2) tangent='0 1 0';
            fb_clip_surface_normal=normals[face];fb_clip_count=2;
            fb_clip_points[0]=normals[face]*64-tangent*24;
            fb_clip_points[1]=normals[face]*64+tangent*24;
            fb_poly_t front={0},back={0};
            int valid=fb_clip_plane() && fb_split(cube,6,fb_clip_normal,fb_clip_dist,&front,&back);
            fb_view_expect(valid,sprintf("face_split_%i",face));
            fb_poly_free(&front);fb_poly_free(&back);
        }
        fb_clip_count=0;
        fb_clip_pick(project('-32 -64 64'));
        fb_clip_pick(project('32 -64 64'));
        fb_view_expect(fb_clip_count==2 && fabs(fb_clip_surface_normal_y)>0.99,"side_face_picking");
        fb_view_expect(fb_clip_plane() && fabs(fb_clip_normal_z)>0.99,"side_face_cut_plane");
        int clipId=fb_hits[0].id;
        brush_select(selectedbrushmodel,clipId);
        fb_view_expect(fb_preview_replaces(selectedbrushmodel,clipId),"side_face_preview");
        cvar_set("ftebroom_clip_keep","0");fb_clip_apply();
        return TRUE;
    }
    fb_pick(project('0 0 64'));
    int id=fb_hits[0].id;
    brush_select(selectedbrushmodel,id);fb_view_remember_selection();brush_deselectall();
    for(int view=1;view<=3;view++) {
        cvar_set("ca_brush_view",itos(view));cvar_set("ca_brush_viewsize","512");
        fb_view_centers[view]='0 0 0';fb_view_prepare();
        vector origin=project('0 0 0'),r=project(fb_view_right*32),u=project(fb_view_up*32);
        fb_view_expect(r_x>origin_x && fabs(r_y-origin_y)<0.01 && u_y<origin_y && fabs(u_x-origin_x)<0.01,sprintf("axes_%i",view));
        vector pixel='713 347 0';cvar_set("ftebroom_mouse_x","713");cvar_set("ftebroom_mouse_y","347");
        vector world=unproject(pixel);
        fb_view_input("wheel",0,0,10);
        vector after=project(world);after_z=0;
        fb_view_expect(vlen(after-pixel)<0.5,sprintf("zoom_anchor_%i",view));
        fb_view_input("pan",35,-27,0);
        after=project(world);after_z=0;
        fb_view_expect(vlen(after-(pixel+'35 -27 0'))<0.5,sprintf("pan_%i",view));
        vector start=project(fb_view_right*300+fb_view_up*300),end=project(fb_view_right*364+fb_view_up*396);
        start_z=end_z=0;
        cvar_set("ftebroom_tool","0");cvar_set("ftebroom_shift","0");
        fb_begin(start,0);fb_update(end,0);
        int depth=fb_view_depth_axis(view);
        fb_view_expect(fabs(fb_boxsize[depth]-(fb_view_lastmax[depth]-fb_view_lastmin[depth]))<0.01,sprintf("selection_depth_%i",view));
        fb_view_expect(fabs(fb_boxsize*fb_view_right-64)<0.01 && fabs(fb_boxsize*fb_view_up-96)<0.01,sprintf("shape_plane_%i",view));
        fb_cancel();
    }
    cvar_set("ca_brush_view","2");fb_view_prepare();
    fb_view_has_selection=FALSE;
    vector a=project('300 0 300'),b=project('364 0 396');a_z=b_z=0;
    fb_begin(a,0);fb_update(b,0);
    fb_view_expect(fb_boxsize_y==fb_grid() && fb_boxcenter_y==fb_grid()*0.5,"default_depth");
    fb_cancel();
    fb_view_has_selection=TRUE;fb_view_lastmin_y=17.25;fb_view_lastmax_y=17.5;
    fb_begin(a,0);fb_update(b,0);
    fb_view_expect(fabs(fb_boxsize_y-0.25)<0.001 && fabs(fb_boxcenter_y-17.375)<0.001,"fractional_selection_depth");
    fb_cancel();
    return TRUE;
}
