// SPDX-License-Identifier: GPL-2.0-or-later
// FTEBroom gestures use a fixed world XY plane; Alt locks displacement to world Z.
float fb_active, fb_dragged, fb_moving, fb_alt;
int fb_model, fb_brush, fb_contents, fb_facecount;
vector fb_downpixel, fb_anchor, fb_offset, fb_segment, fb_lastpixel, fb_boxcenter, fb_boxsize;
brushface_t fb_original[128], fb_preview[128];
float fb_grid() { return max(1, cvar("ca_grid")); }
vector fb_snap(vector p) { float g = fb_grid(); return [rint(p_x/g)*g,rint(p_y/g)*g,rint(p_z/g)*g]; }
vector fb_xy(vector pixel, float height)
{
    vector a = unproject(pixel), b = unproject(pixel + '0 0 8192');
    vector ray = b-a;
    if (fabs(ray_z) < 0.0001) {
        vector p=a;
        if (fabs(ray_x)>fabs(ray_y)) p_x=fb_anchor_x; else p_y=fb_anchor_y;
        p_z=height; return p;
    }
    return a + ray * ((height-a_z)/ray_z);
}
void fb_boxfaces(vector center, vector size)
{
    static const vector normals[6] = {'-1 0 0','0 -1 0','0 0 -1','1 0 0','0 1 0','0 0 1'};
    for (int i=0;i<6;i++) {
        fb_preview[i].planenormal=normals[i];
        fb_preview[i].planedist=center*normals[i]+size[i%3]*0.5;
        fb_preview[i].shadername=cvar_string("ca_newbrushtexture");
        reset_texturecoords(&fb_preview[i]);
    }
}
int fb_createbox(vector center, vector size)
{
    for (int i=0;i<3;i++) if (!(size[i]>=1 && size[i]<=8192 && fabs(center[i])<=16384)) return 0;
    fb_boxfaces(center,size);
    brush_deselectall();
    return brush_history_create(selectedbrushmodel,fb_preview,6,CONTENTBIT_SOLID,TRUE);
}
void fb_cancel() { fb_active=FALSE; fb_dragged=FALSE; }
void fb_begin(vector pixel, float alt)
{
    fb_cancel();
    vector a=unproject(pixel), b=unproject(pixel+'0 0 8192');
    *world_hitcontentsmaski=~0;
    traceline(a,b,TRUE,world);
    *world_hitcontentsmaski=0;
    fb_model=trace_ent.modelindex; fb_brush=trace_brush_id;
    float tool=cvar("ftebroom_tool");
    fb_moving = (tool==1 || (tool==0 && brush_isselected(fb_model,fb_brush))) && fb_brush;
    fb_anchor=fb_brush?fb_snap(trace_endpos):[0,0,cvar("ftebroom_plane")];
    if (!fb_brush) fb_anchor=fb_xy(pixel,fb_anchor_z);
    if (fb_moving) {
        fb_facecount=brush_get(fb_model,fb_brush,fb_original,128,&fb_contents);
        if (!fb_facecount || fb_facecount>128) return;
    }
    fb_anchor=fb_snap(fb_anchor);
    fb_downpixel=fb_lastpixel=pixel; fb_segment=fb_xy(pixel,fb_anchor_z);
    fb_offset='0 0 0'; fb_alt=alt; fb_active=TRUE;
}
void fb_update(vector pixel, float alt)
{
    if (!fb_active) return;
    if (vlen(pixel-fb_downpixel)>=4) fb_dragged=TRUE;
    if (alt != fb_alt) {
        fb_alt=alt; fb_segment=fb_xy(pixel,fb_anchor_z); fb_lastpixel=pixel;
        return;
    }
    if (fb_alt) {
        // Screen-space vertical motion gives a stable Z constraint even in top view.
        fb_offset_z += (fb_lastpixel_y-pixel_y)*2;
    } else {
        vector point=fb_xy(pixel,fb_anchor_z);
        fb_offset_x += point_x-fb_segment_x;
        fb_offset_y += point_y-fb_segment_y;
        fb_segment=point;
    }
    fb_lastpixel=pixel;
    for (int axis=0;axis<3;axis++) fb_offset[axis]=bound(-8192,fb_offset[axis],8192);
    vector offset=fb_snap(fb_offset);
    if (fb_moving) {
        memcpy(fb_preview,fb_original,sizeof(brushface_t)*fb_facecount);
        for (int i=0;i<fb_facecount;i++) {
            fb_preview[i].planedist += fb_preview[i].planenormal*offset;
            fb_preview[i].sbias -= fb_preview[i].sdir*offset;
            fb_preview[i].tbias -= fb_preview[i].tdir*offset;
        }
    } else {
        vector size=[max(fb_grid(),fabs(offset_x)),max(fb_grid(),fabs(offset_y)),max(fb_grid(),cvar("ftebroom_height")+offset_z)];
        vector center=fb_anchor+[(offset_x<0?-1:1)*size_x*0.5,(offset_y<0?-1:1)*size_y*0.5,size_z*0.5];
        fb_boxcenter=center; fb_boxsize=size; fb_boxfaces(center,size);
    }
}
void fb_finish(vector pixel, float alt)
{
    if (!fb_active) return;
    fb_update(pixel,alt);
    if (!fb_dragged) {
        brush_deselectall();
        if (fb_brush) brush_select(fb_model,fb_brush);
    } else if (fb_moving) {
        if (vlen(fb_snap(fb_offset))>0) brush_history_edit(fb_model,fb_brush,fb_preview,fb_facecount,fb_contents);
    } else {
        if (!fb_createbox(fb_boxcenter,fb_boxsize)) print("FTEBroom: gesture exceeds supported map bounds.\n");
    }
    fb_cancel();
}
void ftebroom_frame()
{
    curmousepos=[cvar("ftebroom_mouse_x"),cvar("ftebroom_mouse_y"),0];
    fb_update(curmousepos,cvar("ftebroom_alt"));
    if (fb_active && fb_dragged) {
        DrawQCBrushTextured(fb_preview,fb_moving?fb_facecount:6,'1 1 1',0.35);
        DrawQCBrushWireframe(fb_preview,fb_moving?fb_facecount:6,"chop",'1 0.5 0',1);
    }
    if (cvar("ftebroom_grid_visible")) {
        float g=max(fb_grid(),8), z=cvar("ftebroom_plane");
        for (int i=-32;i<=32;i++) {
            R_BeginPolygon("chop");
            R_PolygonVertex([i*g,-32*g,z],'0 0','0.16 0.18 0.2',0.5);
            R_PolygonVertex([i*g,32*g,z],'0 0','0.16 0.18 0.2',0.5); R_EndPolygon();
            R_BeginPolygon("chop");
            R_PolygonVertex([-32*g,i*g,z],'0 0','0.16 0.18 0.2',0.5);
            R_PolygonVertex([32*g,i*g,z],'0 0','0.16 0.18 0.2',0.5); R_EndPolygon();
        }
    }
    cvar_set("ftebroom_selection_count",itos(selectedbrushcount));
}
float() ftebroom_command =
{
    if (argv(0)=="ftebroom_pointer") {
        vector pixel=[stof(argv(2)),stof(argv(3)),0]; float alt=stof(argv(4));
        if(argv(1)=="down") fb_begin(pixel,alt);
        else if(argv(1)=="up") fb_finish(pixel,alt);
        else if(argv(1)=="cancel") fb_cancel();
        return TRUE;
    }
    if (argv(0)=="ftebroom_look") {
        vector angles=getproperty(VF_CL_VIEWANGLES);
        angles_x=bound(-89,angles_x+stof(argv(2))*0.25,89);
        angles_y-=stof(argv(1))*0.25;
        setproperty(VF_CL_VIEWANGLES,angles);
        return TRUE;
    }
    if (argv(0)!="ftebroom_box") return FALSE;
    if(argv(6)=="") { print("Usage: ftebroom_box x y z width depth height\n"); return TRUE; }
    vector center=[stof(argv(1)),stof(argv(2)),stof(argv(3))];
    vector size=[stof(argv(4)),stof(argv(5)),stof(argv(6))];
    int id=fb_createbox(center,size);
    if(id) print(sprintf("FTEBroom: created brush %i.\n",id));
    else print("FTEBroom: invalid box dimensions or position.\n");
    return TRUE;
};
