// SPDX-License-Identifier: GPL-2.0-or-later
vector fb_assemble_points[256],fb_assemble_saved[256];
vector fb_assemble_hover,fb_assemble_normal,fb_assemble_start,fb_assemble_pixel,fb_assemble_u,fb_assemble_v;
int fb_assemble_hover_valid,fb_assemble_drag,fb_assemble_saved_count;
float fb_assemble_axis_start;
void fb_assemble_add(vector point)
{
    for(int p=0;p<fb_shape_count;p++) if(vlen(fb_assemble_points[p]-point)<FB_GEOM_MERGE) return;
    if(fb_shape_count>=fb_assemble_points.length) {cvar_set("ftebroom_selection_status","Brush assembly supports at most 256 points");return;}
    fb_assemble_points[fb_shape_count++]=point;
}
int fb_assemble_pick(vector pixel,int view)
{
    fb_assemble_hover_valid=FALSE;if(view) return FALSE;
    if(!fb_pick_query(unproject(pixel),unproject(pixel+'0 0 8192'),pixel,0,FB_HIT_BRUSH,FALSE)) return FALSE;
    fb_assemble_hover=fb_snap_to_plane(fb_hits[0].point,fb_hits[0].normal,fb_hits[0].point*fb_hits[0].normal);
    fb_assemble_hover_valid=TRUE;return TRUE;
}
int fb_assemble_planar(vector pixel)
{
    if(fb_shape_count<3) return FALSE;
    vector normal='0 0 0';
    for(int p=2;p<fb_shape_count;p++) {
        normal=crossproduct(fb_assemble_points[1]-fb_assemble_points[0],fb_assemble_points[p]-fb_assemble_points[0]);
        if(vlen(normal)>0.001) break;
    }
    if(vlen(normal)<0.001) return FALSE;normal=normalize(normal);
    for(int p=0;p<fb_shape_count;p++) if(fabs((fb_assemble_points[p]-fb_assemble_points[0])*normal)>FB_GEOM_PLANE) return FALSE;
    vector start=unproject(pixel),ray=unproject(pixel+'0 0 8192')-start;
    float denominator=ray*normal;if(fabs(denominator)<0.00001) return FALSE;
    vector point=start+ray*((fb_assemble_points[0]-start)*normal/denominator);
    // Every supporting edge of the planar convex hull bounds the hit point.
    for(int a=0;a<fb_shape_count;a++) for(int b=a+1;b<fb_shape_count;b++) {
        vector side=normalize(crossproduct(fb_assemble_points[b]-fb_assemble_points[a],normal));
        float lo=0,hi=0;for(int p=0;p<fb_shape_count;p++) {float d=(fb_assemble_points[p]-fb_assemble_points[a])*side;lo=min(lo,d);hi=max(hi,d);}
        float distance=(point-fb_assemble_points[a])*side;
        if(lo>=-FB_GEOM_PLANE && distance<-FB_GEOM_PLANE) return FALSE;
        if(hi<=FB_GEOM_PLANE && distance>FB_GEOM_PLANE) return FALSE;
    }
    fb_assemble_normal=normal;fb_assemble_start=point;return TRUE;
}
int fb_assemble_axis(vector pixel,float *distance)
{
    vector start=unproject(pixel),ray=normalize(unproject(pixel+'0 0 8192')-start),offset=start-fb_assemble_start;
    float dot=ray*fb_assemble_normal,denominator=1-dot*dot;if(denominator<0.00001) return FALSE;
    *distance=(offset*fb_assemble_normal-dot*(offset*ray))/denominator;return TRUE;
}
void fb_assemble_down(vector pixel,int view)
{
    if(view) return;
    fb_assemble_saved_count=fb_shape_count;memcpy(fb_assemble_saved,fb_assemble_points,sizeof(vector)*fb_shape_count);
    fb_assemble_pixel=pixel;
    if(cvar("ftebroom_shift") && fb_assemble_planar(pixel)) {
        if(!fb_assemble_axis(pixel,&fb_assemble_axis_start)) return;
        if(fb_shape_count*2>fb_assemble_points.length) return;
        fb_assemble_drag=2;fb_active=TRUE;return;
    }
    if(!fb_assemble_pick(pixel,view)) return;
    fb_assemble_start=fb_assemble_hover;fb_assemble_normal=fb_hits[0].normal;
    vector axis='0 0 1';if(fabs(fb_assemble_normal_z)>0.9) axis='0 1 0';
    fb_assemble_u=normalize(crossproduct(axis,fb_assemble_normal));fb_assemble_v=crossproduct(fb_assemble_normal,fb_assemble_u);
    fb_assemble_add(fb_assemble_start);fb_assemble_drag=1;fb_active=TRUE;
}
void fb_assemble_move(vector pixel,int view)
{
    if(!fb_assemble_drag) {fb_assemble_pick(pixel,view);return;}
    if(view || vlen(pixel-fb_assemble_pixel)<3) return;
    if(fb_assemble_drag==2) {
        float distance;if(!fb_assemble_axis(pixel,&distance)) return;
        distance=fb_snap_scalar(distance-fb_assemble_axis_start);
        fb_shape_count=fb_assemble_saved_count;
        for(int p=0;p<fb_assemble_saved_count;p++) fb_assemble_add(fb_assemble_saved[p]+fb_assemble_normal*distance);
    } else {
        vector start=unproject(pixel),ray=unproject(pixel+'0 0 8192')-start;
        float denominator=ray*fb_assemble_normal;if(fabs(denominator)<0.00001) return;
        vector end=start+ray*((fb_assemble_start-start)*fb_assemble_normal/denominator),delta=end-fb_assemble_start;
        vector u=fb_assemble_u*fb_snap_scalar(delta*fb_assemble_u),v=fb_assemble_v*fb_snap_scalar(delta*fb_assemble_v);
        fb_shape_count=fb_assemble_saved_count;fb_assemble_add(fb_assemble_start);fb_assemble_add(fb_assemble_start+u);
        fb_assemble_add(fb_assemble_start+u+v);fb_assemble_add(fb_assemble_start+v);
    }
}
void fb_assemble_up(vector pixel,int view) {fb_assemble_move(pixel,view);fb_assemble_drag=0;fb_active=FALSE;}
void fb_assemble_cancel()
{
    if(!fb_assemble_drag) return;fb_shape_count=fb_assemble_saved_count;
    memcpy(fb_assemble_points,fb_assemble_saved,sizeof(vector)*fb_shape_count);fb_assemble_drag=0;
}
void fb_assemble_double(vector pixel,int view)
{
    if(!fb_assemble_pick(pixel,view)) return;
    static vector points[MAX_FACEPOINTS];
    int count=brush_getfacepoints(fb_hits[0].model,fb_hits[0].id,fb_hits[0].face,points,MAX_FACEPOINTS);
    if(count+fb_shape_count>fb_assemble_points.length) return;
    for(int p=0;p<count;p++) fb_assemble_add(points[p]);
    fb_assemble_drag=0;fb_active=FALSE;
}
void fb_assemble_apply()
{
    fb_poly_t hull={0};if(!fb_hull(fb_assemble_points,fb_shape_count,&hull)) {
        cvar_set("ftebroom_selection_status","Place at least four non-coplanar points to create a brush");return;
    }
    static brushface_t faces[64];for(int f=0;f<hull.nf;f++) faces[f]=hull.faces[f].attr;
    fb_tx_begin("Assemble Brush");int model=fb_creation_model();brush_deselectall();fb_restore_entity_selection(-1);
    int created=0;if(model) created=brush_history_create(model,faces,hull.nf,CONTENTBIT_SOLID,TRUE);
    if(created) {fb_tx_commit();fb_shape_count=0;}else fb_tx_cancel();
    fb_poly_free(&hull);
}
// Project the planar point cloud and build its convex boundary; interior points
// are not edges. The outline is also useful before a volume can exist.
int fb_assemble_outline(int *outline)
{
    if(fb_shape_count<2)return 0;
    vector origin=fb_assemble_points[0],u=normalize(fb_assemble_points[1]-origin),normal='0 0 0';
    for(int p=2;p<fb_shape_count;p++) {
        normal=crossproduct(u,fb_assemble_points[p]-origin);if(vlen(normal)>FB_GEOM_PLANE)break;
    }
    if(vlen(normal)<=FB_GEOM_PLANE){outline[0]=0;outline[1]=1;return 2;}
    normal=normalize(normal);vector v=crossproduct(normal,u);
    for(int p=0;p<fb_shape_count;p++)if(fabs((fb_assemble_points[p]-origin)*normal)>FB_GEOM_PLANE)return 0;
    int order[256];vector coords[256];
    for(int p=0;p<fb_shape_count;p++) {
        coords[p]=[fb_assemble_points[p]*u,fb_assemble_points[p]*v,0];int at=p;
        while(at>0) {
            vector previous=coords[order[at-1]];
            if(previous_x<coords[p][0] || (previous_x==coords[p][0] && previous_y<=coords[p][1]))break;
            order[at]=order[at-1];at--;
        }
        order[at]=p;
    }
    int count=0;
    for(int p=0;p<fb_shape_count;p++) {
        while(count>=2) {
            vector turn=crossproduct(coords[outline[count-1]]-coords[outline[count-2]],coords[order[p]]-coords[outline[count-1]]);
            if(turn_z>0.0001)break;count--;
        }
        outline[count++]=order[p];
    }
    int lower=count;
    for(int p=fb_shape_count-2;p>=0;p--) {
        while(count>lower) {
            vector turn=crossproduct(coords[outline[count-1]]-coords[outline[count-2]],coords[order[p]]-coords[outline[count-1]]);
            if(turn_z>0.0001)break;count--;
        }
        outline[count++]=order[p];
    }
    return count-1;
}
void fb_assemble_draw()
{
    if(cvar("ftebroom_tool")!=FB_TOOL_BRUSH) return;
    shaderforname("ftebroom/assemble","{\ncull none\n{\nmap $whiteimage\nblendfunc blend\nrgbgen vertex\nalphagen vertex\nnodepthtest\n}\n}");
    fb_poly_t hull={0};
    if(fb_hull(fb_assemble_points,fb_shape_count,&hull)) {
        static brushface_t faces[64];for(int f=0;f<hull.nf;f++) faces[f]=hull.faces[f].attr;
        DrawQCBrushSolid(faces,hull.nf,"ftebroom/assemble",'1 0.8 0',0.15);
        DrawQCBrushWireframe(faces,hull.nf,"ftebroom/assemble",'1 0.8 0',1);
    }
    else {
        static int outline[512];int count=fb_assemble_outline(outline);
        vector center='0 0 0';for(int p=0;p<count;p++)center+=fb_assemble_points[outline[p]];
        if(count)center/=(float)count;
        for(int p=0;p<count;p++) {
            vector a=fb_assemble_points[outline[p]],b=fb_assemble_points[outline[(p+1)%count]];
            if(count>2){R_BeginPolygon("ftebroom/assemble",3);R_PolygonVertex(center,'0 0 0','1 0.8 0',0.15);R_PolygonVertex(a,'0 0 0','1 0.8 0',0.15);R_PolygonVertex(b,'0 0 0','1 0.8 0',0.15);R_EndPolygon();}
            R_BeginPolygon("ftebroom/assemble");R_PolygonVertex(a,'0 0 0','1 0.8 0',1);R_PolygonVertex(b,'0 0 0','1 0.8 0',1);R_EndPolygon();
        }
    }
    fb_poly_free(&hull);
    cvar_set("ftebroom_shape_points",itos(fb_shape_count));
    for(int p=0;p<fb_shape_count;p++) {vector screen=project(fb_assemble_points[p]);cvar_set(sprintf("ftebroom_shape_point_%i",p),sprintf("%g %g",screen_x,screen_y));}
    cvar_set("ftebroom_shape_hover","");
    if(fb_assemble_hover_valid) {vector screen=project(fb_assemble_hover);cvar_set("ftebroom_shape_hover",sprintf("%g %g",screen_x,screen_y));}
}
