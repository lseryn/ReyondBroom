// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_mod_definitions.h"
#include <cassert>
#include <cstring>
#include <iostream>
int main(int argc,char** argv){
  assert(argc==2);namespace fs=std::filesystem;auto root=fs::u8path(argv[1]);fs::create_directories(root/"examples");
  std::ofstream(root/"examples/other.fgd")<<"@PointClass = other []";
  std::ofstream(root/"mod.fgd")<<"@PointClass = custom []";
  assert(ftebroom::discoverModDefinitions(root)==(root/"mod.fgd").u8string());
  auto packed=root/"packed";fs::create_directories(packed);auto archive=packed/"pak0.pak";
  std::string source="/*QUAKED custom (1 1 1) (-8 -8 -8) (8 8 8) */";
  std::ofstream out(archive,std::ios::binary);out.write("PACK",4);ftebroom::pak::put(out,12+source.size());ftebroom::pak::put(out,64);out<<source;char name[56]={};std::strcpy(name,"defs/mod.def");out.write(name,56);ftebroom::pak::put(out,12);ftebroom::pak::put(out,source.size());out.close();
  auto found=ftebroom::discoverModDefinitions(packed);assert(found==(archive/"defs/mod.def").u8string());assert(ftebroom::pak::read(fs::u8path(found))==source);
  assert(ftebroom::discoverModDefinitions(root/"missing").empty());
  std::cout<<"PASS: loose definitions, packed definitions and fallback\n";
}
