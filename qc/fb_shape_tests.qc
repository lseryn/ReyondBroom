// SPDX-License-Identifier: GPL-2.0-or-later
void fb_shape_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_SHAPE_PASS ":"FTEBROOM_SHAPE_FAIL ",name,"\n"));
}
float fb_shape_testcommand()
{
    if(argv(0)!="ftebroom_test_shape" || !cvar("ftebroom_skip_setup")) return FALSE;
    cvar_set("ca_grid","16");cvar_set("ftebroom_grid_snap","1");
    static vector bounds[2];
    fb_view_has_selection=FALSE;
    fb_shape_bounds('0 0 0','48 16 0',0,0,0,'100 100 100',bounds);
    fb_shape_expect(vlen(bounds[1]-bounds[0]-'48 16 16')<0.01,"box_grid_height");
    fb_shape_bounds('0 0 0','48 16 0',0,1,0,'100 100 100',bounds);
    fb_shape_expect(vlen(bounds[1]-bounds[0]-'48 48 16')<0.01,"shift_square");
    fb_shape_bounds('0 0 0','48 16 0',0,1,1,'100 100 100',bounds);
    fb_shape_expect(vlen(bounds[1]-bounds[0]-'48 48 48')<0.01,"shift_alt_cube");
    fb_shape_bounds('0 0 128','-48 16 0',0,0,0,'100 100 0',bounds);
    fb_shape_expect(bounds[0][2]==112 && bounds[1][2]==128 && bounds[0][0]==-48,"ceiling_down");
    fb_shape_bounds('3 5 0','48 16 0',0,0,0,'100 100 100',bounds);
    fb_shape_expect(vlen(bounds[1]-bounds[0]-'64 32 16')<0.01,"outward_snap");
    fb_shape_bounds('0 0 0','48 16 64',0,0,1,'100 100 100',bounds);
    fb_shape_expect(vlen(bounds[1]-bounds[0]-'48 16 64')<0.01,"alt_height");
    fb_view_has_selection=TRUE;fb_view_lastmin='-10 -20 -30';fb_view_lastmax='10 20 30';
    fb_shape_bounds('100 0 100','48 0 16',2,0,0,'100 -200 100',bounds);
    fb_shape_expect(bounds[0][1]==-20 && bounds[1][1]==20,"reference_depth");
    fb_view_has_selection=FALSE;
    fb_shape_bounds('65520 0 0','64 16 0',0,0,0,'0 100 100',bounds);
    fb_shape_expect(bounds[1][0]==65536,"world_clip");
    fb_shape_expect(!fb_shape_bounds('65536 0 0','64 16 0',0,0,0,'0 100 100',bounds),"empty_world_reject");
    cvar_set("ftebroom_shift","0");cvar_set("ftebroom_ctrl","0");cvar_set("ca_brush_view","0");
    fb_createbox('0 0 64','128 128 128');
    int before=history;
    vector start=project('800 800 0'),end=project('900 900 0');start_z=end_z=0;
    fb_begin(start,0,0);fb_finish(end,0,0);
    fb_shape_expect(history==before && selectedbrushcount==1,"selection_blocks_creation");
    fb_selection_clear();fb_begin(start,0,0);fb_update(end,0,0);fb_cancel();
    fb_shape_expect(history==before,"cancel_no_history");
    return TRUE;
}
