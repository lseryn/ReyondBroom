#include "../native/ftebroom_resource_directory.h"
#include <cassert>
#include <chrono>
#include <fstream>
#include <iostream>
int main(){
 namespace fs=std::filesystem;
 auto root=fs::temp_directory_path()/("ReyondBroom-resources69-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
 fs::create_directories(root/"Game with spaces"/"id1");fs::create_directories(root/"custom mod");
 auto game=root/"Game with spaces",id1=game/"id1",mod=root/"custom mod";
 auto resolve=ftebroom::quakeResourceDirectory;
 assert(resolve(game.u8string())==id1);assert(resolve(id1.u8string())==id1);
 assert(resolve((id1/"").u8string())==id1);
 assert(resolve(mod.u8string())==mod);
 assert(resolve("  \""+game.u8string()+"\" \r\n")==id1);
 fs::create_directories(root/"ID1"/"id1");assert(resolve((root/"ID1").u8string())==root/"ID1");
 std::ofstream(game/"pak0.pak")<<"root data";assert(resolve(game.u8string())==id1);
 std::ofstream(root/"file")<<"data";
 for(auto path:{std::string(),std::string("\"\""),(root/"missing").u8string(),(root/"file").u8string()}){
  bool failed=false;try{resolve(path);}catch(const std::exception&){failed=true;}assert(failed);
 }
 fs::remove_all(root);std::cout<<"PASS: id1, game root, custom mod, quotes, spaces, case, trailing separators and invalid paths\n";
}
