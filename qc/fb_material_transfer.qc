// SPDX-License-Identifier: GPL-2.0-or-later
brushface_t fb_transfer_source;
int fb_transfer_active,fb_transfer_mode,fb_transfer_lastmodel,fb_transfer_lastid,fb_transfer_lastface;
void fb_transfer_finish(int commit)
{
    if(!fb_transfer_active) return;
    fb_transfer_active=FALSE;
    if(commit) fb_tx_commit();else fb_tx_cancel();
    strunzone(fb_transfer_source.shadername);fb_transfer_source.shadername="";
}
void fb_transfer_attributes(brushface_t *source,brushface_t *target,int mode)
{
    if(mode==2) {target->shadername=source->shadername;return;}
    vector normal=target->planenormal;float distance=target->planedist;
    brushface_t result=*source;result.planenormal=normal;result.planedist=distance;
    if(mode==1) {
        vector axis=crossproduct(source->planenormal,normal);
        float length=vlen(axis),cosine=bound(-1,source->planenormal*normal,1);
        vector anchor=normal*distance;
        if(length>0.000001) {
            anchor=(crossproduct(normal,axis)*source->planedist+crossproduct(axis,source->planenormal)*distance)/(axis*axis);
            axis=axis/length;
        } else {
            axis=normalize(source->sdir-source->planenormal*(source->sdir*source->planenormal));
            if(vlen(axis)<0.01) axis=normalize(crossproduct(source->planenormal,'0 0 1'));
        }
        float angle=atan2(length,cosine);
        result.sdir=fb_uv_rotate(source->sdir,axis,angle);result.tdir=fb_uv_rotate(source->tdir,axis,angle);
        result.sbias=source->sdir*anchor+source->sbias-result.sdir*anchor;
        result.tbias=source->tdir*anchor+source->tbias-result.tdir*anchor;
    }
    *target=result;
}
void fb_transfer_at(vector pixel,int allFaces)
{
    if(!fb_transfer_active || !fb_pick(pixel)) return;
    fb_hit_t hit=fb_hits[0];if(hit.kind!=FB_HIT_BRUSH || hit.face<1) return;
    if(hit.model==fb_transfer_lastmodel && hit.id==fb_transfer_lastid && hit.face==fb_transfer_lastface && !allFaces) return;
    static brushface_t faces[128];int contents;
    int count=brush_get(hit.model,hit.id,faces,128,&contents);if(count<4 || count>128 || hit.face>count) return;
    int changed=FALSE;
    for(int f=0;f<count;f++) if(allFaces || f==hit.face-1) {
        if(brushface_isselected(hit.model,hit.id,f+1)) continue;
        fb_transfer_attributes(&fb_transfer_source,&faces[f],fb_transfer_mode);changed=TRUE;
    }
    if(!changed) return;
    int id=brush_history_edit(hit.model,hit.id,faces,count,contents);
    string material=strzone(faces[hit.face-1].shadername);
    strunzone(fb_transfer_source.shadername);fb_transfer_source=faces[hit.face-1];fb_transfer_source.shadername=material;
    fb_transfer_lastmodel=hit.model;fb_transfer_lastid=id;fb_transfer_lastface=hit.face;
}
int fb_transfer_begin(vector pixel,int rotate,int materialOnly)
{
    if(fb_faces_count()!=1 || cvar("ca_brush_view")) return FALSE;
    if(!fb_pick(pixel)) return FALSE;
    fb_hit_t target=fb_hits[0];
    if(target.kind!=FB_HIT_BRUSH) return FALSE;
    if(brushface_isselected(target.model,target.id,target.face)) return FALSE;
    static brushface_t faces[128];int found=FALSE;
    for(int b=0;b<selectedbrushcount;b++) {
        int count=brush_get(selectedbrushes[b].model,selectedbrushes[b].id,faces,128,__NULL__);
        for(int f=0;f<min(count,128);f++) if(selbrush_face(&selectedbrushes[b],f)) {
            fb_transfer_source=faces[f];fb_transfer_source.shadername=strzone(faces[f].shadername);found=TRUE;break;
        }
        if(found) break;
    }
    if(!found) return FALSE;
    fb_transfer_mode=rotate?1:0;if(materialOnly) fb_transfer_mode=2;
    fb_transfer_lastid=0;fb_transfer_lastface=0;fb_transfer_active=TRUE;fb_tx_begin("Transfer Material");
    fb_transfer_at(pixel,FALSE);return TRUE;
}
