// SPDX-License-Identifier: GPL-3.0-or-later
void fb_array_preview_tests()
{
    fb_tool_deactivate();fb_selection_clear();fb_createbox('0 0 128','32 32 32');fb_document_tick();int marker=history;
    cvar_set("ftebroom_array_mode","0");cvar_set("ftebroom_array_count","3");cvar_set("ftebroom_array_x","64");cvar_set("ftebroom_array_y","0");cvar_set("ftebroom_array_z","0");
    tokenize("ftebroom_array preview");fb_array_command();
    fb_transform_expect(fb_array_active&&fb_generator_count==3&&history==marker&&selectedbrushcount==1&&cvar("ftebroom_array_valid"),"array48_preview_immutable");
    fb_transform_expect(fb_generator_items[2].poly.volume>32767&&!fb_generator_hide_original,"array48_volume_original_visible");
    cvar_set("ftebroom_array_count","5");tokenize("ftebroom_array preview");fb_array_command();fb_transform_expect(fb_generator_count==5,"array48_live_count");
    tokenize("ftebroom_undo");fb_array_command();fb_transform_expect(fb_generator_count==3&&cvar("ftebroom_array_count")==3&&history==marker,"array48_settings_undo");
    tokenize("ftebroom_redo");fb_array_command();fb_transform_expect(fb_generator_count==5,"array48_settings_redo");
    cvar_set("ftebroom_array_count","513");tokenize("ftebroom_array preview");fb_array_command();fb_transform_expect(!fb_generator_count&&!cvar("ftebroom_array_valid")&&history==marker,"array48_invalid_immutable");
    tokenize("ftebroom_undo");fb_array_command();fb_transform_expect(fb_generator_count==5&&cvar("ftebroom_array_valid"),"array48_undo_invalid");
    tokenize("ftebroom_array apply");fb_array_command();fb_transform_expect(selectedbrushcount==5&&!fb_array_active&&!fb_generator_count,"array48_apply");brush_undo();fb_document_tick();fb_transform_expect(history==marker&&selectedbrushcount==1,"array48_one_document_undo");
    tokenize("ftebroom_array preview");fb_array_command();tokenize("ftebroom_array cancel");fb_array_command();fb_transform_expect(history==marker&&!fb_array_active&&!fb_generator_count,"array48_cancel");
    int id=selectedbrushes[0].id,model=selectedbrushes[0].model;brush_deselectall();brushface_select(model,id,6);fb_patch_convert();fb_document_tick();marker=history;
    cvar_set("ftebroom_array_count","2");tokenize("ftebroom_array preview");fb_array_command();fb_transform_expect(fb_generator_count==2&&fb_generator_items[0].points&&history==marker,"array48_patch_preview");
    tokenize("ftebroom_array cancel");fb_array_command();brush_undo();fb_document_tick();fb_selection_clear();fb_entity_create("info_player_start",FALSE,'0 0 192');fb_document_tick();marker=history;
    tokenize("ftebroom_array preview");fb_array_command();fb_transform_expect(fb_array_entity_count==2&&!fb_generator_count&&history==marker,"array48_entity_preview");
    fb_selection_clear();fb_array_draw();fb_transform_expect(!fb_array_active&&!fb_array_entity_count,"array48_stale_rejected");
    tokenize("ftebroom_array apply");fb_array_command();fb_transform_expect(history==marker,"array48_stale_apply_rejected");
    fb_entity_create("info_player_start",FALSE,'-64 0 192');fb_document_tick();tokenize("ftebroom_array preview");fb_array_command();fb_camera_position('320 -420 340');setproperty(VF_CL_VIEWANGLES,'20 130 0');
}
