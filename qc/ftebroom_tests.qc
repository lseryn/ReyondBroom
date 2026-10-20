// Regression commands exercise the same gesture functions used by the native frontend.
float ftebroom_testcommand()
{
    if (argv(0)!="ftebroom_test_drag") return FALSE;
    string mode=argv(1);
    int model,id;
    if (mode=="face") {
        if(selectedbrushcount!=1) return TRUE;
        model=selectedbrushes[0].model;id=selectedbrushes[0].id;
        static vector facebounds[2];
        brush_getfacepoints(model,id,0,facebounds,2);
        vector facepixel=project((facebounds[0]+facebounds[1])*0.5);facepixel_z=0;
        cvar_set("ftebroom_shift","1");
        fb_begin(facepixel,0);fb_finish(facepixel,0);
        cvar_set("ftebroom_shift","0");
    } else if (mode=="whole") {
        if(selectedbrushcount!=1) return TRUE;
        model=selectedbrushes[0].model;id=selectedbrushes[0].id;
        brush_deselectall(); brush_select(model,id);
    } else if (mode=="clip" || mode=="tangent" || mode=="miss" || mode=="collinear") {
        cvar_set("ftebroom_tool","2");
        float x=mode=="tangent"?64:(mode=="miss"?128:0);
        fb_clip_points[0]=[x,-64,64];fb_clip_points[1]=[x,64,64];
        fb_clip_count=2;
        if(mode=="collinear") {fb_clip_points[2]=[x,128,64];fb_clip_count=3;}
    } else if (mode=="create") {
        brush_deselectall();
        cvar_set("ftebroom_tool","0");
        fb_begin(project('-160 -160 0'),0);
        fb_finish(project('-96 -96 0'),0);
    } else {
        if (selectedbrushcount!=1) { print("FTEBroom TEST FAIL: expected one selected brush.\n"); return TRUE; }
        static vector bounds[2];
        brush_getfacepoints(selectedbrushes[0].model,selectedbrushes[0].id,0,bounds,2);
        vector p=project((bounds[0]+bounds[1])*0.5); p_z=0;
        if (mode=="click") { fb_begin(p,0); fb_finish(p,0); }
        else if (mode=="z") { fb_begin(p,1); fb_finish(p+'0 -16 0',1); }
        else if (mode=="cancel") { fb_begin(p,0); fb_update(p+'40 20 0',0); fb_cancel(); }
        else if (mode=="xy") { fb_begin(p,0); fb_finish(p+'40 20 0',0); }
    }
    print(strcat("FTEBroom TEST gesture: ",mode,"\n"));
    return TRUE;
}
