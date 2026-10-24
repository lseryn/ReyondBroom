// SPDX-License-Identifier: GPL-3.0-or-later
int fb_generators_test_history;
int fb_generators_testcommand()
{
    if(argv(0)!="ftebroom_test_generators"||!cvar("ftebroom_skip_setup"))return FALSE;
    if(argv(1)=="settle44stale") {int staleHistory=history;int captured=fb_settle_export();fb_selection_clear();int accepted=fb_settle_preview();fb_settle_clear();fb_transform_expect(captured&&!accepted&&history==staleHistory&&!fb_generator_count,"settle44_stale_result_rejected");return TRUE;}
    if(argv(1)=="subdivision44texture") {
        fb_cancel();fb_selection_clear();fb_createbox('64 64 64','128 128 128');int textureModel=selectedbrushes[0].model,textureId=selectedbrushes[0].id,textureContents,textureFace=-1;
        static brushface_t textureFaces[64];int textureCount=brush_get(textureModel,textureId,textureFaces,64,&textureContents);
        for(int f=0;f<textureCount;f++)if(textureFaces[f].planenormal[2]>.99){textureFace=f;textureFaces[f].sdir='2 0 0';textureFaces[f].tdir='0 0.5 0';textureFaces[f].sbias=textureFaces[f].tbias=0;}
        fb_tx_begin("Texture basis fixture");brush_history_edit(textureModel,textureId,textureFaces,textureCount,textureContents);fb_tx_commit();fb_document_tick();
        selbrush_reset_mask(&selectedbrushes[0],FALSE);selbrush_set_face(&selectedbrushes[0],textureFace,TRUE);
        cvar_set("ftebroom_subdivide_texture","1");cvar_set("ftebroom_subdivide_grid","1");cvar_set("ftebroom_subdivide_cell","64");fb_tx_begin("Texture subdivision");int textureOK=fb_subdivision_apply();
        fb_transform_expect(textureOK&&selectedbrushcount==4,"subdivision44_texture_cell_scale");float textureVolume=0;for(int b=0;b<selectedbrushcount;b++){fb_poly_t texturePart={0};if(fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&texturePart))textureVolume+=texturePart.volume;fb_poly_free(&texturePart);}
        fb_transform_expect(textureOK&&fabs(textureVolume-128*128*128)<1,"subdivision44_texture_volume");fb_tx_cancel();cvar_set("ftebroom_subdivide_texture","0");return TRUE;
    }
    if(argv(1)=="inset44taper") {
        fb_cancel();fb_selection_clear();fb_createbox('0 0 0','128 128 128');int model=selectedbrushes[0].model,id=selectedbrushes[0].id,contents;
        static brushface_t taper[64];int nf=brush_get(model,id,taper,64,&contents);
        for(int f=0;f<nf;f++)if(fabs(taper[f].planenormal[2])<.01){taper[f].planenormal[2]=.5;float length=vlen(taper[f].planenormal);taper[f].planenormal/=length;taper[f].planedist=96/length;}
        fb_tx_begin("Tapered inset fixture");id=brush_history_edit(model,id,taper,nf,contents);fb_tx_commit();fb_document_tick();
        selbrush_reset_mask(&selectedbrushes[0],FALSE);for(int f=0;f<nf;f++)if(taper[f].planenormal[2]>.99)selbrush_set_face(&selectedbrushes[0],f,TRUE);
        fb_poly_t before={0};fb_poly_from_brush(model,id,&before);float expected=before.volume;fb_poly_free(&before);
        cvar_set("ftebroom_inset_amount","16");cvar_set("ftebroom_inset_snap","0");fb_tx_begin("Tapered inset");int taperValid=fb_inset_apply();float actual=0;
        for(int b=0;b<selectedbrushcount;b++){fb_poly_t part={0};if(fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&part))actual+=part.volume;fb_poly_free(&part);}
        fb_transform_expect(taperValid&&selectedbrushcount==5&&fabs(actual-expected)<expected*.001,"inset44_wider_back_preserved");fb_tx_cancel();return TRUE;
    }
    if(argv(1)=="settle44debug") {print(sprintf("Settle state history %i %i selection %i %i geometry %i %i\n",history,fb_settle_history,fb_selection_epoch,fb_settle_selection,fb_grid_geometry_epoch,fb_settle_geometry));print(sprintf("Settle count %i preview %i valid %g error %s\n",fb_settle_count,fb_generator_count,cvar("ftebroom_settle_valid"),cvar_string("ftebroom_settle_error")));return TRUE;}
    if(argv(1)=="settle44setup"||argv(1)=="settle44patch") {
        int usePatch=argv(1)=="settle44patch";fb_cancel();fb_selection_clear();float position=usePatch?4096:2048;
        if(usePatch){static patchvert_t ground[9];patchinfo_t groundInfo={0};groundInfo.cpwidth=groundInfo.cpheight=3;groundInfo.tesswidth=groundInfo.tessheight=-1;groundInfo.shadername="ftebroom/grid";groundInfo.contents=CONTENTBIT_SOLID;
            for(int y=0;y<3;y++)for(int x=0;x<3;x++){ground[y*3+x].xyz=[position+(x-1)*256,position+(y-1)*256,0];ground[y*3+x].rgb='1 1 1';}
            fb_tx_begin("Patch floor");patch_history_create(1,ground,groundInfo,FALSE);fb_tx_commit();
        }else fb_createbox([position,position,-16],'512 512 32');
        fb_selection_clear();fb_createbox([position,position,72],'16 16 16');fb_document_tick();fb_generators_test_history=history;return TRUE;
    }
    if(argv(1)=="settle44verify") {
        vector limits[2];brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,limits,2);fb_transform_expect(limits[0][2]>-.25&&limits[0][2]<.25,"settle44_applied_contact");
        brush_undo();brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,limits,2);fb_transform_expect(history==fb_generators_test_history&&fabs(limits[0][2]-64)<.01,"settle44_single_undo");
        brush_redo();brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,limits,2);fb_transform_expect(limits[0][2]>-.25&&limits[0][2]<.25,"settle44_redo");return TRUE;
    }
    if(argv(1)=="viewport44") {
        fb_camera_position('256 -384 320');setproperty(VF_CL_VIEWANGLES,'25 124 0');
        fb_cancel();fb_selection_clear();fb_createbox('0 0 128','128 128 128');fb_document_tick();
        static brushface_t viewFaces[64];int viewCount=brush_get(selectedbrushes[0].model,selectedbrushes[0].id,viewFaces,64,__NULL__);
        selbrush_reset_mask(&selectedbrushes[0],FALSE);for(int f=0;f<viewCount;f++)if(viewFaces[f].planenormal[2]>.99)selbrush_set_face(&selectedbrushes[0],f,TRUE);return TRUE;
    }
    if(argv(1)=="spin44") {
        fb_cancel();fb_selection_clear();fb_createbox('0 0 128','128 128 128');fb_document_tick();int spinMarker=history,spinOriginal=selectedbrushes[0].id;
        static brushface_t spinFaces[64];int spinCount=brush_get(selectedbrushes[0].model,spinOriginal,spinFaces,64,__NULL__);
        selbrush_reset_mask(&selectedbrushes[0],FALSE);for(int f=0;f<spinCount;f++)if(spinFaces[f].planenormal[2]>.99)selbrush_set_face(&selectedbrushes[0],f,TRUE);
        cvar_set("ftebroom_spin_segments","3");cvar_set("ftebroom_spin_auto","1");cvar_set("ftebroom_spin_scale","1");cvar_set("ftebroom_spin_flex","0");cvar_set("ca_grid","16");
        fb_tx_begin("Spin test");int spinOK=fb_spin_apply();print(strcat("Spin: ",fb_geom_error,"\n"));fb_transform_expect(spinOK&&selectedbrushcount==3,"spin44_segment_count");
        float spinVolume=0;for(int b=0;b<selectedbrushcount;b++){fb_poly_t measureSpin={0};if(fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&measureSpin))spinVolume+=measureSpin.volume;fb_poly_free(&measureSpin);}
        fb_transform_expect(spinOK&&fabs(spinVolume-128*128*48)<1,"spin44_straight_volume");fb_transform_expect(brush_get(1,spinOriginal,__NULL__,0,__NULL__)>0,"spin44_preserves_source");
        if(spinOK)fb_tx_commit();else fb_tx_cancel();brush_undo();fb_transform_expect(history==spinMarker&&selectedbrushcount==1,"spin44_undo");
        cvar_set("ftebroom_spin_auto","0");cvar_set("ftebroom_spin_x","64");cvar_set("ftebroom_spin_z","128");cvar_set("ftebroom_spin_flex",".5");cvar_set("ftebroom_spin_scale",".7");cvar_set("ftebroom_spin_rz","30");
        fb_tx_begin("Curved Spin");spinOK=fb_spin_apply();print(strcat("Curved Spin: ",fb_geom_error,"\n"));fb_transform_expect(spinOK&&selectedbrushcount==3,"spin44_curve_rotate_scale");fb_tx_cancel();return TRUE;
    }
    if(argv(1)=="partition44") {
        fb_cancel();fb_selection_clear();fb_createbox('0 0 128','128 128 128');fb_document_tick();int partitionMarker=history;
        static brushface_t partitionFaces[64];int partitionCount=brush_get(selectedbrushes[0].model,selectedbrushes[0].id,partitionFaces,64,__NULL__);
        selbrush_reset_mask(&selectedbrushes[0],FALSE);for(int f=0;f<partitionCount;f++)if(partitionFaces[f].planenormal[2]>.99)selbrush_set_face(&selectedbrushes[0],f,TRUE);
        cvar_set("ftebroom_inset_amount","16");cvar_set("ftebroom_inset_snap","0");fb_tx_begin("Inset test");int partitionOK=fb_inset_apply();
        print(strcat("Inset: ",fb_geom_error,"\n"));fb_transform_expect(partitionOK&&selectedbrushcount==5,"inset44_inner_and_four_borders");
        float partitionVolume=0;for(int b=0;b<selectedbrushcount;b++){fb_poly_t measure={0};if(fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&measure))partitionVolume+=measure.volume;fb_poly_free(&measure);}
        fb_transform_expect(partitionOK&&fabs(partitionVolume-128*128*128)<1,"inset44_volume_conserved");
        if(partitionOK)fb_tx_commit();else fb_tx_cancel();brush_undo();fb_transform_expect(history==partitionMarker&&selectedbrushcount==1,"inset44_undo");
        cvar_set("ftebroom_inset_amount","1024");fb_tx_begin("Invalid inset");partitionOK=fb_inset_apply();fb_tx_cancel();fb_transform_expect(!partitionOK&&history==partitionMarker,"inset44_invalid_atomic");
        selbrush_reset_mask(&selectedbrushes[0],TRUE);cvar_set("ftebroom_subdivide_u","3");cvar_set("ftebroom_subdivide_v","2");cvar_set("ftebroom_subdivide_grid","0");cvar_set("ftebroom_subdivide_texture","0");
        for(int plane=0;plane<3;plane++){cvar_set("ftebroom_subdivide_plane",itos(plane));fb_tx_begin("Subdivision test");partitionOK=fb_subdivision_apply();print(strcat("Subdivision: ",fb_geom_error,"\n"));fb_transform_expect(partitionOK&&selectedbrushcount==6,"subdivision44_six_pieces");
            partitionVolume=0;for(int b=0;b<selectedbrushcount;b++){fb_poly_t measure={0};if(fb_poly_from_brush(selectedbrushes[b].model,selectedbrushes[b].id,&measure))partitionVolume+=measure.volume;fb_poly_free(&measure);}fb_transform_expect(partitionOK&&fabs(partitionVolume-128*128*128)<1,"subdivision44_volume_conserved");fb_tx_cancel();fb_transform_expect(history==partitionMarker&&selectedbrushcount==1,"subdivision44_cancel_atomic");}
        cvar_set("ftebroom_subdivide_grid","1");cvar_set("ftebroom_subdivide_cell","32");fb_tx_begin("Grid subdivision");partitionOK=fb_subdivision_apply();fb_transform_expect(partitionOK&&selectedbrushcount==16,"subdivision44_world_cells");fb_tx_cancel();
        cvar_set("ftebroom_subdivide_cell",".125");fb_tx_begin("Excessive subdivision");partitionOK=fb_subdivision_apply();fb_tx_cancel();fb_transform_expect(!partitionOK&&history==partitionMarker,"subdivision44_budget");return TRUE;
    }
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
