// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Rebuild selected brushes independently; closed containers form conversion clusters.
// Subtract the source union from the hull before accepting a cluster, so cavities
// and disconnected pieces cannot silently become solid.
int fb_convert_brushes_apply()
{
    fb_document_tick();int total=selectedbrushcount;
    if(total<1||total>256){fb_geom_error="Select 1..256 brushes";return FALSE;}
    fb_csg_item_t *input=memalloc(total*sizeof(fb_csg_item_t));int *cluster=memalloc(total*sizeof(int));
    fb_csg_item_t *output=memalloc(total*sizeof(fb_csg_item_t));int count=0,valid=TRUE;
    for(int i=0;i<total&&valid;i++){
        input[i].model=selectedbrushes[i].model;input[i].id=selectedbrushes[i].id;cluster[i]=-i-1;
        valid=fb_poly_from_brush(input[i].model,input[i].id,&input[i].poly);brush_get(input[i].model,input[i].id,__NULL__,0,&input[i].contents);
        int node=-1;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_BRUSH&&fb_nodes[n].model==input[i].model&&fb_nodes[n].id==input[i].id){node=n;break;}
        if(node>=2)for(int n=fb_nodes[node].parent;n>=2;n=fb_nodes[n].parent){
            if(fb_nodes[n].kind!=FB_NODE_GROUP&&fb_nodes[n].kind!=FB_NODE_ENTITY)continue;
            if(fb_selection_descendant(fb_selection_open_node(),n))continue;
            if(fb_selection_selected(n))cluster[i]=n;
        }
    }
    for(int i=0;i<total&&valid;i++){
        int earlier=FALSE;for(int j=0;j<i;j++)if(cluster[j]==cluster[i])earlier=TRUE;if(earlier)continue;
        int vertices=0,attributes=0;
        for(int j=i;j<total;j++)if(cluster[j]==cluster[i]){vertices+=input[j].poly.nv;attributes+=input[j].poly.nf;}
        if(vertices>4096){valid=FALSE;fb_geom_error="Conversion exceeds 4096 vertices per cluster";break;}
        vector *points=memalloc(vertices*sizeof(vector));brushface_t *attrs=memalloc(attributes*sizeof(brushface_t));int nv=0,nf=0;
        for(int j=i;j<total;j++)if(cluster[j]==cluster[i]){
            for(int v=0;v<input[j].poly.nv;v++)points[nv++]=input[j].poly.vertices[v];
            for(int f=0;f<input[j].poly.nf;f++)attrs[nf++]=input[j].poly.faces[f].attr;
        }
        fb_csg_item_t *result=&output[count];valid=fb_hull(points,nv,&result->poly);memfree(points);
        if(valid){fb_land_attributes(&result->poly,attrs,nf);fb_csg_materials(&result->poly,attrs,nf);}
        memfree(attrs);if(!valid)break;
        result->model=input[i].model;result->contents=input[i].contents;
        if(cluster[i]>=2)result->model=fb_organize_model(fb_nodes[cluster[i]].id);
        if(!result->model){valid=FALSE;break;}
        fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));fb_poly_t remaining={0};valid=fb_csg_copy(&result->poly,&remaining);
        if(valid)valid=fb_csg_append(&remaining,result->model,result->contents);fb_poly_free(&remaining);
        for(int j=i;j<total&&valid&&fb_csg_count;j++)if(cluster[j]==cluster[i]){
            int pieces=fb_csg_count;fb_csg_item_t *previous=memalloc(pieces*sizeof(fb_csg_item_t));memcpy(previous,fb_csg_results,pieces*sizeof(fb_csg_item_t));fb_csg_count=0;
            for(int p=0;p<pieces;p++){if(valid)valid=fb_csg_difference(&previous[p].poly,&input[j].poly,result->model,result->contents);fb_poly_free(&previous[p].poly);}memfree(previous);
        }
        float missing=0;for(int p=0;p<fb_csg_count;p++)missing+=fb_csg_results[p].poly.volume;
        if(missing>max(.01,result->poly.volume*.000001)){valid=FALSE;fb_geom_error="Cluster is not convex; conversion would fill empty space. Open the group and select individual brushes instead.";}
        fb_csg_clear();count++;
    }
    if(valid){
        brush_deselectall();
        for(int i=0;i<count&&valid;i++){static brushface_t faces[64];for(int f=0;f<output[i].poly.nf;f++)faces[f]=output[i].poly.faces[f].attr;valid=brush_history_create(output[i].model,faces,output[i].poly.nf,output[i].contents,TRUE)!=0;}
        if(valid)for(int i=0;i<total;i++)brush_history_delete(input[i].model,input[i].id);
    }
    for(int i=0;i<total;i++){fb_poly_free(&input[i].poly);fb_poly_free(&output[i].poly);}memfree(input);memfree(output);memfree(cluster);return valid;
}
