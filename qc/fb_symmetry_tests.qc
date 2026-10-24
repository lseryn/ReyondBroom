// SPDX-License-Identifier: GPL-3.0-or-later
void fb_symmetry_reload_test()
{
    fb_document_tick();int roots[2],count=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_ftebroom_symmetry"]=="2 0"){
        if(count<2)roots[count]=fb_nodes[n].id;count++;
    }
    fb_transform_expect(count==2,"symmetry47_reload_metadata");if(count!=2)return;
    int first=fb_linked_test_brush(roots[0]),second=fb_linked_test_brush(roots[1]);
    vector before=fb_linked_test_min(second);fb_open_group=roots[0];fb_selection_clear();fb_selection_set(first,TRUE);fb_move_numeric('0 0 16');fb_document_tick();
    vector after=fb_linked_test_min(fb_linked_test_brush(roots[1]));fb_transform_expect(vlen(after-before-'0 0 16')<.01,"symmetry47_reload_sync");fb_open_group=0;
}
void fb_symmetry_tests()
{
    fb_tool_deactivate();fb_open_group=0;fb_selection_clear();fb_createbox('512 256 64','128 64 32');fb_document_tick();
    int marker=history,ok=fb_symmetry_apply(4,FALSE);fb_document_tick();
    int root=-1;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_selection_selected(n))root=fb_nodes[n].id;
    fb_transform_expect(ok&&root>=0,"symmetry47_create");if(root<0)return;
    string link=strzone(fb_nodes[fb_organize_node(root)].fields["_tb_linked_group_id"]);int peers=0,other=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_tb_linked_group_id"]==link){peers++;if(fb_nodes[n].id!=root)other=fb_nodes[n].id;}
    fb_transform_expect(peers==4,"symmetry47_four_sides");brush_undo();fb_document_tick();fb_transform_expect(history==marker&&selectedbrushcount==1,"symmetry47_single_undo");brush_redo();fb_document_tick();
    fb_open_group=root;fb_selection_clear();fb_selection_set(fb_linked_test_brush(root),TRUE);marker=history;fb_move_numeric('16 0 0');fb_document_tick();
    int a=fb_linked_test_brush(root),b=fb_linked_test_brush(other);vector lowA=fb_linked_test_min(a),lowB=fb_linked_test_min(b);fb_affine_t transform;
    fb_linked_matrix(fb_nodes[fb_organize_node(other)].fields["_tb_transformation"],&transform);
    fb_poly_t source={0},peer={0};int valid=fb_poly_from_brush(fb_nodes[a].model,fb_nodes[a].id,&source)&&fb_poly_from_brush(fb_nodes[b].model,fb_nodes[b].id,&peer);
    vector expected='1000000 1000000 1000000';for(int v=0;v<source.nv;v++){vector mapped=fb_affine_point(&transform,source.vertices[v]);for(int axis=0;axis<3;axis++)expected[axis]=min(expected[axis],mapped[axis]);}
    fb_transform_expect(valid&&vlen(expected-lowB)<.01,"symmetry47_edit_sync");fb_poly_free(&source);fb_poly_free(&peer);
    brush_undo();fb_transform_expect(history==marker,"symmetry47_edit_single_undo");brush_redo();fb_document_tick();
    fb_open_group=other;fb_selection_clear();fb_selection_set(fb_linked_test_brush(other),TRUE);fb_move_numeric('0 0 16');fb_document_tick();
    vector raised=fb_linked_test_min(fb_linked_test_brush(root));fb_transform_expect(fabs(raised_z-lowA_z-16)<.01,"symmetry47_reverse_edit");
    fb_open_group=0;fb_selection_clear();fb_selection_set(fb_organize_node(root),TRUE);marker=history;
    ok=fb_symmetry_apply(8,TRUE);fb_document_tick();peers=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_tb_linked_group_id"]==link){peers++;fb_linked_matrix(fb_nodes[n].fields["_tb_transformation"],&transform);if(transform.determinant<.99)ok=FALSE;}
    fb_transform_expect(ok&&peers==8,"symmetry47_reconfigure_rotation");brush_undo();fb_document_tick();peers=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_tb_linked_group_id"]==link)peers++;
    fb_transform_expect(history==marker&&peers==4,"symmetry47_reconfigure_undo");
    fb_selection_clear();fb_selection_set(fb_organize_node(root),TRUE);ok=fb_symmetry_apply(2,FALSE);fb_document_tick();peers=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_tb_linked_group_id"]==link)peers++;
    fb_transform_expect(ok&&peers==2,"symmetry47_two_sides");strunzone(link);
}

