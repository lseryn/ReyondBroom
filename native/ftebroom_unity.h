// SPDX-License-Identifier: GPL-3.0-or-later
// Unity export is a one-way asset sync. Source maps and mod resources are read-only.
static bool unityOpen=false,unityWaiting=false,unitySeparate=true,unityTextures=true,unityColliders=false;
static float unityScale=.0254f;
static char unityFolder[4096]{};
static std::string unityMessage;
static std::vector<std::filesystem::path> unityDirectories;
static std::string unityBrowsePath,unityBrowseError;
static std::filesystem::path unityAssets,unityOutput;
static std::string unityJson(const std::string& text){
  std::ostringstream out;out<<'"';for(unsigned char c:text){if(c=='"'||c=='\\')out<<'\\'<<char(c);else if(c<32)out<<"\\u"<<std::hex<<std::setw(4)<<std::setfill('0')<<int(c)<<std::dec;else out<<char(c);}out<<'"';return out.str();
}
static std::string unityId(const std::string& value){uint64_t h=14695981039346656037ull;for(unsigned char c:value){h^=c;h*=1099511628211ull;}std::ostringstream out;out<<std::hex<<h;return "material_"+out.str();}
static std::string unityRead(const std::filesystem::path& path,size_t limit=134217728){std::ifstream in(path,std::ios::binary);if(!in)throw std::runtime_error("Cannot read "+path.u8string());auto size=std::filesystem::file_size(path);if(size>limit)throw std::runtime_error("Unity export file exceeds its size budget.");return std::string(std::istreambuf_iterator<char>(in),{});}
static std::string unityResource(const std::string& name){size_t size=0;char* data=(char*)files->LoadFile(name.c_str(),&size);if(!data)return {};std::string result;if(size<=67108864)result.assign(data,size);core->Free(data);return result;}
static void unityResolve(const std::filesystem::path& chosen,std::filesystem::path& assets,std::filesystem::path& output){
  auto path=std::filesystem::canonical(chosen);if(!std::filesystem::is_directory(path))throw std::runtime_error("Choose a Unity project or a directory inside Assets.");
  assets.clear();if(std::filesystem::is_directory(path/"Assets"))assets=path/"Assets";
  else for(auto parent=path;!parent.empty();parent=parent.parent_path()){if(parent.filename()=="Assets"){assets=parent;break;}if(parent==parent.root_path())break;}
  if(assets.empty())throw std::runtime_error("The chosen directory is not in a Unity Assets folder.");
  auto root=path==assets.parent_path()?assets:path;std::string name=documentName.empty()?"Map":documentName;
  for(char& c:name)if(!std::isalnum((unsigned char)c)&&c!='-'&&c!='_')c='_';if(name.empty())name="Map";
  output=root/("ReyondBroom_"+name);
  if(std::filesystem::exists(output)&&!std::filesystem::is_empty(output)&&!std::filesystem::exists(output/"map.ftebroom.json"))throw std::runtime_error("Destination exists and is not an ReyondBroom export. Choose another folder or map name.");
}
static void unityCheckPath(const std::filesystem::path& path){
  auto relative=path.lexically_relative(unityAssets);if(relative.empty()||*relative.begin()=="..")throw std::runtime_error("Export path leaves Assets.");
  auto current=unityAssets;for(const auto& part:relative){current/=part;if(std::filesystem::is_symlink(current))throw std::runtime_error("Unity export cannot replace files through symbolic links.");}
}
static void unityShow(){
  static bool loaded=false;if(!loaded){loaded=true;std::ifstream input(documentPath("data/ftebroom-unity-settings.txt"));std::string folder;if(std::getline(input,folder))std::snprintf(unityFolder,sizeof unityFolder,"%s",folder.c_str());input>>unitySeparate>>unityTextures>>unityColliders>>unityScale;}
  unityOpen=true;
}
static void unityStart(){
  try{
    if(unityWaiting)return;if(!std::isfinite(unityScale)||unityScale<=0||unityScale>1000)throw std::runtime_error("Scale must be greater than zero and at most 1000.");
    unityResolve(std::filesystem::u8path(unityFolder),unityAssets,unityOutput);
    std::filesystem::create_directories(documentPath("data"));std::ofstream saved(documentPath("data/ftebroom-unity-settings.txt"));saved<<unityFolder<<'\n'<<unitySeparate<<' '<<unityTextures<<' '<<unityColliders<<' '<<unityScale<<'\n';
    unityMessage="Exporting map geometry...";cvars->SetFloat("ftebroom_unity_status",0);unityWaiting=true;command("ftebroom_export_unity\n");
  }catch(const std::exception& e){unityMessage=e.what();}
}
static std::string unityTexture(const MaterialEntry& material){
  std::vector<std::string> names;if(!material.preview.empty())names.push_back(material.preview);names.push_back(material.name);if(material.name.rfind("textures/",0)!=0)names.push_back("textures/"+material.name);
  for(const auto& base:names)for(const auto& suffix:{"",".tga",".png",".jpg",".jpeg",".bmp"}){
    auto bytes=unityResource(base+suffix);if(bytes.empty())continue;int w=0,h=0,channels=0;
    if(!stbi_info_from_memory((const stbi_uc*)bytes.data(),bytes.size(),&w,&h,&channels)||w<=0||h<=0||size_t(w)*h>16777216)continue;
    auto pixels=stbi_load_from_memory((const stbi_uc*)bytes.data(),bytes.size(),&w,&h,&channels,4);if(!pixels)continue;
    std::string tga(18+size_t(w)*h*4,0);tga[2]=2;tga[12]=w&255;tga[13]=w>>8;tga[14]=h&255;tga[15]=h>>8;tga[16]=32;tga[17]=40;
    for(size_t i=0;i<size_t(w)*h;i++){tga[18+i*4]=pixels[i*4+2];tga[19+i*4]=pixels[i*4+1];tga[20+i*4]=pixels[i*4];tga[21+i*4]=pixels[i*4+3];}stbi_image_free(pixels);return tga;
  }return {};
}
static void unityFinish(){
  if(!unityWaiting||!cvars->GetFloat("ftebroom_unity_status"))return;unityWaiting=false;
  std::filesystem::path stage,lock;std::vector<std::pair<std::filesystem::path,std::filesystem::path>> backups;std::vector<std::filesystem::path> installed;
  try{
    if(cvars->GetFloat("ftebroom_unity_status")!=1)throw std::runtime_error("Map geometry export failed.");
    std::map<std::filesystem::path,std::string> output;
    auto obj=unityRead(documentPath("data/unity.obj"));if(obj.find("\nf ")==std::string::npos)throw std::runtime_error("No brush or patch geometry to export.");output[unityOutput/"map.obj"]=obj;
    output[unityOutput/"export.mtl"]=unityRead(documentPath("data/unity.mtl"));
    std::ifstream list(documentPath("data/unity-materials.txt"));if(!list)throw std::runtime_error("Missing exported material list.");
    std::ostringstream manifest;manifest.imbue(std::locale::classic());manifest<<"{\"version\":1,\"mesh\":\"map.obj\",\"separate\":"<<(unitySeparate?"true":"false")<<",\"colliders\":"<<(unityColliders?"true":"false")<<",\"scale\":"<<unityScale<<",\"materials\":[";
    std::string id,name;int count=0,missing=0,shaders=0;size_t bytes=obj.size();
    while(list>>id>>std::quoted(name)){
      if(++count>4096)throw std::runtime_error("More than 4096 materials in export.");auto stable=unityId(name);std::string texture;
      if(unityTextures){auto found=materials.find(name);if(found==materials.end())found=materials.find("textures/"+name);MaterialEntry material=found==materials.end()?MaterialEntry{name,name,false}:found->second;auto pixels=unityTexture(material);if(pixels.empty())++missing;else{texture="Textures/"+stable+".tga";bytes+=pixels.size();if(bytes>268435456)throw std::runtime_error("Unity export exceeds 256 MiB. Export fewer textures or smaller images.");output[unityOutput/std::filesystem::u8path(texture)]=std::move(pixels);}if(material.shader)++shaders;}
      if(count>1)manifest<<',';manifest<<"{\"id\":"<<unityJson(id)<<",\"name\":"<<unityJson(name)<<",\"file\":"<<unityJson(stable)<<",\"texture\":"<<unityJson(texture)<<'}';
    }
    manifest<<"]}\n";if(!count)throw std::runtime_error("No exported materials.");
    for(const char* file:{"ReyondBroomObj.cs","ReyondBroomSync.cs"}){
      auto path=unityAssets/"ReyondBroomEditor"/"Editor"/file;auto code=unityResource(std::string("unity/")+file);if(code.empty())throw std::runtime_error("Missing bundled Unity bridge source.");
      if(std::filesystem::exists(path)&&unityRead(path,1048576).rfind("// ReyondBroom managed Unity bridge v1",0)!=0)throw std::runtime_error("Unity bridge path contains an unrelated file: "+path.u8string());if(!std::filesystem::exists(path)||unityRead(path,1048576)!=code)output[path]=code;
    }
    // Stage all data first; publish the manifest last. The Unity importer waits on the lock.
    unityCheckPath(unityOutput);std::filesystem::create_directories(unityOutput);stage=unityOutput/(".ftebroom-stage-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));std::filesystem::create_directory(stage);
    unityCheckPath(unityOutput);for(const auto& item:output)unityCheckPath(item.first);
    int index=0;for(const auto& item:output){std::ofstream file(stage/std::to_string(index++),std::ios::binary);file.write(item.second.data(),item.second.size());file.close();if(!file)throw std::runtime_error("Cannot stage Unity asset.");}
    lock=unityOutput/".ftebroom-lock";{std::ofstream file(lock);file<<"ReyondBroom Sync\n";if(!file)throw std::runtime_error("Cannot lock Unity export.");}
    auto install=[&](const std::filesystem::path& source,const std::filesystem::path& target){std::filesystem::create_directories(target.parent_path());if(std::filesystem::exists(target)){auto backup=stage/("backup-"+std::to_string(backups.size()));std::filesystem::rename(target,backup);backups.push_back({target,backup});}std::filesystem::rename(source,target);installed.push_back(target);};
    index=0;for(const auto& item:output)install(stage/std::to_string(index++),item.first);
    auto manifestFile=stage/"manifest";{std::ofstream file(manifestFile);file<<manifest.str();file.close();if(!file)throw std::runtime_error("Cannot write Unity manifest.");}install(manifestFile,unityOutput/"map.ftebroom.json");
    std::error_code cleanup;std::filesystem::remove(lock,cleanup);lock.clear();std::filesystem::remove_all(stage,cleanup);stage.clear();
    unityMessage="Exported to "+unityOutput.u8string()+". Unity will create Prefabs/Map.prefab. Missing texture previews: "+std::to_string(missing)+"; Quake shader previews baked as static images: "+std::to_string(shaders)+". Gameplay entities are not Unity components.";
    core->Print(("ReyondBroom Unity Sync: "+unityMessage+"\n").c_str());
  }catch(const std::exception& e){
    std::error_code error;bool restored=true;for(auto it=installed.rbegin();it!=installed.rend();++it){std::filesystem::remove(*it,error);if(error)restored=false;}
    for(auto it=backups.rbegin();it!=backups.rend();++it){std::filesystem::rename(it->second,it->first,error);if(error)restored=false;}
    if(!lock.empty())std::filesystem::remove(lock,error);if(restored&&!stage.empty())std::filesystem::remove_all(stage,error);unityMessage=e.what();if(!restored)unityMessage+=". Recovery copies retained in "+stage.u8string();
  }
}
static void unityPanel(){
  unityFinish();if(!unityOpen)return;ImGui::SetNextWindowSize({600*uiScale(),0},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Unity Sync",&unityOpen)){
    ImGui::BeginDisabled(unityWaiting);ImGui::InputText("Project / Assets folder",unityFolder,sizeof unityFolder);
    if(ImGui::CollapsingHeader("Browse folders")){
      auto path=*unityFolder?std::filesystem::u8path(unityFolder):documentDefaultFolder();
      if(ImGui::Button("Up")){path=path.parent_path();std::snprintf(unityFolder,sizeof unityFolder,"%s",path.u8string().c_str());}
      ImGui::SameLine();if(ImGui::Button("Refresh"))unityBrowsePath.clear();
      if(unityBrowsePath!=path.u8string()){
        unityBrowsePath=path.u8string();unityDirectories.clear();unityBrowseError.clear();
        try{for(const auto& item:std::filesystem::directory_iterator(path))if(item.is_directory())unityDirectories.push_back(item.path());std::sort(unityDirectories.begin(),unityDirectories.end());}
        catch(const std::exception& e){unityBrowseError=e.what();}
      }
      ImGui::BeginChild("Unity folders",{0,130*uiScale()},ImGuiChildFlags_Borders);
      ImGuiListClipper clipper;clipper.Begin(unityDirectories.size());while(clipper.Step())for(int i=clipper.DisplayStart;i<clipper.DisplayEnd;i++){const auto& dir=unityDirectories[i];if(ImGui::Selectable(dir.filename().u8string().c_str()))std::snprintf(unityFolder,sizeof unityFolder,"%s",dir.u8string().c_str());}
      ImGui::EndChild();if(!unityBrowseError.empty())ImGui::TextWrapped("%s",unityBrowseError.c_str());
    }
    ImGui::Checkbox("Separate brush / patch objects",&unitySeparate);ImGui::Checkbox("Copy texture previews",&unityTextures);ImGui::Checkbox("Add mesh colliders",&unityColliders);ImGui::InputFloat("World unit scale",&unityScale,.001f,.01f,"%.5f");
    ImGui::TextWrapped("Exports into a dedicated ReyondBroom_<map> folder. Re-sync replaces generated geometry and prefab contents. Quake shader animation and game entity behavior are not Unity components.");
    if(ImGui::Button("Sync"))unityStart();ImGui::EndDisabled();if(!unityMessage.empty())ImGui::TextWrapped("%s",unityMessage.c_str());
  }ImGui::End();
}
