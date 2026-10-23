// SPDX-License-Identifier: GPL-2.0-or-later
vector(float model,float sequence,float mode) editor_model_info = #0:editor_model_info;
entity fb_modelviewer_entity;
string fb_modelviewer_path;
float fb_modelviewer_skeleton;
void fb_modelviewer_draw()
{
    if(!cvar("ftebroom_modelviewer_open")) {
        if(fb_modelviewer_entity){remove(fb_modelviewer_entity);fb_modelviewer_entity=world;}
        if(fb_modelviewer_skeleton){skel_delete(fb_modelviewer_skeleton);fb_modelviewer_skeleton=0;}
        return;
    }
    string path=cvar_string("ftebroom_modelviewer_path");
    if(strcmp(path,fb_modelviewer_path) || !fb_modelviewer_entity) {
        if(fb_modelviewer_entity)remove(fb_modelviewer_entity);
        if(fb_modelviewer_skeleton)skel_delete(fb_modelviewer_skeleton);
        fb_modelviewer_entity=spawn();setmodel(fb_modelviewer_entity,path);
        strunzone(fb_modelviewer_path);fb_modelviewer_path=strzone(path);
        fb_modelviewer_skeleton=skel_create(fb_modelviewer_entity.modelindex);
    }
    entity item=fb_modelviewer_entity;float model=item.modelindex;
    cvar_set("ftebroom_modelviewer_count",ftos(modelframecount(model)));
    int sequence=bound(0,cvar("ftebroom_modelviewer_sequence"),max(0,modelframecount(model)-1));
    vector info=editor_model_info(model,sequence,0);
    cvar_set("ftebroom_modelviewer_poses",ftos(info_x));cvar_set("ftebroom_modelviewer_duration",ftos(info_y));
    cvar_set("ftebroom_modelviewer_name",frametoname(model,sequence));
    float bones=fb_modelviewer_skeleton?skel_get_numbones(fb_modelviewer_skeleton):0;
    cvar_set("ftebroom_modelviewer_bones",ftos(bones));
    int selectedBone=bound(1,cvar("ftebroom_modelviewer_bone"),max(1,bones));
    cvar_set("ftebroom_modelviewer_bonename",bones?skel_get_bonename(fb_modelviewer_skeleton,selectedBone):"No skeletal bones");
    item.frame=sequence;item.frame1time=cvar("ftebroom_modelviewer_time");item.frame2=sequence;item.lerpfrac=0;
    vector low=editor_model_info(model,0,1),high=editor_model_info(model,0,2),center=(low+high)*0.5;
    vector angles=[cvar("ftebroom_modelviewer_pitch"),cvar("ftebroom_modelviewer_yaw"),0];
    makevectors(angles);vector eye=center-v_forward*max(8,vlen(high-low)*1.4)*max(.1,cvar("ftebroom_modelviewer_zoom"));
    vector size=[bound(64,cvar("ftebroom_modelviewer_width"),1600),bound(64,cvar("ftebroom_modelviewer_height"),1200),0];
    vector oldOrigin=getproperty(VF_ORIGIN),oldAngles=getproperty(VF_ANGLES),oldMin=getproperty(VF_MIN),oldSize=getproperty(VF_SIZE),oldFov=getproperty(VF_FOV);
    float oldPerspective=getproperty(VF_PERSPECTIVE),oldNear=getproperty(VF_MINDIST),oldFar=getproperty(VF_MAXDIST);
    clearscene();setproperty(VF_PERSPECTIVE,TRUE);setproperty(VF_MINDIST,1);setproperty(VF_MAXDIST,0);setproperty(VF_RT_DESTCOLOUR,"ftebroom_modelviewer",-IMGFMT_R8G8B8A8,size);
    setproperty(VF_MIN,'0 0 0');setproperty(VF_SIZE,size);setproperty(VF_ORIGIN,eye);setproperty(VF_ANGLES,angles);
    setproperty(VF_DRAWWORLD,0);setproperty(VF_FOVY,45);setproperty(VF_FOVX,atan(tan(45*M_PI/360)*size_x/size_y)*360/M_PI);
    drawfill('0 0 0',size,'0.08 0.09 0.11',1,0);item.effects=EF_FULLBRIGHT;addentity(item);
    if(cvar("ftebroom_modelviewer_showbones"))for(int bone=1;bone<=min(bones,512);bone++) {
        int parent=skel_get_boneparent(fb_modelviewer_skeleton,bone);
        if(parent)fb_visual_line(gettaginfo(item,bone),gettaginfo(item,parent),'0.2 1 0.4',1,1,0);
    }
    renderscene();setproperty(VF_RT_DESTCOLOUR,"");
    setproperty(VF_ORIGIN,oldOrigin);setproperty(VF_ANGLES,oldAngles);setproperty(VF_MIN,oldMin);setproperty(VF_SIZE,oldSize);setproperty(VF_FOV,oldFov);setproperty(VF_DRAWWORLD,1);setproperty(VF_PERSPECTIVE,oldPerspective);setproperty(VF_MINDIST,oldNear);setproperty(VF_MAXDIST,oldFar);
}
