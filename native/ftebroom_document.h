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
static std::filesystem::path documentFile, pendingDocumentFile, saveNativeTarget;
static std::string pendingDocumentAlias;
static int saveRevision;
static bool savingDocument, savingBackup, savingExport, confirmDocument;
static bool exportRequest;
static bool documentUntitled;
static unsigned long long saveSerial;
static auto lastBackup = std::chrono::steady_clock::now();

static std::filesystem::path documentPath(const std::string& relative)
{
  char path[4096];
  if (!files->NativePath(relative.c_str(), (fs_relative)5, path, sizeof path))
    return {};
  return std::filesystem::u8path(path);
}
#include "ftebroom_lines.h"
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
  const std::string storageName =
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
    for (int i = 0; i < 50; ++i)
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
    if (!savingBackup && !savingExport)
    {
      documentIndexLines(target);
      documentFile = target;
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
  const auto now = std::chrono::steady_clock::now();
  const double minutes = cvars->GetFloat("ftebroom_autosave_interval");
  if (
    minutes <= 0
    || std::chrono::duration<double>(now - lastBackup).count() < minutes * 60)
    return;
  if (!savingDocument && !sceneDrag && cvars->GetFloat("ftebroom_dirty"))
  {
    documentSave(documentName, true);
    lastBackup = now;
  }
}
static void documentDialogs()
{
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

// Paths stay in native filesystem APIs; only generated ASCII aliases reach FTE commands.
static bool fileBrowserSaving, fileBrowserExport, fileBrowserDefinitions,
  definitionsRequest;
static void definitionsChoose(const std::filesystem::path& path);
static std::filesystem::path fileBrowserFolder;
static char fileBrowserPath[4096] = {}, fileBrowserName[1024] = {};
static std::filesystem::path overwriteTarget;
static void documentFileBrowser()
{
  if (openRequest || saveRequest || definitionsRequest || exportRequest)
  {
    cancelGesture();
    fileBrowserSaving = saveRequest || exportRequest;
    fileBrowserExport = exportRequest;
    exportRequest = false;
    fileBrowserDefinitions = definitionsRequest;
    definitionsRequest = false;
    openRequest = saveRequest = false;
    if (fileBrowserFolder.empty())
      fileBrowserFolder =
        documentFile.empty() ? documentPath("maps") : documentFile.parent_path();
    std::snprintf(
      fileBrowserPath,
      sizeof fileBrowserPath,
      "%s",
      fileBrowserFolder.u8string().c_str());
    std::snprintf(
      fileBrowserName,
      sizeof fileBrowserName,
      "%s",
      fileBrowserSaving ? (documentName + ".map").c_str() : "");
    documentError.clear();
    ImGui::OpenPopup("Map files");
  }
  ImGui::SetNextWindowSize({720, 520}, ImGuiCond_FirstUseEver);
  if (ImGui::BeginPopupModal("Map files", nullptr))
  {
    ImGui::TextUnformatted(
      fileBrowserExport        ? "Export map for compilation (omitted layers excluded)"
      : fileBrowserDefinitions ? "Open entity definitions"
      : fileBrowserSaving      ? "Save map as"
                               : "Open map");
    bool upClicked = ImGui::Button("Up");
    fileBrowserTestItem("up");
    if (upClicked)
    {
      fileBrowserFolder = fileBrowserFolder.parent_path();
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
        && (folder || (fileBrowserDefinitions ? (extension == ".ent" || extension == ".def" || extension == ".fgd") : extension == ".map")))
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
        if (entry.first && ImGui::IsMouseDoubleClicked(0))
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
        target += ".map";
      auto extension = target.extension().u8string();
      std::transform(
        extension.begin(), extension.end(), extension.begin(), [](unsigned char c) {
          return char(std::tolower(c));
        });
      if (fileBrowserDefinitions)
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
      else if (!*fileBrowserName || extension != ".map")
        documentError = "Choose a .map file.";
      else if (fileBrowserSaving)
      {
        if (std::filesystem::exists(target, error))
        {
          overwriteTarget = target;
          ImGui::OpenPopup("Replace map?");
        }
        else if (documentSave(documentName, false, target, fileBrowserExport))
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
        if (documentSave(documentName, false, overwriteTarget, fileBrowserExport))
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
    if (savingDocument)
      ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
  }
}
