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
    cvar_set("ca_brush_view","0");fb_rotate_reset();
    return TRUE;
}
