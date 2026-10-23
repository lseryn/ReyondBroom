// SPDX-License-Identifier: GPL-2.0-or-later
void fb_moveface_cancel()
{
    if(!fb_moveface_active)return;fb_moveface_active=FALSE;fb_vertex_scope=FALSE;fb_vertex_clear();
}
int fb_moveface_prepare(fb_hit_t hit,vector pixel,int view)
{
    fb_vertex_scope=TRUE;fb_vertex_mode=FB_TOOL_FACE;fb_vertex_rebuild();
    int found=FALSE;
    for(int b=0;b<fb_vertex_brushcount;b++) {
        fb_vertex_brush_t *item=&fb_vertex_brushes[b];
        for(int f=0;f<item->source.nf;f++) {
            brushface_t face=item->source.faces[f].attr;
            if(fabs(fabs(face.planenormal*hit.normal)-1)>0.0001)continue;
            if(fabs(face.planenormal*hit.point-face.planedist)>FB_GEOM_PLANE)continue;
            fb_vertex_handles[item->handles[f]].selected=TRUE;found=TRUE;
        }
    }
    if(!found){fb_vertex_scope=FALSE;fb_vertex_clear();return FALSE;}
    fb_extrude_anchor=hit.point;fb_extrude_normal=hit.normal;
    if(!view && !fb_extrude_ray_distance(pixel,&fb_extrude_start_distance)){fb_vertex_scope=FALSE;fb_vertex_clear();return FALSE;}
    fb_moveface_active=TRUE;fb_vertex_drag=1;fb_vertex_pixel=pixel;fb_vertex_anchor=hit.point;fb_vertex_view=view;
    fb_owner=FB_OWNER_MODAL;fb_active=TRUE;return TRUE;
}
int fb_moveface_begin(vector pixel,int view)
{
    if(!fb_extrude_pick(pixel,view))return FALSE;
    fb_hit_t hit=fb_hits[0];int selected=brush_isselected(hit.model,hit.id);if(!selected)return FALSE;
    if(!selbrush_whole(&selectedbrushes[selected-1]))return FALSE;
    return fb_moveface_prepare(hit,pixel,view);
}
void fb_moveface_move(vector pixel,int view)
{
    if(!fb_moveface_active || view!=fb_vertex_view || vlen(pixel-fb_vertex_pixel)<3)return;
    vector delta;
    if(view){delta=fb_snap_delta(fb_view_plane_point(pixel,view,fb_vertex_anchor)-fb_view_plane_point(fb_vertex_pixel,view,fb_vertex_anchor));delta[fb_view_depth_axis(view)]=0;}
    else {float distance;if(!fb_extrude_ray_distance(pixel,&distance))return;delta=fb_extrude_normal*fb_snap_scalar(distance-fb_extrude_start_distance);}
    if(!fb_vertex_build(delta,FALSE,0))cvar_set("ftebroom_selection_status","Move Face rejected: invalid convex volume");
}
void fb_moveface_up(vector pixel,int view)
{
    fb_moveface_move(pixel,view);if(fb_vertex_preview_valid && vlen(fb_vertex_delta)>0.0001)fb_vertex_commit("Move Face");
    fb_moveface_cancel();fb_active=FALSE;
}
