// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Face-centred inset partition, following UltimateTrenchBroom FaceTool semantics.
int fb_polygon_intersection(fb_poly_t *source,vector *points,int count,vector normal,fb_poly_t *result)
{
    if(count<3||count>64){fb_geom_error="Polygon requires 3..64 corners";return FALSE;}
    vector center='0 0 0';for(int i=0;i<count;i++)center+=points[i];center/=(float)count;
    if(!fb_csg_copy(source,result))return FALSE;
    for(int i=0;i<count&&result->nf;i++) {
        int next=i+1;if(next==count)next=0;
        vector n=crossproduct(points[next]-points[i],normal);
        if(vlen(n)<.00001){fb_geom_error="Polygon has coincident corners";return FALSE;}
        n=normalize(n);if(n*(center-points[i])>0)n=-n;
        for(int j=0;j<count;j++)if(n*(points[j]-points[i])>FB_GEOM_PLANE){fb_geom_error="Polygon is not convex after snapping";return FALSE;}
        brushface_t plane=source->faces[0].attr;plane.planenormal=n;plane.planedist=n*points[i];
        fb_poly_t front={0},back={0};int ok=fb_csg_split(result,plane,&front,&back);fb_poly_free(&front);fb_poly_free(result);*result=back;
        if(!ok)return FALSE;
    }
    if(!result->nf){fb_geom_error="Inset region is empty";return FALSE;}return TRUE;
}
int fb_inset_apply()
{
    if(selectedbrushcount!=1||selbrush_whole(&selectedbrushes[0])){fb_geom_error="Select exactly one brush face (Shift-click)";return FALSE;}
    int model=selectedbrushes[0].model,id=selectedbrushes[0].id,contents,face=-1;
    fb_poly_t source={0};if(!fb_poly_from_brush(model,id,&source))return FALSE;
    for(int f=0;f<source.nf;f++)if(selbrush_face(&selectedbrushes[0],f)){if(face!=-1){fb_poly_free(&source);fb_geom_error="Select exactly one face";return FALSE;}face=f;}
    if(face<0){fb_poly_free(&source);fb_geom_error="No face selected";return FALSE;}
    fb_poly_face_t boundary=source.faces[face];int count=boundary.count;
    if(count>64){fb_poly_free(&source);fb_geom_error="Face exceeds 64 corners";return FALSE;}
    vector outer[64],inner[64],center='0 0 0';
    for(int i=0;i<count;i++){outer[i]=source.vertices[source.indices[boundary.start+i]];center+=outer[i];}center/=(float)count;
    float nearest=1000000;for(int i=0;i<count;i++)nearest=min(nearest,vlen(outer[i]-center));
    float amount=cvar("ftebroom_inset_amount"),scale=1-amount/nearest;
    if(amount<=0||scale<.01){fb_poly_free(&source);fb_geom_error="Inset amount must be positive and smaller than the face radius";return FALSE;}
    for(int i=0;i<count;i++){inner[i]=center+(outer[i]-center)*scale;if(cvar("ftebroom_inset_snap"))inner[i]=fb_snap_to_plane(inner[i],boundary.attr.planenormal,boundary.attr.planedist);}
    brush_get(model,id,__NULL__,0,&contents);fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));int valid=TRUE;
    for(int part=0;part<=count&&valid;part++) {
        fb_poly_t fragment={0};
        if(!part)valid=fb_polygon_intersection(&source,inner,count,boundary.attr.planenormal,&fragment);
        else {
            // Extend the border sector through the complete source volume. This also
            // preserves a brush whose back face is wider than the chosen front face.
            int i=part-1,next=i+1;if(next==count)next=0;
            vector corners[3];corners[0]=center;corners[1]=inner[i];corners[2]=inner[next];
            vector keep=(inner[i]+inner[next])*0.5+((inner[i]+inner[next])*0.5-center)*.1;
            valid=fb_csg_copy(&source,&fragment);
            for(int edge=0;edge<3&&valid;edge++) {
                int end=edge+1;if(end==3)end=0;
                brushface_t plane=boundary.attr;plane.planenormal=crossproduct(corners[end]-corners[edge],boundary.attr.planenormal);
                if(vlen(plane.planenormal)<.00001){valid=FALSE;break;}plane.planenormal=normalize(plane.planenormal);
                if(plane.planenormal*(keep-corners[edge])>0)plane.planenormal=-plane.planenormal;
                plane.planedist=plane.planenormal*corners[edge];fb_poly_t front={0},back={0};valid=fb_csg_split(&fragment,plane,&front,&back);fb_poly_free(&front);fb_poly_free(&fragment);fragment=back;
                if(!fragment.nf)valid=FALSE;
            }
        }
        if(valid)valid=fb_csg_append(&fragment,model,contents);fb_poly_free(&fragment);
    }
    float volume=0;for(int i=0;i<fb_csg_count;i++)volume+=fb_csg_results[i].poly.volume;
    if(valid&&fabs(volume-source.volume)>max(.01,source.volume*.001)){valid=FALSE;fb_geom_error="Inset projection does not cover this brush; choose another face";}
    if(valid){static brushface_t attrs[64],faces[64];for(int f=0;f<source.nf;f++)attrs[f]=source.faces[f].attr;brush_deselectall();
        for(int i=0;i<fb_csg_count&&valid;i++){fb_poly_t *piece=&fb_csg_results[i].poly;fb_land_attributes(piece,attrs,source.nf);fb_csg_materials(piece,attrs,source.nf);for(int f=0;f<piece->nf;f++)faces[f]=piece->faces[f].attr;valid=brush_history_create(model,faces,piece->nf,contents,TRUE)!=0;}
        if(valid)brush_history_delete(model,id);
    }
    fb_csg_clear();fb_poly_free(&source);return valid;
}
