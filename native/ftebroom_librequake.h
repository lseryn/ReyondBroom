// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_pak.h"
static bool q1UseLibre;
static std::string libreError;
#ifdef _WIN32
static HANDLE libreProcess;
#endif
static std::filesystem::path libreInstall(){return settingsPath().parent_path()/"downloads/librequake-v0.09";}
static std::string libreMod(){return (libreInstall()/"mod_lite/lq1").u8string();}
static bool libreReady(){return std::filesystem::exists(libreInstall()/"ready.txt")&&std::filesystem::is_regular_file(std::filesystem::u8path(libreMod())/"pak0.pak");}
static void libreTick(){
#ifdef _WIN32
  if(libreProcess){DWORD code=STILL_ACTIVE;if(GetExitCodeProcess(libreProcess,&code)&&code!=STILL_ACTIVE){CloseHandle(libreProcess);libreProcess=nullptr;if(code||!libreReady()){std::ifstream f(libreInstall()/"error.txt");std::getline(f,libreError);if(libreError.empty())libreError="Download failed. Retry when connected.";}}}
#endif
}
static void libreFields(){
  libreTick();
  if(libreReady()){ImGui::Checkbox("Use LibreQuake mod",&q1UseLibre);return;}
  q1UseLibre=false;
#ifdef _WIN32
  if(libreProcess){uint64_t done=0,total=0;std::string phase;std::ifstream(libreInstall()/"progress.txt")>>done>>total>>phase;ImGui::ProgressBar(total?float(double(done)/total):0,{400,0},phase.empty()?"Connecting...":phase.c_str());ImGui::Text("%.1f / %.1f MiB",done/1048576.,total/1048576.);}
  else if(ImGui::Button("Download LibreQuake mod")){
    libreError.clear();try{char script[4096]={};if(!files->NativePath("download-librequake.ps1",(fs_relative)5,script,sizeof script))throw std::runtime_error("Installer script is missing.");
      auto path=std::filesystem::u8path(script);auto destination=libreInstall();std::filesystem::create_directories(destination);
      std::wstring args=L"powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File \""+path.wstring()+L"\" -Destination \""+destination.wstring()+L"\"";
      STARTUPINFOW si{};si.cb=sizeof si;PROCESS_INFORMATION pi{};if(!CreateProcessW(nullptr,args.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,nullptr,&si,&pi))throw std::runtime_error("Cannot start LibreQuake download.");CloseHandle(pi.hThread);libreProcess=pi.hProcess;
    }catch(const std::exception& e){libreError=e.what();}}
#else
  ImGui::TextWrapped("Download mod_lite.zip from the link below and select its lq1 folder.");
#endif
  ImGui::TextWrapped("https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/mod_lite.zip");
  if(!libreError.empty())ImGui::TextWrapped("%s",libreError.c_str());
}
