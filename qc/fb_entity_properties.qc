// SPDX-License-Identifier: GPL-2.0-or-later
var float autocvar_ftebroom_instantiate_defaults=0;
int *fb_property_entities;int fb_property_entity_count,fb_property_epoch;
void fb_entity_targets()
{
    memfree(fb_property_entities);fb_property_entities=memalloc(max(1,fb_node_count)*sizeof(int));fb_property_entity_count=0;
    for(int n=2;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_ENTITY) {
        int chosen=fb_entity_selected(fb_nodes[n].id);
        for(int b=2;b<fb_node_count;b++) if(fb_nodes[b].parent==n && fb_nodes[b].kind>=FB_NODE_BRUSH) if(brush_isselected(fb_nodes[b].model,fb_nodes[b].id)) chosen=TRUE;
        if(chosen) fb_property_entities[fb_property_entity_count++]=fb_nodes[n].id;
    }
    if(!fb_property_entity_count) fb_property_entities[fb_property_entity_count++]=0;
}
void fb_entity_publish()
{
    static string previous="";fb_document_tick();fb_entity_targets();
    string signature=strcat(itos(fb_document_revision()),"/",itos(fb_grid_geometry_epoch));for(int i=0;i<fb_property_entity_count;i++)signature=strcat(signature," ",itos(fb_property_entities[i]));
    if(signature==previous)return;strunzone(previous);previous=strzone(signature);
    filestream stream=fopen("ftebroom-entity-selection.txt",FILE_WRITE);if((float)stream<0)return;
    for(int i=0;i<fb_property_entity_count;i++) {
        int id=fb_property_entities[i];fputs(stream,sprintf("e %i\n",id));
        int n=tokenize(terrain_edit(TEREDIT_ENT_GET,id));
        for(int k=0;k<n;k+=2) fputs(stream,sprintf("p %i \"%s\" \"%s\"\n",id,fb_organize_escape(argv(k)),fb_organize_escape(argv(k+1))));
    }
    // Usage counts and the document's definition path are independent of selection.
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY)fputs(stream,sprintf("u %i \"%s\"\n",fb_nodes[n].id,fb_organize_escape(fb_nodes[n].fields["classname"])));
    fputs(stream,strcat("d 0 \"",fb_organize_escape(fb_nodes[0].fields["_tb_def"]),"\"\n"));
    fclose(stream);cvar_set("ftebroom_property_epoch",itos(++fb_property_epoch));
}
void fb_entity_property(string operation,string key,string value)
{
    string op=strzone(operation),name=strzone(key),replacement=strzone(value);fb_tool_refresh();fb_document_tick();fb_entity_targets();
    int invalid=op!="set" && op!="remove" && op!="rename" && op!="setflag" && op!="clearflag";
    if(name=="classname" && (op!="set" || replacement==""))invalid=TRUE;
    if(substring(name,0,4)=="_tb_")invalid=TRUE;
    if(op=="rename" && (replacement=="" || strstrofs(replacement,"\"",0)>=0 || strstrofs(replacement,"\n",0)>=0 || replacement=="model" || substring(replacement,0,4)=="_tb_"))invalid=TRUE;
    if(name=="model")for(int i=0;i<fb_property_entity_count;i++) {
        int count=tokenize(terrain_edit(TEREDIT_ENT_GET,fb_property_entities[i]));
        for(int k=0;k<count;k+=2)if(argv(k)=="model" && substring(argv(k+1),0,1)=="*")invalid=TRUE;
    }
    if(invalid || name=="" || strstrofs(name,"\"",0)>=0 || strstrofs(name,"\n",0)>=0 || name=="model" && substring(replacement,0,1)=="*") {
        cvar_set("ftebroom_selection_status","Invalid property key or internal model reference");strunzone(op);strunzone(name);strunzone(replacement);return;
    }
    fb_tx_begin("Entity properties");
    for(int i=0;i<fb_property_entity_count;i++) {
        int id=fb_property_entities[i];string data="";
        hashtable fields=hash_createtab(32,EV_STRING);int count=tokenize(terrain_edit(TEREDIT_ENT_GET,id));
        for(int k=0;k<count;k+=2)fields[argv(k)]=argv(k+1);
        if(op=="rename" && replacement!="") fields[replacement]=fields[name];
        if(op=="set")fields[name]=replacement;
        if((op=="setflag" || op=="clearflag") && fields[name]=="" && (int)fb_entity_defaults!=0)fields[name]=fb_entity_defaults[strcat(fields["classname"],"/",name)];
        if(op=="setflag")fields[name]=itos(stoi(fields[name])|stoi(replacement));
        if(op=="clearflag")fields[name]=itos(stoi(fields[name])&~stoi(replacement));
        for(int k=0;;k++) {
            string current=hash_getkey(fields,k);if isnull(current)break;
            if(current==name && (op=="remove"||op=="rename"))continue;
            data=strcat(data,"\"",fb_organize_escape(current),"\" \"",fb_organize_escape(fields[current]),"\"\n");
        }
        fb_tx_entity_set(id,data,HIST_ENTITY);hash_destroytab(fields);
    }
    fb_tx_commit();strunzone(op);strunzone(name);strunzone(replacement);
}
void fb_entity_create(string classname,int brush,vector position)
{
    string name=strzone(classname);fb_tool_refresh();fb_document_tick();
    if(name=="" || name=="worldspawn" || brush && !selectedbrushcount) {strunzone(name);return;}
    for(int a=0;a<3;a++)if(!fb_geom_finite(position[a])||fabs(position[a])>autocvar_ftebroom_world_bound){strunzone(name);return;}
    int parent=fb_selection_open_node();if(parent<0)parent=fb_organize_node(fb_active_layer);
    fb_tx_begin("Create entity");int id=terrain_edit(TEREDIT_ENT_ADD,"");
    string data=strcat("\"classname\" \"",fb_organize_escape(name),"\"\n");
    if(!brush)data=strcat(data,"\"origin\" \"",vtos(position),"\"\n");
    if(autocvar_ftebroom_instantiate_defaults && (int)fb_entity_defaults!=0) {
        string prefix=strcat(name,"/");
        for(int k=0;;k++) {
            string key=hash_getkey(fb_entity_defaults,k);if isnull(key)break;
            if(substring(key,0,strlen(prefix))!=prefix)continue;
            string property=substring(key,strlen(prefix),-1);
            if(property=="classname" || property=="origin" || property=="model" || substring(property,0,4)=="_tb_")continue;
            data=strcat(data,"\"",fb_organize_escape(property),"\" \"",fb_organize_escape(fb_entity_defaults[key]),"\"\n");
        }
    }
    fb_tx_entity_set(id,data,HIST_ENTITY);fb_organize_parent(id,parent);
    int valid=TRUE;
    if(brush) {
        int destination=fb_organize_model(id),count=selectedbrushcount;
        selbrush_t *selection=memalloc(count*sizeof(selbrush_t));memcpy(selection,selectedbrushes,count*sizeof(selbrush_t));
        if(!destination)valid=FALSE;
        for(int b=0;b<count && valid;b++)valid=fb_organize_move_brush(selection[b].model,selection[b].id,destination,FALSE);
        memfree(selection);fb_organize_cleanup();
    }else {fb_selection_clear();fb_entity_select(id,TRUE);}
    if(valid)fb_tx_commit();else fb_tx_cancel();strunzone(name);
}
void fb_entity_apply_defaults(string mode)
{
    string operation=strzone(mode);fb_tool_refresh();fb_document_tick();fb_entity_targets();
    if(!fb_entity_defaults){strunzone(operation);return;}
    fb_tx_begin("Entity defaults");
    for(int i=0;i<fb_property_entity_count;i++) {
        int id=fb_property_entities[i];hashtable fields=hash_createtab(32,EV_STRING);int count=tokenize(terrain_edit(TEREDIT_ENT_GET,id));
        for(int k=0;k<count;k+=2)fields[argv(k)]=argv(k+1);
        string prefix=strcat(fields["classname"],"/");
        for(int k=0;;k++) {
            string key=hash_getkey(fb_entity_defaults,k);if isnull(key)break;
            if(substring(key,0,strlen(prefix))!=prefix)continue;
            string name=substring(key,strlen(prefix),-1);if(name=="classname" || name=="origin" || name=="model" || substring(name,0,4)=="_tb_")continue;
            string before=hash_get(fields,name,__NULL__);int exists=!isnull(before);
            if(operation=="all" || (operation=="existing" && exists) || (operation=="missing" && !exists))fb_tx_set_key(id,name,fb_entity_defaults[key],HIST_ENTITY);
        }
        hash_destroytab(fields);
    }
    fb_tx_commit();strunzone(operation);
}
float fb_entity_command()
{
    if(argv(0)=="ftebroom_entity_defaults"){fb_entity_apply_defaults(argv(1));return TRUE;}
    if(argv(0)=="ftebroom_entity_property") {fb_entity_property(argv(1),argv(2),argv(3));return TRUE;}
    if(argv(0)=="ftebroom_entity_create") {fb_entity_create(argv(1),stoi(argv(2)),stov(argv(3)));return TRUE;}
    if(argv(0)=="ftebroom_entity_definitions_loaded") {fb_entity_definitions_load();editor_ents_reload();return TRUE;}
    if(argv(0)=="ftebroom_entity_definition_path") {string path=strzone(argv(1));fb_tx_set_key(0,"_tb_def",path,HIST_ENTITY);strunzone(path);return TRUE;}
    return FALSE;
}
