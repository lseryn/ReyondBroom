// SPDX-License-Identifier: GPL-2.0-or-later
// Gestures capture their originating view; perspective Alt locks world Z.
float fb_dragged, fb_moving, fb_alt;
int fb_model, fb_brush, fb_contents, fb_facecount, fb_face;
int fb_original_owned,fb_gesture_view,fb_constraint_axis;
float fb_hidden_source;
float fb_face_select;
int fb_point_entity,fb_pick_kind;
vector fb_applied_offset;
vector fb_downpixel, fb_anchor, fb_offset, fb_segment, fb_lastpixel, fb_boxcenter, fb_boxsize;
brushface_t fb_original[128], fb_preview[128];
vector fb_view_plane_point(vector pixel, int view, vector depthAnchor)
{
    if(view) {vector point=unproject(pixel);point[fb_view_depth_axis(view)]=depthAnchor[fb_view_depth_axis(view)];return point;}
    float height=depthAnchor_z;
    vector a = unproject(pixel), b = unproject(pixel + '0 0 8192');
    vector ray = b-a;
    if (fabs(ray_z) < 0.0001) {
        vector p=a;
        if (fabs(ray_x)>fabs(ray_y)) p_x=depthAnchor_x; else p_y=depthAnchor_y;
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
    for (int i=0;i<3;i++) if (!(size[i]>=0.125 && size[i]<=8192 && fabs(center[i])<=16384)) return 0;
    fb_tx_begin("Create brush");
    fb_boxfaces(center,size);
    brush_deselectall();
    fb_restore_entity_selection(-1);
    int id=brush_history_create(selectedbrushmodel,fb_preview,6,CONTENTBIT_SOLID,TRUE);
    fb_tx_commit();return id;
}
void fb_cancel()
{
    if(fb_select_paint) {fb_select_paint=FALSE;fb_tx_cancel();}
    if(fb_hidden_source) {
        if(!brush_isselected(fb_model,fb_brush)) brush_selected(fb_model,fb_brush,-1,FALSE);
        fb_hidden_source=FALSE;
    }
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
        if(!selbrush_whole(&selection[b])) {memfree(selection);return;}
    }
    fb_tool_refresh();fb_tx_begin("Move");
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
    fb_tx_commit();memfree(selection);
}
void fb_begin(vector pixel, float alt, int view)
{
    fb_cancel();
    fb_gesture_view=view;fb_constraint_axis=-1;
    if(view) alt=0;
    int hits=fb_pick(pixel);
    fb_model=selectedbrushmodel;fb_brush=0;fb_face=0;fb_point_entity=-1;fb_pick_kind=0;
    vector hitpoint='0 0 0';
    if(hits) {
        fb_hit_t hit=fb_hits[0];fb_pick_kind=hit.kind;hitpoint=hit.point;
        if(hit.kind==FB_HIT_BRUSH || hit.kind==FB_HIT_PATCH) {fb_model=hit.model;fb_brush=hit.id;fb_face=hit.face;}
        else if(hit.kind==FB_HIT_ENTITY) fb_point_entity=hit.id;
        else if(hit.kind==FB_HIT_HANDLE) return;
    }
    fb_face_select=cvar("ftebroom_shift");
    fb_select_ctrl=cvar("ftebroom_ctrl") && !fb_face_select;
    fb_select_node=hits?fb_selection_target(fb_hits[0].node):-1;
    // Keep the function call out of a mixed logical expression on the legacy QC target.
    fb_select_blocked=FALSE;
    if(fb_select_ctrl) if(fb_select_node>=0) fb_select_blocked=fb_selection_selected(fb_select_node);
    fb_owner=(fb_pick_kind==FB_HIT_PATCH || fb_point_entity>=0)?FB_OWNER_SELECTION:fb_permanent_owner();
    if(fb_select_ctrl) fb_owner=FB_OWNER_SELECTION;
    fb_moving=(fb_owner==FB_OWNER_MOVE);
    fb_anchor=fb_brush?fb_snap(hitpoint):[0,0,cvar("ftebroom_plane")];
    if (!fb_brush) fb_anchor=fb_view_plane_point(pixel,fb_gesture_view,fb_anchor);
    if(fb_gesture_view && !fb_moving) {
        int depth=fb_view_depth_axis(fb_gesture_view);
        float level=0;if(fb_view_has_selection) level=fb_view_lastmin[depth];
        vector depthAnchor=fb_anchor;depthAnchor[depth]=level;
        fb_anchor=fb_view_plane_point(pixel,view,depthAnchor);
    }
    if (fb_moving) {
        fb_facecount=brush_get(fb_model,fb_brush,fb_original,128,&fb_contents);
        if (!fb_facecount || fb_facecount>128) return;
        for(int f=0;f<fb_facecount;f++) fb_original[f].shadername=strzone(fb_original[f].shadername);
        fb_original_owned=fb_facecount;
    }
    fb_anchor=fb_snap(fb_anchor);
    if(fb_gesture_view && !fb_moving && fb_view_has_selection)
        fb_anchor[fb_view_depth_axis(fb_gesture_view)]=fb_view_lastmin[fb_view_depth_axis(fb_gesture_view)];
    fb_downpixel=fb_lastpixel=pixel; fb_segment=fb_view_plane_point(pixel,fb_gesture_view,fb_anchor);
    fb_applied_offset=fb_offset='0 0 0'; fb_alt=alt; fb_active=TRUE;
}
void fb_update(vector pixel, float alt, int view)
{
    if (!fb_active || view!=fb_gesture_view) return;
    if(view) alt=0;
    if (vlen(pixel-fb_downpixel)>=4) fb_dragged=TRUE;
    if(fb_owner==FB_OWNER_SELECTION) {
        if(fb_select_ctrl && fb_dragged && !fb_select_blocked) {
            vector delta=pixel-fb_lastpixel;
            int samples=min(256,max(1,ceil(vlen(delta)/4)));
            if(!fb_select_paint || vlen(delta)>0) for(int sample=1;sample<=samples;sample++)
                fb_selection_paint(fb_lastpixel+delta*((float)sample/(float)samples));
            fb_lastpixel=pixel;
        }
        return;
    }
    if (alt != fb_alt) {
        fb_alt=alt; fb_segment=fb_view_plane_point(pixel,fb_gesture_view,fb_anchor); fb_lastpixel=pixel;
        return;
    }
    if(fb_gesture_view) {
        vector point2d=fb_view_plane_point(pixel,fb_gesture_view,fb_anchor);
        fb_offset+=point2d-fb_segment;fb_segment=point2d;
    } else if (fb_alt) {
        // Screen-space vertical motion gives a stable Z constraint even in top view.
        fb_offset_z += (fb_lastpixel_y-pixel_y)*2;
    } else {
        vector point=fb_view_plane_point(pixel,fb_gesture_view,fb_anchor);
        fb_offset_x += point_x-fb_segment_x;
        fb_offset_y += point_y-fb_segment_y;
        fb_segment=point;
    }
    fb_lastpixel=pixel;
    for (int axis=0;axis<3;axis++) fb_offset[axis]=bound(-8192,fb_offset[axis],8192);
    vector offset=fb_snap_delta(fb_offset);
    if(view && cvar("ftebroom_shift") && fb_dragged) {
        int depthAxis=fb_view_depth_axis(view);
        if(fb_constraint_axis<0 && vlen(offset)>0) {
            int first=(depthAxis+1)%3,second=(depthAxis+2)%3;
            fb_constraint_axis=fabs(offset[first])>=fabs(offset[second])?first:second;
        }
        for(int locked=0;locked<3;locked++) if(fb_constraint_axis>=0 && locked!=fb_constraint_axis) offset[locked]=0;
    } else fb_constraint_axis=-1;
    fb_applied_offset=offset;
    if (fb_moving) {
        if(fb_dragged) if(!brush_isselected(fb_model,fb_brush)) {
            brush_selected(fb_model,fb_brush,-1,TRUE);fb_hidden_source=TRUE;
        }
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
        if(fb_gesture_view) {
            int depth=fb_view_depth_axis(fb_gesture_view);
            for(int a=0;a<3;a++) {
                size[a]=max(fb_grid(),fabs(offset[a]));
                float sign=1;if(offset[a]<0) sign=-1;
                center[a]=fb_anchor[a]+sign*size[a]*0.5;
            }
            size[depth]=fb_grid();
            if(fb_view_has_selection) size[depth]=max(0.125,fb_view_lastmax[depth]-fb_view_lastmin[depth]);
            center[depth]=fb_anchor[depth]+size[depth]*0.5;
        }
        fb_boxcenter=center; fb_boxsize=size; fb_boxfaces(center,size);
    }
}
void fb_finish(vector pixel, float alt, int view)
{
    if (!fb_active || view!=fb_gesture_view) return;
    if(view) alt=0;
    fb_update(pixel,alt,view);
    if(fb_select_paint) {fb_select_paint=FALSE;fb_tx_commit();}
    else if(fb_select_ctrl && fb_dragged) {
        if(fb_select_blocked) print("FTEBroom: duplicate and move is reserved for roadmap task 4.1.\n");
    } else if(!fb_dragged && !fb_face_select) fb_selection_click(fb_select_node,fb_select_ctrl);
    else if (fb_face_select || fb_pick_kind==FB_HIT_PATCH || fb_point_entity>=0) {
        fb_tx_begin("Select");
        brush_deselectall();
        fb_restore_entity_selection(fb_point_entity);
        if (fb_brush) {
            if(fb_face_select && fb_face>0) brushface_select(fb_model,fb_brush,fb_face);
            else brush_select(fb_model,fb_brush);
        }
        fb_tx_commit();
    } else if (fb_moving) {
        if (vlen(fb_applied_offset)>0) {
            fb_tx_begin("Move");
            brush_history_edit(fb_model,fb_brush,fb_preview,fb_facecount,fb_contents);
            fb_tx_commit();
        }
    } else {
        if (!fb_createbox(fb_boxcenter,fb_boxsize)) print("FTEBroom: gesture exceeds supported map bounds.\n");
    }
    fb_cancel();
}

