// SPDX-License-Identifier: GPL-2.0-or-later
int fb_visual_test_a,fb_visual_test_b;
void fb_visual_expect(int condition,string name) {print(strcat(condition?"FTEBROOM_VISUAL_PASS ":"FTEBROOM_VISUAL_FAIL ",name,"\n"));}
float fb_visual_testcommand()
{
    if(argv(0)!="ftebroom_test_visual" || !cvar("ftebroom_skip_setup")) return FALSE;
    string mode=argv(1);static vector bounds[2];
    if(mode=="single") {
        fb_document_tick();fb_selection_clear();
        for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_BRUSH && fb_nodes[n].model==1) {
            brush_getfacepoints(1,fb_nodes[n].id,0,bounds,2);
            vector center=(bounds[0]+bounds[1])*0.5;
            if(vlen(center-'0 0 64')<0.1) fb_visual_test_a=fb_nodes[n].id;
            if(vlen(center-'192 0 32')<0.1) fb_visual_test_b=fb_nodes[n].id;
        }
        fb_visual_expect(fb_visual_test_a && fb_visual_test_b,"fixture");
        brush_select(1,fb_visual_test_a);int before=history;fb_visual_prepare();
        fb_visual_expect(fb_visual_has_bounds && vlen(fb_visual_min-'-64 -64 0')<0.1 && vlen(fb_visual_max-'64 64 128')<0.1,"single_bounds");
        fb_visual_expect(history==before,"render_does_not_change_history");
        int locked=0;for(int i=0;i<fb_node_count;i++) if(fb_nodes[i].kind==FB_NODE_BRUSH && fb_visual_locked(i)) locked++;
        fb_visual_expect(locked==1,"locked_layer_inherited");
        vector collision=fb_visual_spike_trace('64 0 32','320 0 32');
        fb_visual_expect(fb_visual_spike_hit && vlen(collision-'160 0 32')<.01,"spike_first_brush_collision");
        collision=fb_visual_spike_trace('64 0 96','320 0 96');
        fb_visual_expect(!fb_visual_spike_hit && vlen(collision-'320 0 96')<.01,"spike_miss_preserves_length");
        collision=fb_visual_spike_trace('0 0 64','0 0 320');
        fb_visual_expect(!fb_visual_spike_hit,"spike_ignores_selected_brush");
    } else if(mode=="hover") {
        vector pixel=project('0 -64 64');pixel_z=0;curmousepos=pixel;
        cvar_set("ftebroom_mouse_x",ftos(pixel_x));cvar_set("ftebroom_mouse_y",ftos(pixel_y));fb_visual_prepare();
        fb_visual_expect(fb_visual_hover>=0 && fb_visual_spikes,"selected_hover_guides");
    } else if(mode=="multi") {
        brush_select(1,fb_visual_test_b);fb_visual_prepare();
        fb_visual_expect(vlen(fb_visual_max-'224 64 128')<0.1,"combined_bounds");
    } else if(mode=="face") {
        fb_selection_clear();brushface_select(1,fb_visual_test_a,fb_faces_test_top(fb_visual_test_a));fb_visual_prepare();
        fb_visual_expect(fabs(fb_visual_min_z-128)<0.1 && fabs(fb_visual_max_z-128)<0.1,"face_bounds");
    } else if(mode=="labels") {
        fb_visual_expect(fb_visual_label_count==3,"three_dimensions");
    } else if(mode=="off") {
        cvar_set("ftebroom_selection_dimensions","0");cvar_set("ftebroom_hover_highlight","0");cvar_set("ftebroom_selection_spikes","0");fb_visual_prepare();
        fb_visual_expect(fb_visual_hover==-1 && !fb_visual_spikes,"hover_disabled");
        fb_visual_labels();fb_visual_expect(fb_visual_label_count==0,"dimensions_disabled");
    } else if(mode=="on") {
        cvar_set("ftebroom_selection_dimensions","1");cvar_set("ftebroom_hover_highlight","1");cvar_set("ftebroom_selection_spikes","1");
        fb_selection_clear();brush_select(1,fb_visual_test_a);brush_select(1,fb_visual_test_b);
    } else if(mode=="2d") fb_visual_expect(fb_visual_label_count==2,"two_dimensions");
    else if(mode=="clear") {fb_selection_clear();fb_visual_prepare();fb_visual_expect(!fb_visual_has_bounds,"empty_bounds");}
    return TRUE;
}
