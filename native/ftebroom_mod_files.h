// SPDX-License-Identifier: GPL-2.0-or-later
// File operations are confined to the selected mod; existing files are never replaced.
#ifdef _WIN32
#include <shellapi.h>
#endif
static bool modFilesOpen=false,modFilesVisible=false;
static ImVec2 modFilesMin,modFilesMax;
static std::filesystem::path modFilesFolder,modFilesRoot;
static std::vector<std::filesystem::directory_entry> modFilesEntries;
static bool modFilesRefresh=true;
static std::string modFilesError;
static std::filesystem::path modFileRoot(){return std::filesystem::u8path(gameProfile==0?std::string(baseq3):gameRuntime());}
static bool modFileInside(const std::filesystem::path& path) {
  auto root=std::filesystem::weakly_canonical(modFileRoot());
  if(root.empty())return false;
  auto relative=std::filesystem::weakly_canonical(path).lexically_relative(root);
  return !relative.empty()&&!relative.is_absolute()&&*relative.begin()!="..";
}
static void modFileValidate(const std::filesystem::path& path) {
  if(modFileRoot().empty()||!std::filesystem::is_directory(modFileRoot()))throw std::runtime_error("Configure the runtime mod directory first.");
  if(!modFileInside(path))throw std::runtime_error("Destination must be inside the selected mod.");
}
static std::filesystem::path modFileCopy(const std::filesystem::path& source,const std::filesystem::path& folder) {
  modFileValidate(folder);
  if(!std::filesystem::is_regular_file(source)||std::filesystem::is_symlink(source))throw std::runtime_error("Drop regular files; symbolic links and directories are not imported.");
  auto target=folder/source.filename();
  if(std::filesystem::exists(target)&&std::filesystem::equivalent(source,target))return target;
  for(int i=1;std::filesystem::exists(target);i++)target=folder/(source.stem().u8string()+"-"+std::to_string(i)+source.extension().u8string());
  std::filesystem::copy_file(source,target);modFilesRefresh=true;return target;
}
static void modFileMove(const std::filesystem::path& source,const std::filesystem::path& folder) {
  modFileValidate(source);modFileValidate(folder);
  auto target=folder/source.filename();
  if(source==target)return;
  if(source==modFilesRoot||std::filesystem::exists(target))throw std::runtime_error("Destination already exists or source is the mod root.");
  if(std::filesystem::is_symlink(source))throw std::runtime_error("Moving symbolic links is not supported.");
  if(std::filesystem::is_directory(source)) {
    auto relative=std::filesystem::weakly_canonical(folder).lexically_relative(std::filesystem::weakly_canonical(source));
    if(!relative.empty()&&*relative.begin()!="..")throw std::runtime_error("Cannot move a folder into itself.");
  }
  std::filesystem::rename(source,target);modFilesRefresh=true;
}
static void modFilesTarget(const std::filesystem::path& folder) {
  if(ImGui::BeginDragDropTarget()) {
    if(auto payload=ImGui::AcceptDragDropPayload("FTEBROOM_MOD_FILE")) {
      try {modFileMove(std::filesystem::u8path((const char*)payload->Data),folder);}catch(const std::exception& e){modFilesError=e.what();}
    }
    ImGui::EndDragDropTarget();
  }
}
static void modFilesExplorer() {
#ifdef _WIN32
  ShellExecuteW(nullptr,L"open",modFilesFolder.c_str(),nullptr,nullptr,SW_SHOWNORMAL);
#else
  const char* tool=
#ifdef __APPLE__
    "open";
#else
    "xdg-open";
#endif
  std::string folder=modFilesFolder.string();char* args[]={const_cast<char*>(tool),folder.data(),nullptr};pid_t pid;posix_spawnp(&pid,tool,nullptr,nullptr,args,environ);
#endif
}
static void modFilesPanel() {
  modFilesVisible=false;if(!modFilesOpen)return;
  ImGui::SetNextWindowSize({650*uiScale(),450*uiScale()},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Mod file manager",&modFilesOpen)) {
    modFilesVisible=true;modFilesMin=ImGui::GetWindowPos();auto sz=ImGui::GetWindowSize();modFilesMax={modFilesMin.x+sz.x,modFilesMin.y+sz.y};
    try {
      auto root=modFileRoot();modFileValidate(root);
      if(root!=modFilesRoot){modFilesRoot=root;modFilesFolder=root;modFilesRefresh=true;}
      if(ImGui::Button("Up")&&modFilesFolder!=root){modFilesFolder=modFilesFolder.parent_path();modFilesRefresh=true;}modFilesTarget(modFilesFolder.parent_path());
      ImGui::SameLine();if(ImGui::Button("Refresh"))modFilesRefresh=true;ImGui::SameLine();if(ImGui::Button("Open in file manager"))modFilesExplorer();
      ImGui::TextWrapped("%s",modFilesFolder.u8string().c_str());
      static char name[256]={},contents[8192]={};
      if(ImGui::CollapsingHeader("New file / folder")) {
        ImGui::InputText("Name",name,sizeof name);ImGui::InputTextMultiline("Initial file contents",contents,sizeof contents,{0,90});
        bool folder=ImGui::Button("Create folder");ImGui::SameLine();bool file=ImGui::Button("Create file");
        if(folder||file){auto leaf=std::filesystem::u8path(name);if(leaf.empty()||leaf.has_parent_path()||leaf=="."||leaf=="..")throw std::runtime_error("Enter a single file or folder name.");auto target=modFilesFolder/leaf;modFileValidate(target);if(std::filesystem::exists(target))throw std::runtime_error("Name already exists.");if(folder)std::filesystem::create_directory(target);else{std::ofstream out(target,std::ios::binary);out<<contents;if(!out)throw std::runtime_error("Cannot create file.");}modFilesRefresh=true;}
      }
      if(modFilesRefresh){modFilesEntries.clear();for(auto& entry:std::filesystem::directory_iterator(modFilesFolder))modFilesEntries.push_back(entry);std::sort(modFilesEntries.begin(),modFilesEntries.end(),[](const auto& a,const auto& b){if(a.is_directory()!=b.is_directory())return a.is_directory();return a.path().filename()<b.path().filename();});modFilesRefresh=false;}
      ImGui::Separator();std::filesystem::path navigate;
      ImGuiListClipper clipper;clipper.Begin((int)modFilesEntries.size());
      while(clipper.Step())for(int i=clipper.DisplayStart;i<clipper.DisplayEnd;i++) {
        auto& entry=modFilesEntries[i];auto path=entry.path();bool directory=entry.is_directory();auto label=std::string(directory?"[Folder] ":"")+path.filename().u8string();
        ImGui::PushID(i);if(ImGui::Selectable(label.c_str())&&directory){navigate=path;}
        if(ImGui::BeginDragDropSource()){auto value=path.u8string();ImGui::SetDragDropPayload("FTEBROOM_MOD_FILE",value.c_str(),value.size()+1);ImGui::TextUnformatted(label.c_str());ImGui::EndDragDropSource();}
        if(directory)modFilesTarget(path);ImGui::PopID();
      }
      if(!navigate.empty()){modFileValidate(navigate);modFilesFolder=navigate;modFilesRefresh=true;}
    }catch(const std::exception& e){modFilesError=e.what();}
    if(ImGui::BeginPopupContextWindow("mod_files_context")){if(ImGui::MenuItem("Open this directory in OS file manager"))modFilesExplorer();ImGui::EndPopup();}
    if(!modFilesError.empty())ImGui::TextWrapped("%s",modFilesError.c_str());
    ImGui::TextDisabled("External drops copy files. Internal drags move files. Existing files are preserved.");
  }ImGui::End();
}
