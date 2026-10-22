// SPDX-License-Identifier: GPL-2.0-or-later
static void testDesktop(){
 if(!cvars->GetFloat("ftebroom_skip_setup")||commands->IsInsecure())return;
 auto expect=[](bool ok,const char* name){core->Print((std::string(ok?"FTEBROOM_DESKTOP_PASS ":"FTEBROOM_DESKTOP_FAIL ")+name+"\n").c_str());};
 char mode[64]={},root[4096]={};commands->Argv(1,mode,sizeof mode);cvars->GetString("ftebroom_test_import_root",root,sizeof root);auto frame=[](){event(0,0,0,950,550,1280,800);};
 try {
  if(std::string(mode)=="ui"){
   uiTheme=1;cvars->SetFloat("ftebroom_skip_setup",0);uiSaveAppearance();uiTheme=0;uiLoaded=false;uiLoad();cvars->SetFloat("ftebroom_skip_setup",1);expect(uiTheme==1,"theme_persisted");selectMaterialTab=true;frame();frame();
   expect(ImGui::GetStyle().FrameRounding==0&&ImGui::GetStyle().Colors[ImGuiCol_WindowBg].x>.7,"retro_style");
#ifdef _WIN32
   desktopAttach();ImGui::SetMouseCursor(ImGuiMouseCursor_ResizeEW);desktopProc(desktopHost,WM_SETCURSOR,(WPARAM)desktopHost,HTCLIENT);expect(GetCursor()==LoadCursorA(nullptr,IDC_SIZEWE),"horizontal_resize_cursor");
   ImGui::SetMouseCursor(ImGuiMouseCursor_ResizeNWSE);desktopProc(desktopHost,WM_SETCURSOR,(WPARAM)desktopHost,HTCLIENT);expect(GetCursor()==LoadCursorA(nullptr,IDC_SIZENWSE),"diagonal_resize_cursor");
#endif
  }
#ifdef _WIN32
  if(std::string(mode)=="drop"){
   selectMaterialTab=true;frame();frame();auto path=(std::filesystem::u8path(root)/"import.png").wstring();SIZE_T size=sizeof(DROPFILES)+(path.size()+2)*sizeof(wchar_t);auto memory=GlobalAlloc(GHND,size);auto drop=(DROPFILES*)GlobalLock(memory);drop->pFiles=sizeof(DROPFILES);drop->fWide=TRUE;RECT rect;GetClientRect(desktopHost,&rect);drop->pt.x=int((materialDropMin.x+20)*rect.right/ImGui::GetIO().DisplaySize.x);drop->pt.y=int((materialDropMin.y+20)*rect.bottom/ImGui::GetIO().DisplaySize.y);std::memcpy((char*)drop+sizeof(DROPFILES),path.c_str(),(path.size()+1)*sizeof(wchar_t));GlobalUnlock(memory);SendMessageW(desktopHost,WM_DROPFILES,(WPARAM)memory,0);expect(desktopDrops.size()==1,"explorer_drop_routed");frame();expect(importImages.size()==1,"import_destination_dialog");
   std::snprintf(importWad,sizeof importWad,"%s",(std::filesystem::u8path(root)/"target.wad").u8string().c_str());std::snprintf(importName,sizeof importName,"imported");importSaveImage();frame();auto textures=ftebroom::quake1::wad(q1Read(std::filesystem::u8path(importWad)));expect(textures.size()==2&&textures.back().width==32&&textures.back().height==16,"image_resized_and_appended");
  }
#endif
  if(std::string(mode)=="models"){
   ftebroom::EntityDefinition d;d.name="test_md3";d.model="models/qa/test.md3";d.brush=false;entityDefinitions[d.name]=d;d.name="test_mdl";d.model="models/qa/test.mdl";entityDefinitions[d.name]=d;cvars->SetFloat("ftebroom_test_model_previews",1);cvars->SetString("ftebroom_test_entity_filter","test_");selectEntityTab=true;frame();frame();
   expect(entityPreviews.count("models/qa/test.md3:")&&entityPreviews["models/qa/test.md3:"].parts.size()==2&&entityPreviews["models/qa/test.md3:"].image,"md3_textured_surfaces");expect(entityPreviews.count("models/qa/test.mdl:")&&entityPreviews["models/qa/test.mdl:"].image,"mdl_uploaded_skin");
  }
 }catch(const std::exception& e){core->Print((std::string("FTEBROOM_DESKTOP_FAIL ")+e.what()+"\n").c_str());}
}
