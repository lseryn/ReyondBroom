// SPDX-License-Identifier: GPL-2.0-or-later
var float autocvar_ftebroom_create_with_selection=0;
var float autocvar_ftebroom_default_distance=256;
var float autocvar_ftebroom_project_creation_plane=1;
// Bounds expand outwards so the preview always contains both dragged points.
int fb_shape_bounds(vector start,vector delta,int view,int shift,int alt,vector camera,vector *bounds)
{
    vector end=start+delta;
    int depth=2;if(view) depth=fb_view_depth_axis(view);
    if(shift) {
        float extent=0;
        for(int a=0;a<3;a++) if(a!=depth || (alt && !view)) extent=max(extent,fabs(delta[a]));
        for(int a=0;a<3;a++) if(a!=depth || (alt && !view)) {
            float sign=1;if(delta[a]<0) sign=-1;
            if(a==depth && delta[a]==0 && camera[a]<start[a]) sign=-1;
            end[a]=start[a]+sign*extent;
        }
    }
    for(int a=0;a<3;a++) {
        bounds[0][a]=fb_snap_down(min(start[a],end[a]));
        bounds[1][a]=fb_snap_up(max(start[a],end[a]));
        if(bounds[1][a]-bounds[0][a]<0.001) {
            if(camera[a]>=start[a]) bounds[1][a]=bounds[0][a]+fb_grid();
            else bounds[0][a]=bounds[1][a]-fb_grid();
        }
    }
    if(view && fb_view_has_selection) {
        bounds[0][depth]=fb_view_lastmin[depth];
        bounds[1][depth]=fb_view_lastmax[depth];
        if(bounds[1][depth]-bounds[0][depth]<0.125) bounds[1][depth]=bounds[0][depth]+fb_grid();
    }
    for(int a=0;a<3;a++) {
        bounds[0][a]=max(-autocvar_ftebroom_world_bound,bounds[0][a]);
        bounds[1][a]=min(autocvar_ftebroom_world_bound,bounds[1][a]);
        if(bounds[1][a]-bounds[0][a]<0.125) return FALSE;
    }
    return TRUE;
}
