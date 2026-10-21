// SPDX-License-Identifier: GPL-2.0-or-later
var float autocvar_ftebroom_show_brushes=1,autocvar_ftebroom_show_points=1,autocvar_ftebroom_show_models=1;
var float autocvar_ftebroom_show_entity_names=1,autocvar_ftebroom_show_entity_bounds=1,autocvar_ftebroom_show_group_bounds=1,autocvar_ftebroom_show_brush_entity_bounds=1;
var float autocvar_ftebroom_render_faces=0,autocvar_ftebroom_shade_faces=1,autocvar_ftebroom_show_edges=0;
var float autocvar_ftebroom_bounds_visible=1;
var float autocvar_ftebroom_hidden_tags=0,autocvar_ftebroom_entity_links=1;
var string autocvar_ftebroom_hidden_classes="";
int *fb_filter_tags;int fb_filter_tag_count;
hashtable fb_shader_tags,fb_shader_previews;
enum : int {FB_TAG_TRIGGER=1,FB_TAG_CLIP=2,FB_TAG_CAULK=4,FB_TAG_HINT=8,FB_TAG_DETAIL=16,FB_TAG_LIQUID=32,FB_TAG_TRANSLUCENT=64,FB_TAG_AREAPORTAL=128,FB_TAG_CLUSTERPORTAL=256};
void fb_filter_materials_load()
{
    if(fb_shader_tags)hash_destroytab(fb_shader_tags);if(fb_shader_previews)hash_destroytab(fb_shader_previews);
    fb_shader_tags=hash_createtab(512,EV_INTEGER);fb_shader_previews=hash_createtab(512,EV_STRING);
    filestream file=fopen("ftebroom-material-tags.txt",FILE_READ);if((float)file<0)return;
    string line;while((line=fgets(file)))if(tokenize(line)>=2){fb_shader_tags[argv(0)]=stoi(argv(1));fb_shader_previews[argv(0)]=argv(2);}
    fclose(file);fb_filter_epoch++;
}
int fb_filter_face_tags(brushface_t *face,int contents)
{
    string name=fb_material_key(face->shadername);int tags=0;
    if(fb_shader_tags)tags=fb_shader_tags[name];
    if(substring(name,0,7)=="common/") {
        if(strstrofs(name,"clip",7)>=0)tags|=FB_TAG_CLIP;
        if(strstrofs(name,"caulk",7)>=0)tags|=FB_TAG_CAULK;
        if(substring(name,7,4)=="hint")tags|=FB_TAG_HINT;
    }
    if(contents&134217728i)tags|=FB_TAG_DETAIL;
    return tags;
}
void fb_filter_prepare()
{
    static int epoch=-1,materials=-1;static string previous="";
    string signature=sprintf("%g %g %g %g %g %g",autocvar_ftebroom_show_brushes,autocvar_ftebroom_show_points,autocvar_ftebroom_show_models,autocvar_ftebroom_render_faces,autocvar_ftebroom_shade_faces,autocvar_ftebroom_show_edges);
    signature=strcat(signature,sprintf(" %g %g %g %g %g %g %i",autocvar_ftebroom_hidden_tags,autocvar_ftebroom_entity_links,autocvar_ftebroom_show_entity_names,autocvar_ftebroom_show_entity_bounds,autocvar_ftebroom_show_group_bounds,autocvar_ftebroom_show_brush_entity_bounds,fb_open_group)," ",autocvar_ftebroom_hidden_classes,ftos(autocvar_ftebroom_bounds_visible));
    signature=strcat(signature," fog=",cvar_string("r_fog_enabled"));
    if(signature!=previous){strunzone(previous);previous=strzone(signature);fb_filter_epoch++;}
    int materialEpoch=cvar("ftebroom_material_tag_epoch");
    if(materialEpoch!=materials){materials=materialEpoch;fb_filter_materials_load();epoch=-1;}
    if(epoch==fb_grid_geometry_epoch)return;epoch=fb_grid_geometry_epoch;
    memfree(fb_filter_tags);fb_filter_tag_count=fb_node_count;fb_filter_tags=memalloc(fb_node_count*sizeof(int));
    static brushface_t faces[64];
    for(int n=2;n<fb_node_count;n++) {
        int tags=0;
        if(fb_nodes[n].kind==FB_NODE_BRUSH) {
            int contents,count=brush_get(fb_nodes[n].model,fb_nodes[n].id,faces,64,&contents);
            for(int f=0;f<min(count,64);f++)tags|=fb_filter_face_tags(&faces[f],contents);
        }
        for(int parent=n;parent>=2;parent=fb_nodes[parent].parent)if(fb_nodes[parent].kind==FB_NODE_ENTITY)
            if(substring(fb_nodes[parent].fields["classname"],0,8)=="trigger_")tags|=FB_TAG_TRIGGER;
        fb_filter_tags[n]=tags;
    }
    fb_filter_epoch++;
}
int fb_filter_allowed(int node)
{
    if(node<0 || node>=fb_node_count)return TRUE;
    if(fb_nodes[node].kind>=FB_NODE_BRUSH && !autocvar_ftebroom_show_brushes)return FALSE;
    if(fb_nodes[node].kind==FB_NODE_ENTITY) {
        if(strstrofs(autocvar_ftebroom_hidden_classes,strcat("|",fb_nodes[node].fields["classname"],"|"),0)>=0)return FALSE;
        if(substring(fb_nodes[node].fields["model"],0,1)!="*" && !autocvar_ftebroom_show_points)return FALSE;
    }
    if(node<fb_filter_tag_count)if(fb_filter_tags[node]&(int)autocvar_ftebroom_hidden_tags)return FALSE;
    return TRUE;
}
int fb_filter_custom(int node)
{
    if(node<0 || node>=fb_filter_tag_count)return FALSE;
    return autocvar_ftebroom_render_faces!=0 || !autocvar_ftebroom_shade_faces || (fb_filter_tags[node] & (FB_TAG_TRIGGER|FB_TAG_CLIP|FB_TAG_CAULK|FB_TAG_HINT|FB_TAG_TRANSLUCENT|FB_TAG_AREAPORTAL|FB_TAG_CLUSTERPORTAL));
}
int fb_render_visible(int model,int id)
{
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].model==model && fb_nodes[n].id==id)return fb_pick_allowed(n,FB_PICK_LOCKED);
    return FALSE;
}
void fb_filter_patch(int model,int id)
{
    patchinfo_t info;int total=patch_getmesh(model,id,__NULL__,0,&info);
    if(total<1 || total>65536)return;
    if(info.cpwidth<2 || info.cpheight<2 || info.cpwidth*info.cpheight!=total)return;
    patchvert_t *mesh=memalloc(total*sizeof(patchvert_t));
    if(patch_getmesh(model,id,mesh,total,&info)!=total){memfree(mesh);return;}
    string shader="ftebroom/flatface";
    if(!autocvar_ftebroom_render_faces) {
        string material=fb_material_key(info.shadername),preview="";
        if(fb_shader_previews)preview=fb_shader_previews[material];if(preview=="")preview=strcat("textures/",material);
        shader=strcat("ftebroom/filtered/",material);
        shaderforname(shader,strcat("{\ncull none\n{\nmap ",fb_map_quote(preview),"\nrgbgen vertex\nalphagen vertex\nblendfunc blend\n}\n}"));
    }
    for(int y=0;y<info.cpheight-1;y++)for(int x=0;x<info.cpwidth-1;x++) {
        int at=y*info.cpwidth+x;int corners[4];corners[0]=at;corners[1]=at+1;corners[2]=at+info.cpwidth+1;corners[3]=at+info.cpwidth;
        vector normal=normalize(crossproduct(mesh[corners[1]].xyz-mesh[at].xyz,mesh[corners[3]].xyz-mesh[at].xyz));
        float shade=1;if(autocvar_ftebroom_shade_faces)shade=0.6+0.4*fabs(normal*normalize('0.3 -0.5 1'));
        vector color='0.65 0.68 0.72'*shade;if(!autocvar_ftebroom_render_faces)color='1 1 1'*shade;
        R_BeginPolygon(shader,3);
        for(int c=0;c<4;c++){patchvert_t v=mesh[corners[c]];R_PolygonVertex(v.xyz,[v.s,v.t,0],color,1);}
        R_EndPolygon();
    }
    memfree(mesh);
}
void fb_filter_draw()
{
    if(cvar("ca_brush_view"))return;
    shaderforname("ftebroom/flatface","{\ncull none\n{\nmap $whiteimage\nrgbgen vertex\nalphagen vertex\nblendfunc blend\n}\n}");
    static brushface_t faces[64];static vector points[64];
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind>=FB_NODE_BRUSH && fb_pick_allowed(n,FB_PICK_LOCKED)) {
        fb_node_t node=fb_nodes[n];if(fb_preview_replaces(node.model,node.id))continue;
        int custom=fb_filter_custom(n);
        if(custom && node.kind==FB_NODE_BRUSH) {
            int contents,count=brush_get(node.model,node.id,faces,64,&contents);
            if(autocvar_ftebroom_render_faces!=2)for(int f=0;f<min(count,64);f++) {
                brushface_t face=faces[f];int tags=fb_filter_face_tags(&face,contents);if(fb_filter_tags[n]&FB_TAG_TRIGGER)tags|=FB_TAG_TRIGGER;
                float alpha=1;if(tags&(FB_TAG_TRIGGER|FB_TAG_CLIP|FB_TAG_CAULK|FB_TAG_HINT|FB_TAG_TRANSLUCENT|FB_TAG_AREAPORTAL|FB_TAG_CLUSTERPORTAL))alpha=0.35;
                float shade=1;if(autocvar_ftebroom_shade_faces)shade=0.6+0.4*fabs(face.planenormal*normalize('0.3 -0.5 1'));
                vector color='0.65 0.68 0.72'*shade;string shader="ftebroom/flatface";vector size='1 1 1';
                if(!autocvar_ftebroom_render_faces) {
                    string material=fb_material_key(face.shadername),preview="";if(fb_shader_previews)preview=fb_shader_previews[material];if(preview=="")preview=strcat("textures/",material);
                    shader=strcat("ftebroom/filtered/",material);shaderforname(shader,strcat("{\ncull none\n{\nmap ",fb_map_quote(preview),"\nrgbgen vertex\nalphagen vertex\nblendfunc blend\n}\n}"));
                    size=drawgetimagesize(shader);size_x=max(1,size_x);size_y=max(1,size_y);color='1 1 1'*shade;
                }
                int vertices=brush_getfacepoints(node.model,node.id,f+1,points,64);if(vertices<3||vertices>64)continue;
                R_BeginPolygon(shader,3);for(int p=0;p<vertices;p++)R_PolygonVertex(points[p],[(points[p]*face.sdir+face.sbias)/size_x,(points[p]*face.tdir+face.tbias)/size_y,0],color,alpha);R_EndPolygon();
            }
        }else if(custom && node.kind==FB_NODE_PATCH && autocvar_ftebroom_render_faces!=2)fb_filter_patch(node.model,node.id);
        if(autocvar_ftebroom_render_faces==2 || autocvar_ftebroom_show_edges)DrawEngineBrushWireframe(node.model,node.id);
    }
}
string fb_structural_material(string material)
{
    brushface_t face={0};face.shadername=material;int tags=fb_filter_face_tags(&face,0);
    string key=fb_material_key(material);
    if(!(tags&(FB_TAG_CLIP|FB_TAG_CAULK|FB_TAG_HINT)) && key!="common/trigger")return material;
    string replacement=cvar_string("ca_newbrushtexture");face.shadername=replacement;tags=fb_filter_face_tags(&face,0);
    if(tags&(FB_TAG_CLIP|FB_TAG_CAULK|FB_TAG_HINT) || fb_material_key(replacement)=="common/trigger")replacement="ftebroom/grid";
    return replacement;
}
void fb_filter_tag(string type,int enabled)
{
    if(type!="trigger" && type!="clip" && type!="caulk" && type!="hint" && type!="detail")return;
    string tag=strzone(type);fb_tool_refresh();fb_document_tick();
    if(tag=="trigger") {
        if(enabled){fb_tx_begin("Create trigger");fb_entity_create("trigger_multiple",TRUE,'0 0 0');cvar_set("ca_newbrushtexture","common/trigger");fb_material_edit("material",0);fb_tx_commit();}
        else fb_organize_action("structural",0,"");strunzone(tag);return;
    }
    fb_tx_begin("Change brush tag");static brushface_t faces[64];
    for(int b=0;b<selectedbrushcount;b++) {
        selbrush_t item=selectedbrushes[b];int contents,count=brush_get(item.model,item.id,faces,64,&contents);if(count<4||count>64)continue;
        if(tag=="detail") {if(enabled)contents|=134217728i;else contents&=~134217728i;}
        else for(int f=0;f<count;f++)if(selbrush_whole(&item)||selbrush_face(&item,f)) {
            if(enabled)faces[f].shadername=strcat("common/",tag);
            else {int bits=fb_filter_face_tags(&faces[f],contents),bit=tag=="clip"?FB_TAG_CLIP:(tag=="caulk"?FB_TAG_CAULK:FB_TAG_HINT);if(bits&bit)faces[f].shadername=fb_structural_material(faces[f].shadername);}
        }
        brush_history_edit(item.model,item.id,faces,count,contents);
    }
    fb_tx_commit();strunzone(tag);
}
