// SPDX-License-Identifier: GPL-2.0-or-later
int fb_terrain_stroke;
void fb_terrain_begin()
{
    if(fb_terrain_stroke)return;
    fb_terrain_stroke=(float)terrain_edit(200);
    if(fb_terrain_stroke)fb_tx_begin("Terrain stroke");
}
void fb_terrain_finish()
{
    if(!fb_terrain_stroke)return;
    int handle=(float)terrain_edit(201);fb_terrain_stroke=0;
    if(handle){history_t *h=history_allocate();h->kind=HIST_TERRAIN;h->terrainhandle=handle;}
    fb_tx_commit();fb_tx_lasttime=-100;cvar_set("ftebroom_terrain_dirty","0");
}
void fb_terrain_create(vector position,string material)
{
    if(!cvar("ftebroom_allow_engine_terrain")){print("FTE Engine terrain requires the FTE Custom game profile.\n");return;}
    fb_terrain_finish();fb_terrain_begin();
    if(!fb_terrain_stroke)return;
    terrain_edit(204,position,material);fb_terrain_finish();
    cvar_set("ftebroom_terrain_document","1");cvar_set("ftebroom_terrain_edit","1");
}

void fb_terrain_test32(int stage)
{
    if(!cvar("ftebroom_skip_setup"))return;
    if(stage==3) {
        float allowed=cvar("ftebroom_allow_engine_terrain"),document=cvar("ftebroom_terrain_document");
        cvar_set("ftebroom_allow_engine_terrain","0");fb_terrain_create('2048 2048 64',"textures/ftebroom/grid");
        print(cvar("ftebroom_terrain_document")==document?"FTEBROOM_TERRAIN37_PASS profile_creation_guard\n":"FTEBROOM_TERRAIN37_FAIL profile_creation_guard\n");
        cvar_set("ftebroom_allow_engine_terrain",ftos(allowed));return;
    }
    if(stage==1) {
        fb_terrain_create('2048 2048 64',"textures/ftebroom/grid");
        traceline('2560 2560 512','2560 2560 -512',TRUE,world);
        print(sprintf("FTEBROOM_TERRAIN32_%s create height=%g\n",fabs(trace_endpos_z-64)<1?"PASS":"FAIL",trace_endpos_z));
        fb_terrain_begin();terrain_edit(TEREDIT_HEIGHT_RAISE,'2560 2560 64',256,64);fb_terrain_finish();
        traceline('2560 2560 512','2560 2560 -512',TRUE,world);
        print(sprintf("FTEBROOM_TERRAIN32_%s raise height=%g\n",fabs(trace_endpos_z-128)<1?"PASS":"FAIL",trace_endpos_z));
        brush_undo();traceline('2560 2560 512','2560 2560 -512',TRUE,world);
        print(sprintf("FTEBROOM_TERRAIN32_%s undo height=%g\n",fabs(trace_endpos_z-64)<1?"PASS":"FAIL",trace_endpos_z));
        brush_redo();traceline('2560 2560 512','2560 2560 -512',TRUE,world);
        print(sprintf("FTEBROOM_TERRAIN32_%s redo height=%g\n",fabs(trace_endpos_z-128)<1?"PASS":"FAIL",trace_endpos_z));
        brush_undo();brush_undo();traceline('2560 2560 512','2560 2560 -512',TRUE,world);
        print(sprintf("FTEBROOM_TERRAIN32_%s undo_creation fraction=%g\n",trace_fraction==1?"PASS":"FAIL",trace_fraction));
        brush_redo();brush_redo();
        cvar_set("ftebroom_terrain_edit","1");cvar_set("ftebroom_terrain_paint","1");fb_terrain_begin();
        fb_tool_activate(FB_TOOL_CLIP);
        int released=!cvar("ftebroom_terrain_edit")&&!cvar("ftebroom_terrain_paint")&&!fb_terrain_stroke&&cvar("ftebroom_tool")==FB_TOOL_CLIP;
        print(sprintf("FTEBROOM_TERRAIN34_%s tool_releases_terrain\n",released?"PASS":"FAIL"));
        cvar_set("ftebroom_terrain_edit","1");fb_tool_escape();
        released=!cvar("ftebroom_terrain_edit")&&!cvar("ftebroom_tool");
        print(sprintf("FTEBROOM_TERRAIN34_%s escape_releases_terrain\n",released?"PASS":"FAIL"));
    } else {
        traceline('2560 2560 512','2560 2560 -512',TRUE,world);
        print(sprintf("FTEBROOM_TERRAIN32_%s reopen height=%g\n",fabs(trace_endpos_z-128)<1?"PASS":"FAIL",trace_endpos_z));
    }
}
