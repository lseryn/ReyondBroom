// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_wall_file.h"
#include <cassert>
#include <iostream>
int main(int argc,char** argv){
 assert(argc==2);auto root=std::filesystem::u8path(argv[1]);std::filesystem::create_directories(root);
 auto check=[&](const char* name,const std::string& bytes,bool accept){auto path=root/name;{std::ofstream f(path,std::ios::binary);f.write(bytes.data(),bytes.size());}bool ok=false;try{ok=gameWallReadFile(path)==bytes;}catch(const std::exception&){}assert(ok==accept);};
 check("valid.GLSL","!!ver 100 150\nvoid main(){}",true);check("empty.glsl","",false);check("binary.glsl",std::string("a\0b",3),false);check("wrong.txt","shader",false);check("maximum.glsl",std::string(1024*1024,'a'),true);check("large.glsl",std::string(1024*1024+1,'a'),false);
 bool missing=false;try{gameWallReadFile(root/"absent.glsl");}catch(const std::exception&){missing=true;}assert(missing);
 std::cout<<"PASS: GLSL file validation, exact byte preservation and size boundaries\n";
}
