// SPDX-License-Identifier: GPL-2.0-or-later
// Windows child rendering avoids frame readback and keeps the mod VM isolated.
static std::string modSavedCamera;
static double modLastSend,modPendingSince;
static uint64_t modAckCount;
static bool modAwaiting;
#ifdef _WIN32
static HWND modHost,modChild;
static LONG_PTR modHostStyle;
static BOOL CALLBACK modFindHost(HWND window,LPARAM result)
{
  DWORD pid=0;GetWindowThreadProcessId(window,&pid);
  if(pid==GetCurrentProcessId() && IsWindowVisible(window) && !GetWindow(window,GW_OWNER)){
    *reinterpret_cast<HWND*>(result)=window;return FALSE;
  }return TRUE;
}
#endif
static void modEmbedEnd()
{
  if(!modEmbedded)return;
  modEmbedded=false;
  cvars->SetFloat("ftebroom_mod_preview",0);
  std::fill(std::begin(moveHeld),std::end(moveHeld),false);
  cvars->SetFloat("ftebroom_forward",0);cvars->SetFloat("ftebroom_right",0);cvars->SetFloat("ftebroom_up",0);
  if(runActive)runStop();
#ifdef _WIN32
  if(IsWindow(modHost))SetWindowLongPtr(modHost,GWL_STYLE,modHostStyle);
  modChild=modHost=nullptr;
#endif
  cameraEnd();
  if(!modSavedCamera.empty()){cvars->SetString("ftebroom_camera_state",modSavedCamera.c_str());command(("ftebroom_camera_restore "+modSavedCamera+"\n").c_str());}
  buildRestoreLayout();
  buildMessage="Returned to editing. Mod simulation stopped.";
}
static void modEmbedBegin()
{
#ifdef _WIN32
  EnumWindows(modFindHost,reinterpret_cast<LPARAM>(&modHost));
  if(!modHost)throw std::runtime_error("Cannot locate the editor window.");
  modHostStyle=GetWindowLongPtr(modHost,GWL_STYLE);
  SetWindowLongPtr(modHost,GWL_STYLE,modHostStyle|WS_CLIPCHILDREN);
  char state[512]={};cvars->GetString("ftebroom_camera_state",state,sizeof state);modSavedCamera=state;
  cancelGesture();cameraEnd();
  buildWindow=false;runWindow=false;
  if(!buildWasPreview){buildSavedLayout=viewLayout;buildSavedFocus=viewFocus;buildSavedMax=viewMax;
    std::copy(std::begin(viewTypes),std::end(viewTypes),buildSavedTypes);buildWasPreview=true;}
  viewLayout=1;viewFocus=0;viewMax=-1;viewTypes[0]=0;cvars->SetFloat("ftebroom_view_layout",1);viewActivate(0);
  modChild=nullptr;modAwaiting=false;modAckCount=runControlAcks;modLastSend=0;modEmbedded=true;
  cvars->SetFloat("ftebroom_mod_preview",1);
#else
  throw std::runtime_error("Embedded mod preview currently requires Windows.");
#endif
}
static void modEmbedTick(float width,float height)
{
#ifdef _WIN32
  if(!modEmbedded)return;
  if(!runActive){auto error=runError;modEmbedEnd();if(!error.empty())buildMessage="Mod preview stopped: "+error;return;}
  if(!runInput || !runProcess)return;
  if(!modChild){
    auto at=runLog.find("refocuswindow ");
    if(at!=std::string::npos){
      auto candidate=reinterpret_cast<HWND>(std::strtoull(runLog.c_str()+at+14,nullptr,16));DWORD pid=0;
      GetWindowThreadProcessId(candidate,&pid);
      if(IsWindow(candidate) && pid==GetProcessId(runProcess)){
        modChild=candidate;SetParent(modChild,modHost);
        SetWindowLongPtr(modChild,GWL_STYLE,WS_CHILD|WS_CLIPSIBLINGS|WS_DISABLED);
        EnableWindow(modChild,FALSE);
        SetFocus(modHost);
      }
    }
  }
  auto r=viewRects[0];r.h=std::max(1.f,r.h-140*uiScale());
  bool covered=popupOpen || !IsWindowVisible(modHost) || IsIconic(modHost);
  for(auto window:ImGui::GetCurrentContext()->Windows){
    if(!window->Active || window->Hidden || (window->Flags & (ImGuiWindowFlags_DockNodeHost|ImGuiWindowFlags_NoBackground)))continue;
    if(std::string(window->Name)=="##Build viewport status")continue;
    if(window->Pos.x<r.x+r.w && window->Pos.y<r.y+r.h && window->Pos.x+window->Size.x>r.x && window->Pos.y+window->Size.y>r.y)covered=true;
  }
  RECT client{};GetClientRect(modHost,&client);
  float sx=float(client.right)/std::max(1.f,width),sy=float(client.bottom)/std::max(1.f,height);
  int x=int(r.x*sx),y=int(r.y*sy),w=std::max(16,int(r.w*sx)),h=std::max(16,int(r.h*sy));
  if(modChild){
    SetWindowPos(modChild,HWND_TOP,x,y,w,h,SWP_NOACTIVATE|SWP_ASYNCWINDOWPOS|(covered?SWP_HIDEWINDOW:SWP_SHOWWINDOW));
  }
  if(modAwaiting && runControlAcks!=modAckCount)modAwaiting=false;
  if(modAwaiting){if(ImGui::GetTime()-modPendingSince>10)buildMessage="Mod preview is not responding. Back to editing stops the process.";return;}
  if(ImGui::GetTime()-modLastSend<.033)return;
  char state[512]={};float values[7];cvars->GetString("ftebroom_camera_state",state,sizeof state);
  if(!cameraParse(state,values))return;
  char control[512];std::snprintf(control,sizeof control,
    "vid_recenter %d %d %d %d %llx\nset ftebroom_preview_camera \"%g %g %g %g %g %g %g\"\n",
    x,y,w,h,(unsigned long long)(uintptr_t)modHost,values[0],values[1],values[2],values[3],values[4],values[5],values[6]);
  DWORD written=0;modAckCount=runControlAcks;
  if(!WriteFile(runInput,control,(DWORD)std::strlen(control),&written,nullptr)){modEmbedEnd();buildMessage="Mod preview control connection closed.";return;}
  modAwaiting=true;modPendingSince=modLastSend=ImGui::GetTime();
#endif
}
