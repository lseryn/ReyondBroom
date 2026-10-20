// SPDX-License-Identifier: GPL-2.0-or-later
string fb_clip_test_read(string name)
{
    filestream file=fopen(name,FILE_READ);if((float)file<0) return "";
    string text="",line;while((line=fgets(file))) text=strcat(text,line,"\n");fclose(file);return text;
}
float fb_clip_testcommand()
{
    if(argv(0)!="ftebroom_test_clipboard" || !cvar("ftebroom_skip_setup")) return FALSE;
    if(argv(1)=="parse") {
        int before=history;
        fb_transform_expect(fb_map_parse(fb_clip_test_read("clipboard-standard.map")),"parse_standard_map");
        fb_transform_expect(fb_map_count==3 && fb_map_items[1].count==6 && fb_map_items[1].faces[0].surfaceflags==42 && fb_map_items[1].faces[5].surfacevalue==128,"parse_flags_values");
        fb_map_clear();
        fb_transform_expect(fb_map_parse("{ patchDef3WS { grid ( 3 3 2 4 0 1 1 ) ( ( ( 0 0 0 0 0 1 0 0 1 ) ( 16 0 0 0.5 0 0 1 0 1 ) ( 32 0 0 1 0 0 0 1 1 ) ) ( ( 0 16 0 0 0.5 1 1 1 1 ) ( 16 16 16 0.5 0.5 1 1 1 1 ) ( 32 16 0 1 0.5 1 1 1 1 ) ) ( ( 0 32 0 0 1 1 1 1 1 ) ( 16 32 0 0.5 1 1 1 1 1 ) ( 32 32 0 1 1 1 1 1 1 ) ) ) } }"),"parse_colored_patch_without_entity");
        fb_transform_expect(fb_map_items[0].patch.tesswidth==2 && fb_map_items[0].patch.tessheight==4 && fb_map_items[0].points[0].rgb=='1 0 0',"patch_preserves_subdivisions_colors");
        fb_map_clear();fb_transform_expect(!fb_map_parse("{ \"classname\" }"),"reject_missing_value");
        fb_transform_expect(!fb_map_parse("/* missing close"),"reject_unterminated_comment");
        fb_transform_expect(!fb_map_parse("( 1-2 0 0 ) ( 0 1 0 ) ( 0 0 1 ) grid 0 0 0 1 1"),"reject_malformed_number");
        fb_transform_expect(history==before,"parse_does_not_mutate_history");fb_map_clear();
        fb_selection_clear();fb_document_tick();int count=0;
        for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].kind>=FB_NODE_BRUSH && fb_nodes[i].model==1) {brush_select(1,fb_nodes[i].id);count++;}
        fb_transform_expect(fb_clip_export(),"export_selection");
        fb_transform_expect(fb_map_parse(fb_clip_test_read("clipboard-out.map")),"parse_own_export");
        fb_transform_expect(fb_map_count==count+1,"export_preserves_object_count");
        fb_transform_expect(fb_clip_insert('128 0 0'),"paste_insert");fb_map_clear();
    } else if(argv(1)=="undo") {brush_undo();}
    else if(argv(1)=="redo") {brush_redo();}
    else if(argv(1)=="fixture") {
        fb_transform_expect(fb_map_parse(fb_clip_test_read("clipboard-standard.map")),"parse_fixture_before_insert");
        fb_transform_expect(fb_clip_insert('0 0 0'),"insert_fixture_entities");fb_map_clear();
    }
    if(argv(1)=="group") {
        fb_document_tick();fb_selection_clear();
        int group=-1;
        for(int n=2;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_GROUP && fb_nodes[n].tbid=="20") group=n;
        fb_transform_expect(group>=0,"group_fixture_exists");
        if(group>=0) fb_selection_set(group,TRUE);
        int brushes=selectedbrushcount,points=fb_selected_entity_count;
        fb_transform_expect(brushes==2 && points==1,"select_closed_group_members");
        fb_duplicate_numeric('256 0 0');fb_document_tick();
        fb_transform_expect(selectedbrushcount==brushes && fb_selected_entity_count==points,"duplicate_group_selection");
        int groups=0,doors=0;
        for(int n=2;n<fb_node_count;n++) {
            if(fb_nodes[n].kind==FB_NODE_GROUP) groups++;
            if(fb_nodes[n].kind==FB_NODE_ENTITY && fb_nodes[n].fields["classname"]=="func_door") doors++;
        }
        fb_transform_expect(groups==2 && doors==2,"duplicate_independent_group_entities");
        fb_transform_expect(fb_clip_export(),"export_duplicated_group");
        fb_transform_expect(fb_map_parse(fb_clip_test_read("clipboard-out.map")),"parse_duplicated_group");
        fb_map_clear();
    } else if(argv(1)=="grouppaste") {
        fb_transform_expect(fb_map_parse(fb_clip_test_read("clipboard-out.map")),"parse_group_before_paste");
        fb_transform_expect(fb_clip_insert('0 256 0'),"paste_group");fb_map_clear();fb_document_tick();
        int pastedGroups=0,pastedDoors=0;
        for(int n=2;n<fb_node_count;n++) {
            if(fb_nodes[n].kind==FB_NODE_GROUP) pastedGroups++;
            if(fb_nodes[n].kind==FB_NODE_ENTITY && fb_nodes[n].fields["classname"]=="func_door") pastedDoors++;
        }
        fb_transform_expect(pastedGroups==3 && pastedDoors==3,"paste_preserves_group_entities");
    }
    return TRUE;
}
