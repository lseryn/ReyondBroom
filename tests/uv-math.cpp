// SPDX-License-Identifier: GPL-2.0-or-later
#include "../native/ftebroom_uv_math.h"
#include <algorithm>
#include <cassert>
#include <iostream>
static bool near(double a,double b){return std::abs(a-b)<1e-8;}
int main()
{
  UVFace f;f.points={{0,0},{64,0},{64,64},{0,64}};
  auto raw=uvDragOffset(f,{20,20},{33.25,27.75},{64,64},1,1,false);
  assert(near(raw.x,-13.25)&&near(raw.y,-7.75));
  // The texture point under the initial cursor follows the new cursor exactly.
  for(auto m: {std::array<double,6>{1,0,0,0,1,0},
               std::array<double,6>{0,-2,17,.5,0,-11},
               std::array<double,6>{-2,.3,9,.2,.5,23}}) {
    f.matrix=m;
    for(double zoom: {.25,1.,4.}) {
      UVPoint down{20,20},cursor=down+UVPoint{13.25/zoom,7.75/zoom};
      auto d=uvDragOffset(f,down,cursor,{64,64},zoom,1,false);
      auto moved=m;moved[2]+=d.x;moved[5]+=d.y;
      auto point=uvInverse(moved,uvMap(m,down));
      assert(near(point.x,cursor.x)&&near(point.y,cursor.y));
    }
  }
  f.matrix={1,0,0,0,1,0};
  // Eight screen pixels at every zoom/DPI, independent per axis.
  for(double zoom: {.5,1.,2.})for(double dpi: {1.,1.25}) {
    auto inside=uvDragOffset(f,{0,0},{7*dpi/zoom,18*dpi/zoom},{64,64},zoom,dpi,true);
    assert(near(inside.x,0));
    auto outside=uvDragOffset(f,{0,0},{9*dpi/zoom,0},{64,64},zoom,dpi,true);
    double quantum=std::min(1.,dpi/zoom);assert(near(outside.x,std::round((-9*dpi/zoom)/quantum)*quantum));
  }
  f.points={{1,2},{61,3},{62,60},{3,60}};
  auto nearest=uvDragOffset(f,{0,0},{0,0},{64,64},1,1,true);
  assert(near(nearest.x,-1)&&near(nearest.y,-2));
  std::reverse(f.points.begin(),f.points.end());
  auto reverse=uvDragOffset(f,{0,0},{0,0},{64,64},1,1,true);
  assert(near(reverse.x,nearest.x)&&near(reverse.y,nearest.y));
  // No incremental drift after entering/leaving snap or returning to the start.
  f.points={{0,0},{64,0},{64,64},{0,64}};
  for(double x: {6.,7.,9.,16.,3.,0.}) {
    auto d=uvDragOffset(f,{0,0},{x,0},{64,64},1,1,true);
    assert(near(d.x,x<8?0:-x));
  }
  f.matrix[2]=.3;
  auto snapped=uvDragOffset(f,{0,0},{7,0},{64,64},1,1,true);
  assert(near(snapped.x,-.3));
  auto unsnapped=uvDragOffset(f,{0,0},{10,0},{64,64},1,1,true,snapped);
  assert(near(unsnapped.x,-10.3));
  auto free=uvDragOffset(f,{0,0},{10.125,0},{64,64},1,1,false,unsnapped);
  assert(near(free.x,-10.125));
  f.matrix={1,0,0,0,1,0};
  auto precise=uvDragOffset(f,{0,0},{12.125,0},{64,64},16,1,true);
  assert(near(precise.x,-12.125));
  std::cout<<"PASS: UV cursor tracking, rotated/scaled/sheared axes, 8px snap, zoom/DPI, nearest vertex, residual motion\n";
}

