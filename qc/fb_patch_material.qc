// SPDX-License-Identifier: GPL-2.0-or-later
// Patch UVs are stored on control points. Derive the inspector from that data,
// so edits, Undo and MAP reloads never depend on a separate UV metadata cache.
vector fb_patch_saxis,fb_patch_taxis,fb_patch_bias;
vector fb_patch_uv(patchvert_t *points,patchinfo_t info)
{
    int x=info.cpwidth-1,y=(info.cpheight-1)*info.cpwidth;
    fb_patch_bias=[points[0].s,points[0].t,0];
    fb_patch_saxis=[points[x].s-points[0].s,points[y].s-points[0].s,0];
    fb_patch_taxis=[points[x].t-points[0].t,points[y].t-points[0].t,0];
    float sx=1/max(0.000001,vlen(fb_patch_saxis)),sy=1/max(0.000001,vlen(fb_patch_taxis));
    vector handed=crossproduct(fb_patch_saxis,fb_patch_taxis);if(handed_z<0)sy=-sy;
    return [sx,sy,atan2(-fb_patch_saxis_y,fb_patch_saxis_x)*180/M_PI];
}
int fb_patch_material_change(int model,int id,string operation,float value,int relative,string material)
{
    patchinfo_t info;int count=patch_getcp(model,id,__NULL__,0,&info);if(!count)return FALSE;
    patchvert_t *points=memalloc(count*sizeof(patchvert_t));patch_getcp(model,id,points,count,&info);
    info.shadername=strzone(operation=="material"?material:info.shadername);
    vector uv=fb_patch_uv(points,info),bias=fb_patch_bias,sa=fb_patch_saxis,ta=fb_patch_taxis;
    float target=value;if(relative){if(operation=="sx")target+=uv_x;if(operation=="sy")target+=uv_y;}
    if((operation=="sx" || operation=="sy") && fabs(target)<0.001){memfree(points);strunzone(info.shadername);return FALSE;}
    float angle=(relative?value:value-uv_z)*M_PI/180;
    vector ds=[sa_x*cos(angle)+sa_y*sin(angle),sa_y*cos(angle)-sa_x*sin(angle),0]-sa;
    vector dt=[ta_x*cos(angle)+ta_y*sin(angle),ta_y*cos(angle)-ta_x*sin(angle),0]-ta;
    for(int p=0;p<count;p++) {
        if(operation=="sx")points[p].s=bias_x+(points[p].s-bias_x)*uv_x/target;
        if(operation=="sy")points[p].t=bias_y+(points[p].t-bias_y)*uv_y/target;
        if(operation=="ox")points[p].s+=relative?value:value-bias_x;
        if(operation=="oy")points[p].t+=relative?value:value-bias_y;
        if(operation=="angle") {
            vector parameter=[(float)(p%info.cpwidth)/(info.cpwidth-1),(float)(p/info.cpwidth)/(info.cpheight-1),0];
            points[p].s+=ds*parameter;points[p].t+=dt*parameter;
        }
    }
    int result=patch_history_edit(model,id,points,info);memfree(points);strunzone(info.shadername);return result!=0;
}
