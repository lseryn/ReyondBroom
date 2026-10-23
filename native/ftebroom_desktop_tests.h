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

#ifdef _WIN32
  if(std::string(mode)=="crash31"){crashContextTick();RaiseException(EXCEPTION_ACCESS_VIOLATION,0,0,nullptr);}
#endif
  if(std::string(mode)=="wad32load") {importAddWads({std::filesystem::u8path(root)/"concrete_sh.wad"});expect(true,"wad_selected_from_map_directory");}
  if(std::string(mode)=="wad32paint") {
    auto textures=ftebroom::quake1::wad(q1Read(std::filesystem::u8path(root)/"concrete_sh.wad"));
    command("ftebroom_select all\n");chooseMaterial("textures/"+textures.front().name);expect(true,"wad_material_applied");
  }
  if(std::string(mode)=="wad32build") {gamePreviewAfterBuild=false;runLoad();buildLoadSettings();buildGeometry=true;buildVis=false;buildLight=false;buildBegin();expect(buildRunning,"real_background_build_started");}
  if(std::string(mode)=="wad32result") {
    std::ofstream(documentPath("wad32-build.log"))<<runLog<<"\n"<<buildMessage;
    expect(!buildRunning&&!runHadError&&!buildResult.empty(),"real_background_build_finished");
    if(!buildResult.empty())std::ofstream(documentPath("wad32-result.txt"))<<buildResult.u8string();
  }
  if(std::string(mode)=="recent33") {recentRemember(std::filesystem::u8path(root)/"id1/maps/wad-external.map",2);recentMaps.front().favorite=true;recentSave();recentMaps.clear();recentLoaded=false;recentLoad();expect(!recentMaps.empty()&&recentMaps.front().favorite&&recentMaps.front().profile==2,"recent_profile_favorite_persisted");recentWindow=true;}
  if(std::string(mode)=="viewer33") {recentWindow=false;modelViewerShow("models/qa/test.md3");frame();}
  if(std::string(mode)=="viewer33check") {expect(cvars->GetFloat("ftebroom_modelviewer_count")>0,"model_viewer_frames");expect(cvars->GetFloat("ftebroom_modelviewer_poses")>0,"model_viewer_poses");}
  if(std::string(mode)=="viewer33iqm") {modelViewerShow("models/qa/skeleton.iqm");modelViewerBones=true;modelViewerPlay=true;}
  if(std::string(mode)=="viewer33iqmcheck") {expect(cvars->GetFloat("ftebroom_modelviewer_bones")==2,"viewer_skeletal_bones");expect(cvars->GetFloat("ftebroom_modelviewer_poses")==2,"viewer_animation_poses");}
  if(std::string(mode)=="material33") {modelViewerOpen=false;selectMaterialTab=true;materialAdvanced=true;materialWidths[0]=materialWidths[1]=64;materialHeights[0]=materialHeights[1]=64;}
  if(std::string(mode)=="material33check") {bool found=false;for(auto& d:materialDimensions)if(d.second.x==64&&d.second.y==64)found=true;expect(found,"material_dimensions_loaded");}
  if(std::string(mode)=="profile33") {modelViewerOpen=false;documentRequest("__profile:0");}
  if(std::string(mode)=="profile33check") {expect(gameProfile==0 && documentUntitled && documentFile.empty(),"profile_switch_starter_document");}
  if(std::string(mode)=="thumbnail32") {
    modFilesOpen=false;
    draw->LoadImageShader("textures/qa/deform","{ deformVertexes wave 1 sin 0 200 0 1 { map textures/qa/tile.tga } }");
    materials["textures/qa/deform"]={"textures/qa/deform","textures/qa/tile.tga",true,0};
    cvars->SetString("ftebroom_reveal_material","qa/deform");selectMaterialTab=true;frame();frame();
    expect(thumbnail("textures/qa/deform")!=0,"isolated_thumbnail_shader");
  }
  if(std::string(mode)=="new32") {modFilesOpen=false;documentNext="__new";documentProceed();frame();expect(fileBrowserNew,"new_map_profile_dialog");}
  if(std::string(mode)=="new32result") {expect(!documentFile.empty()&&documentFile.filename()=="created32.map"&&gameProfile==2,"new_map_created_with_profile");}
  if(std::string(mode)=="files32") {
    auto root=modFileRoot()/"manager32";std::filesystem::create_directories(root/"one");std::filesystem::create_directories(root/"two");std::ofstream(root/"one/a.txt")<<"preserve";
    modFilesRoot=modFileRoot();modFilesFolder=root/"two";modFilesClipboard=root/"one/a.txt";modFilesCut=false;modFilesPaste();expect(q1Read(root/"two/a.txt")=="preserve"&&std::filesystem::exists(root/"one/a.txt"),"manager_copy_paste");
    modFilesClipboard=root/"one/a.txt";modFilesCut=true;modFilesFolder=root;modFilesPaste();expect(std::filesystem::exists(root/"a.txt")&&!std::filesystem::exists(root/"one/a.txt"),"manager_cut_paste");
    modFilesOpen=true;modFilesGrid=true;modFilesRefresh=true;frame();
  }
  if(std::string(mode)=="windows31"){modFilesOpen=true;selectMaterialTab=true;frame();}
  if(std::string(mode)=="assets31") {

#ifdef _WIN32

   auto folder=std::filesystem::u8path(root);auto external=folder/std::filesystem::u8path(u8"Рабочий стол");

   importAddWads({external/"concrete_sh.wad"});auto original=ftebroom::quake1::wad(q1Read(external/"concrete_sh.wad"));expect(!original.empty(),"unicode_wad_loaded");

   for(auto extension:{"jpg","png"}){importImages={external/(std::string("images.")+extension)};std::snprintf(importWad,sizeof importWad,"%s",(folder/"converted.wad").u8string().c_str());std::snprintf(importName,sizeof importName,"image%s",extension);importSaveImage();}

   auto converted=ftebroom::quake1::wad(q1Read(folder/"converted.wad"));expect(converted.size()==2&&converted[0].width==512&&converted[0].height==512,"real_jpg_png_converted");

   auto build=folder/"compiler";std::filesystem::create_directories(build);auto wads=q1CompilerWads(build);expect(wads.find(u8"Рабочий")==std::string::npos&&wads.find("_ftebroom-wads/")==0,"compiler_ascii_wads");

   auto map=ftebroom::quake1::map(q1Read(documentPath("maps/build-fixture.map")),false,wads);

   size_t at=0;int face=0;while((at=map.find("q1test",at))!=std::string::npos){auto name=face++%3==0?original.front().name:face%2?"imagejpg":"imagepng";map.replace(at,6,name);at+=name.size();}

   std::ofstream output(build/"unicode.map",std::ios::binary);output<<map;output.close();

   std::ofstream expected(build/"expected.txt");expected<<original.front().name<<"\nimagejpg\nimagepng\n";

   auto oldProfile=gameProfile;auto oldFormat=q1MapFormat;

   for(int profile=0;profile<3;profile++){gameProfile=profile;documentTerrain=false;auto bytes=documentMetadata("{\n}\n");expect(bytes.rfind("// FTEBroom profile=",0)==0,"map_profile_marker");}

   gameProfile=oldProfile;q1MapFormat=oldFormat;

   auto destination=modFileRoot()/"import-qa";std::filesystem::create_directories(destination);auto copied=modFileCopy(external/"images.png",destination);auto copiedAgain=modFileCopy(external/"images.png",destination);expect(copied!=copiedAgain&&q1Read(copied)==q1Read(copiedAgain),"manager_copy_preserves_collision");

   auto sub=destination/"sub";std::filesystem::create_directory(sub);modFileMove(copied,sub);expect(std::filesystem::exists(sub/copied.filename())&&!std::filesystem::exists(copied),"manager_move");

   bool rejected=false;try{modFileValidate(folder.parent_path());}catch(...){rejected=true;}expect(rejected,"manager_rejects_outside_mod");

   removedCollections.insert("test collection");collectionsSave();collectionScope.clear();collectionsLoad();expect(removedCollections.count("test collection"),"removed_collection_persists");

#endif

  }

  if(std::string(mode)=="models"){

   ftebroom::EntityDefinition d;d.name="test_md3";d.model="models/qa/test.md3";d.brush=false;entityDefinitions[d.name]=d;d.name="test_mdl";d.model="models/qa/test.mdl";entityDefinitions[d.name]=d;cvars->SetFloat("ftebroom_test_model_previews",1);cvars->SetString("ftebroom_test_entity_filter","test_");selectEntityTab=true;frame();frame();

   expect(entityPreviews.count("models/qa/test.md3:")&&entityPreviews["models/qa/test.md3:"].parts.size()==2&&entityPreviews["models/qa/test.md3:"].image,"md3_textured_surfaces");expect(entityPreviews.count("models/qa/test.mdl:")&&entityPreviews["models/qa/test.mdl:"].image,"mdl_uploaded_skin");

  }

 }catch(const std::exception& e){core->Print((std::string("FTEBROOM_DESKTOP_FAIL ")+e.what()+"\n").c_str());}

}
