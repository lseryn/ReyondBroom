// SPDX-License-Identifier: GPL-2.0-or-later
static bool terrainCreateWindow;
static void terrainPanel()
{
  static bool shown=false;
  if(gameProfile!=1){shown=false;return;}
  if(terrainCreateWindow) {
    ImGui::SetNextWindowSize({520*uiScale(),320*uiScale()},ImGuiCond_FirstUseEver);
    if(ImGui::Begin("Create terrain",&terrainCreateWindow)) {
      static char name[80]="terrain",texture[256]="textures/ftebroom/grid";static float height=0;
      ImGui::InputText("Map name",name,sizeof name);ImGui::InputText("Ground material",texture,sizeof texture);ImGui::InputFloat("Initial height",&height);
      ImGui::TextWrapped("Creates a native FTE terrain map with a 2048 x 2048 starting area. Height and material sections are saved in a folder beside the MAP. This is not a Q3 BSP terrain mesh.");
      if(ImGui::Button("Create and open"))try {
        if(!safeName(name)||(std::string(texture).find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-/.*")!=std::string::npos||!*texture)||!std::isfinite(height)||std::abs(height)>65536)throw std::runtime_error("Use safe relative names and a finite height.");
        auto target=documentDefaultFolder()/(std::string(name)+".map");if(std::filesystem::exists(target))throw std::runtime_error("A map with this name already exists.");
        std::filesystem::create_directories(target.parent_path());std::ofstream out(target,std::ios::binary);
        out<<"// FTEBroom profile=when-the-sky-went-dark format=fte-terrain\n{\n\"classname\" \"worldspawn\"\n\"_segmentsize\" \"1024\"\n\"_forcedefault\" \"1\"\n\"_minxsegment\" \"-1\"\n\"_minysegment\" \"-1\"\n\"_maxxsegment\" \"1\"\n\"_maxysegment\" \"1\"\n\"_defaultgroundtexture\" \""<<texture<<"\"\n\"_defaultgroundheight\" \""<<height<<"\"\n}\n{\n\"classname\" \"info_player_start\"\n\"origin\" \"0 0 "<<height+128<<"\"\n}\n";out.close();if(!out)throw std::runtime_error("Cannot create terrain map.");
        documentRequest("@"+target.u8string());terrainCreateWindow=false;
      }catch(const std::exception& e){documentError=e.what();}
      if(!documentError.empty())ImGui::TextWrapped("%s",documentError.c_str());
    }ImGui::End();
  }
  if(!documentTerrain){shown=false;return;}
  if(!shown){ImGui::SetNextWindowFocus();shown=true;}
  ImGui::SetNextWindowSize({370*uiScale(),600*uiScale()},ImGuiCond_FirstUseEver);
  if(auto inspector=ImGui::FindWindowByName("Map");inspector&&inspector->DockId)ImGui::SetNextWindowDockID(inspector->DockId,ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Terrain",nullptr,uiPanelFlags())) {
    bool editing=cvars->GetFloat("ftebroom_terrain_edit")!=0;if(ImGui::Checkbox("Sculpt / paint terrain",&editing)){cvars->SetFloat("ftebroom_terrain_edit",editing);cvars->SetFloat("ftebroom_terrain_paint",0);}
    static const int operations[]={7,8,3,4,5,6,11,12,13,14,15,16,2};static int selected=0;
    ImGui::Combo("Operation",&selected,"Raise\0Lower\0Set height\0Smooth\0Spread\0Flatten\0Paint blend\0Paint solid\0Concentrate layers\0Layer noise\0Blur layers\0Water height\0Hole\0");cvars->SetFloat("ftebroom_terrain_operation",operations[selected]);
    static float radius=256,quantity=8,strength=40;static bool square=false;static char texture[256]="textures/ftebroom/grid";
    ImGui::SliderFloat("Radius",&radius,8,2048);ImGui::InputFloat("Height / amount",&quantity);ImGui::SliderFloat("Strength",&strength,0,100);ImGui::Checkbox("Square brush",&square);ImGui::InputText("Paint material",texture,sizeof texture);
    if(ImGui::Button("Use selected material")){auto name=selectedMaterial;std::snprintf(texture,sizeof texture,"%s",name.c_str());}
    cvars->SetFloat("ftebroom_terrain_radius",radius);cvars->SetFloat("ftebroom_terrain_quantity",std::isfinite(quantity)?quantity:0);cvars->SetFloat("ftebroom_terrain_strength",strength);cvars->SetFloat("ftebroom_terrain_square",square);cvars->SetString("ftebroom_terrain_texture",texture);
    if(ImGui::Button("Save terrain and map"))documentSave(documentName);
    ImGui::TextWrapped("Drag in the perspective viewport to paint. Disable sculpting to edit brushes/entities. Save writes the MAP and its terrain sections. Terrain strokes currently use csaddon's direct editing and do not participate in brush Undo.");
  }ImGui::End();
}
