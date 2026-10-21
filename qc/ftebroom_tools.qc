void fb_rotate_reset();
void fb_rotate_cancel();
void fb_rotate_down(vector pixel,int alt,int view);
void fb_rotate_move(vector pixel,int alt,int view);
void fb_rotate_up(vector pixel,int alt,int view);
void fb_rotate_draw();
int fb_vertex_tool();
void fb_vertex_rebuild();
void fb_vertex_clear();
void fb_vertex_deselect();
void fb_vertex_down(vector pixel,int alt,int view);
void fb_vertex_move(vector pixel,int alt,int view);
void fb_vertex_up(vector pixel,int alt,int view);
void fb_vertex_draw();
int fb_vertex_selection_count();
int fb_vertex_scope,fb_vertex_preserve;
int fb_moveface_active;
void fb_moveface_move(vector pixel,int view);
void fb_moveface_up(vector pixel,int view);
int fb_scale_tool();
void fb_scale_down(vector pixel,int alt,int view);
void fb_scale_move(vector pixel,int alt,int view);
void fb_scale_up(vector pixel,int alt,int view);
void fb_scale_draw();
void fb_assemble_down(vector pixel,int view);
void fb_assemble_move(vector pixel,int view);
void fb_assemble_up(vector pixel,int view);
void fb_assemble_draw();
void fb_assemble_apply();
// SPDX-License-Identifier: GPL-2.0-or-later
// Modal lifecycle and gesture ownership. Geometry tools are implemented in later tasks.
enum : int { FB_TOOL_NONE, FB_TOOL_BRUSH, FB_TOOL_CLIP, FB_TOOL_ROTATE,
    FB_TOOL_SWEEP, FB_TOOL_SCALE, FB_TOOL_SHEAR, FB_TOOL_VERTEX, FB_TOOL_EDGE,
    FB_TOOL_FACE, FB_TOOL_CONTROLPOINT };
