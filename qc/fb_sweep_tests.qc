// SPDX-License-Identifier: GPL-2.0-or-later
void fb_sweep_expect(int ok,string label){print(strcat(ok?"FTEBROOM_SWEEP_PASS ":"FTEBROOM_SWEEP_FAIL ",label,"\n"));}
int fb_sweep_testcommand()
{
    if(argv(0)!="ftebroom_test_sweep" || !cvar("ftebroom_skip_setup"))return FALSE;
    fb_tool_deactivate();fb_open_group=0;int id=fb_createbox('0 0 32','32 32 64');brush_deselectall();brushface_select(1,id,6);
    fb_tool_activate(FB_TOOL_SWEEP);int marker=history;fb_sweep_offset='0 0 128';
    cvar_set("ftebroom_sweep_segments","4");cvar_set("ftebroom_sweep_iterations","1");cvar_set("ftebroom_sweep_path","straight");
    int valid=fb_sweep_build(),uniform=valid && fb_sweep_solid_count==4;
    if(uniform)for(int i=0;i<4;i++)if(fabs(fb_sweep_solids[i].volume-32*32*32)>1)uniform=FALSE;
    fb_sweep_expect(uniform && history==marker,"straight_four_cuboids_preview");
    fb_sweep_perform();fb_sweep_expect(selectedbrushcount==4 && !cvar("ftebroom_tool"),"perform_selects_new_brushes");
    brush_undo();fb_sweep_expect(history==marker && selectedbrushcount==1 && fb_faces_count()==1,"single_undo_restores_faces");
    brush_deselectall();brushface_select(selectedbrushmodel,id,4);fb_tool_activate(FB_TOOL_SWEEP);
    fb_sweep_offset='128 128 64';fb_sweep_rotate('0 0 1',90);cvar_set("ftebroom_sweep_segments","8");
    for(int mode=0;mode<3;mode++) {
        string path="straight";if(mode==1)path="arc";if(mode==2)path="sbend";cvar_set("ftebroom_sweep_path",path);
        fb_affine_t end;fb_sweep_map(1,&end);vector final=fb_affine_point(&end,fb_sweep_center);
        fb_sweep_expect(vlen(final-fb_sweep_center-fb_sweep_offset)<0.001,strcat(path,"_endpoint"));
    }
    cvar_set("ftebroom_sweep_path","arc");valid=fb_sweep_build();int joined=valid;
    if(joined)for(int i=0;i<fb_sweep_solid_count-1;i++) {
        int shared=0;fb_poly_t *a=&fb_sweep_solids[i];fb_poly_t *b=&fb_sweep_solids[i+1];
        for(int p=0;p<a->nv;p++)for(int q=0;q<b->nv;q++)if(vlen(a->vertices[p]-b->vertices[q])<0.001){shared++;break;}
        if(shared<4)joined=FALSE;
    }
    fb_sweep_expect(joined,"arc_shared_segment_caps");
    cvar_set("ftebroom_sweep_iterations","4");fb_sweep_expect(fb_sweep_build() && fb_sweep_solid_count==32,"four_arc_iterations");
    fb_tool_escape();fb_sweep_expect(cvar("ftebroom_tool")==FB_TOOL_SWEEP && fb_sweep_offset=='0 0 0',"first_escape_resets_cap");
    fb_tool_escape();fb_sweep_expect(!cvar("ftebroom_tool") && !fb_sweep_count,"second_escape_exits");
    cvar_set("ftebroom_sweep_iterations","1");return TRUE;
}
