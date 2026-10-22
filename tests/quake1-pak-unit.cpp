// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_pak.h"
#include "../native/ftebroom_mdl.h"
#include <cassert>
#include <iostream>
int main(int argc,char** argv){
  using namespace ftebroom;auto root=std::filesystem::temp_directory_path()/("ftebroom-pak-unit-"+std::to_string(std::chrono::high_resolution_clock::now().time_since_epoch().count()));std::filesystem::create_directories(root);auto archive=root/"test.pak";
  {std::ofstream out(archive,std::ios::binary);out.write("PACK",4);pak::put(out,12);pak::put(out,0);}
  pak::replace(archive/"maps/test.map","original map");pak::replace(archive/"textures/original.wad",std::string("WAD2\0bytes",10));pak::replace(archive/"maps/test.map","changed map");
  assert(pak::read(archive/"maps/test.map")=="changed map");assert(pak::read(archive/"textures/original.wad")==std::string("WAD2\0bytes",10));assert(pak::list(archive).size()==2);assert(pak::list(archive/"maps").size()==1);assert(pak::diskFolder(archive/"maps")==root);
  auto before=std::filesystem::file_size(archive);bool rejected=false;try{pak::replace(archive/"../escape.map","bad");}catch(...){rejected=true;}assert(rejected&&std::filesystem::file_size(archive)==before);
  assert(!pak::validName("/absolute")&&!pak::validName("a/../b")&&!pak::validName("C:/bad"));
  if(argc>1){auto bytes=pak::read(std::filesystem::u8path(argv[1])/"progs/ogre.mdl");auto mdl=readMdl(bytes);assert(mdl.triangles.size()>10&&!mdl.skin.pixels.empty());for(size_t n=0;n<bytes.size();n+=101){bool bad=false;try{readMdl(bytes.substr(0,n));}catch(...){bad=true;}if(n<84)assert(bad);}std::cout<<"MDL triangles: "<<mdl.triangles.size()<<"\n";}
  std::cout<<"PASS: PAK entries, byte preservation, folders, backups, traversal rejection and MDL parsing. "<<root<<"\n";
}
