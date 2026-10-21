// SPDX-License-Identifier: GPL-2.0-or-later
void fb_assemble_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_ASSEMBLE_PASS ":"FTEBROOM_ASSEMBLE_FAIL ",label,"\n"));}
float fb_assemble_testcommand()
{
    if(argv(0)!="ftebroom_test_assemble" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_cancel();fb_selection_clear();fb_createbox('0 0 64','128 128 128');fb_tool_activate(FB_TOOL_BRUSH);
    vector pixel=project('0 0 128');pixel_z=0;int marker=history;
    fb_assemble_double(pixel,0);fb_assemble_expect(fb_shape_count==4,"double_click_face_vertices");
    int outline[512];fb_assemble_expect(fb_assemble_outline(outline)==4,"flat_polygon_outline");
    fb_assemble_apply();fb_assemble_expect(history==marker && fb_shape_count==4,"flat_polygon_not_created");
    cvar_set("ftebroom_shift","1");fb_assemble_down(pixel,0);
    vector end=project('0 0 192');end_z=0;fb_assemble_move(end,0);
    fb_assemble_expect(fb_shape_count==8 && history==marker,"shift_extrusion_preview");
    fb_tool_escape();fb_assemble_expect(fb_shape_count==4 && !fb_active,"escape_restores_polygon");
    fb_assemble_down(pixel,0);fb_assemble_up(end,0);cvar_set("ftebroom_shift","0");fb_assemble_apply();
    fb_poly_t poly={0};fb_poly_from_brush(1,selectedbrushes[0].id,&poly);
    fb_assemble_expect(selectedbrushcount==1 && fabs(poly.volume-128*128*64)<2,"create_prism_volume");fb_poly_free(&poly);
    fb_assemble_expect(!fb_shape_count && cvar("ftebroom_tool")==FB_TOOL_BRUSH,"tool_stays_active");
    brush_undo();fb_assemble_expect(history==marker && selectedbrushcount==1,"single_undo");
    brush_redo();fb_assemble_expect(selectedbrushcount==1,"redo_created_brush");brush_undo();
    fb_shape_count=0;fb_assemble_down(pixel,2);fb_assemble_expect(!fb_shape_count,"reject_points_in_2d");
    fb_assemble_double(pixel,0);fb_tool_escape();fb_assemble_expect(!fb_shape_count && cvar("ftebroom_tool")==FB_TOOL_BRUSH,"escape_clears_all_points");
    fb_assemble_double(pixel,0);
    return TRUE;
}
