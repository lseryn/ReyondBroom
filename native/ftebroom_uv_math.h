// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <array>
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>
struct UVPoint
{
  double x=0,y=0;
  UVPoint operator+(UVPoint b)const{return {x+b.x,y+b.y};}
  UVPoint operator-(UVPoint b)const{return {x-b.x,y-b.y};}
  UVPoint operator*(double s)const{return {x*s,y*s};}
};
static double uvLength(UVPoint p){return std::hypot(p.x,p.y);}
struct UVFace
{
  std::string material;
  int model=0,id=0,face=0;
  double width=64,height=64;
  std::array<double,6> matrix{1,0,0,0,1,0};
  std::vector<UVPoint> points;
};
static UVPoint uvMap(const std::array<double,6>& m,UVPoint p)
{return {m[0]*p.x+m[1]*p.y+m[2],m[3]*p.x+m[4]*p.y+m[5]};}
static UVPoint uvInverse(const std::array<double,6>& m,UVPoint p)
{
  double d=m[0]*m[4]-m[1]*m[3];if(std::abs(d)<1e-12)return {};
  p=p-UVPoint{m[2],m[5]};return {(m[4]*p.x-m[1]*p.y)/d,(-m[3]*p.x+m[0]*p.y)/d};
}
// Offset is evaluated from the immutable gesture start, preserving subpixel motion
// and the cursor residual while an edge is snapped.
static UVPoint uvDragOffset(const UVFace& face, UVPoint down, UVPoint cursor,
                            UVPoint grid, double zoom, double dpi, bool snap, UVPoint previous={})
{
  UVPoint delta=uvMap(face.matrix,down)-uvMap(face.matrix,cursor);
  if(!snap)return delta;
  UVPoint nearest{1e30,1e30};
  for(auto p:face.points) {
    auto uv=uvMap(face.matrix,p)+delta;
    UVPoint distance{std::round(uv.x/grid.x)*grid.x-uv.x,
                     std::round(uv.y/grid.y)*grid.y-uv.y};
    if(std::abs(distance.x)<std::abs(nearest.x))nearest.x=distance.x;
    if(std::abs(distance.y)<std::abs(nearest.y))nearest.y=distance.y;
  }
  double tolerance=8*dpi/zoom;
  // At high magnification, quantize to one logical screen pixel instead of
  // forcing a whole texel jump. Ctrl still allows completely continuous motion.
  double quantumX=std::min(1.,std::hypot(face.matrix[0],face.matrix[1])*dpi/zoom);
  double quantumY=std::min(1.,std::hypot(face.matrix[3],face.matrix[4])*dpi/zoom);
  return {
    std::abs(nearest.x)<tolerance*std::hypot(face.matrix[0],face.matrix[1])?delta.x+nearest.x:previous.x+std::round((delta.x-previous.x)/quantumX)*quantumX,
    std::abs(nearest.y)<tolerance*std::hypot(face.matrix[3],face.matrix[4])?delta.y+nearest.y:previous.y+std::round((delta.y-previous.y)/quantumY)*quantumY};
}
