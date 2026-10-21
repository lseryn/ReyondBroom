// SPDX-License-Identifier: GPL-2.0-or-later
// Linked instances retain world-space geometry and an explicit local-to-world map.
int fb_linked_busy,fb_linked_serial;
string fb_linked_uuid()
{
    return sprintf("%08lx-%04lx-4%03lx-a%03lx-%08lx%04lx",(int)(random()*2147483647),
        (int)(random()*65535),(int)(random()*4095),(int)(random()*4095),
        (int)(random()*2147483647),++fb_linked_serial);
}
int fb_linked_matrix(string text,fb_affine_t *m)
{
    m->x='1 0 0';m->y='0 1 0';m->z='0 0 1';m->translation='0 0 0';
    if(text!="") {
        if(tokenize(text)!=16)return FALSE;
        m->x=[stof(argv(0)),stof(argv(4)),stof(argv(8))];
        m->y=[stof(argv(1)),stof(argv(5)),stof(argv(9))];
        m->z=[stof(argv(2)),stof(argv(6)),stof(argv(10))];
        m->translation=[stof(argv(3)),stof(argv(7)),stof(argv(11))];
        if(stof(argv(12))!=0 || stof(argv(13))!=0 || stof(argv(14))!=0 || stof(argv(15))!=1)return FALSE;
    }
    return fb_affine_prepare(m);
}
string fb_linked_matrix_text(fb_affine_t *m)
{
    return strcat(sprintf("%.9g %.9g %.9g %.9g ",m->x[0],m->y[0],m->z[0],m->translation[0]),
        sprintf("%.9g %.9g %.9g %.9g ",m->x[1],m->y[1],m->z[1],m->translation[1]),
        sprintf("%.9g %.9g %.9g %.9g 0 0 0 1",m->x[2],m->y[2],m->z[2],m->translation[2]));
}
void fb_linked_compose(fb_affine_t *a,fb_affine_t *b,fb_affine_t *out)
{
    out->x=fb_affine_direction(a,b->x);out->y=fb_affine_direction(a,b->y);
    out->z=fb_affine_direction(a,b->z);out->translation=fb_affine_point(a,b->translation);
    fb_affine_prepare(out);
}
void fb_linked_inverse(fb_affine_t *m,fb_affine_t *out)
{
    out->x=[m->ix[0],m->iy[0],m->iz[0]];out->y=[m->ix[1],m->iy[1],m->iz[1]];
    out->z=[m->ix[2],m->iy[2],m->iz[2]];out->translation=-fb_affine_direction(out,m->translation);
    fb_affine_prepare(out);
}
hashtable fb_linked_fields(string data)
{
    hashtable fields=hash_createtab(32,EV_STRING);int count=fb_entity_tokenize(data);
    for(int k=0;k<count;k+=2)fields[argv(k)]=argv(k+1);
    return fields;
}
string fb_linked_fields_text(hashtable fields)
{
    string data="";
    for(int i=0;;i++) {
        string key=hash_getkey(fields,i);if isnull(key)break;
        data=strcat(data,fb_map_quote(key)," ",fb_map_quote(fields[key]),"\n");
    }
    return data;
}
int fb_linked_protected(string list,string key)
{
    string current="";int escape=FALSE;
    for(int i=0;i<=strlen(list);i++) {
        string ch=substring(list,i,1);
        if(escape){current=strcat(current,ch);escape=FALSE;}
        else if(ch=="\\")escape=TRUE;
        else if(ch==";" || ch==""){if(current==key)return TRUE;current="";}
        else current=strcat(current,ch);
    }
    return FALSE;
}
// Called while the pre-transform document tree is still available.
void fb_linked_transform(fb_affine_t *delta)
{
    int opened=fb_selection_open_node();
    for(int n=2;n<fb_node_count;n++) {
        if(fb_nodes[n].kind!=FB_NODE_GROUP || fb_nodes[n].fields["_tb_linked_group_id"]=="")continue;
        if(fb_selection_descendant(opened,n))continue;
        if(!fb_selection_selected(n))continue;
        fb_affine_t before,after;
        if(!fb_linked_matrix(fb_nodes[n].fields["_tb_transformation"],&before))continue;
        fb_linked_compose(delta,&before,&after);
        int id=fb_nodes[n].id,clone=-1;
        if(n<fb_clone_count)clone=fb_clone_entities[n];
        if(fb_transform_duplicate && clone>=0)id=clone;
        fb_tx_set_key(id,"_tb_transformation",fb_linked_matrix_text(&after),HIST_TREE);
    }
}
void fb_linked_translate(vector delta)
{
    fb_affine_t map;fb_linked_matrix("",&map);map.translation=delta;fb_linked_transform(&map);
}
typedef struct {
    int kind,parent,id,model,count,contents;
    string fields;
    brushface_t *faces;
    patchvert_t *points;
    patchinfo_t patch;
} fb_linked_item_t;
fb_linked_item_t *fb_linked_items;int fb_linked_count,fb_linked_root,fb_linked_nextid;
void fb_linked_clear()
{
    for(int i=0;i<fb_linked_count;i++) {
        fb_linked_item_t *item=&fb_linked_items[i];strunzone(item->fields);
        if(item->faces)for(int f=0;f<item->count;f++)strunzone(item->faces[f].shadername);
        if(item->points)strunzone(item->patch.shadername);
        memfree(item->faces);memfree(item->points);
    }
    memfree(fb_linked_items);fb_linked_items=__NULL__;fb_linked_count=0;
}
int fb_linked_capture(int root)
{
    fb_linked_clear();fb_linked_items=memalloc(fb_node_count*sizeof(fb_linked_item_t));
    int *mapping=memalloc(fb_node_count*sizeof(int));
    for(int n=0;n<fb_node_count;n++)mapping[n]=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_selection_descendant(n,root)) {
        int index=fb_linked_count++;mapping[n]=index;
        fb_node_t node=fb_nodes[n];fb_linked_item_t *item=&fb_linked_items[index];
        item->kind=node.kind;item->parent=node.parent;item->model=node.model;item->id=node.id;
        if(node.kind<FB_NODE_BRUSH) {
            string fields=strzone(terrain_edit(TEREDIT_ENT_GET,node.id));
            if(n!=root && fb_clip_field(fields,"_ftebroom_link_member")=="") {
                fb_tx_set_key(node.id,"_ftebroom_link_member",fb_linked_uuid(),HIST_TREE);
                strunzone(fields);fields=strzone(terrain_edit(TEREDIT_ENT_GET,node.id));
            }
            item->fields=fields;
        } else if(node.kind==FB_NODE_BRUSH) {
            item->count=brush_get(node.model,node.id,__NULL__,0,&item->contents);
            if(item->count<4 || item->count>64){memfree(mapping);fb_linked_clear();return FALSE;}
            item->faces=memalloc(item->count*sizeof(brushface_t));
            brush_get(node.model,node.id,item->faces,item->count,&item->contents);
            for(int f=0;f<item->count;f++)item->faces[f].shadername=strzone(item->faces[f].shadername);
        } else {
            item->count=patch_getcp(node.model,node.id,__NULL__,0,&item->patch);
            item->points=memalloc(item->count*sizeof(patchvert_t));
            patch_getcp(node.model,node.id,item->points,item->count,&item->patch);
            item->patch.shadername=strzone(item->patch.shadername);
        }
    }
    int rootIndex=mapping[root];fb_linked_root=rootIndex;
    for(int i=0;i<fb_linked_count;i++) {
        int parent=fb_linked_items[i].parent;
        int mappedParent=-1;if(parent>=0)mappedParent=mapping[parent];
        fb_linked_items[i].parent=mappedParent;
    }
    memfree(mapping);return rootIndex>=0;
}
int fb_linked_validate(fb_affine_t *delta)
{
    for(int i=0;i<fb_linked_count;i++) {
        fb_linked_item_t *item=&fb_linked_items[i];
        if(item->kind==FB_NODE_BRUSH) {
            brushface_t *faces=memalloc(item->count*sizeof(brushface_t));memcpy(faces,item->faces,item->count*sizeof(brushface_t));
            for(int f=0;f<item->count;f++)fb_affine_face(delta,&faces[f],TRUE);
            int valid=fb_brush_valid(faces,item->count);memfree(faces);if(!valid)return FALSE;
        } else if(item->kind==FB_NODE_PATCH) {
            for(int p=0;p<item->count;p++)if(!fb_geom_point(fb_affine_point(delta,item->points[p].xyz)))return FALSE;
        } else {
            string origin=fb_clip_field(item->fields,"origin");
            if(origin!="")if(!fb_geom_point(fb_affine_point(delta,stov(origin))))return FALSE;
        }
    }
    return TRUE;
}
string fb_linked_merge_properties(string source,string existing)
{
    hashtable src=fb_linked_fields(source),old=fb_linked_fields(existing);
    string protectedSource=strzone(src["_tb_protected_properties"]),protectedTarget=strzone(old["_tb_protected_properties"]);
    hashtable keys=hash_createtab(32,EV_STRING);
    for(int pass=0;pass<2;pass++) {
        hashtable fields=pass?old:src;
        for(int k=0;;k++) {string key=hash_getkey(fields,k);if isnull(key)break;keys[key]="1";}
    }
    for(int k=0;;k++) {
        string key=hash_getkey(keys,k);if isnull(key)break;
        if(fb_linked_protected(protectedSource,key) || fb_linked_protected(protectedTarget,key)) {
            string value=old[key];if isnull(value)hash_delete(src,key);else src[key]=value;
        }
    }
    src["_tb_protected_properties"]=protectedTarget;
    string result=strzone(fb_linked_fields_text(src));
    hash_destroytab(src);hash_destroytab(old);hash_destroytab(keys);strunzone(protectedSource);strunzone(protectedTarget);
    return result;
}
int fb_linked_replace(int target,fb_affine_t *delta)
{
    hashtable previous=hash_createtab(64,EV_STRING);
    for(int n=2;n<fb_node_count;n++)if(n!=target && fb_selection_descendant(n,target)) {
        fb_node_t node=fb_nodes[n];
        if(node.kind<FB_NODE_BRUSH) {
            string data=strzone(terrain_edit(TEREDIT_ENT_GET,node.id));
            string member=fb_clip_field(data,"_ftebroom_link_member");
            if(member!="")previous[member]=data;strunzone(data);
        }
    }
    // All destinations have been validated before the first replacement.
    for(int n=fb_node_count-1;n>=2;n--)if(n!=target && fb_selection_descendant(n,target)) {
        fb_node_t node=fb_nodes[n];
        if(node.kind>=FB_NODE_BRUSH)brush_history_delete(node.model,node.id);
        else fb_tx_entity_set(node.id,"",HIST_TREE);
    }
    int *entities=memalloc(fb_linked_count*sizeof(int));
    int *models=memalloc(fb_linked_count*sizeof(int));
    int *identities=memalloc(fb_linked_count*sizeof(int));int valid=TRUE;
    entities[fb_linked_root]=fb_nodes[target].id;identities[fb_linked_root]=stoi(fb_nodes[target].tbid);
    models[fb_linked_root]=fb_organize_model(fb_nodes[target].id);
    if(!models[fb_linked_root])valid=FALSE;
    for(int i=0;i<fb_linked_count && valid;i++) {
        fb_linked_item_t *item=&fb_linked_items[i];if(i==fb_linked_root || item->kind>=FB_NODE_BRUSH)continue;
        int id=terrain_edit(TEREDIT_ENT_ADD,"");entities[i]=id;
        string member=strzone(fb_clip_field(item->fields,"_ftebroom_link_member"));
        string merged=fb_linked_merge_properties(item->fields,previous[member]);strunzone(member);
        string protectedKeys=strzone(fb_clip_field(merged,"_tb_protected_properties"));
        fb_tx_entity_set(id,merged,HIST_ENTITY);strunzone(merged);
        if(item->kind==FB_NODE_GROUP) {
            identities[i]=fb_linked_nextid++;
            fb_tx_set_key(id,"_tb_id",itos(identities[i]),HIST_TREE);
            if(fb_clip_field(item->fields,"_tb_linked_group_id")!="") {
                fb_affine_t sourceMap,targetMap;
                fb_linked_matrix(fb_clip_field(item->fields,"_tb_transformation"),&sourceMap);
                fb_linked_compose(delta,&sourceMap,&targetMap);
                fb_tx_set_key(id,"_tb_transformation",fb_linked_matrix_text(&targetMap),HIST_TREE);
            }
        }
        int hasGeometry=FALSE;for(int child=0;child<fb_linked_count;child++)
            if(fb_linked_items[child].parent==i && fb_linked_items[child].kind>=FB_NODE_BRUSH)hasGeometry=TRUE;
        if(hasGeometry) {
            // A copied *model reference must never alias another instance.
            fb_tx_set_key(id,"model","",HIST_ENTITY);models[i]=fb_organize_model(id);if(!models[i])valid=FALSE;
        }
        string origin=strzone(fb_clip_field(item->fields,"origin"));
        if(origin!="" && !fb_linked_protected(protectedKeys,"origin"))fb_tx_set_key(id,"origin",fb_clip_vec(fb_affine_point(delta,stov(origin))),HIST_ENTITY);
        strunzone(origin);
        if(cvar("ftebroom_rotate_entity_properties") && !fb_linked_protected(protectedKeys,"angle") && !fb_linked_protected(protectedKeys,"angles"))fb_affine_angles(id,delta);
        strunzone(protectedKeys);
    }
    for(int i=0;i<fb_linked_count && valid;i++) {
        fb_linked_item_t *item=&fb_linked_items[i];if(i==fb_linked_root)continue;
        int parent=item->parent;if(parent<0){valid=FALSE;break;}
        if(item->kind<FB_NODE_BRUSH) {
            fb_tx_set_key(entities[i],"_tb_group",itos(identities[parent]),HIST_TREE);
            fb_tx_set_key(entities[i],"_tb_layer","",HIST_TREE);
        } else if(item->kind==FB_NODE_BRUSH) {
            brushface_t *faces=memalloc(item->count*sizeof(brushface_t));memcpy(faces,item->faces,item->count*sizeof(brushface_t));
            for(int f=0;f<item->count;f++)fb_affine_face(delta,&faces[f],TRUE);
            if(!brush_history_create(models[parent],faces,item->count,item->contents,FALSE))valid=FALSE;
            memfree(faces);
        } else {
            patchvert_t *points=memalloc(item->count*sizeof(patchvert_t));
            for(int p=0;p<item->count;p++) {
                int destination=p;
                if(delta->determinant<0){int row=p/item->patch.cpwidth,col=p-row*item->patch.cpwidth;destination=row*item->patch.cpwidth+item->patch.cpwidth-1-col;}
                points[destination]=item->points[p];points[destination].xyz=fb_affine_point(delta,item->points[p].xyz);
            }
            if(!patch_history_create(models[parent],points,item->patch,FALSE))valid=FALSE;memfree(points);
        }
    }
    memfree(entities);memfree(models);memfree(identities);hash_destroytab(previous);return valid;
}
int fb_linked_sync_source(int source)
{
    string link=strzone(fb_nodes[source].fields["_tb_linked_group_id"]);
    if(link==""){strunzone(link);return TRUE;}
    fb_linked_busy=TRUE;
    fb_affine_t sourceMap,inverse;int valid=fb_linked_matrix(fb_nodes[source].fields["_tb_transformation"],&sourceMap);
    if(valid){fb_linked_inverse(&sourceMap,&inverse);valid=fb_linked_capture(source);}
    fb_linked_nextid=1;for(int n=2;n<fb_node_count;n++)fb_linked_nextid=max(fb_linked_nextid,stoi(fb_nodes[n].tbid)+1);
    for(int pass=0;pass<2 && valid;pass++)for(int n=2;n<fb_node_count && valid;n++) {
        if(n==source || fb_nodes[n].kind!=FB_NODE_GROUP || fb_nodes[n].fields["_tb_linked_group_id"]!=link)continue;
        if(fb_selection_descendant(n,source) || fb_selection_descendant(source,n)){valid=FALSE;break;}
        fb_affine_t targetMap,delta;
        valid=fb_linked_matrix(fb_nodes[n].fields["_tb_transformation"],&targetMap);if(!valid)break;
        fb_linked_compose(&targetMap,&inverse,&delta);
        if(!pass)valid=fb_linked_validate(&delta);else valid=fb_linked_replace(n,&delta);
    }
    fb_linked_clear();strunzone(link);fb_linked_busy=FALSE;
    if(!valid)cvar_set("ftebroom_selection_status","Linked update would create invalid geometry; edit cancelled");
    return valid;
}
int fb_linked_before_commit()
{
    if(fb_linked_busy || !fb_open_group || history<=fb_tx_start+1)return TRUE;
    int changed=FALSE;
    for(int h=fb_tx_start+1;h<history;h++) {
        int kind=historyring[h&(historyring_length-1)].kind;
        if(kind==HIST_GEOMETRY || kind==HIST_ENTITY || kind==HIST_TREE)changed=TRUE;
    }
    if(!changed)return TRUE;
    fb_document_tick();int source=fb_selection_open_node();if(source<0)return TRUE;
    // Preserve entity identities while sibling replacement rebuilds node indices.
    int *ancestors=memalloc(fb_node_count*sizeof(int));int count=0;
    for(int n=source,steps=0;n>=2 && steps++<fb_node_count;n=fb_nodes[n].parent)
        if(fb_nodes[n].kind==FB_NODE_GROUP && fb_nodes[n].fields["_tb_linked_group_id"]!="")ancestors[count++]=fb_nodes[n].id;
    int valid=TRUE;
    for(int i=0;i<count && valid;i++) {
        fb_document_tick();int node=fb_organize_node(ancestors[i]);
        if(node>=2)valid=fb_linked_sync_source(node);
    }
    memfree(ancestors);return valid;
}
void fb_linked_extract()
{
    fb_tool_refresh();fb_document_tick();int root=fb_selection_open_node();
    if(root<0 || (!selectedbrushcount && !fb_selected_entity_count))return;
    if(fb_nodes[root].fields["_tb_linked_group_id"]=="")return;
    string matrix=strzone(fb_nodes[root].fields["_tb_transformation"]),link=strzone(fb_linked_uuid());
    fb_tx_begin("Extract linked group");
    int newGroup=fb_organize_new("group","Extracted group",root);
    fb_document_rebuild();int newNode=fb_organize_node(newGroup);
    int moved=fb_organize_move(newGroup,newNode,FALSE);
    if(!moved){fb_tx_cancel();strunzone(matrix);strunzone(link);return;}
    fb_document_rebuild();
    int created=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP && fb_nodes[n].parent==fb_selection_open_node() && fb_selection_selected(n)) {
        created=fb_nodes[n].id;fb_tx_set_key(created,"_tb_linked_group_id",link,HIST_TREE);
        fb_tx_set_key(created,"_tb_transformation",matrix,HIST_TREE);break;
    }
    int valid=created>=0;if(valid)valid=fb_linked_before_commit();
    if(valid) {
        fb_document_tick();
        for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP && fb_nodes[n].fields["_tb_linked_group_id"]==link) {
            int parent=fb_nodes[n].parent;
            if(parent>=2)fb_organize_parent(fb_nodes[n].id,fb_nodes[parent].parent);
        }
        fb_linked_busy=TRUE;fb_tx_commit();fb_linked_busy=FALSE;
    }else fb_tx_cancel();
    strunzone(matrix);strunzone(link);
}
void fb_linked_action(string operation)
{
    if(operation=="extract"){fb_linked_extract();return;}
    string op=strzone(operation);fb_tool_refresh();fb_document_tick();
    hashtable links=hash_createtab(16,EV_STRING);
    int *roots=memalloc(fb_node_count*sizeof(int)),count=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP && fb_selection_selected(n)) {
        int nested=FALSE;for(int a=fb_nodes[n].parent;a>=2;a=fb_nodes[a].parent)
            if(fb_nodes[a].kind==FB_NODE_GROUP && fb_selection_selected(a))nested=TRUE;
        if(!nested){roots[n]=TRUE;count++;}
        string link=fb_nodes[n].fields["_tb_linked_group_id"];if(link!="")links[link]="1";
    }
    if(!count){cvar_set("ftebroom_selection_status","Select a closed group first");memfree(roots);hash_destroytab(links);strunzone(op);return;}
    fb_tx_begin(op=="duplicate"?"Create linked duplicate":(op=="select"?"Select linked groups":"Separate linked groups"));
    if(op=="duplicate") {
        for(int n=2;n<fb_node_count;n++)if(roots[n]) {
            if(fb_nodes[n].fields["_tb_linked_group_id"]=="") {
                fb_tx_set_key(fb_nodes[n].id,"_tb_linked_group_id",fb_linked_uuid(),HIST_TREE);
                fb_affine_t identity;fb_linked_matrix("",&identity);
                fb_tx_set_key(fb_nodes[n].id,"_tb_transformation",fb_linked_matrix_text(&identity),HIST_TREE);
            }
            // Stable member identities let per-instance properties survive content replacement.
            if(!fb_linked_capture(n)){fb_tx_cancel();break;}fb_linked_clear();
        }
        if(fb_tx_depth)fb_duplicate_numeric('0 0 0');
    } else if(op=="select") {
        for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP)
            if(links[fb_nodes[n].fields["_tb_linked_group_id"]]!="")fb_selection_set(n,TRUE);
    } else if(op=="separate") {
        for(int k=0;;k++) {
            string link=hash_getkey(links,k);if isnull(link)break;
            int chosen=0;for(int n=2;n<fb_node_count;n++)if(roots[n] && fb_nodes[n].fields["_tb_linked_group_id"]==link)chosen++;
            string replacement="";if(chosen>1)replacement=fb_linked_uuid();replacement=strzone(replacement);
            for(int n=2;n<fb_node_count;n++)if(roots[n] && fb_nodes[n].fields["_tb_linked_group_id"]==link)
                fb_tx_set_key(fb_nodes[n].id,"_tb_linked_group_id",replacement,HIST_TREE);
            strunzone(replacement);
        }
    }
    fb_tx_commit();memfree(roots);hash_destroytab(links);strunzone(op);
}
string fb_linked_protection_list(hashtable keys)
{
    string list="";
    for(int i=0;;i++) {
        string key=hash_getkey(keys,i);if isnull(key)break;
        if(list!="")list=strcat(list,";");
        list=strcat(list,strreplace(";","\\;",strreplace("\\","\\\\",key)));
    }
    return list;
}
hashtable fb_linked_protection_keys(string list)
{
    hashtable keys=hash_createtab(16,EV_STRING);string current="";int escape=FALSE;
    for(int i=0;i<=strlen(list);i++) {
        string ch=substring(list,i,1);
        if(escape){current=strcat(current,ch);escape=FALSE;}
        else if(ch=="\\")escape=TRUE;
        else if(ch==";" || ch==""){if(current!="")keys[current]="1";current="";}
        else current=strcat(current,ch);
    }
    return keys;
}
void fb_linked_restore_property(int id,hashtable fields,string key,int root)
{
    string member=strzone(fields["_ftebroom_link_member"]);
    string link=strzone(fb_nodes[root].fields["_tb_linked_group_id"]);
    for(int n=2;n<fb_node_count;n++) {
        if(fb_nodes[n].kind>=FB_NODE_BRUSH || fb_nodes[n].id==id || fb_nodes[n].fields["_ftebroom_link_member"]!=member || member=="")continue;
        int peer=fb_nodes[n].parent;
        while(peer>=2 && fb_nodes[peer].fields["_tb_linked_group_id"]!=link)peer=fb_nodes[peer].parent;
        if(peer<2 || peer==root || fb_linked_protected(fb_nodes[n].fields["_tb_protected_properties"],key))continue;
        string value=fb_nodes[n].fields[key];
        if isnull(value)hash_delete(fields,key);else {
            if(key=="origin" || key=="angle" || key=="angles") {
                fb_affine_t sourceMap,inverse,targetMap,delta;
                fb_linked_matrix(fb_nodes[peer].fields["_tb_transformation"],&sourceMap);fb_linked_inverse(&sourceMap,&inverse);
                fb_linked_matrix(fb_nodes[root].fields["_tb_transformation"],&targetMap);fb_linked_compose(&targetMap,&inverse,&delta);
                if(key=="origin")value=fb_clip_vec(fb_affine_point(&delta,stov(value)));
                else if(cvar("ftebroom_rotate_entity_properties")) {
                    if(key=="angle") {
                        float yaw=stof(value);vector direction;
                        if(yaw==-1)direction='0 0 1';else if(yaw==-2)direction='0 0 -1';
                        else {makevectors([0,yaw,0]);direction=v_forward;}
                        direction=normalize(fb_affine_direction(&delta,direction));
                        yaw=direction_z>0.99999?-1:direction_z< -0.99999?-2:atan2(direction_y,direction_x)*180/M_PI;
                        value=sprintf("%.9g",yaw);
                    }else {
                        vector angles=stov(value);makevectors(angles);
                        vector forward=normalize(fb_affine_direction(&delta,v_forward)),up=normalize(fb_affine_direction(&delta,v_up));
                        angles=vectoangles(forward,up);angles_x=-angles_x;value=fb_clip_vec(angles);
                    }
                }
            }
            fields[key]=value;
        }
        break;
    }
    strunzone(member);strunzone(link);
}
void fb_linked_protect(string operation,string name)
{
    string op=strzone(operation),key=strzone(name);fb_tool_refresh();fb_document_tick();
    int root=fb_selection_open_node();
    while(root>=2 && fb_nodes[root].fields["_tb_linked_group_id"]=="")root=fb_nodes[root].parent;
    if((root<2 && op!="clear") || key=="classname" || key=="model" || substring(key,0,1)=="_") {strunzone(op);strunzone(key);return;}
    fb_entity_targets();fb_tx_begin("Protected properties");
    for(int e=0;e<fb_property_entity_count;e++) {
        int id=fb_property_entities[e],node=fb_organize_node(id);
        int propertyRoot=root;
        if(op=="clear" && node>=2) {
            propertyRoot=fb_nodes[node].parent;
            while(propertyRoot>=2 && fb_nodes[propertyRoot].fields["_tb_linked_group_id"]=="")propertyRoot=fb_nodes[propertyRoot].parent;
        }
        if(node<2 || propertyRoot<2 || !fb_selection_descendant(node,propertyRoot))continue;
        hashtable fields=fb_linked_fields(terrain_edit(TEREDIT_ENT_GET,id));
        hashtable keys=fb_linked_protection_keys(fields["_tb_protected_properties"]);
        if(op=="clear") {
            for(int i=0;;i++){string old=hash_getkey(keys,i);if isnull(old)break;fb_linked_restore_property(id,fields,old,propertyRoot);}
            fields["_tb_protected_properties"]="";
        } else {
            if(op=="off") {hash_delete(keys,key);fb_linked_restore_property(id,fields,key,propertyRoot);}
            else {keys[key]="1";if(op=="add")fields[key]="";}
            fields["_tb_protected_properties"]=fb_linked_protection_list(keys);
        }
        fb_tx_entity_set(id,fb_linked_fields_text(fields),HIST_ENTITY);hash_destroytab(fields);hash_destroytab(keys);
    }
    fb_tx_commit();strunzone(op);strunzone(key);
}
int fb_linked_command()
{
    if(argv(0)=="ftebroom_protect"){fb_linked_protect(argv(1),argv(2));return TRUE;}
    if(argv(0)!="ftebroom_linked")return FALSE;
    fb_linked_action(argv(1));return TRUE;
}