// Geometry survives camera motion; projected spacing survives stationary frames.
typedef struct {
    int id,count,u,v;
    vector center,normal,points[MAX_FACEPOINTS];
    float spacing;
} fb_grid_face_t;
fb_grid_face_t *fb_grid_faces;
int fb_grid_face_count,fb_grid_face_capacity;
void fb_surfacegrid(optional int geometryOnly)
{
    static int ids[4096],epoch,model,valid;
    static vector axes[6]={'1 0 0','-1 0 0','0 1 0','0 -1 0','0 0 1','0 0 -1'};
    static float distances[6];
    static vector region,lastEye,lastAngles,lastSize,lastMin,lastFov;
    static float lastGrid;
    vector eye=getproperty(VF_ORIGIN),angles=getproperty(VF_ANGLES),size=getproperty(VF_SIZE);
    vector viewport=getproperty(VF_MIN),fov=getproperty(VF_FOV);
    vector cell=[floor(eye_x/1024),floor(eye_y/1024),floor(eye_z/1024)];
    float grid=fb_grid(),alpha=bound(0,cvar("ftebroom_grid_alpha"),1);
    int rebuild=!valid || epoch!=fb_grid_geometry_epoch || model!=selectedbrushmodel || region!=cell;
    if(rebuild) {
        region=cell;epoch=fb_grid_geometry_epoch;model=selectedbrushmodel;valid=TRUE;
        fb_grid_face_count=0;
        vector center=(cell+'0.5 0.5 0.5')*1024;
        for(int a=0;a<6;a++) distances[a]=center*axes[a]+5120;
        int count=brush_findinvolume(model,axes,distances,6,ids,__NULL__,ids.length);
        for(int b=0;b<min(count,ids.length);b++) for(int f=1;f<=128;f++) {
            int n=brush_getfacepoints(model,ids[b],f,facepoints,MAX_FACEPOINTS);
            if(n<3) break;
            if(fb_grid_face_count==fb_grid_face_capacity) {
                int capacity=max(256,fb_grid_face_capacity*2);
                fb_grid_face_t *items=memalloc(sizeof(fb_grid_face_t)*capacity);
                if(fb_grid_face_count) memcpy(items,fb_grid_faces,sizeof(fb_grid_face_t)*fb_grid_face_count);
                if(fb_grid_faces) memfree(fb_grid_faces);
                fb_grid_faces=items;fb_grid_face_capacity=capacity;
            }
            fb_grid_face_t *face=&fb_grid_faces[fb_grid_face_count++];
            face.id=ids[b];face.count=n;face.center='0 0 0';
            memcpy(face.points,facepoints,sizeof(vector)*n);
            face.normal=normalize(crossproduct(facepoints[1]-facepoints[0],facepoints[2]-facepoints[0]));
            face.u=0;face.v=1;
            if(fabs(face.normal[0])>fabs(face.normal[1]) && fabs(face.normal[0])>fabs(face.normal[2])) {face.u=1;face.v=2;}
            else if(fabs(face.normal[1])>fabs(face.normal[2])) {face.u=0;face.v=2;}
            for(int j=0;j<n;j++) face.center+=facepoints[j];
            face.center=face.center / (float)n;
        }
    }
    if(geometryOnly) {lastGrid=-1;return;}
    int reproject=rebuild || eye!=lastEye || angles!=lastAngles || size!=lastSize || viewport!=lastMin || fov!=lastFov || grid!=lastGrid;
    lastEye=eye;lastAngles=angles;lastSize=size;lastMin=viewport;lastFov=fov;lastGrid=grid;
    shaderforname("ftebroom/surfacegrid","{\npolygonoffset\ncull none\n{\nmap textures/ftebroom/overlay.tga\nblendfunc blend\nrgbgen vertex\nalphagen vertex\n}\n}");
    int previous=-1,replaced=FALSE;
    for(int i=0;i<fb_grid_face_count;i++) {
        fb_grid_face_t *face=&fb_grid_faces[i];
        if(reproject) face.spacing=fb_grid_display_step(face.center,face.normal);
        if(face.id!=previous) {previous=face.id;replaced=fb_preview_replaces(model,face.id);}
        if(replaced) continue;
        R_BeginPolygon("ftebroom/surfacegrid",3);
        for(int j=0;j<face.count;j++) R_PolygonVertex(face.points[j],[face.points[j][face.u]/face.spacing,face.points[j][face.v]/face.spacing,0],'0.2 0.25 0.3',alpha);
        R_EndPolygon();
    }
}

