// SPDX-License-Identifier: GPL-2.0-or-later
#include <chrono>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

static std::string documentName = "start", documentError, documentNext;
static std::string saveTemporary, saveDestination;
static int saveRevision;
static bool savingDocument, savingBackup, confirmDocument;
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
  else if (!next.empty())
    action(("mapedit maps/" + next + ".map\n").c_str());
}
static bool documentSave(const std::string& name, bool backup = false)
{
  if (savingDocument || !safeName(name.c_str()))
    return false;
  documentError.clear();
  const auto serial = std::chrono::system_clock::now().time_since_epoch().count();
  saveTemporary =
    "_ftebroom_save_" + std::to_string(serial) + "_" + std::to_string(++saveSerial);
  saveDestination = "maps/" + name + ".map";
  if (backup)
  {
    int slot = 0;
    auto oldest = std::filesystem::file_time_type::max();
    for (int i = 0; i < 50; ++i)
    {
      const auto path =
        documentPath("autosave/" + name + "-" + std::to_string(i) + ".map");
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
    saveDestination = "autosave/" + name + "-" + std::to_string(slot) + ".map";
  }
  if (documentPath("maps/" + saveTemporary + ".map").empty())
  {
    documentError = "Cannot locate the writable editor directory.";
    return false;
  }
  saveRevision = (int)cvars->GetFloat("ftebroom_revision");
  savingDocument = true;
  savingBackup = backup;
  action(("mod_terrain_save \"\" " + saveTemporary + "\nftebroom_save_finish\n").c_str());
  return true;
}
static void documentSaveFinished()
{
  if (!savingDocument)
    return;
  savingDocument = false;
  const auto source = documentPath("maps/" + saveTemporary + ".map");
  const auto target = documentPath(saveDestination);
  try
  {
    if (
      source.empty() || target.empty() || !std::filesystem::exists(source)
      || std::filesystem::file_size(source) == 0)
      throw std::runtime_error("The engine did not write the map.");
    std::filesystem::create_directories(target.parent_path());
#ifdef _WIN32
    if (!MoveFileExW(
          source.c_str(),
          target.c_str(),
          MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
      throw std::runtime_error("Cannot replace the destination file.");
#else
    std::filesystem::rename(source, target);
#endif
    core->Print(("FTEBROOM_SAVED " + saveDestination + "\n").c_str());
    if (!savingBackup)
    {
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
  if (next != "exit" && next != "__new")
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
  if (ImGui::BeginPopupModal("Save changes?", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
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
  if (!documentError.empty())
  {
    ImGui::OpenPopup("Document error");
    if (
      ImGui::BeginPopupModal(
        "Document error", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
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
