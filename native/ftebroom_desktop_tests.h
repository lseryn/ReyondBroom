// SPDX-License-Identifier: GPL-2.0-or-later

static void testDesktop(){

 if(!cvars->GetFloat("ftebroom_skip_setup")||commands->IsInsecure())return;

 auto expect=[](bool ok,const char* name){core->Print((std::string(ok?"FTEBROOM_DESKTOP_PASS ":"FTEBROOM_DESKTOP_FAIL ")+name+"\n").c_str());};

 char mode[64]={},root[4096]={};commands->Argv(1,mode,sizeof mode);cvars->GetString("ftebroom_test_import_root",root,sizeof root);auto frame=[](){event(0,0,0,950,550,1280,800);};

 try {
  if(std::string(mode)=="setup37") {
    recentWindow=false;setupNeeded=true;setupInitialized=true;firstSetupStep=0;frame();frame();
    auto wizard=ImGui::FindWindowByName("First-time setup");expect(wizard&&wizard->Active,"language_setup_first");
  }
  if(std::string(mode)=="setup37profile") {firstSetupStep=1;frame();frame();}
  if(std::string(mode)=="setup37resources") {firstSetupStep=2;ImGui::ClosePopupToLevel(0,true);frame();frame();}
  if(std::string(mode)=="roots37") {
    if(!*root)throw std::runtime_error("Missing test root");
    firstSetupStep=-1;setupNeeded=false;ImGui::ClosePopupToLevel(0,true);
    auto fixture=std::filesystem::u8path(root);auto mod=fixture/"mod",sources=fixture/"sources";
    std::filesystem::create_directories(mod/"models");std::filesystem::create_directories(sources/"maps");
    gameProfile=1;std::snprintf(gameMod,sizeof gameMod,"%s",mod.u8string().c_str());std::snprintf(baseq3,sizeof baseq3,"%s",sources.u8string().c_str());
    expect(modFileInside(mod/"models/a.md3")&&modFileInside(sources/"maps/a.map")&&!modFileInside(fixture/"outside.txt"),"configured_roots_only");
    expect(modFileModelPath(sources/"models/test.md3")=="models/test.md3","authoring_model_relative_path");
    modFilesSources=true;modFilesOpen=true;frame();frame();expect(modFilesFolder==sources&&gameRuntime()==mod.u8string(),"authoring_navigation_keeps_runtime");
    modFilesSources=false;frame();frame();expect(modFilesFolder==mod,"return_to_mod_root");
  }
#ifdef _WIN32
  if(std::string(mode)=="window37") {
    desktopAttach();auto style=GetWindowLongPtr(desktopHost,GWL_STYLE);
    expect(cvars->GetFloat("vid_fullscreen")==0 && (style&WS_CAPTION),"decorated_window_default");
  }
  if(std::string(mode)=="seamless36") {
    desktopAttach();RECT client{};GetClientRect(desktopHost,&client);MONITORINFO monitor{};monitor.cbSize=sizeof monitor;GetMonitorInfo(MonitorFromWindow(desktopHost,MONITOR_DEFAULTTONEAREST),&monitor);
    auto style=GetWindowLongPtr(desktopHost,GWL_STYLE);
    expect(cvars->GetFloat("vid_fullscreen")==2&&!(style&WS_CAPTION)&&client.right==monitor.rcMonitor.right-monitor.rcMonitor.left&&client.bottom==monitor.rcMonitor.bottom-monitor.rcMonitor.top,"default_borderless_desktop_window");
  }
#endif
  if(std::string(mode)=="audio36open") {
    gameProfile=0;std::snprintf(baseq3,sizeof baseq3,"%s",root);
    soundOpen(std::filesystem::u8path(root)/"sound/test.wav");
    expect(soundBusy()&&soundEditorOpen,"audio_background_decode_started");
  }
  if(std::string(mode)=="audio36save") {
    soundFinish();expect(!soundBusy()&&soundPCM.size()==176400,"audio_decoded_two_seconds_stereo");
    soundVolume=.5f;soundSpeed=2;soundStart=.5f;soundEnd=1.5f;soundTrim=true;soundLaunch(true);
  }
  if(std::string(mode)=="audio36check") {
    soundFinish();expect(!soundBusy()&&soundPCM.size()>43000&&soundPCM.size()<45000,"audio_trim_speed_saved_in_original");
    bool backup=false;for(auto& entry:std::filesystem::directory_iterator(soundEditorPath.parent_path()))if(entry.path().extension()==".bak")backup=true;
    expect(backup,"audio_original_backup_retained");soundEditorOpen=false;
  }
  if(std::string(mode)=="ui36") {
    recentWindow=false;uiReset=true;uiTheme=2;uiLanguage=1;frame();frame();
    expect(ImGui::GetStyle().Colors[ImGuiCol_WindowBg].x<.3f&&ImGui::GetStyle().FrameRounding==0,"retro_dark_palette");
    const char* label="File";const char* end=nullptr;FteBroomTranslate(label,end);expect(std::string(label,end)=="Файл","localized_label");
    bool glyphs=true;for(auto& row:uiTranslations)for(int language:{4,5}){const char* p=row[language];while(*p){unsigned int code;int n=ImTextCharFromUtf8(&code,p,nullptr);if(n<=0)break;glyphs&=uiFonts[1]->FindGlyphNoFallback((ImWchar)code)!=nullptr;p+=n;}}
    expect(glyphs,"complete_cjk_catalog_glyphs");
    auto explorer=ImGui::FindWindowByName("Mod file manager");
    expect(explorer&&explorer->Pos.x>=uiScenePos.x-1&&explorer->Pos.x+explorer->Size.x<=uiScenePos.x+uiSceneSize.x+1,"explorer_below_center_only");
  }
  if(std::string(mode)=="light36"){uiTheme=3;uiLanguage=4;frame();expect(ImGui::GetStyle().Colors[ImGuiCol_WindowBg].x>.7f,"modern_light_palette");}
  if(std::string(mode)=="maps36") {
    auto destination=std::filesystem::u8path(root)/"other.map";
    std::ofstream(destination)<<"// Game: Quake 3\n// Format: Quake3 (Valve)\n{\n\"classname\" \"worldspawn\"\n}\n";
    auto previous=documentFile;auto name=documentName;float dirty=cvars->GetFloat("ftebroom_dirty");cvars->SetFloat("ftebroom_dirty",1);
    modFileOpenMap(destination);
    expect(confirmDocument&&documentNext=="@"+destination.u8string()&&documentFile==previous&&documentName==name,"explorer_map_waits_for_unsaved_changes_decision");
    confirmDocument=false;uiClosedDialog="Save changes?";frame();
    expect(documentNext.empty()&&documentFile==previous,"cancel_map_open_preserves_current_document");cvars->SetFloat("ftebroom_dirty",dirty);
  }

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

  if(std::string(mode)=="hidefiles34") {recentWindow=false;modFilesOpen=false;frame();frame();}
  if(std::string(mode)=="viewer34") {modFilesOpen=true;modFilesRoot=modFileRoot();modFilesFolder=modFileRoot()/"models/qa";modFilesRefresh=true;modelViewerShow("models/qa/skeleton.iqm");modelViewerPlay=true;modelViewerBones=true;}
  if(std::string(mode)=="viewer34check") {expect(modelViewerPlay&&cvars->GetFloat("ftebroom_modelviewer_poses")==2,"animation_with_large_thumbnail_survives");}
  if(std::string(mode)=="pak34") {
   recentWindow=false;
   modelViewerOpen=false;modFilesOpen=true;modFilesGrid=true;modFilesRoot=modFileRoot();modFilesFolder=modFileRoot()/"explorer.pak";modFilesRefresh=true;
   auto entries=modFileList(modFilesFolder);expect(entries.size()==2&&entries.front().first,"pak_root_folders");
   auto filesInPak=modFileList(modFilesFolder/"models/qa");expect(filesInPak.size()==1&&!filesInPak.front().first,"pak_nested_files");
   expect(modFileModelPath(filesInPak.front().second)=="models/qa/skeleton.iqm","pak_model_relative_path");
   auto archiveBytes=[](){std::ifstream in(modFileRoot()/"explorer.pak",std::ios::binary);return std::string(std::istreambuf_iterator<char>(in),{});};auto before=archiveBytes();auto target=modFileCopy(filesInPak.front().second,modFileRoot());expect(q1Read(target)==q1Read(filesInPak.front().second),"pak_copy_extracts_exact_bytes");
   expect(archiveBytes()==before,"pak_browse_preserves_archive");
   auto imported=modFileCopy(target,modFilesFolder/"new/models");expect(q1Read(imported)==q1Read(target),"pak_import_file");
   auto originalSound=q1Read(modFilesFolder/"sound/ambient/test.wav");
   ftebroom::pak::rename(imported,modFilesFolder/"new/renamed.iqm");expect(!ftebroom::pak::exists(imported)&&q1Read(modFilesFolder/"new/renamed.iqm")==q1Read(target),"pak_rename_file");
   ftebroom::pak::replace(modFilesFolder/"config/editor.cfg","original\n");modFilesEdit(modFilesFolder/"config/editor.cfg");std::snprintf(modFilesEditBuffer.data(),modFilesEditBuffer.size(),"edited\n");modFilesSaveText();modFilesEditOpen=false;
   expect(q1Read(modFilesFolder/"config/editor.cfg")=="edited\n"&&q1Read(modFilesFolder/"sound/ambient/test.wav")==originalSound,"pak_text_edit_preserves_other_members");
   bool backupFound=false;for(const auto& e:std::filesystem::directory_iterator(modFileRoot()))if(e.path().filename().u8string().rfind("explorer.pak.ftebroom-",0)==0&&e.path().extension()==".bak")backupFound=true;expect(backupFound,"pak_edits_create_backups");
  }
  if(std::string(mode)=="modelindices34") {modFilesOpen=false;frame();frame();
   ftebroom::EntityDefinition d;d.name="stress_model";d.model="models/qa/test.md3";d.brush=false;entityDefinitions[d.name]=d;
   cvars->SetFloat("ftebroom_test_model_previews",1);cvars->SetString("ftebroom_test_entity_filter","stress_model");selectEntityTab=true;frame();frame();
   auto data=ImGui::GetDrawData();bool split=false,large=false,valid=true;
   for(int n=0;n<data->CmdListsCount;++n){auto list=data->CmdLists[n];large|=list->VtxBuffer.Size>65535;
    for(const auto& cmd:list->CmdBuffer){split|=cmd.VtxOffset>0;for(unsigned int i=0;i<cmd.ElemCount;++i){auto offset=cmd.IdxOffset+i;if(offset>=unsigned(list->IdxBuffer.Size)){valid=false;break;}if(list->IdxBuffer[offset]+cmd.VtxOffset>=unsigned(list->VtxBuffer.Size))valid=false;}}
   }
   expect(large&&split&&valid,"model_thumbnail_72k_vertices_valid_offsets");
  }

  if(std::string(mode)=="models"){

   ftebroom::EntityDefinition d;d.name="test_md3";d.model="models/qa/test.md3";d.brush=false;entityDefinitions[d.name]=d;d.name="test_mdl";d.model="models/qa/test.mdl";entityDefinitions[d.name]=d;cvars->SetFloat("ftebroom_test_model_previews",1);cvars->SetString("ftebroom_test_entity_filter","test_");selectEntityTab=true;frame();frame();

   expect(entityPreviews.count("models/qa/test.md3:")&&entityPreviews["models/qa/test.md3:"].parts.size()==2&&entityPreviews["models/qa/test.md3:"].image,"md3_textured_surfaces");expect(entityPreviews.count("models/qa/test.mdl:")&&entityPreviews["models/qa/test.mdl:"].image,"mdl_uploaded_skin");

  }

 }catch(const std::exception& e){core->Print((std::string("FTEBROOM_DESKTOP_FAIL ")+e.what()+"\n").c_str());}

}
