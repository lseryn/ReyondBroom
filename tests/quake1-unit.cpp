// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_quake1.h"
#include "../native/ftebroom_entity_defs.h"
#include <cassert>
#include <fstream>
#include <iostream>
using namespace ftebroom::quake1;
int main(int argc,char** argv) {
  std::string faceLine="( 0 0 0 ) ( 0 64 0 ) ( 64 64 0 ) stone [ 2 0 0 3 ] [ 0 -4 0 5 ] 0 1 1 1 2 3";
  assert(face(faceLine,false).find("1 2 3")==std::string::npos);
  auto standard=face(faceLine,true);assert(standard.find("3 5 0 0.5 0.25")!=std::string::npos);
  auto shear=faceLine;shear.replace(shear.find("0 -4 0"),6,"1 -4 0");bool rejected=false;
  try{face(shear,true);}catch(...){rejected=true;}assert(rejected);
  rejected=false;try{map("{\npatchDef2\n}",false,"");}catch(...){rejected=true;}assert(rejected);
  auto output=map("{\n\"classname\" \"worldspawn\"\n\"wad\" \"old.wad\"\n}\n",false,"C:/test/my textures.wad");
  assert(output.find("old.wad")==std::string::npos&&output.find("my textures.wad")!=std::string::npos);
  std::string header(184,0);header.replace(0,4,"IBSP");header[4]=46;header[8+7*8]=char(144);header[12+7*8]=40;
  assert(bsp(header,false)&&!bsp(header,true));header[12+7*8]=0;assert(!bsp(header,false));
  header.assign(188,0);header[0]=29;header[4+14*8]=124;header[8+14*8]=64;assert(bsp(header,true));header[4]=127;header[8]=127;assert(!bsp(header,true));
  Texture t{"stone",1,1,{1}};std::string palette(768,0);palette[3]=10;palette[4]=20;palette[5]=30;auto image=tga(t,palette);
  assert(image.size()==21&&image[18]==30&&image[19]==20&&image[20]==10);
  std::ifstream defs("runtime/quake1.ent");std::string def((std::istreambuf_iterator<char>(defs)),{});
  auto entities=ftebroom::entityRead(def,".ent");assert(entities.count("monster_ogre")&&entities.at("func_door").brush);
  assert(entities.at("monster_ogre").model=="progs/ogre.mdl");
  if(argc>1){std::ifstream file(argv[1],std::ios::binary);std::string bytes((std::istreambuf_iterator<char>(file)),{});auto textures=wad(bytes);assert(textures.size()==1&&textures[0].width==64);
    for(size_t size=0;size<bytes.size();size+=31){rejected=false;try{wad(bytes.substr(0,size));}catch(...){rejected=true;}assert(rejected);}}
  std::cout<<"PASS: Quake BSP versions, malformed offsets, WAD bounds, palette, UV preservation, patch rejection, entity definitions.\n";
}
