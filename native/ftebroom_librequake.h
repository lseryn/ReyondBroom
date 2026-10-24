// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_pak.h"
static bool q1UseLibre;
static std::string libreError;
#ifdef _WIN32
static HANDLE libreProcess;
#else
static pid_t libreProcess=-1;
#endif
static bool libreBusy(){
#ifdef _WIN32
return libreProcess!=nullptr;
#else
return libreProcess>0;
#endif
}
static std::filesystem::path libreInstall(){return settingsPath().parent_path()/"downloads/librequake-v0.09";}
static std::string libreMod(){return (libreInstall()/"mod_lite/lq1").u8string();}
static bool libreReady(){return std::filesystem::exists(libreInstall()/"wads-ready.txt")&&std::filesystem::is_regular_file(libreInstall()/"mod_lite/lq1/texture-wads/lq_dev.wad")&&std::filesystem::exists(libreInstall()/"ready.txt")&&std::filesystem::is_regular_file(std::filesystem::u8path(libreMod())/"pak0.pak");}
static void libreTick(){
  bool finished=false,failed=false;
#ifdef _WIN32
  if(libreProcess){DWORD code=STILL_ACTIVE;if(GetExitCodeProcess(libreProcess,&code)&&code!=STILL_ACTIVE){CloseHandle(libreProcess);libreProcess=nullptr;finished=true;failed=code!=0;}}
#else
  if(libreProcess>0){int status=0;auto result=waitpid(libreProcess,&status,WNOHANG);if(result>0||(result<0&&errno!=EINTR)){libreProcess=-1;finished=true;failed=result<0?(errno!=ECHILD||!libreReady()):(!WIFEXITED(status)||WEXITSTATUS(status)!=0);}}
#endif
  if(finished){if(failed||!libreReady()){std::ifstream f(libreInstall()/"error.txt");std::getline(f,libreError);if(libreError.empty())libreError="Download failed. Retry when connected.";}}
}
static void libreStartDownload(){
  if(libreBusy())return;
  libreError.clear();
  std::error_code ignored;std::filesystem::create_directories(libreInstall(),ignored);
  std::ofstream(libreInstall()/"progress.txt")<<"0 0 Connecting";
#ifdef _WIN32
    libreError.clear();try{char script[4096]={};if(!files->NativePath("download-librequake.ps1",(fs_relative)5,script,sizeof script))throw std::runtime_error("Installer script is missing.");
      auto path=std::filesystem::u8path(script);auto destination=libreInstall();std::filesystem::create_directories(destination);
      std::wstring args=L"powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File \""+path.wstring()+L"\" -Destination \""+destination.wstring()+L"\"";
      STARTUPINFOW si{};si.cb=sizeof si;PROCESS_INFORMATION pi{};if(!CreateProcessW(nullptr,args.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,nullptr,&si,&pi))throw std::runtime_error("Cannot start LibreQuake download.");CloseHandle(pi.hThread);libreProcess=pi.hProcess;
    }catch(const std::exception& e){libreError=e.what();}
#else
    libreError.clear();try{char script[4096]={};if(!files->NativePath("download-librequake.py",(fs_relative)5,script,sizeof script))throw std::runtime_error("Installer script is missing.");
      std::filesystem::create_directories(libreInstall());
      std::vector<std::string> args={"python3",script,"--destination",libreInstall().u8string()};std::vector<char*> argv;for(auto& a:args)argv.push_back(a.data());argv.push_back(nullptr);
      int status=posix_spawnp(&libreProcess,"python3",nullptr,nullptr,argv.data(),environ);if(status){libreProcess=-1;throw std::runtime_error("Cannot start downloader. Install Python 3.");}
    }catch(const std::exception& e){libreError=e.what();}
#endif
}
