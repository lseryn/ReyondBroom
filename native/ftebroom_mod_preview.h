// SPDX-License-Identifier: GPL-2.0-or-later
// Keep the editor VM alive while the actual mod runs in a separate process.
static std::string modQuote(const std::string& text)
{
  if(text.find_first_of("\"\r\n")!=std::string::npos)throw std::runtime_error("A profile path contains a quote or newline.");
  return "\""+text+"\"";
}
static void modValidate()
{
  auto mod=std::filesystem::u8path(gameMod);
  if(!std::filesystem::is_regular_file(std::filesystem::u8path(gameEngine)))throw std::runtime_error("Choose an existing runtime FTE executable in Game / resources.");
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
    std::string args="-quake -basedir "+modQuote(mod.parent_path().generic_u8string())+" -game "+modQuote(mod.filename().u8string())+
      " -homedir "+modQuote(home.generic_u8string())+" -usehome -readonly -window -width 1280 -height 800 +set sv_public 0 +set deathmatch 0 +set coop 0 +map "+name;
    RunProfile preview{"When the sky went dark: mod preview",root.u8string(),true,{{1,gameEngine,args}}};
    runBegin(preview);
    buildMessage="Mod preview runs in a separate window. Close it to return, or use Stop in the run log. The installed mod and source map are not overwritten.";
  }catch(const std::exception& error){buildMessage=error.what();}
}
