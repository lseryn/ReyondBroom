// SPDX-License-Identifier: GPL-2.0-or-later
void fb_patch_expect(int ok,string label){print(strcat(ok?"FTEBROOM_PATCH_PASS ":"FTEBROOM_PATCH_FAIL ",label,"\n"));}
int fb_patch_testcommand()
{
    if(argv(0)!="ftebroom_test_patches" || !cvar("ftebroom_skip_setup"))return FALSE;
    fb_tool_deactivate();fb_open_group=0;int id=fb_createbox('0 0 64','128 128 128');
    brush_deselectall();brushface_select(1,id,6);int marker=history;fb_patch_convert();
    patchinfo_t info;int count=0;if(selectedbrushcount==1)count=patch_getcp(selectedbrushes[0].model,selectedbrushes[0].id,__NULL__,0,&info);
    fb_patch_expect(count==9 && !brush_get(1,id,__NULL__,0,__NULL__),"quad_conversion_removes_source");
    brush_undo();fb_patch_expect(history==marker && selectedbrushcount==1,"conversion_single_undo");brush_redo();
    fb_tool_activate(FB_TOOL_CONTROLPOINT);fb_patch_expect(fb_vertex_count==9,"nine_handles");
    fb_vertex_handles[4].selected=TRUE;fb_vertex_nudge('0 0 64');
    fb_patch_expect(fb_vertex_selection_count()==1 && fb_vertex_handles[4].point[2]==192,"central_point_dome");
    patchvert_t original[9];patch_getcp(selectedbrushes[0].model,selectedbrushes[0].id,original,9,&info);
    fb_patch_resize(0,5);patchvert_t enlarged[15];patch_getcp(selectedbrushes[0].model,selectedbrushes[0].id,enlarged,15,&info);
    float error=0;
    for(int row=0;row<3;row++)for(int sample=0;sample<=20;sample++) {
        patchvert_t before,after;float t=(float)sample/20;
        fb_patch_curve(&original[row*3],3,1,t,&before);fb_patch_curve(&enlarged[row*5],5,1,t,&after);
        error=max(error,vlen(before.xyz-after.xyz));error=max(error,fabs(before.s-after.s)+fabs(before.t-after.t));
    }
    fb_patch_expect(info.cpwidth==5 && error<0.001,"subdivision_preserves_surface_and_uv");
    fb_patch_resize(0,3);patchvert_t reduced[9];patch_getcp(selectedbrushes[0].model,selectedbrushes[0].id,reduced,9,&info);error=0;
    for(int p=0;p<9;p++)error=max(error,vlen(original[p].xyz-reduced[p].xyz));
    fb_patch_expect(error<0.001,"reduction_reconstructs_single_quadratic");
    marker=history;fb_vertex_handles[4].selected=TRUE;fb_vertex_delete();fb_patch_expect(history==marker,"delete_control_point_blocked");
    fb_tool_deactivate();
    for(int sides=5;sides<=8;sides+=3) {
        cvar_set("ftebroom_shape","cylinder");cvar_set("ftebroom_shape_sides",itos(sides));
        fb_primitive_create('256 0 0','384 128 128',FALSE);
        int model=selectedbrushes[0].model;id=selectedbrushes[0].id;brushface_t faces[64];int nf=brush_get(model,id,faces,64,__NULL__),top=-1;
        for(int f=0;f<nf;f++)if(faces[f].planenormal=='0 0 1')top=f+1;
        brush_deselectall();brushface_select(model,id,top);fb_patch_convert();
        int expected=(sides-1)/2;
        fb_patch_expect(selectedbrushcount==expected,sides==5?"pentagon_two_patches":"octagon_three_patches");
    }
    cvar_set("ftebroom_shape","cuboid");fb_tool_activate(FB_TOOL_CONTROLPOINT);
    fb_patch_expect(fb_vertex_count<selectedbrushcount*9,"coincident_handles_shared");
    return TRUE;
}
