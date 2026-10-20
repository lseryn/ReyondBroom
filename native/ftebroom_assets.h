// SPDX-License-Identifier: GPL-2.0-or-later
// Resource discovery uses FTE's mounted filesystem, including PK3 precedence.
#include <cctype>
#include <filesystem>
#include <fstream>
#include <map>
#include <set>

static plugfsfuncs_t* files;
static char baseq3[1024] = "";
static bool setupNeeded = true, setupInitialized = false, assetsLoading = false;
static std::string assetError;
struct MaterialEntry
{
  std::string name, preview;
  bool shader = false;
};
static std::map<std::string, MaterialEntry> materials;
static std::set<std::string> resourceFiles, resourceDirs;
static int shaderFiles = 0;
static std::string selectedMaterial;
static void resetMaterialBrowser();
static std::filesystem::path settingsPath()
{
  char path[4096] = {};
  if (!files->NativePath("ftebroom-project.txt", (fs_relative)2, path, sizeof path))
    return {};
  return std::filesystem::u8path(path);
}
static std::string token(const std::string& source, size_t& i)
{
  for (;;)
  {
    while (i < source.size() && std::isspace((unsigned char)source[i]))
      ++i;
    if (source.compare(i, 2, "//") == 0)
    {
      while (i < source.size() && source[i] != '\n')
        ++i;
    }
    else if (source.compare(i, 2, "/*") == 0)
    {
      auto end = source.find("*/", i + 2);
      i = end == std::string::npos ? source.size() : end + 2;
    }
    else
      break;
  }
  if (i == source.size())
    return {};
  if (source[i] == '{' || source[i] == '}')
    return source.substr(i++, 1);
  if (source[i] == '"')
  {
    size_t start = ++i;
    while (i < source.size() && source[i] != '"')
      ++i;
    auto result = source.substr(start, i - start);
    if (i < source.size())
      ++i;
    return result;
  }
  size_t start = i;
  while (i < source.size() && !std::isspace((unsigned char)source[i]) && source[i] != '{'
         && source[i] != '}')
    ++i;
  return source.substr(start, i - start);
}
static int QDECL
collectResource(const char* name, qofs_t, time_t, void*, searchpathfuncs_s*)
{
  std::string path = name;
  if (path.empty())
    return 1;
  if (path.back() == '/')
    resourceDirs.insert(path);
  else
    resourceFiles.insert(path);
  return 1;
}
static void scanDirectory(const std::string& path)
{
  files->EnumerateFiles((fs_relative)4, (path + "*").c_str(), collectResource, nullptr);
}
static void assetsReady()
{
  resetMaterialBrowser();
  materials.clear();
  resourceFiles.clear();
  resourceDirs.clear();
  shaderFiles = 0;
  scanDirectory("textures/");
  scanDirectory("scripts/");
  // ZIPs need not contain directory records. Match each depth explicitly too.
  std::string nested = "textures/";
  for (int depth = 0; depth < 32; ++depth)
  {
    nested += "*/";
    scanDirectory(nested);
  }
  std::set<std::string> visited;
  while (visited.size() < resourceDirs.size())
  {
    auto pending = resourceDirs;
    for (auto& dir : pending)
      if (visited.insert(dir).second && std::count(dir.begin(), dir.end(), '/') < 32)
        scanDirectory(dir);
  }
  for (auto& path : resourceFiles)
  {
    auto dot = path.find_last_of('.');
    if (dot == std::string::npos)
      continue;
    auto ext = path.substr(dot);
    std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) {
      return char(std::tolower(c));
    });
    if (
      path.rfind("textures/", 0) == 0
      && (ext == ".tga" || ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".dds"))
    {
      if (path == "textures/ftebroom/overlay.tga")
        continue;
      auto name = path.substr(0, dot);
      materials[name] = {name, path, false};
    }
  }
  for (auto& path : resourceFiles)
  {
    if (path.size() < 7 || path.substr(path.size() - 7) != ".shader")
      continue;
    size_t size = 0;
    auto data = (char*)files->LoadFile(path.c_str(), &size);
    if (!data)
      continue;
    std::string source(data, size);
    core->Free(data);
    ++shaderFiles;
    size_t offset = 0;
    for (;;)
    {
      auto name = token(source, offset);
      if (name.empty())
        break;
      if (token(source, offset) != "{")
        continue;
      int depth = 1;
      std::string preview;
      while (depth && offset < source.size())
      {
        auto word = token(source, offset);
        if (word == "{")
          ++depth;
        else if (word == "}")
          --depth;
        else if (depth == 1 && word == "qer_editorimage")
          preview = token(source, offset);
      }
      if (!depth)
        materials[name] = {name, preview, true};
    }
  }
  assetsLoading = false;
  setupNeeded = false;
  cvars->SetFloat("ftebroom_material_count", float(materials.size()));
  cvars->SetFloat("ftebroom_shader_file_count", float(shaderFiles));
  core->Print(("FTEBroom: indexed " + std::to_string(materials.size())
               + " materials from " + std::to_string(shaderFiles) + " shader files.\n")
                .c_str());
  if (cvars->GetFloat("ftebroom_skip_setup"))
    for (auto& pair : materials)
      core->Print(("FTEBroom material: " + pair.first + "\n").c_str());
}
static bool mountAssets()
{
  assetError.clear();
  try
  {
    auto path = std::filesystem::weakly_canonical(std::filesystem::u8path(baseq3));
    if (!*baseq3 || !std::filesystem::is_directory(path))
      throw std::runtime_error("Choose an existing baseq3 folder.");
    bool hasAssets = std::filesystem::is_directory(path / "textures")
                     || std::filesystem::is_directory(path / "scripts");
    for (auto& entry : std::filesystem::directory_iterator(path))
    {
      auto ext = entry.path().extension().string();
      std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) {
        return char(std::tolower(c));
      });
      if (ext == ".pk3")
        hasAssets = true;
    }
    if (!hasAssets)
      throw std::runtime_error(
        "No PK3 archives, textures or scripts were found in this folder.");
    auto normalized = path.generic_u8string();
    cvars->SetString("ftebroom_assetpath", normalized.c_str());
    std::ofstream settings(settingsPath(), std::ios::binary);
    settings << normalized;
    assetsLoading = true;
    command("fs_restart\nftebroom_assets_ready\n");
    return true;
  }
  catch (const std::exception& e)
  {
    assetError = e.what();
    return false;
  }
}
static void loadProjectCommand()
{
  if (commands->IsInsecure())
    return;
  commands->Argv(1, baseq3, sizeof baseq3);
  if (!mountAssets())
    core->Print(("FTEBroom: " + assetError + "\n").c_str());
}
static void projectSetup()
{
  if (!setupInitialized)
  {
    setupInitialized = true;
    std::ifstream settings(settingsPath(), std::ios::binary);
    std::string saved;
    std::getline(settings, saved);
    std::snprintf(baseq3, sizeof baseq3, "%s", saved.c_str());
    setupNeeded = cvars->GetFloat("ftebroom_skip_setup") == 0;
  }
  if (setupNeeded)
    ImGui::OpenPopup("New Quake 3 project");
  ImGui::SetNextWindowSize({550, 0}, ImGuiCond_Appearing);
  if (
    ImGui::BeginPopupModal(
      "New Quake 3 project", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
  {
    int game = 0;
    ImGui::Combo("Game", &game, "Quake III Arena\0");
    ImGui::TextUnformatted("Map format: Quake 3 (Valve 220)");
    ImGui::SetNextItemWidth(420);
    ImGui::InputText("baseq3 folder", baseq3, sizeof baseq3);
    ImGui::TextWrapped(
      "Paste the full path to baseq3. PK3 archives and loose textures/scripts are read "
      "without modifying your game. Maps are saved in the editor's ftebroom/maps "
      "folder.");
    if (!assetError.empty())
      ImGui::TextWrapped("%s", assetError.c_str());
    ImGui::BeginDisabled(assetsLoading);
    if (ImGui::Button("Load resources and start") && mountAssets())
      ImGui::CloseCurrentPopup();
    ImGui::EndDisabled();
    if (assetsLoading)
      ImGui::TextUnformatted("Loading resources...");
    ImGui::EndPopup();
  }
}

#include "ftebroom_materials.h"
