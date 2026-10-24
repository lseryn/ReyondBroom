// SPDX-License-Identifier: GPL-2.0-or-later
// Compute the complete result before deleting selector brushes.
int fb_select_in_scope(int node)
{
    int opened=fb_selection_open_node();
    return fb_pick_allowed(node,0) && (opened<0 || fb_selection_descendant(node,opened));
}
int fb_select_axis_separates(fb_poly_t *a,fb_poly_t *b,vector axis)
{
    float length=vlen(axis);
    if(length<0.000001) return FALSE;
    axis=axis/length;
    float amin=1000000000,amax=-1000000000,bmin=1000000000,bmax=-1000000000;
    for(int i=0;i<a->nv;i++) {float p=a->vertices[i]*axis;amin=min(amin,p);amax=max(amax,p);}
    for(int j=0;j<b->nv;j++) {float p=b->vertices[j]*axis;bmin=min(bmin,p);bmax=max(bmax,p);}
    return amax<bmin-0.01 || bmax<amin-0.01;
}
int fb_select_intersects(fb_poly_t *a,fb_poly_t *b)
{
    for(int f=0;f<a->nf;f++) if(fb_select_axis_separates(a,b,a->faces[f].attr.planenormal)) return FALSE;
    for(int g=0;g<b->nf;g++) if(fb_select_axis_separates(a,b,b->faces[g].attr.planenormal)) return FALSE;
    for(int i=0;i<a->ne;i++) for(int j=0;j<b->ne;j++) {
        vector ae=a->vertices[a->edges[i].b]-a->vertices[a->edges[i].a];
        vector be=b->vertices[b->edges[j].b]-b->vertices[b->edges[j].a];
        if(fb_select_axis_separates(a,b,crossproduct(ae,be))) return FALSE;
    }
    return TRUE;
}
int fb_select_contains(fb_poly_t *selector,fb_poly_t *object,int depth)
{
    if(depth<0) {
        for(int v=0;v<object->nv;v++) for(int f=0;f<selector->nf;f++)
            if(object->vertices[v]*selector->faces[f].attr.planenormal>selector->faces[f].attr.planedist+0.01) return FALSE;
        return TRUE;
    }
    // Supporting lines of the projected convex hull are projections of its edges.
    vector normal='0 0 0';normal[depth]=1;
    for(int e=0;e<selector->ne;e++) {
        vector a=selector->vertices[selector->edges[e].a];
        vector edge=selector->vertices[selector->edges[e].b]-a;
        vector axis=crossproduct(edge,normal);
        if(vlen(axis)<0.000001) continue;
        axis=normalize(axis);
        float low=1000000000,high=-1000000000;
        for(int s=0;s<selector->nv;s++) {
            float p=selector->vertices[s]*axis;low=min(low,p);high=max(high,p);
        }
        for(int p=0;p<object->nv;p++) {
            float value=object->vertices[p]*axis;
            if(value<low-0.01 || value>high+0.01) return FALSE;
        }
    }
    return TRUE;
}
int fb_select_node_poly(int node,fb_poly_t *poly)
{
    if(fb_nodes[node].kind==FB_NODE_BRUSH)
        return fb_poly_from_brush(fb_nodes[node].model,fb_nodes[node].id,poly);
    static vector bounds[2];
    if(fb_nodes[node].kind==FB_NODE_ENTITY) {
        if(!fb_entity_bounds(fb_nodes[node].id,bounds)) return FALSE;
    } else if(brush_getfacepoints(fb_nodes[node].model,fb_nodes[node].id,0,bounds,2)!=2) return FALSE;
    // Point entities and patches participate through their editor bounds.
    static brushface_t box[6];
    for(int axis=0;axis<3;axis++) for(int side=0;side<2;side++) {
        int f=axis*2+side;box[f].planenormal='0 0 0';
        box[f].planenormal[axis]=side?1:-1;
        box[f].planedist=side?bounds[1][axis]:-bounds[0][axis];
        if(bounds[1][axis]-bounds[0][axis]<0.01) box[f].planedist+=0.01;
        box[f].shadername="";
    }
    return fb_poly_from_faces(box,6,poly);
}
int fb_select_patch_match(int node,fb_poly_t *selector,string mode,int depth)
{
    int count=patch_getmesh(fb_nodes[node].model,fb_nodes[node].id,__NULL__,0,__NULL__);
    if(count<4) return FALSE;
    patchinfo_t info;
    patchvert_t *mesh=memalloc(sizeof(patchvert_t)*count);
    patch_getmesh(fb_nodes[node].model,fb_nodes[node].id,mesh,count,&info);
    fb_poly_t object={0};
    object.vertices=memalloc(sizeof(vector)*count);object.nv=count;
    for(int p=0;p<count;p++) object.vertices[p]=mesh[p].xyz;
    int found=FALSE;
    if(mode!="touching") found=fb_select_contains(selector,&object,depth);
    else {
        static vector triangle[3];static fb_poly_face_t faces[1];static fb_poly_edge_t edges[3];
        fb_poly_t surface={0};surface.vertices=triangle;surface.nv=3;
        surface.faces=faces;surface.nf=1;surface.edges=edges;surface.ne=3;
        for(int e=0;e<3;e++) {edges[e].a=e;edges[e].b=e+1;if(e==2) edges[e].b=0;}
        for(int y=0;y<info.cpheight-1 && !found;y++) for(int x=0;x<info.cpwidth-1 && !found;x++) {
            int index=y*info.cpwidth+x;
            for(int t=0;t<2 && !found;t++) {
                triangle[0]=mesh[index].xyz;triangle[1]=mesh[index+1].xyz;triangle[2]=mesh[index+1+info.cpwidth].xyz;
                if(t) {triangle[1]=triangle[2];triangle[2]=mesh[index+info.cpwidth].xyz;}
                faces[0].attr.planenormal=crossproduct(triangle[1]-triangle[0],triangle[2]-triangle[0]);
                found=fb_select_intersects(selector,&surface);
            }
        }
    }
    memfree(object.vertices);memfree(mesh);return found;
}
void fb_select_command(string mode)
{
    if(mode!="all" && mode!="invert" && mode!="siblings" && mode!="touching" && mode!="inside" && mode!="tall") return;
    fb_tool_refresh();fb_document_tick();
    int count=fb_node_count;
    int *result=memalloc(sizeof(int)*count);
    int *old=memalloc(sizeof(int)*count);
    for(int n=0;n<count;n++) old[n]=fb_selection_selected(n);
    int volume=mode=="touching" || mode=="inside" || mode=="tall";
    int valid=TRUE;
    fb_poly_t *selectors=__NULL__;int *selectorNodes=__NULL__;int selectorCount=0;
    if(volume) {
        if(mode=="tall" && !cvar("ca_brush_view")) valid=FALSE;
        selectors=memalloc(sizeof(fb_poly_t)*selectedbrushcount);
        selectorNodes=memalloc(sizeof(int)*selectedbrushcount);
        for(int s=0;s<count;s++) if(fb_nodes[s].kind==FB_NODE_BRUSH && old[s] && fb_select_in_scope(s)) {
            if(!fb_poly_from_brush(fb_nodes[s].model,fb_nodes[s].id,&selectors[selectorCount])) {valid=FALSE;break;}
            selectorNodes[selectorCount++]=s;
        }
        if(!selectorCount) valid=FALSE;
    }
    for(int i=0;i<count && valid;i++) {
        if(!fb_selection_leaf(i) || !fb_select_in_scope(i)) continue;
        int target=fb_selection_target(i);
        if(mode=="all") result[target]=TRUE;
        else if(mode=="invert") result[target]=!old[target];
        else if(mode=="siblings") {
            for(int j=0;j<count;j++) if(old[j] && fb_select_in_scope(j))
                if(fb_nodes[fb_selection_target(j)].parent==fb_nodes[target].parent) result[target]=TRUE;
        } else if(volume) {
            int isSelector=FALSE;
            for(int k=0;k<selectorCount;k++) if(selectorNodes[k]==i) isSelector=TRUE;
            if(isSelector) continue;
            if(fb_nodes[i].kind==FB_NODE_PATCH) {
                int patchDepth=-1;if(mode=="tall") patchDepth=fb_view_depth_axis(cvar("ca_brush_view"));
                for(int k=0;k<selectorCount;k++) result[i]|=fb_select_patch_match(i,&selectors[k],mode,patchDepth);
                continue;
            }
            fb_poly_t object={0};
            if(!fb_select_node_poly(i,&object)) {valid=FALSE;break;}
            for(int k=0;k<selectorCount;k++) {
                if(mode=="touching") result[i]|=fb_select_intersects(&selectors[k],&object);
                else {
                    int depth=-1;if(mode=="tall") depth=fb_view_depth_axis(cvar("ca_brush_view"));
                    result[i]|=fb_select_contains(&selectors[k],&object,depth);
                }
            }
            fb_poly_free(&object);
        }
    }
    if(valid && volume) {
        // A closed group is selected only when all of its selectable leaves match.
        for(int g=0;g<count;g++) if(fb_nodes[g].kind==FB_NODE_GROUP && fb_selection_target(g)==g) {
            int found=FALSE,complete=TRUE;
            for(int c=0;c<count;c++) if(fb_selection_leaf(c) && fb_selection_descendant(c,g) && fb_select_in_scope(c)) {
                found=TRUE;if(!result[c]) complete=FALSE;
            }
            for(int c=0;c<count;c++) if(fb_selection_descendant(c,g)) result[c]=FALSE;
            result[g]=found && complete;
        }
    }
    if(valid) {
        fb_tx_begin(strcat("Select ",mode));fb_selection_clear();
        for(int r=0;r<count;r++) if(result[r]) fb_selection_set(r,TRUE);
        for(int d=0;d<selectorCount;d++) {
            int node=selectorNodes[d];
            brush_history_delete(fb_nodes[node].model,fb_nodes[node].id);
        }
        fb_tx_commit();
    } else print("ReyondBroom: selection needs valid convex selectors; map unchanged.\n");
    for(int k=0;k<selectorCount;k++) fb_poly_free(&selectors[k]);
    memfree(selectors);memfree(selectorNodes);memfree(result);memfree(old);
}
