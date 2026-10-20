// SPDX-License-Identifier: GPL-2.0-or-later
float fb_grid()
{
    float exponent=bound(-3,rint(log(max(0.125,cvar("ca_grid")))/log(2)),8);
    float size=pow(2,exponent);
    if(cvar("ftebroom_grid_exp")!=exponent) cvar_set("ftebroom_grid_exp",ftos(exponent));
    if(cvar("ca_grid")!=size) cvar_set("ca_grid",ftos(size));
    return size;
}
float fb_snap_scalar(float value) {return cvar("ftebroom_grid_snap")?rint(value/fb_grid())*fb_grid():value;}
float fb_snap_up(float value) {return cvar("ftebroom_grid_snap")?ceil(value/fb_grid())*fb_grid():value;}
float fb_snap_down(float value) {return cvar("ftebroom_grid_snap")?floor(value/fb_grid())*fb_grid():value;}
vector fb_snap_vec(vector point) {return [fb_snap_scalar(point_x),fb_snap_scalar(point_y),fb_snap_scalar(point_z)];}
vector fb_snap_delta(vector delta) {return fb_snap_vec(delta);}
vector fb_snap(vector point) {return fb_snap_vec(point);}
float fb_snap_angle(float angle,float step)
{
    if(!cvar("ftebroom_grid_snap") || step<=0) return angle;
    return rint(angle/step)*step;
}
vector fb_snap_to_plane(vector point,vector normal,float distance)
{
    if(!cvar("ftebroom_grid_snap")) return point;
    int axis=0;
    if(fabs(normal_y)>fabs(normal[axis])) axis=1;
    if(fabs(normal_z)>fabs(normal[axis])) axis=2;
    if(fabs(normal[axis])<0.000001) return point;
    vector result=fb_snap_vec(point);
    result[axis]=0;
    result[axis]=(distance-result*normal)/normal[axis];
    return result;
}
float fb_snap_move_distance(float distance,vector *vertices,int count,vector normal)
{
    if(!cvar("ftebroom_grid_snap")) return distance;
    float best=fb_snap_scalar(distance),error=fabs(best-distance);
    for(int i=0;i<count;i++) for(int axis=0;axis<3;axis++) {
        if(fabs(normal[axis])<0.000001) continue;
        float coordinate=vertices[i][axis]+normal[axis]*distance;
        float candidate=(fb_snap_scalar(coordinate)-vertices[i][axis])/normal[axis];
        if(fabs(candidate-distance)<error) {best=candidate;error=fabs(candidate-distance);}
    }
    return best;
}
float fb_grid_display_step(vector point,vector normal)
{
    float spacing=fb_grid();
    int axis=0;
    if(fabs(normal_y)>fabs(normal[axis])) axis=1;
    if(fabs(normal_z)>fabs(normal[axis])) axis=2;
    vector a='0 0 0',b='0 0 0';
    a[(axis+1)%3]=1;b[(axis+2)%3]=1;
    // Tangent vectors retain the world-aligned texture projection on inclined faces.
    if(fabs(normal[axis])>0.000001) {
        a[axis]=-normal*a/normal[axis];b[axis]=-normal*b/normal[axis];
    }
    vector screen=project(point);
    vector sa=project(point+a*spacing)-screen,sb=project(point+b*spacing)-screen;
    sa_z=sb_z=0;
    // Estimate screen density once, then keep the displayed grid power-of-two aligned.
    float pixels=max(0.00001,min(vlen(sa),vlen(sb)));
    if(pixels<4) spacing*=pow(2,min(18,ceil(log(4/pixels)/log(2))));
    return spacing;
}
float fb_grid_command()
{
    if(argv(0)!="ftebroom_grid") return FALSE;
    string mode=argv(1);
    float grid=fb_grid(),step=stof(argv(2));
    if(mode=="snap") cvar_set("ftebroom_grid_snap",ftos(!cvar("ftebroom_grid_snap")));
    else if(mode=="visible") cvar_set("ftebroom_grid_visible",ftos(!cvar("ftebroom_grid_visible")));
    else if(mode=="set") cvar_set("ca_grid",ftos(bound(0.125,step,256)));
    else if(mode=="step") cvar_set("ca_grid",ftos(bound(0.125,grid*pow(2,step),256)));
    else if(mode=="wheel") {
        int modified=stoi(argv(3));
        if(!modified && !cvar("ftebroom_wheel_grid")) return TRUE;
        if(modified) step=-step;
        if(cvar("ftebroom_wheel_invert")) step=-step;
        cvar_set("ca_grid",ftos(bound(0.125,grid*pow(2,step),256)));
    }
    fb_grid();return TRUE;
}
