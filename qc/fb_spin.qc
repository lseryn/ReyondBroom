// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Segmented face extrusion using UltimateTrenchBroom's flexible path interpolation.
vector fb_spin_section(vector point,vector center,vector normal,vector delta,vector rotation,float flex,float endScale,float t)
{
    vector control=normal*vlen(delta)*.5;
    vector path=delta*t*(1-flex)+(control*(2*(1-t)*t)+delta*t*t)*flex;
    vector tangent=delta*(1-flex)+(control*(2-4*t)+delta*2*t)*flex;
    if(vlen(tangent)<.000001)tangent=normal;else tangent=normalize(tangent);
    float smooth=t*t*(3-2*t),angle=acos(bound(-1,normal*tangent,1))*smooth;
    vector axis=crossproduct(normal,tangent);if(vlen(axis)<.000001){axis=crossproduct(normal,'0 0 1');if(vlen(axis)<.000001)axis=crossproduct(normal,'1 0 0');}
    vector offset=(point-center)*(1+(endScale-1)*t);offset=fb_affine_rotate_axis(offset,normalize(axis),angle);
    offset=fb_affine_rotate_axis(offset,'0 0 1',rotation_z*smooth*M_PI/180);
    offset=fb_affine_rotate_axis(offset,'0 1 0',rotation_y*smooth*M_PI/180);
    offset=fb_affine_rotate_axis(offset,'1 0 0',rotation_x*smooth*M_PI/180);
    return center+path+offset;
}
int fb_spin_prism(vector *points,int count,fb_poly_t *piece)
{
    if(count>62)return FALSE;
    vector center='0 0 0';for(int p=0;p<count*2;p++)center+=points[p];center/=(float)(count*2);
    static brushface_t planes[64];
    for(int f=0;f<count+2;f++) {
        int a=0,b=1,c=2;
        if(f==1){a=count;b=count+1;c=count+2;}
        else if(f>=2){a=f-2;b=a+1;if(b==count)b=0;c=b+count;}
        vector normal=crossproduct(points[b]-points[a],points[c]-points[a]);if(vlen(normal)<.00001)return FALSE;normal=normalize(normal);if(normal*(center-points[a])>0)normal=-normal;
        brushface_t attr={0};attr.planenormal=normal;attr.planedist=normal*points[a];attr.shadername=cvar_string("ca_newbrushtexture");reset_texturecoords(&attr);planes[f]=attr;
    }
    return fb_poly_from_faces(planes,count+2,piece);
}
int fb_spin_apply()
{
    int total=selectedbrushcount,segments=bound(1,cvar("ftebroom_spin_segments"),64);
    if(!total||total>32){fb_geom_error="Select faces on 1..32 brushes";return FALSE;}
    selbrush_t *selection=memalloc(total*sizeof(selbrush_t));memcpy(selection,selectedbrushes,total*sizeof(selbrush_t));
    fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));int valid=TRUE;
    vector center='0 0 0',normal='0 0 0';int corners=0;
    for(int b=0;b<total&&valid;b++){if(selbrush_whole(&selection[b])){valid=FALSE;fb_geom_error="Shift-click the faces to extrude";break;}
        fb_poly_t poly={0};valid=fb_poly_from_brush(selection[b].model,selection[b].id,&poly);
        if(valid)for(int f=0;f<poly.nf;f++)if(selbrush_face(&selection[b],f)){normal+=poly.faces[f].attr.planenormal;for(int p=0;p<poly.faces[f].count;p++){center+=poly.vertices[poly.indices[poly.faces[f].start+p]];corners++;}}
        fb_poly_free(&poly);
    }
    if(!corners||vlen(normal)<.00001){valid=FALSE;fb_geom_error="Selected faces must have a nonzero common direction";}else{center/=(float)corners;normal=normalize(normal);}
    vector delta=[cvar("ftebroom_spin_x"),cvar("ftebroom_spin_y"),cvar("ftebroom_spin_z")];
    if(cvar("ftebroom_spin_auto"))delta=normal*fb_grid()*segments;
    vector rotation=[cvar("ftebroom_spin_rx"),cvar("ftebroom_spin_ry"),cvar("ftebroom_spin_rz")];
    float flex=bound(-1,cvar("ftebroom_spin_flex"),1),scale=bound(.05,cvar("ftebroom_spin_scale"),8);
    if(vlen(delta)<.01){valid=FALSE;fb_geom_error="Move the extrusion endpoint away from the source";}
    for(int b=0;b<total&&valid;b++) {
        int model=selection[b].model,id=selection[b].id,contents;fb_poly_t source={0};valid=fb_poly_from_brush(model,id,&source);if(!valid)break;brush_get(model,id,__NULL__,0,&contents);
        static brushface_t attrs[64];for(int f=0;f<source.nf;f++)attrs[f]=source.faces[f].attr;
        for(int f=0;f<source.nf&&valid;f++)if(selbrush_face(&selection[b],f)) {
            fb_poly_face_t face=source.faces[f];if(face.count>64||fb_csg_count+segments>512){valid=FALSE;fb_geom_error="Spin exceeds 64 corners or 512 pieces";break;}
            for(int segment=0;segment<segments&&valid;segment++) {
                vector points[128];for(int p=0;p<face.count;p++){vector point=source.vertices[source.indices[face.start+p]];points[p]=fb_spin_section(point,center,normal,delta,rotation,flex,scale,(float)segment/segments);points[p+face.count]=fb_spin_section(point,center,normal,delta,rotation,flex,scale,(float)(segment+1)/segments);}
                fb_poly_t piece={0};valid=fb_spin_prism(points,face.count,&piece);if(!valid)valid=fb_hull(points,face.count*2,&piece);if(valid){fb_land_attributes(&piece,attrs,source.nf);fb_csg_materials(&piece,attrs,source.nf);valid=fb_csg_append(&piece,model,contents);}fb_poly_free(&piece);
            }
        }
        fb_poly_free(&source);
    }
    if(valid){brush_deselectall();for(int i=0;i<fb_csg_count&&valid;i++){fb_csg_item_t *item=&fb_csg_results[i];static brushface_t faces[64];for(int f=0;f<item->poly.nf;f++)faces[f]=item->poly.faces[f].attr;valid=brush_history_create(item->model,faces,item->poly.nf,item->contents,TRUE)!=0;}}
    fb_csg_clear();memfree(selection);return valid;
}
