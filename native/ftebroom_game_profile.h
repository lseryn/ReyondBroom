// SPDX-License-Identifier: GPL-2.0-or-later
// Map format, authoring assets and runtime game are independent settings.
#include "ftebroom_librequake.h"
static int gameProfile;
static bool gameProfileLocked;
static char gameMod[1024]="C:/Games/fteqw/id1";
static char gameEngine[1024]="C:/Games/fteqw/fteqw64.exe";
static bool gamePreviewAfterBuild=true;
static char gameDefinitions[1024]="";
static char gameQC[1024]="C:/Games/LibreQuake-0.08-beta (source code)/qcsrc";
static char q1Root[1024]="",q1Mod[1024]="",q1Wads[8192]="",q1Definitions[1024]="";
static std::string q3Root;
static int q1MapFormat=1,q1BspFormat=0;
static const char* gameProfileName(){return gameProfile==2?"Quake 1":gameProfile==1?"When the sky went dark":"Quake III Arena";}
static std::string q1Authoring(){return *q1Root?q1Root:q1UseLibre?libreMod():"";}
static std::string gameRuntime(){return gameProfile==2?(q1UseLibre?libreMod():(*q1Mod?q1Mod:q1Root)):gameMod;}
static void gameProfileLoad()
{
  static bool loaded=false;if(loaded)return;loaded=true;
  std::ifstream input(settingsPath().parent_path()/"ftebroom-game-profile.txt");
  int selected=0,automatic=1;std::string mod,engine;
  if(input>>selected>>automatic>>std::quoted(mod)>>std::quoted(engine)) {
    std::string defs,qc;
    if(input>>std::quoted(defs)>>std::quoted(qc)){std::snprintf(gameDefinitions,sizeof gameDefinitions,"%s",defs.c_str());std::snprintf(gameQC,sizeof gameQC,"%s",qc.c_str());}
    gameProfile=std::clamp(selected,0,2);gamePreviewAfterBuild=automatic!=0;
    std::snprintf(gameMod,sizeof gameMod,"%s",mod.c_str());
    std::snprintf(gameEngine,sizeof gameEngine,"%s",engine.c_str());
  }
  std::ifstream quake(settingsPath().parent_path()/"ftebroom-quake1.txt");
  std::string root,wads,defs;
  if(quake>>std::quoted(root)>>std::quoted(mod)>>std::quoted(wads)>>std::quoted(defs)>>q1MapFormat>>q1BspFormat>>std::quoted(q3Root)) {
    std::snprintf(q1Root,sizeof q1Root,"%s",root.c_str());std::snprintf(q1Mod,sizeof q1Mod,"%s",mod.c_str());
    std::snprintf(q1Wads,sizeof q1Wads,"%s",wads.c_str());std::snprintf(q1Definitions,sizeof q1Definitions,"%s",defs.c_str());
    q1MapFormat=std::clamp(q1MapFormat,0,1);q1BspFormat=std::clamp(q1BspFormat,0,1);
    int libre=0;if(quake>>libre)q1UseLibre=libre!=0;
  }
}
static bool gameProfileSave()
{
  auto target=settingsPath().parent_path()/"ftebroom-game-profile.txt";
  std::ofstream output(target,std::ios::binary);
  output<<gameProfile<<' '<<gamePreviewAfterBuild<<' '<<std::quoted(gameMod)<<' '<<std::quoted(gameEngine)<<' '<<std::quoted(gameDefinitions)<<' '<<std::quoted(gameQC)<<'\n';
  output.close();
  std::ofstream quake(settingsPath().parent_path()/"ftebroom-quake1.txt");
  quake<<std::quoted(q1Root)<<' '<<std::quoted(q1Mod)<<' '<<std::quoted(q1Wads)<<' '<<std::quoted(q1Definitions)<<' '<<q1MapFormat<<' '<<q1BspFormat<<' '<<std::quoted(q3Root)<<' '<<q1UseLibre<<'\n';
  quake.close();return bool(output)&&bool(quake);
}
static void gameProfileFields()
{
  gameProfileLoad();
  ImGui::BeginDisabled(gameProfileLocked);
  int old=gameProfile;
  if(ImGui::Combo("Game profile",&gameProfile,"Quake III Arena\0When the sky went dark\0Quake 1\0")) {
    if(old!=2)q3Root=baseq3;
    std::snprintf(baseq3,sizeof baseq3,"%s",gameProfile==2?q1Root:q3Root.c_str());
  }
  if(gameProfile==2) {
    ImGui::InputText("Quake id1 / authoring directory",q1Root,sizeof q1Root);
    libreFields();
    ImGui::BeginDisabled(q1UseLibre);ImGui::InputText("Runtime mod directory (optional)",q1Mod,sizeof q1Mod);ImGui::EndDisabled();
    ImGui::InputTextMultiline("WAD2 archives (one full path per line)",q1Wads,sizeof q1Wads,{470,85});
    ImGui::InputText("Entity definitions (optional .def / .fgd / .ent)",q1Definitions,sizeof q1Definitions);
    ImGui::Combo("Save MAP format",&q1MapFormat,"Quake standard\0Valve 220\0");
    ImGui::Combo("Target BSP",&q1BspFormat,"BSP29 (classic limits)\0BSP2 (modern engines)\0");
    ImGui::TextWrapped("Resources are read-only. The last WAD wins duplicate texture names. Blank mod uses id1. Patches are unavailable in Quake 1. Existing standard maps keep their format until you select Valve 220.");
  }
  if(gameProfile==1) {
    ImGui::InputText("Runtime mod directory",gameMod,sizeof gameMod);
    ImGui::TextWrapped("Preview engine: bundled FTE (required for embedded free camera).");
    ImGui::InputText("Entity definitions (.def / .fgd)",gameDefinitions,sizeof gameDefinitions);
    ImGui::InputText("QuakeC source folder",gameQC,sizeof gameQC);
    ImGui::Checkbox("Open mod preview after Build",&gamePreviewAfterBuild);
    ImGui::TextWrapped("Quake 3 BSP with Quake game logic. Preview runs your mod inside the 3D viewport, using a temporary home and read-only filesystem. Only mod assets are loaded; baseq3 is the authoring library.");
  }
  ImGui::EndDisabled();
}

