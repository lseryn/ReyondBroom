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
