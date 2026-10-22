// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_quake1.h"
static std::map<std::string,std::string> q1MaterialWad;
static std::vector<qhandle_t> q1ShaderHandles;
static std::string q1Read(const std::filesystem::path& path) {
  std::ifstream input(path,std::ios::binary);
  if(!input)throw std::runtime_error("Cannot read "+path.u8string());
  if(std::filesystem::file_size(path)>512*1024*1024)throw std::runtime_error("Resource exceeds 512 MiB.");
  return {std::istreambuf_iterator<char>(input),{}};
}
static std::vector<std::filesystem::path> q1WadPaths() {
  std::istringstream input(q1Wads);std::string line;std::vector<std::filesystem::path> result;
  while(std::getline(input,line)){if(!line.empty()&&line.back()=='\r')line.pop_back();if(line.empty())continue;
    auto path=std::filesystem::u8path(line);if(path.is_relative())path=std::filesystem::u8path(q1Root)/path;
    result.push_back(std::filesystem::absolute(path).lexically_normal());}
  char builtin[4096]={};if(files->NativePath("quake1-editor.wad",(fs_relative)5,builtin,sizeof builtin)&&std::filesystem::is_regular_file(std::filesystem::u8path(builtin)))result.insert(result.begin(),std::filesystem::u8path(builtin));
  return result;
}
static std::string q1WadList() {
  std::string list;for(auto& path:q1WadPaths()){auto name=path.generic_u8string();
    if(name.find_first_of(";\"\r\n")!=std::string::npos)throw std::runtime_error("WAD path contains a separator or quote.");
    if(!list.empty())list+=';';list+=name;}
  return list;
}
static bool q1DiscoverWads(const std::string& source,const std::filesystem::path& map) {
  if(*q1Wads)return false;
  std::istringstream input(source);std::string line,list;
  while(std::getline(input,line)) {
    auto at=line.find_first_not_of(" \t");if(at==std::string::npos||line.compare(at,5,"\"wad\""))continue;
    auto start=line.find('"',at+5),end=line.rfind('"');if(start==std::string::npos||end<=start)continue;
    auto raw=line.substr(start+1,end-start-1);std::replace(raw.begin(),raw.end(),'\\','/');
    std::istringstream entries(raw);std::string entry;
    while(std::getline(entries,entry,';')){if(entry.empty())continue;auto path=std::filesystem::u8path(entry);
      if(path.is_relative())path=map.parent_path()/path;
      if(!std::filesystem::is_regular_file(path))path=std::filesystem::u8path(q1Root)/path.filename();
      if(!std::filesystem::is_regular_file(path))path=std::filesystem::u8path(q1Root)/"textures"/path.filename();
      if(std::filesystem::is_regular_file(path))list+=path.generic_u8string()+"\n";
    }break;
  }
  if(list.empty())return false;
  if(list.size()>=sizeof q1Wads)throw std::runtime_error("Map WAD list is too long.");
  std::snprintf(q1Wads,sizeof q1Wads,"%s",list.c_str());return true;
}
static void q1IndexAssets() {
  for(auto handle:q1ShaderHandles)draw->UnloadImage(handle);q1ShaderHandles.clear();q1MaterialWad.clear();
  size_t size=0;auto data=(char*)files->LoadFile("gfx/palette.lmp",&size);
  if(!data)throw std::runtime_error("Quake gfx/palette.lmp was not found. Select the id1 folder containing PAK files.");
  std::string palette(data,size);core->Free(data);
  if(palette.size()!=768)throw std::runtime_error("Invalid Quake palette.lmp.");
  std::map<std::string,ftebroom::quake1::Texture> textures;
  for(const auto& path:q1WadPaths())for(auto& tex:ftebroom::quake1::wad(q1Read(path))){q1MaterialWad[tex.name]=path.filename().u8string();textures[tex.name]=std::move(tex);}
  char writable[4096]={};if(!files->NativePath("ftebroom.cfg",(fs_relative)5,writable,sizeof writable))throw std::runtime_error("No writable editor cache.");
  auto editor=std::filesystem::u8path(writable).parent_path();
  auto cache=editor/"textures/_ftebroom_q1";std::filesystem::create_directories(cache);
  std::filesystem::create_directories(editor/"scripts");
  std::ofstream shaderFile(editor/"scripts/ftebroom-quake1.shader");
  static unsigned generation=0;generation++;
  for(const auto& pair:textures) {
    const auto& t=pair.second;std::ostringstream encoded;encoded<<generation<<'-';for(unsigned char c:t.name)encoded<<std::hex<<std::setw(2)<<std::setfill('0')<<int(c);
    auto image="textures/_ftebroom_q1/"+encoded.str()+".tga";
    auto bytes=ftebroom::quake1::tga(t,palette);std::ofstream out(cache/(encoded.str()+".tga"),std::ios::binary);out.write(bytes.data(),bytes.size());out.close();if(!out)throw std::runtime_error("Cannot write Quake texture cache.");
    int tags=t.name[0]=='*'?32:0;if(t.name.rfind("sky",0)==0)tags|=512;
    auto material="textures/"+t.name;
    auto script="{\n{\nmap "+image+"\nrgbgen vertex\nalphagen vertex\n}\n}";
    shaderFile<<material<<"\n"<<script<<"\n";
    materials[material]={material,image,false,tags};
  }
  shaderFile.close();command("fs_restart\nftebroom_reload_palette\n");
  if(!textures.empty())cvars->SetString("ca_newbrushtexture",textures.begin()->first.c_str());
  for(const char* name:{"clip","skip","hint","trigger"}){
    auto material=std::string("textures/")+name;
    if(!materials.count(material))materials[material]={material,"textures/ftebroom/default",false,0};
  }
}
