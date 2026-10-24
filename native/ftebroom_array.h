// SPDX-License-Identifier: GPL-2.0-or-later
static bool arrayOpen=false;
static const char* arrayKeys[]={"mode","count","axis","seed","x","y","z","pivot_x","pivot_y","pivot_z","angle","rotate","lines","rings","facing_side","spacing","radius","centered","cross","mirror_offsets","face_center"};
static float arrayDefaults[]={0,4,2,1337,128,0,0,0,0,0,45,1,1,1,0,128,256,1,0,1,0};
static float arrayGet(int i){return cvars->GetFloat((std::string("ftebroom_array_")+arrayKeys[i]).c_str());}
static void arraySet(int i,float value){cvars->SetFloat((std::string("ftebroom_array_")+arrayKeys[i]).c_str(),value);}
static bool arrayInteger(const char* label,int i,int low,int high){int value=(int)arrayGet(i);if(!ImGui::SliderInt(label,&value,low,high))return false;arraySet(i,value);return true;}
static bool arrayFlag(const char* label,int i){bool value=arrayGet(i)!=0;if(!ImGui::Checkbox(label,&value))return false;arraySet(i,value);return true;}
static bool arrayFloat(const char* label,int i){float value=arrayGet(i);if(!ImGui::InputFloat(label,&value))return false;arraySet(i,value);return true;}
static bool arrayVector(const char* label,int i){float value[]={arrayGet(i),arrayGet(i+1),arrayGet(i+2)};if(!ImGui::InputFloat3(label,value))return false;for(int a=0;a<3;a++)arraySet(i+a,value[a]);return true;}
static bool arrayCombo(const char* label,int i,const char* options){int value=(int)arrayGet(i);if(!ImGui::Combo(label,&value,options))return false;arraySet(i,value);return true;}
static void arrayPanel(){
  static bool wasOpen=false,initialized=false,pending=false;static double lastPreview=-1;
  if(!arrayOpen){if(wasOpen)command("ftebroom_array cancel\n");wasOpen=false;pending=false;return;}
  bool changed=!wasOpen;wasOpen=true;
  if(!initialized){for(int i=0;i<21;i++)arraySet(i,arrayDefaults[i]);initialized=true;}
  bool apply=false;
  if(ImGui::Begin("Array",&arrayOpen)){
    changed|=arrayCombo("Mode",0,"Linear\0Radial\0Random volume\0Lines / cross-lines\0Concentric rings\0Random radius\0");changed|=arrayInteger("Additional copies",1,1,64);
    int mode=(int)arrayGet(0);
    if(mode==1){changed|=arrayCombo("Axis",2,"X\0Y\0Z\0");changed|=arrayVector("Pivot",7);changed|=arrayFloat("Angle per copy",10);changed|=arrayFlag("Rotate copies",11);}
    else if(mode<3)changed|=arrayVector(mode==2?"Random half extents":"Offset per copy",4);
    if(mode==2||mode==5){int seed=(int)arrayGet(3);if(ImGui::InputInt("Seed",&seed)){arraySet(3,seed);changed=true;}}
    if(mode>=3){
      changed|=arrayCombo("Axis",2,"X\0Y\0Z\0");
      if(mode==3){changed|=arrayInteger("Lines",12,1,64);changed|=arrayFlag("Cross lines",18);changed|=arrayFlag("Centered",17);changed|=arrayFlag("Mirror offsets",19);}
      if(mode==4)changed|=arrayInteger("Rings",13,1,64);
      if(mode!=5){changed|=arrayFloat("Spacing",15);changed|=arrayVector("Additional offset",4);}else changed|=arrayFloat("Radius",16);
      if(mode!=3){changed|=arrayFlag("Face center",20);if(arrayGet(20))changed|=arrayCombo("Facing side",14,"+X\0-X\0+Y\0-Y\0+Z\0-Z\0");}
    }
    ImGui::TextWrapped("Live preview keeps the original. Apply creates copies in one document Undo. Up to 512 objects.");
    ImGui::BeginDisabled(!cvars->GetFloat("ftebroom_array_valid")||changed||pending);
    if(ImGui::Button("Apply")){apply=true;arrayOpen=false;command("ftebroom_array apply\n");}
    ImGui::EndDisabled();ImGui::SameLine();
    if(ImGui::Button("Default")){for(int i=0;i<21;i++)arraySet(i,arrayDefaults[i]);changed=true;}
    ImGui::SameLine();ImGui::BeginDisabled(!cvars->GetFloat("ftebroom_array_active"));if(ImGui::Button("Undo settings"))command("ftebroom_undo\n");
    ImGui::SameLine();if(ImGui::Button("Redo settings"))command("ftebroom_redo\n");
    ImGui::EndDisabled();ImGui::SameLine();if(ImGui::Button("Cancel"))arrayOpen=false;
    if(ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows)&&!ImGui::GetIO().WantTextInput&&ImGui::IsKeyPressed(ImGuiKey_Escape))arrayOpen=false;
    char error[512]={};cvars->GetString("ftebroom_array_error",error,sizeof error);if(*error)ImGui::TextWrapped("%s",error);
  }ImGui::End();
  if(!arrayOpen){if(!apply)command("ftebroom_array cancel\n");wasOpen=false;pending=false;}
  else {pending|=changed;if(pending&&(ImGui::GetTime()-lastPreview>=.1||!ImGui::IsAnyItemActive())){command("ftebroom_array preview\n");pending=false;lastPreview=ImGui::GetTime();}}
}
