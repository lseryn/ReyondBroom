// SPDX-License-Identifier: GPL-2.0-or-later
typedef struct {int kind,direction,speed;vector delta,center;fb_affine_t matrix;string mode;} fb_repeat_item_t;
fb_repeat_item_t fb_repeat_items[128];int fb_repeat_count,fb_repeat_running;
void fb_repeat_clear()
{
    if(fb_repeat_running)return;
    for(int i=0;i<fb_repeat_count;i++)strunzone(fb_repeat_items[i].mode);fb_repeat_count=0;cvar_set("ftebroom_repeat_count","0");
}
fb_repeat_item_t *fb_repeat_allocate(int kind)
{
    if(fb_repeat_running)return __NULL__;
    if(fb_repeat_count>=fb_repeat_items.length)fb_repeat_clear();
    fb_repeat_item_t *item=&fb_repeat_items[fb_repeat_count++];memfill8((__variant*)item,0,sizeof(fb_repeat_item_t));item->kind=kind;
    cvar_set("ftebroom_repeat_count",itos(fb_repeat_count));return item;
}
void fb_repeat_move(vector delta,int duplicate)
{
    fb_repeat_item_t *item=fb_repeat_allocate(duplicate?1:0);if(item)item->delta=delta;
}
void fb_repeat_affine(fb_affine_t *matrix,vector center)
{
    fb_repeat_item_t *item=fb_repeat_allocate(2);if(!item)return;
    item->matrix=*matrix;item->center=center;item->direction=fb_repeat_fixed_pivot;
}
void fb_repeat_texture(string mode,int direction,int speed)
{
    fb_repeat_item_t *item=fb_repeat_allocate(3);if(!item)return;
    item->mode=strzone(mode);item->direction=direction;item->speed=speed;
}
void fb_repeat_uv(vector row0,vector row1)
{
    fb_repeat_item_t *item=fb_repeat_allocate(4);if(!item)return;
    item->delta=row0;item->center=row1;
}
void fb_repeat_selection(history_t *marker)
{
    if(fb_repeat_running)return;
    if(marker->label=="Duplicate and Move" || marker->label=="Move" || marker->label=="Nudge" || marker->label=="Rotate" || marker->label=="Flip" || marker->label=="Scale" || marker->label=="Shear" || marker->label=="Texture Alignment" || marker->label=="UV editor")return;
    if(marker->statebefore!=marker->stateafter || !fb_selection_equal(marker->selection,marker->selectioncount,marker->afterselection,marker->aftercount))fb_repeat_clear();
}
void fb_repeat_run()
{
    if(!fb_repeat_count || fb_repeat_running || (!selectedbrushcount && !fb_selected_entity_count))return;
    fb_tool_refresh();fb_repeat_running=TRUE;fb_tx_begin("Repeat commands");int valid=TRUE;
    for(int i=0;i<fb_repeat_count && valid;i++) {
        fb_repeat_item_t *item=&fb_repeat_items[i];
        if(item->kind<2) {
            valid=fb_transform_capture();
            if(valid) {
                fb_transform_duplicate=item->kind==1;valid=fb_transform_valid(item->delta);
                if(valid)fb_transform_commit(item->delta);fb_transform_clear();
            }
        }else if(item->kind==2) {
            valid=fb_transform_capture();if(valid) {
                fb_affine_t matrix=item->matrix;vector center=fb_affine_center();
                if(!item->direction)matrix.translation+=center-item->center-fb_affine_direction(&matrix,center-item->center);
                valid=fb_affine_apply(&matrix,"Repeat transform");fb_transform_clear();
            }
        }else if(item->kind==3)fb_texture_key(item->mode,item->direction,item->speed);
        else {
            valid=fb_uv_begin();
            if(valid){fb_uv_matrix(item->delta,item->center);valid=fb_uv_editing;fb_uv_finish(valid);}
        }
    }
    if(valid && fb_tx_depth)fb_tx_commit();else fb_tx_cancel();fb_repeat_running=FALSE;
}
int fb_repeat_command()
{
    if(argv(0)!="ftebroom_repeat")return FALSE;
    if(argv(1)=="clear")fb_repeat_clear();else fb_repeat_run();return TRUE;
}