void fb_symmetry_settings_tests()
{
    fb_tool_deactivate();fb_open_group=0;fb_selection_clear();fb_createbox('2560 0 64','64 64 128');fb_document_tick();int before=history;
    cvar_set("ftebroom_symmetry_custom_center","1");cvar_set("ftebroom_symmetry_center_x","2400");cvar_set("ftebroom_symmetry_center_y","0");cvar_set("ftebroom_symmetry_center_z","0");cvar_set("ftebroom_symmetry_angle","90");
    int valid=fb_symmetry_apply(2,FALSE),source=-1,other=-1;fb_document_tick();
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_selection_selected(n)&&fb_nodes[n].fields["_ftebroom_symmetry"]!="")source=n;
    fb_transform_expect(valid&&source>=2,"symmetry54_custom_create");if(source<2)return;
    int sourceId=fb_nodes[source].id;string link=strzone(fb_nodes[source].fields["_tb_linked_group_id"]);
    for(int n=2;n<fb_node_count;n++)if(n!=source&&fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_tb_linked_group_id"]==link)other=n;
    vector bounds[2];valid=other>=2;if(valid)valid=fb_container_bounds(other,bounds);
    fb_transform_expect(valid&&fabs(bounds[0][0]-2208)<.05&&fabs(bounds[1][0]-2272)<.05,"symmetry54_custom_mirror");
    fb_symmetry_guides_update();fb_transform_expect(fb_symmetry_guide_sides==2&&fb_symmetry_guide_center=='2400 0 0'&&fabs(fb_symmetry_guide_angle-M_PI*.5)<.001,"symmetry54_guides");
    brush_undo();fb_document_tick();fb_transform_expect(history==before&&selectedbrushcount==1,"symmetry54_custom_undo");brush_redo();fb_document_tick();
    fb_selection_clear();fb_selection_set(fb_organize_node(sourceId),TRUE);cvar_set("ftebroom_symmetry_custom_center","0");valid=fb_symmetry_apply(4,FALSE);fb_document_tick();
    source=fb_organize_node(sourceId);fb_transform_expect(valid&&stov(fb_nodes[source].fields["_ftebroom_symmetry_center"])=='2400 0 0',"symmetry54_preserved_pivot");
    fb_open_group=sourceId;fb_selection_clear();fb_selection_set(fb_linked_test_brush(sourceId),TRUE);fb_symmetry_guides_update();fb_transform_expect(fb_symmetry_guide_sides==4,"symmetry54_open_group_guides");fb_open_group=0;
    fb_selection_clear();fb_symmetry_guides_update();fb_transform_expect(fb_symmetry_guide_sides==0,"symmetry54_deselected_guides");
    fb_selection_set(fb_organize_node(sourceId),TRUE);fb_symmetry_guides_update();fb_camera_position('2900 -600 420');setproperty(VF_CL_VIEWANGLES,'25 130 0');strunzone(link);
    cvar_set("ftebroom_symmetry_angle","0");
}

