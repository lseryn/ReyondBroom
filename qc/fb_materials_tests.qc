// SPDX-License-Identifier: GPL-2.0-or-later
int fb_material_test_id;
float fb_material_testcommand()
{
    if(argv(0)!="ftebroom_test_materials" || !cvar("ftebroom_skip_setup")) return FALSE;
    if(argv(1)=="edit") {
        fb_selection_clear();fb_material_test_id=fb_createbox('0 0 128','64 64 64');
        static brushface_t faces[6];int contents;
        brush_get(1,fb_material_test_id,faces,6,&contents);
        faces[0].sbias=0;faces[1].sbias=8;faces[2].sbias=20;
        fb_tx_begin("Fixture attributes");fb_material_test_id=brush_history_edit(1,fb_material_test_id,faces,6,contents);fb_tx_commit();
        brush_deselectall();for(int f=1;f<=3;f++) brushface_select(1,fb_material_test_id,f);
        fb_material_change("ox",16,TRUE);
        brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(faces[0].sbias==16 && faces[1].sbias==24 && faces[2].sbias==36,"offset_delta_preserves_differences");
        fb_material_edit("ox",32);brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(faces[0].sbias==32 && faces[1].sbias==32 && faces[2].sbias==32,"offset_absolute_three_faces");
        vector s=faces[0].sdir,t=faces[0].tdir;
        fb_material_change("angle",15,TRUE);fb_material_change("angle",15,TRUE);
        fb_material_change("angle",-30,TRUE);brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(vlen(faces[0].sdir-s)<0.0001 && vlen(faces[0].tdir-t)<0.0001,"angle_roundtrip_preserves_axes");
        fb_material_flags("surface",0x80000001i,FALSE);fb_material_flags("value",123456789i,FALSE);
        brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(faces[0].surfaceflags==0x80000001i && faces[2].surfaceflags==0x80000001i && faces[3].surfaceflags==0,"flags_exact_and_selected_only");
        fb_transform_expect(faces[0].surfacevalue==123456789i,"surface_value_exact_integer");
        fb_material_state();fb_transform_expect((int)cvar("ftebroom_uv_mixed")==0,"uniform_fields_not_mixed");
        int before=history;fb_material_edit("sx",0);
        fb_transform_expect(history==before,"zero_scale_rejected_atomically");
        fb_material_edit("sx",2);fb_material_edit("sy",0.5);
        brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(fabs(vlen(faces[0].sdir)-0.5)<0.0001 && fabs(vlen(faces[0].tdir)-2)<0.0001,"independent_scales");
        float bias=faces[0].tbias;
        fb_texture_key("vertical",1,0);fb_texture_key("vertical",-1,0);
        brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(fabs(faces[0].tbias-bias)<0.0001,"keyboard_texture_roundtrip");
        cvar_set("ca_newbrushtexture","ftebroom/qa_red");fb_material_edit("material",0);
        cvar_set("ftebroom_replace_from","ftebroom/qa_red");cvar_set("ftebroom_replace_to","ftebroom/qa_blue");
        int replaceBefore=history;fb_material_replace();
        fb_transform_expect(fb_faces_count()==3,"replace_selects_changed_faces");
        brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(faces[0].shadername=="ftebroom/qa_blue" && faces[2].shadername=="ftebroom/qa_blue" && faces[3].shadername=="ftebroom/grid","replace_selected_scope");
        brush_undo();brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(history==replaceBefore && faces[0].shadername=="ftebroom/qa_red","replace_one_undo");
        brush_redo();
        cvar_set("ftebroom_material_query","ftebroom/qa_blue");fb_material_select("faces");
        fb_transform_expect(fb_faces_count()==3,"select_material_faces");
        fb_material_usage();
        brush_deselectall();fb_createbox('256 0 128','128 64 32');fb_faces_convert();
        int fitId=selectedbrushes[0].id;brush_deselectall();brushface_select(1,fitId,3);
        cvar_set("ca_newbrushtexture","ftebroom/grid");fb_material_edit("material",0);fb_texture_key("world",1,0);
        vector image=drawgetimagesize("textures/ftebroom/grid");
        fb_texture_align("fit_h",1,FALSE);brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(image_x>0 && fabs(vlen(faces[2].sdir)-image_x/128)<0.0001,"fit_h_one_repeat");
        fb_texture_align("fit_h",1,FALSE);brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(fabs(vlen(faces[2].sdir)-image_x*2/128)<0.0001,"fit_h_two_repeats");
        fb_texture_align("fit_h",1,TRUE);brush_get(1,selectedbrushes[0].id,faces,6,&contents);
        fb_transform_expect(fabs(vlen(faces[2].sdir)-image_x/256)<0.0001,"fit_h_half_texture");
        fb_texture_align("auto",1,FALSE);
        fb_transform_expect(fb_faces_count()==1,"auto_fit_preserves_face_selection");
    }
    return TRUE;
}
