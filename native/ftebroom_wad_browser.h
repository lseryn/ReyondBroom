// SPDX-License-Identifier: GPL-2.0-or-later
#include <mutex>
// WAD folders expose read-only texture images; writes still use the WAD importer.
static std::mutex wadBrowseMutex;
static std::filesystem::path wadBrowseCache;
static std::filesystem::file_time_type wadBrowseStamp;
static std::vector<ftebroom::quake1::Texture> wadBrowseTextures;
static std::string wadBrowsePalette;
static bool wadBrowseSplit(const std::filesystem::path& path,std::filesystem::path& wad,std::string& member) {
  for(auto p=path;!p.empty();p=p.parent_path()) {
    if(entityLower(p.extension().u8string())==".wad") {wad=p;member=path==p?"":path.lexically_relative(p).generic_u8string();return true;}
    if(p==p.parent_path())break;
  }return false;
}
static bool wadBrowseMember(const std::filesystem::path& path){std::filesystem::path wad;std::string member;return wadBrowseSplit(path,wad,member)&&!member.empty();}
static bool wadBrowseFolder(const std::filesystem::path& path){return entityLower(path.extension().u8string())==".wad";}
static void wadBrowseLoad(const std::filesystem::path& wad) {
  std::filesystem::path archive;std::string member;auto disk=ftebroom::pak::split(wad,archive,member)?archive:wad;
  auto stamp=std::filesystem::last_write_time(disk);
  if(wadBrowseCache==wad&&wadBrowseStamp==stamp)return;
  auto textures=ftebroom::quake1::wad(q1Read(wad));
  wadBrowseTextures=std::move(textures);wadBrowseCache=wad;wadBrowseStamp=stamp;
}
static std::vector<std::pair<bool,std::filesystem::path>> wadBrowseList(const std::filesystem::path& wad) {
  std::lock_guard<std::mutex> lock(wadBrowseMutex);wadBrowseLoad(wad);
  size_t size=0;auto palette=(char*)files->LoadFile("gfx/palette.lmp",&size);
  if(palette&&size==768)wadBrowsePalette.assign(palette,size);else {wadBrowsePalette.resize(768);for(int i=0;i<256;i++)for(int c=0;c<3;c++)wadBrowsePalette[i*3+c]=char(i);}
  if(palette)core->Free(palette);
  std::vector<std::pair<bool,std::filesystem::path>> result;
  for(const auto& texture:wadBrowseTextures)result.push_back({false,wad/(texture.name+".tga")});return result;
}
static std::string wadBrowseRead(const std::filesystem::path& path) {
  std::filesystem::path wad;std::string member;if(!wadBrowseSplit(path,wad,member)||member.empty())throw std::runtime_error("Choose a WAD texture.");
  std::lock_guard<std::mutex> lock(wadBrowseMutex);wadBrowseLoad(wad);
  for(const auto& texture:wadBrowseTextures)if(member==texture.name+".tga")return ftebroom::quake1::tga(texture,wadBrowsePalette);
  throw std::runtime_error("WAD texture no longer exists.");
}
