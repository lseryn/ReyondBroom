// SPDX-License-Identifier: GPL-2.0-or-later
// FTEBroom gestures use a fixed world XY plane; Alt locks displacement to world Z.
float fb_dragged, fb_moving, fb_alt;
int fb_model, fb_brush, fb_contents, fb_facecount, fb_face;
int fb_original_owned;
float fb_face_select;
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
        float extent = (i==0 || i==3) ? size_x : ((i==1 || i==4) ? size_y : size_z);
        fb_preview[i].planedist=center*normals[i]+extent*0.5;
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
void fb_cancel()
{
    for(int f=0;f<fb_original_owned;f++) strunzone(fb_original[f].shadername);
    fb_original_owned=0; fb_active=FALSE; fb_dragged=FALSE; fb_owner=FB_OWNER_NONE;
}
// Camera claims RMB in the native frontend before this chain is reached.
// Extrude and entity-drop slots decline until their geometry/document tasks land.
int fb_permanent_owner()
{
    if(fb_brush) if(!fb_face_select) {
        if(cvar("ftebroom_drag_mode")) return FB_OWNER_MOVE;
        if(brush_isselected(fb_model,fb_brush)) return FB_OWNER_MOVE;
    }
    if(!fb_face_select) return FB_OWNER_SHAPE;
    return FB_OWNER_SELECTION;
}
void fb_move_numeric(vector offset)
{
    for(int a=0;a<3;a++) if(!(fabs(offset[a])<=8192)) return;
    if(vlen(offset)==0) return;
    int count=selectedbrushcount;
    selbrush_t *selection=memalloc(sizeof(selbrush_t)*count);
    memcpy(selection,selectedbrushes,sizeof(selbrush_t)*count);
    static brushface_t faces[128];
    // Validate the entire selection before creating a transaction.
    for(int b=0;b<count;b++) {
        int n=brush_get(selection[b].model,selection[b].id,__NULL__,0,__NULL__);
        if(n<4 || n>128) {memfree(selection);return;}
        if(selection[b].facemask!=~0ul) {memfree(selection);return;}
    }
    fb_tool_refresh();history_transaction=gettime(0);
    for(int b=0;b<count;b++) {
        int contents,n=brush_get(selection[b].model,selection[b].id,faces,128,&contents);
        for(int f=0;f<n;f++) {
            faces[f].planedist+=faces[f].planenormal*offset;
            if(cvar("ftebroom_texture_lock")) {
                faces[f].sbias-=faces[f].sdir*offset;faces[f].tbias-=faces[f].tdir*offset;
            }
        }
        brush_history_edit(selection[b].model,selection[b].id,faces,n,contents);
    }
    history_transaction=0;memfree(selection);
}
void fb_begin(vector pixel, float alt)
{
    fb_cancel();
    vector a=unproject(pixel), b=unproject(pixel+'0 0 8192');
    *world_hitcontentsmaski=~0;
    traceline(a,b,TRUE,world);
    *world_hitcontentsmaski=0;
    fb_model=trace_ent.modelindex; fb_brush=trace_brush_id; fb_face=trace_brush_faceid;
    fb_face_select=cvar("ftebroom_shift");
    fb_owner=fb_permanent_owner();
    fb_moving=(fb_owner==FB_OWNER_MOVE);
    fb_anchor=fb_brush?fb_snap(trace_endpos):[0,0,cvar("ftebroom_plane")];
    if (!fb_brush) fb_anchor=fb_xy(pixel,fb_anchor_z);
    if (fb_moving) {
        fb_facecount=brush_get(fb_model,fb_brush,fb_original,128,&fb_contents);
        if (!fb_facecount || fb_facecount>128) return;
        for(int f=0;f<fb_facecount;f++) fb_original[f].shadername=strzone(fb_original[f].shadername);
        fb_original_owned=fb_facecount;
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
            if(cvar("ftebroom_texture_lock")) {
                fb_preview[i].sbias -= fb_preview[i].sdir*offset;
                fb_preview[i].tbias -= fb_preview[i].tdir*offset;
            }
        }
    } else {
        vector size=[max(fb_grid(),fabs(offset_x)),max(fb_grid(),fabs(offset_y)),max(fb_grid(),fb_grid()+offset_z)];
        vector center=fb_anchor+[(offset_x<0?-1:1)*size_x*0.5,(offset_y<0?-1:1)*size_y*0.5,size_z*0.5];
        fb_boxcenter=center; fb_boxsize=size; fb_boxfaces(center,size);
    }
}
void fb_finish(vector pixel, float alt)
{
    if (!fb_active) return;
    fb_update(pixel,alt);
    if (!fb_dragged || fb_face_select) {
        brush_deselectall();
        if (fb_brush) {
            if(fb_face_select && fb_face>0) brushface_select(fb_model,fb_brush,fb_face);
            else brush_select(fb_model,fb_brush);
        }
    } else if (fb_moving) {
        if (vlen(fb_snap(fb_offset))>0) brush_history_edit(fb_model,fb_brush,fb_preview,fb_facecount,fb_contents);
    } else {
        if (!fb_createbox(fb_boxcenter,fb_boxsize)) print("FTEBroom: gesture exceeds supported map bounds.\n");
    }
    fb_cancel();
}

