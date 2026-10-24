// Copyright (C) 2026 Kristian Duske and ReyondBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Duplicate the original selection for each sample; never transform earlier copies.
// Additional patterns follow UltimateTrenchBroom ArrayTool placement rules.
float fb_array_ordinal(int index){if(!index)return 0;int ordinal=(index+1)/2;return ordinal*(index&1?1:-1);}
vector fb_array_pattern(int mode,int sample,int count,int axis,int seed,vector offset)
{
    vector u='1 0 0',v='0 1 0',direction='0 0 0';direction[axis]=1;
    if(axis==0){u='0 1 0';v='0 0 1';}else if(axis==1)v='0 0 1';
    int band=sample/count,index=sample%count;float spacing=cvar("ftebroom_array_spacing");
    if(mode==3){
        int centered=cvar("ftebroom_array_centered"),cross=cvar("ftebroom_array_cross"),lines=max(1,cvar("ftebroom_array_lines"));
        float step=(centered||cross)?fb_array_ordinal(index+1):index+1;
        vector drift=offset*(((centered||cross)&&!cvar("ftebroom_array_mirror_offsets"))?fabs(step):step);
        if(cross&&lines>1){float angle=M_PI*band/lines;return (u*cos(angle)+v*sin(angle))*step*spacing+drift;}
        return direction*step*spacing+drift+u*(centered?fb_array_ordinal(band):band)*spacing;
    }
    if(mode==4){float ringAngle=index*2*M_PI/count;return (u*cos(ringAngle)+v*sin(ringAngle))*spacing*(band+1)+offset*(band+1);}
    float randomAngle=fb_land_hash(sample,0,seed,0xa55i)*2*M_PI;
    float distance=sqrt(fb_land_hash(sample,1,seed,0xa55i))*max(1,cvar("ftebroom_array_radius"));
    return (u*cos(randomAngle)+v*sin(randomAngle))*distance;
}
void fb_array_facing(fb_affine_t *matrix,vector center,vector delta)
{
    if(!cvar("ftebroom_array_face_center")||vlen(delta)<.001)return;
    int side=bound(0,cvar("ftebroom_array_facing_side"),5);vector from='0 0 0';from[side/2]=side&1?-1:1;
    vector target=-normalize(delta),axis=crossproduct(from,target);float dot=bound(-1,from*target,1);
    if(vlen(axis)<.0001){if(dot>0)return;axis=crossproduct(from,side/2==2?'1 0 0':'0 0 1');}
    axis=normalize(axis);float angle=acos(dot);
    matrix->x=fb_affine_rotate_axis('1 0 0',axis,angle);matrix->y=fb_affine_rotate_axis('0 1 0',axis,angle);matrix->z=fb_affine_rotate_axis('0 0 1',axis,angle);
    matrix->translation=center+delta-fb_affine_direction(matrix,center);
}
void fb_array_matrix(int i,int count,vector center,fb_affine_t *result)
{
    int mode=cvar("ftebroom_array_mode"),axis=bound(0,cvar("ftebroom_array_axis"),2),seed=cvar("ftebroom_array_seed"),rotate=cvar("ftebroom_array_rotate");
    vector offset=[cvar("ftebroom_array_x"),cvar("ftebroom_array_y"),cvar("ftebroom_array_z")];
    vector pivot=[cvar("ftebroom_array_pivot_x"),cvar("ftebroom_array_pivot_y"),cvar("ftebroom_array_pivot_z")];float degrees=cvar("ftebroom_array_angle");
        fb_affine_t matrix={0};matrix.x='1 0 0';matrix.y='0 1 0';matrix.z='0 0 1';
        if(mode>=3){matrix.translation=fb_array_pattern(mode,i-1,count,axis,seed,offset);if(mode!=3)fb_array_facing(&matrix,center,matrix.translation);}
        else if(mode==0)matrix.translation=offset*i;
        else if(mode==2){for(int a=0;a<3;a++)matrix.translation[a]=(fb_land_hash(i,a,seed,0x43i)*2-1)*fabs(offset[a]);}
        else {
            vector direction='0 0 0';direction[axis]=1;float angle=degrees*i*M_PI/180;
            if(rotate){matrix.x=fb_affine_rotate_axis(matrix.x,direction,angle);matrix.y=fb_affine_rotate_axis(matrix.y,direction,angle);matrix.z=fb_affine_rotate_axis(matrix.z,direction,angle);matrix.translation=pivot-fb_affine_direction(&matrix,pivot);}
            else matrix.translation=pivot+fb_affine_rotate_axis(center-pivot,direction,angle)-center;
        }
    fb_affine_prepare(&matrix);*result=matrix;
}
int fb_array_apply()
{
    fb_tool_refresh();fb_document_tick();
    int copies=cvar("ftebroom_array_count"),mode=cvar("ftebroom_array_mode"),axis=bound(0,cvar("ftebroom_array_axis"),2),seed=cvar("ftebroom_array_seed");
    int perBand=copies;int bands=mode==3?bound(1,cvar("ftebroom_array_lines"),64):mode==4?bound(1,cvar("ftebroom_array_rings"),64):1;copies*=bands;
    int nb=selectedbrushcount,ne=fb_selected_entity_count;
    if(fb_vertex_scope||copies<1||copies>512||!nb&&!ne||(nb+ne)*copies>512){cvar_set("ftebroom_array_error","Select objects; use at most 512 resulting objects across all lines or rings.");return FALSE;}
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
        fb_affine_t matrix;fb_array_matrix(i,perBand,center,&matrix);
        valid=fb_affine_apply(&matrix,"Array placement");fb_transform_clear();
        if(made+selectedbrushcount>512||madeEntities+fb_selected_entity_count>512)valid=FALSE;
        if(valid){for(int b=0;b<selectedbrushcount;b++)created[made++]=selectedbrushes[b];for(int e=0;e<fb_selected_entity_count;e++)entities[madeEntities++]=fb_selected_entities[e];}
    }
    if(valid){history_restore_list(created,made,-1);for(int e=0;e<madeEntities;e++)fb_entity_select(entities[e],TRUE);fb_tx_commit();}else if(fb_tx_depth)fb_tx_cancel();
    fb_repeat_running=FALSE;fb_repeat_clear();memfree(original);memfree(created);memfree(entities);strunzone(state);fb_document_tick();
    cvar_set("ftebroom_array_error",valid?"":"Array was cancelled because a copy could not be created or its geometry was invalid.");return valid;
}
