// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_pak.h"
#include <cassert>
#include <iostream>
int main(int argc,char** argv){
  assert(argc==2);namespace fs=std::filesystem;namespace pak=ftebroom::pak;fs::path root=fs::u8path(argv[1]),archive=root/"test.pk3";
  assert(pak::read(archive/"texts/readme.txt")=="deflated text\n");
  assert(pak::read(archive/"empty.txt").empty());
  auto listed=pak::list(archive);assert(listed.size()==3);
  pak::replace(archive/"texts/readme.txt","edited");pak::replace(archive/"new/sub/data.txt","added");
  assert(pak::read(archive/"texts/readme.txt")=="edited");assert(pak::read(archive/"stored.bin")==std::string("\0\1\2",3));
  pak::rename(archive/"new",archive/"renamed");assert(pak::read(archive/"renamed/sub/data.txt")=="added");
  bool refused=false;try{pak::replace(archive/"../escape.txt","bad");}catch(...){refused=true;}assert(refused&&!fs::exists(root/"escape.txt"));
  pak::erase(archive/"texts/readme.txt");assert(!pak::exists(archive/"texts/readme.txt"));assert(pak::read(archive/"renamed/sub/data.txt")=="added");
  int backups=0;for(const auto& e:fs::directory_iterator(root))if(e.path().extension()==".bak")backups++;assert(backups==4);
  std::cout<<"PASS: PK3 stored/deflate/empty reads, list, replacement, insertion, folder rename, delete, backups and traversal rejection\n";
}
