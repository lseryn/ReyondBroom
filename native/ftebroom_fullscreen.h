// SPDX-License-Identifier: GPL-2.0-or-later
// Change the desktop window only: never restart the renderer or reload an unsaved MAP.
static bool uiFullscreen=false,uiFullscreenLoaded=false;
static std::string uiFullscreenError;
#ifdef _WIN32
static WINDOWPLACEMENT uiWindowPlacement={sizeof(WINDOWPLACEMENT)};
static LONG_PTR uiWindowStyle;
static bool uiFullscreenApply(bool enabled)
{
  if(!desktopHost||!IsWindow(desktopHost))return false;
  if(enabled) {
    MONITORINFO monitor={sizeof(MONITORINFO)};
    if(!GetWindowPlacement(desktopHost,&uiWindowPlacement)||!GetMonitorInfo(MonitorFromWindow(desktopHost,MONITOR_DEFAULTTONEAREST),&monitor))return false;
    uiWindowStyle=GetWindowLongPtr(desktopHost,GWL_STYLE);
    SetWindowLongPtr(desktopHost,GWL_STYLE,uiWindowStyle&~WS_OVERLAPPEDWINDOW);
    SetWindowPos(desktopHost,nullptr,monitor.rcMonitor.left,monitor.rcMonitor.top,monitor.rcMonitor.right-monitor.rcMonitor.left,monitor.rcMonitor.bottom-monitor.rcMonitor.top,SWP_NOOWNERZORDER|SWP_FRAMECHANGED);
  } else {
    SetWindowLongPtr(desktopHost,GWL_STYLE,uiWindowStyle);
    SetWindowPlacement(desktopHost,&uiWindowPlacement);
    SetWindowPos(desktopHost,nullptr,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOOWNERZORDER|SWP_FRAMECHANGED);
  }
  return true;
}
#else
#include <dlfcn.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#undef None
#undef Status
#undef Always
static bool uiFullscreenApply(bool enabled)
{
  void* library=dlopen("libX11.so.6",RTLD_NOW|RTLD_LOCAL);if(!library)return false;
  auto open=(decltype(&XOpenDisplay))dlsym(library,"XOpenDisplay");
  auto close=(decltype(&XCloseDisplay))dlsym(library,"XCloseDisplay");
  auto atom=(decltype(&XInternAtom))dlsym(library,"XInternAtom");
  auto get=(decltype(&XGetWindowProperty))dlsym(library,"XGetWindowProperty");
  auto query=(decltype(&XQueryTree))dlsym(library,"XQueryTree");
  auto release=(decltype(&XFree))dlsym(library,"XFree");
  auto send=(decltype(&XSendEvent))dlsym(library,"XSendEvent");
  auto flush=(decltype(&XFlush))dlsym(library,"XFlush");
  auto handler=(decltype(&XSetErrorHandler))dlsym(library,"XSetErrorHandler");
  if(!open||!close||!atom||!get||!query||!release||!send||!flush||!handler){dlclose(library);return false;}
  Display* display=open(nullptr);if(!display){dlclose(library);return false;}
  // Other desktop windows may disappear while we inspect their PID.
  auto previousHandler=handler(+[](Display*,XErrorEvent*){return 0;});
  Window root=DefaultRootWindow(display),found=0;Atom pid=atom(display,"_NET_WM_PID",False);
  auto property=[&](Window window,Atom key,Atom type)->unsigned long {
    Atom actual=0;int format=0;unsigned long count=0,remaining=0;unsigned char* data=nullptr;unsigned long value=0;
    if(get(display,window,key,0,1,False,type,&actual,&format,&count,&remaining,&data)==Success&&data&&format==32&&count)value=*(unsigned long*)data;
    if(data)release(data);return value;
  };
  bool manager=property(root,atom(display,"_NET_SUPPORTING_WM_CHECK",False),XA_WINDOW)!=0;
  std::vector<Window> pending{root};
  for(int depth=0;depth<5&&!found;depth++) {
    std::vector<Window> next;
    for(auto window:pending) {
      if(property(window,pid,XA_CARDINAL)==static_cast<unsigned long>(getpid())){found=window;break;}
      Window parent,treeRoot,*children=nullptr;unsigned int count=0;
      if(query(display,window,&treeRoot,&parent,&children,&count))for(unsigned int i=0;i<count;i++)next.push_back(children[i]);
      if(children)release(children);
    }
    pending=std::move(next);
  }
  bool ok=false;
  if(found&&manager) {
    XEvent message={};message.xclient.type=ClientMessage;message.xclient.window=found;
    message.xclient.message_type=atom(display,"_NET_WM_STATE",False);message.xclient.format=32;
    message.xclient.data.l[0]=enabled?1:0;message.xclient.data.l[1]=atom(display,"_NET_WM_STATE_FULLSCREEN",False);message.xclient.data.l[3]=1;
    ok=send(display,root,False,SubstructureRedirectMask|SubstructureNotifyMask,&message)!=0;flush(display);
  }
  close(display);handler(previousHandler);dlclose(library);return ok;
}
#undef Success
#endif
static void uiFullscreenSet(bool enabled,bool save=true)
{
  if(enabled==uiFullscreen)return;
  if(!uiFullscreenApply(enabled)){uiFullscreenError="The desktop window manager could not change fullscreen mode.";return;}
  uiFullscreen=enabled;uiFullscreenError.clear();
  if(save){std::ofstream out(documentPath("display-mode.txt"));out<<(enabled?1:0)<<'\n';}
}
static void uiFullscreenTick()
{
  if(uiFullscreenLoaded)return;uiFullscreenLoaded=true;
  if(cvars->GetFloat("ftebroom_skip_setup"))return;
  int saved=0;std::ifstream input(documentPath("display-mode.txt"));if(input>>saved&&saved==1)uiFullscreenSet(true,false);
}
