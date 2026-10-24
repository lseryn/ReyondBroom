vector fb_view_plane_point(vector pixel,int view,vector depthAnchor);
// SPDX-License-Identifier: GPL-2.0-or-later
var float autocvar_ftebroom_rotate_step=15;
var float autocvar_ftebroom_grid_rotate_step=1;
vector fb_rotate_center,fb_rotate_start,fb_rotate_center_before,fb_rotate_segment,fb_rotate_pixel;
int fb_rotate_ready,fb_rotate_drag,fb_rotate_axis_index,fb_rotate_alt,fb_rotate_view;
float fb_rotate_angle;
vector fb_grid_rotate_pivot,fb_grid_before_origin,fb_grid_before_x,fb_grid_before_y,fb_grid_before_z;
float fb_grid_before_angle;
string fb_grid_vector_string(vector p){return sprintf("%.9g %.9g %.9g",p_x,p_y,p_z);}
int fb_rotating_grid(){return cvar("ftebroom_tool")==FB_TOOL_GRIDROTATE;}
void fb_grid_rotation_capture(){fb_grid_before_origin=autocvar_ftebroom_grid_origin;fb_grid_before_x=autocvar_ftebroom_grid_basis_x;fb_grid_before_y=autocvar_ftebroom_grid_basis_y;fb_grid_before_z=autocvar_ftebroom_grid_basis_z;fb_grid_before_angle=autocvar_ftebroom_grid_rotation;}
void fb_grid_rotation_restore(){cvar_set("ftebroom_grid_origin",fb_grid_vector_string(fb_grid_before_origin));cvar_set("ftebroom_grid_basis_x",fb_grid_vector_string(fb_grid_before_x));cvar_set("ftebroom_grid_basis_y",fb_grid_vector_string(fb_grid_before_y));cvar_set("ftebroom_grid_basis_z",fb_grid_vector_string(fb_grid_before_z));cvar_set("ftebroom_grid_rotation",ftos(fb_grid_before_angle));}
void fb_grid_rotation_apply(vector axis,float angle){
    float radians=angle*M_PI/180;
    cvar_set("ftebroom_grid_origin",fb_grid_vector_string(fb_rotate_center+fb_affine_rotate_axis(fb_grid_before_origin-fb_rotate_center,axis,radians)));
    cvar_set("ftebroom_grid_basis_x",fb_grid_vector_string(fb_affine_rotate_axis(fb_grid_rotate(fb_grid_before_x,fb_grid_before_angle),axis,radians)));
    cvar_set("ftebroom_grid_basis_y",fb_grid_vector_string(fb_affine_rotate_axis(fb_grid_rotate(fb_grid_before_y,fb_grid_before_angle),axis,radians)));
    cvar_set("ftebroom_grid_basis_z",fb_grid_vector_string(fb_affine_rotate_axis(fb_grid_rotate(fb_grid_before_z,fb_grid_before_angle),axis,radians)));
    cvar_set("ftebroom_grid_rotation","0");
}
void fb_rotate_publish()
{
    if(fb_rotating_grid())fb_grid_rotate_pivot=fb_rotate_center;
    cvar_set("ftebroom_rotate_center_x",ftos(fb_rotate_center_x));
    cvar_set("ftebroom_rotate_center_y",ftos(fb_rotate_center_y));
    cvar_set("ftebroom_rotate_center_z",ftos(fb_rotate_center_z));
    cvar_set("ftebroom_rotate_angle",ftos(fb_rotate_angle));
}
void fb_rotate_restore_center(vector center)
{
    fb_rotate_center=center;fb_rotate_ready=TRUE;fb_rotate_publish();
}
void fb_rotate_record_center(vector before,vector after)
{
    if(before==after||fb_rotating_grid())return;
    fb_tx_begin("Move rotation center");history_t *item=history_allocate();item->kind=HIST_PIVOT;
    item->beforefields=strzone(vtos(before));item->afterfields=strzone(vtos(after));fb_tx_commit();
}
void fb_rotate_reset()
{
    cvar_set("ftebroom_rotate_pick_center","0");
    if(fb_rotating_grid()){fb_rotate_center=fb_grid_rotate_pivot;fb_rotate_ready=TRUE;fb_rotate_publish();return;}
    if(!fb_transform_capture()) {fb_rotate_ready=FALSE;return;}
    fb_rotate_center=fb_affine_center();fb_transform_clear();fb_rotate_ready=TRUE;fb_rotate_publish();
}
void fb_rotate_cancel()
{
    if(fb_rotate_drag==2 && fb_rotating_grid())fb_grid_rotation_restore();
    cvar_set("ftebroom_rotate_pick_center","0");
    if(fb_rotate_drag==1) fb_rotate_center=fb_rotate_center_before;
    fb_rotate_drag=0;fb_affine_preview_active=FALSE;fb_rotate_angle=0;fb_rotate_publish();
}
vector fb_rotate_axis(int index)
{
    vector axis='0 0 0';axis[index]=1;return axis;
}
float fb_rotate_radius()
{
    vector size=getproperty(VF_SIZE);
    if(cvar("ca_brush_view")) return cvar("ca_brush_viewsize")*64/max(size_x,size_y);
    return max(4,vlen(fb_rotate_center-getproperty(VF_ORIGIN))*0.12);
}
vector fb_rotate_ring_point(int axis,float fraction,int full)
{
    int a=axis+1,b=axis+2;if(a>2) a-=3;if(b>2) b-=3;
    vector point='0 0 0',eye=getproperty(VF_ORIGIN)-fb_rotate_center;
    float angle=fraction*(full?2*M_PI:M_PI*0.5),sa=1,sb=1;
    if(!full) {if(eye[a]<0) sa=-1;if(eye[b]<0) sb=-1;}
    point[a]=cos(angle)*sa;point[b]=sin(angle)*sb;
    return fb_rotate_center+point*fb_rotate_radius();
}
float fb_rotate_screen_distance(vector pixel,vector a,vector b)
{
    a=project(a);b=project(b);a_z=b_z=0;
    vector edge=b-a;float length=edge*edge;
    float t=0;if(length>0.00001) t=bound(0,(pixel-a)*edge/length,1);
    return vlen(pixel-a-edge*t);
}
int fb_rotate_pick(vector pixel,int view)
{
    vector center=project(fb_rotate_center);center_z=0;
    if(vlen(pixel-center)<8) return 3;
    float best=6;int result=-1;
    for(int axis=0;axis<3;axis++) {
        if(view && axis!=fb_view_depth_axis(view)) continue;
        for(int i=0;i<48;i++) {
            float distance=fb_rotate_screen_distance(pixel,fb_rotate_ring_point(axis,(float)i/48,view!=0),fb_rotate_ring_point(axis,(float)(i+1)/48,view!=0));
            if(distance<best) {best=distance;result=axis;}
        }
    }
    return result;
}
int fb_rotate_plane(vector pixel,vector axis,vector *point)
{
    vector start=unproject(pixel),ray=unproject(pixel+'0 0 8192')-start;
    float denominator=ray*axis;if(fabs(denominator)<0.00001) return FALSE;
    *point=start+ray*((fb_rotate_center-start)*axis/denominator);return TRUE;
}
void fb_rotate_down(vector pixel,int alt,int view)
{
    if(cvar("ftebroom_rotate_pick_center")) {
        vector pickedPoint=fb_view_plane_point(pixel,view,fb_rotate_center);
        if(fb_pick_query(unproject(pixel),unproject(pixel+'0 0 8192'),pixel,0,FB_HIT_BRUSH|FB_HIT_PATCH,view!=0))pickedPoint=fb_hits[0].point;
        pickedPoint=fb_snap(pickedPoint);
        if(fb_geom_point(pickedPoint)){vector before=fb_rotate_center;fb_rotate_center=pickedPoint;fb_rotate_ready=TRUE;fb_rotate_record_center(before,pickedPoint);fb_rotate_publish();}
        cvar_set("ftebroom_rotate_pick_center","0");return;
    }
    if(!fb_rotate_ready) fb_rotate_reset();
    if(!fb_rotate_ready) return;
    int picked=fb_rotate_pick(pixel,view);if(picked<0) return;
    fb_rotate_center_before=fb_rotate_center;fb_rotate_view=view;fb_rotate_alt=alt;
    fb_rotate_pixel=pixel;fb_rotate_segment=fb_rotate_center;
    if(picked==3) fb_rotate_drag=1;
    else {
        vector point='0 0 0';
        if(!fb_rotate_plane(pixel,fb_rotate_axis(picked),&point) || vlen(point-fb_rotate_center)<0.001) return;
        if(fb_rotating_grid())fb_grid_rotation_capture();else if(!fb_transform_capture()) return;
        fb_rotate_start=normalize(point-fb_rotate_center);fb_rotate_axis_index=picked;fb_rotate_drag=2;
    }
    fb_active=TRUE;fb_owner=FB_OWNER_MODAL;
}
void fb_rotate_move(vector pixel,int alt,int view)
{
    if(!fb_rotate_drag || view!=fb_rotate_view) return;
    if(fb_rotate_drag==1) {
        if(alt!=fb_rotate_alt) {fb_rotate_segment=fb_rotate_center;fb_rotate_pixel=pixel;fb_rotate_alt=alt;}
        vector delta='0 0 0';
        if(!view && alt) delta_z=(fb_rotate_pixel_y-pixel_y)*fb_grid()/8;
        else delta=fb_view_plane_point(pixel,view,fb_rotate_segment)-fb_view_plane_point(fb_rotate_pixel,view,fb_rotate_segment);
        if(cvar("ftebroom_shift")) {
            int axis=0;for(int a=1;a<3;a++) if(fabs(delta[a])>fabs(delta[axis])) axis=a;
            for(int a=0;a<3;a++) if(a!=axis) delta[a]=0;
        }
        vector candidate=fb_snap(fb_rotate_segment+delta);
        if(fb_geom_point(candidate)) fb_rotate_center=candidate;
    } else {
        vector rotationAxis=fb_rotate_axis(fb_rotate_axis_index);vector point='0 0 0';
        if(!fb_rotate_plane(pixel,rotationAxis,&point) || vlen(point-fb_rotate_center)<0.001) return;
        vector direction=normalize(point-fb_rotate_center);
        float angle=atan2(rotationAxis*crossproduct(fb_rotate_start,direction),fb_rotate_start*direction)*180/M_PI;
        float step=bound(0.01,autocvar_ftebroom_rotate_step,360);
        if(fb_rotating_grid())step=bound(1,rint(autocvar_ftebroom_grid_rotate_step),180);
        angle=rint(angle/step)*step;
        if(fb_rotating_grid()){fb_grid_rotation_apply(rotationAxis,angle);fb_rotate_angle=angle;fb_rotate_publish();return;}
        fb_affine_t m={0};m.x=fb_affine_rotate_axis('1 0 0',rotationAxis,angle*M_PI/180);
        m.y=fb_affine_rotate_axis('0 1 0',rotationAxis,angle*M_PI/180);m.z=fb_affine_rotate_axis('0 0 1',rotationAxis,angle*M_PI/180);
        m.translation=fb_rotate_center-fb_affine_direction(&m,fb_rotate_center);
        int valid=FALSE;if(fb_vertex_scope) valid=fb_vertex_affine_preview(&m);else valid=fb_affine_valid(&m);
        if(valid) {
            fb_affine_preview_matrix=m;fb_affine_preview_active=TRUE;fb_transform_preview=TRUE;fb_rotate_angle=angle;
        }
    }
    fb_rotate_publish();
}
void fb_rotate_up(vector pixel,int alt,int view)
{
    if(!fb_rotate_drag) return;
    fb_rotate_move(pixel,alt,view);
    if(fb_rotate_drag==1)fb_rotate_record_center(fb_rotate_center_before,fb_rotate_center);
    if(fb_rotate_drag==2 && !fb_rotating_grid() && fabs(fb_rotate_angle)>0.0001) {
        fb_repeat_fixed_pivot=vlen(fb_rotate_center-fb_affine_center())>0.001;
        fb_affine_apply(&fb_affine_preview_matrix,"Rotate");fb_repeat_fixed_pivot=FALSE;
    }
    fb_rotate_drag=0;fb_active=FALSE;fb_affine_preview_active=FALSE;fb_transform_clear();fb_rotate_publish();
}
void fb_rotate_draw()
{
    if(cvar("ftebroom_tool")!=FB_TOOL_ROTATE&&!fb_rotating_grid()) return;
    if(!fb_rotate_ready) fb_rotate_reset();if(!fb_rotate_ready) return;
    int view=cvar("ca_brush_view");vector pixel=[cvar("ftebroom_mouse_x"),cvar("ftebroom_mouse_y"),0];
    int hover=fb_rotate_pick(pixel,view);
    shaderforname("ftebroom/rotate","{\n{\nmap $whiteimage\nrgbgen vertex\nalphagen vertex\nblendfunc blend\nnodepthtest\n}\n}");
    for(int axis=0;axis<3;axis++) {
        if(view && axis!=fb_view_depth_axis(view)) continue;
        vector color='0.15 0.15 0.15';color[axis]=1;if(hover==axis) color='1 1 0';
        for(int i=0;i<48;i++) {
            R_BeginPolygon("ftebroom/rotate");R_PolygonVertex(fb_rotate_ring_point(axis,(float)i/48,view!=0),'0 0 0',color,1);
            R_PolygonVertex(fb_rotate_ring_point(axis,(float)(i+1)/48,view!=0),'0 0 0',color,1);R_EndPolygon();
        }
    }
    float radius=fb_rotate_radius()*0.08;
    for(int axis=0;axis<3;axis++) {
        vector delta=fb_rotate_axis(axis)*radius;
        R_BeginPolygon("ftebroom/rotate");R_PolygonVertex(fb_rotate_center-delta,'0 0 0','1 1 0',1);
        R_PolygonVertex(fb_rotate_center+delta,'0 0 0','1 1 0',1);R_EndPolygon();
    }
}
float fb_rotate_tool_command()
{
    if(argv(0)=="ftebroom_grid_rotate") {
        if(argv(1)=="reset"){fb_rotate_cancel();fb_grid_default();fb_grid_rotate_pivot='0 0 0';fb_rotate_reset();}
        else {int axis=bound(0,stoi(argv(1)),2);float angle=rint(stof(argv(2)));if(angle>=-360&&angle<=360){fb_grid_rotation_capture();fb_grid_rotation_apply(fb_rotate_axis(axis),angle);}}
        return TRUE;
    }
    if(argv(0)!="ftebroom_rotate_center") return FALSE;
    vector before=fb_rotate_center;
    if(argv(1)=="pick"){cvar_set("ftebroom_rotate_pick_center","1");return TRUE;}
    if(argv(1)=="reset") fb_rotate_reset();
    else {
        vector center=[stof(argv(1)),stof(argv(2)),stof(argv(3))];
        if(fb_geom_point(center)) {fb_rotate_center=center;fb_rotate_ready=TRUE;fb_rotate_publish();}
    }
    fb_rotate_record_center(before,fb_rotate_center);
    return TRUE;
}
