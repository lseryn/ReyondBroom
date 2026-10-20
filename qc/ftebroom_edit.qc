// SPDX-License-Identifier: GPL-2.0-or-later
// Material edits and clipping share the brush history transaction boundary.
vector fb_clip_normal;
float fb_clip_dist;

vector fb_uv_values(brushface_t *face)
{
    brushface_t base = *face;
    reset_texturecoords(&base);
    float u=face->sdir*base.sdir, v=face->sdir*base.tdir;
    float sx=1/max(0.000001,vlen(face->sdir));
    float sy=1/max(0.000001,vlen(face->tdir));
    if(u*(face->tdir*base.tdir)-v*(face->tdir*base.sdir)<0) sy=-sy;
    return [sx,sy,atan2(-v,u)*180/M_PI];
}
void fb_material_state()
{
    static brushface_t faces[128];
    int count=0,contents,firstContents=0,firstFlags=0,firstValue=0,mixedFields=0;
    string material="";vector values='1 1 0',bias='0 0 0';int mixed=FALSE;
    for(int b=0;b<selectedbrushcount;b++) {
        int n=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,faces,128,&contents);
        for(int f=0;f<min(n,128);f++) if(selbrush_face(&selectedbrushes[b],f)) {
            vector uv=fb_uv_values(&faces[f]);
            if(!count) {
                material=strzone(faces[f].shadername);values=uv;bias=[faces[f].sbias,faces[f].tbias,0];
                firstContents=contents;firstFlags=faces[f].surfaceflags;firstValue=faces[f].surfacevalue;
            } else {
                if(material!=faces[f].shadername) mixed=TRUE;
                if(fabs(uv_x-values_x)>0.0001) mixedFields|=1;
                if(fabs(uv_y-values_y)>0.0001) mixedFields|=2;
                if(fabs(uv_z-values_z)>0.0001) mixedFields|=4;
                if(fabs(faces[f].sbias-bias_x)>0.0001) mixedFields|=8;
                if(fabs(faces[f].tbias-bias_y)>0.0001) mixedFields|=16;
                if(firstFlags!=faces[f].surfaceflags) mixedFields|=32;
                if(firstContents!=contents) mixedFields|=64;
                if(firstValue!=faces[f].surfacevalue) mixedFields|=128;
            }
            count++;
        }
    }
    cvar_set("ftebroom_current_material",mixed?"<multiple materials>":material);
    cvar_set("ftebroom_face_count",itos(count));cvar_set("ftebroom_uv_mixed",itos(mixedFields));
    cvar_set("ftebroom_scale_x",ftos(values_x));cvar_set("ftebroom_scale_y",ftos(values_y));
    cvar_set("ftebroom_angle",ftos(values_z));cvar_set("ftebroom_offset_x",ftos(bias_x));cvar_set("ftebroom_offset_y",ftos(bias_y));
    cvar_set("ftebroom_surface_flags",itos(firstFlags));cvar_set("ftebroom_content_flags",itos(firstContents));cvar_set("ftebroom_surface_value",itos(firstValue));
    if(count && !mixed && fb_faces_count()) cvar_set("ca_newbrushtexture",material);
    if(count) strunzone(material);
}
vector fb_uv_rotate(vector axis,vector normal,float angle)
{
    // Rodrigues rotation preserves skew and the normal component of Valve 220 axes.
    float c=cos(angle),s=sin(angle);
    return axis*c+crossproduct(normal,axis)*s+normal*(normal*axis)*(1-c);
}
void fb_material_change(string operation,float value,int relative)
{
    if(operation!="material" && operation!="sx" && operation!="sy" && operation!="angle" && operation!="ox" && operation!="oy") return;
    if(operation!="material" && (!fb_geom_finite(value) || fabs(value)>1000000)) return;
    static brushface_t faces[128];int contents;
    string material=strzone(cvar_string("ca_newbrushtexture"));
    // Validate every selected face before opening a transaction.
    for(int candidate=0;candidate<selectedbrushcount;candidate++) {
        int n=brush_get(selectedbrushes[candidate].model,selectedbrushes[candidate].id,faces,128,&contents);
        if(n>128) {strunzone(material);return;}
        for(int f=0;f<n;f++) if(selbrush_face(&selectedbrushes[candidate],f)) {
            vector uv=fb_uv_values(&faces[f]);float scale=value;
            if(relative && operation=="sx") scale+=uv_x;
            if(relative && operation=="sy") scale+=uv_y;
            if((operation=="sx" || operation=="sy") && fabs(scale)<0.001) {strunzone(material);return;}
        }
    }
    fb_tx_begin(operation=="material"?"Set Material":strcat("Texture ",operation));
    for(int b=0;b<selectedbrushcount;b++) {
        int n=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,faces,128,&contents);
        if(n<=0 || n>128) continue;
        for(int f=0;f<n;f++) if(selbrush_face(&selectedbrushes[b],f)) {
            if(operation=="material") faces[f].shadername=material;
            else {
                vector uv=fb_uv_values(&faces[f]);
                if(operation=="sx") faces[f].sdir*=uv_x/(relative?uv_x+value:value);
                else if(operation=="sy") faces[f].tdir*=uv_y/(relative?uv_y+value:value);
                else if(operation=="ox") faces[f].sbias=relative?faces[f].sbias+value:value;
                else if(operation=="oy") faces[f].tbias=relative?faces[f].tbias+value:value;
                else if(operation=="angle") {
                    brushface_t base=faces[f];reset_texturecoords(&base);
                    float delta=(relative?value:value-uv_z)*M_PI/180;
                    if(crossproduct(base.sdir,base.tdir)*faces[f].planenormal>0) delta=-delta;
                    faces[f].sdir=fb_uv_rotate(faces[f].sdir,faces[f].planenormal,delta);
                    faces[f].tdir=fb_uv_rotate(faces[f].tdir,faces[f].planenormal,delta);
                }
            }
        }
        brush_history_edit(selectedbrushes[b].model,selectedbrushes[b].id,faces,n,contents);
    }
    fb_tx_commit();strunzone(material);fb_material_state();
}
void fb_material_edit(string operation,float value) {fb_material_change(operation,value,FALSE);}
void fb_material_flags(string operation,int value,int toggle)
{
    if(operation!="surface" && operation!="contents" && operation!="value") return;
    static brushface_t faces[128];int contents;
    for(int b=0;b<selectedbrushcount;b++) if(brush_get(selectedbrushes[b].model,selectedbrushes[b].id,__NULL__,0,__NULL__)>128) return;
    fb_tx_begin("Face Attributes");
    for(int b=0;b<selectedbrushcount;b++) {
        int count=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,faces,128,&contents);
        if(count<4) continue;
        if(operation=="contents") contents=toggle==1?(contents|value):(toggle==2?(contents&~value):value);
        for(int f=0;f<count;f++) if(selbrush_face(&selectedbrushes[b],f)) {
            if(operation=="surface") faces[f].surfaceflags=toggle==1?(faces[f].surfaceflags|value):(toggle==2?(faces[f].surfaceflags&~value):value);
            if(operation=="value") faces[f].surfacevalue=value;
        }
        brush_history_edit(selectedbrushes[b].model,selectedbrushes[b].id,faces,count,contents);
    }
    fb_tx_commit();fb_material_state();
}
vector fb_clip_surface_normal;
var int fb_clip_source_view=-1;
float fb_clip_plane()
{
    if(fb_clip_count<2) return FALSE;
    int clipView=cvar("ca_brush_view");if(fb_clip_source_view>=0) clipView=fb_clip_source_view;
    vector third=fb_clip_count==3?fb_clip_points[2]:fb_clip_points[0]+'0 0 128';
    if(fb_clip_count==2 && !clipView && vlen(fb_clip_surface_normal)>0.5)
        third=fb_clip_points[0]+fb_clip_surface_normal*128;
    if(fb_clip_count==2 && clipView==1) third=fb_clip_points[0]+'128 0 0';
    if(fb_clip_count==2 && clipView==2) third=fb_clip_points[0]+'0 128 0';
    vector normal=crossproduct(fb_clip_points[1]-fb_clip_points[0],third-fb_clip_points[0]);
    if(vlen(normal)<0.01 && fb_clip_count==2) {
        vector edge=fb_clip_points[1]-fb_clip_points[0];
        vector unit=normalize(edge),axis='0 0 1';if(fabs(unit_z)>0.9) axis='0 1 0';
        normal=crossproduct(edge,axis);
    }
    if(vlen(normal)<0.01) return FALSE;
    fb_clip_normal=normalize(normal); fb_clip_dist=fb_clip_normal*fb_clip_points[0];
    return TRUE;
}
void fb_clip_pick(vector pixel,int view)
{
    if(fb_clip_count==3) fb_clip_count=0;
    vector start=unproject(pixel),end=unproject(pixel+'0 0 8192');
    if(view) {end=unproject(pixel+'0 0 1');}
    int hits=fb_pick_query(start,end,pixel,0,FB_HIT_BRUSH|FB_HIT_PATCH,view!=0);
    vector point=fb_view_plane_point(pixel,view,[0,0,cvar("ftebroom_plane")]),normal='0 0 1';
    float distance=cvar("ftebroom_plane");
    if(view && !hits) {
        int depth=fb_view_depth_axis(view);
        vector anchor='0 0 0';
        if(fb_clip_count) anchor=fb_clip_points[0];
        else if(fb_view_has_selection) anchor=fb_view_lastmin;
        point=fb_view_plane_point(pixel,view,anchor);
        normal='0 0 0';normal[depth]=1;distance=anchor[depth];
    }
    if(hits) {point=fb_hits[0].point;normal=fb_hits[0].normal;distance=point*normal;}
    if(!fb_clip_count) {fb_clip_surface_normal=normal;fb_clip_source_view=view;}
    fb_clip_points[fb_clip_count++]=fb_snap_to_plane(point,normal,distance);
}
float fb_clip_candidate(brushface_t *source,int n,vector normal,float dist,brushface_t *result)
{
    memcpy(result,source,n*sizeof(brushface_t));
    result[n]=source[0]; result[n].planenormal=normal; result[n].planedist=dist;
    result[n].shadername=cvar_string("ca_newbrushtexture"); reset_texturecoords(&result[n]);
    static vector points[MAX_FACEPOINTS];
    if(brush_calcfacepoints(n+1,result,n+1,points,MAX_FACEPOINTS)<3) return FALSE;
    int valid=0;
    for(int f=1;f<=n+1;f++) if(brush_calcfacepoints(f,result,n+1,points,MAX_FACEPOINTS)>=3) valid++;
    return valid>=4;
}
void fb_clip_apply()
{
    if(!fb_clip_plane()) {print("FTEBroom: place two distinct cut points (or three non-collinear points).\n");return;}
    static brushface_t source[64], front[64], back[64];
    int total=selectedbrushcount;
    selbrush_t *selection=memalloc(total*sizeof(selbrush_t));
    memcpy(selection,selectedbrushes,total*sizeof(selbrush_t));
    fb_tx_begin("Clip");
    int mode=cvar("ftebroom_clip_keep"), applied=0;
    for(int b=0;b<total;b++) {
        int n=brush_get(selection[b].model,selection[b].id,__NULL__,0,__NULL__),contents;
        if(n<4 || n>64) continue;
        brush_get(selection[b].model,selection[b].id,source,64,&contents);
        fb_poly_t frontPoly={0},backPoly={0};
        if(!fb_split(source,n,fb_clip_normal,fb_clip_dist,&frontPoly,&backPoly)) {
            print(strcat("FTEBroom: Clip skipped brush: ",fb_geom_error,"\n"));continue;
        }
        for(int k=0;k<frontPoly.nf;k++) front[k]=frontPoly.faces[k].attr;
        for(int k=0;k<backPoly.nf;k++) back[k]=backPoly.faces[k].attr;
        // Owned polyhedron materials survive history's engine queries.
        brush_history_edit(selection[b].model,selection[b].id,mode==1?front:back,mode==1?frontPoly.nf:backPoly.nf,contents);
        if(mode==0) brush_history_create(selection[b].model,front,frontPoly.nf,contents,TRUE);
        fb_poly_free(&frontPoly);fb_poly_free(&backPoly);
        applied++;
    }
    fb_tx_commit(); memfree(selection); fb_clip_count=0;
    print(sprintf("FTEBroom: clipped %i brushes.\n",applied));
}
float fb_preview_replaces(int model,int id)
{
    if(fb_transform_replaces(model,id)) return TRUE;
    if(cvar("ftebroom_tool")!=FB_TOOL_CLIP) return FALSE;
    if(!brush_isselected(model,id)) return FALSE;
    if(!fb_clip_plane()) return FALSE;
    int n=brush_get(model,id,__NULL__,0,__NULL__);
    if(n<4 || n>64) return FALSE;
    static brushface_t source[64],part[65];
    brush_get(model,id,source,64,__NULL__);
    if(!fb_clip_candidate(source,n,fb_clip_normal,fb_clip_dist,part)) return FALSE;
    if(!fb_clip_candidate(source,n,-fb_clip_normal,-fb_clip_dist,part)) return FALSE;
    static vector vertices[MAX_FACEPOINTS];
    float lo=1000000,hi=-1000000;
    for(int f=1;f<=n;f++) {
        int count=brush_calcfacepoints(f,source,n,vertices,MAX_FACEPOINTS);
        for(int v=0;v<count;v++) {float d=vertices[v]*fb_clip_normal-fb_clip_dist;lo=min(lo,d);hi=max(hi,d);}
    }
    return lo < -0.01 && hi > 0.01;
}
void fb_clip_preview()
{
    cvar_set("ftebroom_clip_points",itos(fb_clip_count));
    if(cvar("ftebroom_tool")!=FB_TOOL_CLIP) {fb_clip_count=0;return;}
    for(int i=0;i<fb_clip_count;i++) {
        vector p=project(fb_clip_points[i]);
        cvar_set(sprintf("ftebroom_clip_point_%i",i),sprintf("%g %g",p_x,p_y));
    }
    if(!fb_clip_plane()) return;
    shaderforname("ftebroom/clipwire","{\ncull none\n{\nmap $whiteimage\nblendfunc blend\nrgbgen vertex\nalphagen vertex\nnodepthtest\n}\n}");
    shaderforname("ftebroom/discarded","{\ncull none\n{\nmap $whiteimage\nblendfunc blend\nrgbgen vertex\nalphagen vertex\n}\n}");
    static brushface_t source[64], candidate[65];
    int mode=cvar("ftebroom_clip_keep");
    for(int b=0;b<selectedbrushcount;b++) {
        if(!fb_preview_replaces(selectedbrushes[b].model,selectedbrushes[b].id)) continue;
        int contents,n=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,source,64,&contents);
        for(int side=1;side<=2;side++) {
            float sign=side==1?-1:1;
            if(!fb_clip_candidate(source,n,fb_clip_normal*sign,fb_clip_dist*sign,candidate)) continue;
            float keep=(mode==0 || mode==side);
            if(keep) DrawQCBrushTextured(candidate,n+1,'1 1 1',1);
            else DrawQCBrushSolid(candidate,n+1,"ftebroom/discarded",'1 0.35 0.15',0.18);
            DrawQCBrushWireframe(candidate,n+1,"ftebroom/clipwire",keep?'0 0.8 1':'1 0.35 0.15',keep?1:0.3);
        }
    }
}
