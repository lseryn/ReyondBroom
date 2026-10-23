// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Convex half-space bevel adapted from ReyondBroom's BrushBevel.
typedef struct {vector anchor,normal;float offset;int material;} fb_bevel_cut_t;
fb_bevel_cut_t fb_bevel_cuts[4096];int fb_bevel_cut_count;
int fb_bevel_edges[256],fb_bevel_vertices[256];
int fb_bevel_add(vector anchor,vector normal,float offset,int material)
{
    if(offset>=-0.00000001)return TRUE;
    for(int i=0;i<fb_bevel_cut_count;i++)if(vlen(fb_bevel_cuts[i].normal-normal)<0.00001&&fabs((anchor-fb_bevel_cuts[i].anchor)*normal)<0.00001&&fabs(fb_bevel_cuts[i].offset-offset)<0.00001)return TRUE;
    if(fb_bevel_cut_count>=4096){fb_geom_error="Bevel is too complex; reduce segments";return FALSE;}
    fb_bevel_cut_t *cut=&fb_bevel_cuts[fb_bevel_cut_count++];cut->anchor=anchor;cut->normal=normal;cut->offset=offset;cut->material=material;return TRUE;
}
int fb_bevel_center(vector *directions,int count,vector *center)
{
    float a[12];memfill8((__variant*)a,0,sizeof(a));
    for(int d=0;d<count;d++)for(int i=0;i<3;i++){a[i*4+3]+=directions[d][i];for(int j=0;j<3;j++)a[i*4+j]+=directions[d][i]*directions[d][j];}
    for(int i=0;i<3;i++) {
        int pivot=i;for(int j=i+1;j<3;j++)if(fabs(a[j*4+i])>fabs(a[pivot*4+i]))pivot=j;
        if(fabs(a[pivot*4+i])<0.00000001)return FALSE;
        for(int j=0;j<4;j++){float temp=a[i*4+j];a[i*4+j]=a[pivot*4+j];a[pivot*4+j]=temp;}
        float divisor=a[i*4+i];for(int j=i;j<4;j++)a[i*4+j]/=divisor;
        for(int k=0;k<3;k++)if(k!=i){float factor=a[k*4+i];for(int j=i;j<4;j++)a[k*4+j]-=factor*a[i*4+j];}
    }
    *center=[a[3],a[7],a[11]];return TRUE;
}
int fb_bevel_cuts_for(fb_poly_t *poly,selbrush_t *selection)
{
    if(poly->ne>256||poly->nv>256){fb_geom_error="Bevel exceeds geometry limits";return FALSE;}
    fb_bevel_cut_count=0;memfill8((__variant*)fb_bevel_edges,0,sizeof(fb_bevel_edges));memfill8((__variant*)fb_bevel_vertices,0,sizeof(fb_bevel_vertices));
    int segments=bound(1,cvar("ftebroom_bevel_segments"),16),mode=cvar("ftebroom_bevel_mode");float profile=bound(0,cvar("ftebroom_bevel_profile"),1);
    if(mode==2||mode==1) {
        for(int h=0;h<fb_vertex_count;h++)if(fb_vertex_selected(h)) {
            vector point=fb_vertex_handles[h].point;
            if(mode==2&&fb_vertex_mode==FB_TOOL_VERTEX)for(int v=0;v<poly->nv;v++)if(vlen(point-poly->vertices[v])<FB_GEOM_MERGE)fb_bevel_vertices[v]=TRUE;
            if(mode==1&&fb_vertex_mode==FB_TOOL_EDGE)for(int e=0;e<poly->ne;e++)if(vlen(point-(poly->vertices[poly->edges[e].a]+poly->vertices[poly->edges[e].b])*0.5)<FB_GEOM_MERGE)fb_bevel_edges[e]=TRUE;
        }
    }else for(int e=0;e<poly->ne;e++) {
        fb_poly_edge_t edge=poly->edges[e];
        fb_bevel_edges[e]=selbrush_whole(selection)||(selbrush_face(selection,edge.face)!=selbrush_face(selection,edge.other));
    }
    for(int e=0;e<poly->ne;e++)if(fb_bevel_edges[e]) {
        fb_poly_edge_t edge=poly->edges[e];vector a=poly->faces[edge.face].attr.planenormal,b=poly->faces[edge.other].attr.planenormal;
        float cosine=a*b;if(cosine>1-0.000001)continue;if(cosine< -1+0.000001){fb_geom_error="Bevel edge is too narrow";return FALSE;}
        vector center=-(a+b)/(1+cosine),start=center+a,end=center+b,points[17];float angle=acos(bound(-1,cosine,1));
        for(int i=0;i<=segments;i++) {
            float t=(float)i/segments;vector normal=(a*sin((1-t)*angle)+b*sin(t*angle))/sin(angle);
            vector circular=center+normal,flat=start*(1-t)+end*t,square=start*(1-2*t);if(t>0.5)square=end*(2*t-1);
            if(profile<=0.5)points[i]=flat*(1-2*profile)+circular*2*profile;else points[i]=circular*(2-2*profile)+square*(2*profile-1);
        }
        vector axis=normalize(poly->vertices[edge.b]-poly->vertices[edge.a]);
        for(int i=0;i<segments;i++){vector n=normalize(crossproduct(points[i+1]-points[i],axis));if(n*(a+b)<0)n=-n;if(!fb_bevel_add(poly->vertices[edge.a],n,n*points[i],edge.face))return FALSE;}
    }
    for(int v=0;v<poly->nv;v++) {
        int junction=0;for(int e=0;e<poly->ne;e++)if(fb_bevel_edges[e]&&(poly->edges[e].a==v||poly->edges[e].b==v))junction++;
        if(!fb_bevel_vertices[v]&&junction<2)continue;
        vector vertex=poly->vertices[v],directions[64],normals[64],average='0 0 0';int nd=0,nn=0,material=0;
        for(int f=0;f<poly->nf;f++)if(fabs(vertex*poly->faces[f].attr.planenormal-poly->faces[f].attr.planedist)<0.001){normals[nn++]=poly->faces[f].attr.planenormal;average+=poly->faces[f].attr.planenormal;material=f;}
        if(!fb_bevel_vertices[v])for(int i=0;i<nn;i++)directions[nd++]=-normals[i];
        else for(int e=0;e<poly->ne;e++){fb_poly_edge_t edge=poly->edges[e];if(edge.a==v)directions[nd++]=normalize(poly->vertices[edge.b]-vertex);else if(edge.b==v)directions[nd++]=normalize(poly->vertices[edge.a]-vertex);}
        vector center;if(!fb_bevel_center(directions,nd,&center)){fb_geom_error="Unstable bevel corner";return FALSE;}
        float radius=0;for(int i=0;i<nd;i++)radius=max(radius,vlen(center-directions[i]*(center*directions[i])));if(!fb_bevel_vertices[v])radius=1;
        if(radius<0.000001)return FALSE;average=normalize(average);
        for(int i=0;i<nn;i++)for(int j=i+1;j<nn;j++)for(int k=j+1;k<nn;k++)for(int u=0;u<=segments;u++)for(int w=0;w<=segments-u;w++) {
            if(!fb_bevel_vertices[v]&&(u==0||w==0||u+w==segments)&&segments>1)continue;
            vector n=normalize(normals[i]*u+normals[j]*w+normals[k]*(segments-u-w));
            if(segments==1)n=average;
            float spread=min(1,2*profile);n=normalize(average*(1-spread)+n*spread);
            float offset=(n*center+radius)/radius;if(profile>0.5)offset*=2-2*profile;
            if(!fb_bevel_add(vertex,n,offset,material))return FALSE;
        }
    }
    if(!fb_bevel_cut_count){fb_geom_error="Select face boundaries, edges or vertices to bevel";return FALSE;}return TRUE;
}
int fb_bevel_survives(fb_poly_t *source,float size)
{
    for(int e=0;e<source->ne;e++)if(!fb_bevel_edges[e]) {
        vector a=source->vertices[source->edges[e].a],b=source->vertices[source->edges[e].b];float lo=0,hi=1;
        for(int i=0;i<fb_bevel_cut_count;i++){fb_bevel_cut_t c=fb_bevel_cuts[i];float da=(a-c.anchor)*c.normal-c.offset*size,db=(b-c.anchor)*c.normal-c.offset*size;if(da>0&&db>0)return FALSE;if(da>0)lo=max(lo,da/(da-db));if(db>0)hi=min(hi,da/(da-db));}
        if((hi-lo)*vlen(b-a)<0.05)return FALSE;
    }
    for(int f=0;f<source->nf;f++) {
        vector polygon[256],clipped[256];int count=source->faces[f].count;
        for(int p=0;p<count;p++)polygon[p]=source->vertices[source->indices[source->faces[f].start+p]];
        for(int i=0;i<fb_bevel_cut_count;i++) {
            fb_bevel_cut_t c=fb_bevel_cuts[i];int output=0;
            for(int p=0;p<count;p++){vector a=polygon[p],b=polygon[p+1==count?0:p+1];float da=(a-c.anchor)*c.normal-c.offset*size,db=(b-c.anchor)*c.normal-c.offset*size;if(output>252)return FALSE;if(da<=0)clipped[output++]=a;if((da<0&&db>0)||(da>0&&db<0))clipped[output++]=a+(b-a)*(da/(da-db));}
            count=output;if(count<3)return FALSE;memcpy(polygon,clipped,count*sizeof(vector));
        }
        vector area='0 0 0';for(int p=1;p+1<count;p++)area+=crossproduct(polygon[p]-polygon[0],polygon[p+1]-polygon[0]);if(vlen(area)<0.0025)return FALSE;
    }
    return TRUE;
}
int fb_bevel_apply()
{
    if(!selectedbrushcount){fb_geom_error="Select brushes first";return FALSE;}
    int total=selectedbrushcount;selbrush_t *selection=memalloc(total*sizeof(selbrush_t));memcpy(selection,selectedbrushes,total*sizeof(selbrush_t));int valid=TRUE;
    for(int b=0;b<total&&valid;b++) {
        fb_poly_t source={0},result={0};valid=fb_poly_from_brush(selection[b].model,selection[b].id,&source);
        if(valid)valid=fb_bevel_cuts_for(&source,&selection[b]);float size=max(0.001,cvar("ftebroom_bevel_radius"));
        if(valid&&!fb_bevel_survives(&source,size)) {
            if(!cvar("ftebroom_bevel_clamp")){valid=FALSE;fb_geom_error="Bevel overlaps; reduce radius or enable Clamp";}
            else {float lo=0,hi=size;for(int i=0;i<24;i++){float middle=(lo+hi)*0.5;if(fb_bevel_survives(&source,middle))lo=middle;else hi=middle;}size=lo*0.99;if(size<0.001){valid=FALSE;fb_geom_error="No room for bevel";}}
        }
        if(valid)valid=fb_csg_copy(&source,&result);
        for(int i=0;i<fb_bevel_cut_count&&valid;i++) {
            fb_bevel_cut_t cut=fb_bevel_cuts[i];brushface_t plane=source.faces[cut.material].attr;plane.planenormal=cut.normal;plane.planedist=cut.anchor*cut.normal+cut.offset*size;
            fb_poly_t front={0},back={0};valid=fb_csg_split(&result,plane,&front,&back);fb_poly_free(&front);fb_poly_free(&result);result=back;
            if(!result.nf)valid=FALSE;
        }
        if(valid){static brushface_t faces[64],attributes[64];for(int f=0;f<source.nf;f++)attributes[f]=source.faces[f].attr;fb_land_attributes(&result,attributes,source.nf);for(int f=0;f<result.nf;f++)faces[f]=result.faces[f].attr;int contents;brush_get(selection[b].model,selection[b].id,__NULL__,0,&contents);valid=brush_history_edit(selection[b].model,selection[b].id,faces,result.nf,contents)!=0;}
        fb_poly_free(&result);fb_poly_free(&source);
    }
    memfree(selection);return valid;
}
int fb_bevel_command()
{
    if(argv(0)!="ftebroom_bevel")return FALSE;
    fb_tx_begin("Bevel");if(fb_bevel_apply())fb_tx_commit();else {fb_tx_cancel();cvar_set("ftebroom_selection_status",fb_geom_error);}fb_vertex_rebuild();return TRUE;
}
