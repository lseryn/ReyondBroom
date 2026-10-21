// SPDX-License-Identifier: GPL-2.0-or-later
int fb_export_included(int node)
{
    int layer=fb_nodes[node].layer;
    if(layer==1)return fb_nodes[0].fields["_tb_layer_omit_from_export"]!="1";
    return fb_nodes[layer].fields["_tb_layer_omit_from_export"]!="1";
}
int fb_export_owner(int node)
{
    for(int p=fb_nodes[node].parent,steps=0;p>=2 && steps++<fb_node_count;p=fb_nodes[p].parent)
        if(fb_nodes[p].kind==FB_NODE_ENTITY)return p;
    return 0;
}
int fb_export_map()
{
    cvar_set("ftebroom_export_status","-1");fb_document_tick();filestream file=fopen("export-map.map",FILE_WRITE);if((float)file<0)return FALSE;
    int success=TRUE;
    for(int e=0;e<fb_node_count;e++) {
        if(e && (fb_nodes[e].kind!=FB_NODE_ENTITY || !fb_export_included(e)))continue;
        fputs(file,"{\n");hashtable fields=(hashtable)fb_nodes[e].fields;
        for(int k=0;;k++) {
            string key=hash_getkey(fields,k);if isnull(key)break;
            if(substring(key,0,4)=="_tb_")continue;
            if(key=="model" && substring(fields[key],0,1)=="*")continue;
            fputs(file,strcat(fb_map_quote(key)," ",fb_map_quote(fields[key]),"\n"));
        }
        for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind>=FB_NODE_BRUSH && fb_export_included(n) && fb_export_owner(n)==e)
            if(!fb_clip_write_geometry(file,fb_nodes[n].model,fb_nodes[n].id))success=FALSE;
        fputs(file,"}\n");
    }
    fclose(file);cvar_set("ftebroom_export_status",success?"1":"-1");return success;
}
