// SPDX-License-Identifier: GPL-2.0-or-later
// Results own their geometry until the entire operation has been validated.
typedef struct {fb_poly_t poly;int model,id,contents;} fb_csg_item_t;
fb_csg_item_t *fb_csg_results;
int fb_csg_count;
void fb_csg_clear()
{
    for(int i=0;i<fb_csg_count;i++) fb_poly_free(&fb_csg_results[i].poly);
    memfree(fb_csg_results);fb_csg_results=__NULL__;fb_csg_count=0;
}
int fb_csg_append(fb_poly_t *poly,int model,int contents)
{
    if(fb_csg_count>=2048) {fb_geom_error="CSG exceeds 2048 result brushes";return FALSE;}
    fb_csg_item_t *item=&fb_csg_results[fb_csg_count++];
    item->poly=*poly;memfill8((__variant*)poly,0,sizeof(fb_poly_t));
    item->model=model;item->contents=contents;return TRUE;
}
int fb_csg_copy(fb_poly_t *source,fb_poly_t *target)
{
    static brushface_t faces[64];
    for(int f=0;f<source->nf;f++) faces[f]=source->faces[f].attr;
    return fb_poly_from_faces(faces,source->nf,target);
}
// Split also accepts planes outside the volume. Empty outputs are successful.
int fb_csg_split(fb_poly_t *source,brushface_t plane,fb_poly_t *front,fb_poly_t *back)
{
    float lo=1000000,hi=-1000000;
    for(int v=0;v<source->nv;v++) {
        float side=source->vertices[v]*plane.planenormal-plane.planedist;
        lo=min(lo,side);hi=max(hi,side);
    }
    if(hi<=FB_GEOM_PLANE) return fb_csg_copy(source,back);
    if(lo>=-FB_GEOM_PLANE) return fb_csg_copy(source,front);
    static brushface_t faces[64];
    for(int f=0;f<source->nf;f++) faces[f]=source->faces[f].attr;
    return fb_split(faces,source->nf,plane.planenormal,plane.planedist,front,back);
}
// Apply the common CSG material rule after topology generation.
void fb_csg_materials(fb_poly_t *poly,brushface_t *source,int count)
{
    for(int f=0;f<poly->nf;f++) {
        brushface_t *face=&poly->faces[f].attr;
        for(int s=0;s<count;s++) if(fb_geom_sameplane(face,&source[s])) {
            strunzone(face->shadername);*face=source[s];face->shadername=strzone(source[s].shadername);break;
        }
    }
}
int fb_csg_difference(fb_poly_t *source,fb_poly_t *cutter,int model,int contents)
{
    // A separating cutter plane leaves the source intact, without unnecessary splits.
    for(int p=0;p<cutter->nf;p++) {
        brushface_t plane=cutter->faces[p].attr;float nearest=1000000;
        for(int v=0;v<source->nv;v++) nearest=min(nearest,source->vertices[v]*plane.planenormal-plane.planedist);
        if(nearest>=-FB_GEOM_PLANE) {
            fb_poly_t copy={0};int valid=fb_csg_copy(source,&copy);
            if(valid) valid=fb_csg_append(&copy,model,contents);fb_poly_free(&copy);return valid;
        }
    }
    fb_poly_t rest={0};if(!fb_csg_copy(source,&rest)) return FALSE;
    for(int p=0;p<cutter->nf && rest.nf;p++) {
        fb_poly_t front={0},back={0};
        int ok=fb_csg_split(&rest,cutter->faces[p].attr,&front,&back);fb_poly_free(&rest);
        if(!ok) {fb_poly_free(&front);fb_poly_free(&back);return FALSE;}
        if(front.nf) if(!fb_csg_append(&front,model,contents)) {fb_poly_free(&front);fb_poly_free(&back);return FALSE;}
        rest=back;
    }
    fb_poly_free(&rest);return TRUE;
}
void fb_csg(string operation)
{
    if(operation!="merge" && operation!="intersect" && operation!="hollow" && operation!="subtract") return;
    if(operation=="merge" && fb_vertex_tool()) {fb_vertex_merge();return;}
    fb_tool_refresh();fb_document_tick();
    int total=selectedbrushcount;
    if(total<1 || ((operation=="merge" || operation=="intersect") && total<2)) return;
    fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));
    fb_csg_item_t *inputs=memalloc(total*sizeof(fb_csg_item_t));
    brushface_t *attributes=memalloc(total*64*sizeof(brushface_t));int na=0,ok=TRUE;
    int *remove=memalloc(fb_node_count*sizeof(int));memfill8((__variant*)remove,0,fb_node_count*sizeof(int));
    for(int i=0;i<total;i++) {
        fb_csg_item_t *item=&inputs[i];item->model=selectedbrushes[i].model;item->id=selectedbrushes[i].id;
        if(!fb_poly_from_brush(item->model,item->id,&item->poly)) {ok=FALSE;break;}
        brush_get(item->model,item->id,__NULL__,0,&item->contents);
        for(int f=0;f<item->poly.nf;f++) attributes[na++]=item->poly.faces[f].attr;
        for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_BRUSH && fb_nodes[n].model==item->model && fb_nodes[n].id==item->id) remove[n]=TRUE;
    }
    if(ok && operation=="merge") {
        int count=0;for(int i=0;i<total;i++) count+=inputs[i].poly.nv;
        vector *points=memalloc(count*sizeof(vector));count=0;
        for(int i=0;i<total;i++) for(int v=0;v<inputs[i].poly.nv;v++) points[count++]=inputs[i].poly.vertices[v];
        fb_poly_t hull={0};ok=fb_hull(points,count,&hull);memfree(points);
        if(ok) {fb_csg_materials(&hull,attributes,na);ok=fb_csg_append(&hull,inputs[0].model,inputs[0].contents);}
        fb_poly_free(&hull);
    }
    if(ok && operation=="intersect") {
        fb_poly_t rest={0};ok=fb_csg_copy(&inputs[0].poly,&rest);
        for(int i=1;i<total && ok && rest.nf;i++) for(int p=0;p<inputs[i].poly.nf && ok && rest.nf;p++) {
            fb_poly_t front={0},back={0};ok=fb_csg_split(&rest,inputs[i].poly.faces[p].attr,&front,&back);
            fb_poly_free(&front);fb_poly_free(&rest);rest=back;
        }
        if(ok && !rest.nf) {ok=FALSE;fb_geom_error="Empty intersection";}
        if(ok) {fb_csg_materials(&rest,attributes,na);ok=fb_csg_append(&rest,inputs[0].model,inputs[0].contents);}
        fb_poly_free(&rest);
    }
    if(ok && operation=="hollow") for(int i=0;i<total && ok;i++) {
        static brushface_t inset[64];fb_csg_item_t *item=&inputs[i];
        for(int f=0;f<item->poly.nf;f++) {inset[f]=item->poly.faces[f].attr;inset[f].planedist-=cvar("ca_grid");}
        fb_poly_t inner={0};
        if(!fb_poly_from_faces(inset,item->poly.nf,&inner)) {
            print("FTEBroom: Hollow skipped a brush too thin for the current grid.\n");
            for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].model==item->model && fb_nodes[n].id==item->id) remove[n]=FALSE;
            continue;
        }
        ok=fb_csg_difference(&item->poly,&inner,item->model,item->contents);fb_poly_free(&inner);
    }
    if(ok && operation=="subtract") for(int n=0;n<fb_node_count && ok;n++) {
        if(remove[n] || fb_nodes[n].kind!=FB_NODE_BRUSH || !fb_pick_allowed(n,0)) continue;
        fb_poly_t original={0};int model=fb_nodes[n].model,id=fb_nodes[n].id,contents;
        if(!fb_poly_from_brush(model,id,&original)) {ok=FALSE;break;}
        brush_get(model,id,__NULL__,0,&contents);
        float originalVolume=original.volume;
        int begin=fb_csg_count;ok=fb_csg_append(&original,model,contents);fb_poly_free(&original);
        for(int c=0;c<total && ok;c++) {
            int end=fb_csg_count;
            // Move the previous generation aside so appending cannot invalidate it.
            int size=end-begin;fb_csg_item_t *previous=memalloc(size*sizeof(fb_csg_item_t));
            memcpy(previous,&fb_csg_results[begin],size*sizeof(fb_csg_item_t));fb_csg_count=begin;
            for(int part=0;part<size;part++) {
                if(ok) ok=fb_csg_difference(&previous[part].poly,&inputs[c].poly,model,contents);
                fb_poly_free(&previous[part].poly);
            }
            memfree(previous);
        }
        if(ok) {
            float volume=0;for(int part=begin;part<fb_csg_count;part++) volume+=fb_csg_results[part].poly.volume;
            if(fabs(volume-originalVolume)<=max(0.01,originalVolume*0.000001)) {
                for(int part=begin;part<fb_csg_count;part++) fb_poly_free(&fb_csg_results[part].poly);
                fb_csg_count=begin;
            } else remove[n]=TRUE;
        }
    }
    if(ok) for(int r=0;r<fb_csg_count;r++) fb_csg_materials(&fb_csg_results[r].poly,attributes,na);
    if(ok) {
        fb_tx_begin(strcat("CSG ",operation));brush_deselectall();fb_restore_entity_selection(-1);
        for(int n=0;n<fb_node_count;n++) if(remove[n]) brush_history_delete(fb_nodes[n].model,fb_nodes[n].id);
        for(int r=0;r<fb_csg_count;r++) {
            static brushface_t result[64];fb_csg_item_t *item=&fb_csg_results[r];
            for(int f=0;f<item->poly.nf;f++) result[f]=item->poly.faces[f].attr;
            if(!brush_history_create(item->model,result,item->poly.nf,item->contents,TRUE)) {ok=FALSE;break;}
        }
        if(ok) {fb_organize_cleanup();fb_tx_commit();}else fb_tx_cancel();
    }
    if(!ok) print(strcat("FTEBroom: CSG cancelled: ",fb_geom_error,"\n"));
    for(int i=0;i<total;i++) fb_poly_free(&inputs[i].poly);
    memfree(inputs);memfree(attributes);memfree(remove);fb_csg_clear();
}
