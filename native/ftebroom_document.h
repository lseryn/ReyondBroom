// SPDX-License-Identifier: GPL-2.0-or-later
#include <chrono>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

static std::map<std::string, ImVec2> fileBrowserTestItems;
static void fileBrowserTestItem(const std::string& name)
{
  if (!cvars->GetFloat("ftebroom_skip_setup"))
    return;
  auto a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
  fileBrowserTestItems[name] = {(a.x + b.x) * .5f, (a.y + b.y) * .5f};
}
static std::string documentName = "start", documentError, documentNext;
static std::string saveTemporary, saveDestination;
static std::filesystem::path documentFile, pendingDocumentFile, saveNativeTarget, fileBrowserFolder;
static std::string pendingDocumentAlias;
static int saveRevision;
static bool savingDocument, savingBackup, savingExport, confirmDocument;
static bool exportRequest;
static bool objRequest, fileBrowserObj, savingObj;
static std::filesystem::path objDestination;
static bool documentUntitled;
static unsigned long long saveSerial;
static auto lastBackup = std::chrono::steady_clock::now();
static std::filesystem::path recoveryFile, recoverySource;
static bool recoveryRequest, recoveryOpening;
static std::string backupStorageName()
{
  if (documentFile.empty()) return "untitled";
  uint64_t hash = 14695981039346656037ull;
  for (unsigned char c : documentFile.lexically_normal().u8string()) {hash ^= c; hash *= 1099511628211ull;}
  return "map-" + std::to_string(hash);
}

