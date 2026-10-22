// SPDX-License-Identifier: GPL-2.0-or-later
// Map format, authoring assets and runtime game are independent settings.
static int gameProfile;
static bool gameProfileLocked;
static char gameMod[1024]="C:/Games/fteqw/id1";
static char gameEngine[1024]="C:/Games/fteqw/fteqw64.exe";
static bool gamePreviewAfterBuild=true;
static char gameDefinitions[1024]="";
static char gameQC[1024]="C:/Games/LibreQuake-0.08-beta (source code)/qcsrc";
static void gameProfileLoad()
{
  static bool loaded=false;if(loaded)return;loaded=true;
  std::ifstream input(settingsPath().parent_path()/"ftebroom-game-profile.txt");
  int selected=0,automatic=1;std::string mod,engine;
  if(input>>selected>>automatic>>std::quoted(mod)>>std::quoted(engine)) {
    std::string defs,qc;
    if(input>>std::quoted(defs)>>std::quoted(qc)){std::snprintf(gameDefinitions,sizeof gameDefinitions,"%s",defs.c_str());std::snprintf(gameQC,sizeof gameQC,"%s",qc.c_str());}
    gameProfile=selected==1;gamePreviewAfterBuild=automatic!=0;
    std::snprintf(gameMod,sizeof gameMod,"%s",mod.c_str());
    std::snprintf(gameEngine,sizeof gameEngine,"%s",engine.c_str());
  }
}
static bool gameProfileSave()
{
  auto target=settingsPath().parent_path()/"ftebroom-game-profile.txt";
  std::ofstream output(target,std::ios::binary);
  output<<gameProfile<<' '<<gamePreviewAfterBuild<<' '<<std::quoted(gameMod)<<' '<<std::quoted(gameEngine)<<' '<<std::quoted(gameDefinitions)<<' '<<std::quoted(gameQC)<<'\n';
  output.close();return bool(output);
}
static void gameProfileFields()
{
  gameProfileLoad();
  ImGui::BeginDisabled(gameProfileLocked);
  if(ImGui::Combo("Game profile",&gameProfile,"Quake III Arena\0When the sky went dark\0") && gameProfile==1)
    std::snprintf(baseq3,sizeof baseq3,"%s","C:/Games/fteqw/baseq3");
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
  gameProfileLoad();if(gameProfile!=1)return {};
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