enum : int { FB_OWNER_NONE, FB_OWNER_MOVE, FB_OWNER_SHAPE, FB_OWNER_SELECTION, FB_OWNER_MODAL, FB_OWNER_MATERIAL, FB_OWNER_EXTRUDE };
int fb_owner, fb_handle_count, fb_shape_count;
float fb_active;
vector fb_clip_points[3];
int fb_clip_count;
void fb_cancel();
void fb_begin(vector pixel,float alt,int view);
void fb_update(vector pixel,float alt,int view);
void fb_finish(vector pixel,float alt,int view);
void fb_clip_pick(vector pixel,int view);
void fb_clip_down(vector pixel,int view);
void fb_clip_move(vector pixel,int view);
void fb_clip_up(vector pixel,int view);
void fb_clip_double(vector pixel,int view);
void fb_clip_cancel_drag();
void fb_clip_apply();
void fb_clip_preview();
void fb_tool_panel_state()
{
    cvar_set("ftebroom_handle_count",itos(fb_handle_count));
    cvar_set("ftebroom_shape_points",itos(fb_shape_count));
    cvar_set("ftebroom_gesture_owner",itos(fb_owner));
}
float fb_tool_can_activate(int tool) { return tool>=FB_TOOL_NONE && tool<=FB_TOOL_CONTROLPOINT; }
void fb_tool_refresh()
{
    fb_cancel(); fb_owner=FB_OWNER_NONE;
    fb_clip_count=fb_shape_count=fb_handle_count=0;
    fb_pick_clear_handles();
    if(!fb_vertex_preserve) {fb_vertex_clear();fb_vertex_scope=FALSE;}
    vertedit.selectedvert1=vertedit.selectedvert2=-1;
    fb_tool_panel_state();
}
void fb_tool_deactivate()
{
    fb_tool_refresh(); cvar_set("ftebroom_tool","0");
}
void fb_tool_activate(int tool)
{
    if(!fb_tool_can_activate(tool)) return;
    int affine=tool==FB_TOOL_ROTATE || tool==FB_TOOL_SCALE || tool==FB_TOOL_SHEAR;
    fb_vertex_preserve=FALSE;
    if(affine) if(fb_vertex_tool() || fb_vertex_scope) if(fb_vertex_selection_count()>0) fb_vertex_preserve=TRUE;
    fb_tool_deactivate(); cvar_set("ftebroom_tool",itos(tool));
    fb_vertex_scope=fb_vertex_preserve;fb_vertex_preserve=FALSE;
    if(fb_vertex_scope) fb_vertex_selection_count();
    if(tool==FB_TOOL_ROTATE) fb_rotate_reset();
    if(fb_vertex_tool()) fb_vertex_rebuild();
}
int fb_tool_id(string name)
{
    if(name=="default") return FB_TOOL_NONE;
    if(name=="brush") return FB_TOOL_BRUSH;
    if(name=="clip") return FB_TOOL_CLIP;
    if(name=="rotate") return FB_TOOL_ROTATE;
    if(name=="sweep") return FB_TOOL_SWEEP;
    if(name=="scale") return FB_TOOL_SCALE;
    if(name=="shear") return FB_TOOL_SHEAR;
    if(name=="vertex") return FB_TOOL_VERTEX;
    if(name=="edge") return FB_TOOL_EDGE;
    if(name=="face") return FB_TOOL_FACE;
    if(name=="controlpoint") return FB_TOOL_CONTROLPOINT;
    return -1;
}
float fb_tool_cancel()
{
    int tool=cvar("ftebroom_tool");
    if(tool==FB_TOOL_CLIP && fb_clip_count>0) {fb_clip_count--; return TRUE;}
    if(tool==FB_TOOL_BRUSH && fb_shape_count>0) {fb_shape_count=0; return TRUE;}
    if(fb_handle_count>0) {fb_vertex_deselect();fb_handle_count=0; vertedit.selectedvert1=vertedit.selectedvert2=-1; return TRUE;}
    return FALSE;
}
void fb_tool_escape()
{
    if(fb_active) {fb_cancel();fb_owner=FB_OWNER_NONE;return;}
    if(cvar("ftebroom_tool")) {
        if(!fb_tool_cancel()) fb_tool_deactivate();
    } else brush_history_deselect();
    fb_tool_panel_state();
}
void fb_tool_pointer_down(vector pixel,float alt,int view)
{
    int tool=cvar("ftebroom_tool");
    fb_owner=FB_OWNER_MODAL;
    if(tool==FB_TOOL_CLIP) fb_clip_down(pixel,view);
    else if(fb_vertex_tool()) fb_vertex_down(pixel,alt,view);
    else if(fb_scale_tool()) fb_scale_down(pixel,alt,view);
    else if(tool==FB_TOOL_NONE) fb_begin(pixel,alt,view);
    else if(tool==FB_TOOL_ROTATE) fb_rotate_down(pixel,alt,view);
    else if(tool==FB_TOOL_BRUSH) fb_assemble_down(pixel,view);
    else print("FTEBroom: modal tool framework active; geometry editing follows in its roadmap task.\n");
}
void fb_tool_pointer_move(vector pixel,float alt,int view)
{
    if(fb_moveface_active)fb_moveface_move(pixel,view);
    else if(cvar("ftebroom_tool")==FB_TOOL_CLIP) fb_clip_move(pixel,view);
    else if(fb_vertex_tool()) fb_vertex_move(pixel,alt,view);
    else if(fb_scale_tool()) fb_scale_move(pixel,alt,view);
    else if(cvar("ftebroom_tool")==FB_TOOL_BRUSH) fb_assemble_move(pixel,view);
    else if(cvar("ftebroom_tool")==FB_TOOL_ROTATE) fb_rotate_move(pixel,alt,view);
    else if(fb_owner!=FB_OWNER_NONE) fb_update(pixel,alt,view);
}
void fb_tool_pointer_up(vector pixel,float alt,int view)
{
    if(fb_moveface_active)fb_moveface_up(pixel,view);
    else if(cvar("ftebroom_tool")==FB_TOOL_CLIP) fb_clip_up(pixel,view);
    else if(fb_vertex_tool()) fb_vertex_up(pixel,alt,view);
    else if(fb_scale_tool()) fb_scale_up(pixel,alt,view);
    else if(cvar("ftebroom_tool")==FB_TOOL_BRUSH) fb_assemble_up(pixel,view);
    else if(cvar("ftebroom_tool")==FB_TOOL_ROTATE) fb_rotate_up(pixel,alt,view);
    else if(fb_owner!=FB_OWNER_MODAL) fb_finish(pixel,alt,view);
    fb_owner=FB_OWNER_NONE;
}
void fb_tool_double_click(vector pixel,float alt,int view) { fb_tool_pointer_down(pixel,alt,view); fb_tool_pointer_up(pixel,alt,view); }
void fb_tool_scroll(float delta) { }
void fb_tool_draw() { fb_clip_preview();fb_rotate_draw();fb_vertex_draw();fb_scale_draw();fb_assemble_draw(); }
void fb_tools_test()
{
    string mode=argv(1);
    if(mode=="points") {
        fb_clip_points[0]='0 -64 64';fb_clip_points[1]='0 64 64';fb_clip_points[2]='0 64 128';fb_clip_count=3;
    } else if(mode=="handles") fb_handle_count=2;
    else if(mode=="state") print(sprintf("FTEBROOM_TOOLS %s tool=%g points=%i handles=%i selected=%i active=%g\n",argv(2),cvar("ftebroom_tool"),fb_clip_count,fb_handle_count,selectedbrushcount,fb_active));
}
void fb_tool_key(string key)
{
    if(cvar("ftebroom_tool")==FB_TOOL_BRUSH && key=="apply") {fb_assemble_apply();return;}
    if(cvar("ftebroom_tool")!=FB_TOOL_CLIP) return;
    if(key=="apply") fb_clip_apply();
    else if(key=="side") cvar_set("ftebroom_clip_keep",itos((cvar("ftebroom_clip_keep")+1)%3));
    else if(key=="back") {
        if(fb_clip_count>0) fb_tool_cancel();

    }
}
float fb_tools_command()
{
    string cmd=argv(0);
    if(cmd=="ftebroom_test_tools") {
        if(cvar("ftebroom_skip_setup")) fb_tools_test();
    } else if(cmd=="ftebroom_tool_toggle") {
        int tool=fb_tool_id(argv(1));
        if(!fb_tool_can_activate(tool)) print("FTEBroom: unknown tool.\n");
        else if(tool==cvar("ftebroom_tool")) fb_tool_deactivate();
        else fb_tool_activate(tool);
    } else if(cmd=="ftebroom_tool_deactivate") fb_tool_deactivate();
    else if(cmd=="ftebroom_cancel") fb_tool_escape();
    else if(cmd=="ftebroom_tool_key") fb_tool_key(argv(1));
    else return FALSE;
    return TRUE;
}
