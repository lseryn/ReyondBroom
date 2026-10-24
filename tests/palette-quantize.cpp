// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_wad_import.h"
#include <cassert>
#include <iostream>
using namespace ftebroom;
int main(){
 std::string palette(768,0);for(int i=0;i<256;i++)for(int c=0;c<3;c++)palette[i*3+c]=char(i);
 std::vector<unsigned char> rgba(1024*16*4,250);for(size_t i=3;i<rgba.size();i+=4)rgba[i]=255;
 auto t=quantizeFolderImage(rgba.data(),1024,16,palette,"bright");assert(t.width==1024&&t.height==16&&t.pixels[0]==250);
 auto w=addWadTexture({},t,palette,true);auto directory=quake1::word(w,8),lump=quake1::word(w,directory);
 for(int m=0;m<4;m++)assert((unsigned char)w[lump+quake1::word(w,lump+24+m*4)]==250);
 auto old=addWadTexture({},t,palette);auto oldlump=quake1::word(old,quake1::word(old,8));assert((unsigned char)old[oldlump+quake1::word(old,oldlump+28)]==223);
 for(unsigned y=0;y<16;y++)for(unsigned x=0;x<512;x++)rgba[(y*1024+x)*4+3]=0;
 t=quantizeFolderImage(rgba.data(),1024,16,palette,"{mask");assert(t.pixels[0]==255&&t.pixels[1023]==250);
 w=addWadTexture({},t,palette,true);lump=quake1::word(w,quake1::word(w,8));for(int m=0;m<4;m++){auto p=lump+quake1::word(w,lump+24+m*4);assert((unsigned char)w[p]==255&&(unsigned char)w[p+(1024>>m)-1]==250);}
 auto image=quake1::tga(t,palette);assert(image[16]==32&&(unsigned char)image[21]==0);
 auto odd=quantizeFolderImage(rgba.data(),31,19,palette,"odd");assert(odd.width==32&&odd.height==32);
 std::atomic<bool> cancel{true};bool rejected=false;try{quantizeFolderImage(rgba.data(),16,16,palette,"cancel",&cancel);}catch(...){rejected=true;}assert(rejected);
 rejected=false;try{addWadTexture({},quake1::Texture{"zero",0,0,{}},palette);}catch(...){rejected=true;}assert(rejected);
 PaletteQuantizer q(palette,256);for(int i=0;i<256;i++){assert(q.nearest(i,i,i)==i);assert(q.nearest(i,i,i)==i);}
 std::cout<<"PASS: full palette, legacy policy, alpha, mipmaps, dimensions, cancellation and exact cache\n";
}
