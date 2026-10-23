// SPDX-License-Identifier: GPL-3.0-or-later
int fb_generators_test_history;
int fb_generators_testcommand()
{
    if(argv(0)!="ftebroom_test_generators"||!cvar("ftebroom_skip_setup"))return FALSE;
    if(argv(1)=="holes43") {
        fb_cancel();fb_selection_clear();fb_createbox('0 0 128','512 512 128');fb_document_tick();int limitMarker=history;
        cvar_set("ftebroom_hole_count","64");cvar_set("ftebroom_hole_sides","32");cvar_set("ftebroom_hole_min","8");cvar_set("ftebroom_hole_max","12");
        fb_tx_begin("Over budget holes");int limitValid=fb_perforate_apply(FALSE);fb_tx_cancel();fb_transform_expect(!limitValid&&history==limitMarker&&selectedbrushcount==1,"holes43_over_budget_rejected");
        cvar_set("ftebroom_hole_count","8");cvar_set("ftebroom_hole_sides","16");cvar_set("ftebroom_hole_min","64");cvar_set("ftebroom_hole_max","72");fb_tx_begin("Boundary holes");limitValid=fb_perforate_apply(FALSE);print(strcat("Boundary holes: ",fb_geom_error,"\n"));fb_tx_cancel();fb_transform_expect((limitValid||fb_geom_error!="")&&history==limitMarker&&selectedbrushcount==1,"holes43_boundary_atomic");return TRUE;
    }
    if(argv(1)=="array43") {
        fb_cancel();fb_selection_clear();fb_createbox('256 0 128','32 32 32');fb_document_tick();int arrayMarker=history;
        cvar_set("ftebroom_array_count","3");cvar_set("ftebroom_array_mode","0");cvar_set("ftebroom_array_x","64");cvar_set("ftebroom_array_y","0");cvar_set("ftebroom_array_z","0");
        int arrayValid=fb_array_apply();fb_transform_expect(arrayValid&&selectedbrushcount==3,"array43_linear_count");
        vector bounds[2];brush_getfacepoints(selectedbrushes[2].model,selectedbrushes[2].id,0,bounds,2);fb_transform_expect(bounds[0][0]>=400,"array43_linear_bounds");
        brush_undo();fb_transform_expect(history==arrayMarker&&selectedbrushcount==1,"array43_single_undo");
        cvar_set("ftebroom_array_mode","1");cvar_set("ftebroom_array_angle","90");cvar_set("ftebroom_array_axis","2");cvar_set("ftebroom_array_rotate","1");arrayValid=fb_array_apply();fb_transform_expect(arrayValid&&selectedbrushcount==3,"array43_radial_count");brush_undo();
        cvar_set("ftebroom_array_mode","2");cvar_set("ftebroom_array_seed","1337");arrayValid=fb_array_apply();brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,bounds,2);vector first=bounds[0];brush_undo();arrayValid=fb_array_apply();brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,bounds,2);fb_transform_expect(arrayValid&&vlen(first-bounds[0])<.01,"array43_random_seed");brush_undo();return TRUE;
    }
    if(argv(1)=="perforate") {
        fb_cancel();fb_selection_clear();fb_createbox('0 0 128','128 128 128');fb_document_tick();int holeMarker=history;
        cvar_set("ftebroom_hole_count","2");cvar_set("ftebroom_hole_sides","5");cvar_set("ftebroom_hole_axis","2");cvar_set("ftebroom_hole_seed","1337");
        cvar_set("ftebroom_hole_min","16");cvar_set("ftebroom_hole_max","24");cvar_set("ftebroom_hole_spacing","4");cvar_set("ftebroom_hole_keep","1");
        fb_tx_begin("Perforate test");int holeOK=fb_perforate_apply(FALSE);print(strcat("Perforate test: ",fb_geom_error,"\n"));
        fb_transform_expect(holeOK&&selectedbrushcount==2,"perforate_selects_only_plugs");
        int holeShape=TRUE;for(int b=0;b<selectedbrushcount;b++){fb_poly_t poly={0};holeShape&=fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&poly)&&poly.nf==7;fb_poly_free(&poly);}
        fb_transform_expect(holeOK&&holeShape,"perforate_requested_sides");
        if(holeOK)fb_tx_commit();else fb_tx_cancel();brush_undo();
        fb_transform_expect(history==holeMarker&&selectedbrushcount==1,"perforate_single_undo");
        cvar_set("ftebroom_hole_min","1024");cvar_set("ftebroom_hole_max","1024");fb_tx_begin("Impossible holes");holeOK=fb_perforate_apply(FALSE);fb_tx_cancel();
        fb_transform_expect(!holeOK&&history==holeMarker&&selectedbrushcount==1,"perforate_rejects_unplaceable_holes");return TRUE;
    }
    if(argv(1)=="fracture") {
        fb_cancel();fb_selection_clear();fb_createbox('0 0 128','128 128 128');fb_document_tick();
        int fractureMarker=history;
        cvar_set("ftebroom_fracture_count","8");cvar_set("ftebroom_fracture_seed","1337");cvar_set("ftebroom_fracture_separation","0");cvar_set("ftebroom_fracture_entities","0");
        fb_tx_begin("Fracture test");int valid=fb_fracture_apply();
        print(strcat("Fracture test: ",fb_geom_error,"\n"));
        fb_transform_expect(valid&&selectedbrushcount==8,"fracture_exact_count");
        float volume=0;for(int b=0;b<selectedbrushcount;b++){fb_poly_t poly={0};if(fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&poly))volume+=poly.volume;fb_poly_free(&poly);}
        fb_transform_expect(valid&&fabs(volume-128*128*128)<128*128*128*.001,"fracture_volume_conserved");
        if(valid)fb_tx_commit();else fb_tx_cancel();
        brush_undo();fb_transform_expect(history==fractureMarker&&selectedbrushcount==1,"fracture_undo_original");
        brush_redo();fb_transform_expect(selectedbrushcount==8,"fracture_redo_fragments");brush_undo();
        cvar_set("ftebroom_fracture_entities","1");fb_tx_begin("Fracture entity test");valid=fb_fracture_apply();
        int independent=TRUE;for(int a=0;a<selectedbrushcount;a++)for(int b=a+1;b<selectedbrushcount;b++)if(selectedbrushes[a].model==selectedbrushes[b].model)independent=FALSE;
        fb_transform_expect(valid&&selectedbrushcount==8&&independent,"fracture_independent_brush_entities");
        fb_tx_cancel();cvar_set("ftebroom_fracture_entities","0");return TRUE;
    }
    if(argv(1)=="patch") {
        fb_selection_clear();static patchvert_t points[9];patchinfo_t info={0};info.cpwidth=info.cpheight=3;info.tesswidth=info.tessheight=-1;info.shadername="ftebroom/grid";info.contents=CONTENTBIT_SOLID;
        for(int y=0;y<3;y++)for(int x=0;x<3;x++){int at=y*3+x;points[at].xyz=[x*32,y*32,256];points[at].s=x;points[at].t=y;points[at].rgb='1 1 1';points[at].a=1;}
        fb_tx_begin("Patch fixture");patch_history_create(1,points,info,TRUE);fb_tx_commit();int marker=history;
        cvar_set("ftebroom_quake1","0");cvar_set("ftebroom_land_patch_u","5");cvar_set("ftebroom_land_patch_v","7");
        fb_tx_begin("Terrain patch");int patchOK=fb_land_apply();if(patchOK)fb_tx_commit();else fb_tx_cancel();
        patchinfo_t after;int count=patch_getcp(selectedbrushes[0].model,selectedbrushes[0].id,__NULL__,0,&after);
        fb_transform_expect(patchOK&&count==35&&after.cpwidth==5&&after.cpheight==7&&after.shadername=="ftebroom/grid","terrain_patch_resizes_and_preserves_material");
        brush_undo();count=patch_getcp(selectedbrushes[0].model,selectedbrushes[0].id,__NULL__,0,&after);
        fb_transform_expect(history==marker&&count==9,"terrain_patch_single_undo");return TRUE;
    }
    if(argv(1)=="preview") {
        fb_transform_expect(fb_generator_count==8&&selectedbrushcount==1&&history==fb_generators_test_history,"preview_owns_geometry_without_document_change");
        fb_transform_expect(fb_generator_replaces(selectedbrushes[0].model,selectedbrushes[0].id),"preview_hides_original");return TRUE;
    }
    if(argv(1)=="cancelled") {
        fb_transform_expect(fb_generator_count==0&&selectedbrushcount==1&&history==fb_generators_test_history,"preview_cancel_restores_original");return TRUE;
    }
    fb_cancel();fb_selection_clear();fb_createbox('0 0 128','128 128 128');fb_document_tick();
    cvar_set("ftebroom_bevel_segments","3");cvar_set("ftebroom_bevel_profile","0.5");cvar_set("ftebroom_bevel_mode","0");cvar_set("ftebroom_bevel_radius","8");cvar_set("ftebroom_bevel_clamp","1");
    fb_tx_begin("Test bevel");int ok=fb_bevel_apply();
    print(strcat("GENERATOR bevel result: ",fb_geom_error,"\n"));
    fb_transform_expect(ok,"bevel_cube_valid");
    if(ok){fb_poly_t p={0};fb_poly_from_brush(selectedbrushes[0].model,selectedbrushes[0].id,&p);fb_transform_expect(p.nf>6&&p.volume<128*128*128,"bevel_adds_convex_faces");fb_poly_free(&p);}
    fb_tx_cancel();
    cvar_set("ftebroom_bevel_radius","1024");fb_tx_begin("Test clamp");ok=fb_bevel_apply();print(strcat("GENERATOR clamp: ",fb_geom_error,"\n"));fb_transform_expect(ok,"bevel_clamp_large_radius");fb_tx_cancel();
    cvar_set("ftebroom_bevel_radius","8");
    for(int mode=1;mode<=2;mode++) {
        fb_tool_activate(mode==1?FB_TOOL_EDGE:FB_TOOL_VERTEX);fb_vertex_deselect();fb_vertex_handles[0].selected=TRUE;cvar_set("ftebroom_bevel_mode",itos(mode));
        fb_tx_begin("Partial bevel");ok=fb_bevel_apply();fb_transform_expect(ok,mode==1?"bevel_selected_edge":"bevel_selected_vertex");fb_tx_cancel();
    }
    fb_tool_activate(0);cvar_set("ftebroom_bevel_mode","0");
    cvar_set("ftebroom_land_u","2");cvar_set("ftebroom_land_v","2");cvar_set("ftebroom_land_frequency","4");cvar_set("ftebroom_land_height","32");cvar_set("ftebroom_land_intensity","1");cvar_set("ftebroom_land_roughness","1");cvar_set("ftebroom_land_triangles","1");
    fb_tx_begin("Test terrain");ok=fb_land_apply();fb_transform_expect(ok&&selectedbrushcount==8,"terrain_eight_triangular_prisms");fb_tx_cancel();
    fb_transform_expect(selectedbrushcount==1,"generator_cancel_restores_selection");
    fb_generators_test_history=history;
    return TRUE;
}
