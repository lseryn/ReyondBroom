// SPDX-License-Identifier: GPL-2.0-or-later
static bool updateStarted=false;
#ifdef _WIN32
static HANDLE updateProcess=nullptr;
#endif
static std::string updateMessage;
static void updateStart(){
#ifdef _WIN32
 if(updateProcess){DWORD code;GetExitCodeProcess(updateProcess,&code);if(code==STILL_ACTIVE)return;CloseHandle(updateProcess);updateProcess=nullptr;}
 try {auto root=settingsPath().parent_path();auto script=documentPath("update-ftebroom.ps1");if(!std::filesystem::is_regular_file(script))throw std::runtime_error("Updater script is missing.");
  auto args=L"powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File \""+script.wstring()+L"\" -Root \""+root.wstring()+L"\" -CurrentVersion 0.5.0-alpha.30 -ParentId "+std::to_wstring(GetCurrentProcessId());STARTUPINFOW si{};si.cb=sizeof si;PROCESS_INFORMATION pi{};
  if(!CreateProcessW(nullptr,args.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,nullptr,&si,&pi))throw std::runtime_error("Cannot start update manager.");CloseHandle(pi.hThread);updateProcess=pi.hProcess;updateMessage="Checking GitHub releases...";
 }catch(const std::exception& e){updateMessage=e.what();}
#endif
}
static void updateTick(){
 if(!ready||cvars->GetFloat("ftebroom_skip_setup"))return;
 if(!updateStarted){updateStarted=true;updateStart();}
 static quintptr_t last=0;auto now=core->GetMilliseconds();if(now-last<1000)return;last=now;
 std::ifstream input(settingsPath().parent_path()/"updates/status.txt");if(input){std::string value((std::istreambuf_iterator<char>(input)),{});if(value.size()<4096)updateMessage=value;}
}
static void updatePanel(){ImGui::TextWrapped("%s",updateMessage.empty()?"Updates are checked automatically at startup.":updateMessage.c_str());ImGui::TextWrapped("New Windows releases download in the background and install after the editor closes. Settings and maps are retained; rollback files stay in updates/.");if(ImGui::Button("Check for updates"))updateStart();}
