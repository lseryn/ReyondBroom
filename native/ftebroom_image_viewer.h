// SPDX-License-Identifier: GPL-2.0-or-later
#define STB_IMAGE_STATIC
#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_STDIO
#define STBI_MAX_DIMENSIONS 16384
#include "third_party/stb_image.h"
// Decode loose files and archive members, then upload bounded images to FTE.
struct FileImage { qhandle_t handle=0; int slot=0,frame=-1; unsigned long long used=0; std::string error; };
static std::map<std::pair<std::filesystem::path,bool>,FileImage> fileImages;
static unsigned long long fileImageClock=0;
static std::filesystem::path imageViewerPath;
static bool imageViewerOpen=false, imageViewerFit=true;
static float imageViewerZoom=1;
static bool imageFile(const std::filesystem::path& path) {
  auto ext=entityLower(path.extension().u8string());
  return ext==".png"||ext==".jpg"||ext==".jpeg"||ext==".tga"||ext==".bmp"||ext==".gif"||ext==".psd";
}
static void clearFileImages() {
  for(auto& item:fileImages)if(item.second.handle)draw->UnloadImage(item.second.handle);
  fileImages.clear();
}
static FileImage& fileImage(const std::filesystem::path& path,bool full=false) {
  if(full)for(auto it=fileImages.begin();it!=fileImages.end();){if(it->first.second&&it->first.first!=path){if(it->second.handle)draw->UnloadImage(it->second.handle);it=fileImages.erase(it);}else ++it;}
  auto key=std::make_pair(path,full);auto found=fileImages.find(key);
  if(found==fileImages.end()) {
    // Limit GPU residency and failed-file entries, including when browsing large PAKs.
    if(fileImages.size()>=256) {
      auto oldest=std::min_element(fileImages.begin(),fileImages.end(),[](const auto& a,const auto& b){return a.second.used<b.second.used;});
      if(oldest->second.frame==ImGui::GetFrameCount()){static FileImage unavailable;return unavailable;}
      if(oldest->second.handle)draw->UnloadImage(oldest->second.handle);
      fileImages.erase(oldest);
    }
    FileImage entry;
    for(;;entry.slot++){bool occupied=false;for(const auto& cached:fileImages)occupied|=cached.second.slot==entry.slot;if(!occupied)break;}
    try {
      modFileValidate(path);auto bytes=modFileBytes(path);
      if(bytes.empty()||bytes.size()>32*1024*1024)throw std::runtime_error("Image must be between 1 byte and 32 MiB.");
      int width=0,height=0,channels=0;
      if(!stbi_info_from_memory((const stbi_uc*)bytes.data(),bytes.size(),&width,&height,&channels)||
         width<=0||height<=0||size_t(width)*height>16777216)throw std::runtime_error("Unsupported image or more than 16 million pixels.");
      auto pixels=stbi_load_from_memory((const stbi_uc*)bytes.data(),bytes.size(),&width,&height,&channels,4);
      if(!pixels)throw std::runtime_error("Cannot decode image.");
      struct FreePixels {stbi_uc* p;~FreePixels(){stbi_image_free(p);}} cleanup{pixels};
      float scale=full?1.f:std::min(1.f,std::min(256.f/width,256.f/height));int tw=std::max(1,int(width*scale)),th=std::max(1,int(height*scale));
      std::string raster(18+tw*th*4,0);raster[2]=2;raster[12]=tw&255;raster[13]=tw>>8;raster[14]=th&255;raster[15]=th>>8;raster[16]=32;raster[17]=40;
      for(int y=0;y<th;y++)for(int x=0;x<tw;x++){auto from=pixels+((y*height/th)*width+x*width/tw)*4;auto to=&raster[18+(y*tw+x)*4];to[0]=from[2];to[1]=from[1];to[2]=from[0];to[3]=from[3];}
      bytes=std::move(raster);
      auto name="ftebroom/file-image-slot-"+std::to_string(entry.slot)+".tga";
      draw->LoadImageData(name.c_str(),"image/tga",bytes.data(),bytes.size());
      entry.handle=draw->LoadImage(name.c_str());
      if(!entry.handle)throw std::runtime_error("FTE could not decode this image.");
    }catch(const std::exception& e){entry.error=e.what();}
    found=fileImages.emplace(key,std::move(entry)).first;
  }
  found->second.used=++fileImageClock;found->second.frame=ImGui::GetFrameCount();return found->second;
}
static bool fileImageTile(const std::filesystem::path& path,ImVec2 p,float size) {
  auto& image=fileImage(path);float w=0,h=0;
  if(!image.handle||draw->ImageSize(image.handle,&w,&h)<=0||w<=0||h<=0)return false;
  float scale=std::min(size/w,size/h);ImVec2 a(p.x+(size-w*scale)*.5f,p.y+(size-h*scale)*.5f);
  auto list=ImGui::GetWindowDrawList();list->PushClipRect(p,{p.x+size,p.y+size},true);
  list->AddImage((ImTextureID)image.handle,a,{a.x+w*scale,a.y+h*scale});list->PopClipRect();return true;
}
static void imageViewerShow(const std::filesystem::path& path){imageViewerPath=path;imageViewerOpen=true;imageViewerFit=true;imageViewerZoom=1;}
static void imageViewerPanel() {
  if(!imageViewerOpen)return;
  ImGui::SetNextWindowSize({760,580},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Image viewer",&imageViewerOpen)) {
    ImGui::TextWrapped("%s",imageViewerPath.u8string().c_str());
    ImGui::Checkbox("Fit image",&imageViewerFit);ImGui::SameLine();
    if(ImGui::Button("100%")){imageViewerFit=false;imageViewerZoom=1;}
    ImGui::SameLine();ImGui::SetNextItemWidth(180);
    if(ImGui::SliderFloat("Zoom",&imageViewerZoom,.05f,8.f,"%.2fx"))imageViewerFit=false;
    auto& image=fileImage(imageViewerPath,true);float w=0,h=0;
    if(!image.error.empty())ImGui::TextWrapped("%s",image.error.c_str());
    else if(image.handle&&draw->ImageSize(image.handle,&w,&h)>0&&w>0&&h>0) {
      ImGui::Text("%.0f x %.0f",w,h);
      ImGui::BeginChild("Image canvas",{0,0},ImGuiChildFlags_Borders,ImGuiWindowFlags_HorizontalScrollbar);
      auto avail=ImGui::GetContentRegionAvail();float zoom=imageViewerFit?std::min(avail.x/w,avail.y/h):imageViewerZoom;
      ImGui::Image((ImTextureID)image.handle,{std::max(1.f,w*zoom),std::max(1.f,h*zoom)});
      ImGui::EndChild();
    }else ImGui::TextUnformatted("Loading image...");
  }ImGui::End();
}
