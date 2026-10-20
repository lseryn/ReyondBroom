// SPDX-License-Identifier: GPL-2.0-or-later
// Camera operations are view-only; they never enter document history.
var float autocvar_ftebroom_fly_speed=500;
var float autocvar_ftebroom_look_speed=0.25;
var float autocvar_ftebroom_pan_speed=0.5;
var float autocvar_ftebroom_move_speed=0.5;
var float autocvar_ftebroom_fov=90;
var float autocvar_ftebroom_invert_horizontal=0;
var float autocvar_ftebroom_invert_vertical=0;
var float autocvar_ftebroom_alt_move=0;
var float autocvar_ftebroom_move_to_cursor=0;
vector fb_cameraoffset,fb_camera_base,fb_camera_eye,fb_orbit_center;
float fb_cameratime,fb_camera_zoom,fb_orbit_radius;
int fb_camera_gesture;
float fb_camera_scale()
{
    return min(1,fb_camera_zoom/bound(30,autocvar_ftebroom_fov,150));
}
vector fb_camera_angles(vector direction)
{
    return [-atan2(direction_z,sqrt(direction_x*direction_x+direction_y*direction_y))*180/M_PI,
        atan2(direction_y,direction_x)*180/M_PI,0];
}
void fb_camera_position(vector eye)
{
    fb_camera_eye=eye;fb_cameraoffset=eye-fb_camera_base;
}
void fb_camera_step(float dt)
{
    if(cvar("ca_brush_view")!=0 || fb_camera_gesture==2) return;
    makevectors((vector)getproperty(VF_CL_VIEWANGLES));
    vector motion=v_forward*cvar("ftebroom_forward")+v_right*cvar("ftebroom_right")+'0 0 1'*cvar("ftebroom_up");
    if(vlen(motion)>1) motion=normalize(motion);
    float speed=bound(100,autocvar_ftebroom_fly_speed,10000)*fb_camera_scale();
    if(cvar("ftebroom_ctrl")) return;
    if(cvar("ftebroom_shift")) speed*=2;
    if(cvar("ftebroom_alt")) speed*=0.5;
    fb_camera_position(fb_camera_eye+motion*speed*bound(0,dt,0.05));
}
void ftebroom_camera()
{
    float now=gettime(0),dt=fb_cameratime?bound(0,now-fb_cameratime,0.05):0;
    fb_cameratime=now;
    fb_camera_base=getproperty(VF_ORIGIN);fb_camera_eye=fb_camera_base+fb_cameraoffset;
    if(!fb_camera_zoom) fb_camera_zoom=bound(30,autocvar_ftebroom_fov,150);
    fb_camera_step(dt);
    setproperty(VF_ORIGIN,fb_camera_eye);
    if(!cvar("ca_brush_view")) setproperty(VF_AFOV,fb_camera_zoom);
    cvar_set("ftebroom_camera_offset",vtos(fb_cameraoffset));
    vector angles=getproperty(VF_CL_VIEWANGLES);
    cvar_set("ftebroom_camera_state",sprintf("%g %g %g %g %g %g %g",fb_camera_eye_x,fb_camera_eye_y,fb_camera_eye_z,angles_x,angles_y,0,fb_camera_zoom));
    cvar_set("ftebroom_camera_zoom",ftos(fb_camera_zoom));
}
void fb_camera_input(string kind,float dx,float dy,float scroll,int mods)
{
    if(kind=="end") {fb_camera_gesture=0;return;}
    if(kind=="resetzoom") {fb_camera_zoom=bound(30,autocvar_ftebroom_fov,150);return;}
    if(cvar("ca_brush_view")!=0) {fb_view_input(kind,dx,dy,scroll);return;}
    if(!fb_camera_zoom) fb_camera_zoom=bound(30,autocvar_ftebroom_fov,150);
    vector angles=getproperty(VF_CL_VIEWANGLES);
    vector pixel=[cvar("ftebroom_mouse_x"),cvar("ftebroom_mouse_y"),0];
    float scale=fb_camera_scale();
    if(kind=="begin") {
        fb_camera_gesture=1;
        if(mods&2) {
            fb_camera_gesture=2;
            makevectors(angles);
            fb_orbit_center=fb_camera_eye+v_forward*256;
            if(fb_pick(pixel)>0) fb_orbit_center=fb_hits[0].point;
            fb_orbit_radius=max(32,vlen(fb_orbit_center-fb_camera_eye));
            angles=fb_camera_angles(fb_orbit_center-fb_camera_eye);
            angles_x=bound(-89,angles_x,89);angles_z=0;
            setproperty(VF_CL_VIEWANGLES,angles);
            makevectors(angles);fb_camera_position(fb_orbit_center-v_forward*fb_orbit_radius);
        }
    } else if(kind=="look" || kind=="orbit") {
        if(autocvar_ftebroom_invert_horizontal) dx=-dx;
        if(autocvar_ftebroom_invert_vertical) dy=-dy;
        float sensitivity=bound(0.01,autocvar_ftebroom_look_speed,5)*scale;
        angles_x=bound(-89,angles_x+dy*sensitivity,89);angles_y-=dx*sensitivity;angles_z=0;
        setproperty(VF_CL_VIEWANGLES,angles);
        if(fb_camera_gesture==2 || kind=="orbit") {
            makevectors(angles);fb_camera_position(fb_orbit_center-v_forward*fb_orbit_radius);
        }
    } else if(kind=="pan") {
        makevectors(angles);
        vector vertical=v_up;if((mods&2) && autocvar_ftebroom_alt_move) vertical=v_forward;
        fb_camera_position(fb_camera_eye+(-dx*v_right+dy*vertical)*bound(0.01,autocvar_ftebroom_pan_speed,20)*scale);
    } else if(kind=="wheel") {
        if(cvar("ftebroom_wheel_invert")) scroll=-scroll;
        float amount=scroll*bound(0.01,autocvar_ftebroom_move_speed,20)*20*scale;
        if(fb_camera_gesture==2) {
            fb_orbit_radius=max(32,fb_orbit_radius-amount);
            makevectors(angles);fb_camera_position(fb_orbit_center-v_forward*fb_orbit_radius);
        } else if(fb_camera_gesture==1) {
            cvar_set("ftebroom_fly_speed",ftos(bound(100,autocvar_ftebroom_fly_speed*max(0.01,1+scroll*0.05),10000)));
        } else if(mods&4) fb_camera_zoom=bound(10,fb_camera_zoom/max(0.01,1+scroll/50),150);
        else {
            makevectors(angles);vector direction=v_forward;
            if(autocvar_ftebroom_move_to_cursor) direction=normalize(unproject(pixel+'0 0 8192')-unproject(pixel));
            fb_camera_position(fb_camera_eye+direction*amount);
        }
    }
}
float fb_camera_command()
{
    if(argv(0)=="ftebroom_camera_input") {
        fb_camera_input(argv(1),stof(argv(2)),stof(argv(3)),stof(argv(4)),stoi(argv(5)));return TRUE;
    }
    if(argv(0)=="ftebroom_camera_restore") {
        vector eye=[stof(argv(1)),stof(argv(2)),stof(argv(3))];
        vector angles=[stof(argv(4)),stof(argv(5)),0];float fov=stof(argv(7));
        if(!fb_geom_point(eye) || !fb_geom_finite(angles_x) || !fb_geom_finite(angles_y) || !fb_geom_finite(fov)) return TRUE;
        angles_x=bound(-89,angles_x,89);setproperty(VF_CL_VIEWANGLES,angles);
        fb_camera_position(eye);fb_camera_zoom=bound(10,fov,150);fb_camera_gesture=0;return TRUE;
    }
    return FALSE;
}