static std::filesystem::path documentPath(const std::string& relative)
{
  char path[4096];
  if (!files->NativePath(relative.c_str(), (fs_relative)5, path, sizeof path))
    return {};
  return std::filesystem::u8path(path);
}
static std::filesystem::path documentDefaultFolder()
{
  if(!documentFile.empty())return documentFile.parent_path();
  std::error_code error;
  if(*baseq3 && std::filesystem::is_directory(std::filesystem::u8path(baseq3),error))
    return std::filesystem::u8path(baseq3)/"maps";
  return documentPath("maps");
}
#include "ftebroom_lines.h"
#include "ftebroom_trace_files.h"
static bool objSave(const std::filesystem::path& target)
{
  if (savingObj) return false;
  objDestination = target; savingObj = true;
  cvars->SetFloat("ftebroom_obj_status", 0);
  action("ftebroom_export_obj\nftebroom_obj_finish\n");
  return true;
}
static void objSaveFinished()
{
  if (!savingObj) return;
  savingObj = false;
  std::filesystem::path staged, material;
  try
  {
    if (cvars->GetFloat("ftebroom_obj_status") != 1)
      throw std::runtime_error("OBJ export failed.");
    const auto serial = std::to_string(std::chrono::system_clock::now().time_since_epoch().count());
    const auto materialName = "ftebroom-materials-" + serial + ".mtl";
    material = objDestination.parent_path() / materialName;
    staged = objDestination; staged += "." + serial + ".tmp";
    std::ifstream input(documentPath("data/export.obj"));
    std::ofstream output(staged);
    std::string line;
    while (std::getline(input, line))
      output << (line.rfind("mtllib ",0)==0 ? "mtllib " + materialName : line) << '\n';
    output.close();
    if (!input.eof() || !output) throw std::runtime_error("Cannot stage OBJ export.");
    std::filesystem::copy_file(documentPath("data/export.mtl"), material);
#ifdef _WIN32
    if (!MoveFileExW(staged.c_str(),objDestination.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))
      throw std::runtime_error("Cannot replace OBJ destination.");
#else
    std::filesystem::rename(staged,objDestination);
#endif
    core->Print("FTEBroom: OBJ and MTL exported.\n");
  }
  catch (const std::exception& error)
  {
    documentError = error.what(); std::error_code ignored;
    if (!staged.empty()) std::filesystem::remove(staged,ignored);
    if (!material.empty()) std::filesystem::remove(material,ignored);
  }
}
static void documentProceed()
{
  const auto next = documentNext;
  documentNext.clear();
  if (next == "exit")
    action("quit force\n");
  else if (next == "__new")
  {
    const auto name =
      "_ftebroom_new_"
      + std::to_string(std::chrono::system_clock::now().time_since_epoch().count());
    const auto path = documentPath("maps/" + name + ".map");
    std::ofstream file(path);
    file << "{\n\"classname\" \"worldspawn\"\n}\n";
    file.close();
    if (!file)
      documentError = "Cannot create a new map.";
    else
      action(("mapedit maps/" + name + ".map\n").c_str());
  }
  else if (next.rfind("@", 0) == 0)
  {
    try
    {
      pendingDocumentFile = std::filesystem::u8path(next.substr(1));
      pendingDocumentAlias =
        "_ftebroom_open_"
        + std::to_string(std::chrono::system_clock::now().time_since_epoch().count())
        + "_" + std::to_string(++saveSerial);
      std::filesystem::copy_file(
        pendingDocumentFile,
        documentPath("maps/" + pendingDocumentAlias + ".map"),
        std::filesystem::copy_options::overwrite_existing);
      action(("mapedit maps/" + pendingDocumentAlias + ".map\n").c_str());
    }
    catch (const std::exception& error)
    {
      documentError = error.what();
      pendingDocumentFile.clear();
    }
  }
  else if (!next.empty())
    action(("mapedit maps/" + next + ".map\n").c_str());
}
static bool documentSave(
  const std::string& name,
  bool backup = false,
  const std::filesystem::path& destination = {},
  bool compile = false)
{
  if (
    savingDocument
    || (!safeName(name.c_str()) && documentFile.empty() && destination.empty()))
    return false;
  documentError.clear();
  const auto serial = std::chrono::system_clock::now().time_since_epoch().count();
  saveTemporary =
    "_ftebroom_save_" + std::to_string(serial) + "_" + std::to_string(++saveSerial);
  const std::string storageName = backup ? backupStorageName() :
    safeName(name.c_str())
      ? name
      : "external_" + std::to_string(std::hash<std::string>{}(documentFile.u8string()));
  saveDestination = "maps/" + storageName + ".map";
  saveNativeTarget = destination;
  if (saveNativeTarget.empty() && !backup && name == documentName)
    saveNativeTarget = documentFile;
  if (backup)
  {
    saveNativeTarget.clear();
    int slot = 0;
    auto oldest = std::filesystem::file_time_type::max();
    for (int i = 0; i < std::clamp((int)cvars->GetFloat("ftebroom_autosave_count"),1,200); ++i)
    {
      const auto path =
        documentPath("autosave/" + storageName + "-" + std::to_string(i) + ".map");
      std::error_code error;
      if (!std::filesystem::exists(path, error))
      {
        slot = i;
        break;
      }
      const auto modified = std::filesystem::last_write_time(path, error);
      if (!error && modified < oldest)
      {
        oldest = modified;
        slot = i;
      }
    }
    saveDestination = "autosave/" + storageName + "-" + std::to_string(slot) + ".map";
  }
  if (documentPath("maps/" + saveTemporary + ".map").empty())
  {
    documentError = "Cannot locate the writable editor directory.";
    return false;
  }
  saveRevision = (int)cvars->GetFloat("ftebroom_revision");
  savingDocument = true;
  savingBackup = backup;
  savingExport = compile;
  if (compile)
  {
    cvars->SetFloat("ftebroom_export_status", 0);
    action("ftebroom_export_map\nftebroom_save_finish\n");
    return true;
  }
  action(("mod_terrain_save \"\" " + saveTemporary + "\nftebroom_save_finish\n").c_str());
  return true;
}
static void documentSaveFinished()
{
  if (!savingDocument)
    return;
  savingDocument = false;
  const auto source =
    documentPath(savingExport ? "data/export-map.map" : "maps/" + saveTemporary + ".map");
  const auto target =
    saveNativeTarget.empty() ? documentPath(saveDestination) : saveNativeTarget;
  try
  {
    if (
      (savingExport && cvars->GetFloat("ftebroom_export_status") != 1) || source.empty()
      || target.empty() || !std::filesystem::exists(source)
      || std::filesystem::file_size(source) == 0)
      throw std::runtime_error("The engine did not write the map.");
    std::filesystem::create_directories(target.parent_path());
    // Stage beside the destination so replacement remains atomic across drives.
    auto adjacent = target;
    adjacent += ".ftebroom-" + std::to_string(saveSerial) + ".tmp";
    std::filesystem::copy_file(
      source, adjacent, std::filesystem::copy_options::overwrite_existing);
#ifdef _WIN32
    if (!MoveFileExW(
          adjacent.c_str(),
          target.c_str(),
          MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
    {
      std::filesystem::remove(adjacent);
      throw std::runtime_error("Cannot replace the destination file.");
    }
#else
    std::filesystem::rename(adjacent, target);
#endif
    std::error_code cleanupError;
    std::filesystem::remove(source, cleanupError);
    core->Print(("FTEBROOM_SAVED " + saveDestination + "\n").c_str());
    if (savingBackup)
    {
      auto sourcePath = target; sourcePath += ".source";
      std::ofstream(sourcePath) << documentFile.u8string();
      int retained=std::clamp((int)cvars->GetFloat("ftebroom_autosave_count"),1,200);
      for(int i=retained;i<200;i++)
      {
        auto old=documentPath("autosave/"+backupStorageName()+"-"+std::to_string(i)+".map");
        std::error_code ignored;std::filesystem::remove(old,ignored);old+=".source";std::filesystem::remove(old,ignored);
      }
    }
    if (!savingBackup && !savingExport)
    {
      documentIndexLines(target);
      documentFile = target;
      fileBrowserFolder=target.parent_path();
      cvars->SetString("ftebroom_document_path",target.u8string().c_str());
      documentName = target.stem().u8string();
      documentUntitled = false;
      std::snprintf(mapName, sizeof mapName, "%s", documentName.c_str());
      command(("ftebroom_document_saved " + std::to_string(saveRevision) + "\n").c_str());
      if ((int)cvars->GetFloat("ftebroom_revision") == saveRevision)
        documentProceed();
      else
        documentNext.clear();
    }
  }
  catch (const std::exception& error)
  {
    documentError = error.what();
    documentNext.clear();
    core->Print(("FTEBroom save failed: " + documentError + "\n").c_str());
  }
}
static void documentRequest(const std::string& next)
{
  if (savingDocument)
    return;
  if (next.rfind("@", 0) == 0)
  {
    std::error_code error;
    auto path = std::filesystem::u8path(next.substr(1));
    if (
      !std::filesystem::is_regular_file(path, error)
      || std::filesystem::file_size(path, error) == 0 || error)
    {
      documentError = "The requested map is missing, empty or unreadable.";
      return;
    }
  }
  else if (next != "exit" && next != "__new")
  {
    qhandle_t handle;
    const int size = files->Open(("maps/" + next + ".map").c_str(), &handle, 1);
    if (handle >= 0)
      files->Close(handle);
    if (size <= 0)
    {
      documentError = "The requested map is missing or empty.";
      return;
    }
  }
  cancelGesture();
  documentNext = next;
  if (cvars->GetFloat("ftebroom_dirty"))
    confirmDocument = true;
  else
    documentProceed();
}
static void documentTick()
{
  static bool recoveryChecked = false;
  if (!recoveryChecked)
  {
    recoveryChecked = true;
    if (!cvars->GetFloat("ftebroom_skip_setup"))
    {
      std::error_code error;
      auto newest = std::filesystem::file_time_type::min();
      for (std::filesystem::directory_iterator it(documentPath("autosave"),error),end; it!=end; it.increment(error))
      {
        if (error) break;
        if (it->path().extension()!=".map") continue;
        auto sourcePath=it->path(); sourcePath += ".source";
        std::ifstream stream(sourcePath); std::string source; std::getline(stream,source);
        if (!stream && source.empty()) continue;
        auto backupTime=std::filesystem::last_write_time(it->path(),error); if(error){error.clear();continue;}
        auto original=std::filesystem::u8path(source);
        auto originalTime=std::filesystem::last_write_time(original,error);
        bool newer=source.empty() || error || backupTime>originalTime;error.clear();
        if(newer && backupTime>newest){newest=backupTime;recoveryFile=it->path();recoverySource=original;recoveryRequest=true;}
      }
    }
  }
  const auto now = std::chrono::steady_clock::now();
  const double minutes = cvars->GetFloat("ftebroom_autosave_interval");
  if (
    minutes <= 0
    || std::chrono::duration<double>(now - lastBackup).count() < minutes * 60)
    return;
  if (!savingDocument && !sceneDrag && !cvars->GetFloat("ftebroom_bsp_preview") && cvars->GetFloat("ftebroom_dirty"))
  {
    documentSave(documentName, true);
    lastBackup = now;
  }
}
static void documentDialogs()
{
  if (recoveryRequest) {ImGui::OpenPopup("Recover autosave?");recoveryRequest=false;}
  if (uiDialog("Recover autosave?"))
  {
    ImGui::TextWrapped("A newer autosave is available for %s. Restore it as an unsaved document?",recoverySource.empty()?"an untitled map":recoverySource.u8string().c_str());
    if(ImGui::Button("Recover")) {recoveryOpening=true;documentRequest("@"+recoveryFile.u8string());ImGui::CloseCurrentPopup();}
    ImGui::SameLine();if(ImGui::Button("Keep current map")) ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
  }
  if (confirmDocument)
  {
    ImGui::OpenPopup("Save changes?");
    confirmDocument = false;
  }
  if (uiDialog("Save changes?"))
  {
    ImGui::Text("Save changes to %s.map?", documentName.c_str());
    if (ImGui::Button("Save"))
    {
      if (documentUntitled)
      {
        saveRequest = true;
        inspector = true;
      }
      else
        documentSave(documentName);
      ImGui::CloseCurrentPopup();
    }
    ImGui::SameLine();
    if (ImGui::Button("Don't Save"))
    {
      documentProceed();
      ImGui::CloseCurrentPopup();
    }
    ImGui::SameLine();
    if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape))
    {
      documentNext.clear();
      ImGui::CloseCurrentPopup();
    }
    ImGui::EndPopup();
  }
  if(uiClosedDialog=="Document error"){documentError.clear();uiClosedDialog.clear();}
  if(uiClosedDialog=="Save changes?"){documentNext.clear();uiClosedDialog.clear();}
  if (!documentError.empty() && !ImGui::IsPopupOpen("Map files"))
  {
    ImGui::OpenPopup("Document error");
    if (uiDialog("Document error"))
    {
      ImGui::TextWrapped("%s", documentError.c_str());
      if (ImGui::Button("OK"))
      {
        documentError.clear();
        ImGui::CloseCurrentPopup();
      }
      ImGui::EndPopup();
    }
  }
}
static void documentSaveCommand()
{
  char name[64];
  commands->Argv(1, name, sizeof name);
  documentSave(*name ? name : documentName);
}
static void testBackups()
{
  if(!cvars->GetFloat("ftebroom_skip_setup"))return;
  char argument[16]={};commands->Argv(1,argument,sizeof argument);
  if(std::atoi(argument)==0){cvars->SetFloat("ftebroom_autosave_count",2);documentSave(documentName,true);return;}
  int count=0;bool valid=true;std::error_code error;
  for(std::filesystem::directory_iterator it(documentPath("autosave"),error),end;it!=end;it.increment(error))
  {
    if(error){valid=false;break;}
    if(it->path().extension()!=".map"||it->path().filename().u8string().rfind(backupStorageName()+"-",0)!=0)continue;
    ++count;auto source=it->path();source+=".source";std::ifstream input(source);std::string text;std::getline(input,text);
    valid=valid&&text==documentFile.u8string()&&std::filesystem::file_size(it->path())>100;
  }
  core->Print(valid&&count==2?"FTEBROOM_BACKUP_PASS bounded_rotation_and_source\n":"FTEBROOM_BACKUP_FAIL bounded_rotation_and_source\n");
}

