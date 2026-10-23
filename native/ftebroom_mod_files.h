// SPDX-License-Identifier: GPL-2.0-or-later
// File operations are confined to the selected mod; archive writes retain backups.
#ifdef _WIN32
#include <shellapi.h>
#endif
static bool modFilesOpen=true,modFilesVisible=false;
static ImVec2 modFilesMin,modFilesMax;
static std::filesystem::path modFilesFolder,modFilesRoot;
using ModFileEntry=std::pair<bool,std::filesystem::path>;
static std::vector<ModFileEntry> modFilesEntries;
static std::map<std::filesystem::path,std::vector<ModFileEntry>> modFilesTreeCache;
static bool modFilePacked(const std::filesystem::path& path){std::filesystem::path archive;std::string member;return ftebroom::pak::split(path,archive,member);}
static bool modFileMember(const std::filesystem::path& path){std::filesystem::path archive;std::string member;return ftebroom::pak::split(path,archive,member)&&!member.empty();}
static std::vector<ModFileEntry> modFileList(const std::filesystem::path& path){auto entries=ftebroom::pak::list(path);std::sort(entries.begin(),entries.end(),[](const auto& a,const auto& b){return a.first!=b.first?a.first>b.first:a.second.filename()<b.second.filename();});return entries;}
static std::string modFileModelPath(const std::filesystem::path& path);
static void modFileOpenMap(const std::filesystem::path& path) {
  if(entityLower(path.extension().u8string())!=".map")return;
  command("ftebroom_generator cancel\n");
  documentRequest("@"+path.u8string());
}

