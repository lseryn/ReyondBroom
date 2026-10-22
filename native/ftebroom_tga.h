// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include "ftebroom_quake1.h"
namespace ftebroom {
struct ImportImage {unsigned width,height;std::vector<unsigned char> rgba;};
inline ImportImage readTga(const std::string& bytes){
 quake1::range(bytes,0,18);auto byte=[&](size_t p){quake1::range(bytes,p,1);return (unsigned char)bytes[p];};
 unsigned type=byte(2),bits=byte(16),w=byte(12)|(byte(13)<<8),h=byte(14)|(byte(15)<<8);
 if(byte(1)||!(type==2||type==10)||!(bits==24||bits==32)||!w||!h||w>8192||h>8192)throw std::runtime_error("Use a 24/32-bit RGB TGA up to 8192 pixels.");
 ImportImage image{w,h,std::vector<unsigned char>(size_t(w)*h*4)};size_t at=18+byte(0),done=0,total=size_t(w)*h;bool top=byte(17)&32,right=byte(17)&16;
 while(done<total){unsigned run=1;bool repeat=false;if(type==10){auto packet=byte(at++);run=(packet&127)+1;repeat=packet&128;}if(run>total-done)throw std::runtime_error("Invalid TGA packet.");unsigned char pixel[4]={0,0,0,255};
  for(unsigned j=0;j<run;j++){if(!repeat||!j){quake1::range(bytes,at,bits/8);pixel[2]=byte(at++);pixel[1]=byte(at++);pixel[0]=byte(at++);pixel[3]=bits==32?byte(at++):255;}auto y=done/w,x=done%w;if(!top)y=h-y-1;if(right)x=w-x-1;std::copy(pixel,pixel+4,image.rgba.begin()+(y*w+x)*4);done++;}
 }return image;
}
}
