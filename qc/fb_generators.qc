// SPDX-License-Identifier: GPL-3.0-or-later
// Preview geometry owns copies and never leaves the document in a pending transaction.
typedef struct {fb_poly_t poly;patchinfo_t info;patchvert_t *points;} fb_generator_preview_t;
fb_generator_preview_t *fb_generator_items;int fb_generator_count;
selbrush_t *fb_generator_original;int fb_generator_original_count,fb_generator_history,fb_generator_selection,fb_generator_geometry;
void fb_generator_clear()
{
    for(int i=0;i<fb_generator_count;i++){fb_poly_free(&fb_generator_items[i].poly);if(fb_generator_items[i].points)strunzone(fb_generator_items[i].info.shadername);memfree(fb_generator_items[i].points);}
    memfree(fb_generator_items);fb_generator_items=__NULL__;fb_generator_count=0;memfree(fb_generator_original);fb_generator_original=__NULL__;fb_generator_original_count=0;
    fb_visibility_epoch++;cvar_set("ftebroom_generator_valid","0");
}
int fb_generator_replaces(int model,int id)
{
    if(history!=fb_generator_history || fb_selection_epoch!=fb_generator_selection || fb_grid_geometry_epoch!=fb_generator_geometry)return FALSE;
    for(int i=0;i<fb_generator_original_count;i++)if(fb_generator_original[i].model==model&&fb_generator_original[i].id==id)return TRUE;return FALSE;
}
void fb_generator_draw()
{
    if(history!=fb_generator_history || fb_selection_epoch!=fb_generator_selection || fb_grid_geometry_epoch!=fb_generator_geometry){if(fb_generator_count)fb_generator_clear();return;}
    for(int i=0;i<fb_generator_count;i++) {
        fb_generator_preview_t *item=&fb_generator_items[i];
        if(item->points)DrawQCPatchTextured(item->points,item->info,'1 1 1',1);
        else {static brushface_t faces[64];for(int f=0;f<item->poly.nf;f++)faces[f]=item->poly.faces[f].attr;
            if(!cvar("ca_brush_view"))DrawQCBrushTextured(faces,item->poly.nf,'1 1 1',1);
            DrawQCBrushWireframe(faces,item->poly.nf,"chop",'1 0.8 0',1);
        }
    }
}
int fb_generator_command()
{
    if(argv(0)!="ftebroom_generator")return FALSE;
    string mode=argv(1),kind=argv(2);fb_generator_clear();
    if(mode=="cancel")return TRUE;
    fb_tx_begin(kind=="bevel"?"Bevel":"Generate terrain");int valid=kind=="bevel"?fb_bevel_apply():fb_land_apply();
    if(mode=="apply") {if(valid)fb_tx_commit();else fb_tx_cancel();fb_vertex_rebuild();}
    else {
        if(valid){fb_generator_count=selectedbrushcount;fb_generator_items=memalloc(fb_generator_count*sizeof(fb_generator_preview_t));
            for(int b=0;b<fb_generator_count&&valid;b++) {fb_generator_preview_t *item=&fb_generator_items[b];int model=selectedbrushes[b].model,id=selectedbrushes[b].id;
                int count=patch_getcp(model,id,__NULL__,0,&item->info);
                if(count){item->points=memalloc(count*sizeof(patchvert_t));patch_getcp(model,id,item->points,count,&item->info);item->info.shadername=strzone(item->info.shadername);patchvert_t *mesh=fb_patch_preview_mesh(item->points,&item->info);memfree(item->points);item->points=mesh;}
                else valid=fb_poly_from_brush(model,id,&item->poly);
            }
        }
        fb_tx_cancel();
        if(valid){fb_generator_original_count=selectedbrushcount;fb_generator_original=memalloc(selectedbrushcount*sizeof(selbrush_t));memcpy(fb_generator_original,selectedbrushes,selectedbrushcount*sizeof(selbrush_t));fb_generator_history=history;fb_generator_selection=fb_selection_epoch;fb_generator_geometry=fb_grid_geometry_epoch;cvar_set("ftebroom_generator_valid","1");}
        else fb_generator_clear();
    }
    cvar_set("ftebroom_generator_error",valid?"":fb_geom_error);fb_document_tick();return TRUE;
}
