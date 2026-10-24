// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Rebuild a shared teleport closet from persistent source-entity metadata.
int fb_spawn_source,fb_spawn_selection,fb_spawn_revision;
int fb_spawn_source_node()
{
    fb_entity_targets();int result=-1;
    for(int i=0;i<fb_property_entity_count;i++){
        int node=fb_organize_node(fb_property_entities[i]);if(node<2)continue;
        string name=fb_nodes[node].fields["classname"];
        if(substring(name,0,8)!="trigger_"&&strstrofs(name,"button")<0)continue;
        if(result>=0)return -1;result=node;
    }
    return result;
}
int fb_spawn_definition(string name)
{
    if(!fb_entity_kinds)return -1;if((int)fb_entity_kinds[name]!=1)return -1;
    for(int i=0;i<fb_entity_definition_count;i++)if(fb_entity_definitions[i].classname==name)return i;return -1;
}
void fb_spawn_prepare()
{
    fb_entity_definitions_load();fb_tool_deactivate();fb_document_tick();int source=fb_spawn_source_node();fb_spawn_source=source<2?-1:fb_nodes[source].id;
    fb_spawn_selection=fb_selection_epoch;fb_spawn_revision=fb_document_revision();
    cvar_set("ftebroom_spawn_error",source<2?"Select exactly one trigger or button entity.":"");
    filestream file=fopen("ftebroom-spawn-master.txt",FILE_WRITE);if((float)file<0)return;
    fputs(file,sprintf("s %i\n",fb_spawn_source));
    if(source>=2){fputs(file,strcat("d \"",fb_organize_escape(fb_nodes[source].fields["_tb_spawn_master_destination"]),"\"\n"));fputs(file,strcat("c \"",fb_organize_escape(fb_nodes[source].fields["_tb_spawn_master_classname"]),"\"\n"));}
    hashtable names=hash_createtab(128,EV_STRING);
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY){string target=fb_nodes[n].fields["targetname"];if(target!=""&&names[target]==""){fputs(file,strcat("t \"",fb_organize_escape(target),"\"\n"));names[target]="1";}}
    hash_destroytab(names);fclose(file);cvar_set("ftebroom_spawn_epoch",ftos(cvar("ftebroom_spawn_epoch")+1));
}
typedef struct {string destination,classname,target;int definition;} fb_spawn_entry_t;
int fb_spawn_box(int model,vector low,vector high,string material)
{
    if(!fb_geom_point(low)||!fb_geom_point(high))return FALSE;
    fb_boxfaces((low+high)*.5,high-low);for(int i=0;i<6;i++)fb_preview[i].shadername=material;
    return brush_history_create(model,fb_preview,6,CONTENTBIT_SOLID,FALSE)!=0;
}
int fb_spawn_point(string classname,vector origin,int group)
{
    int id=terrain_edit(TEREDIT_ENT_ADD,"");if(id<1)return -1;
    string data=strcat("\"classname\" \"",fb_organize_escape(classname),"\"\n\"origin\" \"",vtos(origin),"\"\n");
    if(autocvar_ftebroom_instantiate_defaults)if(fb_entity_defaults){
        string prefix=strcat(classname,"/");
        for(int k=0;;k++){string key=hash_getkey(fb_entity_defaults,k);if isnull(key)break;if(substring(key,0,strlen(prefix))!=prefix)continue;string property=substring(key,strlen(prefix),-1);
            if(property=="classname"||property=="origin"||property=="model"||substring(property,0,4)=="_tb_")continue;
            data=strcat(data,"\"",fb_organize_escape(property),"\" \"",fb_organize_escape(fb_entity_defaults[key]),"\"\n");
        }
    }
    fb_tx_entity_set(id,data,HIST_ENTITY);fb_organize_parent(id,group);return id;
}
int fb_spawn_apply(string destination,string classname)
{
    fb_tool_deactivate();fb_document_tick();int source=fb_spawn_source_node();
    if(source<2)return FALSE;
    if(fb_nodes[source].id!=fb_spawn_source||fb_selection_epoch!=fb_spawn_selection||fb_document_revision()!=fb_spawn_revision){cvar_set("ftebroom_spawn_error","Selection or map changed. Refresh Spawn Master.");return FALSE;}
    int definition=fb_spawn_definition(classname),hasDestination=FALSE;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY&&fb_nodes[n].fields["targetname"]==destination&&destination!="")hasDestination=TRUE;
    if(definition<0||!hasDestination){cvar_set("ftebroom_spawn_error","Choose a known point entity and an existing destination targetname.");return FALSE;}
    int sourceId=fb_nodes[source].id,parent=fb_nodes[source].parent,oldGroup=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_ftebroom_spawn_closet"]=="1")oldGroup=n;
    if(oldGroup>=2)if(fb_selection_descendant(source,oldGroup)){cvar_set("ftebroom_spawn_error","The source cannot be inside its generated closet.");return FALSE;}
    fb_spawn_entry_t *entries=memalloc(128*sizeof(fb_spawn_entry_t));int count=0,valid=TRUE;
    hashtable used=hash_createtab(256,EV_STRING),seen=hash_createtab(128,EV_STRING);
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY){string name=fb_nodes[n].fields["targetname"];if(name!="")used[name]="1";string configured=fb_nodes[n].fields["_tb_spawn_master_teleport_target"];if(configured!="")used[configured]="1";}
    string sourceTarget=fb_nodes[source].fields["_tb_spawn_master_teleport_target"];
    if(sourceTarget==""){int number=1;do{sourceTarget=strcat("sm_teleport_",itos(number++));}while(used[sourceTarget]!="");}
    sourceTarget=strzone(sourceTarget);
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY){
        string target=n==source?sourceTarget:(string)fb_nodes[n].fields["_tb_spawn_master_teleport_target"];
        string cls=n==source?classname:(string)fb_nodes[n].fields["_tb_spawn_master_classname"];
        string dest=n==source?destination:(string)fb_nodes[n].fields["_tb_spawn_master_destination"];
        if(target==""||dest==""||cls==""||seen[target]!="")continue;
        int def=fb_spawn_definition(cls);if(def<0||count==128){valid=FALSE;break;}
        entries[count].target=strzone(target);entries[count].classname=strzone(cls);entries[count].destination=strzone(dest);entries[count].definition=def;count++;seen[target]="1";
    }
    hash_destroytab(used);hash_destroytab(seen);
    vector cell='224 224 144';for(int i=0;i<count;i++){fb_entity_definition_t *def=&fb_entity_definitions[entries[i].definition];vector size=def->maxs-def->mins;cell_x=max(cell_x,size_x+64);cell_y=max(cell_y,size_y+64);cell_z=max(cell_z,size_z+48);}
    int columns=max(1,ceil(sqrt(count))),rows=(count+columns-1i)/columns;
    vector extent=[columns*cell_x+(columns-1)*32+32,rows*cell_y+(rows-1)*32+32,cell_z+32],bounds[2],seed='0 0 0';
    if(fb_container_bounds(source,bounds))seed=(bounds[0]+bounds[1])*.5-'0 0 1000'-extent*.5;
    if(oldGroup>=2)if(fb_container_bounds(oldGroup,bounds))seed=bounds[0];
    // Include hidden geometry: generated rooms must not overlap it either.
    fb_container_bounds_t *occupied=memalloc(fb_node_count*sizeof(fb_container_bounds_t));int occupiedCount=0;
    for(int n=2;n<fb_node_count;n++)if(fb_selection_leaf(n)){
        if(oldGroup>=2)if(fb_selection_descendant(n,oldGroup))continue;
        int found=FALSE;if(fb_nodes[n].kind==FB_NODE_ENTITY)found=fb_entity_bounds(fb_nodes[n].id,bounds);else found=brush_getfacepoints(fb_nodes[n].model,fb_nodes[n].id,0,bounds,2)==2;
        if(found){occupied[occupiedCount].mins=bounds[0];occupied[occupiedCount++].maxs=bounds[1];}
    }
    vector low=seed,high=seed+extent;int placed=FALSE;
    for(int attempt=0;attempt<65&&!placed;attempt++){
        vector offset='0 0 0';if(attempt){int index=attempt-1i;offset=[((index%8i)-4)*(extent_x+64),0,-(index/8i)*(extent_z+64)];}
        low=seed+offset;high=low+extent;placed=fb_geom_point(low)&&fb_geom_point(high);
        for(int i=0;i<occupiedCount&&placed;i++){vector a=occupied[i].mins,b=occupied[i].maxs;if(low_x<b_x&&high_x>a_x&&low_y<b_y&&high_y>a_y&&low_z<b_z&&high_z>a_z)placed=FALSE;}
    }
    memfree(occupied);valid=valid&&placed&&count>0;
    if(valid){
        fb_tx_begin("Spawn Master");
        fb_tx_set_key(sourceId,"target",sourceTarget,HIST_ENTITY);fb_tx_set_key(sourceId,"_tb_spawn_master_destination",destination,HIST_ENTITY);fb_tx_set_key(sourceId,"_tb_spawn_master_classname",classname,HIST_ENTITY);fb_tx_set_key(sourceId,"_tb_spawn_master_teleport_target",sourceTarget,HIST_ENTITY);fb_tx_set_key(sourceId,"_tb_spawn_master_group","SpawnMasterCloset",HIST_ENTITY);
        if(oldGroup>=2)for(int n=fb_node_count-1;n>=2;n--)if(fb_selection_descendant(n,oldGroup)){if(fb_nodes[n].kind>=FB_NODE_BRUSH)brush_history_delete(fb_nodes[n].model,fb_nodes[n].id);else fb_tx_entity_set(fb_nodes[n].id,"",HIST_TREE);}
        int groupId=fb_organize_new("group","SpawnMasterCloset",parent);fb_tx_set_key(groupId,"_ftebroom_spawn_closet","1",HIST_TREE);fb_document_rebuild();int group=fb_organize_node(groupId),model=fb_organize_model(groupId);
        string wall=strzone(cvar_string("ca_newbrushtexture"));if(wall==""){strunzone(wall);wall=strzone("skip");}
        vector innerLow=low+'16 16 16',innerHigh=high-'16 16 16';
        if(!model)valid=FALSE;
        if(valid)valid=fb_spawn_box(model,low,[high_x,high_y,innerLow_z],wall);
        if(valid)valid=fb_spawn_box(model,[low_x,low_y,innerHigh_z],high,wall);
        if(valid)valid=fb_spawn_box(model,[low_x,low_y,innerLow_z],[innerLow_x,high_y,innerHigh_z],wall);
        if(valid)valid=fb_spawn_box(model,[innerHigh_x,low_y,innerLow_z],[high_x,high_y,innerHigh_z],wall);
        if(valid)valid=fb_spawn_box(model,[innerLow_x,low_y,innerLow_z],[innerHigh_x,innerLow_y,innerHigh_z],wall);
        if(valid)valid=fb_spawn_box(model,[innerLow_x,innerHigh_y,innerLow_z],[innerHigh_x,high_y,innerHigh_z],wall);
        strunzone(wall);
        for(int i=0;i<count&&valid;i++){
            fb_spawn_entry_t *entry=&entries[i];vector cellLow=innerLow+[(i%columns)*(cell_x+32),(i/columns)*(cell_y+32),0],cellHigh=cellLow+cell;
            int teleport=terrain_edit(TEREDIT_ENT_ADD,"");fb_tx_entity_set(teleport,"\"classname\" \"trigger_teleport\"\n",HIST_ENTITY);fb_organize_parent(teleport,group);fb_tx_set_key(teleport,"targetname",entry->target,HIST_ENTITY);fb_tx_set_key(teleport,"target",entry->destination,HIST_ENTITY);
            int teleportModel=fb_organize_model(teleport);if(!teleportModel){valid=FALSE;break;}valid=fb_spawn_box(teleportModel,cellLow,cellHigh,"trigger");
            fb_entity_definition_t *def=&fb_entity_definitions[entry->definition];vector center=(cellLow+cellHigh)*.5,defCenter=(def->mins+def->maxs)*.5;
            vector origin=[center_x-defCenter_x,center_y-defCenter_y,cellLow_z-def->mins[2]];if(fb_spawn_point(entry->classname,origin,group)<1)valid=FALSE;
        }
        if(valid){fb_selection_clear();fb_document_rebuild();fb_selection_set(fb_organize_node(groupId),TRUE);fb_tx_commit();}else fb_tx_cancel();
    }
    for(int i=0;i<count;i++){strunzone(entries[i].target);strunzone(entries[i].classname);strunzone(entries[i].destination);}memfree(entries);strunzone(sourceTarget);fb_document_tick();
    cvar_set("ftebroom_spawn_error",valid?"":"Could not place a valid closet (space, definitions or 128-entry limit). No changes applied.");return valid;
}
int fb_spawn_command()
{
    if(argv(0)!="ftebroom_spawn_master")return FALSE;
    if(argv(1)=="prepare")fb_spawn_prepare();
    else if(argv(1)=="apply"){string destination=strzone(argv(2)),classname=strzone(argv(3));int valid=fb_spawn_apply(destination,classname);cvar_set("ftebroom_spawn_result",valid?"1":"-1");strunzone(destination);strunzone(classname);}return TRUE;
}