#include "ftebroom_edit.qc"

void ftebroom_prepare()
{
    fb_grid();
    fb_document_tick();
    fb_view_remember_selection();
    curmousepos=[cvar("ftebroom_mouse_x"),cvar("ftebroom_mouse_y"),0];
    fb_tool_pointer_move(curmousepos,cvar("ftebroom_alt"),cvar("ca_brush_view"));
}
void ftebroom_frame()
{
    fb_pick_draw_entities();
    if (fb_active && fb_dragged && !fb_face_select && fb_owner!=FB_OWNER_SELECTION) {
        if(!cvar("ca_brush_view")) DrawQCBrushTextured(fb_preview,fb_moving?fb_facecount:6,'1 1 1',0.35);
        DrawQCBrushWireframe(fb_preview,fb_moving?fb_facecount:6,"chop",'1 0.5 0',1);
    }
    if (cvar("ftebroom_grid_visible") && !cvar("ca_brush_view")) {
        fb_surfacegrid();
        shaderforname("ftebroom/worldgrid","{\n{\nmap $whiteimage\nblendfunc blend\nrgbgen vertex\nalphagen vertex\n}\n}");
        // Keep the construction plane just behind a coincident brush surface.
        float z=cvar("ftebroom_plane")-0.05;
        float g=fb_grid_display_step([0,0,z],'0 0 1');
        for (int i=-32;i<=32;i++) {
            R_BeginPolygon("ftebroom/worldgrid");
            R_PolygonVertex([i*g,-32*g,z],'0 0','0.16 0.18 0.2',bound(0,cvar("ftebroom_grid_alpha"),1));
            R_PolygonVertex([i*g,32*g,z],'0 0','0.16 0.18 0.2',bound(0,cvar("ftebroom_grid_alpha"),1)); R_EndPolygon();
            R_BeginPolygon("ftebroom/worldgrid");
            R_PolygonVertex([-32*g,i*g,z],'0 0','0.16 0.18 0.2',bound(0,cvar("ftebroom_grid_alpha"),1));
            R_PolygonVertex([32*g,i*g,z],'0 0','0.16 0.18 0.2',bound(0,cvar("ftebroom_grid_alpha"),1)); R_EndPolygon();
        }
    }
    fb_tool_draw();
    fb_tool_panel_state();
    fb_material_state();
    int selectionContext=0;
    if(selectedbrushcount) {
        selectionContext=1;
        for(int b=0;b<selectedbrushcount;b++)
            if(!selbrush_whole(&selectedbrushes[b])) selectionContext=2;
    }
    cvar_set("ftebroom_ctx_selection",itos(selectionContext));
    int view=cvar("ca_brush_view");
    cvar_set("ftebroom_ctx_view",itos(view==3?1:(view==2?2:(view==1?3:0))));
    cvar_set("ftebroom_selection_count",itos(selectedbrushcount));
    cvar_set("ftebroom_entity_selection_count",itos(fb_selected_entity_count));
    int openNode=fb_selection_open_node();
    cvar_set("ftebroom_open_group",openNode>=0?fb_nodes[openNode].name:"");
}
float() ftebroom_command =
{
    if(fb_document_command()) return TRUE;
    if(fb_grid_command()) return TRUE;
    if(fb_tools_command()) return TRUE;
    if(argv(0)=="ftebroom_move") {fb_move_numeric([stof(argv(1)),stof(argv(2)),stof(argv(3))]);return TRUE;}
    if(argv(0)=="ftebroom_undo") {fb_tool_refresh();brush_undo();return TRUE;}
    if(argv(0)=="ftebroom_redo") {fb_tool_refresh();brush_redo();return TRUE;}
    if(argv(0)=="ftebroom_delete" || argv(0)=="brushedit_delete") {
        fb_tool_refresh();fb_tx_begin("Delete");
        int count=selectedbrushcount;
        for(int i=0;i<count;i++) {
            if(!selectedbrushcount) break;
            brush_history_delete(selectedbrushes[0].model,selectedbrushes[0].id);
        }
        fb_tx_commit();return TRUE;
    }
    if(argv(0)=="ftebroom_nudge") {
        vector offset='0 0 0';int axis=stoi(argv(1));
        if(axis<0 || axis>2) return TRUE;
        offset[axis]=stof(argv(2))*fb_grid();
        if(cvar("ca_brush_view") && axis<2) {
            fb_view_axes(cvar("ca_brush_view"));
            vector direction=fb_view_right;if(axis==1) direction=fb_view_up;
            offset=direction*stof(argv(2))*fb_grid();
        }
        fb_tx_begin("Nudge");fb_move_numeric(offset);fb_tx_commit();return TRUE;
    }
    if (argv(0)=="ftebroom_pointer") {
        vector pixel=[stof(argv(2)),stof(argv(3)),0]; float alt=stof(argv(4));
        float oldCtrl=cvar("ftebroom_ctrl"),oldShift=cvar("ftebroom_shift");
        if(argv(6)!="") {
            int modifiers=stoi(argv(6));
            cvar_set("ftebroom_ctrl",(modifiers&1)?"1":"0");
            cvar_set("ftebroom_shift",(modifiers&2)?"1":"0");
        }
        if(argv(1)=="down") {
            fb_tool_pointer_down(pixel,alt,cvar("ca_brush_view"));
        }
        else if(argv(1)=="up") fb_tool_pointer_up(pixel,alt,cvar("ca_brush_view"));
        else if(argv(1)=="dblclick" && !cvar("ftebroom_tool")) fb_selection_double(pixel,cvar("ftebroom_ctrl"));
        else if(argv(1)=="drill" && !fb_active && !cvar("ftebroom_tool")) {fb_pick(pixel);fb_selection_drill_hits(alt>0?1:-1);}
        else if(argv(1)=="cancel") {fb_cancel();fb_owner=FB_OWNER_NONE;}
        cvar_set("ftebroom_ctrl",ftos(oldCtrl));cvar_set("ftebroom_shift",ftos(oldShift));
        return TRUE;
    }
    if(argv(0)=="ftebroom_material") {fb_material_edit("material",0);return TRUE;}
    if(argv(0)=="ftebroom_uv") {fb_material_edit(argv(1),stof(argv(2)));return TRUE;}
    if(argv(0)=="ftebroom_clip") {if(argv(1)=="apply") fb_clip_apply(); else fb_clip_count=0; return TRUE;}
    if (argv(0)=="ftebroom_look") {
        fb_camera_input("look",stof(argv(1)),stof(argv(2)),0,0);
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
