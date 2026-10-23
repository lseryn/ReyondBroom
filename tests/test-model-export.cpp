// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_model_export.h"
#include "../native/ftebroom_md3.h"
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
  bool rejected=false;try{ftebroom::modelExport::parse("FTEBROOM_MESH 1 2 1\n"+frame);}catch(...){rejected=true;}assert(rejected);
  mesh.surfaces[0].frames[0][0].position[0]=600;rejected=false;try{ftebroom::modelExport::md3(mesh);}catch(...){rejected=true;}assert(rejected);
  std::cout<<"PASS: animated MD3 roundtrip, material/UV/topology and invalid-input guards\n";
}
