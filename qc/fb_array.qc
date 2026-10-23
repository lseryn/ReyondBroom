// SPDX-License-Identifier: GPL-2.0-or-later
// Duplicate the original selection for each sample; never transform earlier copies.
int fb_array_apply()
{
    fb_tool_refresh();fb_document_tick();
    int copies=cvar("ftebroom_array_count"),mode=cvar("ftebroom_array_mode"),axis=bound(0,cvar("ftebroom_array_axis"),2),seed=cvar("ftebroom_array_seed");
    int nb=selectedbrushcount,ne=fb_selected_entity_count;
    if(fb_vertex_scope||copies<1||copies>64||!nb&&!ne||(nb+ne)*copies>512){cvar_set("ftebroom_array_error","Select objects; use 1-64 copies and at most 512 resulting objects.");return FALSE;}
    selbrush_t *original=memalloc(nb*sizeof(selbrush_t));memcpy(original,selectedbrushes,nb*sizeof(selbrush_t));string state=strzone(fb_selection_state());
    selbrush_t *created=memalloc(512*sizeof(selbrush_t));int *entities=memalloc(512*sizeof(int));int made=0,madeEntities=0;
    vector offset=[cvar("ftebroom_array_x"),cvar("ftebroom_array_y"),cvar("ftebroom_array_z")];
    vector pivot=[cvar("ftebroom_array_pivot_x"),cvar("ftebroom_array_pivot_y"),cvar("ftebroom_array_pivot_z")];
    float degrees=cvar("ftebroom_array_angle");int rotate=cvar("ftebroom_array_rotate");
    fb_repeat_running=TRUE;fb_tx_begin("Array");int valid=TRUE;
    for(int i=1;i<=copies&&valid;i++) {
        history_restore_list(original,nb,-1);fb_selection_restore_state(state);fb_document_tick();
        valid=fb_transform_capture();if(!valid)break;
        vector center=fb_affine_center();fb_transform_duplicate=TRUE;fb_transform_commit('0 0 0');fb_transform_clear();
        if(!fb_tx_depth){valid=FALSE;break;}fb_document_tick();valid=fb_transform_capture();if(!valid)break;
        fb_affine_t matrix={0};matrix.x='1 0 0';matrix.y='0 1 0';matrix.z='0 0 1';
        if(mode==0)matrix.translation=offset*i;
        else if(mode==2){for(int a=0;a<3;a++)matrix.translation[a]=(fb_land_hash(i,a,seed,0x43i)*2-1)*fabs(offset[a]);}
        else {
            vector direction='0 0 0';direction[axis]=1;float angle=degrees*i*M_PI/180;
            if(rotate){matrix.x=fb_affine_rotate_axis(matrix.x,direction,angle);matrix.y=fb_affine_rotate_axis(matrix.y,direction,angle);matrix.z=fb_affine_rotate_axis(matrix.z,direction,angle);matrix.translation=pivot-fb_affine_direction(&matrix,pivot);}
            else matrix.translation=pivot+fb_affine_rotate_axis(center-pivot,direction,angle)-center;
        }
        valid=fb_affine_apply(&matrix,"Array placement");fb_transform_clear();
        if(made+selectedbrushcount>512||madeEntities+fb_selected_entity_count>512)valid=FALSE;
        if(valid){for(int b=0;b<selectedbrushcount;b++)created[made++]=selectedbrushes[b];for(int e=0;e<fb_selected_entity_count;e++)entities[madeEntities++]=fb_selected_entities[e];}
    }
    if(valid){history_restore_list(created,made,-1);for(int e=0;e<madeEntities;e++)fb_entity_select(entities[e],TRUE);fb_tx_commit();}else if(fb_tx_depth)fb_tx_cancel();
    fb_repeat_running=FALSE;fb_repeat_clear();memfree(original);memfree(created);memfree(entities);strunzone(state);fb_document_tick();
    cvar_set("ftebroom_array_error",valid?"":"Array was cancelled because a copy could not be created or its geometry was invalid.");return valid;
}
int fb_array_command(){if(argv(0)!="ftebroom_array")return FALSE;fb_array_apply();return TRUE;}