void fb_symmetry_relink_tests()
{
    fb_tool_deactivate();fb_open_group=0;fb_selection_clear();fb_createbox('6000 128 64','64 64 128');fb_document_tick();fb_group_create("Relink source");fb_document_tick();int sourceId=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_selection_selected(n))sourceId=fb_nodes[n].id;
    fb_selection_clear();fb_createbox('6000 -128 64','64 64 128');fb_document_tick();fb_group_create("Relink peer");fb_document_tick();int targetId=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_selection_selected(n))targetId=fb_nodes[n].id;
    fb_transform_expect(sourceId>=0&&targetId>=0,"symmetry54_relink_fixture");if(sourceId<0||targetId<0)return;
    int sourceBrush=fb_linked_test_brush(sourceId),targetBrush=fb_linked_test_brush(targetId),originalSourceId=fb_nodes[sourceBrush].id,originalTargetId=fb_nodes[targetBrush].id;
    fb_selection_clear();fb_selection_set(fb_organize_node(sourceId),TRUE);cvar_set("ftebroom_symmetry_custom_center","1");cvar_set("ftebroom_symmetry_center_x","6000");cvar_set("ftebroom_symmetry_center_y","0");cvar_set("ftebroom_symmetry_center_z","0");cvar_set("ftebroom_symmetry_angle","0");
    int before=history,count=fb_node_count,valid=fb_symmetry_apply(2,FALSE);fb_document_tick();
    sourceBrush=fb_linked_test_brush(sourceId);targetBrush=fb_linked_test_brush(targetId);
    fb_transform_expect(valid&&fb_node_count==count&&fb_nodes[sourceBrush].id==originalSourceId&&fb_nodes[targetBrush].id==originalTargetId,"symmetry54_relink_preserves_geometry");
    string sourceLink=fb_nodes[fb_organize_node(sourceId)].fields["_tb_linked_group_id"],targetLink=fb_nodes[fb_organize_node(targetId)].fields["_tb_linked_group_id"];
    fb_transform_expect(sourceLink==targetLink&&sourceLink!="","symmetry54_relink_shared_link");
    brush_undo();fb_document_tick();fb_transform_expect(history==before&&fb_nodes[fb_organize_node(sourceId)].fields["_tb_linked_group_id"]=="","symmetry54_relink_undo");brush_redo();fb_document_tick();
    fb_open_group=targetId;fb_selection_clear();fb_selection_set(fb_linked_test_brush(targetId),TRUE);fb_move_numeric('0 0 16');fb_document_tick();vector minimum=fb_linked_test_min(fb_linked_test_brush(sourceId));fb_transform_expect(fabs(minimum_z-16)<.05,"symmetry54_relink_reverse_sync");fb_open_group=0;
    cvar_set("ftebroom_symmetry_custom_center","0");cvar_set("ftebroom_symmetry_angle","0");
}

void fb_symmetry_patch_match_tests()
{
    fb_tool_deactivate();fb_open_group=0;fb_selection_clear();fb_tx_begin("Patch symmetry fixture");
    patchinfo_t info={0};info.cpwidth=info.cpheight=3;info.shadername="ftebroom/qa_red";info.tesswidth=info.tessheight=-1;info.contents=CONTENTBIT_SOLID;info.texinfo='1 1 0';patchvert_t left[9],right[9];fb_affine_t mirror;fb_symmetry_matrix('8000 0 0',0,1,2,FALSE,&mirror);
    for(int row=0;row<3;row++)for(int col=0;col<3;col++){int i=row*3+col,j=row*3+2-col;left[i].xyz=[8000+col*16,128+row*16,64];if(row==1)if(col==1)left[i].xyz[2]+=32;left[i].rgb='1 1 1';left[i].a=1;left[i].s=col*.5;left[i].t=row*.5;right[j]=left[i];right[j].xyz=fb_affine_point(&mirror,left[i].xyz);}
    int model=fb_active_layer_model(),a=patch_history_create(model,left,info,FALSE),b=patch_history_create(model,right,info,FALSE);fb_tx_commit();fb_document_tick();int an=-1,bn=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_PATCH&&fb_nodes[n].model==model){if(fb_nodes[n].id==a)an=n;if(fb_nodes[n].id==b)bn=n;}
    fb_transform_expect(an>=2&&bn>=2,"symmetry54_patch_fixture");if(an<2||bn<2)return;
    int *mapping=memalloc(fb_node_count*sizeof(int));fb_symmetry_match_work=fb_symmetry_match_scans=0;
    fb_transform_expect(fb_symmetry_match_node(an,bn,&mirror,mapping,0),"symmetry54_patch_match");fb_linked_matrix("",&mirror);
    fb_transform_expect(!fb_symmetry_match_node(an,bn,&mirror,mapping,0),"symmetry54_patch_mismatch");memfree(mapping);
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP){string center=fb_nodes[n].fields["_ftebroom_symmetry_center"];if(center!="")if(stov(center)=='2400 0 0'){fb_selection_set(n,TRUE);break;}}
    fb_camera_position('2900 -600 420');setproperty(VF_CL_VIEWANGLES,'25 130 0');
    cvar_set("ftebroom_symmetry_custom_center","1");cvar_set("ftebroom_symmetry_center_x","2400");

}
void fb_symmetry_metadata_reload_test()
{
    fb_document_tick();int found=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP){string center=fb_nodes[n].fields["_ftebroom_symmetry_center"];if(center!="")if(stov(center)=='2400 0 0')found++;}
    fb_transform_expect(found==4,"symmetry54_reload_pivot_metadata");
}
