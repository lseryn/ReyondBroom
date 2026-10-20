// SPDX-License-Identifier: GPL-2.0-or-later
int *fb_clone_entities;
int *fb_clone_models;
int fb_clone_count;
void fb_clone_clear()
{
    memfree(fb_clone_entities);memfree(fb_clone_models);
    fb_clone_entities=fb_clone_models=__NULL__;fb_clone_count=0;
}
int fb_clone_groups()
{
    fb_clone_clear();fb_clone_count=fb_node_count;
    fb_clone_entities=memalloc(sizeof(int)*fb_clone_count);
    fb_clone_models=memalloc(sizeof(int)*fb_clone_count);
    int nextId=1;
    for(int n=0;n<fb_clone_count;n++) {
        fb_clone_entities[n]=-1;
        nextId=max(nextId,stoi(fb_nodes[n].tbid)+1);
    }
    for(int n=2;n<fb_clone_count;n++) if(fb_nodes[n].kind<FB_NODE_BRUSH && fb_nodes[n].kind!=FB_NODE_LAYER) {
        int target=fb_selection_target(n);
        int grouped=fb_nodes[target].kind==FB_NODE_GROUP && fb_selection_selected(target);
        int wholeEntity=fb_nodes[n].kind==FB_NODE_ENTITY && fb_selection_selected(n);
        if(!grouped && !wholeEntity) continue;
        int model=0;
        string modelName="";
        for(int b=0;b<fb_node_count;b++) if(fb_nodes[b].parent==n && fb_nodes[b].kind>=FB_NODE_BRUSH) {
            modelName=strzone(brush_model_create());
            if(modelName=="") {strunzone(modelName);return FALSE;}
            precache_model(modelName);
            if(!fb_document_probe) fb_document_probe=spawn();
            setmodel(fb_document_probe,modelName);model=fb_document_probe.modelindex;
            if(!model) {strunzone(modelName);return FALSE;}
            break;
        }
        string data=strzone(terrain_edit(TEREDIT_ENT_GET,fb_nodes[n].id));
        int entityIndex=terrain_edit(TEREDIT_ENT_ADD,"");
        fb_tx_entity_set(entityIndex,data,HIST_ENTITY);strunzone(data);
        if(modelName!="") {fb_tx_set_key(entityIndex,"model",modelName,HIST_ENTITY);strunzone(modelName);}
        if(fb_nodes[n].kind==FB_NODE_GROUP) fb_tx_set_key(entityIndex,"_tb_id",itos(nextId++),HIST_TREE);
        fb_clone_entities[n]=entityIndex;fb_clone_models[n]=model;
    }
    // Resolve parent IDs after every container has received its independent identity.
    for(int n=2;n<fb_clone_count;n++) if(fb_clone_entities[n]>=0) {
        int parent=fb_nodes[n].parent;
        if(parent>=0 && parent<fb_clone_count && fb_clone_entities[parent]>=0) {
            hashtable fields=hash_createtab(16,EV_STRING);
            int count=tokenize(terrain_edit(TEREDIT_ENT_GET,fb_clone_entities[parent]));
            for(int k=0;k<count;k+=2) fields[argv(k)]=argv(k+1);
            fb_tx_set_key(fb_clone_entities[n],"_tb_group",fields["_tb_id"],HIST_TREE);
            hash_destroytab(fields);
        }
    }
    return TRUE;
}
int fb_clone_destination(int model,int id)
{
    for(int n=0;n<fb_clone_count;n++) if(fb_nodes[n].kind>=FB_NODE_BRUSH && fb_nodes[n].model==model && fb_nodes[n].id==id) {
        int parent=fb_nodes[n].parent;
        if(parent>=0 && parent<fb_clone_count && fb_clone_models[parent]) return fb_clone_models[parent];
    }
    return model;
}
int fb_clone_entity(int id)
{
    for(int n=0;n<fb_clone_count;n++) if(fb_nodes[n].kind==FB_NODE_ENTITY && fb_nodes[n].id==id) return fb_clone_entities[n];
    return -1;
}
// Return the editable model of the open container, allocating it transactionally.
int fb_creation_model()
{
    int opened=fb_selection_open_node();
    if(opened<0) return 1;
    int entityIndex=fb_nodes[opened].id;
    string name="";int count=tokenize(terrain_edit(TEREDIT_ENT_GET,entityIndex));
    for(int k=0;k<count;k+=2) if(argv(k)=="model") name=argv(k+1);
    name=strzone(name);
    if(substring(name,0,1)!="*") {
        strunzone(name);name=strzone(brush_model_create());
        if(name=="") {strunzone(name);return 0;}
        fb_tx_set_key(entityIndex,"model",name,HIST_ENTITY);
    }
    precache_model(name);if(!fb_document_probe) fb_document_probe=spawn();setmodel(fb_document_probe,name);
    int model=fb_document_probe.modelindex;strunzone(name);return model;
}
