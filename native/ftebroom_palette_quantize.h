// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include "ftebroom_quake1.h"
#include <atomic>
#include <climits>
#include <unordered_map>
namespace ftebroom {
// Exact RGB caching accelerates flat regions without reducing palette precision.
class PaletteQuantizer {
  const std::string& colors;int count;
  std::unordered_map<uint32_t,unsigned char> cache;
public:
  PaletteQuantizer(const std::string& palette,int limit):colors(palette),count(limit){if(colors.size()!=768||limit<1||limit>256)throw std::runtime_error("Invalid palette.");cache.reserve(65536);}
  unsigned char nearest(int r,int g,int b){
    uint32_t key=(r<<16)|(g<<8)|b;auto found=cache.find(key);if(found!=cache.end())return found->second;
    int best=0,distance=INT_MAX;
    for(int i=0;i<count;i++){int dr=r-(unsigned char)colors[i*3],dg=g-(unsigned char)colors[i*3+1],db=b-(unsigned char)colors[i*3+2];int d=dr*dr+dg*dg+db*db;if(d<distance){best=i;distance=d;if(!d)break;}}
    if(cache.size()<65536)cache.emplace(key,best);return best;
  }
};
inline quake1::Texture quantizeFolderImage(const unsigned char* rgba,unsigned width,unsigned height,const std::string& palette,const std::string& name,const std::atomic<bool>* cancel=nullptr){
  if(!rgba||!width||!height||uint64_t(width)*height>16777216)throw std::runtime_error("Invalid image dimensions.");
  // WAD mip dimensions must be multiples of 16. Valid source dimensions are retained.
  unsigned w=std::min(4096u,std::max(16u,(width+15)&~15u)),h=std::min(4096u,std::max(16u,(height+15)&~15u));
  bool masked=!name.empty()&&name[0]=='{';PaletteQuantizer quantizer(palette,masked?255:256);
  quake1::Texture result{name,w,h,{}};result.pixels.resize(size_t(w)*h);
  for(unsigned y=0;y<h;y++){
    if(cancel&&cancel->load())throw std::runtime_error("Texture folder compilation cancelled.");
    for(unsigned x=0;x<w;x++){
      unsigned x0=x*width/w,x1=std::max(x0+1,(x+1)*width/w),y0=y*height/h,y1=std::max(y0+1,(y+1)*height/h);
      uint64_t rgb[3]={},alpha=0,n=uint64_t(x1-x0)*(y1-y0);
      for(unsigned sy=y0;sy<y1;sy++)for(unsigned sx=x0;sx<x1;sx++){
        auto pixel=rgba+(size_t(sy)*width+sx)*4;alpha+=pixel[3];for(int c=0;c<3;c++)rgb[c]+=uint64_t(pixel[c])*(masked?pixel[3]:1);
      }
      if(masked&&alpha<n*128){result.pixels[size_t(y)*w+x]=255;continue;}
      auto divisor=masked?alpha:n;result.pixels[size_t(y)*w+x]=quantizer.nearest(rgb[0]/divisor,rgb[1]/divisor,rgb[2]/divisor);
    }
  }return result;
}
}
