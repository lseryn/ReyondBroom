// SPDX-License-Identifier: GPL-3.0-or-later
// Array previews own geometry; document history is only used by Apply.
string fb_array_keys[]={"mode","count","axis","seed","x","y","z","pivot_x","pivot_y","pivot_z","angle","rotate","lines","rings","facing_side","spacing","radius","centered","cross","mirror_offsets","face_center"};
typedef struct {float values[21];} fb_array_state_t;
fb_array_state_t fb_array_state;
fb_array_state_t *fb_array_undo;
fb_array_state_t *fb_array_redo;
int fb_array_undo_count,fb_array_redo_count,fb_array_active,fb_array_history,fb_array_selection,fb_array_epoch;
typedef struct {int id;fb_affine_t matrix;vector corners[8];} fb_array_entity_t;
fb_array_entity_t *fb_array_entities;int fb_array_entity_count;
void fb_array_clear()
{
    if(fb_array_active)fb_generator_clear();fb_array_active=FALSE;
    memfree(fb_array_entities);fb_array_entities=__NULL__;fb_array_entity_count=0;
    memfree(fb_array_undo);memfree(fb_array_redo);fb_array_undo=fb_array_redo=__NULL__;fb_array_undo_count=fb_array_redo_count=0;
    cvar_set("ftebroom_array_valid","0");cvar_set("ftebroom_array_active","0");
}
void fb_array_write_state(){for(int i=0;i<21;i++)cvar_set(strcat("ftebroom_array_",fb_array_keys[i]),ftos(fb_array_state.values[i]));}
void fb_array_read_state(fb_array_state_t *state){for(int i=0;i<21;i++)state->values[i]=cvar(strcat("ftebroom_array_",fb_array_keys[i]));}
void fb_array_save_state()
{
    if(!fb_array_undo)fb_array_undo=memalloc(128*sizeof(fb_array_state_t));
    if(fb_array_undo_count==128){for(int i=1;i<128;i++)fb_array_undo[i-1]=fb_array_undo[i];fb_array_undo_count--;}
    fb_array_undo[fb_array_undo_count++]=fb_array_state;fb_array_redo_count=0;
}
int fb_array_preview()
{
    fb_generator_clear();memfree(fb_array_entities);fb_array_entities=__NULL__;fb_array_entity_count=0;cvar_set("ftebroom_array_valid","0");
    fb_array_history=history;fb_array_selection=fb_selection_epoch;fb_array_epoch=fb_grid_geometry_epoch;
    if(!fb_transform_capture()){cvar_set("ftebroom_array_error","Select whole objects before previewing Array.");return FALSE;}
    int perBand=cvar("ftebroom_array_count"),mode=cvar("ftebroom_array_mode");
    int bands=mode==3?bound(1,cvar("ftebroom_array_lines"),64):mode==4?bound(1,cvar("ftebroom_array_rings"),64):1,copies=perBand*bands;
    if(fb_vertex_scope||copies<1||copies>512||fb_transform_count*copies>512){fb_transform_clear();cvar_set("ftebroom_array_error","Array is limited to 512 resulting objects.");return FALSE;}
    // Bound tessellated patch memory independently of the object-count limit.
    int vertices=0;
    for(int sourceIndex=0;sourceIndex<fb_transform_count;sourceIndex++){
        fb_transform_item_t *item=&fb_transform_items[sourceIndex];
        if(item->kind==FB_NODE_PATCH)vertices+=((item->patch.cpwidth-1)*4+1)*((item->patch.cpheight-1)*4+1);
        else vertices+=item->kind==FB_NODE_BRUSH?item->count*4:8;
    }
    if(vertices*copies>262144){fb_transform_clear();cvar_set("ftebroom_array_error","Preview exceeds 262144 vertices. Reduce copies or patch complexity.");return FALSE;}
    fb_generator_items=memalloc(512*sizeof(fb_generator_preview_t));fb_array_entities=memalloc(512*sizeof(fb_array_entity_t));
    vector center=fb_affine_center();int valid=TRUE;
    for(int i=1;i<=copies&&valid;i++){
        fb_affine_t matrix;fb_array_matrix(i,perBand,center,&matrix);valid=fb_affine_valid(&matrix);
        for(int b=0;b<fb_transform_count&&valid;b++){
            fb_transform_item_t *source=&fb_transform_items[b];
            if(source->kind==FB_NODE_ENTITY){
                fb_array_entity_t *entityCopy=&fb_array_entities[fb_array_entity_count++];entityCopy->id=source->id;entityCopy->matrix=matrix;
                for(int c=0;c<8;c++){vector point='0 0 0';for(int a=0;a<3;a++)point[a]=(c&(1i<<a))?source->high[a]:source->low[a];entityCopy->corners[c]=fb_affine_point(&matrix,point);}
            }else{
                fb_generator_preview_t *out=&fb_generator_items[fb_generator_count++];
                if(source->kind==FB_NODE_BRUSH){brushface_t *faces=memalloc(source->count*sizeof(brushface_t));memcpy(faces,source->faces,source->count*sizeof(brushface_t));for(int f=0;f<source->count;f++)fb_affine_face(&matrix,&faces[f],cvar("ftebroom_texture_lock"));valid=fb_poly_from_faces(faces,source->count,&out->poly);memfree(faces);}
                else{out->info=source->patch;out->info.shadername=strzone(source->patch.shadername);out->points=fb_patch_preview_mesh(source->points,&out->info);int points=out->info.cpwidth*out->info.cpheight;for(int p=0;p<points;p++)out->points[p].xyz=fb_affine_point(&matrix,out->points[p].xyz);}
            }
        }
    }
    fb_transform_clear();fb_array_history=history;fb_array_selection=fb_selection_epoch;fb_array_epoch=fb_grid_geometry_epoch;
    if(valid){fb_generator_hide_original=FALSE;fb_generator_history=history;fb_generator_selection=fb_selection_epoch;fb_generator_geometry=fb_grid_geometry_epoch;cvar_set("ftebroom_generator_valid","1");}
    else{fb_generator_clear();memfree(fb_array_entities);fb_array_entities=__NULL__;fb_array_entity_count=0;}
    cvar_set("ftebroom_array_valid",itos(valid));cvar_set("ftebroom_array_error",valid?"":"Array contains invalid geometry.");return valid;
}
void fb_array_draw()
{
    if(!fb_array_active)return;
    if(history!=fb_array_history||fb_selection_epoch!=fb_array_selection||fb_grid_geometry_epoch!=fb_array_epoch){fb_array_clear();cvar_set("ftebroom_array_error","Selection or document changed. Change settings to refresh Array.");return;}
    for(int i=0;i<fb_array_entity_count;i++){
        fb_array_entity_t *copy=&fb_array_entities[i];
        for(int c=0;c<8;c++)for(int a=0;a<3;a++)if(!(c&(1i<<a)))fb_visual_line(copy->corners[c],copy->corners[c|(1i<<a)],'1 .8 0',1,1,FALSE);
        if(!cvar("ca_brush_view"))fb_entity_draw_instance(copy->id,copy->matrix.translation,copy->matrix.x,copy->matrix.y,copy->matrix.z);
    }
}
int fb_array_command()
{
    string cmd=argv(0),op=argv(1);
    if(fb_array_active){
        if(cmd=="ftebroom_undo"){
            if(fb_array_undo_count){if(!fb_array_redo)fb_array_redo=memalloc(128*sizeof(fb_array_state_t));fb_array_redo[fb_array_redo_count++]=fb_array_state;fb_array_state=fb_array_undo[--fb_array_undo_count];fb_array_write_state();fb_array_preview();}return TRUE;
        }
        if(cmd=="ftebroom_redo"){
            if(fb_array_redo_count){fb_array_undo[fb_array_undo_count++]=fb_array_state;fb_array_state=fb_array_redo[--fb_array_redo_count];fb_array_write_state();fb_array_preview();}return TRUE;
        }
    }
    if(cmd!="ftebroom_array")return FALSE;
    if(op=="cancel"){fb_array_clear();return TRUE;}
    if(op=="preview"){
        if(!fb_array_active){fb_tool_deactivate();fb_array_active=TRUE;cvar_set("ftebroom_array_active","1");}else fb_array_save_state();
        fb_array_read_state(&fb_array_state);fb_array_preview();return TRUE;
    }
    if(op=="apply"){
        if(!fb_array_active||history!=fb_array_history||fb_selection_epoch!=fb_array_selection||fb_grid_geometry_epoch!=fb_array_epoch){fb_array_clear();cvar_set("ftebroom_array_error","Selection or document changed. Refresh the preview before Apply.");return TRUE;}
        if(!fb_array_preview())return TRUE;
    }
    fb_array_clear();fb_array_apply();return TRUE;
}
