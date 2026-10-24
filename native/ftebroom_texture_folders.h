// SPDX-License-Identifier: GPL-2.0-or-later
// Folder compilation runs outside the render thread; publication and FTE mounts stay on it.
struct TextureFolderSpec {std::string source,palette;};
struct TextureFolderResult {std::string wad,names;int count=0;};
static std::vector<TextureFolderSpec> textureFolders,textureFolderQueue;
static std::future<TextureFolderResult> textureFolderJob;
static std::atomic<int> textureFolderProgress{0},textureFolderTotal{0};
static std::atomic<bool> textureFolderCancel{false};
static bool textureFolderOpen=false,textureFolderBrowsePalette=false;
static char textureFolderSource[4096]{},textureFolderPalette[4096]{};
static TextureFolderSpec textureFolderPending;
static std::string textureFolderMessage,textureFolderColors,textureFolderBrowser,textureFolderScanned,textureFolderBrowserError;
static std::vector<std::pair<std::filesystem::path,bool>> textureFolderEntries;
static std::string textureFolderRead(const std::filesystem::path& path,size_t limit){
  std::ifstream input(path,std::ios::binary);if(!input)throw std::runtime_error("Cannot read "+path.u8string());
  if(std::filesystem::file_size(path)>limit)throw std::runtime_error("File exceeds import size limit: "+path.u8string());
  return {std::istreambuf_iterator<char>(input),{}};
}
static std::string textureFolderLoadPalette(const std::filesystem::path& path){
  auto bytes=textureFolderRead(path,16777216);if(bytes.size()==768)return bytes;
  if(bytes.size()>=897&&(unsigned char)bytes[0]==10&&(unsigned char)bytes[3]==8&&(unsigned char)bytes[65]==1&&(unsigned char)bytes[bytes.size()-769]==12)return bytes.substr(bytes.size()-768);
  if(bytes.size()>=54&&bytes.substr(0,2)=="BM"){
    auto word=[&](size_t at){return ftebroom::quake1::word(bytes,at);};
    auto header=word(14);if(header>=40&&header<=4096&&(unsigned char)bytes[28]==8&&bytes[29]==0&&(word(46)==0||word(46)==256)&&bytes.size()>=14+header+1024&&word(10)>=14+header+1024){
      std::string palette(768,0);for(int i=0;i<256;i++)for(int c=0;c<3;c++)palette[i*3+c]=bytes[14+header+i*4+2-c];return palette;
    }
  }throw std::runtime_error("Choose a 768-byte LMP palette, 256-color PCX or 8-bit BMP palette.");
}
static void textureFoldersSave(){
  std::filesystem::create_directories(documentPath("data"));std::ofstream output(documentPath("data/ftebroom-texture-folders.txt"));
  for(const auto& entry:textureFolders)output<<std::quoted(entry.source)<<' '<<std::quoted(entry.palette)<<'\n';if(!output)throw std::runtime_error("Cannot save texture folder settings.");
}
static void textureFolderShow(){
  static bool loaded=false;if(!loaded){loaded=true;std::ifstream input(documentPath("data/ftebroom-texture-folders.txt"));TextureFolderSpec entry;while(textureFolders.size()<128&&input>>std::quoted(entry.source)>>std::quoted(entry.palette))textureFolders.push_back(entry);}
  textureFolderOpen=true;
}
static TextureFolderResult textureFolderCompile(const std::filesystem::path& source,const std::string& palette){
  std::vector<std::filesystem::path> images;
  for(const auto& item:std::filesystem::recursive_directory_iterator(source)){
    if(textureFolderCancel)throw std::runtime_error("Texture folder compilation cancelled.");
    if(item.is_symlink())continue;if(!item.is_regular_file())continue;
    auto ext=entityLower(item.path().extension().u8string());
    if(ext==".png"||ext==".jpg"||ext==".jpeg"||ext==".tga"||ext==".bmp")images.push_back(item.path());
    if(images.size()>1024)throw std::runtime_error("A texture folder may contain at most 1024 images.");
  }
  if(images.empty())throw std::runtime_error("No PNG, JPEG, TGA or BMP images in this folder.");std::sort(images.begin(),images.end());textureFolderTotal=images.size();
  TextureFolderResult result;result.wad="WAD2";result.wad.resize(12,0);std::string directory;std::set<std::string> used;
  auto put=[](std::string& bytes,size_t at,uint32_t value){for(int i=0;i<4;i++)bytes[at+i]=char(value>>(i*8));};
  for(const auto& path:images){
    if(textureFolderCancel)throw std::runtime_error("Texture folder compilation cancelled.");
    auto relative=path.lexically_relative(source).generic_u8string(),name=entityLower(path.stem().u8string());
    for(char& c:name)if(!((c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='_'||c=='-'||c=='*'||c=='+'||c=='{'))c='_';
    if(name.empty())name="texture";
    if(name.size()>15||path.parent_path()!=source)name=name.substr(0,8)+"_"+unityId(relative).substr(9,6);
    if(!used.insert(name).second)throw std::runtime_error("Duplicate WAD texture name: "+name+". Rename one source image.");
    if(std::filesystem::file_size(path)>67108864)throw std::runtime_error("Source image exceeds 64 MiB: "+relative);
    auto texture=importDecode(path,palette,name,true,&textureFolderCancel);auto single=ftebroom::addWadTexture({},std::move(texture),palette,true);
    auto table=ftebroom::quake1::word(single,8),offset=ftebroom::quake1::word(single,table),length=ftebroom::quake1::word(single,table+4);
    auto row=single.substr(table,32);put(row,0,result.wad.size());directory+=row;result.wad.append(single,offset,length);
    if(result.wad.size()+directory.size()>134217728)throw std::runtime_error("Compiled WAD exceeds 128 MiB.");
    result.names+=name+"\t"+relative+"\n";textureFolderProgress=++result.count;
  }
  put(result.wad,4,result.count);put(result.wad,8,result.wad.size());result.wad+=directory;return result;
}
static void textureFolderStart(){
  try{
    if(textureFolderJob.valid())return;if(gameProfile!=2)throw std::runtime_error("Compile WAD texture folders require the Quake 1 profile.");
    auto source=std::filesystem::canonical(std::filesystem::u8path(textureFolderSource));if(!std::filesystem::is_directory(source))throw std::runtime_error("Choose a source image folder.");
    textureFolderColors=*textureFolderPalette?textureFolderLoadPalette(std::filesystem::u8path(textureFolderPalette)):modelResource("gfx/palette.lmp");
    if(textureFolderColors.size()!=768){textureFolderColors.clear();throw std::runtime_error("Load game resources or choose an export palette first.");}
    textureFolderPending={source.u8string(),textureFolderPalette};textureFolderProgress=0;textureFolderTotal=0;textureFolderCancel=false;textureFolderMessage="Reading source images...";
    textureFolderJob=std::async(std::launch::async,[source,palette=textureFolderColors](){return textureFolderCompile(source,palette);});
  }catch(const std::exception& e){textureFolderMessage=e.what();}
}
static void textureFolderNext(){
  if(textureFolderQueue.empty())return;auto entry=textureFolderQueue.front();textureFolderQueue.erase(textureFolderQueue.begin());
  std::snprintf(textureFolderSource,sizeof textureFolderSource,"%s",entry.source.c_str());std::snprintf(textureFolderPalette,sizeof textureFolderPalette,"%s",entry.palette.c_str());textureFolderStart();if(!textureFolderJob.valid())textureFolderQueue.clear();
}
static void textureFolderFinish(){
  if(!textureFolderJob.valid()||textureFolderJob.wait_for(std::chrono::seconds(0))!=std::future_status::ready)return;
  try{
    auto result=textureFolderJob.get();if(textureFolderCancel)throw std::runtime_error("Texture folder compilation cancelled.");
    auto folder=documentPath("data/texture-folder-wads");std::filesystem::create_directories(folder);
    auto target=folder/(unityId(textureFolderPending.source)+".wad"),temporary=target;temporary+=".tmp";
    if(std::filesystem::is_symlink(target)||std::filesystem::is_symlink(temporary))throw std::runtime_error("Cannot replace a linked WAD path.");
    {std::ofstream file(temporary,std::ios::binary);file.write(result.wad.data(),result.wad.size());file.close();if(!file)throw std::runtime_error("Cannot write compiled WAD.");}
    auto backup=target;backup+=".previous";if(std::filesystem::is_symlink(backup))throw std::runtime_error("Cannot replace a linked WAD backup.");if(std::filesystem::exists(target))std::filesystem::copy_file(target,backup,std::filesystem::copy_options::overwrite_existing);
#ifdef _WIN32
    if(!MoveFileExW(temporary.c_str(),target.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))throw std::runtime_error("Cannot publish compile WAD; previous output is preserved.");
#else
    std::filesystem::rename(temporary,target);
#endif
    std::ofstream(target.u8string()+".names.txt")<<result.names;
    auto found=std::find_if(textureFolders.begin(),textureFolders.end(),[](const auto& entry){return entry.source==textureFolderPending.source;});if(found==textureFolders.end()){if(textureFolders.size()>=128)throw std::runtime_error("Texture folder settings limit reached.");textureFolders.push_back(textureFolderPending);}else *found=textureFolderPending;
    textureFoldersSave();if(gameProfile==2)importAddWads({target});
    textureFolderMessage="Compiled "+std::to_string(result.count)+" textures into "+target.u8string()+". Rebuild after editing source images. The name mapping is saved beside the WAD.";
    if(gameProfile!=2)textureFolderMessage+=" Switch to Quake 1 and add this WAD to use it.";
    core->Print(("FTEBroom texture folder: "+textureFolderMessage+"\n").c_str());textureFolderNext();
  }catch(const std::exception& e){textureFolderMessage=e.what();textureFolderQueue.clear();}
}
static void textureFolderPanel(){
  textureFolderFinish();if(!textureFolderOpen)return;auto viewport=ImGui::GetMainViewport();ImGui::SetNextWindowSize({std::min(650*uiScale(),viewport->WorkSize.x-24),std::min(620*uiScale(),viewport->WorkSize.y-32)},ImGuiCond_FirstUseEver);ImGui::SetNextWindowPos({viewport->WorkPos.x+viewport->WorkSize.x*.5f,viewport->WorkPos.y+viewport->WorkSize.y*.5f},ImGuiCond_FirstUseEver,{.5f,.5f});
  if(ImGui::Begin("Texture folders / compile WAD",&textureFolderOpen)){
    bool running=textureFolderJob.valid();ImGui::BeginDisabled(running);
    ImGui::InputText("Source folder",textureFolderSource,sizeof textureFolderSource);ImGui::SameLine();if(ImGui::SmallButton("Browse##source")){textureFolderBrowsePalette=false;textureFolderBrowser=*textureFolderSource?textureFolderSource:documentDefaultFolder().u8string();textureFolderScanned.clear();}
    ImGui::InputText("Palette (optional)",textureFolderPalette,sizeof textureFolderPalette);ImGui::SameLine();if(ImGui::SmallButton("Browse##palette")){textureFolderBrowsePalette=true;textureFolderBrowser=*textureFolderPalette?std::filesystem::u8path(textureFolderPalette).parent_path().u8string():documentDefaultFolder().u8string();textureFolderScanned.clear();}
    if(ImGui::SmallButton("Use active game palette")){textureFolderPalette[0]=0;textureFolderColors=modelResource("gfx/palette.lmp");if(textureFolderColors.size()!=768)textureFolderColors.clear();}
    ImGui::SameLine();if(ImGui::SmallButton("Preview palette"))try{textureFolderColors=*textureFolderPalette?textureFolderLoadPalette(std::filesystem::u8path(textureFolderPalette)):modelResource("gfx/palette.lmp");if(textureFolderColors.size()!=768){textureFolderColors.clear();throw std::runtime_error("Load game resources or choose a palette.");}}catch(const std::exception& e){textureFolderColors.clear();textureFolderMessage=e.what();}
    if(!textureFolderBrowser.empty()){
      if(ImGui::SmallButton("Up##texturefolder"))textureFolderBrowser=std::filesystem::u8path(textureFolderBrowser).parent_path().u8string();ImGui::SameLine();if(ImGui::SmallButton("Refresh##texturefolder"))textureFolderScanned.clear();ImGui::SameLine();if(ImGui::SmallButton("Close browser"))textureFolderBrowser.clear();
      if(!textureFolderBrowsePalette&&ImGui::SmallButton("Use this folder")){std::snprintf(textureFolderSource,sizeof textureFolderSource,"%s",textureFolderBrowser.c_str());textureFolderBrowser.clear();}
      if(textureFolderScanned!=textureFolderBrowser){textureFolderScanned=textureFolderBrowser;textureFolderEntries.clear();textureFolderBrowserError.clear();try{if(!textureFolderBrowser.empty())for(const auto& item:std::filesystem::directory_iterator(std::filesystem::u8path(textureFolderBrowser))){auto ext=entityLower(item.path().extension().u8string());bool dir=item.is_directory();if(dir||(textureFolderBrowsePalette&&(ext==".lmp"||ext==".pcx"||ext==".bmp")))textureFolderEntries.push_back({item.path(),dir});}std::sort(textureFolderEntries.begin(),textureFolderEntries.end(),[](const auto& a,const auto& b){return a.second!=b.second?a.second>b.second:a.first<b.first;});}catch(const std::exception& e){textureFolderBrowserError=e.what();}}
      ImGui::TextWrapped("%s",textureFolderBrowser.c_str());ImGui::BeginChild("Folder entries",{0,140*uiScale()},ImGuiChildFlags_Borders);ImGuiListClipper clipper;clipper.Begin(textureFolderEntries.size());while(clipper.Step())for(int i=clipper.DisplayStart;i<clipper.DisplayEnd;i++){const auto& entry=textureFolderEntries[i];auto label=(entry.second?"[Folder] ":"")+entry.first.filename().u8string();if(ImGui::Selectable(label.c_str())){if(entry.second)textureFolderBrowser=entry.first.u8string();else{std::snprintf(textureFolderPalette,sizeof textureFolderPalette,"%s",entry.first.u8string().c_str());textureFolderBrowser.clear();}}}ImGui::EndChild();if(!textureFolderBrowserError.empty())ImGui::TextWrapped("%s",textureFolderBrowserError.c_str());
    }
    if(ImGui::BeginCombo("Registered folders",textureFolderSource)){for(const auto& entry:textureFolders)if(ImGui::Selectable(entry.source.c_str())){std::snprintf(textureFolderSource,sizeof textureFolderSource,"%s",entry.source.c_str());std::snprintf(textureFolderPalette,sizeof textureFolderPalette,"%s",entry.palette.c_str());}ImGui::EndCombo();}
    ImGui::TextWrapped("Recursively imports PNG/JPEG/TGA/BMP into a generated WAD2. Source dimensions are retained when divisible by 16, otherwise rounded up; maximum 4096 per axis. All palette colors, including fullbright colors, are available. Names starting with { preserve cutout transparency. Four mip levels use the chosen palette. The palette must match the game's palette. Rebuild replaces this folder's generated WAD, with one previous copy retained.");
    if(ImGui::Button("Import / rebuild folder"))textureFolderStart();ImGui::SameLine();ImGui::BeginDisabled(textureFolders.empty());if(ImGui::Button("Rebuild all registered folders")){textureFolderQueue=textureFolders;textureFolderNext();}ImGui::EndDisabled();ImGui::EndDisabled();
    if(running){auto total=textureFolderTotal.load();ImGui::ProgressBar(total?float(textureFolderProgress.load())/total:0);if(ImGui::Button("Cancel compilation")){textureFolderCancel=true;textureFolderQueue.clear();}}
    if(textureFolderColors.size()==768){auto pos=ImGui::GetCursorScreenPos();float cell=9*uiScale();auto draw=ImGui::GetWindowDrawList();for(int i=0;i<256;i++){auto p=pos;p.x+=(i%32)*cell;p.y+=(i/32)*cell;draw->AddRectFilled(p,{p.x+cell,p.y+cell},IM_COL32((unsigned char)textureFolderColors[i*3],(unsigned char)textureFolderColors[i*3+1],(unsigned char)textureFolderColors[i*3+2],255));}ImGui::Dummy({32*cell,8*cell});}
    if(!textureFolderMessage.empty())ImGui::TextWrapped("%s",textureFolderMessage.c_str());
  }ImGui::End();
}
