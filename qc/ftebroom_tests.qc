// Regression commands exercise the same gesture functions used by the native frontend.
float ftebroom_testcommand()
{
    if (argv(0)!="ftebroom_test_drag") return FALSE;
    string mode=argv(1);
    if (mode=="create") {
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
