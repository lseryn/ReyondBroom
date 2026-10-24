// SPDX-License-Identifier: GPL-2.0-or-later
static bool gameWallBrowserOpen=false;
static char gameWallBrowsePath[4096]{};
static std::string gameWallScanned,gameWallBrowseError;
static std::filesystem::path gameWallChosen;
static std::vector<std::pair<std::filesystem::path,bool>> gameWallEntries;
static void gameWallBrowse(){
 auto folder=*gameWallFile?std::filesystem::u8path(gameWallFile).parent_path():documentDefaultFolder();
 std::snprintf(gameWallBrowsePath,sizeof gameWallBrowsePath,"%s",folder.u8string().c_str());
 gameWallBrowserOpen=true;gameWallScanned.clear();gameWallChosen.clear();gameWallBrowseError.clear();
}
static void gameWallChoose(const std::filesystem::path& path){
 try{auto absolute=std::filesystem::absolute(path).lexically_normal();auto name=absolute.u8string();
  if(name.size()>=sizeof gameWallFile)throw std::runtime_error("The selected path is too long.");
  gameWallReadFile(absolute);std::snprintf(gameWallFile,sizeof gameWallFile,"%s",name.c_str());gameWallBrowserOpen=false;
 }catch(const std::exception& e){gameWallBrowseError=e.what();}
}
static void gameWallBrowser(){
 if(!gameWallBrowserOpen)return;
 if(gameProfile!=1||gameProfileLocked){gameWallBrowserOpen=false;return;}
 if(!ImGui::IsPopupOpen("Choose editor GLSL shader"))ImGui::OpenPopup("Choose editor GLSL shader");
 ImGui::SetNextWindowSize({650*uiScale(),420*uiScale()},ImGuiCond_FirstUseEver);
 if(ImGui::BeginPopupModal("Choose editor GLSL shader",&gameWallBrowserOpen)){
  ImGui::InputText("Directory",gameWallBrowsePath,sizeof gameWallBrowsePath);
  if(ImGui::Button("Up##wall")){auto parent=std::filesystem::u8path(gameWallBrowsePath).parent_path();if(!parent.empty())std::snprintf(gameWallBrowsePath,sizeof gameWallBrowsePath,"%s",parent.u8string().c_str());}
  ImGui::SameLine();if(ImGui::Button("Refresh##wall"))gameWallScanned.clear();
  if(gameWallScanned!=gameWallBrowsePath){gameWallScanned=gameWallBrowsePath;gameWallEntries.clear();gameWallChosen.clear();gameWallBrowseError.clear();
   try{for(const auto& entry:std::filesystem::directory_iterator(std::filesystem::u8path(gameWallBrowsePath))){auto ext=entry.path().extension().u8string();for(char& c:ext)if(c>='A'&&c<='Z')c+=32;bool dir=entry.is_directory();if(dir||(entry.is_regular_file()&&ext==".glsl"))gameWallEntries.push_back({entry.path(),dir});}
    std::sort(gameWallEntries.begin(),gameWallEntries.end(),[](const auto& a,const auto& b){return a.second!=b.second?a.second>b.second:a.first<b.first;});
   }catch(const std::exception& e){gameWallBrowseError=e.what();}
  }
  ImGui::BeginChild("GLSL entries",{0,-85*uiScale()},ImGuiChildFlags_Borders);ImGuiListClipper clip;clip.Begin(gameWallEntries.size());
  while(clip.Step())for(int i=clip.DisplayStart;i<clip.DisplayEnd;i++){const auto& e=gameWallEntries[i];ImGui::PushID(i);auto label=(e.second?"[Folder] ":"")+e.first.filename().u8string();
   if(ImGui::Selectable(label.c_str(),gameWallChosen==e.first,ImGuiSelectableFlags_AllowDoubleClick)){if(e.second)std::snprintf(gameWallBrowsePath,sizeof gameWallBrowsePath,"%s",e.first.u8string().c_str());else{gameWallChosen=e.first;if(ImGui::IsMouseDoubleClicked(0))gameWallChoose(e.first);}}ImGui::PopID();
  }ImGui::EndChild();
  ImGui::BeginDisabled(gameWallChosen.empty());if(ImGui::Button("Choose GLSL"))gameWallChoose(gameWallChosen);ImGui::EndDisabled();ImGui::SameLine();if(ImGui::Button("Cancel##wall"))gameWallBrowserOpen=false;
  if(!gameWallBrowseError.empty())ImGui::TextWrapped("%s",gameWallBrowseError.c_str());
  if(!gameWallBrowserOpen)ImGui::CloseCurrentPopup();
  ImGui::EndPopup();
 }
}
