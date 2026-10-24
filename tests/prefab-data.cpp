// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_prefab_data.h"
#include <cassert>
#include <fstream>
#include <iostream>
using namespace ftebroom::prefab;
int main(int argc,char** argv){
  assert(argc==2||argc==3);std::ifstream input(argv[1]);std::string bytes(std::istreambuf_iterator<char>(input),{});
  auto collection=parse(bytes);
  if(argc==3){assert(collection.groups.size()==2);std::set<std::string> names,ids;
    for(int root:collection.groups){names.insert(collection.entities[root].get("_tb_name"));ids.insert(collection.entities[root].get("_tb_id"));auto one=parse(extract(collection,root,"check"));assert(one.entities.size()==4);int doors=0,players=0,brushes=0;for(const auto& e:one.entities){doors+=e.get("classname")=="func_door";players+=e.get("classname")=="info_player_deathmatch";brushes+=!e.geometry.empty();}assert(doors==1&&players==1&&brushes==2);}
    assert(ids.size()==2&&names.count("Test Group")&&names.count("Test Group_1"));std::cout<<"PASS: saved prefab instances retain geometry and independent hierarchy\n";return 0;
  }
  assert(collection.groups.size()==1);
  auto root=collection.groups[0];assert(collection.entities[root].get("_tb_name")=="Test Group");
  auto subset=parse(extract(collection,root,"Copy_1"));assert(subset.entities.size()==4);
  assert(subset.entities[1].geometry==collection.entities[root].geometry);
  assert(subset.entities[1].get("_tb_layer").empty());assert(subset.entities[1].get("_tb_name")=="Copy_1");
  assert(subset.entities[2].get("classname")=="func_door"&&subset.entities[2].parent==1);
  assert(subset.entities[3].get("classname")=="info_player_deathmatch"&&subset.entities[3].parent==1);
  auto nested=bytes+"\n{\"classname\" \"func_group\" \"_tb_type\" \"_tb_group\" \"_tb_id\" \"30\" \"_tb_group\" \"20\" \"_tb_name\" \"Nested\" \"_tb_linked_group_id\" \"old-link\"}\n";
  auto tree=parse(nested);assert(tree.groups.size()==2);
  auto detached=parse(extract(tree,tree.groups[1],"Detached"));assert(detached.entities.size()==2&&detached.entities[1].parent==-1&&detached.entities[1].get("_tb_linked_group_id").empty());
  auto all=parse(extract(tree,tree.groups[0],"Parent"));assert(all.groups.size()==2&&all.entities.back().parent==1);
  auto escaped=parse("/* { */\n"+extract(collection,root,"quote\" slash\\ newline\n}"));assert(escaped.entities[1].get("_tb_name")=="quote\" slash\\ newline\n}");
  int failures=0;for(const auto& bad:{std::string("{\"classname\""),std::string("/* missing"),std::string("{\"a\" \"b\"}"),bytes+"{\"_tb_id\" \"20\"}",bytes+"{\"classname\" \"func_group\" \"_tb_type\" \"_tb_group\" \"_tb_id\" \"30\" \"_tb_group\" \"30\"}"})try{parse(bad);}catch(const std::exception&){++failures;}
  assert(failures==5);std::cout<<"PASS: prefab hierarchy, geometry preservation, isolation, escaped fields and malformed input\n";
}
