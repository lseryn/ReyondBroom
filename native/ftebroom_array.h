// SPDX-License-Identifier: GPL-2.0-or-later
static bool arrayOpen=false;
static void arrayPanel(){
  if(!arrayOpen)return;
  if(ImGui::Begin("Array",&arrayOpen)){
    static int mode=0,count=4,axis=2,seed=1337;static float offset[3]={128,0,0},pivot[3]={0,0,0},angle=45;static bool rotate=true;static int lines=1,rings=1,facing=0;static float spacing=128,radius=256;static bool centered=true,cross=false,mirror=true,faceCenter=false;
    ImGui::Combo("Mode",&mode,"Linear\0Radial\0Random volume\0Lines / cross-lines\0Concentric rings\0Random radius\0");ImGui::SliderInt("Additional copies",&count,1,64);
    if(mode==1){ImGui::Combo("Axis",&axis,"X\0Y\0Z\0");ImGui::InputFloat3("Pivot",pivot);ImGui::InputFloat("Angle per copy",&angle);ImGui::Checkbox("Rotate copies",&rotate);}
    else if(mode<3) ImGui::InputFloat3(mode==2?"Random half extents":"Offset per copy",offset);
    if(mode==2||mode==5)ImGui::InputInt("Seed",&seed);
    if(mode>=3){
      ImGui::Combo("Axis",&axis,"X\0Y\0Z\0");
      if(mode==3){ImGui::SliderInt("Lines",&lines,1,64);ImGui::Checkbox("Cross lines",&cross);ImGui::Checkbox("Centered",&centered);ImGui::Checkbox("Mirror offsets",&mirror);}
      if(mode==4)ImGui::SliderInt("Rings",&rings,1,64);
      if(mode!=5){ImGui::InputFloat("Spacing",&spacing);ImGui::InputFloat3("Additional offset",offset);}else ImGui::DragFloat("Radius",&radius,1,1,65536);
      if(mode!=3){ImGui::Checkbox("Face center",&faceCenter);if(faceCenter)ImGui::Combo("Facing side",&facing,"+X\0-X\0+Y\0-Y\0+Z\0-Z\0");}
    }
    ImGui::TextWrapped("Keeps the original. Selects the created copies. Apply is one Undo. At most 512 resulting objects.");
    if(ImGui::Button("Apply")){
      cvars->SetFloat("ftebroom_array_lines",lines);cvars->SetFloat("ftebroom_array_rings",rings);cvars->SetFloat("ftebroom_array_spacing",spacing);cvars->SetFloat("ftebroom_array_radius",radius);cvars->SetFloat("ftebroom_array_centered",centered);cvars->SetFloat("ftebroom_array_cross",cross);cvars->SetFloat("ftebroom_array_mirror_offsets",mirror);cvars->SetFloat("ftebroom_array_face_center",faceCenter);cvars->SetFloat("ftebroom_array_facing_side",facing);
      cvars->SetFloat("ftebroom_array_mode",mode);cvars->SetFloat("ftebroom_array_count",count);cvars->SetFloat("ftebroom_array_axis",axis);cvars->SetFloat("ftebroom_array_seed",seed);cvars->SetFloat("ftebroom_array_angle",angle);cvars->SetFloat("ftebroom_array_rotate",rotate);
      for(int a=0;a<3;a++){auto suffix=std::string(1,"xyz"[a]);cvars->SetFloat(("ftebroom_array_"+suffix).c_str(),offset[a]);cvars->SetFloat(("ftebroom_array_pivot_"+suffix).c_str(),pivot[a]);}command("ftebroom_array\n");
    }
    char error[512]={};cvars->GetString("ftebroom_array_error",error,sizeof error);if(*error)ImGui::TextWrapped("%s",error);
  }ImGui::End();
}
