// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_model_export.h"
static bool modelConverterOpen=false,modelConverterPending=false,modelConverterAcceptLoss=false;
static std::string modelConverterSource,modelConverterMessage;
static int modelConverterFormat=0,modelConverterSequence=0,modelConverterFrames=1;
static float modelConverterFPS=24;
static char modelConverterDestination[4096]={};
static void modelConverterShow(const std::string& source) {
  if(modelConverterPending)return;
  modelConverterSource=source;modelConverterOpen=true;modelConverterMessage.clear();modelConverterAcceptLoss=false;
  auto target=modFileRoot()/"models"/"converted"/(std::filesystem::u8path(source).stem().u8string()+".md3");
  std::snprintf(modelConverterDestination,sizeof modelConverterDestination,"%s",target.u8string().c_str());
}
static void modelConverterPanel() {
  if(modelConverterPending&&cvars->GetFloat("ftebroom_convert_status")!=0) {
    modelConverterPending=false;
    try {
      if(cvars->GetFloat("ftebroom_convert_status")!=1)throw std::runtime_error("FTE could not extract this model. Check the model, animation index and conversion limits.");
      size_t length=0;auto data=(char*)files->LoadFile("data/model-convert.mesh",&length);
      if(!data)throw std::runtime_error("Model extraction output is missing.");
      if(length>128*1024*1024){core->Free(data);throw std::runtime_error("Model extraction exceeds 128 MiB.");}
      std::string bytes(data,length);core->Free(data);
      auto mesh=ftebroom::modelExport::parse(bytes);
      auto target=std::filesystem::u8path(modelConverterDestination);modFileValidate(target);
      std::string skinBytes;std::filesystem::path skinPath;
      if(!modelConverterFormat&&entityLower(std::filesystem::u8path(modelConverterSource).extension().u8string())==".mdl") {
        auto source=modelResource(modelConverterSource),palette=modelResource("gfx/palette.lmp");
        if(source.substr(0,4)=="IDPO") {
          auto mdl=ftebroom::readMdl(source);skinBytes=ftebroom::quake1::tga(mdl.skin,palette);
          skinPath=target.parent_path()/(target.stem().u8string()+".skin.tga");
          if(std::filesystem::exists(skinPath))throw std::runtime_error("Converted skin already exists. Choose a new model filename.");
          auto material=skinPath.lexically_relative(modFileRoot()).generic_u8string();for(auto& surface:mesh.surfaces)surface.material=material;
        }
      }
      auto output=modelConverterFormat?ftebroom::modelExport::obj(mesh):ftebroom::modelExport::md3(mesh);
      if(std::filesystem::exists(target))throw std::runtime_error("Destination exists. Choose a new name to preserve it.");
      std::filesystem::create_directories(target.parent_path());
      auto temp=target;temp+=".ftebroom-convert.tmp";
      try{soundWrite(temp,output);if(!skinBytes.empty())soundWrite(skinPath,skinBytes);std::filesystem::rename(temp,target);}catch(...){std::error_code ec;std::filesystem::remove(temp,ec);throw;}
      modFilesRefresh=true;modelConverterMessage="Saved "+target.u8string();
    }catch(const std::exception& e){modelConverterMessage=e.what();}
  }
  if(!modelConverterOpen)return;
  ImGui::SetNextWindowSize({650,380},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Convert model",&modelConverterOpen)) {
    ImGui::TextWrapped("Source: %s",modelConverterSource.c_str());
    ImGui::BeginDisabled(modelConverterPending);
    if(ImGui::Combo("Target format",&modelConverterFormat,"MD3 (baked animation)\0OBJ (static mesh)\0")){
      auto target=std::filesystem::u8path(modelConverterDestination);target.replace_extension(modelConverterFormat?".obj":".md3");std::snprintf(modelConverterDestination,sizeof modelConverterDestination,"%s",target.u8string().c_str());
    }
    ImGui::InputText("Destination",modelConverterDestination,sizeof modelConverterDestination);
    ImGui::InputInt("Animation / sequence",&modelConverterSequence);ImGui::TextDisabled("Use -1 to export consecutive frame/sequence poses (Quake MDL/MD2).");ImGui::SliderInt("Baked frames",&modelConverterFrames,1,1024);ImGui::SliderFloat("Sampling FPS",&modelConverterFPS,1,120,"%.0f");
    ImGui::TextWrapped("Conversion bakes vertex positions. Bones, tags, model events and skin variants are not retained. MD3 retains material references; the first embedded Quake MDL skin is exported as a TGA using the loaded palette. OBJ exports only the first sampled pose and does not retain materials. The source file is preserved.");
    ImGui::Checkbox("I accept these conversion losses",&modelConverterAcceptLoss);
    ImGui::BeginDisabled(!modelConverterAcceptLoss);
    if(ImGui::Button("Bake and convert"))try {
      auto path=std::filesystem::u8path(modelConverterDestination);modFileValidate(path);
      if(modFilePacked(path)||std::filesystem::exists(path))throw std::runtime_error("Choose a new loose file inside the mod directory.");
      if(entityLower(path.extension().u8string())!=(modelConverterFormat?".obj":".md3"))throw std::runtime_error("Destination extension must match the selected format.");
      cvars->SetString("ftebroom_convert_source",modelConverterSource.c_str());cvars->SetFloat("ftebroom_convert_sequence",std::max(-1,modelConverterSequence));cvars->SetFloat("ftebroom_convert_frames",modelConverterFormat?1:modelConverterFrames);cvars->SetFloat("ftebroom_convert_fps",modelConverterFPS);cvars->SetFloat("ftebroom_convert_status",0);
      command("ftebroom_model_extract\n");modelConverterPending=true;modelConverterMessage="Extracting model geometry...";
    }catch(const std::exception& e){modelConverterMessage=e.what();}
    ImGui::EndDisabled();ImGui::EndDisabled();if(modelConverterPending&&ImGui::Button("Cancel conversion")){modelConverterPending=false;modelConverterMessage="Conversion cancelled.";}if(!modelConverterMessage.empty())ImGui::TextWrapped("%s",modelConverterMessage.c_str());
  }ImGui::End();
}
