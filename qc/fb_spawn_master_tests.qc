// SPDX-License-Identifier: GPL-3.0-or-later
int fb_spawn_test_source,fb_spawn_test_second;
int fb_spawn_test_groups(){int count=0;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_ftebroom_spawn_closet"]=="1")count++;return count;}
int fb_spawn_test_count(string classname){int count=0;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY&&fb_nodes[n].fields["classname"]==classname)count++;return count;}
void fb_spawn_tests()
{
    fb_tool_deactivate();fb_selection_clear();fb_entity_create("light",FALSE,'200 200 64');fb_entity_property("set","targetname","spawn_destination");
    fb_selection_clear();fb_createbox('256 0 64','64 64 64');fb_entity_create("func_button",TRUE,'0 0 0');fb_document_tick();fb_entity_targets();fb_spawn_test_source=fb_property_entities[0];
    fb_transform_expect(fb_entity_definition_count>0&&(int)fb_entity_kinds["light"]==1,"spawn49_definition_cache");fb_spawn_prepare();int marker=history,valid=fb_spawn_apply("spawn_destination","light");fb_document_tick();
    print(strcat("Spawn result: ",cvar_string("ftebroom_spawn_error"),"\n"));
    fb_transform_expect(valid&&fb_spawn_test_groups()==1&&fb_spawn_test_count("trigger_teleport")==1,"spawn49_create");
    int group=-1,walls=0;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].fields["_ftebroom_spawn_closet"]=="1")group=n;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].parent==group&&fb_nodes[n].kind==FB_NODE_BRUSH)walls++;
    fb_transform_expect(walls==6,"spawn49_six_walls");
    string target=fb_entity_field(fb_spawn_test_source,"target");fb_transform_expect(target!=""&&target==fb_entity_field(fb_spawn_test_source,"_tb_spawn_master_teleport_target"),"spawn49_source_link");
    int teleport=-1;for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY&&fb_nodes[n].fields["classname"]=="trigger_teleport")teleport=fb_nodes[n].id;
    fb_transform_expect(fb_entity_field(teleport,"targetname")==target&&fb_entity_field(teleport,"target")=="spawn_destination","spawn49_destination_link");
    brush_undo();fb_document_tick();fb_transform_expect(history==marker&&!fb_spawn_test_groups()&&fb_entity_field(fb_spawn_test_source,"target")=="","spawn49_single_undo");brush_redo();fb_document_tick();fb_transform_expect(fb_spawn_test_groups()==1,"spawn49_redo");
    fb_selection_clear();fb_createbox('512 0 64','64 64 64');fb_entity_create("func_button",TRUE,'0 0 0');fb_document_tick();fb_entity_targets();fb_spawn_test_second=fb_property_entities[0];fb_spawn_prepare();marker=history;
    valid=fb_spawn_apply("spawn_destination","light");fb_document_tick();fb_transform_expect(valid&&fb_spawn_test_groups()==1&&fb_spawn_test_count("trigger_teleport")==2,"spawn49_shared_expansion");
    fb_transform_expect(fb_entity_field(fb_spawn_test_source,"target")!=fb_entity_field(fb_spawn_test_second,"target"),"spawn49_unique_targets");
    brush_undo();fb_document_tick();fb_transform_expect(history==marker&&fb_spawn_test_groups()==1&&fb_spawn_test_count("trigger_teleport")==1,"spawn49_expansion_undo");brush_redo();fb_document_tick();
    fb_selection_clear();fb_entity_select(fb_spawn_test_source,TRUE);fb_spawn_prepare();marker=history;valid=fb_spawn_apply("missing_destination","light");fb_transform_expect(!valid&&history==marker,"spawn49_missing_destination");
    valid=fb_spawn_apply("spawn_destination","worldspawn");fb_transform_expect(!valid&&history==marker,"spawn49_invalid_class");
    fb_selection_clear();fb_entity_select(fb_spawn_test_second,TRUE);valid=fb_spawn_apply("spawn_destination","light");fb_transform_expect(!valid&&history==marker,"spawn49_stale_selection");
    fb_spawn_prepare();valid=fb_spawn_apply("spawn_destination","light");fb_document_tick();fb_transform_expect(valid&&fb_spawn_test_count("trigger_teleport")==2&&fb_spawn_test_groups()==1,"spawn49_reconfigure");
    fb_selection_clear();fb_entity_select(fb_spawn_test_source,TRUE);fb_spawn_prepare();fb_camera_position('600 -700 -600');setproperty(VF_CL_VIEWANGLES,'15 130 0');
}
// Save/load must preserve enough metadata to rebuild rather than duplicate the closet.
void fb_spawn_reload_tests()
{
    fb_document_tick();int source=-1;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_ENTITY&&fb_nodes[n].fields["_tb_spawn_master_destination"]=="spawn_destination")source=fb_nodes[n].id;
    fb_transform_expect(source>0&&fb_spawn_test_groups()==1&&fb_spawn_test_count("trigger_teleport")==2,"spawn49_reload_metadata");
    fb_selection_clear();fb_entity_select(source,TRUE);fb_spawn_prepare();int valid=fb_spawn_apply("spawn_destination","light");fb_document_tick();
    fb_transform_expect(valid&&fb_spawn_test_groups()==1&&fb_spawn_test_count("trigger_teleport")==2,"spawn49_reload_reconfigure");
}
