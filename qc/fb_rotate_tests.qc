// SPDX-License-Identifier: GPL-2.0-or-later
float fb_rotate_testcommand()
{
    if(argv(0)!="ftebroom_test_rotate" || !cvar("ftebroom_skip_setup")) return FALSE;
    fb_selection_clear();fb_createbox('0 0 128','64 32 32');
    cvar_set("ca_brush_view","3");cvar_set("ca_brush_viewsize","1024");fb_view_prepare();
    fb_tool_activate(FB_TOOL_ROTATE);cvar_set("ftebroom_rotate_step","15");
    vector initial=fb_rotate_center;
    vector start=project(fb_rotate_ring_point(2,0,TRUE));start_z=0;
    vector end=project(fb_rotate_ring_point(2,40.0/360,TRUE));end_z=0;
    int before=history;
    fb_rotate_down(start,0,3);fb_rotate_move(end,0,3);
    fb_transform_expect(fb_rotate_drag==2 && fb_affine_preview_active && fabs(fb_rotate_angle-45)<0.001,"ring_drag_snaps_40_to_45");
    fb_transform_expect(history==before,"rotation_preview_no_history");
    fb_cancel();fb_transform_expect(!fb_affine_preview_active && history==before,"rotation_escape_no_change");
    fb_rotate_down(start,0,3);fb_rotate_up(end,0,3);
    fb_transform_expect(history>before && !fb_affine_preview_active,"rotation_release_commits");
    brush_undo();fb_transform_expect(history==before,"rotation_gesture_single_undo");
    vector centerPixel=project(fb_rotate_center);centerPixel_z=0;
    fb_rotate_down(centerPixel,0,3);fb_rotate_move(centerPixel+'64 0 0',0,3);
    fb_transform_expect(fb_rotate_drag==1 && vlen(fb_rotate_center-initial)>1 && history==before,"center_drag_does_not_edit_map");
    fb_cancel();fb_transform_expect(fb_rotate_center==initial && history==before,"center_escape_restores_pivot");
    fb_rotate_down(centerPixel,0,3);fb_rotate_up(centerPixel+'64 0 0',0,3);vector moved=fb_rotate_center;
    fb_transform_expect(moved!=initial,"center_release_moves_pivot");
    brush_undo();fb_transform_expect(fb_rotate_center==initial && history==before,"center_undo");
    brush_redo();fb_transform_expect(fb_rotate_center==moved,"center_redo");
    cvar_set("ftebroom_rotate_pick_center","1");
    vector target=project('192 96 128');target_z=0;fb_rotate_down(target,0,3);
    fb_transform_expect(!cvar("ftebroom_rotate_pick_center")&&vlen(fb_rotate_center-moved)>1,"pick_rotation_center");
    fb_tool_activate(FB_TOOL_GRIDROTATE);fb_rotate_center='32 48 16';fb_rotate_publish();
    vector pivotLocal=fb_grid_local(fb_rotate_center);int gridHistory=history;
    start=project(fb_rotate_ring_point(2,0,TRUE));start_z=0;
    end=project(fb_rotate_ring_point(2,37.0/360,TRUE));end_z=0;
    fb_rotate_down(start,0,3);fb_rotate_move(end,0,3);
    fb_transform_expect(fb_rotate_drag==2&&fabs(fb_rotate_angle-37)<0.01,"grid_ring_one_degree");
    fb_transform_expect(vlen(fb_grid_world(pivotLocal)-fb_rotate_center)<0.001&&history==gridHistory,"grid_pivot_fixed_map_untouched");
    fb_cancel();fb_transform_expect(vlen(fb_grid_world('1 2 3')-'1 2 3')<0.001,"grid_cancel_restores");
    cvar_set("ftebroom_grid_rotate_step","15");fb_rotate_down(start,0,3);fb_rotate_up(end,0,3);
    fb_transform_expect(fabs(fb_rotate_angle-30)<0.01,"grid_custom_angle_step");cvar_set("ftebroom_grid_rotate_step","1");
    fb_grid_rotation_capture();fb_grid_rotation_apply('1 0 0',23);
    vector probe='123 -78 54';fb_transform_expect(vlen(fb_grid_world(fb_grid_local(probe))-probe)<0.001,"grid_three_axis_roundtrip");
    vector normal=normalize('1 2 3');fb_transform_expect(fabs(fb_snap_to_plane(probe,normal,7)*normal-7)<0.001,"grid_pivot_plane_constraint");
    fb_transform_expect(vlen(fb_snap_delta('0 0 0'))<0.001,"grid_delta_has_no_origin_offset");
    fb_grid_default();fb_transform_expect(vlen(fb_grid_world(probe)-probe)<0.001,"grid_reset_default");
    fb_tool_activate(FB_TOOL_ROTATE);
    cvar_set("ca_brush_view","0");fb_rotate_reset();
    return TRUE;
}
