// SPDX-License-Identifier: GPL-2.0-or-later
// Keep the editor VM alive while the actual mod runs in a separate process.
#include "ftebroom_embed.h"
static std::string modQuote(const std::string& text)
{
  if(text.find_first_of("\"\r\n")!=std::string::npos)throw std::runtime_error("A profile path contains a quote or newline.");
  return "\""+text+"\"";
}
static void modValidate()
{
  auto mod=std::filesystem::u8path(gameMod);
  if(!std::filesystem::is_regular_file(documentPath("ftebroom.cfg").parent_path().parent_path()/"fteqw64.exe"))throw std::runtime_error("The bundled preview engine fteqw64.exe is missing.");
  if(!std::filesystem::is_directory(mod) || !std::filesystem::is_regular_file(mod/"progs.dat"))throw std::runtime_error("The runtime mod directory must contain progs.dat.");
  auto name=mod.filename().u8string();
  if(name.empty() || name.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")!=std::string::npos)
    throw std::runtime_error("The runtime mod folder name must contain only letters, digits, _ or -.");
}
static void modPreview()
{
  if(runActive || buildRunning)return;
  try {
    modValidate();
    if(buildResult.empty() || buildResultDocument!=documentFile)throw std::runtime_error("Build this map before opening the mod preview.");
    auto name=documentFile.stem().u8string();
    if(name.empty() || name.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")!=std::string::npos)
      throw std::runtime_error("For mod preview, save the map with a name containing letters, digits, _ or -.");
    auto mod=std::filesystem::absolute(std::filesystem::u8path(gameMod)).lexically_normal();
    auto root=buildResult.parent_path()/"mod-preview";
    auto home=root/"home", maps=home/mod.filename()/"maps";
    std::filesystem::create_directories(maps);
    // Preserve generated external lightmap names while retaining the real map name.
    for(const auto& file:std::filesystem::directory_iterator(buildResult.parent_path())) {
      auto ext=file.path().extension();
      if(file.path()==root || ext==".map" || ext==".log" || ext==".prt")continue;
      std::filesystem::copy(file.path(),maps/file.path().filename(),std::filesystem::copy_options::overwrite_existing|std::filesystem::copy_options::recursive);
    }
    std::filesystem::copy_file(buildResult,maps/(name+".bsp"),std::filesystem::copy_options::overwrite_existing);
    if(cvars->GetFloat("ftebroom_bsp_preview"))buildEdit();
    modEmbedBegin();
    auto embeddedEngine=documentPath("ftebroom.cfg").parent_path().parent_path()/"fteqw64.exe";
    std::string args="-plugin -ftebroom-preview -noupdates -quake -basedir "+modQuote(mod.parent_path().generic_u8string())+" -game "+modQuote(mod.filename().u8string())+
      " -homedir "+modQuote(home.generic_u8string())+" -usehome -readonly -window -width 1280 -height 800 +set sv_public 0 +set deathmatch 0 +set coop 0 +set sv_nopvs 0 +set r_drawviewmodel 0 +set cl_idlefps 60 +set cl_maxfps 60 +set vid_wait 0 +map "+name;
    if(cvars->GetFloat("ftebroom_skip_setup"))args+=" +set ftebroom_preview_trace 1";
    RunProfile preview{"When the sky went dark: mod preview",root.u8string(),true,{{1,embeddedEngine.u8string(),args}}};
    runBegin(preview);runWindow=false;
    if(!runActive){modEmbedEnd();throw std::runtime_error(runError);}
    buildMessage="Choose Free camera to inspect, or Play mod to control the player.";
  }catch(const std::exception& error){modEmbedEnd();buildMessage=error.what();}
}
