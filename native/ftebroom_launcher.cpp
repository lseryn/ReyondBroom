// SPDX-License-Identifier: GPL-2.0-or-later
// GUI-subsystem launcher: preserve Unicode paths and never invoke a command shell.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <filesystem>
#include <string>
#include <vector>
#include <fstream>
#include <iterator>

static std::wstring quote(const std::wstring& value) {
  std::wstring result=L"\"";size_t slashes=0;
  for(auto ch:value){
    if(ch==L'\\'){++slashes;continue;}
    result.append(ch==L'"'?slashes*2+1:slashes,L'\\');slashes=0;result+=ch;
  }
  result.append(slashes*2,L'\\');return result+L'"';
}
static int fail(const std::wstring& text){MessageBoxW(nullptr,text.c_str(),L"FTEBroom",MB_OK|MB_ICONERROR);return 1;}
int WINAPI wWinMain(HINSTANCE,HINSTANCE,PWSTR extra,int) {
  std::vector<wchar_t> buffer(32768);
  auto size=GetModuleFileNameW(nullptr,buffer.data(),DWORD(buffer.size()));
  if(!size||size>=buffer.size())return fail(L"Cannot locate the FTEBroom installation.");
  auto root=std::filesystem::path(std::wstring(buffer.data(),size)).parent_path();
  // Older updaters require this root filename in an archive. Remove only the
  // byte-identical compatibility launcher after the new layout is installed.
  if(std::filesystem::path(std::wstring(buffer.data(),size)).filename()==L"FTEBroom.exe"
      && std::filesystem::is_regular_file(root/L"bin"/L"fteqw64.exe")) {
    std::ifstream own(root/L"FTEBroom.exe",std::ios::binary), alias(root/L"fteqw64.exe",std::ios::binary);
    if(own && alias) {
      std::string a((std::istreambuf_iterator<char>(own)),{}),b((std::istreambuf_iterator<char>(alias)),{});
      own.close();alias.close();
      if(!a.empty() && a==b){std::error_code ignored;std::filesystem::remove(root/L"fteqw64.exe",ignored);}
    }
  }
  auto engine=root/L"bin"/L"fteqw64.exe";
  if(!std::filesystem::is_regular_file(engine))engine=root/L"fteqw64.exe";
  if(GetFileAttributesW(engine.c_str())==INVALID_FILE_ATTRIBUTES)
    return fail(L"The engine in bin is missing. Extract the entire FTEBroom archive before starting the editor.");
  for(const auto* name:{L"zlib1.dll",L"fteplug_ftebroom_x64.dll",L"libpng16.dll",L"libjpeg.dll",L"libgcc_s_seh-1.dll",L"libwinpthread-1.dll"})
    if(GetFileAttributesW((root/name).c_str())==INVALID_FILE_ATTRIBUTES)
      return fail(std::wstring(L"The installation is incomplete: ")+name+L" is missing.\nExtract the entire FTEBroom ZIP into one folder, keeping all DLLs beside FTEBroom.exe.");
  auto command=quote(engine.wstring())+L" -window -maximize -nohome -noupdates -condebug -basedir "+quote(root.wstring())+L" +exec ftebroom.cfg";
  if(extra&&*extra)command+=L" "+std::wstring(extra);
  STARTUPINFOW startup{};startup.cb=sizeof startup;PROCESS_INFORMATION process{};
  if(!CreateProcessW(engine.c_str(),command.data(),nullptr,nullptr,FALSE,0,nullptr,root.c_str(),&startup,&process)){
    auto code=GetLastError();return fail(L"Cannot start the editor (Windows error "+std::to_wstring(code)+L").\nCheck that the archive is fully extracted and the executable is accessible.");
  }
  CloseHandle(process.hThread);CloseHandle(process.hProcess);return 0;
}
