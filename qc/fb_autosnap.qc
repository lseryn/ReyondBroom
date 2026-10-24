// SPDX-License-Identifier: GPL-3.0-or-later
// Round edited brush vertices inside the outer transaction, before linked copies.
// Selection-only transactions and patches are deliberately untouched.
void fb_autosnap_before_commit()
{
    if(!cvar("ftebroom_auto_integer_snap"))return;
    int changed=FALSE;
    for(int i=fb_tx_start+1;i<history;i++){history_t *record=&historyring[i&(historyring_length-1)];if(record->kind==HIST_GEOMETRY&&record->brushdata){changed=TRUE;break;}}
    if(!changed)return;
    int count=selectedbrushcount;selbrush_t *selection=memalloc(count*sizeof(selbrush_t));memcpy(selection,selectedbrushes,count*sizeof(selbrush_t));int skipped=0;
    brushface_t *attrs=memalloc(64*sizeof(brushface_t));brushface_t *faces=memalloc(64*sizeof(brushface_t));
    for(int b=0;b<count;b++) {
        fb_poly_t source={0};if(!fb_poly_from_brush(selection[b].model,selection[b].id,&source))continue;
        vector *points=memalloc(source.nv*sizeof(vector));int fractional=FALSE;
        for(int v=0;v<source.nv;v++)for(int axis=0;axis<3;axis++){points[v][axis]=rint(source.vertices[v][axis]);if(fabs(points[v][axis]-source.vertices[v][axis])>.0001)fractional=TRUE;}
        if(fractional){fb_poly_t result={0};
            if(fb_hull(points,source.nv,&result)){
                for(int f=0;f<source.nf;f++)attrs[f]=source.faces[f].attr;fb_land_attributes(&result,attrs,source.nf);fb_csg_materials(&result,attrs,source.nf);
                for(int f=0;f<result.nf;f++)faces[f]=result.faces[f].attr;int contents;brush_get(selection[b].model,selection[b].id,__NULL__,0,&contents);
                int id=brush_history_edit(selection[b].model,selection[b].id,faces,result.nf,contents);
                // A reconstructed hull can reorder faces. Keep a valid whole-brush selection.
                if(id)brush_selected(selection[b].model,id,-1,TRUE);else skipped++;
            }else skipped++;
            fb_poly_free(&result);
        }
        memfree(points);fb_poly_free(&source);
    }
    memfree(attrs);memfree(faces);memfree(selection);
    if(skipped)cvar_set("ftebroom_selection_status","Auto Integer Snap skipped brushes that would collapse");
}
