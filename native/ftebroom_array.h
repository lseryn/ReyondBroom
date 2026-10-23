// SPDX-License-Identifier: GPL-2.0-or-later
static bool arrayOpen=false;
static void arrayPanel(){
  if(!arrayOpen)return;
  if(ImGui::Begin("Array",&arrayOpen)){
    static int mode=0,count=4,axis=2,seed=1337;static float offset[3]={128,0,0},pivot[3]={0,0,0},angle=45;static bool rotate=true;
    ImGui::Combo("Mode",&mode,"Linear\0Radial\0Random volume\0");ImGui::SliderInt("Additional copies",&count,1,64);
    if(mode==1){ImGui::Combo("Axis",&axis,"X\0Y\0Z\0");ImGui::InputFloat3("Pivot",pivot);ImGui::InputFloat("Angle per copy",&angle);ImGui::Checkbox("Rotate copies",&rotate);}
    else ImGui::InputFloat3(mode==2?"Random half extents":"Offset per copy",offset);
    if(mode==2)ImGui::InputInt("Seed",&seed);
    ImGui::TextWrapped("Keeps the original. Selects the created copies. Apply is one Undo. At most 512 resulting objects.");
    if(ImGui::Button("Apply")){
      cvars->SetFloat("ftebroom_array_mode",mode);cvars->SetFloat("ftebroom_array_count",count);cvars->SetFloat("ftebroom_array_axis",axis);cvars->SetFloat("ftebroom_array_seed",seed);cvars->SetFloat("ftebroom_array_angle",angle);cvars->SetFloat("ftebroom_array_rotate",rotate);
      for(int a=0;a<3;a++){auto suffix=std::string(1,"xyz"[a]);cvars->SetFloat(("ftebroom_array_"+suffix).c_str(),offset[a]);cvars->SetFloat(("ftebroom_array_pivot_"+suffix).c_str(),pivot[a]);}command("ftebroom_array\n");
    }
    char error[512]={};cvars->GetString("ftebroom_array_error",error,sizeof error);if(*error)ImGui::TextWrapped("%s",error);
  }ImGui::End();
}
