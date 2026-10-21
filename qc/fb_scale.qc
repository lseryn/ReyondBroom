// SPDX-License-Identifier: GPL-2.0-or-later
// Scale and shear use the same validated affine transaction path as rotation.
vector fb_scale_low,fb_scale_high,fb_scale_sides,fb_scale_anchor,fb_scale_pixel,fb_scale_point;
vector fb_scale_handles[26],fb_scale_directions[26];
int fb_scale_count,fb_scale_drag,fb_scale_view,fb_scale_ready,fb_scale_valid;
fb_affine_t fb_scale_matrix;
int fb_scale_tool() {int tool=cvar("ftebroom_tool");return tool==FB_TOOL_SCALE || tool==FB_TOOL_SHEAR;}
void fb_scale_cancel() {fb_scale_drag=fb_scale_valid=FALSE;fb_affine_preview_active=FALSE;}
int fb_scale_capture()
{
    fb_scale_ready=FALSE;if(!fb_transform_capture()) return FALSE;
    fb_scale_low='1000000 1000000 1000000';fb_scale_high=-fb_scale_low;
    if(fb_vertex_scope) {
        vector bounds[2];if(!fb_vertex_bounds(bounds)) return FALSE;fb_scale_low=bounds[0];fb_scale_high=bounds[1];
    } else for(int b=0;b<fb_transform_count;b++) for(int a=0;a<3;a++) {
        fb_scale_low[a]=min(fb_scale_low[a],fb_transform_items[b].low[a]);fb_scale_high[a]=max(fb_scale_high[a],fb_transform_items[b].high[a]);
    }
    fb_scale_ready=TRUE;return TRUE;
}
void fb_scale_make_handles(int view)
{
    fb_scale_count=0;int shear=cvar("ftebroom_tool")==FB_TOOL_SHEAR;
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++) {
        vector direction=[x,y,z];int axes=fabs(x)+fabs(y)+fabs(z);if(!axes) continue;
        if(shear && axes!=1) continue;
        if(view && direction[fb_view_depth_axis(view)]!=0) continue;
        vector point=(fb_scale_low+fb_scale_high)*0.5;
        for(int a=0;a<3;a++) if(direction[a]) {if(direction[a]<0) point[a]=fb_scale_low[a];else point[a]=fb_scale_high[a];}
        fb_scale_handles[fb_scale_count]=point;fb_scale_directions[fb_scale_count++]=direction;
    }
}
int fb_scale_pick(vector pixel,int view)
{
    fb_scale_make_handles(view);int picked=-1,priority=0;float best=9;
    for(int h=0;h<fb_scale_count;h++) {
        vector screen=project(fb_scale_handles[h]);screen_z=0;float distance=vlen(screen-pixel);
        vector d=fb_scale_directions[h];int axes=fabs(d_x)+fabs(d_y)+fabs(d_z);
        if(distance<=9 && (axes>priority || (axes==priority && distance<best))) {picked=h;priority=axes;best=distance;}
    }
    // Edge segments and complete sides remain usable away from their centre handles.
    for(int h=0;h<fb_scale_count;h++) {
        vector d=fb_scale_directions[h];int axes=fabs(d_x)+fabs(d_y)+fabs(d_z);
        int edge=(!view && axes==2) || (view && axes==1);
        if(!edge || priority>axes)continue;
        vector a=fb_scale_handles[h],b=a;
        for(int axis=0;axis<3;axis++)if(!d[axis] && (!view || axis!=fb_view_depth_axis(view))) {a[axis]=fb_scale_low[axis];b[axis]=fb_scale_high[axis];}
        float distance=fb_pick_segment_distance(pixel,a,b);
        if(distance<8 && (axes>priority || distance<best)){picked=h;priority=axes;best=distance;}
    }
    if(picked<0 && !view) {
        vector start=unproject(pixel),ray=normalize(unproject(pixel+'0 0 8192')-start);float nearest=1000000;
        for(int h=0;h<fb_scale_count;h++) {
            vector d=fb_scale_directions[h];if(fabs(d_x)+fabs(d_y)+fabs(d_z)!=1)continue;
            int axis=0;for(int a=0;a<3;a++)if(d[a])axis=a;
            if(fabs(ray[axis])<0.00001)continue;float distance=(fb_scale_handles[h][axis]-start[axis])/ray[axis];
            if(distance<0 || distance>=nearest)continue;vector point=start+ray*distance;int inside=TRUE;
            for(int a=0;a<3;a++)if(a!=axis && (point[a]<fb_scale_low[a] || point[a]>fb_scale_high[a]))inside=FALSE;
            if(inside){picked=h;nearest=distance;}
        }
    }
    return picked;
}
int fb_scale_pointer(vector pixel,vector *point)
{
    if(fb_scale_view) {*point=fb_view_plane_point(pixel,fb_scale_view,fb_scale_point);return TRUE;}
    vector start=unproject(pixel),ray=normalize(unproject(pixel+'0 0 8192')-start);
    int count=0,axis=0;for(int a=0;a<3;a++) if(fb_scale_sides[a]) {axis=a;count++;}
    if(count==1 && cvar("ftebroom_tool")==FB_TOOL_SCALE) {
        vector direction='0 0 0';direction[axis]=1;
        float dot=ray*direction,denom=1-dot*dot;if(denom<0.00001) return FALSE;
        vector offset=start-fb_scale_point;
        *point=fb_scale_point+direction*((offset*direction-dot*(offset*ray))/denom);return TRUE;
    }
    vector normal='0 0 0';
    if(cvar("ftebroom_tool")==FB_TOOL_SHEAR) normal[axis]=1;
    else if(count==2) {for(int a=0;a<3;a++) if(!fb_scale_sides[a]) normal[a]=1;}
    else {makevectors(getproperty(VF_ANGLES));normal=v_forward;}
    float planeDenominator=ray*normal;if(fabs(planeDenominator)<0.00001) return FALSE;
    *point=start+ray*((fb_scale_point-start)*normal/planeDenominator);return TRUE;
}
int fb_scale_preview(fb_affine_t *m)
{
    int valid=FALSE;if(fb_vertex_scope) valid=fb_vertex_affine_preview(m);else valid=fb_affine_valid(m);
    if(!valid) return FALSE;
    fb_scale_matrix=*m;fb_affine_preview_matrix=*m;fb_scale_valid=TRUE;fb_affine_preview_active=TRUE;fb_transform_preview=TRUE;return TRUE;
}
void fb_scale_down(vector pixel,int alt,int view)
{
    if(!fb_scale_capture()) return;
    int handle=fb_scale_pick(pixel,view);if(handle<0) {fb_transform_clear();return;}
    fb_scale_sides=fb_scale_directions[handle];fb_scale_point=fb_scale_handles[handle];fb_scale_view=view;
    fb_scale_pixel=pixel;
    if(!fb_scale_pointer(pixel,&fb_scale_anchor)) {fb_transform_clear();return;}
    fb_scale_drag=TRUE;fb_scale_valid=FALSE;fb_active=TRUE;
}
void fb_scale_move(vector pixel,int alt,int view)
{
    if(!fb_scale_drag || view!=fb_scale_view) return;
    vector point='0 0 0';if(!fb_scale_pointer(pixel,&point)) return;
    vector delta=point-fb_scale_anchor,size=fb_scale_high-fb_scale_low,anchor=(fb_scale_high+fb_scale_low)*0.5;
    fb_affine_t m={0};m.x='1 0 0';m.y='0 1 0';m.z='0 0 1';
    if(cvar("ftebroom_tool")==FB_TOOL_SHEAR) {
        int axis=0;for(int a=0;a<3;a++) if(fb_scale_sides[a]) axis=a;
        delta[axis]=0;
        if(!view) {if(alt && axis!=2) {delta_x=delta_y=0;}else delta_z=0;}
        delta=fb_snap_delta(delta);if(size[axis]<0.0001) return;
        float sign=fb_scale_sides[axis];
        vector column=delta*(sign/size[axis]);
        if(axis==0) m.x+=column;if(axis==1) m.y+=column;if(axis==2) m.z+=column;
        if(sign>0) anchor[axis]=fb_scale_low[axis];else anchor[axis]=fb_scale_high[axis];
    } else {
        vector factors='1 1 1';int axes=0;float uniform=1,best=-1;
        float grid=1;if(cvar("ftebroom_grid_snap")) grid=fb_grid();
        for(int a=0;a<3;a++) if(fb_scale_sides[a]) {
            if(size[a]<0.0001) {cvar_set("ftebroom_selection_status","Cannot scale a zero-size selection axis");return;}
            axes++;float side=fb_scale_sides[a],moving=fb_scale_low[a];if(side>0)moving=fb_scale_high[a];
            moving+=delta[a];if(cvar("ftebroom_grid_snap"))moving=rint(moving/grid)*grid;
            float fixed=fb_scale_high[a];if(side>0)fixed=fb_scale_low[a];
            float length=(moving-fixed)*side;if(alt)length=(moving-anchor[a])*side*2;
            length=max(cvar("ftebroom_grid_snap")?grid:0.001,length);factors[a]=length/size[a];
            if(fabs(factors[a]-1)>best) {best=fabs(factors[a]-1);uniform=factors[a];}
            if(!alt) {if(fb_scale_sides[a]>0) anchor[a]=fb_scale_low[a];else anchor[a]=fb_scale_high[a];}
        }
        int proportional=cvar("ftebroom_shift") || (!view && axes>=2);
        if(proportional) for(int a=0;a<3;a++) {
            if(view && a==fb_view_depth_axis(view)) continue;
            if(!view && !cvar("ftebroom_shift") && !fb_scale_sides[a]) continue;
            factors[a]=uniform;
        }
        m.x[0]=factors_x;m.y[1]=factors_y;m.z[2]=factors_z;
    }
    m.translation=anchor-fb_affine_direction(&m,anchor);
    if(!fb_scale_preview(&m)) cvar_set("ftebroom_selection_status","Transform rejected: invalid geometry");
}
void fb_scale_up(vector pixel,int alt,int view)
{
    if(!fb_scale_drag) return;fb_scale_move(pixel,alt,view);
    if(fb_scale_valid && vlen(pixel-fb_scale_pixel)>2) fb_affine_apply(&fb_scale_matrix,cvar("ftebroom_tool")==FB_TOOL_SHEAR?"Shear":"Scale");
    fb_scale_cancel();fb_vertex_cancel();fb_transform_clear();fb_active=FALSE;fb_scale_ready=FALSE;
}
void fb_scale_draw()
{
    if(!fb_scale_tool()) return;
    if(!fb_scale_drag) {if(!fb_scale_capture()) return;}
    int view=cvar("ca_brush_view");fb_scale_make_handles(view);
    shaderforname("ftebroom/scalewire","{\n{\nmap $whiteimage\nrgbgen vertex\nalphagen vertex\nblendfunc blend\nnodepthtest\n}\n}");
    for(int corner=0;corner<8;corner++) {
        vector point='0 0 0';for(int a=0;a<3;a++) {point[a]=fb_scale_low[a];if(corner&(1i<<a)) point[a]=fb_scale_high[a];}
        for(int axis=0;axis<3;axis++) if(!(corner&(1i<<axis))) {
            vector other=point;other[axis]=fb_scale_high[axis];vector start=point;
            if(fb_scale_valid) {start=fb_affine_point(&fb_scale_matrix,start);other=fb_affine_point(&fb_scale_matrix,other);}
            R_BeginPolygon("ftebroom/scalewire");R_PolygonVertex(start,'0 0','1 1 0',1);R_PolygonVertex(other,'0 0','1 1 0',1);R_EndPolygon();
        }
    }
    for(int h=0;h<fb_scale_count;h++) {
        vector point=fb_scale_handles[h];if(fb_scale_valid) point=fb_affine_point(&fb_scale_matrix,point);
        vector p=project(point);cvar_set(sprintf("ftebroom_scale_handle_%i",h),sprintf("%g %g",p_x,p_y));
    }
    cvar_set("ftebroom_scale_handles",itos(fb_scale_count));
}
void fb_scale_numeric(vector values,int absolute)
{
    if(!fb_scale_capture()) return;
    vector size=fb_scale_high-fb_scale_low,center=(fb_scale_low+fb_scale_high)*0.5;
    for(int a=0;a<3;a++) {
        if(!fb_geom_finite(values[a]) || values[a]<=0) {fb_transform_clear();return;}
        if(absolute) {if(size[a]<0.0001) {fb_transform_clear();return;}values[a]/=size[a];}
    }
    fb_affine_t m={0};m.x=[values_x,0,0];m.y=[0,values_y,0];m.z=[0,0,values_z];
    m.translation=center-fb_affine_direction(&m,center);
    if(!fb_affine_apply(&m,"Scale")) cvar_set("ftebroom_selection_status","Scale rejected: invalid geometry");
    fb_transform_clear();fb_scale_ready=FALSE;
}
