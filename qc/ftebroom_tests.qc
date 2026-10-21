// Regression commands exercise the same gesture functions used by the native frontend.
float ftebroom_testcommand()
{
    if (argv(0)!="ftebroom_test_drag") return FALSE;
    string mode=argv(1);
    int model,id;
    if (mode=="overlaystress") {
        if(!cvar("ftebroom_skip_setup"))return TRUE;
        float started=gettime(1);
        shaderforname("ftebroom/stresslines","{\n{\nmap $whiteimage\nrgbgen vertex\n}\n}");
        R_BeginPolygon("ftebroom/stresslines",3);
        for(int line=0;line<200000;line++) {
            R_PolygonVertex([0,0,(float)line*0.001],'0 0','1 1 1',1);
            R_PolygonVertex([1,0,(float)line*0.001],'0 0','1 1 1',1);R_EndPolygon();
        }
        print(sprintf("FTEBROOM_OVERLAY_STRESS 400000 vertices %g seconds\n",gettime(1)-started));
        return TRUE;
    } else if (mode=="occluded") {
        if(!cvar("ftebroom_skip_setup"))return TRUE;
        cvar_set("ca_brush_view","0");cvar_set("ftebroom_shift","0");cvar_set("ftebroom_ctrl","0");
        setproperty(VF_ORIGIN,'-512 0 96');setproperty(VF_ANGLES,'0 0 0');
        int front=fb_createbox('-128 0 96','32 128 128');
        int rear=fb_createbox('0 0 96','64 64 64');
        fb_document_tick();
        vector pixel=project('0 0 96');pixel_z=0;
        int hits=fb_pick(pixel);
        print((hits>=2 && fb_hits[0].id==front)?"FTEBROOM_OCCLUDED_PASS fixture\n":"FTEBROOM_OCCLUDED_FAIL fixture\n");
        fb_begin(pixel,1,0);fb_update(pixel+'0 -40 0',1,0);
        print((fb_moving && fb_brush==rear && fb_transform_preview)?"FTEBROOM_OCCLUDED_PASS selected_drag\n":"FTEBROOM_OCCLUDED_FAIL selected_drag\n");
        fb_cancel();
        static vector before[2],after[2],rearBefore[2],rearAfter[2];brush_getfacepoints(1,front,0,before,2);
        brush_getfacepoints(1,rear,0,rearBefore,2);
        fb_begin(pixel,1,0);fb_finish(pixel+'0 -40 0',1,0);
        brush_getfacepoints(1,front,0,after,2);
        print((before[0]==after[0] && before[1]==after[1])?"FTEBROOM_OCCLUDED_PASS obstacle_unchanged\n":"FTEBROOM_OCCLUDED_FAIL obstacle_unchanged\n");
        brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,rearAfter,2);
        print((rearAfter[0]-rearBefore[0]=='0 0 80' && rearAfter[1]-rearBefore[1]=='0 0 80')?"FTEBROOM_OCCLUDED_PASS vertical_delta\n":"FTEBROOM_OCCLUDED_FAIL vertical_delta\n");
        brush_undo();
        brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,rearAfter,2);
        print((rearAfter[0]==rearBefore[0] && rearAfter[1]==rearBefore[1])?"FTEBROOM_OCCLUDED_PASS undo\n":"FTEBROOM_OCCLUDED_FAIL undo\n");
        fb_begin(pixel,0,0);fb_finish(pixel,0,0);
        print(brush_isselected(1,front)?"FTEBROOM_OCCLUDED_PASS front_click\n":"FTEBROOM_OCCLUDED_FAIL front_click\n");
    } else if (mode=="face") {
        if(selectedbrushcount!=1) return TRUE;
        model=selectedbrushes[0].model;id=selectedbrushes[0].id;
        static vector facebounds[2];
        brush_getfacepoints(model,id,0,facebounds,2);
        vector facepixel=project((facebounds[0]+facebounds[1])*0.5);facepixel_z=0;
        cvar_set("ftebroom_shift","1");
        fb_begin(facepixel,0,cvar("ca_brush_view"));fb_finish(facepixel,0,cvar("ca_brush_view"));
        cvar_set("ftebroom_shift","0");
    } else if (mode=="whole") {
        if(selectedbrushcount!=1) return TRUE;
        model=selectedbrushes[0].model;id=selectedbrushes[0].id;
        brush_deselectall(); brush_select(model,id);
    } else if (mode=="clip" || mode=="tangent" || mode=="miss" || mode=="collinear") {
        cvar_set("ftebroom_tool","2");
        float x=mode=="tangent"?64:(mode=="miss"?128:0);
        fb_clip_points[0]=[x,-64,64];fb_clip_points[1]=[x,64,64];
        fb_clip_count=2;fb_clip_exact=FALSE;fb_clip_help[0]=fb_clip_help[1]='0 0 1';
        if(mode=="collinear") {fb_clip_points[2]=[x,128,64];fb_clip_count=3;}
    } else if (mode=="create") {
        brush_deselectall();
        cvar_set("ftebroom_tool","0");
        fb_begin(project('-160 -160 0'),0,cvar("ca_brush_view"));
        fb_finish(project('-96 -96 0'),0,cvar("ca_brush_view"));
    } else {
        if (selectedbrushcount!=1) { print("FTEBroom TEST FAIL: expected one selected brush.\n"); return TRUE; }
        static vector bounds[2];
        brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,bounds,2);
        vector p=project((bounds[0]+bounds[1])*0.5); p_z=0;
        if (mode=="click") { fb_begin(p,0,cvar("ca_brush_view")); fb_finish(p,0,cvar("ca_brush_view")); }
        else if (mode=="z") { fb_begin(p,1,cvar("ca_brush_view")); fb_finish(p+'0 -16 0',1,cvar("ca_brush_view")); }
        else if (mode=="cancel") { fb_begin(p,0,cvar("ca_brush_view")); fb_update(p+'40 20 0',0,cvar("ca_brush_view")); fb_cancel(); }
        // Freeze the synthetic preview so OS pointer events cannot move it before capture.
        else if (mode=="pending") { fb_begin(p,0,cvar("ca_brush_view")); fb_update(p+'100 0 0',0,cvar("ca_brush_view")); fb_owner=FB_OWNER_NONE; cvar_set("ftebroom_mouse_x",ftos(p_x+160));cvar_set("ftebroom_mouse_y",ftos(p_y)); print(sprintf("FTEBROOM_PREVIEW moving=%g replaced=%g\n",fb_moving,fb_preview_replaces(selectedbrushes[0].model,selectedbrushes[0].id))); }
        else if (mode=="xy") { fb_begin(p,0,cvar("ca_brush_view")); fb_finish(p+'40 20 0',0,cvar("ca_brush_view")); }
    }
    print(strcat("FTEBroom TEST gesture: ",mode,"\n"));
    return TRUE;
}
