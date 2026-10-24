// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Brush subdivision in a world or projected texture basis.
int fb_subdivision_apply()
{
    int total=selectedbrushcount;
    if(total<1||total>64){fb_geom_error="Select 1..64 convex brushes";return FALSE;}
    int segments[2];segments[0]=bound(1,cvar("ftebroom_subdivide_u"),64);segments[1]=bound(1,cvar("ftebroom_subdivide_v"),64);
    int plane=bound(0,cvar("ftebroom_subdivide_plane"),2),texture=cvar("ftebroom_subdivide_texture"),grid=cvar("ftebroom_subdivide_grid");
    float cell=cvar("ftebroom_subdivide_cell");if(grid&&cell<.125){fb_geom_error="Cell size must be at least 0.125";return FALSE;}
    selbrush_t *selected=memalloc(total*sizeof(selbrush_t));memcpy(selected,selectedbrushes,total*sizeof(selbrush_t));
    fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));int valid=TRUE;
    for(int b=0;b<total&&valid;b++) {
        int model=selected[b].model,id=selected[b].id,contents;fb_poly_t source={0};valid=fb_poly_from_brush(model,id,&source);if(!valid)break;brush_get(model,id,__NULL__,0,&contents);
        int face=-1;
        if(!selbrush_whole(&selected[b]))for(int f=0;f<source.nf;f++)if(selbrush_face(&selected[b],f)){face=f;break;}
        vector basis[2];basis[0]=plane==2?'0 1 0':'1 0 0';basis[1]=plane==0?'0 1 0':'0 0 1';float origin[2],step[2];origin[0]=origin[1]=0;step[0]=step[1]=cell;
        if(grid){
            basis[0]=fb_grid_direction_world(basis[0]);basis[1]=fb_grid_direction_world(basis[1]);
            if(face>=0){
                vector axes[3];axes[0]=fb_grid_direction_world('1 0 0');axes[1]=fb_grid_direction_world('0 1 0');axes[2]='0 0 1';vector normal=source.faces[face].attr.planenormal;
                for(int i=0;i<2;i++)for(int j=i+1;j<3;j++)if(fabs(axes[j]*normal)<fabs(axes[i]*normal)){vector swap=axes[i];axes[i]=axes[j];axes[j]=swap;}
                basis[0]=axes[0];basis[1]=axes[1];
            }
        }else if(face>=0){
            fb_poly_face_t *boundary=&source.faces[face];float longest=0;vector edge='0 0 0';
            for(int i=0;i<boundary->count;i++){int next=(i+1i)%boundary->count;vector delta=source.vertices[source.indices[boundary->start+next]]-source.vertices[source.indices[boundary->start+i]];float length=delta*delta;if(length>longest){longest=length;edge=delta;}}
            if(longest<.00001){valid=FALSE;fb_geom_error="Selected face has no usable edge";}
            else{basis[0]=normalize(edge);basis[1]=normalize(crossproduct(boundary->attr.planenormal,basis[0]));}
        }
        if(texture){
            if(face<0){vector preferred=crossproduct(basis[0],basis[1]);float best=-2;for(int f=0;f<source.nf;f++){float alignment=source.faces[f].attr.planenormal*preferred;if(alignment>best){best=alignment;face=f;}}}
            if(face<0){valid=FALSE;fb_geom_error="No face available for texture alignment";}
            else{brushface_t attr=source.faces[face].attr;vector raw[2];raw[0]=attr.sdir;raw[1]=attr.tdir;float bias[2];bias[0]=attr.sbias;bias[1]=attr.tbias;
                for(int a=0;a<2;a++){basis[a]=raw[a]-attr.planenormal*(raw[a]*attr.planenormal);float length=vlen(basis[a]);if(length<.00001){valid=FALSE;fb_geom_error="Degenerate texture coordinates";break;}basis[a]/=length;step[a]=cell/length;origin[a]=-(bias[a]+raw[a]*attr.planenormal*attr.planedist)/length;}
                if(vlen(crossproduct(basis[0],basis[1]))<.00001){valid=FALSE;fb_geom_error="Parallel texture coordinates";}
            }
        }
        float low[2],high[2];int cuts[2];
        for(int a=0;a<2;a++) {low[a]=1000000;high[a]=-1000000;for(int v=0;v<source.nv;v++){float d=source.vertices[v]*basis[a];low[a]=min(low[a],d);high[a]=max(high[a],d);}
            cuts[a]=segments[a]-1;if(grid)cuts[a]=max(0,ceil((high[a]-origin[a])/step[a])-floor((low[a]-origin[a])/step[a])-1);
        }
        if((cuts[0]+1)*(cuts[1]+1)+fb_csg_count>512){valid=FALSE;fb_geom_error="Subdivision exceeds 512 pieces; increase cell size or reduce segments";}
        int begin=fb_csg_count;fb_poly_t copy={0};if(valid){valid=fb_csg_copy(&source,&copy);if(valid)valid=fb_csg_append(&copy,model,contents);}fb_poly_free(&copy);
        for(int a=0;a<2&&valid;a++)for(int c=0;c<cuts[a]&&valid;c++) {
            float distance=grid?origin[a]+(floor((low[a]-origin[a])/step[a])+c+1)*step[a]:low[a]+(high[a]-low[a])*(c+1)/(float)segments[a];
            if(distance<=low[a]+.01||distance>=high[a]-.01)continue;
            int end=fb_csg_count;
            for(int part=begin;part<end&&valid;part++) {
                fb_poly_t *current=&fb_csg_results[part].poly;brushface_t cut=source.faces[0].attr;cut.planenormal=basis[a];cut.planedist=distance;
                fb_poly_t front={0},back={0};valid=fb_csg_split(current,cut,&front,&back);
                if(valid){fb_poly_free(current);if(back.nf){*current=back;memfill8((__variant*)&back,0,sizeof(back));if(front.nf)valid=fb_csg_append(&front,model,contents);}else{*current=front;memfill8((__variant*)&front,0,sizeof(front));}}
                fb_poly_free(&front);fb_poly_free(&back);
            }
        }
        if(valid){static brushface_t attrs[64];for(int f=0;f<source.nf;f++)attrs[f]=source.faces[f].attr;for(int i=begin;i<fb_csg_count;i++){fb_land_attributes(&fb_csg_results[i].poly,attrs,source.nf);fb_csg_materials(&fb_csg_results[i].poly,attrs,source.nf);}}
        fb_poly_free(&source);
    }
    if(valid){brush_deselectall();for(int i=0;i<fb_csg_count&&valid;i++){static brushface_t faces[64];fb_csg_item_t *item=&fb_csg_results[i];for(int f=0;f<item->poly.nf;f++)faces[f]=item->poly.faces[f].attr;valid=brush_history_create(item->model,faces,item->poly.nf,item->contents,TRUE)!=0;}if(valid)for(int b=0;b<total;b++)brush_history_delete(selected[b].model,selected[b].id);}
    fb_csg_clear();memfree(selected);return valid;
}
