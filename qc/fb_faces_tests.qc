// SPDX-License-Identifier: GPL-2.0-or-later
int fb_faces_test_ids[7],fb_faces_test_many,fb_faces_test_64;
void fb_faces_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_FACES_PASS ":"FTEBROOM_FACES_FAIL ",name,"\n"));
}
int fb_faces_test_top(int id)
{
    static brushface_t faces[128];int count=brush_get(1,id,faces,128,__NULL__);
    for(int f=0;f<count;f++) if(faces[f].planenormal[2]>0.999) return f+1;
    return 0;
}
int fb_faces_test_prism(int sides,vector center)
{
    static brushface_t faces[128];
    for(int f=0;f<sides+2;f++) {
        brushface_t face={0};
        if(f<sides) {float angle=f*2*M_PI/(float)sides;face.planenormal=[cos(angle),sin(angle),0];face.planedist=center*face.planenormal+48;}
        else {face.planenormal=f==sides?'0 0 -1':'0 0 1';face.planedist=f==sides?0:64;}
        face.shadername="ftebroom/grid";reset_texturecoords(&face);faces[f]=face;
    }
    fb_tx_begin("Test prism");int id=brush_history_create(1,faces,sides+2,CONTENTBIT_SOLID,FALSE);fb_tx_commit();return id;
}
void fb_faces_test_rect(fb_flood_face_t *face,vector low,vector high)
{
    face->count=4;face->low=low;face->high=high;
    face->points[0]=low;face->points[1]=[high_x,low_y,low_z];face->points[2]=high;face->points[3]=[low_x,high_y,low_z];
}
float fb_faces_testcommand()
{
    if(argv(0)!="ftebroom_test_faces") return FALSE;
    if(!cvar("ftebroom_skip_setup")) return TRUE;
    string mode=argv(1);
    if(mode=="setup") {
        selectedbrushmodel=1;
        static int oldids[128];static vector axes[1];static float distances[1];
        int oldcount=brush_findinvolume(1,axes,distances,0,oldids,__NULL__,128);
        fb_tx_begin("Face fixture");for(int old=0;old<oldcount;old++) brush_history_delete(1,oldids[old]);fb_tx_commit();
        for(int i=0;i<4;i++) {int col=0;if(i==1 || i==3) col=1;fb_faces_test_ids[i]=fb_createbox([col*64-32,floor(i/2)*64-32,32],'64 64 64');}
        fb_faces_test_ids[4]=fb_createbox('192 0 32','64 64 64');
        fb_faces_test_ids[5]=fb_createbox('96 96 32','64 64 64');
        fb_faces_test_ids[6]=fb_createbox('-128 0 48','64 64 64');
    } else if(mode=="prism65") {
        fb_faces_test_many=fb_faces_test_prism(63,'350 0 0');
    } else if(mode=="prism64") {
        fb_faces_test_64=fb_faces_test_prism(62,'500 0 0');
        fb_selection_clear();
    } else if(mode=="core") {
        int a=fb_faces_test_ids[0],b=fb_faces_test_ids[1],top=fb_faces_test_top(a);
        fb_faces_click(1,a,top,0);fb_faces_expect(fb_faces_count()==1 && !selbrush_whole(&selectedbrushes[0]),"single_face");
        fb_faces_click(1,b,top,1);fb_faces_expect(fb_faces_count()==2,"toggle_add");
        fb_faces_click(1,a,top,1);fb_faces_expect(fb_faces_count()==1 && !brush_isselected(1,a),"toggle_remove_last");
        brush_undo();fb_faces_expect(fb_faces_count()==2,"toggle_undo");brush_redo();fb_faces_expect(fb_faces_count()==1,"toggle_redo");
        fb_selection_clear();brush_select(1,a);brush_select(1,b);fb_entity_select(1,TRUE);
        fb_faces_click(1,a,top,1);
        fb_faces_expect(fb_faces_count()==11 && fb_selected_entity_count==0 && !selbrush_whole(&selectedbrushes[0]),"nodes_to_faces_except_one");
        brush_undo();fb_faces_expect(selectedbrushcount==2 && selbrush_whole(&selectedbrushes[0]) && fb_selected_entity_count==1,"conversion_undo_nodes");
        fb_faces_click(1,fb_faces_test_ids[4],top,1);fb_faces_expect(fb_faces_count()==1 && selectedbrushcount==1,"unselected_face_replaces_nodes");
        fb_faces_all(1,a,0);fb_faces_expect(fb_faces_count()==6,"double_all");
        fb_faces_all(1,b,1);fb_faces_expect(fb_faces_count()==12,"double_add_all");
        fb_faces_click(1,0,0,0);fb_faces_expect(selectedbrushcount==0,"empty_clears");
        fb_faces_click(1,fb_faces_test_many,33,0);fb_faces_expect(fb_faces_count()==1 && brushface_isselected(1,fb_faces_test_many,33) && !brushface_isselected(1,fb_faces_test_many,1),"mask_high_word");
        fb_faces_click(1,fb_faces_test_many,64,1);fb_faces_expect(fb_faces_count()==2 && brushface_isselected(1,fb_faces_test_many,64),"mask_bit_63");
        int before=history;fb_faces_click(1,fb_faces_test_many,65,1);fb_faces_expect(history==before && fb_faces_count()==2 && cvar_string("ftebroom_selection_status")!="","face_limit_preserves_selection");
        fb_faces_all(1,fb_faces_test_64,0);fb_faces_expect(fb_faces_count()==64 && !selbrush_whole(&selectedbrushes[0]),"all_64_are_faces");
        brush_undo();fb_faces_expect(fb_faces_count()==2,"all_64_undo");brush_redo();fb_faces_expect(fb_faces_count()==64 && !selbrush_whole(&selectedbrushes[0]),"all_64_redo");
    } else if(mode=="material") {
        fb_faces_click(1,fb_faces_test_many,33,0);
        cvar_set("ca_newbrushtexture","ftebroom/qa_blue");fb_material_edit("material",0);
        int changedID=selectedbrushes[0].id;fb_faces_test_many=changedID;
        static brushface_t checked[128];int total=brush_get(1,changedID,checked,128,__NULL__),changed=0;
        for(int f=0;f<total;f++) if(checked[f].shadername=="ftebroom/qa_blue") changed++;
        fb_faces_expect(changed==1 && checked[32].shadername=="ftebroom/qa_blue","material_high_face_only");
    } else if(mode=="material_undo") {
        brush_undo();fb_faces_test_many=selectedbrushes[0].id;
    } else if(mode=="whole_material") {
        static brushface_t checkedAll[128];int totalAll,changedAll;
        brush_deselectall();brush_select(1,fb_faces_test_many);fb_material_edit("material",0);
        totalAll=brush_get(1,selectedbrushes[0].id,checkedAll,128,__NULL__);changedAll=0;
        for(int g=0;g<totalAll;g++) if(checkedAll[g].shadername=="ftebroom/qa_blue") changedAll++;
        fb_faces_expect(changedAll==65,"whole_brush_material_all_65");
    } else if(mode=="whole_undo") {
        brush_undo();fb_faces_test_many=selectedbrushes[0].id;cvar_set("ca_newbrushtexture","ftebroom/grid");fb_selection_clear();
    } else if(mode=="flood") {
        int seed=fb_faces_test_ids[0],topFace=fb_faces_test_top(seed);
        fb_faces_flood(1,seed,topFace,0);fb_faces_expect(fb_faces_count()==4,"flood_four_tiles");
        fb_faces_expect(!brush_isselected(1,fb_faces_test_ids[4]) && !brush_isselected(1,fb_faces_test_ids[5]) && !brush_isselected(1,fb_faces_test_ids[6]),"flood_gap_corner_other_plane");
        fb_faces_click(1,fb_faces_test_ids[1],topFace,1);fb_faces_expect(fb_faces_count()==3,"flood_toggle_one");
        brush_undo();fb_faces_expect(fb_faces_count()==4,"flood_toggle_undo");
        fb_faces_click(1,fb_faces_test_ids[4],topFace,0);fb_faces_flood(1,seed,topFace,1);fb_faces_expect(fb_faces_count()==5,"flood_add");
        fb_document_tick();int hidden=-1;
        for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].model==1 && fb_nodes[n].id==fb_faces_test_ids[1]) hidden=n;
        if(hidden>=0) fb_nodes[hidden].flags|=FB_NODE_HIDDEN;
        fb_faces_flood(1,seed,topFace,0);fb_faces_expect(fb_faces_count()==3,"flood_hidden_excluded");
        if(hidden>=0) fb_nodes[hidden].flags&=~FB_NODE_HIDDEN;
        static fb_flood_face_t pa,pb;
        fb_faces_test_rect(&pa,'0 0 0','64 64 0');fb_faces_test_rect(&pb,'64 0 0','128 64 0');
        fb_faces_expect(fb_faces_connected(&pa,&pb,'0 0 1'),"shared_edge");
        fb_faces_test_rect(&pb,'64 64 0','128 128 0');fb_faces_expect(!fb_faces_connected(&pa,&pb,'0 0 1'),"corner_only_excluded");
        fb_faces_test_rect(&pb,'32 32 0','96 96 0');fb_faces_expect(fb_faces_connected(&pa,&pb,'0 0 1'),"positive_area_overlap");
        fb_faces_test_rect(&pb,'64.1 0 0','128 64 0');fb_faces_expect(!fb_faces_connected(&pa,&pb,'0 0 1'),"small_gap_excluded");
        fb_faces_flood(1,seed,topFace,0);
    } else if(mode=="paint") {
        cvar_set("ftebroom_shift","1");cvar_set("ftebroom_ctrl","1");
        fb_faces_click(1,fb_faces_test_ids[0],fb_faces_test_top(fb_faces_test_ids[0]),0);
        vector p=project('-32 -32 64'),q=project('32 -32 64');p_z=q_z=0;
        int start=history;fb_begin(p,0,0);fb_finish(q,0,0);
        fb_faces_expect(fb_faces_count()==2 && history==start+1,"paint_one_transaction");
        brush_undo();fb_faces_expect(fb_faces_count()==1,"paint_undo");brush_redo();fb_faces_expect(fb_faces_count()==2,"paint_redo");
        brush_undo();int redo=history_max;
        fb_begin(p,0,0);fb_update(q,0,0);fb_cancel();fb_faces_expect(fb_faces_count()==1 && history_max==redo,"paint_escape_preserves_redo");
        cvar_set("ca_brush_view","3");fb_view_prepare();p=project('-32 -32 64');p_z=0;
        fb_begin(p,0,3);fb_finish(p,0,3);fb_faces_expect(fb_faces_count()==0,"no_face_selection_in_2d");
        cvar_set("ca_brush_view","0");cvar_set("ftebroom_shift","0");cvar_set("ftebroom_ctrl","0");
    } else if(mode=="show") fb_faces_flood(1,fb_faces_test_ids[0],fb_faces_test_top(fb_faces_test_ids[0]),0);
    else if(mode=="deselected") fb_faces_expect(!selectedbrushcount,"native_deselect_hotkey");
    else if(mode=="native_all") fb_faces_expect(fb_faces_count()==6,"native_shift_double");
    else if(mode=="native_add") {fb_faces_expect(fb_faces_count()==12,"native_ctrl_shift_double");}
    else if(mode=="native_flood") fb_faces_expect(fb_faces_count()==4,"native_alt_shift_flood");
    return TRUE;
}
