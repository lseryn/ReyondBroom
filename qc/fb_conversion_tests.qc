// SPDX-License-Identifier: GPL-3.0-or-later
float fb_conversion_test_volume()
{
    float volume=0;for(int i=0;i<selectedbrushcount;i++){fb_poly_t part={0};if(fb_poly_from_brush(selectedbrushes[i].model,selectedbrushes[i].id,&part))volume+=part.volume;fb_poly_free(&part);}return volume;
}
void fb_conversion_tests()
{
    fb_tool_deactivate();fb_open_group=0;fb_selection_clear();fb_createbox('0 0 64','128 128 128');fb_document_tick();
    int marker=history;cvar_set("ftebroom_subdivide_texture","0");cvar_set("ftebroom_subdivide_grid","0");cvar_set("ftebroom_subdivide_u","2");cvar_set("ftebroom_subdivide_v","3");cvar_set("ftebroom_subdivide_plane","0");
    static brushface_t faces[64];int nf=brush_get(selectedbrushes[0].model,selectedbrushes[0].id,faces,64,__NULL__);
    selbrush_reset_mask(&selectedbrushes[0],FALSE);for(int f=0;f<nf;f++)if(faces[f].planenormal[0]>.99)selbrush_set_face(&selectedbrushes[0],f,TRUE);
    fb_tx_begin("Face basis");int ok=fb_subdivision_apply();fb_transform_expect(ok&&selectedbrushcount==6,"conversion50_face_segments");
    int unsplitX=TRUE;for(int i=0;i<selectedbrushcount;i++){vector bounds[2];brush_getfacepoints(selectedbrushes[i].model,selectedbrushes[i].id,0,bounds,2);if(fabs(bounds[1][0]-bounds[0][0]-128)>.01)unsplitX=FALSE;}
    fb_transform_expect(unsplitX&&fabs(fb_conversion_test_volume()-128*128*128)<1,"conversion50_face_orientation_volume");fb_tx_cancel();
    selbrush_reset_mask(&selectedbrushes[0],TRUE);cvar_set("ftebroom_subdivide_grid","1");cvar_set("ftebroom_subdivide_cell","64");cvar_set("ftebroom_grid_rotation","45");
    fb_tx_begin("Rotated subdivision");ok=fb_subdivision_apply();int rotated=FALSE;for(int i=0;i<selectedbrushcount;i++){nf=brush_get(selectedbrushes[i].model,selectedbrushes[i].id,faces,64,__NULL__);for(int f=0;f<nf;f++)if(fabs(fabs(faces[f].planenormal[0])-.70710678)<.001&&fabs(fabs(faces[f].planenormal[1])-.70710678)<.001)rotated=TRUE;}
    fb_transform_expect(ok&&rotated&&fabs(fb_conversion_test_volume()-128*128*128)<2,"conversion50_rotated_grid");fb_tx_cancel();cvar_set("ftebroom_grid_rotation","0");
    cvar_set("ftebroom_subdivide_texture","1");fb_tx_begin("Automatic texture face");ok=fb_subdivision_apply();fb_transform_expect(ok&&selectedbrushcount>1&&fabs(fb_conversion_test_volume()-128*128*128)<2,"conversion50_auto_texture_face");fb_tx_cancel();
    fb_transform_expect(history==marker&&selectedbrushcount==1,"conversion50_subdivision_cancel");cvar_set("ftebroom_subdivide_texture","0");cvar_set("ftebroom_subdivide_grid","0");
    fb_selection_clear();fb_createbox('512 0 32','64 64 64');int firstModel=selectedbrushes[0].model,firstId=selectedbrushes[0].id;fb_createbox('576 0 32','64 64 64');brush_select(firstModel,firstId);fb_document_tick();
    fb_tx_begin("Independent conversion");ok=fb_convert_brushes_apply();fb_transform_expect(ok&&selectedbrushcount==2&&fabs(fb_conversion_test_volume()-2*64*64*64)<1,"conversion50_independent_brushes");fb_tx_cancel();
    fb_group_create("Conversion fixture");fb_document_tick();marker=history;fb_tx_begin("Cluster conversion");ok=fb_convert_brushes_apply();fb_transform_expect(ok&&selectedbrushcount==1&&fabs(fb_conversion_test_volume()-2*64*64*64)<1,"conversion50_group_cluster");if(ok)fb_tx_commit();else fb_tx_cancel();
    brush_undo();fb_document_tick();fb_transform_expect(history==marker&&selectedbrushcount==2,"conversion50_single_undo");brush_redo();fb_document_tick();fb_transform_expect(selectedbrushcount==1,"conversion50_redo");
    fb_open_group=0;fb_selection_clear();fb_createbox('1024 0 32','64 64 64');firstModel=selectedbrushes[0].model;firstId=selectedbrushes[0].id;fb_createbox('1152 0 32','64 64 64');brush_select(firstModel,firstId);fb_document_tick();fb_group_create("Disconnected conversion");fb_document_tick();marker=history;
    fb_tx_begin("Rejected conversion");ok=fb_convert_brushes_apply();fb_tx_cancel();fb_transform_expect(!ok&&history==marker&&selectedbrushcount==2,"conversion50_empty_space_rejected");
    fb_open_group=0;fb_selection_clear();fb_createbox('2048 0 64','128 128 128');firstModel=selectedbrushes[0].model;firstId=selectedbrushes[0].id;fb_createbox('2304 0 64','128 128 128');brush_select(firstModel,firstId);fb_document_tick();marker=history;
    int beforeGroups=0;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP)beforeGroups++;
    cvar_set("ftebroom_rock_segments","6");cvar_set("ftebroom_rock_group","1");cvar_set("ftebroom_rock_hollow","0");fb_tx_begin("Individual rock groups");ok=fb_rock_apply();fb_document_tick();int afterGroups=0,models=0,first=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP)afterGroups++;
    for(int i=0;i<selectedbrushcount;i++){if(i==0){first=selectedbrushes[i].model;models=1;}else if(selectedbrushes[i].model!=first)models=2;}
    print(sprintf("Rock group result %i before %i after %i models %i selected %i error %s\n",ok,beforeGroups,afterGroups,models,selectedbrushcount,fb_geom_error));
    fb_transform_expect(ok&&afterGroups==beforeGroups+2&&models==2,"conversion50_rock_per_source_group");fb_tx_cancel();fb_transform_expect(history==marker&&selectedbrushcount==2,"conversion50_rock_cancel");cvar_set("ftebroom_rock_group","0");

    fb_selection_clear();fb_createbox('2816 0 64','128 128 128');fb_entity_create("func_wall",TRUE,'0 0 0');fb_document_tick();marker=history;cvar_set("ftebroom_rock_group","1");fb_tx_begin("Protected rock owner");ok=fb_rock_apply();fb_tx_cancel();fb_transform_expect(!ok&&history==marker&&selectedbrushcount==1,"conversion50_rock_entity_protected");cvar_set("ftebroom_rock_group","0");

}
