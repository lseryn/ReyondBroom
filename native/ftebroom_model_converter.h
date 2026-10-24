// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_model_import.h"
static bool modelConverterOpen=false,modelConverterPending=false,modelConverterAcceptLoss=false;
static std::string modelConverterSource,modelConverterMessage;
static int modelConverterFormat=0,modelConverterSequence=0,modelConverterFrames=1;
static float modelConverterFPS=24;
static char modelConverterDestination[4096]={};
static const char* modelConverterExtension(){return modelConverterFormat==2?".mdl":modelConverterFormat==1?".obj":".md3";}
static void modelConverterShow(const std::string& source) {
  if(modelConverterPending||modelImportJob.valid())return;
  modelImportExternal.clear();modelImportStage.clear();modelImportProfile=gameProfile;
  modelConverterSource=source;modelConverterOpen=true;modelConverterMessage.clear();modelConverterAcceptLoss=false;
  modelConverterFormat=gameProfile==2?2:0;modelConverterFrames=1;modelConverterSequence=0;
  auto target=modFileRoot()/"models"/"converted"/(std::filesystem::u8path(source).stem().u8string()+modelConverterExtension());
  std::snprintf(modelConverterDestination,sizeof modelConverterDestination,"%s",target.u8string().c_str());
}
static void modelConverterSave(ftebroom::modelExport::Mesh mesh) {
  if(gameProfile!=modelImportProfile)throw std::runtime_error("Game profile changed. Reopen the conversion in the intended profile.");
  auto target=std::filesystem::u8path(modelConverterDestination);modFileValidate(target);
  if(modFilePacked(target)||std::filesystem::exists(target))throw std::runtime_error("Choose a new loose filename inside the mod directory.");
  std::vector<ftebroom::modelExport::Skin> skins;
  std::string source;auto sourcePath=modelImportExternal.empty()?std::filesystem::u8path(modelConverterSource):modelImportExternal;
  if(entityLower(sourcePath.extension().u8string())==".mdl")source=modelImportExternal.empty()?modelResource(modelConverterSource):q1Read(modelImportExternal);
  for(auto& surface:mesh.surfaces){
    if(source.substr(0,4)=="IDPO"){
      auto palette=modelResource("gfx/palette.lmp");auto mdl=ftebroom::readMdl(source);
      skins.push_back(modelImportDecode(ftebroom::quake1::tga(mdl.skin,palette)));
    }else if(source.substr(0,4)=="IDST"&&surface.material.rfind("__hl_texture_",0)==0){
      auto skin=modelImportHalfLifeSkin(source,std::stoul(surface.material.substr(13)));
      for(auto& frame:surface.frames)for(auto& v:frame){v.uv[0]/=skin.width;v.uv[1]/=skin.height;}
      skins.push_back(std::move(skin));
    }else skins.push_back(modelImportDecode(modelImportTexture(surface.material)));
  }
  auto skinFolder=target.parent_path()/(target.stem().u8string()+"-skins");
  if(modelConverterFormat!=2&&std::filesystem::exists(skinFolder))throw std::runtime_error("The destination skin directory already exists. Choose a new filename.");
  for(size_t i=0;i<mesh.surfaces.size();i++)mesh.surfaces[i].material=modFileModelPath(skinFolder/(std::to_string(i)+".tga"));
  std::string output=modelConverterFormat==2?ftebroom::modelExport::mdl(mesh,skins,modelResource("gfx/palette.lmp")):modelConverterFormat==1?ftebroom::modelExport::obj(mesh):ftebroom::modelExport::md3(mesh);
  auto mtl=target;mtl.replace_extension(".mtl");std::string materialText;
  if(modelConverterFormat==1){
    if(std::filesystem::exists(mtl))throw std::runtime_error("The destination MTL already exists.");
    output="mtllib "+mtl.filename().u8string()+"\n"+output;
    for(size_t i=0;i<skins.size();i++)materialText+="newmtl surface"+std::to_string(i)+"\nKd 1 1 1\nmap_Kd "+(skinFolder/(std::to_string(i)+".tga")).lexically_relative(target.parent_path()).generic_u8string()+"\n";
  }
  std::filesystem::create_directories(target.parent_path());auto temp=target;temp+=".ftebroom-convert.tmp";
  if(std::filesystem::exists(temp))throw std::runtime_error("Conversion temporary file already exists.");
  bool ownedSkins=false;
  try{
    if(modelConverterFormat!=2){ownedSkins=std::filesystem::create_directory(skinFolder);if(!ownedSkins)throw std::runtime_error("Cannot create skin directory.");for(size_t i=0;i<skins.size();i++)soundWrite(skinFolder/(std::to_string(i)+".tga"),modelImportTga(skins[i]));}
    if(modelConverterFormat==1)soundWrite(mtl,materialText);soundWrite(temp,output);std::filesystem::rename(temp,target);
  }catch(...){std::error_code ec;std::filesystem::remove(temp,ec);if(modelConverterFormat==1)std::filesystem::remove(mtl,ec);if(ownedSkins){for(size_t i=0;i<skins.size();i++)std::filesystem::remove(skinFolder/(std::to_string(i)+".tga"),ec);std::filesystem::remove(skinFolder,ec);}throw;}
  command("fs_flush\n");modFilesRefresh=true;modelConverterMessage="Saved "+target.u8string()+". Source coordinates and origin retained (target-format quantization applies).";
}
static void modelConverterPanel() {
  if(modelImportJob.valid()&&modelImportJob.wait_for(std::chrono::seconds(0))==std::future_status::ready){
    auto error=modelImportJob.get();modelConverterPending=false;
    try{if(!error.empty())throw std::runtime_error(error);modelConverterSave(ftebroom::modelExport::parse(q1Read(modelImportStage/"model.mesh")));}catch(const std::exception& e){modelConverterMessage=e.what();}
  }else if(modelConverterPending&&!modelImportJob.valid()&&cvars->GetFloat("ftebroom_convert_status")!=0){
    modelConverterPending=false;
    try{
      if(cvars->GetFloat("ftebroom_convert_status")!=1)throw std::runtime_error("FTE could not extract this model. Check the source format, animation and companion files.");
      size_t length=0;auto data=(char*)files->LoadFile("data/model-convert.mesh",&length);if(!data)throw std::runtime_error("Model extraction output is missing.");
      if(length>128*1024*1024){core->Free(data);throw std::runtime_error("Model extraction exceeds 128 MiB.");}
      std::string bytes(data,length);core->Free(data);modelConverterSave(ftebroom::modelExport::parse(bytes));
    }catch(const std::exception& e){modelConverterMessage=e.what();}
  }
  if(!modelConverterOpen&&!modelConverterPending&&!modelImportQueue.empty()){
    auto request=modelImportQueue.front();modelImportQueue.erase(modelImportQueue.begin());
    modelConverterShow(request.source.u8string());modelImportExternal=request.source;modelImportProfile=request.profile;modelConverterFormat=request.profile==2?2:0;if(modelImportBridge(request.source))modelConverterSequence=1;
    auto folder=(modFilePacked(request.folder)||wadBrowseFolder(request.folder))?modFileRoot()/"models"/"converted":request.folder;
    auto target=folder/(request.source.stem().u8string()+modelConverterExtension());
    for(int i=1;std::filesystem::exists(target);i++)target=folder/(request.source.stem().u8string()+"-"+std::to_string(i)+modelConverterExtension());
    std::snprintf(modelConverterDestination,sizeof modelConverterDestination,"%s",target.u8string().c_str());
  }
  if(!modelConverterOpen)return;
  ImGui::SetNextWindowSize({720,520},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Convert model",modelConverterPending?nullptr:&modelConverterOpen)) {
    ImGui::TextWrapped("Source: %s",modelImportExternal.empty()?modelConverterSource.c_str():modelImportExternal.u8string().c_str());
    ImGui::BeginDisabled(modelConverterPending);
    if(modelImportProfile==1){int choice=modelConverterFormat==2?1:modelConverterFormat==1?2:0;if(ImGui::Combo("Target format",&choice,"MD3 (baked animation)\0Quake MDL (paletted skin)\0OBJ + MTL (static)\0")){modelConverterFormat=choice==1?2:choice==2?1:0;auto target=std::filesystem::u8path(modelConverterDestination);target.replace_extension(modelConverterExtension());std::snprintf(modelConverterDestination,sizeof modelConverterDestination,"%s",target.u8string().c_str());}}
    else ImGui::Text("Target: %s",modelImportProfile==2?"Quake MDL":"Quake III MD3");
    ImGui::InputText("Destination",modelConverterDestination,sizeof modelConverterDestination);
    bool bridge=!modelImportExternal.empty()&&modelImportBridge(modelImportExternal);
    if(bridge){modelImportFindBlender();ImGui::InputText("Blender executable",modelImportBlender,sizeof modelImportBlender);ImGui::TextWrapped("FBX / GLB / BLEND use Blender. SMD / DMX use bundled Blender Source Tools (Blender 4.1+). Blender units become map units; no centering or size normalization is applied.");}
    ImGui::InputInt(bridge?"First Blender frame":"Animation / sequence",&modelConverterSequence);
    if(!bridge)ImGui::TextDisabled("Use -1 for consecutive MDL / MD2 poses.");
    ImGui::SliderInt("Baked frames",&modelConverterFrames,1,1024);ImGui::SliderFloat("Sampling FPS",&modelConverterFPS,1,120,"%.0f");
    ImGui::TextWrapped("Bones, tags, events and skin variants are baked or lost. OBJ retains only the first pose. Diffuse textures are retained; shader effects, transparency, normal/roughness maps are not. Quake MDL uses a 256-pixel tile per material and the active game palette (no fullbright colours); positions have 8-bit precision per axis. MD3 coordinates must fit -512 to 511.984 units. Missing textures stop conversion. The source is never overwritten.");
    ImGui::Checkbox("I accept these conversion losses",&modelConverterAcceptLoss);
    ImGui::BeginDisabled(!modelConverterAcceptLoss);
    if(ImGui::Button("Bake and convert"))try{
      if(gameProfile!=modelImportProfile)throw std::runtime_error("The active game profile changed. Close and reopen this import.");
      auto path=std::filesystem::u8path(modelConverterDestination);modFileValidate(path);
      if(modFilePacked(path)||std::filesystem::exists(path)||entityLower(path.extension().u8string())!=modelConverterExtension())throw std::runtime_error("Choose a new loose file with the target format extension.");
      if(modelConverterFormat==2&&modelResource("gfx/palette.lmp").size()!=768)throw std::runtime_error("Load the Quake palette before converting to MDL.");
      if(bridge){
        if(!*modelImportBlender)throw std::runtime_error("Choose an installed Blender executable.");
        char script[4096]={};if(!files->NativePath("model-import-blender.py",(fs_relative)5,script,sizeof script))throw std::runtime_error("Blender import helper is missing.");
        modelImportStage=modelImportNewStage();
        std::ofstream(documentPath("model-import-blender.txt"))<<modelImportBlender;
        std::vector<std::string> args={modelImportBlender,"--background","--factory-startup","--disable-autoexec","--python",script,"--","--source",modelImportExternal.u8string(),"--output",modelImportStage.u8string(),"--frames",std::to_string(modelConverterFrames),"--start",std::to_string(modelConverterSequence),"--fps",std::to_string(modelConverterFPS)};
        auto output=modelImportStage;modelImportJob=std::async(std::launch::async,[args,output](){return modelImportRun(args,output);});
      }else{
        if(!modelImportExternal.empty()){
          modelImportStage=modelImportNewStage();auto name=modelImportExternal.filename();if(entityLower(name.extension().u8string())==".md5")name.replace_extension(".md5mesh");
          std::filesystem::copy_file(modelImportExternal,modelImportStage/name);
          if(entityLower(modelImportExternal.extension().u8string())==".mdl"&&q1Read(modelImportExternal).substr(0,4)=="IDST"){
            auto parent=modelImportExternal.parent_path();auto stem=modelImportExternal.stem().u8string();
            for(const auto& e:std::filesystem::directory_iterator(parent)){
              auto n=e.path().filename().u8string();auto lower=entityLower(n),prefix=entityLower(stem);
              if(e.is_regular_file()&&n!=name.u8string()&&lower.rfind(prefix,0)==0&&entityLower(e.path().extension().u8string())==".mdl"&&n.size()<=stem.size()+6&&e.file_size()<=128*1024*1024)std::filesystem::copy_file(e.path(),modelImportStage/e.path().filename());
            }
          }
          modelConverterSource=(modelImportStage/name).lexically_relative(modFileRoot()).generic_u8string();
        }
        cvars->SetString("ftebroom_convert_source",modelConverterSource.c_str());cvars->SetFloat("ftebroom_convert_sequence",std::max(-1,modelConverterSequence));cvars->SetFloat("ftebroom_convert_frames",modelConverterFrames);cvars->SetFloat("ftebroom_convert_fps",modelConverterFPS);cvars->SetFloat("ftebroom_convert_status",0);command("fs_flush\nftebroom_model_extract\n");
      }
      modelConverterPending=true;modelConverterMessage="Extracting model and textures...";
    }catch(const std::exception& e){modelConverterMessage=e.what();}
    ImGui::EndDisabled();ImGui::EndDisabled();
    if(modelConverterPending)ImGui::TextUnformatted("Conversion in progress. The editor remains usable.");
    if(!modelConverterMessage.empty())ImGui::TextWrapped("%s",modelConverterMessage.c_str());
  }ImGui::End();
}