static std::string gameDefinitionPath()
{
  gameProfileLoad();if(gameProfile==2)return *q1Definitions?q1Definitions:q1UseLibre?"librequake.def":"quake1.ent";if(gameProfile!=1)return {};
  if(*gameDefinitions)return gameDefinitions;
  auto root=std::filesystem::u8path(gameQC);
  if(!std::filesystem::is_directory(root))throw std::runtime_error("Choose mod entity definitions or its QuakeC source folder in Game / resources.");
  std::vector<std::filesystem::path> sources;
  for(const auto& file:std::filesystem::directory_iterator(root))
    if(file.is_regular_file() && file.path().extension()==".qc")sources.push_back(file.path());
  std::sort(sources.begin(),sources.end());std::string result;
  for(const auto& path:sources){
    if(std::filesystem::file_size(path)>16*1024*1024)continue;
    std::ifstream input(path);std::string source((std::istreambuf_iterator<char>(input)),{});
    size_t at=0;while((at=source.find("/*QUAKED",at))!=std::string::npos){
      auto end=source.find("*/",at);if(end==std::string::npos)break;
      result+=source.substr(at,end+2-at)+"\n";at=end+2;
      if(result.size()>16*1024*1024)throw std::runtime_error("Mod entity definitions exceed 16 MiB.");
    }
  }
  if(result.empty())throw std::runtime_error("No QUAKED descriptions found. Choose a .def or .fgd file for this mod.");
  auto path=settingsPath().parent_path()/"ftebroom-mod-entities.def";
  std::ofstream output(path);output<<result;output.close();
  if(!output)throw std::runtime_error("Cannot write the local mod entity definition cache.");
  return path.u8string();
}
