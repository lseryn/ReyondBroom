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
static std::filesystem::path modFilesClipboard,modFilesRename;
static bool modFilesCut=false,modFilesGrid=false;
static char modFilesRenameName[256]={};
static void modFilesPaste() {
  modFileValidate(modFilesClipboard);modFileValidate(modFilesFolder);
  if(modFilesCut){modFileMove(modFilesClipboard,modFilesFolder);modFilesClipboard.clear();return;}
  if(std::filesystem::is_symlink(modFilesClipboard))throw std::runtime_error("Symbolic links are not copied.");
  if(!std::filesystem::is_directory(modFilesClipboard)){modFileCopy(modFilesClipboard,modFilesFolder);return;}
  auto relative=std::filesystem::weakly_canonical(modFilesFolder).lexically_relative(std::filesystem::weakly_canonical(modFilesClipboard));
  if(!relative.empty()&&*relative.begin()!="..")throw std::runtime_error("Cannot copy a folder into itself.");
  for(auto& item:std::filesystem::recursive_directory_iterator(modFilesClipboard))if(item.is_symlink())throw std::runtime_error("Folder contains symbolic links.");
  auto target=modFilesFolder/modFilesClipboard.filename();
  for(int n=1;std::filesystem::exists(target);n++)target=modFilesFolder/(modFilesClipboard.filename().u8string()+"-"+std::to_string(n));
  std::filesystem::copy(modFilesClipboard,target,std::filesystem::copy_options::recursive);modFilesRefresh=true;
}
static void modFileIcon(ImVec2 p,float size,bool folder) {
  auto d=ImGui::GetWindowDrawList();auto color=folder?IM_COL32(221,178,74,255):IM_COL32(177,190,209,255);
  if(folder){d->AddRectFilled({p.x+size*.1f,p.y+size*.15f},{p.x+size*.5f,p.y+size*.38f},color,2);d->AddRectFilled({p.x+size*.1f,p.y+size*.3f},{p.x+size*.9f,p.y+size*.8f},color,2);}
  else {d->AddRectFilled({p.x+size*.25f,p.y+size*.1f},{p.x+size*.75f,p.y+size*.9f},color,2);for(int i=0;i<3;i++)d->AddLine({p.x+size*.35f,p.y+size*(.4f+i*.14f)},{p.x+size*.65f,p.y+size*(.4f+i*.14f)},IM_COL32(70,80,95,255),1);}
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
      ImGui::Checkbox("Thumbnail view",&modFilesGrid);static float tileSize=96;
      if(modFilesGrid){ImGui::SameLine();ImGui::SetNextItemWidth(180);ImGui::SliderFloat("Thumbnail size",&tileSize,48,180,"%.0f");}
      ImGui::TextWrapped("%s",modFilesFolder.u8string().c_str());
      static char name[256]={},contents[8192]={};
      if(ImGui::CollapsingHeader("New file / folder")) {
        ImGui::InputText("Name",name,sizeof name);ImGui::InputTextMultiline("Initial file contents",contents,sizeof contents,{0,90});
        bool folder=ImGui::Button("Create folder");ImGui::SameLine();bool file=ImGui::Button("Create file");
        if(folder||file){auto leaf=std::filesystem::u8path(name);if(leaf.empty()||leaf.has_parent_path()||leaf=="."||leaf=="..")throw std::runtime_error("Enter a single file or folder name.");auto target=modFilesFolder/leaf;modFileValidate(target);if(std::filesystem::exists(target))throw std::runtime_error("Name already exists.");if(folder)std::filesystem::create_directory(target);else{std::ofstream out(target,std::ios::binary);out<<contents;if(!out)throw std::runtime_error("Cannot create file.");}modFilesRefresh=true;}
      }
      if(modFilesRefresh){modFilesEntries.clear();for(auto& entry:std::filesystem::directory_iterator(modFilesFolder))modFilesEntries.push_back(entry);std::sort(modFilesEntries.begin(),modFilesEntries.end(),[](const auto& a,const auto& b){if(a.is_directory()!=b.is_directory())return a.is_directory();return a.path().filename()<b.path().filename();});modFilesRefresh=false;}
      ImGui::Separator();std::filesystem::path navigate;
      int columns=modFilesGrid?std::max(1,int(ImGui::GetContentRegionAvail().x/(tileSize+12))):1;
      float rowHeight=modFilesGrid?tileSize+38:ImGui::GetTextLineHeightWithSpacing()+5;
      ImGuiListClipper clipper;clipper.Begin(((int)modFilesEntries.size()+columns-1)/columns,rowHeight);
      while(clipper.Step())for(int row=clipper.DisplayStart;row<clipper.DisplayEnd;row++)for(int col=0;col<columns;col++) {
        int i=row*columns+col;if(i>=(int)modFilesEntries.size())break;
        auto& entry=modFilesEntries[i];auto path=entry.path();bool directory=entry.is_directory();auto label=path.filename().u8string();
        if(col)ImGui::SameLine();ImGui::PushID(i);auto p=ImGui::GetCursorScreenPos();
        if(ImGui::Selectable("##file",false,ImGuiSelectableFlags_AllowDoubleClick,{modFilesGrid?tileSize+8:ImGui::GetContentRegionAvail().x,rowHeight-4})&&directory)navigate=path;
        if(ImGui::IsItemHovered()&&ImGui::IsMouseDoubleClicked(0)&&modelFile(path))modelViewerShow(std::filesystem::relative(path,modFileRoot()).generic_u8string());
        if(ImGui::IsItemHovered())ImGui::SetTooltip("%s",label.c_str());
        if(ImGui::BeginDragDropSource()){auto value=path.u8string();ImGui::SetDragDropPayload("FTEBROOM_MOD_FILE",value.c_str(),value.size()+1);ImGui::TextUnformatted(label.c_str());ImGui::EndDragDropSource();}
        if(directory)modFilesTarget(path);
        if(ImGui::BeginPopupContextItem("file_actions")) {
          if(ImGui::MenuItem("Copy")){modFilesClipboard=path;modFilesCut=false;}
          if(ImGui::MenuItem("Cut")){modFilesClipboard=path;modFilesCut=true;}
          if(ImGui::MenuItem("Paste",nullptr,false,!modFilesClipboard.empty())){try{modFilesPaste();}catch(const std::exception& e){modFilesError=e.what();}}
          if(ImGui::MenuItem("Rename...")){modFilesRename=path;std::snprintf(modFilesRenameName,sizeof modFilesRenameName,"%s",label.c_str());}
          if(ImGui::MenuItem("Open containing directory"))modFilesExplorer();ImGui::EndPopup();
        }
        float icon=modFilesGrid?tileSize:rowHeight-5;
        bool preview=false;if(modFilesGrid&&!directory&&modelFile(path)){ftebroom::EntityDefinition def;def.model=std::filesystem::relative(path,modFileRoot()).generic_u8string();def.brush=false;preview=entityModelTile(def,p,icon);}
        if(!preview)modFileIcon(p,icon,directory);
        auto ext=entityLower(path.extension().u8string());
        if(!directory && !preview){auto list=ImGui::GetWindowDrawList();auto color=IM_COL32(45,75,110,255);
          if(ext==".wav"||ext==".ogg"||ext==".mp3"||ext==".flac"){list->AddCircleFilled({p.x+icon*.38f,p.y+icon*.66f},icon*.1f,color);list->AddLine({p.x+icon*.47f,p.y+icon*.66f},{p.x+icon*.47f,p.y+icon*.25f},color,2);list->AddLine({p.x+icon*.47f,p.y+icon*.25f},{p.x+icon*.68f,p.y+icon*.3f},color,3);}
          else if(ext==".png"||ext==".jpg"||ext==".jpeg"||ext==".tga"||ext==".bmp"){list->AddTriangleFilled({p.x+icon*.3f,p.y+icon*.7f},{p.x+icon*.5f,p.y+icon*.4f},{p.x+icon*.7f,p.y+icon*.7f},color);list->AddCircleFilled({p.x+icon*.65f,p.y+icon*.3f},icon*.06f,color);}
        }
        auto d=ImGui::GetWindowDrawList();ImVec2 text=modFilesGrid?ImVec2(p.x+3,p.y+tileSize):ImVec2(p.x+icon+7,p.y+2);
        d->PushClipRect(p,{p.x+(modFilesGrid?tileSize+8:ImGui::GetContentRegionAvail().x),p.y+rowHeight-4},true);d->AddText(text,ImGui::GetColorU32(ImGuiCol_Text),label.c_str());d->PopClipRect();
        ImGui::PopID();
      }
      if(!navigate.empty()){modFileValidate(navigate);modFilesFolder=navigate;modFilesRefresh=true;}
    }catch(const std::exception& e){modFilesError=e.what();}
    if(ImGui::BeginPopupContextWindow("mod_files_context",ImGuiPopupFlags_MouseButtonRight|ImGuiPopupFlags_NoOpenOverItems)){if(ImGui::MenuItem("Paste",nullptr,false,!modFilesClipboard.empty()))try{modFilesPaste();}catch(const std::exception& e){modFilesError=e.what();}if(ImGui::MenuItem("Open this directory in OS file manager"))modFilesExplorer();ImGui::EndPopup();}
    if(!modFilesRename.empty()) {
      ImGui::SeparatorText("Rename file / folder");ImGui::InputText("New name",modFilesRenameName,sizeof modFilesRenameName);
      if(ImGui::Button("Rename"))try {
        auto leaf=std::filesystem::u8path(modFilesRenameName);if(leaf.empty()||leaf.has_parent_path()||leaf=="."||leaf=="..")throw std::runtime_error("Enter a single filename.");
        auto target=modFilesRename.parent_path()/leaf;modFileValidate(modFilesRename);modFileValidate(target);
        if(std::filesystem::exists(target))throw std::runtime_error("Name already exists.");
        std::filesystem::rename(modFilesRename,target);modFilesRename.clear();modFilesRefresh=true;
      }catch(const std::exception& e){modFilesError=e.what();}
      ImGui::SameLine();if(ImGui::Button("Cancel rename"))modFilesRename.clear();
    }
    if(!modFilesError.empty())ImGui::TextWrapped("%s",modFilesError.c_str());
    ImGui::TextDisabled("External drops copy files. Internal drags move files. Existing files are preserved.");
  }ImGui::End();
}
