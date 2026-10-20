// SPDX-License-Identifier: GPL-2.0-or-later
int fb_pick_test_ids[3],fb_pick_test_patch;
void fb_pick_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_PICK_PASS ":"FTEBROOM_PICK_FAIL ",name,"\n"));
}
float fb_pick_testcommand()
{
    if(argv(0)!="ftebroom_test_pick") return FALSE;
    if(!cvar("ftebroom_skip_setup")) return TRUE;
    string mode=argv(1);
    if(mode=="setup") {
        for(int i=0;i<3;i++) fb_pick_test_ids[i]=fb_createbox([i*100,0,200],'32 32 32');
        static patchvert_t cp[9];
        for(int y=0;y<3;y++) for(int x=0;x<3;x++) {
            cp[y*3+x].xyz=[x*32-32,y*32-32,320];
            if(x==1) if(y==1) cp[y*3+x].xyz[2]+=32;
            cp[y*3+x].s=x;cp[y*3+x].t=y;cp[y*3+x].rgb='1 1 1';cp[y*3+x].a=1;
        }
        patchinfo_t info={0};info.cpwidth=info.cpheight=3;
        info.tesswidth=info.tessheight=4;
        info.shadername="ftebroom/grid";info.contents=CONTENTBIT_SOLID;
        fb_tx_begin("Test patch");fb_pick_test_patch=patch_history_create(1,cp,info,FALSE);fb_tx_commit();
    } else if(mode=="query") {
        vector start='-100 0 200',end='300 0 200',pixel=project('0 0 200');
        int count=fb_pick_query(start,end,pixel,0,FB_HIT_BRUSH,FALSE);
        fb_pick_expect(count==3,"three_brushes");
        if(count==3) {
            fb_pick_expect(fb_hits[0].id==fb_pick_test_ids[0] && fb_hits[1].id==fb_pick_test_ids[1] && fb_hits[2].id==fb_pick_test_ids[2],"distance_order");
            fb_pick_expect(fabs(fb_hits[0].distance-84)<0.001 && fb_hits[0].normal=='-1 0 0',"entry_plane");
            int node=fb_hits[1].node;
            fb_nodes[node].flags|=FB_NODE_HIDDEN;
            fb_pick_expect(fb_pick_query(start,end,pixel,0,FB_HIT_BRUSH,FALSE)==2,"hidden_filter");
            fb_pick_expect(fb_pick_query(start,end,pixel,FB_PICK_HIDDEN,FB_HIT_BRUSH,FALSE)==3,"hidden_override");
            fb_nodes[node].flags&=~FB_NODE_HIDDEN;
            fb_nodes[1].flags|=FB_NODE_LOCKED;
            fb_pick_expect(fb_pick_query(start,end,pixel,0,FB_HIT_BRUSH,FALSE)==0,"locked_parent_filter");
            fb_pick_expect(fb_pick_query(start,end,pixel,FB_PICK_LOCKED,FB_HIT_BRUSH,FALSE)==3,"locked_override");
            fb_nodes[1].flags&=~FB_NODE_LOCKED;
        }
        fb_pick_query('0 0 200',end,pixel,0,FB_HIT_BRUSH,FALSE);
        fb_pick_expect(fb_hit_count==3 && fabs(fb_hits[0].distance-16)<0.001,"inside_brush_exit");
        fb_pick_expect(fb_pick_query('-100 50 200','300 50 200',pixel,0,FB_HIT_BRUSH,FALSE)==0,"parallel_miss");
        fb_pick_clear_handles();fb_pick_handle(91,'0 0 200',6,-1);
        fb_pick_query(start,end,pixel+'5 0 0',0,FB_HIT_BRUSH|FB_HIT_HANDLE,FALSE);
        fb_pick_expect(fb_hit_count==4 && fb_hits[0].kind==FB_HIT_HANDLE && fb_hits[0].id==91,"handle_five_pixels");
        fb_pick_query(start,end,pixel+'7 0 0',0,FB_HIT_BRUSH|FB_HIT_HANDLE,FALSE);
        fb_pick_expect(fb_hit_count==3,"handle_outside_radius");fb_pick_clear_handles();
        fb_pick_query('0 0 400','0 0 250',project('0 0 320'),0,FB_HIT_PATCH,FALSE);
        fb_pick_expect(fb_hit_count==1 && fb_hits[0].id==fb_pick_test_patch && fb_hits[0].point[2]>320,"curved_patch_surface");
        fb_pick_expect(fb_hit_count==1 && fb_hits[0].normal[2]>0.9,"patch_normal");
        fb_pick_query('0 -200 256','0 -200 64',project('0 -200 128'),0,FB_HIT_ENTITY,FALSE);
        fb_pick_expect(fb_hit_count==1 && fb_hits[0].kind==FB_HIT_ENTITY,"point_entity_bounds");
        brush_deselectall();brush_select(1,fb_pick_test_ids[2]);
        fb_pick_expect(fb_pick_near_face(project('200 -16 216')),"near_selected_edge");
        if(fb_hit_count) {
            vector ray=normalize(unproject(project('200 -16 216')+'0 0 8192')-unproject(project('200 -16 216')));
            fb_pick_expect(fb_hits[0].normal*ray>0,"near_back_face");
        }
    } else if(mode=="click") {
        vector entityPixel=project('0 -200 128');entityPixel_z=0;
        fb_begin(entityPixel,0,cvar("ca_brush_view"));fb_finish(entityPixel,0,cvar("ca_brush_view"));
        fb_pick_expect(fb_selected_entity()==1 && selectedbrushcount==0,"entity_click");
        brush_undo();fb_pick_expect(selectedbrushcount==1,"entity_selection_undo");
        vector patchPixel=project('8 8 324');patchPixel_z=0;
        fb_begin(patchPixel,0,cvar("ca_brush_view"));fb_finish(patchPixel,0,cvar("ca_brush_view"));
        fb_pick_expect(selectedbrushcount==1 && selectedbrushes[0].id==fb_pick_test_patch,"patch_click");
        brush_undo();
    } else if(mode=="entityview") {
        vector viewPixel=project('0 -200 128');viewPixel_z=0;
        fb_begin(viewPixel,0,cvar("ca_brush_view"));fb_finish(viewPixel,0,cvar("ca_brush_view"));
        fb_pick_expect(fb_selected_entity()==1,"entity_view_selection");
        fb_tool_escape();fb_pick_expect(fb_selected_entity()<0,"entity_escape");
        brush_undo();fb_pick_expect(fb_selected_entity()==1,"entity_deselect_undo");
    } else if(mode=="overlap") {
        fb_createbox('0 0 200','96 96 96');
        int small=fb_createbox('0 0 300','16 16 16');
        vector cursor=project('0 0 200');
        fb_pick_query('0 0 100','0 0 400',cursor,0,FB_HIT_BRUSH,FALSE);
        fb_pick_expect(fb_hits[0].id!=small,"perspective_nearest");
        fb_pick_query('0 0 100','0 0 400',cursor,0,FB_HIT_BRUSH,TRUE);
        fb_pick_expect(fb_hits[0].id==small,"orthographic_smallest");
        vector smallPixel=project('0 0 300');smallPixel_z=0;
        fb_begin(smallPixel,0,cvar("ca_brush_view"));fb_finish(smallPixel,0,cvar("ca_brush_view"));
        fb_pick_expect(selectedbrushcount==1 && selectedbrushes[0].id==small,"orthographic_click");
    }
    return TRUE;
}
