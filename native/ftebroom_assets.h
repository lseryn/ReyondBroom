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
  int tags = 0;
};
static std::map<std::string, MaterialEntry> materials;
static std::set<std::string> resourceFiles, resourceDirs;
static int shaderFiles = 0;
static std::string selectedMaterial;
static void resetMaterialBrowser();
static void publishMaterialTags();
static std::filesystem::path settingsPath()
{
  char path[4096] = {};
  if (!files->NativePath("ftebroom-project.txt", (fs_relative)2, path, sizeof path))
    return {};
  return std::filesystem::u8path(path);
}
#include "ftebroom_game_profile.h"
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
      int depth = 1, tags = 0;
      std::string preview, stagePreview;
      while (depth && offset < source.size())
      {
        auto word = token(source, offset);
        std::transform(word.begin(),word.end(),word.begin(),[](unsigned char c){return char(std::tolower(c));});
        if (word == "{")
          ++depth;
        else if (word == "}")
          --depth;
        else if (depth == 1 && word == "qer_editorimage")
          preview = token(source, offset);
        else if(depth == 1 && word == "qer_trans") {
          auto opacity=token(source,offset);char* end=nullptr;
          float alpha=std::strtof(opacity.c_str(),&end);
          if(end!=opacity.c_str() && alpha<1)tags|=64;
        }
        else if(depth == 2 && (word == "map" || word == "clampmap")) {
          auto image=token(source,offset);
          if(stagePreview.empty() && !image.empty() && image[0]!='$')stagePreview=image;
        }
        else if (depth == 1 && word == "surfaceparm")
        {
          auto parm = token(source, offset);
          if (parm == "water" || parm == "lava" || parm == "slime")
            tags |= 32;
          if (parm == "trans" || parm == "fog")
            tags |= 64;
          if (parm == "areaportal")
            tags |= 128;
          if (parm == "clusterportal")
            tags |= 256;
          if (parm == "sky")tags |= 512;
        }
      }
      if (!depth)
        materials[name] = {name, preview.empty()?stagePreview:preview, true, tags};
    }
  }
  publishMaterialTags();
  command("ftebroom_definitions\n");
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
    settings.close();
    if(!settings)throw std::runtime_error("Cannot save the resource configuration.");
    std::snprintf(baseq3,sizeof baseq3,"%s",normalized.c_str());
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
    setupNeeded = false;
    if(!saved.empty()) { if(!mountAssets())setupNeeded=cvars->GetFloat("ftebroom_skip_setup")==0; }
    else setupNeeded=cvars->GetFloat("ftebroom_skip_setup")==0;
  }
  if(uiClosedDialog=="Game / resources"){setupNeeded=false;uiClosedDialog.clear();}
  if (setupNeeded)
    ImGui::OpenPopup("Game / resources");

  if (uiDialog("Game / resources", {800, 550}))
  {
    gameProfileFields();
    ImGui::TextUnformatted("Map format: Quake 3 (Valve 220)");
    ImGui::SetNextItemWidth(420);
    ImGui::InputText("baseq3 folder", baseq3, sizeof baseq3);
    ImGui::TextWrapped(
      "Paste the full path to baseq3. PK3 archives and loose textures/scripts are read "
      "without modifying your game. Use Save As to choose the map directory.");
    if (!assetError.empty())
      ImGui::TextWrapped("%s", assetError.c_str());
    ImGui::BeginDisabled(assetsLoading||gameProfileLocked);
    if (ImGui::Button("Load resources and start") && gameProfileSave() && mountAssets())
      {command("ftebroom_definitions\n");ImGui::CloseCurrentPopup();}
    ImGui::EndDisabled();
    if (assetsLoading)
      ImGui::TextUnformatted("Loading resources...");
    ImGui::EndPopup();
  }
}

#include "ftebroom_materials.h"