// Editor camera bypasses gameplay input, which is suppressed while menus own focus.
vector fb_cameraoffset;
float fb_cameratime;
void ftebroom_camera()
{
    float now=gettime(0), dt=fb_cameratime?bound(0,now-fb_cameratime,0.05):0;
    fb_cameratime=now;
    makevectors((vector)getproperty(VF_ANGLES));
    vector motion=v_forward*cvar("ftebroom_forward")+v_right*cvar("ftebroom_right");
    if (vlen(motion)>1) motion=normalize(motion);
    fb_cameraoffset+=motion*320*dt;
    setproperty(VF_ORIGIN,(vector)getproperty(VF_ORIGIN)+fb_cameraoffset);
    cvar_set("ftebroom_camera_offset",vtos(fb_cameraoffset));
}
void fb_surfacegrid()
{
    static int ids[4096];
    static vector axes[6]={'1 0 0','-1 0 0','0 1 0','0 -1 0','0 0 1','0 0 -1'};
    static float distances[6];
    vector eye=getproperty(VF_ORIGIN);
    for(int a=0;a<6;a++) distances[a]=eye*axes[a]+4096;
    int count=brush_findinvolume(selectedbrushmodel,axes,distances,6,ids,__NULL__,ids.length);
    shaderforname("ftebroom/surfacegrid","{\npolygonoffset\ncull none\n{\nmap textures/ftebroom/overlay.tga\nblendfunc blend\nrgbgen vertex\nalphagen vertex\n}\n}");
    for(int b=0;b<min(count,ids.length);b++) {
        for(int f=1;f<=128;f++) {
            int n=brush_getfacepoints(selectedbrushmodel,ids[b],f,facepoints,MAX_FACEPOINTS);
            if(n<3) break;
            vector normal=normalize(crossproduct(facepoints[1]-facepoints[0],facepoints[2]-facepoints[0]));
            int u=0,v=1;
            if(fabs(normal_x)>fabs(normal_y) && fabs(normal_x)>fabs(normal_z)) {u=1;v=2;}
            else if(fabs(normal_y)>fabs(normal_z)) {u=0;v=2;}
            R_BeginPolygon("ftebroom/surfacegrid",3);
            for(int j=0;j<n;j++) R_PolygonVertex(facepoints[j],[facepoints[j][u]/fb_grid(),facepoints[j][v]/fb_grid(),0],'0.2 0.25 0.3',0.65);
            R_EndPolygon();
        }
    }
}

#include "ftebroom_edit.qc"

void ftebroom_frame()
{
    curmousepos=[cvar("ftebroom_mouse_x"),cvar("ftebroom_mouse_y"),0];
    fb_tool_pointer_move(curmousepos,cvar("ftebroom_alt"));
    if (fb_active && fb_dragged && !fb_face_select) {
        DrawQCBrushTextured(fb_preview,fb_moving?fb_facecount:6,'1 1 1',0.35);
        DrawQCBrushWireframe(fb_preview,fb_moving?fb_facecount:6,"chop",'1 0.5 0',1);
    }
    if (cvar("ftebroom_grid_visible")) {
        fb_surfacegrid();
        shaderforname("ftebroom/worldgrid","{\n{\nmap $whiteimage\nblendfunc blend\nrgbgen vertex\nalphagen vertex\n}\n}");
        // Keep the construction plane just behind a coincident brush surface.
        float g=max(fb_grid(),8), z=cvar("ftebroom_plane")-0.05;
        for (int i=-32;i<=32;i++) {
            R_BeginPolygon("ftebroom/worldgrid");
            R_PolygonVertex([i*g,-32*g,z],'0 0','0.16 0.18 0.2',0.5);
            R_PolygonVertex([i*g,32*g,z],'0 0','0.16 0.18 0.2',0.5); R_EndPolygon();
            R_BeginPolygon("ftebroom/worldgrid");
            R_PolygonVertex([-32*g,i*g,z],'0 0','0.16 0.18 0.2',0.5);
            R_PolygonVertex([32*g,i*g,z],'0 0','0.16 0.18 0.2',0.5); R_EndPolygon();
        }
    }
    fb_tool_draw();
    fb_tool_panel_state();
    fb_material_state();
    int selectionContext=0;
    if(selectedbrushcount) {
        selectionContext=1;
        for(int b=0;b<selectedbrushcount;b++)
            if(selectedbrushes[b].facemask!=~0ul) selectionContext=2;
    }
    cvar_set("ftebroom_ctx_selection",itos(selectionContext));
    int view=cvar("ca_brush_view");
    cvar_set("ftebroom_ctx_view",itos(view==3?1:(view==2?2:(view==1?3:0))));
    cvar_set("ftebroom_selection_count",itos(selectedbrushcount));
}
float() ftebroom_command =
{
    if(fb_tools_command()) return TRUE;
    if(argv(0)=="ftebroom_move") {fb_move_numeric([stof(argv(1)),stof(argv(2)),stof(argv(3))]);return TRUE;}
    if(argv(0)=="ftebroom_undo") {fb_tool_refresh();brush_undo();return TRUE;}
    if(argv(0)=="ftebroom_redo") {fb_tool_refresh();brush_redo();return TRUE;}
    if(argv(0)=="ftebroom_delete") {localcmd("brushedit_delete\n");return TRUE;}
    if (argv(0)=="ftebroom_pointer") {
        vector pixel=[stof(argv(2)),stof(argv(3)),0]; float alt=stof(argv(4));
        if(argv(1)=="down") {
            fb_tool_pointer_down(pixel,alt);
        }
        else if(argv(1)=="up") fb_tool_pointer_up(pixel,alt);
        else if(argv(1)=="cancel") {fb_cancel();fb_owner=FB_OWNER_NONE;}
        return TRUE;
    }
    if(argv(0)=="ftebroom_material") {fb_material_edit("material",0);return TRUE;}
    if(argv(0)=="ftebroom_uv") {fb_material_edit(argv(1),stof(argv(2)));return TRUE;}
    if(argv(0)=="ftebroom_clip") {if(argv(1)=="apply") fb_clip_apply(); else fb_clip_count=0; return TRUE;}
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
