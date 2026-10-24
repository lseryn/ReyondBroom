// SPDX-License-Identifier: GPL-3.0-or-later
static int generatorWindow=0;
static bool generatorPreview=false;
static double generatorChangedAt=0;
static void generatorPanel() {
  if(!generatorWindow)return;
  bool open=true,changed=false;const char* kind=generatorWindow==8?"rock":generatorWindow==7?"spin":generatorWindow==6?"subdivision":generatorWindow==5?"inset":generatorWindow==1?"terrain":generatorWindow==3?"fracture":generatorWindow==4?"perforate":"bevel";
  ImGui::SetNextWindowSize({460*uiScale(),0},ImGuiCond_FirstUseEver);
  if(ImGui::Begin(generatorWindow==8?"Rock":generatorWindow==7?"Spin":generatorWindow==6?"Subdivision":generatorWindow==5?"Inset":generatorWindow==1?"Terrain generator":generatorWindow==3?"Fracture":generatorWindow==4?"Perforate":"Bevel",&open)) {
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
    }else if(generatorWindow==8) {
      static int detail=10,rockSeed=1337;static bool hollow=false,group=false;static float thickness=8;
      changed|=ImGui::SliderInt("Segments",&detail,4,48);changed|=ImGui::InputInt("Seed",&rockSeed);
      if(ImGui::Button("Another variant")){rockSeed++;changed=true;}
      changed|=ImGui::Checkbox("Hollow shell",&hollow);if(hollow)changed|=ImGui::DragFloat("Shell thickness",&thickness,.25f,.001f,8192);
      changed|=ImGui::Checkbox("Group generated rocks",&group);
      ImGui::TextWrapped("Uses the selected brush bounds to shape seeded rocks. Detailed solid rocks are partitioned into convex pieces to respect the 64-plane limit. Up to 4096 samples and 2048 pieces.");
      cvars->SetFloat("ftebroom_rock_segments",detail);cvars->SetFloat("ftebroom_rock_seed",rockSeed);cvars->SetFloat("ftebroom_rock_hollow",hollow);cvars->SetFloat("ftebroom_rock_thickness",thickness);cvars->SetFloat("ftebroom_rock_group",group);
    }else if(generatorWindow==7) {
      static int count=6;static float flex=0,scale=1,delta[3]={0,0,128},rotation[3]={0,0,0};static bool automatic=true;
      changed|=ImGui::SliderInt("Segments",&count,1,64);changed|=ImGui::SliderFloat("Flexibility",&flex,-1,1);changed|=ImGui::SliderFloat("End scale",&scale,.05f,8);
      changed|=ImGui::Checkbox("Endpoint along face normal",&automatic);
      if(!automatic)changed|=ImGui::InputFloat3("Endpoint offset",delta);
      changed|=ImGui::InputFloat3("End rotation (degrees)",rotation);
      ImGui::TextWrapped("Shift-click faces. Extrusion retains the original brushes. Adjust the endpoint, rotation and scale, then Preview or Apply.");
      cvars->SetFloat("ftebroom_spin_segments",count);cvars->SetFloat("ftebroom_spin_flex",flex);cvars->SetFloat("ftebroom_spin_scale",scale);cvars->SetFloat("ftebroom_spin_auto",automatic);
      for(int a=0;a<3;a++){cvars->SetFloat(a==0?"ftebroom_spin_x":a==1?"ftebroom_spin_y":"ftebroom_spin_z",delta[a]);cvars->SetFloat(a==0?"ftebroom_spin_rx":a==1?"ftebroom_spin_ry":"ftebroom_spin_rz",rotation[a]);}
    }else if(generatorWindow==6) {
      static int su=2,sv=2,plane=0;static bool texture=false,grid=false;static float cell=32;
      changed|=ImGui::Checkbox("Use grid cell size",&grid);
      if(grid)changed|=ImGui::InputFloat("Cell size",&cell,.125f,8);else{changed|=ImGui::SliderInt("Segments U",&su,1,64);changed|=ImGui::SliderInt("Segments V",&sv,1,64);}
      changed|=ImGui::Checkbox("Align to selected face texture",&texture);
      if(!texture)changed|=ImGui::Combo("Plane",&plane,"XY\0XZ\0YZ\0");
      ImGui::TextWrapped("Splits whole brush volumes. Texture alignment uses one selected face per brush; cell size is in texels. Maximum 512 pieces.");
      cvars->SetFloat("ftebroom_subdivide_u",su);cvars->SetFloat("ftebroom_subdivide_v",sv);cvars->SetFloat("ftebroom_subdivide_plane",plane);cvars->SetFloat("ftebroom_subdivide_texture",texture);cvars->SetFloat("ftebroom_subdivide_grid",grid);cvars->SetFloat("ftebroom_subdivide_cell",cell);
    }else if(generatorWindow==5) {
      static float amount=16;static bool snap=true;
      changed|=ImGui::InputFloat("Inset amount",&amount,cvars->GetFloat("ca_grid"),cvars->GetFloat("ca_grid")*4);
      changed|=ImGui::Checkbox("Snap inner contour to grid",&snap);
      ImGui::TextWrapped("Shift-click one face. Creates an inner brush and border pieces through the source brush. Invalid or collapsing contours are rejected.");
      cvars->SetFloat("ftebroom_inset_amount",amount);cvars->SetFloat("ftebroom_inset_snap",snap);
    }else if(generatorWindow==4) {
      static int holes=3,sides=6,axis=2,holeSeed=1337;static float minimum=16,maximum=32,spacing=4;static bool keep=true;
      changed|=ImGui::SliderInt("Holes",&holes,1,64);changed|=ImGui::SliderInt("Polygon sides",&sides,3,32);
      changed|=ImGui::Combo("Through axis",&axis,"X\0Y\0Z\0");changed|=ImGui::InputInt("Seed",&holeSeed);
      changed|=ImGui::DragFloat("Minimum diameter",&minimum,1,.125f,8192);changed|=ImGui::DragFloat("Maximum diameter",&maximum,1,.125f,8192);
      changed|=ImGui::DragFloat("Spacing",&spacing,1,0,8192);changed|=ImGui::Checkbox("Keep plugs as func_wall",&keep);
      ImGui::TextWrapped("Creates convex polygonal through-holes. Retained plugs are selected after Apply. Parameters that cannot fit fail without changing the brush.");
      ImGui::TextDisabled("Complexity budget: holes x sides <= 128 (larger requests are rejected safely).");
      cvars->SetFloat("ftebroom_hole_count",holes);cvars->SetFloat("ftebroom_hole_sides",sides);cvars->SetFloat("ftebroom_hole_axis",axis);cvars->SetFloat("ftebroom_hole_seed",holeSeed);
      cvars->SetFloat("ftebroom_hole_min",minimum);cvars->SetFloat("ftebroom_hole_max",maximum);cvars->SetFloat("ftebroom_hole_spacing",spacing);cvars->SetFloat("ftebroom_hole_keep",keep);
    }else if(generatorWindow==3) {
      static int fragments=8,fractureSeed=1337;static float separation=0;static bool entities=false;static char material[256]={};
      changed|=ImGui::SliderInt("Fragments",&fragments,2,128);changed|=ImGui::InputInt("Seed",&fractureSeed);
      if(ImGui::Button("Another variant")){fractureSeed++;changed=true;}
      changed|=ImGui::SliderFloat("Separation (%)",&separation,0,100);changed|=ImGui::InputText("Cut material",material,sizeof material);
      changed|=ImGui::Checkbox("No collide (func_wall)",&entities);
      ImGui::TextWrapped("Creates one func_wall per fragment. This does not disable collisions in physics tools. Empty cut material inherits the source material.");
      cvars->SetFloat("ftebroom_fracture_count",fragments);cvars->SetFloat("ftebroom_fracture_seed",fractureSeed);cvars->SetFloat("ftebroom_fracture_separation",separation);cvars->SetFloat("ftebroom_fracture_entities",entities);cvars->SetString("ftebroom_fracture_material",material);
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