// Paths stay in native filesystem APIs; only generated ASCII aliases reach FTE commands.
static bool fileBrowserSaving, fileBrowserExport, fileBrowserDefinitions,
  definitionsRequest;
static void definitionsChoose(const std::filesystem::path& path);

static char fileBrowserPath[4096] = {}, fileBrowserName[1024] = {};
static std::filesystem::path overwriteTarget;
static void documentFileBrowser()
{
  if (openRequest || saveRequest || definitionsRequest || exportRequest || traceRequest || objRequest)
  {
    cancelGesture();
    fileBrowserTrace = traceRequest;
    traceRequest = 0;
    fileBrowserObj = objRequest; objRequest = false;
    fileBrowserSaving = saveRequest || exportRequest || fileBrowserObj;
    fileBrowserExport = exportRequest;
    exportRequest = false;
    fileBrowserDefinitions = definitionsRequest;
    definitionsRequest = false;
    openRequest = saveRequest = false;
    if(!fileBrowserDefinitions && !fileBrowserTrace)fileBrowserFolder=documentDefaultFolder();
    else if(fileBrowserFolder.empty())fileBrowserFolder=documentDefaultFolder();
    std::snprintf(
      fileBrowserPath,
      sizeof fileBrowserPath,
      "%s",
      fileBrowserFolder.u8string().c_str());
    std::snprintf(
      fileBrowserName,
      sizeof fileBrowserName,
      "%s",
      fileBrowserSaving ? (documentName + (fileBrowserObj ? ".obj" : ".map")).c_str() : "");
    documentError.clear();
    ImGui::OpenPopup("Map files");
  }
  ImGui::SetNextWindowSize({720, 520}, ImGuiCond_FirstUseEver);
  if (uiDialog("Map files",{760,540}))
  {
    ImGui::TextUnformatted(
      fileBrowserObj          ? "Export Wavefront OBJ + MTL (omitted layers excluded)"
      : fileBrowserTrace == 1 ? "Load point file (.lin)"
      : fileBrowserTrace == 2  ? "Load portal file (.prt)"
      : fileBrowserExport     ? "Export map for compilation (omitted layers excluded)"
      : fileBrowserDefinitions ? "Open entity definitions"
      : fileBrowserSaving      ? "Save map as"
                               : "Open map");
    bool canGoUp = fileBrowserFolder.has_parent_path() && fileBrowserFolder.parent_path() != fileBrowserFolder;
    ImGui::BeginDisabled(!canGoUp);
    bool upClicked = ImGui::Button("Up one level");
    ImGui::EndDisabled();
    fileBrowserTestItem("up");
    if (upClicked)
    {
      fileBrowserFolder = fileBrowserFolder.parent_path();
      documentError.clear();
      if (!fileBrowserSaving) fileBrowserName[0] = 0;
      std::snprintf(
        fileBrowserPath,
        sizeof fileBrowserPath,
        "%s",
        fileBrowserFolder.u8string().c_str());
    }
#ifdef _WIN32
    ImGui::SameLine();
    if (ImGui::BeginCombo("Drive", fileBrowserFolder.root_name().u8string().c_str()))
    {
      DWORD drives = GetLogicalDrives();
      for (int i = 0; i < 26; i++)
        if (drives & (1u << i))
        {
          char drive[] = "A:/";
          drive[0] += i;
          if (ImGui::Selectable(drive))
          {
            fileBrowserFolder = std::filesystem::u8path(drive);
            std::snprintf(fileBrowserPath, sizeof fileBrowserPath, "%s", drive);
          }
        }
      ImGui::EndCombo();
    }
#endif
    bool go = ImGui::InputText(
      "Folder",
      fileBrowserPath,
      sizeof fileBrowserPath,
      ImGuiInputTextFlags_EnterReturnsTrue);
    ImGui::SameLine();
    go |= ImGui::Button("Go");
    if (go)
    {
      std::error_code error;
      auto folder = std::filesystem::u8path(fileBrowserPath);
      if (std::filesystem::is_directory(folder, error))
      {
        fileBrowserFolder = folder;
        documentError.clear();
      }
      else
        documentError = "Folder does not exist or cannot be read.";
    }
    ImGui::BeginChild("File list", {0, -105}, ImGuiChildFlags_Borders);
    std::error_code error;
    std::vector<std::pair<bool, std::filesystem::path>> entries;
    for (std::filesystem::directory_iterator it(fileBrowserFolder, error), end; it != end;
         it.increment(error))
    {
      if (error)
        break;
      std::error_code statError;
      bool folder = it->is_directory(statError);
      auto extension = it->path().extension().u8string();
      std::transform(
        extension.begin(), extension.end(), extension.begin(), [](unsigned char c) {
          return char(std::tolower(c));
        });
      if (
        !statError
        && (folder || (fileBrowserObj ? extension == ".obj" : fileBrowserTrace ? extension == (fileBrowserTrace == 1 ? ".lin" : ".prt") : fileBrowserDefinitions ? (extension == ".ent" || extension == ".def" || extension == ".fgd") : extension == ".map")))
        entries.push_back({folder, it->path()});
    }
    std::sort(entries.begin(), entries.end(), [](const auto& a, const auto& b) {
      return a.first != b.first ? a.first > b.first
                                : a.second.filename() < b.second.filename();
    });
    for (auto& entry : entries)
    {
      auto name = entry.second.filename().u8string();
      auto label = (entry.first ? "[Folder] " : "") + name;
      bool entryClicked = ImGui::Selectable(
        label.c_str(), name == fileBrowserName, ImGuiSelectableFlags_AllowDoubleClick);
      fileBrowserTestItem(name);
      if (entryClicked)
      {
        if (entry.first)
        {
          fileBrowserFolder = entry.second;
          std::snprintf(
            fileBrowserPath,
            sizeof fileBrowserPath,
            "%s",
            fileBrowserFolder.u8string().c_str());
        }
        else if (!entry.first)
          std::snprintf(fileBrowserName, sizeof fileBrowserName, "%s", name.c_str());
      }
    }
    if (error)
      ImGui::TextWrapped("Cannot read this folder: %s", error.message().c_str());
    ImGui::EndChild();
    ImGui::InputText("File name", fileBrowserName, sizeof fileBrowserName);
    if (!documentError.empty())
      ImGui::TextWrapped("%s", documentError.c_str());
    bool primaryClicked = ImGui::Button(fileBrowserSaving ? "Save" : "Open");
    fileBrowserTestItem("primary");
    if (primaryClicked)
    {
      auto target = fileBrowserFolder / std::filesystem::u8path(fileBrowserName);
      if (target.extension().empty() && !fileBrowserDefinitions)
        target += fileBrowserObj ? ".obj" : fileBrowserTrace == 1 ? ".lin" : fileBrowserTrace == 2 ? ".prt" : ".map";
      auto extension = target.extension().u8string();
      std::transform(
        extension.begin(), extension.end(), extension.begin(), [](unsigned char c) {
          return char(std::tolower(c));
        });
      if (fileBrowserTrace)
      {
        if (traceChoose(fileBrowserTrace, target)) ImGui::CloseCurrentPopup();
      }
      else if (fileBrowserDefinitions)
      {
        if (extension != ".ent" && extension != ".def" && extension != ".fgd")
          documentError = "Choose an .ent, .def or .fgd file.";
        else if (!std::filesystem::is_regular_file(target, error))
          documentError = "Definition file does not exist.";
        else
        {
          definitionsChoose(target);
          ImGui::CloseCurrentPopup();
        }
      }
      else if (!*fileBrowserName || extension != (fileBrowserObj ? ".obj" : ".map"))
        documentError = fileBrowserObj ? "Choose an .obj file." : "Choose a .map file.";
      else if (fileBrowserSaving)
      {
        if (std::filesystem::exists(target, error))
        {
          overwriteTarget = target;
          ImGui::OpenPopup("Replace map?");
        }
        else if (fileBrowserObj ? objSave(target) : documentSave(documentName, false, target, fileBrowserExport))
          ImGui::CloseCurrentPopup();
      }
      else
      {
        documentError.clear();
        documentRequest("@" + target.u8string());
        if (documentError.empty())
          ImGui::CloseCurrentPopup();
      }
    }
    ImGui::SameLine();
    if (
      ImGui::Button("Cancel")
      || (ImGui::IsKeyPressed(ImGuiKey_Escape) && !ImGui::IsPopupOpen("Replace map?")))
    {
      documentNext.clear();
      documentError.clear();
      ImGui::CloseCurrentPopup();
    }
    if (uiDialog("Replace map?"))
    {
      ImGui::TextWrapped("Replace %s?", overwriteTarget.u8string().c_str());
      if (ImGui::Button("Replace"))
      {
        if (fileBrowserObj ? objSave(overwriteTarget) : documentSave(documentName, false, overwriteTarget, fileBrowserExport))
        {
          ImGui::CloseCurrentPopup();
          fileBrowserSaving = false;
        }
      }
      ImGui::SameLine();
      if (ImGui::Button("Cancel"))
        ImGui::CloseCurrentPopup();
      ImGui::EndPopup();
    }
    // Successful replacement closes the parent on the next frame.
    if (savingDocument || savingObj)
      ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
  }
}
