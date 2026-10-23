// SPDX-License-Identifier: GPL-2.0-or-later
struct RecentMap { std::string path; int profile=-1; bool favorite=false; };
static std::vector<RecentMap> recentMaps;
static bool recentLoaded=false,recentWindow=false,recentFavorites=false;
static const char* recentProfileName(int profile) {
  return profile==0?"Quake III Arena":profile==1?"When the sky went dark":profile==2?"Quake 1":"Unknown profile";
}
static void recentLoad() {
  if(recentLoaded)return;recentLoaded=true;
  std::ifstream in(settingsPath().parent_path()/"ftebroom-recent-maps.txt");
  RecentMap item;while(in>>item.profile>>item.favorite>>std::quoted(item.path))
    if(!item.path.empty()&&recentMaps.size()<1000)recentMaps.push_back(item);
}
static void recentSave() {
  auto path=settingsPath().parent_path()/"ftebroom-recent-maps.txt";
  std::ofstream out(path,std::ios::trunc);for(const auto& item:recentMaps)out<<item.profile<<' '<<item.favorite<<' '<<std::quoted(item.path)<<'\n';
}
static void recentRemember(const std::filesystem::path& path,int profile) {
  if(path.empty())return;recentLoad();auto name=path.lexically_normal().u8string();bool favorite=false;
  for(auto it=recentMaps.begin();it!=recentMaps.end();)if(it->path==name){favorite=it->favorite;it=recentMaps.erase(it);}else ++it;
  recentMaps.insert(recentMaps.begin(),{name,profile,favorite});
  // Favorites survive ordinary history pruning.
  int ordinary=0;for(auto it=recentMaps.begin();it!=recentMaps.end();)if(!it->favorite&&++ordinary>100)it=recentMaps.erase(it);else ++it;
  recentSave();
}
static void documentRequest(const std::string& next);
static void recentPanel() {
  if(!recentWindow)return;recentLoad();ImGui::SetNextWindowSize({760,520},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Welcome to FTEBroom",&recentWindow)) {
    ImGui::TextUnformatted("Recently edited maps");ImGui::Checkbox("Favorites only",&recentFavorites);
    ImGui::BeginChild("recent-list",{0,-ImGui::GetFrameHeightWithSpacing()*2},ImGuiChildFlags_Borders);
    std::string open;
    for(size_t i=0;i<recentMaps.size();++i) {
      auto& item=recentMaps[i];if(recentFavorites&&!item.favorite)continue;ImGui::PushID(int(i));
      if(ImGui::Checkbox("##favorite",&item.favorite))recentSave();if(ImGui::IsItemHovered())ImGui::SetTooltip("Favorite");ImGui::SameLine();
      auto path=std::filesystem::u8path(item.path);bool exists=ftebroom::pak::exists(path);
      ImGui::BeginDisabled(!exists);
      if(ImGui::Selectable(path.filename().u8string().c_str(),false,ImGuiSelectableFlags_None,{std::min(300.f,ImGui::GetContentRegionAvail().x*.5f),0})){open=item.path;}
      if(ImGui::IsItemHovered())ImGui::SetTooltip("%s",item.path.c_str());ImGui::EndDisabled();ImGui::SameLine();ImGui::TextDisabled("%s%s",recentProfileName(item.profile),exists?"":" (missing)");
      ImGui::TextDisabled("%s",item.path.c_str());ImGui::PopID();
    }
    if(recentMaps.empty())ImGui::TextDisabled("Opened and saved maps will appear here.");
    ImGui::EndChild();
    if(!open.empty()) {recentWindow=false;documentRequest("@"+open);}
    if(ImGui::Button("Open another map...",{-1,0})){recentWindow=false;openRequest=true;}
    if(ImGui::Button("Create new map...",{-1,0})){recentWindow=false;documentRequest("__new");}
  }ImGui::End();
}
