// SPDX-License-Identifier: GPL-2.0-or-later
static void modelConverterShow(const std::string& source);
static bool modelViewerOpen=false,modelViewerPlay=false,modelViewerBones=false;
static std::string modelViewerPath;
static int modelViewerSequence=0,modelViewerPose=0,modelViewerBone=1;
static float modelViewerYaw=135,modelViewerPitch=15,modelViewerZoom=1,modelViewerFPS=10;
static double modelViewerClock=0;
static bool modelFile(const std::filesystem::path& path) {
  auto ext=entityLower(path.extension().u8string());return ext==".mdl"||ext==".md3"||ext==".md2"||ext==".iqm"||ext==".md5mesh"||ext==".mdx"||ext==".zym"||ext==".dpm"||ext==".psk"||ext==".obj";
}
static void modelViewerShow(const std::string& path) {
  modelViewerPath=path;modelViewerOpen=true;modelViewerPlay=false;modelViewerSequence=modelViewerPose=0;modelViewerClock=0;modelViewerZoom=1;
  cvars->SetString("ftebroom_modelviewer_path",path.c_str());cvars->SetFloat("ftebroom_modelviewer_count",0);cvars->SetFloat("ftebroom_modelviewer_poses",0);
}
static void modelViewerPanel() {
  cvars->SetFloat("ftebroom_modelviewer_open",0);if(!modelViewerOpen)return;
  ImGui::SetNextWindowSize({760,650},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Model viewer",&modelViewerOpen)) {
    cvars->SetFloat("ftebroom_modelviewer_open",1);
    ImGui::TextWrapped("%s",modelViewerPath.c_str());
    if(ImGui::Button("Convert..."))modelConverterShow(modelViewerPath);
    if(cvars->GetFloat("ftebroom_modelviewer_count")<=0)ImGui::TextWrapped("Loading model, or model unavailable. Check its file and referenced resources.");
    int sequences=std::max(1,(int)cvars->GetFloat("ftebroom_modelviewer_count"));
    int poses=std::max(1,(int)cvars->GetFloat("ftebroom_modelviewer_poses"));
    float duration=cvars->GetFloat("ftebroom_modelviewer_duration");
    char name[256]={};cvars->GetString("ftebroom_modelviewer_name",name,sizeof name);
    if(ImGui::SliderInt(poses>1?"Animation":"Frame",&modelViewerSequence,0,sequences-1)){modelViewerClock=0;modelViewerPose=0;modelViewerPlay=false;}
    ImGui::Text("%s | %i sequence(s), %i pose(s)",name,sequences,poses);
    if(poses>1 && ImGui::SliderInt("Animation frame",&modelViewerPose,0,poses-1)){modelViewerPlay=false;modelViewerClock=duration>0?modelViewerPose*duration/poses:0;}
    ImGui::Checkbox("Play",&modelViewerPlay);ImGui::SameLine();ImGui::SetNextItemWidth(140);ImGui::SliderFloat("Frames / second",&modelViewerFPS,1,60,"%.1f");
    if(modelViewerPlay){modelViewerClock+=ImGui::GetIO().DeltaTime*(poses>1?(duration>0?modelViewerFPS*duration/poses:1):1);if(poses>1&&duration>0){modelViewerClock=std::fmod(modelViewerClock,duration);modelViewerPose=std::min(poses-1,int(modelViewerClock*poses/duration));}else modelViewerSequence=int(modelViewerClock*modelViewerFPS)%sequences;}
    ImGui::Text("Frame %i / %i",poses>1?modelViewerPose:modelViewerSequence,poses>1?poses-1:sequences-1);
    int bones=(int)cvars->GetFloat("ftebroom_modelviewer_bones");
    ImGui::BeginDisabled(!bones);ImGui::Checkbox("Show bones",&modelViewerBones);
    if(bones){ImGui::SameLine();ImGui::SetNextItemWidth(180);ImGui::SliderInt("Bone",&modelViewerBone,1,bones);cvars->GetString("ftebroom_modelviewer_bonename",name,sizeof name);ImGui::Text("%s",name);}ImGui::EndDisabled();
    if(!bones)ImGui::TextDisabled("No skeletal bones (vertex-animated/static model).");
    ImGui::TextDisabled("Drag with left mouse: orbit. Wheel: zoom.");
    auto size=ImGui::GetContentRegionAvail();size.x=std::max(64.f,size.x);size.y=std::max(64.f,size.y);
    static qhandle_t image=0;if(!image)image=draw->LoadImageShader("ftebroom/modelviewer-image","{\n program default2d\n {\n map $rt:ftebroom_modelviewer\n rgbgen vertex\n alphagen vertex\n }\n }");
    const auto imagePos=ImGui::GetCursorScreenPos();
    ImGui::GetWindowDrawList()->AddImage((ImTextureID)image,imagePos,{imagePos.x+size.x,imagePos.y+size.y});
    ImGui::InvisibleButton("model-orbit",size,ImGuiButtonFlags_MouseButtonLeft);
    if(ImGui::IsItemActive()&&ImGui::IsMouseDragging(0,0)){modelViewerYaw-=ImGui::GetIO().MouseDelta.x*.4f;modelViewerPitch=std::clamp(modelViewerPitch-ImGui::GetIO().MouseDelta.y*.4f,-89.f,89.f);}
    if(ImGui::IsItemHovered())modelViewerZoom=std::clamp(modelViewerZoom*std::pow(1.12f,-ImGui::GetIO().MouseWheel),.1f,20.f);
    cvars->SetFloat("ftebroom_modelviewer_width",size.x);cvars->SetFloat("ftebroom_modelviewer_height",size.y);
    cvars->SetFloat("ftebroom_modelviewer_sequence",modelViewerSequence);cvars->SetFloat("ftebroom_modelviewer_time",poses>1?modelViewerClock:0);
    cvars->SetFloat("ftebroom_modelviewer_yaw",modelViewerYaw);cvars->SetFloat("ftebroom_modelviewer_pitch",modelViewerPitch);cvars->SetFloat("ftebroom_modelviewer_zoom",modelViewerZoom);
    cvars->SetFloat("ftebroom_modelviewer_showbones",modelViewerBones);cvars->SetFloat("ftebroom_modelviewer_bone",modelViewerBone);
  }ImGui::End();
}
