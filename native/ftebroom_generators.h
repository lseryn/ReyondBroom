// SPDX-License-Identifier: GPL-3.0-or-later
static int generatorWindow=0;
static bool generatorPreview=false;
static double generatorChangedAt=0;
static void generatorPanel() {
  if(!generatorWindow)return;
  bool open=true,changed=false;const char* kind=generatorWindow==1?"terrain":"bevel";
  ImGui::SetNextWindowSize({460*uiScale(),480*uiScale()},ImGuiCond_FirstUseEver);
  if(ImGui::Begin(generatorWindow==1?"Terrain generator":"Bevel",&open)) {
    static int u=10,v=10,pu=9,pv=9,side=0,seed=1337,segments=3,mode=0;
    static float height=128,intensity=1,frequency=4,roughness=1,radius=8,profile=.5f;
    static bool triangles=true,clamp=true;
    if(generatorWindow==1) {
      changed|=ImGui::SliderInt("Segments U",&u,1,32);changed|=ImGui::SliderInt("Segments V",&v,1,32);
      changed|=ImGui::DragFloat("Height",&height,1,0,8192);changed|=ImGui::SliderFloat("Intensity",&intensity,0,4);
      changed|=ImGui::SliderFloat("Frequency",&frequency,.01f,64);changed|=ImGui::SliderFloat("Roughness",&roughness,0,2);
      changed|=ImGui::InputInt("Seed",&seed);changed|=ImGui::Combo("Side",&side,"+Z (top)\0-Z (bottom)\0+X\0-X\0+Y\0-Y\0");
      changed|=ImGui::Checkbox("Triangular grid",&triangles);
      if(gameProfile!=2) {
        ImGui::SeparatorText("Selected patches");
        if(ImGui::SliderInt("Control points U",&pu,3,31)){pu|=1;changed=true;}
        if(ImGui::SliderInt("Control points V",&pv,3,31)){pv|=1;changed=true;}
        ImGui::TextWrapped("Odd point counts only. Reducing the grid approximates the surface.");
      }
      cvars->SetFloat("ftebroom_land_u",u);cvars->SetFloat("ftebroom_land_v",v);cvars->SetFloat("ftebroom_land_patch_u",pu);cvars->SetFloat("ftebroom_land_patch_v",pv);
      cvars->SetFloat("ftebroom_land_height",height);cvars->SetFloat("ftebroom_land_intensity",intensity);cvars->SetFloat("ftebroom_land_frequency",frequency);cvars->SetFloat("ftebroom_land_roughness",roughness);cvars->SetFloat("ftebroom_land_seed",seed);cvars->SetFloat("ftebroom_land_side",side);cvars->SetFloat("ftebroom_land_triangles",triangles);
    }else {
      changed|=ImGui::Combo("Selection",&mode,"Face boundary / whole brush\0Selected edges (E)\0Selected vertices (V)\0");
      changed|=ImGui::DragFloat("Radius",&radius,.25f,.125f,8192);changed|=ImGui::SliderInt("Segments",&segments,1,16);
      changed|=ImGui::SliderFloat("Profile",&profile,0,1);changed|=ImGui::Checkbox("Clamp within each brush",&clamp);
      ImGui::TextWrapped("0: flat chamfer; 0.5: round; 1: square. Results stay convex. Complex bevels must fit the engine's 64-face brush limit.");
      cvars->SetFloat("ftebroom_bevel_radius",radius);cvars->SetFloat("ftebroom_bevel_segments",segments);cvars->SetFloat("ftebroom_bevel_profile",profile);cvars->SetFloat("ftebroom_bevel_clamp",clamp);cvars->SetFloat("ftebroom_bevel_mode",mode);
    }
    if(changed&&generatorPreview)generatorChangedAt=ImGui::GetTime();
    bool refresh=generatorChangedAt>0&&ImGui::GetTime()-generatorChangedAt>.2&&!ImGui::IsAnyItemActive();
    if(ImGui::Button("Preview")||refresh){command((std::string("ftebroom_generator preview ")+kind+"\n").c_str());generatorPreview=true;generatorChangedAt=0;}
    ImGui::SameLine();if(ImGui::Button("Apply")){command((std::string("ftebroom_generator apply ")+kind+"\n").c_str());generatorPreview=false;generatorChangedAt=0;}
    ImGui::SameLine();if(ImGui::Button("Cancel"))open=false;
    char error[1024]={};cvars->GetString("ftebroom_generator_error",error,sizeof error);if(*error)ImGui::TextWrapped("%s",error);
  }ImGui::End();
  if(!open){command("ftebroom_generator cancel\n");generatorPreview=false;generatorWindow=0;generatorChangedAt=0;}
}
