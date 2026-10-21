// SPDX-License-Identifier: GPL-2.0-or-later
int fb_container_bounds(int node,vector *bounds)
{
    int found=FALSE;bounds[0]='1000000 1000000 1000000';bounds[1]=-bounds[0];static vector childBounds[2];
    for(int n=2;n<fb_node_count;n++)if(fb_selection_descendant(n,node) && fb_selection_leaf(n) && fb_pick_allowed(n,FB_PICK_LOCKED)) {
        int valid=FALSE;if(fb_nodes[n].kind==FB_NODE_ENTITY)valid=fb_entity_bounds(fb_nodes[n].id,childBounds);
        else valid=brush_getfacepoints(fb_nodes[n].model,fb_nodes[n].id,0,childBounds,2)==2;
        if(valid){found=TRUE;for(int a=0;a<3;a++){bounds[0][a]=min(bounds[0][a],childBounds[0][a]);bounds[1][a]=max(bounds[1][a],childBounds[1][a]);}}
    }
    return found;
}
void fb_container_draw(int labels)
{
    static vector bounds[2];vector camera=getproperty(VF_ORIGIN),angles=getproperty(VF_ANGLES);makevectors(angles);vector forward=v_forward;
    vector mn=getproperty(VF_MIN),size=getproperty(VF_SIZE);
    if(!labels && !cvar("ca_brush_view") && cvar("ftebroom_bounds_visible")) {
        if(tokenize(cvar_string("ftebroom_map_bounds"))==6)fb_visual_box([stof(argv(0)),stof(argv(1)),stof(argv(2))],[stof(argv(3)),stof(argv(4)),stof(argv(5))],'1 0.5 0',0.7,FALSE);
    }
    for(int n=2;n<fb_node_count;n++) {
        int group=fb_nodes[n].kind==FB_NODE_GROUP,brushEntity=fb_nodes[n].kind==FB_NODE_ENTITY && !fb_selection_leaf(n);
        if(group && !cvar("ftebroom_show_group_bounds"))continue;if(brushEntity && !cvar("ftebroom_show_brush_entity_bounds"))continue;
        if(!group && !brushEntity)continue;if(!fb_pick_allowed(n,FB_PICK_LOCKED)||!fb_container_bounds(n,bounds))continue;
        if(labels){vector top=(bounds[0]+bounds[1])*0.5;top_z=bounds[1][2]+8;if(!cvar("ca_brush_view") && (top-camera)*forward<=0)continue;vector pixel=project(top);pixel_z=0;if(pixel_x<mn_x||pixel_y<mn_y||pixel_x>=mn_x+size_x||pixel_y>=mn_y+size_y)continue;drawstring(pixel,fb_nodes[n].name,'8 8 0','0.35 0.6 1',1,0);}
        else fb_visual_box(bounds[0],bounds[1],'0.2 0.45 1',0.75,FALSE);
    }
}
typedef struct {int from,to;} fb_entity_link_t;
fb_entity_link_t *fb_entity_connections;int fb_entity_connection_count;int *fb_entity_reachable;vector *fb_entity_centers;
void fb_entity_links_prepare()
{
    static int revision=-1,geometry=-1,filters=-1;int current=fb_document_revision();
    if(revision==current && geometry==fb_grid_geometry_epoch && filters==fb_filter_epoch)return;revision=current;geometry=fb_grid_geometry_epoch;filters=fb_filter_epoch;
    memfree(fb_entity_connections);fb_entity_connections=__NULL__;fb_entity_connection_count=0;
    memfree(fb_entity_reachable);fb_entity_reachable=memalloc(fb_node_count*sizeof(int));memfree(fb_entity_centers);fb_entity_centers=memalloc(fb_node_count*sizeof(vector));
    static vector bounds[2];
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY) {
        fb_entity_reachable[n]=fb_selection_selected(n);if(fb_container_bounds(n,bounds))fb_entity_centers[n]=(bounds[0]+bounds[1])*0.5;
        string target=fb_nodes[n].fields["target"],killtarget=fb_nodes[n].fields["killtarget"];if(target=="" && killtarget=="")continue;
        for(int other=2;other<fb_node_count;other++)if(other!=n && fb_nodes[other].kind==FB_NODE_ENTITY && fb_nodes[other].fields["targetname"]!="" && (fb_nodes[other].fields["targetname"]==target || fb_nodes[other].fields["targetname"]==killtarget)) {
            fb_entity_link_t *links=memalloc((fb_entity_connection_count+1)*sizeof(fb_entity_link_t));memcpy(links,fb_entity_connections,fb_entity_connection_count*sizeof(fb_entity_link_t));memfree(fb_entity_connections);fb_entity_connections=links;
            links[fb_entity_connection_count].from=n;links[fb_entity_connection_count++].to=other;
        }
    }
    for(int step=0;step<fb_node_count;step++) {
        int changed=FALSE;
        for(int e=0;e<fb_entity_connection_count;e++) {fb_entity_link_t edge=fb_entity_connections[e];if(fb_entity_reachable[edge.from] || fb_entity_reachable[edge.to]) {
            if(!fb_entity_reachable[edge.from] || !fb_entity_reachable[edge.to])changed=TRUE;fb_entity_reachable[edge.from]=fb_entity_reachable[edge.to]=TRUE;
        }}
        if(!changed)break;
    }
}
void fb_entity_links_draw()
{
    int mode=cvar("ftebroom_entity_links");if(!mode)return;fb_entity_links_prepare();
    for(int e=0;e<fb_entity_connection_count;e++) {
        fb_entity_link_t edge=fb_entity_connections[e];
        if(!fb_pick_allowed(edge.from,FB_PICK_LOCKED)||!fb_pick_allowed(edge.to,FB_PICK_LOCKED))continue;
        if(mode==1 && !fb_selection_selected(edge.from) && !fb_selection_selected(edge.to))continue;
        if(mode==2 && !fb_entity_reachable[edge.from])continue;
        vector from=fb_entity_centers[edge.from],to=fb_entity_centers[edge.to],direction=normalize(to-from);
        if(vlen(to-from)<0.01)continue;
        vector side=normalize(crossproduct(direction,'0 0 1'));if(vlen(side)<0.1)side='1 0 0';
        vector color='0.2 1 0.3';if(fb_selection_selected(edge.from)||fb_selection_selected(edge.to))color='1 0.2 0.2';
        fb_visual_line(from,to,color,0.8,0.8,TRUE);
        vector tip=from+(to-from)*0.65;float arrow=min(12,vlen(to-from)*0.15);
        fb_visual_line(tip,tip-direction*arrow+side*arrow*0.5,color,1,1,TRUE);
        fb_visual_line(tip,tip-direction*arrow-side*arrow*0.5,color,1,1,TRUE);
    }
}
