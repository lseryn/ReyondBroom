// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_model_export.h"
#include "../native/ftebroom_md3.h"
#include "../native/ftebroom_mdl.h"
#include "../native/ftebroom_model_mdl_export.h"
#include <cassert>
#include <iostream>
int main() {
  const std::string frame="\"textures/test\" 3 1\n0 0 0 0 0 1 0 0\n16 0 0 0 0 1 1 0\n0 16 0 0 0 1 0 1\n0 1 2\n";
  auto mesh=ftebroom::modelExport::parse("FTEBROOM_MESH 1 2 1\n"+frame+frame);
  auto bytes=ftebroom::modelExport::md3(mesh);auto decoded=ftebroom::readMd3(bytes);
  assert(decoded.size()==1&&decoded[0].triangles.size()==1);
  assert(decoded[0].triangles[0][1].point[0]==16&&decoded[0].shader=="textures/test");
  assert(ftebroom::quake1::word(bytes,76)==2&&ftebroom::quake1::word(bytes,104)==bytes.size());
  auto obj=ftebroom::modelExport::obj(mesh);assert(obj.find("f 1/1/1 2/2/2 3/3/3")!=obj.npos);
  std::string palette(768,0);palette[3]=char(255);
  ftebroom::modelExport::Skin skin;skin.width=skin.height=2;skin.rgba={255,0,0,255,255,0,0,255,255,0,0,255,255,0,0,255};
  for(auto& f:mesh.surfaces[0].frames)for(auto& v:f){v.position[0]+=100;v.position[1]-=27;v.position[2]+=12;}
  mesh.surfaces[0].frames[1][1].position[0]+=8;
  auto mdlBytes=ftebroom::modelExport::mdl(mesh,{skin},palette);auto mdl=ftebroom::readMdl(mdlBytes);
  assert(mdl.skin.pixels[0]==1&&mdl.triangles.size()==1);
  assert(std::abs(mdl.triangles[0][0].point[0]-100)<.1f&&std::abs(mdl.triangles[0][1].point[0]-116)<.1f);
  assert(mdl.triangles[0][0].point[1]==-27&&mdl.triangles[0][0].point[2]==12);
  assert(ftebroom::quake1::word(mdlBytes,68)==2);
  bool noPalette=false;try{ftebroom::modelExport::mdl(mesh,{skin},"");}catch(...){noPalette=true;}assert(noPalette);
  bool rejected=false;try{ftebroom::modelExport::parse("FTEBROOM_MESH 1 2 1\n"+frame);}catch(...){rejected=true;}assert(rejected);
  mesh.surfaces[0].frames[0][0].position[0]=600;rejected=false;try{ftebroom::modelExport::md3(mesh);}catch(...){rejected=true;}assert(rejected);
  std::cout<<"PASS: animated MD3 roundtrip, material/UV/topology and invalid-input guards\n";
}
