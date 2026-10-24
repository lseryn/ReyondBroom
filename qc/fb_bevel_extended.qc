// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Edge profiles follow UltimateTrenchBroom's EdgeTool. CSG output stays convex.
void fb_bevel_edge_profile(fb_poly_t *source,int index,float width,int segments,float curve,float proportion,vector *points)
{
    fb_poly_edge_t edge=source->edges[index];vector anchor=source->vertices[edge.a],axis=normalize(source->vertices[edge.b]-anchor);
    vector a=source->faces[edge.face].attr.planenormal,b=source->faces[edge.other].attr.planenormal;
    vector ta=normalize(crossproduct(axis,a)),tb=normalize(crossproduct(axis,b));if(ta*b>0)ta=-ta;if(tb*a>0)tb=-tb;
    vector first=anchor+ta*width*(1-proportion),last=anchor+tb*width*(1+proportion),middle=(first+last)*.5,bulge=normalize(anchor-middle);
    float cosine=bound(-.999999,a*b,.999999),denominator=cosine*cosine-1,angle=acos(cosine);
    vector delta=first-last;float rhsA=delta*a,rhsB=delta*b,radiusB=(rhsB-cosine*rhsA)/denominator,radiusA=rhsA+cosine*radiusB;
    vector center=(first-a*radiusA+last-b*radiusB)*.5;float radius=(radiusA+radiusB)*.5;
    for(int i=0;i<=segments;i++){
        float t=(float)i/segments;vector point=first*(1-t)+last*t;
        if(curve>=.999){
            if(radiusA>.001&&radiusB>.001)point=center+normalize(a*sin((1-t)*angle)+b*sin(t*angle))*radius;
            else point+=normalize(a+b)*sin(M_PI*t)*width*.25;
        }else point+=bulge*sin(M_PI*t)*width*.5*curve;
        points[i]=point;
    }
}
float fb_bevel_edge_limit(fb_poly_t *source,int index,float proportion)
{
    fb_poly_edge_t edge=source->edges[index];vector anchor=source->vertices[edge.a],axis=normalize(source->vertices[edge.b]-anchor);float limit=1000000;
    for(int side=0;side<2;side++){
        int face=side?edge.other:edge.face,other=side?edge.face:edge.other;vector normal=source->faces[face].attr.planenormal,tangent=normalize(crossproduct(axis,normal));if(tangent*source->faces[other].attr.planenormal>0)tangent=-tangent;
        float extent=0;for(int v=0;v<source->faces[face].count;v++)extent=max(extent,(source->vertices[source->indices[source->faces[face].start+v]]-anchor)*tangent);
        int neighbours=0;for(int e=0;e<source->ne;e++)if(e!=index&&fb_bevel_edges[e]&&(source->edges[e].face==face||source->edges[e].other==face))neighbours++;
        limit=min(limit,extent*(neighbours?.49:.98)/(side?1+proportion:1-proportion));
    }return limit;
}
int fb_bevel_remove_piece(fb_poly_t *source,fb_poly_t *cutter,int model,int contents,fb_csg_item_t *offcuts,int *cutCount)
{
    for(int p=0;p<cutter->nf;p++){
        float nearest=1000000;brushface_t plane=cutter->faces[p].attr;
        for(int v=0;v<source->nv;v++)nearest=min(nearest,source->vertices[v]*plane.planenormal-plane.planedist);
        if(nearest>=-FB_GEOM_PLANE){fb_poly_t untouched={0};if(!fb_csg_copy(source,&untouched))return FALSE;int appended=fb_csg_append(&untouched,model,contents);fb_poly_free(&untouched);return appended;}
    }
    fb_poly_t rest={0};if(!fb_csg_copy(source,&rest))return FALSE;
    for(int p=0;p<cutter->nf&&rest.nf;p++){
        fb_poly_t front={0},back={0};int valid=fb_csg_split(&rest,cutter->faces[p].attr,&front,&back);fb_poly_free(&rest);
        if(valid&&front.nf)valid=fb_csg_append(&front,model,contents);fb_poly_free(&front);
        if(!valid){fb_poly_free(&back);return FALSE;}rest=back;
    }
    if(offcuts&&rest.nf){if(*cutCount>=2048){fb_poly_free(&rest);fb_geom_error="Bevel exceeds 2048 offcuts";return FALSE;}offcuts[*cutCount].poly=rest;(*cutCount)++;}
    else fb_poly_free(&rest);return TRUE;
}
int fb_bevel_extended_apply()
{
    int total=selectedbrushcount,segments=bound(1,cvar("ftebroom_bevel_segments"),16),keep=cvar("ftebroom_bevel_keep");
    if(total<1||total>32){fb_geom_error="Select 1..32 brushes for extended edge bevel";return FALSE;}
    if(cvar("ftebroom_bevel_mode")==2){fb_geom_error="Extended profile uses edges or face boundaries, not vertex mode";return FALSE;}
    selbrush_t *selection=memalloc(total*sizeof(selbrush_t));memcpy(selection,selectedbrushes,total*sizeof(selbrush_t));
    float curve=bound(-1,cvar("ftebroom_bevel_curve"),1),proportion=bound(-.95,cvar("ftebroom_bevel_proportion"),.95);
    int valid=TRUE,operations=0,made=0;fb_csg_clear();
    for(int b=0;b<total&&valid;b++){
        fb_poly_t source={0};int model=selection[b].model,id=selection[b].id,contents;brush_get(model,id,__NULL__,0,&contents);
        valid=fb_poly_from_brush(model,id,&source);if(valid)valid=fb_bevel_cuts_for(&source,&selection[b]);
        float width=max(.001,cvar("ftebroom_bevel_radius"));int edgeCount=0;
        for(int e=0;e<source.ne&&valid;e++)if(fb_bevel_edges[e]){edgeCount++;if(cvar("ftebroom_bevel_clamp"))width=min(width,fb_bevel_edge_limit(&source,e,proportion));}
        if(edgeCount*segments>512||!edgeCount||width<.001){valid=FALSE;fb_geom_error="No room for bevel or more than 512 edge segments";}
        fb_csg_item_t *pieces=memalloc(2048*sizeof(fb_csg_item_t));int count=0,cutCount=0;fb_csg_item_t *offcuts=__NULL__;if(keep)offcuts=memalloc(2048*sizeof(fb_csg_item_t));
        if(valid){valid=fb_csg_copy(&source,&pieces[0].poly);if(valid)count=1;}
        for(int e=0;e<source.ne&&valid;e++)if(fb_bevel_edges[e]){
            vector profile[17];fb_bevel_edge_profile(&source,e,width,segments,curve,proportion,profile);
            fb_poly_edge_t edge=source.edges[e];vector anchor=source.vertices[edge.a],axis=normalize(source.vertices[edge.b]-anchor);float margin=max(64,width*4);vector start=anchor-axis*margin,end=source.vertices[edge.b]+axis*margin;
            for(int segment=0;segment<segments&&valid;segment++){
                vector points[6];points[0]=start;points[1]=start+profile[segment]-anchor;points[2]=start+profile[segment+1]-anchor;points[3]=end;points[4]=end+profile[segment]-anchor;points[5]=end+profile[segment+1]-anchor;
                fb_poly_t cutter={0};valid=fb_hull(points,6,&cutter);fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));
                for(int i=0;i<count&&valid;i++){
                    if(++operations>10000){valid=FALSE;fb_geom_error="Bevel work limit reached; reduce segments or selection";break;}
                    valid=fb_bevel_remove_piece(&pieces[i].poly,&cutter,model,contents,offcuts,&cutCount);
                }
                for(int i=0;i<count;i++)fb_poly_free(&pieces[i].poly);memfree(pieces);pieces=fb_csg_results;count=fb_csg_count;fb_csg_results=__NULL__;fb_csg_count=0;fb_poly_free(&cutter);
            }
        }
        if(valid&&count==0){valid=FALSE;fb_geom_error="Bevel removes the entire brush; reduce width";}
        float volume=0;for(int i=0;i<count;i++)volume+=pieces[i].poly.volume;for(int i=0;i<cutCount;i++)volume+=offcuts[i].poly.volume;
        if(valid&&keep&&fabs(volume-source.volume)>max(.01,source.volume*.001)){valid=FALSE;fb_geom_error="Bevel volume check failed";}
        if(valid&&made+count+cutCount>2048){valid=FALSE;fb_geom_error="Bevel exceeds 2048 output brushes";}
        if(valid){
            static brushface_t attrs[64],faces[64];for(int f=0;f<source.nf;f++)attrs[f]=source.faces[f].attr;
            for(int i=0;i<count+cutCount&&valid;i++){
                fb_poly_t *piece;if(i<count)piece=&pieces[i].poly;else piece=&offcuts[i-count].poly;
                fb_land_attributes(piece,attrs,source.nf);fb_csg_materials(piece,attrs,source.nf);for(int f=0;f<piece->nf;f++)faces[f]=piece->faces[f].attr;
                valid=brush_history_create(model,faces,piece->nf,contents,TRUE)!=0;made++;
            }
            if(valid)brush_history_delete(model,id);
        }
        for(int i=0;i<count;i++)fb_poly_free(&pieces[i].poly);for(int i=0;i<cutCount;i++)fb_poly_free(&offcuts[i].poly);memfree(pieces);memfree(offcuts);fb_poly_free(&source);
    }
    fb_csg_clear();memfree(selection);return valid;
}
