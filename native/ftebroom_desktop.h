// SPDX-License-Identifier: GPL-2.0-or-later
#include <climits>
#include "ftebroom_wad_import.h"
#include "ftebroom_tga.h"
static bool materialDropVisible=false;
static void importAddWads(const std::vector<std::filesystem::path>& paths){
 if(paths.empty())return;
 if(gameProfile!=2)throw std::runtime_error("Select the Quake 1 profile to use WAD materials.");std::string list=q1Wads;
 for(const auto& path:paths){ftebroom::quake1::wad(q1Read(path));auto value=path.generic_u8string();if(value.find_first_of("\r\n;\"")!=value.npos)throw std::runtime_error("Unsupported WAD path.");if(list.find(value)==list.npos){if(!list.empty())list+='\n';list+=value;}}
 if(list.size()>=sizeof q1Wads)throw std::runtime_error("Too many WAD paths.");std::snprintf(q1Wads,sizeof q1Wads,"%s",list.c_str());if(!gameProfileSave())throw std::runtime_error("Cannot save WAD settings.");mountAssets();
}
#ifdef _WIN32
#include <commdlg.h>
#include <shellapi.h>
#include <shlobj.h>
#include <wincodec.h>
#undef LoadImage
static HWND desktopHost;static WNDPROC desktopPrevious;
static std::vector<std::filesystem::path> desktopDrops;
struct DesktopFileDrop {std::filesystem::path path,folder;ImVec2 point;bool scene;};
static std::vector<DesktopFileDrop> desktopFileDrops;
static ImVec2 materialDropMin,materialDropMax;
static std::string importError;static std::vector<std::filesystem::path> importImages;
static char importWad[4096]={},importName[16]={};static bool importRequest=false;static bool importWindow=false;static std::string importNotice;
static BOOL CALLBACK desktopFind(HWND h,LPARAM){DWORD pid=0;GetWindowThreadProcessId(h,&pid);if(pid==GetCurrentProcessId()&&IsWindowVisible(h)&&!GetWindow(h,GW_OWNER)){desktopHost=h;return FALSE;}return TRUE;}
static LRESULT CALLBACK desktopProc(HWND h,UINT message,WPARAM w,LPARAM l){
 if(message==WM_SETCURSOR&&LOWORD(l)==HTCLIENT&&ready&&!sceneLook&&!modCaptured){
  auto cursor=ImGui::GetMouseCursor();LPCSTR id=nullptr;
  switch(cursor){case ImGuiMouseCursor_ResizeNS:id=IDC_SIZENS;break;case ImGuiMouseCursor_ResizeEW:id=IDC_SIZEWE;break;case ImGuiMouseCursor_ResizeNESW:id=IDC_SIZENESW;break;case ImGuiMouseCursor_ResizeNWSE:id=IDC_SIZENWSE;break;case ImGuiMouseCursor_ResizeAll:id=IDC_SIZEALL;break;case ImGuiMouseCursor_TextInput:id=IDC_IBEAM;break;case ImGuiMouseCursor_Hand:id=IDC_HAND;break;default:break;}
  if(id){SetCursor(LoadCursorA(nullptr,id));return TRUE;}
 }
 if(message==WM_DROPFILES){auto drop=(HDROP)w;if(modEmbedded){importError="Return to map editing before importing resources.";DragFinish(drop);return 0;}POINT point;DragQueryPoint(drop,&point);RECT rect;GetClientRect(h,&rect);auto size=ImGui::GetIO().DisplaySize;ImVec2 p{point.x*size.x/std::max(1L,rect.right),point.y*size.y/std::max(1L,rect.bottom)};
  bool over=materialDropVisible&&p.x>=materialDropMin.x&&p.y>=materialDropMin.y&&p.x<materialDropMax.x&&p.y<materialDropMax.y;
  for(UINT i=0,count=DragQueryFileW(drop,0xffffffff,nullptr,0);i<count;i++){UINT n=DragQueryFileW(drop,i,nullptr,0);std::wstring name(n+1,0);DragQueryFileW(drop,i,name.data(),n+1);name.resize(n);auto path=std::filesystem::path(name);auto ext=path.extension().u8string();std::transform(ext.begin(),ext.end(),ext.begin(),::tolower);bool manager=modFilesVisible&&p.x>=modFilesMin.x&&p.y>=modFilesMin.y&&p.x<modFilesMax.x&&p.y<modFilesMax.y;
  if(manager)desktopFileDrops.push_back({path,modFilesFolder,p,false});
  else if(ext==".mdl"||ext==".md3"||ext==".md2"||ext==".iqm")desktopFileDrops.push_back({path,{},p,viewHit(p.x,p.y)>=0&&!over&&!uiBlocksScene(p.x,p.y)});
  else if(ext==".wad"||over)desktopDrops.push_back(path);else importError="Drop images onto the Material / texture browser panel.";}
  DragFinish(drop);return 0;
 }
 return CallWindowProcW(desktopPrevious,h,message,w,l);
}
static void desktopAttach(){if(!desktopHost){EnumWindows(desktopFind,0);if(desktopHost){desktopPrevious=(WNDPROC)SetWindowLongPtrW(desktopHost,GWLP_WNDPROC,(LONG_PTR)desktopProc);DragAcceptFiles(desktopHost,TRUE);ImGui::GetIO().BackendFlags|=ImGuiBackendFlags_HasMouseCursors;}}}
static void desktopDetach(){if(desktopHost&&desktopPrevious&&IsWindow(desktopHost))SetWindowLongPtrW(desktopHost,GWLP_WNDPROC,(LONG_PTR)desktopPrevious);desktopHost=nullptr;desktopPrevious=nullptr;}
static std::vector<std::filesystem::path> importPick(bool save){
 std::vector<wchar_t> buffer(65536);OPENFILENAMEW dialog{};dialog.lStructSize=sizeof dialog;dialog.hwndOwner=desktopHost;dialog.lpstrFile=buffer.data();dialog.nMaxFile=buffer.size();dialog.lpstrFilter=L"Quake WAD2 (*.wad)\0*.wad\0\0";dialog.lpstrDefExt=L"wad";dialog.Flags=OFN_EXPLORER|OFN_NOCHANGEDIR|OFN_PATHMUSTEXIST|(save?0:OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT);
 if(!(save?GetSaveFileNameW(&dialog):GetOpenFileNameW(&dialog)))return {};
 std::vector<std::filesystem::path> result;std::filesystem::path first(buffer.data());auto at=std::wcslen(buffer.data())+1;if(!buffer[at])result.push_back(first);else while(buffer[at]){result.push_back(first/std::filesystem::path(buffer.data()+at));at+=std::wcslen(buffer.data()+at)+1;}return result;
}
template<class T> struct ImportCom{T* p=nullptr;~ImportCom(){if(p)p->Release();}};
static ftebroom::quake1::Texture importDecode(const std::filesystem::path& path,const std::string& palette){
 if(palette.size()!=768)throw std::runtime_error("Load Quake resources with gfx/palette.lmp first.");
 HRESULT init=CoInitializeEx(nullptr,COINIT_APARTMENTTHREADED);struct Uninit{bool own;~Uninit(){if(own)CoUninitialize();}} cleanup{SUCCEEDED(init)};
 auto check=[](HRESULT hr){if(FAILED(hr))throw std::runtime_error("Cannot decode image. Use PNG, JPEG, BMP, GIF, TIFF or TGA.");};
 ImportCom<IWICImagingFactory> factory;check(CoCreateInstance(CLSID_WICImagingFactory,nullptr,CLSCTX_INPROC_SERVER,IID_IWICImagingFactory,(void**)&factory.p));
 ImportCom<IWICBitmapDecoder> decoder;ImportCom<IWICBitmapFrameDecode> frame;ImportCom<IWICBitmap> tgaBitmap;IWICBitmapSource* source=nullptr;
 auto extension=path.extension().u8string();std::transform(extension.begin(),extension.end(),extension.begin(),::tolower);
 if(extension==".tga"){auto image=ftebroom::readTga(q1Read(path));check(factory.p->CreateBitmapFromMemory(image.width,image.height,GUID_WICPixelFormat32bppRGBA,image.width*4,image.rgba.size(),image.rgba.data(),&tgaBitmap.p));source=tgaBitmap.p;}
 else{check(factory.p->CreateDecoderFromFilename(path.c_str(),nullptr,GENERIC_READ,WICDecodeMetadataCacheOnLoad,&decoder.p));check(decoder.p->GetFrame(0,&frame.p));source=frame.p;}
 UINT w,h;check(source->GetSize(&w,&h));if(!w||!h||w>32768||h>32768)throw std::runtime_error("Image dimensions exceed import limits.");
 auto power=[](UINT n){UINT p=16;while(p<512&&p<n)p*=2;return p;};UINT tw=power(w),th=power(h);
 ImportCom<IWICBitmapScaler> scaler;check(factory.p->CreateBitmapScaler(&scaler.p));check(scaler.p->Initialize(source,tw,th,WICBitmapInterpolationModeFant));
 ImportCom<IWICFormatConverter> converter;check(factory.p->CreateFormatConverter(&converter.p));check(converter.p->Initialize(scaler.p,GUID_WICPixelFormat32bppRGBA,WICBitmapDitherTypeNone,nullptr,0,WICBitmapPaletteTypeCustom));std::vector<unsigned char> pixels(tw*th*4);check(converter.p->CopyPixels(nullptr,tw*4,pixels.size(),pixels.data()));
 ftebroom::quake1::Texture result{importName,tw,th,{}};result.pixels.resize(tw*th);
 for(unsigned i=0;i<tw*th;i++){int best=0,distance=INT_MAX;for(int c=0;c<224;c++){int d=0;for(int a=0;a<3;a++){int value=pixels[i*4+a]*pixels[i*4+3]/255-(unsigned char)palette[c*3+a];d+=value*value;}if(d<distance){distance=d;best=c;}}result.pixels[i]=best;}return result;
}
static void importSaveImage(){
 auto target=std::filesystem::u8path(importWad);auto extension=target.extension().u8string();std::transform(extension.begin(),extension.end(),extension.begin(),::tolower);if(target.empty()||extension!=".wad")throw std::runtime_error("Choose a .wad destination.");std::filesystem::path archive;std::string member;if(ftebroom::pak::split(target,archive,member))throw std::runtime_error("Choose a loose WAD destination; packed WADs are read-only for image import.");
 if(!*importName)throw std::runtime_error("Enter a texture name.");for(unsigned char c:std::string(importName))if(!std::isalnum(c)&&c!='_'&&c!='-')throw std::runtime_error("Use letters, digits, underscore or dash for the texture name.");
 auto palette=modelResource("gfx/palette.lmp");auto texture=importDecode(importImages.front(),palette);auto original=std::filesystem::exists(target)?q1Read(target):std::string{};auto bytes=ftebroom::addWadTexture(original,texture,palette);
 auto temp=target;temp+=L".ftebroom-import.tmp";auto backup=target;backup+=L".ftebroom-"+std::to_wstring(std::chrono::high_resolution_clock::now().time_since_epoch().count())+L".bak";
 try{std::ofstream out(temp,std::ios::binary);out.write(bytes.data(),bytes.size());out.close();if(!out)throw std::runtime_error("Cannot write WAD.");if(!original.empty())std::filesystem::copy_file(target,backup);if(!MoveFileExW(temp.c_str(),target.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))throw std::runtime_error("Cannot replace WAD. Original is preserved.");}catch(...){std::error_code e;std::filesystem::remove(temp,e);throw;}
 importAddWads({target});cvars->SetString("ftebroom_reveal_material",texture.name.c_str());importNotice="Added "+texture.name+" to "+target.u8string();importImages.erase(importImages.begin());importName[0]=0;
}
static void importMaterialControls(){
 materialDropVisible=true;materialDropMin=ImGui::GetWindowPos();auto size=ImGui::GetWindowSize();materialDropMax={materialDropMin.x+size.x,materialDropMin.y+size.y};
 if(gameProfile==2){if(ImGui::Button("Add WAD(s)...")){try{importAddWads(importPick(false));}catch(const std::exception& e){importError=e.what();}}ImGui::TextDisabled("Drop WADs or images here from Explorer.");}
 if(!importNotice.empty())ImGui::TextWrapped("%s",importNotice.c_str());
 if(!importError.empty()){ImGui::TextWrapped("%s",importError.c_str());if(ImGui::SmallButton("Dismiss import message"))importError.clear();}
}
static void importDialog(){
 for(const auto& drop:desktopFileDrops)try {
  if(!drop.folder.empty()){modFileCopy(drop.path,drop.folder);continue;}
  auto folder=modFileRoot()/"models"/"imported";modFileValidate(folder);std::filesystem::create_directories(folder);
  auto target=modFileCopy(drop.path,folder);mountAssets();
  if(drop.scene){auto relative=target.lexically_relative(modFileRoot()).generic_u8string();command(("ftebroom_model_drop "+organizationQuote(relative)+" "+std::to_string(drop.point.x)+" "+std::to_string(drop.point.y)+"\n").c_str());}
  importNotice="Model copied to "+target.u8string();
 }catch(const std::exception& e){importError=e.what();}desktopFileDrops.clear();
 if(!desktopDrops.empty())selectMaterialTab=true;
 for(const auto& path:desktopDrops)try{auto ext=path.extension().u8string();std::transform(ext.begin(),ext.end(),ext.begin(),::tolower);if(ext==".wad")importAddWads({path});else if(gameProfile==2){importImages.push_back(path);importRequest=true;}else throw std::runtime_error("Image-to-WAD import requires the Quake 1 profile.");}catch(const std::exception& e){importError=e.what();}desktopDrops.clear();
 if(importRequest){importWindow=true;importRequest=false;}
 if(!importWindow)return;
 ImGui::SetNextWindowSize({640*uiScale(),360*uiScale()},ImGuiCond_FirstUseEver);
 if(ImGui::Begin("Import image into WAD",&importWindow,ImGuiWindowFlags_NoCollapse)){
  if(importImages.empty())importWindow=false;
  if(!importImages.empty()){
   if(!*importName){auto name=importImages.front().stem().u8string();for(char& c:name)if(!std::isalnum((unsigned char)c))c='_';name.resize(std::min<size_t>(15,name.size()));auto unique=name;for(int i=1;materials.count("textures/"+unique);i++){auto suffix="_"+std::to_string(i);unique=name.substr(0,15-suffix.size())+suffix;}std::snprintf(importName,sizeof importName,"%s",unique.c_str());}
   ImGui::TextWrapped("Source: %s",importImages.front().u8string().c_str());ImGui::InputText("Texture name",importName,sizeof importName);ImGui::InputText("Destination WAD",importWad,sizeof importWad);
   if(ImGui::BeginCombo("Loaded WADs",*importWad?importWad:"Choose a WAD...")) {
    for(const auto& path:q1WadPaths())if(!q1WadLabels.count(path.u8string()) && ImGui::Selectable(path.u8string().c_str()))std::snprintf(importWad,sizeof importWad,"%s",path.u8string().c_str());
    ImGui::EndCombo();
   }
   if(ImGui::Button("Choose / create WAD...")){auto paths=importPick(true);if(!paths.empty())std::snprintf(importWad,sizeof importWad,"%s",paths[0].u8string().c_str());}
   ImGui::TextWrapped("Resizes to power-of-two dimensions (16-512), converts to the loaded Quake palette and creates four mip levels. Alpha is composited over black. Existing names are never overwritten.");
   if(!importError.empty())ImGui::TextWrapped("%s",importError.c_str());
   if(ImGui::Button("Import")){try{importSaveImage();importError.clear();if(importImages.empty())importWindow=false;}catch(const std::exception& e){importError=e.what();}}
   ImGui::SameLine();if(ImGui::Button("Cancel")){importImages.clear();importWindow=false;}
  }
 }ImGui::End();
 if(!importWindow)importImages.clear();
}
#else
static void desktopAttach(){}static void desktopDetach(){}static void importDialog(){}
static void importMaterialControls(){
 if(gameProfile!=2)return;static char path[4096]={};static std::string error;
 ImGui::InputText("WAD path",path,sizeof path);
 if(ImGui::Button("Add WAD"))try{importAddWads({std::filesystem::u8path(path)});error.clear();}catch(const std::exception& e){error=e.what();}
 if(!error.empty())ImGui::TextWrapped("%s",error.c_str());
}
#endif
