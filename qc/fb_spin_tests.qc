// SPDX-License-Identifier: GPL-3.0-or-later
void fb_spin_tests()
{
    fb_tool_deactivate();fb_selection_clear();cvar_set("ca_grid","16");fb_createbox('0 0 128','128 128 128');fb_document_tick();
    int original=selectedbrushes[0].id,model=selectedbrushes[0].model,marker=history;brushface_t *faces=memalloc(64*sizeof(brushface_t));int count=brush_get(model,original,faces,64,__NULL__);
    selbrush_reset_mask(&selectedbrushes[0],FALSE);for(int f=0;f<count;f++)if(faces[f].planenormal[2]>.99)selbrush_set_face(&selectedbrushes[0],f,TRUE);memfree(faces);
    fb_tool_activate(FB_TOOL_SPIN);float volume=0;for(int i=0;i<fb_generator_count;i++)volume+=fb_generator_items[i].poly.volume;
    fb_transform_expect(fb_spin_captured&&!fb_bend_count&&!fb_polygon_captured&&fb_spin_valid&&fb_generator_count==6&&history==marker&&fabs(volume-128*128*96)<1,"spin48_initial_preview");
    cvar_set("ca_brush_view","2");cvar_set("ca_brush_viewsize","1024");fb_view_prepare();cvar_set("ftebroom_spin_mode","0");cvar_set("ftebroom_spin_component","0");cvar_set("ftebroom_ctrl","1");
    vector initial=fb_spin_state.delta,endpoint=fb_spin_center+initial,pixel=project(endpoint),target=project(endpoint+'32 0 16');pixel_z=target_z=0;
    fb_tool_pointer_down(pixel,0,2);fb_spin_lasttime=-100;fb_tool_pointer_move(target,0,2);
    fb_transform_expect(fb_spin_drag&&vlen(fb_spin_state.delta-initial-'32 0 16')<.01&&history==marker,"spin48_drag_endpoint");
    fb_tool_escape();fb_transform_expect(!fb_spin_drag&&fb_spin_state.delta==initial&&fb_spin_valid,"spin48_escape_drag");
    fb_tool_pointer_down(pixel,0,2);fb_tool_pointer_up(target,0,2);vector moved=fb_spin_state.delta;
    tokenize("ftebroom_undo");fb_spin_command();fb_transform_expect(fb_spin_state.delta==initial,"spin48_settings_undo");
    tokenize("ftebroom_redo");fb_spin_command();fb_transform_expect(fb_spin_state.delta==moved,"spin48_settings_redo");
    cvar_set("ftebroom_ctrl","0");cvar_set("ftebroom_spin_mode","1");pixel=project(fb_spin_center+moved);pixel_z=0;
    fb_tool_pointer_down(pixel,0,2);fb_tool_pointer_up(pixel+'0 -20 0',0,2);fb_transform_expect(fb_spin_state.scale>1&&fb_spin_valid,"spin48_scale_handle");
    cvar_set("ftebroom_spin_mode","2");cvar_set("ftebroom_spin_component","3");pixel=project(fb_spin_center+fb_spin_state.delta);pixel_z=0;
    fb_tool_pointer_down(pixel,0,2);fb_tool_pointer_up(pixel+'20 0 0',0,2);fb_transform_expect(fabs(fb_spin_state.rotation[2]-20)<.01&&fb_spin_valid,"spin48_rotate_handle");
    tokenize("ftebroom_spin point 0 0 0");fb_spin_command();fb_transform_expect(!fb_spin_valid&&history==marker&&brush_get(model,original,__NULL__,0,__NULL__)>0,"spin48_invalid_preserves_source");
    tokenize("ftebroom_undo");fb_spin_command();fb_transform_expect(fb_spin_valid,"spin48_undo_invalid");
    tokenize("ftebroom_spin reset");fb_spin_command();fb_transform_expect(fb_spin_state.delta==initial&&fb_spin_state.scale==1&&fb_spin_state.rotation=='0 0 0',"spin48_defaults");
    int applied=fb_spin_tool_apply();fb_transform_expect(applied&&selectedbrushcount==6&&brush_get(model,original,__NULL__,0,__NULL__)>0,"spin48_apply");
    brush_undo();fb_document_tick();fb_transform_expect(history==marker&&selectedbrushcount==1,"spin48_single_undo");brush_redo();fb_document_tick();fb_transform_expect(selectedbrushcount==6,"spin48_redo");brush_undo();fb_document_tick();
    fb_tool_activate(FB_TOOL_SPIN);fb_tool_deactivate();fb_transform_expect(history==marker&&!fb_spin_captured&&!fb_generator_count,"spin48_cancel_tool");
    fb_tool_activate(FB_TOOL_SPIN);cvar_set("ca_brush_view","0");fb_camera_position('360 -420 360');setproperty(VF_CL_VIEWANGLES,'20 130 0');
}
