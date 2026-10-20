// SPDX-License-Identifier: GPL-2.0-or-later
void fb_camera_expect(int ok,string name)
{
    print(strcat(ok?"FTEBROOM_CAMERA_PASS ":"FTEBROOM_CAMERA_FAIL ",name,"\n"));
}
float fb_camera_testcommand()
{
    if(argv(0)!="ftebroom_test_navigation_qc") return FALSE;
    if(!cvar("ftebroom_skip_setup")) return TRUE;
    if(argv(1)=="focus") {
        vector focusAngles=getproperty(VF_CL_VIEWANGLES),focusBefore=fb_camera_eye;
        int focusHistory=history;
        fb_camera_focus();fb_camera_expect(fb_focus_active,"focus_started");
        fb_camera_focus_step(fb_focus_time+0.075);
        fb_camera_expect(vlen(fb_camera_eye-(focusBefore+fb_focus_target)*0.5)<1,"focus_halfway");
        fb_camera_focus_step(fb_focus_time+0.151);
        fb_camera_expect(!fb_focus_active && vlen(fb_camera_eye-fb_focus_target)<0.01,"focus_finished");
        fb_camera_expect((vector)getproperty(VF_CL_VIEWANGLES)==focusAngles,"focus_keeps_angles");
        for(int v=1;v<=3;v++) fb_camera_expect(vlen(fb_view_centers[v]-fb_focus_center)<0.01,sprintf("focus_center_%i",v));
        if(cvar("ftebroom_view_count")>1) fb_view_rect(0);
        setproperty(VF_ORIGIN,fb_camera_eye);setproperty(VF_ANGLES,focusAngles);
        setproperty(VF_PERSPECTIVE,TRUE);setproperty(VF_AFOV,fb_camera_zoom);
        vector low=getproperty(VF_MIN),high=low+(vector)getproperty(VF_SIZE);
        for(int i=0;i<8;i++) {
            vector corner=fb_view_lastmin;
            for(int axis=0;axis<3;axis++) if(i&(1<<axis)) corner[axis]=fb_view_lastmax[axis];
            vector screen=project(corner);
            fb_camera_expect(screen_x>=low_x && screen_x<=high_x && screen_y>=low_y && screen_y<=high_y,sprintf("focus_corner_%i",i));
        }
        fb_camera_expect(history==focusHistory,"focus_no_history");return TRUE;
    }
    if(argv(1)=="moved") {
        fb_camera_expect(vlen(fb_camera_eye-'111 -222 333')<0.01,"move_position");
        fb_camera_expect(vlen(fb_view_centers[1]-fb_focus_center)<0.01,"move_keeps_2d");return TRUE;
    }
    if(argv(1)=="restored") {
        fb_camera_expect(vlen(fb_camera_eye-'111 -222 333')<0.01,"saved_position");
        vector loaded=getproperty(VF_CL_VIEWANGLES);
        fb_camera_expect(fabs(loaded_x-12)<0.01 && fabs(loaded_y-34)<0.01 && fabs(fb_camera_zoom-70)<0.01,"saved_angles_zoom");
        return TRUE;
    }
    vector original=fb_camera_eye,originalAngles=getproperty(VF_CL_VIEWANGLES);
    float originalZoom=fb_camera_zoom;
    cvar_set("ca_brush_view","0");cvar_set("ftebroom_fov","90");fb_camera_zoom=90;
    cvar_set("ftebroom_look_speed","0.25");cvar_set("ftebroom_fly_speed","500");
    cvar_set("ftebroom_pan_speed","0.5");cvar_set("ftebroom_move_speed","0.5");
    cvar_set("ftebroom_wheel_invert","0");cvar_set("ftebroom_invert_horizontal","0");cvar_set("ftebroom_invert_vertical","0");
    vector pixel=project('0 0 0');pixel_z=0;
    cvar_set("ftebroom_mouse_x",ftos(pixel_x));cvar_set("ftebroom_mouse_y",ftos(pixel_y));
    int hits=fb_pick(pixel);vector expectedPivot='0 0 0';
    if(hits) expectedPivot=fb_hits[0].point;
    fb_camera_input("begin",0,0,0,2);
    fb_camera_expect(hits>0 && vlen(fb_orbit_center-expectedPivot)<0.01,"orbit_picks_cursor_surface");
    fb_camera_input("end",0,0,0,0);fb_camera_position(original);setproperty(VF_CL_VIEWANGLES,originalAngles);
    cvar_set("ftebroom_mouse_x","640");cvar_set("ftebroom_mouse_y","-5000");
    hits=fb_pick('640 -5000 0');
    fb_camera_input("begin",0,0,0,2);
    fb_camera_expect(!hits && fabs(fb_orbit_radius-256)<0.01,"orbit_miss_fallback");
    fb_camera_input("end",0,0,0,0);
    setproperty(VF_CL_VIEWANGLES,'0 0 0');fb_camera_position('256 0 64');
    fb_orbit_center='0 0 64';fb_orbit_radius=256;fb_camera_gesture=2;
    setproperty(VF_CL_VIEWANGLES,'0 180 0');
    fb_camera_input("orbit",360,0,0,0);
    fb_camera_expect(fabs(vlen(fb_camera_eye-fb_orbit_center)-256)<0.01,"orbit_radius_90_degrees");
    fb_camera_expect(fabs(fb_camera_eye_x)<0.01 && fabs(fb_camera_eye_y+256)<0.01,"orbit_position_90_degrees");
    fb_camera_input("orbit",0,10000,0,0);
    vector a=getproperty(VF_CL_VIEWANGLES);
    fb_camera_expect(a_x<=89 && a_x>=-89 && a_z==0,"orbit_pole_clamp");
    fb_camera_input("wheel",0,0,100,0);
    fb_camera_expect(fabs(vlen(fb_camera_eye-fb_orbit_center)-32)<0.01,"orbit_minimum_radius");
    fb_camera_input("end",0,0,0,0);
    fb_camera_expect(fb_camera_gesture==0,"gesture_end");
    setproperty(VF_CL_VIEWANGLES,'-89 0 0');fb_camera_position('0 0 2000');
    cvar_set("ftebroom_mouse_x","640");cvar_set("ftebroom_mouse_y","400");
    fb_camera_input("look",0,10000,0,0);a=getproperty(VF_CL_VIEWANGLES);
    fb_camera_expect(a_x==89 && a_z==0,"look_pitch_roll");
    fb_camera_input("wheel",0,0,10,4);float zoom=fb_camera_zoom;
    fb_camera_expect(fabs(zoom-75)<0.01,"shift_wheel_zoom");
    fb_camera_input("resetzoom",0,0,0,0);
    fb_camera_expect(fb_camera_zoom==90,"reset_zoom");
    fb_camera_gesture=1;fb_camera_input("wheel",0,0,1,0);
    fb_camera_expect(fabs(cvar("ftebroom_fly_speed")-525)<0.01,"wheel_flight_speed");
    cvar_set("ftebroom_fly_speed","9999");fb_camera_input("wheel",0,0,1,0);
    fb_camera_expect(cvar("ftebroom_fly_speed")==10000,"speed_max");
    cvar_set("ftebroom_fly_speed","100");fb_camera_input("wheel",0,0,-1,0);
    fb_camera_expect(cvar("ftebroom_fly_speed")==100,"speed_min");
    fb_camera_gesture=0;cvar_set("ftebroom_fly_speed","500");
    cvar_set("ftebroom_forward","0");cvar_set("ftebroom_right","0");cvar_set("ftebroom_up","1");
    cvar_set("ftebroom_ctrl","0");cvar_set("ftebroom_shift","0");cvar_set("ftebroom_alt","0");
    setproperty(VF_CL_VIEWANGLES,'0 0 0');fb_camera_position('0 0 0');fb_camera_step(0.02);
    fb_camera_expect(vlen(fb_camera_eye-'0 0 10')<0.001,"world_up");
    cvar_set("ftebroom_up","-1");fb_camera_step(0.02);
    fb_camera_expect(vlen(fb_camera_eye)<0.001,"world_down");
    cvar_set("ftebroom_up","0");cvar_set("ftebroom_forward","1");
    setproperty(VF_CL_VIEWANGLES,'-30 0 0');fb_camera_step(0.02);
    fb_camera_expect(fb_camera_eye_z>4.9 && fabs(vlen(fb_camera_eye)-10)<0.001,"forward_includes_height");
    setproperty(VF_CL_VIEWANGLES,'0 0 0');fb_camera_position('0 0 0');
    cvar_set("ftebroom_shift","1");fb_camera_step(0.02);
    fb_camera_expect(fabs(fb_camera_eye_x-20)<0.001,"shift_double_speed");
    cvar_set("ftebroom_shift","0");cvar_set("ftebroom_alt","1");fb_camera_step(0.02);
    fb_camera_expect(fabs(fb_camera_eye_x-25)<0.001,"alt_half_speed");
    cvar_set("ftebroom_ctrl","1");fb_camera_step(0.02);
    fb_camera_expect(fabs(fb_camera_eye_x-25)<0.001,"ctrl_blocks_flight");
    cvar_set("ftebroom_ctrl","0");cvar_set("ftebroom_alt","0");fb_camera_zoom=45;fb_camera_step(0.02);
    fb_camera_expect(fabs(fb_camera_eye_x-30)<0.001,"zoom_scales_speed");
    cvar_set("ftebroom_forward","0");fb_camera_zoom=90;fb_camera_position('0 0 0');
    fb_camera_input("pan",20,10,0,0);
    fb_camera_expect(vlen(fb_camera_eye-'0 10 5')<0.001,"middle_pan");
    cvar_set("ftebroom_alt_move","1");fb_camera_position('0 0 0');fb_camera_input("pan",0,20,0,2);
    fb_camera_expect(vlen(fb_camera_eye-'10 0 0')<0.001,"alt_forward_pan");
    cvar_set("ftebroom_alt_move","0");fb_camera_position('0 0 0');fb_camera_input("wheel",0,0,1,0);
    fb_camera_expect(vlen(fb_camera_eye-'10 0 0')<0.001,"wheel_forward");
    cvar_set("ftebroom_wheel_invert","1");fb_camera_input("wheel",0,0,1,0);
    fb_camera_expect(vlen(fb_camera_eye)<0.001,"wheel_inversion");
    cvar_set("ftebroom_wheel_invert","0");
    cvar_set("ftebroom_move_to_cursor","1");cvar_set("ftebroom_mouse_x","800");
    vector ray=normalize(unproject('800 400 8192')-unproject('800 400 0'));
    fb_camera_input("wheel",0,0,1,0);
    fb_camera_expect(vlen(fb_camera_eye-ray*10)<0.001,"move_toward_cursor");
    cvar_set("ftebroom_move_to_cursor","0");
    cvar_set("ftebroom_invert_horizontal","1");fb_camera_input("look",40,0,0,0);
    a=getproperty(VF_CL_VIEWANGLES);fb_camera_expect(fabs(a_y-10)<0.001,"look_inversion");
    cvar_set("ftebroom_invert_horizontal","0");cvar_set("ca_brush_view","2");
    vector before=fb_camera_eye;fb_camera_input("wheel",0,0,1,0);fb_camera_step(0.02);
    fb_camera_expect(fb_camera_eye==before,"no_3d_motion_in_2d");
    cvar_set("ca_brush_view","0");fb_camera_position(original);setproperty(VF_CL_VIEWANGLES,originalAngles);fb_camera_zoom=originalZoom;
    print("FTEBROOM_CAMERA_COMPLETE\n");
    return TRUE;
}
