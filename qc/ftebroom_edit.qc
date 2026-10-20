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
    int count=0, contents;
    string material="";
    vector values='1 1 0';
    float mixed=0, uvMixed=0;
    for(int b=0;b<selectedbrushcount;b++) {
        int n=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,faces,128,&contents);
        for(int f=0;f<min(n,64);f++) if(selectedbrushes[b].facemask&(1ull<<f)) {
            vector uv=fb_uv_values(&faces[f]);
            if(!count) {material=strzone(faces[f].shadername);values=uv;}
            else {
                if(material!=faces[f].shadername) mixed=1;
                if(vlen(uv-values)>0.0001) uvMixed=1;
            }
            count++;
        }
    }
    cvar_set("ftebroom_current_material",mixed?"<multiple materials>":material);
    cvar_set("ftebroom_face_count",itos(count));
    cvar_set("ftebroom_uv_mixed",ftos(uvMixed));
    cvar_set("ftebroom_scale_x",ftos(values_x));
    cvar_set("ftebroom_scale_y",ftos(values_y));
    cvar_set("ftebroom_angle",ftos(values_z));
    if(count) strunzone(material);
}
void fb_material_edit(string operation, float value)
{
    if(operation!="material" && operation!="sx" && operation!="sy" && operation!="angle") return;
    if(operation!="material" && (!(value==value) || fabs(value)>10000)) return;
    if((operation=="sx" || operation=="sy") && fabs(value)<0.001) return;
    static brushface_t faces[128];
    int contents;
    string material=strzone(cvar_string("ca_newbrushtexture"));
    if(cvar("ftebroom_skip_setup")) print(sprintf("FTEBroom TEST edit %s material=%s brushes=%i\n",operation,material,selectedbrushcount));
    history_transaction=gettime(0);
    for(int b=0;b<selectedbrushcount;b++) {
        int n=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,faces,128,&contents);
        if(n<=0 || n>64) continue;
        for(int f=0;f<n;f++) if(selectedbrushes[b].facemask&(1ull<<f)) {
            if(operation=="material") faces[f].shadername=material;
            else {
                vector uv=fb_uv_values(&faces[f]);
                if(operation=="sx") faces[f].sdir*=uv_x/value;
                else if(operation=="sy") faces[f].tdir*=uv_y/value;
                else if(operation=="angle") {
                    brushface_t base=faces[f]; reset_texturecoords(&base);
                    float angle=value*M_PI/180;
                    faces[f].sdir=(base.sdir*cos(angle)-base.tdir*sin(angle))/uv_x;
                    faces[f].tdir=(base.sdir*sin(angle)+base.tdir*cos(angle))/uv_y;
                }
            }
        }
        brush_history_edit(selectedbrushes[b].model,selectedbrushes[b].id,faces,n,contents);
    }
    history_transaction=0;
    strunzone(material);
    fb_material_state();
}
float fb_clip_plane()
{
    if(fb_clip_count<2) return FALSE;
    vector third=fb_clip_count==3?fb_clip_points[2]:fb_clip_points[0]+'0 0 128';
    if(fb_clip_count==2 && cvar("ca_brush_view")==1) third=fb_clip_points[0]+'128 0 0';
    if(fb_clip_count==2 && cvar("ca_brush_view")==2) third=fb_clip_points[0]+'0 128 0';
    vector normal=crossproduct(fb_clip_points[1]-fb_clip_points[0],third-fb_clip_points[0]);
    if(vlen(normal)<0.01) return FALSE;
    fb_clip_normal=normalize(normal); fb_clip_dist=fb_clip_normal*fb_clip_points[0];
    return TRUE;
}
void fb_clip_pick(vector pixel)
{
    if(fb_clip_count==3) fb_clip_count=0;
    vector a=unproject(pixel), b=unproject(pixel+'0 0 8192');
    *world_hitcontentsmaski=~0;
    traceline(a,b,TRUE,world); *world_hitcontentsmaski=0;
    vector point=trace_brush_id?trace_endpos:fb_xy(pixel,cvar("ftebroom_plane"));
    fb_clip_points[fb_clip_count++]=fb_snap(point);
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
    static brushface_t source[64], front[65], back[65];
    int total=selectedbrushcount;
    selbrush_t *selection=memalloc(total*sizeof(selbrush_t));
    memcpy(selection,selectedbrushes,total*sizeof(selbrush_t));
    history_transaction=gettime(0);
    int mode=cvar("ftebroom_clip_keep"), applied=0;
    for(int b=0;b<total;b++) {
        if(brush_get(selection[b].model,selection[b].id,__NULL__,0,__NULL__)>63) continue;
        int contents, n=brush_get(selection[b].model,selection[b].id,source,63,&contents);
        if(n<4 || n>63) continue;
        if(!fb_clip_candidate(source,n,fb_clip_normal,fb_clip_dist,back) ||
           !fb_clip_candidate(source,n,-fb_clip_normal,-fb_clip_dist,front)) continue;
        // Tangent planes must not duplicate an unchanged volume.
        static vector points[MAX_FACEPOINTS];
        float lo=1000000,hi=-1000000;
        for(int f=1;f<=n;f++) {
            int np=brush_calcfacepoints(f,source,n,points,MAX_FACEPOINTS);
            for(int j=0;j<np;j++) {float d=points[j]*fb_clip_normal-fb_clip_dist;lo=min(lo,d);hi=max(hi,d);}
        }
        if(lo>=-0.01 || hi<=0.01) continue;
        // History snapshots call brush_get and must not invalidate the second half.
        for(int k=0;k<=n;k++) {
            front[k].shadername=strzone(front[k].shadername);
            back[k].shadername=strzone(back[k].shadername);
        }
        brush_history_edit(selection[b].model,selection[b].id,mode==1?front:back,n+1,contents);
        if(mode==0) brush_history_create(selection[b].model,front,n+1,contents,TRUE);
        for(int k=0;k<=n;k++) {
            strunzone(front[k].shadername);strunzone(back[k].shadername);
        }
        applied++;
    }
    history_transaction=0; memfree(selection); fb_clip_count=0;
    print(sprintf("FTEBroom: clipped %i brushes.\n",applied));
}
float fb_preview_replaces(int model,int id)
{
    if(fb_active) if(fb_dragged) if(fb_moving) if(model==fb_model) if(id==fb_brush) return TRUE;
    if(cvar("ftebroom_tool")!=FB_TOOL_CLIP) return FALSE;
    if(!brush_isselected(model,id)) return FALSE;
    if(!fb_clip_plane()) return FALSE;
    int n=brush_get(model,id,__NULL__,0,__NULL__);
    if(n<4 || n>63) return FALSE;
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
        int contents,n=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,source,63,&contents);
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
