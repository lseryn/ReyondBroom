// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_mdl.h"
struct EntityPreview{qhandle_t image=0;ftebroom::MdlPreview mesh;};
static std::map<std::string,EntityPreview> entityPreviews;
static void clearEntityPreviews(){for(auto& p:entityPreviews)if(p.second.image)draw->UnloadImage(p.second.image);entityPreviews.clear();}
static bool entityModelTile(const ftebroom::EntityDefinition& def,ImVec2 tile,float size){
  if(def.brush||def.model.empty()||def.model.find_first_of("{}()\"'")!=std::string::npos)return false;
  if(!ImGui::IsRectVisible(tile,{tile.x+size,tile.y+size}))return true;
  auto key=def.model+":"+def.modelSkin;auto it=entityPreviews.find(key);
  if(it==entityPreviews.end()){
    EntityPreview preview;
    try{size_t length=0;auto raw=(char*)files->LoadFile(def.model.c_str(),&length);if(!raw)throw std::runtime_error("Missing model");std::string bytes(raw,length);core->Free(raw);
      preview.mesh=ftebroom::readMdl(bytes,std::atoi(def.modelSkin.c_str()));raw=(char*)files->LoadFile("gfx/palette.lmp",&length);if(!raw)throw std::runtime_error("Missing palette");std::string palette(raw,length);core->Free(raw);
      auto name="textures/_ftebroom_model/"+std::to_string(entityDefinitionEpoch)+"-"+std::to_string(std::hash<std::string>{}(key))+".tga";auto path=documentPath(name);std::filesystem::create_directories(path.parent_path());auto pixels=ftebroom::quake1::tga(preview.mesh.skin,palette);std::ofstream out(path,std::ios::binary);out<<pixels;out.close();if(!out)throw std::runtime_error("Cannot cache model skin");preview.image=draw->LoadImage(name.c_str());
      // Project the first pose once; thumbnails never run game code or a second world render.
      float lo[2]={1e30f,1e30f},hi[2]={-1e30f,-1e30f};
      for(auto& tri:preview.mesh.triangles)for(auto& v:tri){auto p=v.point;v.point={.7071f*(p[0]-p[1]),.33f*(p[0]+p[1])-.88f*p[2],.62f*(p[0]+p[1])+.47f*p[2]};for(int a=0;a<2;a++){lo[a]=std::min(lo[a],v.point[a]);hi[a]=std::max(hi[a],v.point[a]);}}
      float extent=std::max({hi[0]-lo[0],hi[1]-lo[1],1.f});for(auto& tri:preview.mesh.triangles)for(auto& v:tri)for(int a=0;a<2;a++)v.point[a]=.5f+.88f*(v.point[a]-(hi[a]+lo[a])*.5f)/extent;
      std::stable_sort(preview.mesh.triangles.begin(),preview.mesh.triangles.end(),[](const auto& a,const auto& b){return a[0].point[2]+a[1].point[2]+a[2].point[2]<b[0].point[2]+b[1].point[2]+b[2].point[2];});
    }catch(...){if(preview.image)draw->UnloadImage(preview.image);preview={};}
    it=entityPreviews.emplace(key,std::move(preview)).first;
  }
  auto& p=it->second;if(!p.image)return false;auto list=ImGui::GetWindowDrawList();list->PushTextureID((ImTextureID)p.image);list->PushClipRect(tile,{tile.x+size,tile.y+size},true);
  for(const auto& tri:p.mesh.triangles){list->PrimReserve(3,3);auto idx=list->_VtxCurrentIdx;for(int j=0;j<3;j++)list->PrimWriteIdx(ImDrawIdx(idx+j));for(const auto& v:tri)list->PrimWriteVtx({tile.x+v.point[0]*size,tile.y+v.point[1]*size},{v.u,v.v},IM_COL32_WHITE);}
  list->PopClipRect();list->PopTextureID();return true;
}