static bool modFilesRefresh=true;
static bool modFilesReplacePacked=false;
static std::string modFilesError;
static std::filesystem::path modFileRoot(){return std::filesystem::u8path(gameProfile==0?std::string(baseq3):gameRuntime());}
static std::string modFileModelPath(const std::filesystem::path& path){std::filesystem::path archive;std::string member;if(ftebroom::pak::split(path,archive,member))return member;return path.lexically_relative(modFileRoot()).generic_u8string();}
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
static std::string modFileBytes(const std::filesystem::path& path){
  if(modFileMember(path))return ftebroom::pak::read(path);
  if(!std::filesystem::is_regular_file(path)||std::filesystem::file_size(path)>512*1024*1024)throw std::runtime_error("Choose a regular file up to 512 MiB.");
  std::ifstream in(path,std::ios::binary);std::string bytes(std::istreambuf_iterator<char>(in),{});if(!in.eof()&&in.fail())throw std::runtime_error("Cannot read file.");return bytes;
}
#include "ftebroom_sound_editor.h"
static std::filesystem::path modFileCopy(const std::filesystem::path& source,const std::filesystem::path& folder) {
  modFileValidate(folder);
  if(modFilePacked(folder)){
    auto target=folder/source.filename();if(target==source)return target;
    if(!modFilesReplacePacked)for(int i=1;ftebroom::pak::exists(target);i++)target=folder/(source.stem().u8string()+"-"+std::to_string(i)+source.extension().u8string());
    ftebroom::pak::replace(target,modFileBytes(source));modFilesRefresh=true;return target;
  }
  if(modFileMember(source)){auto bytes=ftebroom::pak::read(source);auto target=folder/source.filename();for(int i=1;std::filesystem::exists(target);i++)target=folder/(source.stem().u8string()+"-"+std::to_string(i)+source.extension().u8string());std::ofstream out(target,std::ios::binary);out.write(bytes.data(),bytes.size());if(!out)throw std::runtime_error("Cannot extract PAK member.");modFilesRefresh=true;return target;}
  if(!std::filesystem::is_regular_file(source)||std::filesystem::is_symlink(source))throw std::runtime_error("Drop regular files; symbolic links and directories are not imported.");
  auto target=folder/source.filename();
  if(std::filesystem::exists(target)&&std::filesystem::equivalent(source,target))return target;
  for(int i=1;std::filesystem::exists(target);i++)target=folder/(source.stem().u8string()+"-"+std::to_string(i)+source.extension().u8string());
  std::filesystem::copy_file(source,target);modFilesRefresh=true;return target;
}
static void modFileMove(const std::filesystem::path& source,const std::filesystem::path& folder) {
  modFileValidate(source);modFileValidate(folder);
  if(modFileMember(source)){ftebroom::pak::rename(source,folder/source.filename());modFilesRefresh=true;return;}
  if(modFilePacked(folder)){modFileCopy(source,folder);return;}
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
  auto folder=ftebroom::pak::diskFolder(modFilesFolder);
  ShellExecuteW(nullptr,L"open",folder.c_str(),nullptr,nullptr,SW_SHOWNORMAL);
#else
  const char* tool=
#ifdef __APPLE__
    "open";
#else
    "xdg-open";
#endif
  std::string folder=ftebroom::pak::diskFolder(modFilesFolder).string();char* args[]={const_cast<char*>(tool),folder.data(),nullptr};pid_t pid;posix_spawnp(&pid,tool,nullptr,nullptr,args,environ);
#endif
}
static std::filesystem::path modFilesClipboard,modFilesRename;
static bool modFilesCut=false,modFilesGrid=true;
static char modFilesRenameName[256]={};
static void modFilesPaste() {
  modFileValidate(modFilesClipboard);modFileValidate(modFilesFolder);
  if(modFilesCut){if(!modFileMember(modFilesClipboard)&&modFilePacked(modFilesFolder))throw std::runtime_error("Use Copy to import into a PAK; cross-boundary Cut is not supported.");modFileMove(modFilesClipboard,modFilesFolder);modFilesClipboard.clear();return;}
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
static std::filesystem::path modFilesEditPath;
static std::string modFilesEditOriginal,modFilesEditError;
static std::vector<char> modFilesEditBuffer(1024*1024+1);
static bool modFilesEditOpen=false;
static bool modFileText(const std::filesystem::path& path){auto ext=entityLower(path.extension().u8string());return std::string("|.txt|.cfg|.shader|.ent|.def|.fgd|.qc|.map|.mtr|.md|.json|.glsl|.h|.c|.inc|.lst|.rc|").find("|"+ext+"|")!=std::string::npos;}
static void modFilesEdit(const std::filesystem::path& path){
  modFileValidate(path);auto bytes=modFileBytes(path);if(bytes.size()>=modFilesEditBuffer.size()||bytes.find('\0')!=bytes.npos)throw std::runtime_error("Text editor supports text files up to 1 MiB. Replace binary files by importing them.");
  modFilesEditPath=path;modFilesEditOriginal=bytes;std::fill(modFilesEditBuffer.begin(),modFilesEditBuffer.end(),0);std::copy(bytes.begin(),bytes.end(),modFilesEditBuffer.begin());modFilesEditError.clear();modFilesEditOpen=true;
}
static void modFilesSaveText(){
  modFileValidate(modFilesEditPath);if(modFileBytes(modFilesEditPath)!=modFilesEditOriginal)throw std::runtime_error("File changed since opening. Close and reopen it before saving.");
  std::string bytes(modFilesEditBuffer.data());
  if(modFileMember(modFilesEditPath))ftebroom::pak::replace(modFilesEditPath,bytes);
  else {auto backup=modFilesEditPath;backup+=".ftebroom-"+std::to_string(std::chrono::high_resolution_clock::now().time_since_epoch().count())+".bak";std::filesystem::copy_file(modFilesEditPath,backup);std::ofstream out(modFilesEditPath,std::ios::binary);out.write(bytes.data(),bytes.size());if(!out)throw std::runtime_error("Cannot save file; original is in the backup.");}
  modFilesEditOriginal=bytes;modFilesRefresh=true;
}
static void modFilesTextPanel(){
  if(!modFilesEditOpen)return;ImGui::SetNextWindowSize({760,520},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Mod text editor",&modFilesEditOpen)){
    ImGui::TextWrapped("%s",modFilesEditPath.u8string().c_str());
    ImGui::InputTextMultiline("##contents",modFilesEditBuffer.data(),modFilesEditBuffer.size(),{-1,-ImGui::GetFrameHeightWithSpacing()*3},ImGuiInputTextFlags_AllowTabInput);
    if(ImGui::Button("Save with backup"))try{modFilesSaveText();modFilesEditError="Saved. Reload mod resources to see asset changes.";}catch(const std::exception& e){modFilesEditError=e.what();}
    ImGui::SameLine();if(ImGui::Button("Close"))modFilesEditOpen=false;
    if(!modFilesEditError.empty())ImGui::TextWrapped("%s",modFilesEditError.c_str());
  }ImGui::End();
}
// Expand only visible/open branches; do not traverse symbolic links or archive payloads.
static void modFilesTree(const std::filesystem::path& folder,std::filesystem::path& navigate,int depth,int& budget) {
  if(depth>48||budget<=0)return;
  try {
    auto found=modFilesTreeCache.find(folder);if(found==modFilesTreeCache.end()) {
      modFileValidate(folder);
      if(!modFilePacked(folder)&&std::filesystem::is_symlink(folder))return;
      auto entries=modFileList(folder);
      // Rendering uses the directory snapshot. File operations still validate
      // live paths before accessing or modifying their destinations.
      entries.erase(std::remove_if(entries.begin(),entries.end(),[](const auto& entry){
        return !modFileInside(entry.second)||(!modFilePacked(entry.second)&&std::filesystem::is_symlink(entry.second));
      }),entries.end());
      found=modFilesTreeCache.emplace(folder,std::move(entries)).first;
    }
    for(const auto& entry:found->second){if(--budget<0)break;auto path=entry.second;
      auto id=path.generic_u8string();ImGui::PushID(id.c_str());
      bool archive=entityLower(path.extension().u8string())==".pak";
      auto flags=ImGuiTreeNodeFlags_OpenOnArrow|ImGuiTreeNodeFlags_SpanAvailWidth;
      if(!entry.first)flags|=ImGuiTreeNodeFlags_Leaf|ImGuiTreeNodeFlags_NoTreePushOnOpen;
      if(path==modFilesFolder)flags|=ImGuiTreeNodeFlags_Selected;
      bool expanded=ImGui::TreeNodeEx("node",flags,"%s%s",archive?"[PAK] ":"",path.filename().u8string().c_str());
      if(ImGui::IsItemClicked()&&!ImGui::IsItemToggledOpen()&&entry.first)navigate=path;
      if(ImGui::IsItemHovered()&&ImGui::IsMouseDoubleClicked(0)&&!entry.first) {
        if(modelFile(path))modelViewerShow(modFileModelPath(path));else if(soundFile(path))soundOpen(path);else modFileOpenMap(path);
      }
      if(entry.first&&expanded){modFilesTree(path,navigate,depth+1,budget);ImGui::TreePop();}ImGui::PopID();
    }
  }catch(const std::exception& e){ImGui::TextDisabled("%s",e.what());}
}
static void modFilesPanel() {
  soundPanel();
  modFilesTextPanel();
  modFilesVisible=false;if(!modFilesOpen)return;
  ImGui::SetNextWindowSize({650*uiScale(),450*uiScale()},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Mod file manager",&modFilesOpen)) {
    modFilesVisible=true;modFilesMin=ImGui::GetWindowPos();auto sz=ImGui::GetWindowSize();modFilesMax={modFilesMin.x+sz.x,modFilesMin.y+sz.y};
    try {
      auto root=modFileRoot();modFileValidate(root);
      if(root!=modFilesRoot){modFilesRoot=root;modFilesFolder=root;modFilesRefresh=true;}
      // Tighten only the toolbar in wide docked panels; keep the file tree and tiles unchanged.
      struct HeaderSpacing {
        bool active;
        HeaderSpacing(bool compact):active(compact){if(active){ImGui::PushStyleVar(ImGuiStyleVar_FramePadding,{4,2});ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing,{5,3});}}
        void restore(){if(active){ImGui::PopStyleVar(2);active=false;}}
        ~HeaderSpacing(){restore();}
      } headerSpacing(ImGui::GetCurrentWindow()->DockIsActive&&sz.x>sz.y*1.6f);
      bool compact=headerSpacing.active;
      if(ImGui::Button("Up")&&modFilesFolder!=root){modFilesFolder=modFilesFolder.parent_path();modFilesRefresh=true;}modFilesTarget(modFilesFolder.parent_path());
      ImGui::SameLine();if(ImGui::Button("Refresh"))modFilesRefresh=true;ImGui::SameLine();if(ImGui::Button("Open in file manager"))modFilesExplorer();
      ImGui::SameLine();ImGui::Checkbox("Thumbnail view",&modFilesGrid);static float tileSize=72;
      if(modFilesGrid){ImGui::SameLine();ImGui::SetNextItemWidth(180);ImGui::SliderFloat("Thumbnail size",&tileSize,48,180,"%.0f");}
      if(compact){ImGui::SameLine();if(ImGui::Button("New..."))ImGui::OpenPopup("Create mod file");}
      ImGui::TextWrapped("%s",modFilesFolder.u8string().c_str());
      static char name[256]={},contents[8192]={};
      if(compact?ImGui::BeginPopup("Create mod file"):ImGui::CollapsingHeader("New file / folder")) {
        try {
        ImGui::InputText("Name",name,sizeof name);ImGui::InputTextMultiline("Initial file contents",contents,sizeof contents,{0,90});
        bool packed=modFilePacked(modFilesFolder);ImGui::BeginDisabled(packed);bool folder=ImGui::Button("Create folder");ImGui::EndDisabled();ImGui::SameLine();bool file=ImGui::Button("Create file");
        if(packed)ImGui::TextDisabled("PAK folders are implicit: use subfolder/file.cfg as the name.");
        if(folder||file){auto leaf=std::filesystem::u8path(name);if(leaf.empty()||(!packed&&leaf.has_parent_path())||leaf.is_absolute()||leaf=="."||leaf=="..")throw std::runtime_error("Enter a valid relative file or folder name.");auto target=modFilesFolder/leaf;modFileValidate(target);if(ftebroom::pak::exists(target)||std::filesystem::exists(target))throw std::runtime_error("Name already exists.");if(packed)ftebroom::pak::replace(target,contents);else if(folder)std::filesystem::create_directory(target);else{std::ofstream out(target,std::ios::binary);out<<contents;if(!out)throw std::runtime_error("Cannot create file.");}modFilesRefresh=true;}
        }catch(const std::exception& e){modFilesError=e.what();}
        if(compact)ImGui::EndPopup();
      }
      if(modFilesRefresh){modFilesEntries=modFileList(modFilesFolder);modFilesTreeCache.clear();modFilesRefresh=false;}
      if(modFilePacked(modFilesFolder))ImGui::Checkbox("Replace matching files on import (backup)",&modFilesReplacePacked);
      headerSpacing.restore();
      if(!modFilesError.empty())ImGui::TextWrapped("%s",modFilesError.c_str());
      ImGui::Separator();std::filesystem::path navigate;
      ImGui::BeginChild("Folder hierarchy",{std::min(230.f,ImGui::GetContentRegionAvail().x*.35f),0},ImGuiChildFlags_Borders|ImGuiChildFlags_ResizeX);
      if(ImGui::Selectable("Mod root",modFilesFolder==root))navigate=root;
      int treeBudget=4000;modFilesTree(root,navigate,0,treeBudget);if(treeBudget<=0)ImGui::TextDisabled("Collapse branches to display more entries.");
      ImGui::EndChild();ImGui::SameLine();ImGui::BeginChild("Folder contents",{0,0});
      int columns=modFilesGrid?std::max(1,int(ImGui::GetContentRegionAvail().x/(tileSize+12))):1;
      float rowHeight=modFilesGrid?tileSize+38:ImGui::GetTextLineHeightWithSpacing()+5;
      ImGuiListClipper clipper;clipper.Begin(((int)modFilesEntries.size()+columns-1)/columns,rowHeight);
      while(clipper.Step())for(int row=clipper.DisplayStart;row<clipper.DisplayEnd;row++)for(int col=0;col<columns;col++) {
        int i=row*columns+col;if(i>=(int)modFilesEntries.size())break;
        auto& entry=modFilesEntries[i];auto path=entry.second;bool directory=entry.first;auto label=path.filename().u8string();
        if(col)ImGui::SameLine();ImGui::PushID(i);auto p=ImGui::GetCursorScreenPos();
        if(ImGui::Selectable("##file",false,ImGuiSelectableFlags_AllowDoubleClick,{modFilesGrid?tileSize+8:ImGui::GetContentRegionAvail().x,rowHeight-4})&&directory)navigate=path;
        if(ImGui::IsItemHovered()&&ImGui::IsMouseDoubleClicked(0)&&!directory) {
          if(modelFile(path))modelViewerShow(modFileModelPath(path));else if(soundFile(path))soundOpen(path);else modFileOpenMap(path);
        }
        if(ImGui::IsItemHovered())ImGui::SetTooltip("%s",label.c_str());
        if(ImGui::BeginDragDropSource()){auto value=path.u8string();ImGui::SetDragDropPayload("FTEBROOM_MOD_FILE",value.c_str(),value.size()+1);ImGui::TextUnformatted(label.c_str());ImGui::EndDragDropSource();}
        if(directory)modFilesTarget(path);
        if(ImGui::BeginPopupContextItem("file_actions")) {
          if(ImGui::MenuItem("Copy")){modFilesClipboard=path;modFilesCut=false;}
          if(ImGui::MenuItem("Cut")){modFilesClipboard=path;modFilesCut=true;}
          if(ImGui::MenuItem("Paste",nullptr,false,!modFilesClipboard.empty())){try{modFilesPaste();}catch(const std::exception& e){modFilesError=e.what();}}
          if(ImGui::MenuItem("Rename...")){modFilesRename=path;std::snprintf(modFilesRenameName,sizeof modFilesRenameName,"%s",label.c_str());}
          if(!directory&&modFileText(path)&&ImGui::MenuItem("Edit text...")){try{modFilesEdit(path);}catch(const std::exception& e){modFilesError=e.what();}}
          if(ImGui::MenuItem("Open containing directory"))modFilesExplorer();ImGui::EndPopup();
        }
        float icon=modFilesGrid?tileSize:rowHeight-5;
        bool preview=false;if(modFilesGrid&&!directory&&modelFile(path)){ftebroom::EntityDefinition def;def.model=modFileModelPath(path);def.brush=false;preview=entityModelTile(def,p,icon);}
        if(!preview)modFileIcon(p,icon,directory);
        if(directory&&entityLower(path.extension().u8string())==".pak"){auto d=ImGui::GetWindowDrawList();d->AddRectFilled({p.x+icon*.43f,p.y+icon*.3f},{p.x+icon*.58f,p.y+icon*.8f},IM_COL32(85,110,155,255));}
        auto ext=entityLower(path.extension().u8string());
        if(!directory && !preview){auto list=ImGui::GetWindowDrawList();auto color=IM_COL32(45,75,110,255);
          if(ext==".wav"||ext==".ogg"||ext==".mp3"||ext==".flac"){list->AddCircleFilled({p.x+icon*.38f,p.y+icon*.66f},icon*.1f,color);list->AddLine({p.x+icon*.47f,p.y+icon*.66f},{p.x+icon*.47f,p.y+icon*.25f},color,2);list->AddLine({p.x+icon*.47f,p.y+icon*.25f},{p.x+icon*.68f,p.y+icon*.3f},color,3);}
          else if(ext==".png"||ext==".jpg"||ext==".jpeg"||ext==".tga"||ext==".bmp"){list->AddTriangleFilled({p.x+icon*.3f,p.y+icon*.7f},{p.x+icon*.5f,p.y+icon*.4f},{p.x+icon*.7f,p.y+icon*.7f},color);list->AddCircleFilled({p.x+icon*.65f,p.y+icon*.3f},icon*.06f,color);}
        }
        auto d=ImGui::GetWindowDrawList();ImVec2 text=modFilesGrid?ImVec2(p.x+3,p.y+tileSize):ImVec2(p.x+icon+7,p.y+2);
        d->PushClipRect(p,{p.x+(modFilesGrid?tileSize+8:ImGui::GetContentRegionAvail().x),p.y+rowHeight-4},true);d->AddText(text,ImGui::GetColorU32(ImGuiCol_Text),label.c_str());d->PopClipRect();
        ImGui::PopID();
      }
      ImGui::EndChild();
      if(!navigate.empty()){modFileValidate(navigate);modFilesFolder=navigate;modFilesRefresh=true;}
    }catch(const std::exception& e){modFilesError=e.what();ImGui::TextWrapped("%s",modFilesError.c_str());}
    if(ImGui::BeginPopupContextWindow("mod_files_context",ImGuiPopupFlags_MouseButtonRight|ImGuiPopupFlags_NoOpenOverItems)){if(ImGui::MenuItem("Paste",nullptr,false,!modFilesClipboard.empty()))try{modFilesPaste();}catch(const std::exception& e){modFilesError=e.what();}if(ImGui::MenuItem("Open this directory in OS file manager"))modFilesExplorer();ImGui::EndPopup();}
    if(!modFilesRename.empty()) {
      ImGui::SeparatorText("Rename file / folder");ImGui::InputText("New name",modFilesRenameName,sizeof modFilesRenameName);
      if(ImGui::Button("Rename"))try {
        auto leaf=std::filesystem::u8path(modFilesRenameName);if(leaf.empty()||leaf.has_parent_path()||leaf=="."||leaf=="..")throw std::runtime_error("Enter a single filename.");
        auto target=modFilesRename.parent_path()/leaf;modFileValidate(modFilesRename);modFileValidate(target);
        if(std::filesystem::exists(target)||ftebroom::pak::exists(target))throw std::runtime_error("Name already exists.");
        if(modFileMember(modFilesRename))ftebroom::pak::rename(modFilesRename,target);else std::filesystem::rename(modFilesRename,target);modFilesRename.clear();modFilesRefresh=true;
      }catch(const std::exception& e){modFilesError=e.what();}
      ImGui::SameLine();if(ImGui::Button("Cancel rename"))modFilesRename.clear();
    }
  }ImGui::End();
}
