// SPDX-License-Identifier: GPL-2.0-or-later
void fb_export_expect(int ok,string label){print(strcat(ok?"FTEBROOM_EXPORT_PASS ":"FTEBROOM_EXPORT_FAIL ",label,"\n"));}
int fb_export_testcommand()
{
    if(argv(0)!="ftebroom_test_export" || !cvar("ftebroom_skip_setup"))return FALSE;
    fb_tool_deactivate();int marker=history;
    fb_export_expect(fb_trace_count==5 && fb_trace_portal_count==1,"diagnostic_files_loaded");
    for(int p=0;p<5;p++)fb_trace_step(1);
    fb_export_expect(fb_trace_index==4 && fb_camera_eye=='64 32 80',"five_leak_points");
    fb_trace_step(-1);fb_export_expect(fb_camera_eye=='48 32 64',"previous_leak_point");
    fb_export_expect(history==marker,"diagnostics_do_not_change_document");
    fb_trace_unload(FALSE);fb_trace_unload(TRUE);
    fb_export_expect(fb_trace_count==0 && fb_trace_portal_count==0,"unload_diagnostics");
    int id=fb_createbox('0 0 128','64 64 32');brush_deselectall();brushface_select(1,id,6);fb_patch_convert();
    fb_createbox('128 0 128','64 64 32');
    fb_organize_action("layernew",0,"No export");int layer=fb_active_layer;
    fb_createbox('10000 0 0','64 64 32');fb_organize_action("layeromit",layer,"1");
    marker=history;fb_export_expect(fb_obj_export(),"obj_export");
    fb_export_expect(history==marker,"obj_export_preserves_history");
    return TRUE;
}
