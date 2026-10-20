// SPDX-License-Identifier: GPL-2.0-or-later
void fb_pick_clear_handles();
// The engine remains the MAP serializer; this tree references its entity/submodel data.
enum : int { FB_NODE_WORLD, FB_NODE_LAYER, FB_NODE_GROUP, FB_NODE_ENTITY, FB_NODE_BRUSH, FB_NODE_PATCH };
enum : int { FB_NODE_HIDDEN=1, FB_NODE_LOCKED=2, FB_NODE_SELECTED=4 };
typedef struct {
    int kind, model, id, parent, layer, flags;
    string name, tbid, parentref, layerref;
    hashtable fields;
} fb_node_t;
fb_node_t *fb_nodes;
int fb_node_count,fb_node_capacity,fb_saved_revision,fb_seen_revision;
entity fb_document_probe;
int fb_grid_geometry_epoch;
int fb_document_revision()
{
    if(history>history_min) return historyring[(history-1)&(historyring_length-1)].revision;
    return history_base_revision;
}
void fb_document_clear()
{
    fb_grid_geometry_epoch++;
    for(int i=0;i<fb_node_count;i++) {
        strunzone(fb_nodes[i].name);strunzone(fb_nodes[i].tbid);
        strunzone(fb_nodes[i].parentref);strunzone(fb_nodes[i].layerref);
        if(fb_nodes[i].fields) hash_destroytab(fb_nodes[i].fields);
    }
    fb_node_count=0;
}
int fb_document_add(int kind,int model,int id,int parent,string name)
{
    if(fb_node_count==fb_node_capacity) {
        int capacity=max(64,fb_node_capacity*2);
        fb_node_t *nodes=memalloc(sizeof(fb_node_t)*capacity);
        memcpy(nodes,fb_nodes,sizeof(fb_node_t)*fb_node_count);memfree(fb_nodes);
        fb_nodes=nodes;fb_node_capacity=capacity;
    }
    int index=fb_node_count++;
    fb_nodes[index].flags=0;fb_nodes[index].fields=0i;
    fb_nodes[index].tbid=fb_nodes[index].parentref=fb_nodes[index].layerref="";
    fb_nodes[index].kind=kind;fb_nodes[index].model=model;fb_nodes[index].id=id;
    fb_nodes[index].parent=parent;fb_nodes[index].layer=1;
    fb_nodes[index].name=strzone(name);return index;
}
void fb_document_remap(int model,int oldid,int newid)
{
    for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].model==model) if(fb_nodes[i].id==oldid) fb_nodes[i].id=newid;
}
void fb_document_brushes(int model,int parent)
{
    int capacity=256,count;
    int *ids;
    static vector normals[1];static float distances[1];
    do {
        ids=memalloc(sizeof(int)*capacity);
        count=brush_findinvolume(model,normals,distances,0,ids,__NULL__,capacity);
        if(count<capacity) break;
        memfree(ids);capacity*=2;
        if(capacity>1048576) {print("FTEBroom: document node limit exceeded.\n");return;}
    } while(TRUE);
    for(int b=0;b<count;b++) {
        int kind=patch_getcp(model,ids[b],__NULL__,0,__NULL__)>0?FB_NODE_PATCH:FB_NODE_BRUSH;
        fb_document_add(kind,model,ids[b],parent,kind==FB_NODE_PATCH?"Patch":"Brush");
    }
    memfree(ids);
}
void fb_document_rebuild()
{
    fb_document_clear();
    fb_document_add(FB_NODE_WORLD,1,0,-1,"World");
    fb_document_add(FB_NODE_LAYER,0,-1,0,"Default Layer");
    if(!fb_document_probe) fb_document_probe=spawn();
    int entities=terrain_edit(TEREDIT_ENT_COUNT);
    for(int e=0;e<entities;e++) {
        string data=terrain_edit(TEREDIT_ENT_GET,e);
        if not(data) continue;
        hashtable fields=hash_createtab(32,EV_STRING);
        int count=tokenize(data);
        for(int k=0;k<count;k+=2) fields[argv(k)]=argv(k+1);
        string classname=fields["classname"],type=fields["_tb_type"];
        int kind=FB_NODE_ENTITY;
        if(classname=="func_group") {
            if(type=="_tb_layer") kind=FB_NODE_LAYER;
            else if(type=="_tb_group") kind=FB_NODE_GROUP;
        }
        string name=fields["_tb_name"];
        if(name=="") name=classname;
        int node=e?fb_document_add(kind,0,e,1,name):0;
        fb_nodes[node].fields=fields;
        fb_nodes[node].tbid=strzone(fields["_tb_id"]);
        fb_nodes[node].parentref=strzone(fields["_tb_group"]);
        fb_nodes[node].layerref=strzone(fields["_tb_layer"]);
        if(fields["_tb_layer_hidden"]=="1") fb_nodes[node].flags|=FB_NODE_HIDDEN;
        if(fields["_tb_layer_locked"]=="1") fb_nodes[node].flags|=FB_NODE_LOCKED;
        string modelname=fields["model"];
        int model=0;
        if(!e) model=1;
        else if(substring(modelname,0,1)=="*") {
            precache_model(modelname);setmodel(fb_document_probe,modelname);model=fb_document_probe.modelindex;
        }
        if(model) fb_document_brushes(model,e?node:1);
    }
    // Resolve IDs after all entities have been read; file order need not be topological.
    for(int i=2;i<fb_node_count;i++) {
        if(fb_nodes[i].kind>=FB_NODE_BRUSH) continue;
        if(fb_nodes[i].kind==FB_NODE_LAYER) {fb_nodes[i].parent=0;continue;}
        string ref=fb_nodes[i].parentref;
        if(ref=="") ref=fb_nodes[i].layerref;
        if(ref!="") for(int j=2;j<fb_node_count;j++) if(i!=j) if(fb_nodes[j].tbid==ref) {fb_nodes[i].parent=j;break;}
    }
    for(int i=1;i<fb_node_count;i++) {
        int parent=i,steps=0;
        while(parent>0 && steps++<fb_node_count) {
            if(fb_nodes[parent].kind==FB_NODE_LAYER) {fb_nodes[i].layer=parent;break;}
            parent=fb_nodes[parent].parent;
        }
        if(steps>=fb_node_count) {fb_nodes[i].parent=1;print("FTEBroom: cyclic group parent; using Default Layer.\n");}
    }
    cvar_set("ftebroom_node_count",itos(fb_node_count));
}
void fb_document_tick()
{
    int revision=fb_document_revision();
    cvar_set("ftebroom_revision",itos(revision));
    if(revision!=fb_saved_revision) cvar_set("ftebroom_dirty","1");
    else cvar_set("ftebroom_dirty","0");
    if(revision!=fb_seen_revision) {fb_seen_revision=revision;fb_document_rebuild();}
    for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].kind>=FB_NODE_BRUSH) {
        fb_nodes[i].flags=fb_nodes[i].flags & ~FB_NODE_SELECTED;
        if(brush_isselected(fb_nodes[i].model,fb_nodes[i].id)) fb_nodes[i].flags=fb_nodes[i].flags | FB_NODE_SELECTED;
    }
}
void fb_document_loaded()
{
    fb_open_group=0;fb_restore_entity_selection(-1);
    editor_ents_reload();
    fb_pick_clear_handles();
    fb_saved_revision=fb_document_revision();fb_seen_revision=-1;
    fb_history_labels();
    fb_document_tick();
}
float fb_document_command()
{
    if(argv(0)=="ftebroom_document_saved") {fb_saved_revision=stoi(argv(1));fb_document_tick();}
    else if(argv(0)=="ftebroom_document_reload") fb_document_loaded();
    else if(argv(0)=="ftebroom_document_dump") {
        fb_document_rebuild();fb_document_tick();
        print(sprintf("FTEBROOM_DOCUMENT revision=%i saved=%i dirty=%g nodes=%i\n",fb_document_revision(),fb_saved_revision,cvar("ftebroom_dirty"),fb_node_count));
        for(int i=0;i<fb_node_count;i++) print(sprintf("FTEBROOM_NODE %i kind=%i model=%i id=%i parent=%i layer=%i name=%s\n",i,fb_nodes[i].kind,fb_nodes[i].model,fb_nodes[i].id,fb_nodes[i].parent,fb_nodes[i].layer,fb_nodes[i].name));
    } else return FALSE;
    return TRUE;
}
