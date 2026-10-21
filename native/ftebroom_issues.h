// SPDX-License-Identifier: GPL-2.0-or-later
static bool issuesWindow;
static void issuesPanel()
{
  cvars->SetFloat("ftebroom_issues_visible",issuesWindow);
  if(!issuesWindow)return;
  struct Issue {int index,type,model,id,line;std::string message,fix,key;};
  static std::vector<Issue> items;static int epoch=-1;
  int current=(int)cvars->GetFloat("ftebroom_issues_epoch");
  if(current!=epoch)
  {
    std::ifstream stream(documentPath("data/ftebroom-issues.txt"));int fileEpoch;
    std::string mods;
    if(stream>>fileEpoch>>std::quoted(mods))
    {
      items.clear();Issue issue;
      while(stream>>issue.index>>issue.type>>issue.model>>issue.id>>issue.line>>std::quoted(issue.message)>>std::quoted(issue.fix)>>std::quoted(issue.key))items.push_back(issue);
      if(*baseq3) {
        std::istringstream list(mods);std::string mod;
        while(std::getline(list,mod,';'))if(!mod.empty()) {
          std::error_code error;auto path=std::filesystem::u8path(baseq3).parent_path()/std::filesystem::u8path(mod);
          if(!std::filesystem::is_directory(path,error))items.push_back({-1,18,0,0,0,"Missing mod directory: "+mod,"Remove Mod",mod});
        }
      }
      epoch=fileEpoch;
    }
  }
  static std::set<std::string> hidden;static bool showHidden=false;
  static std::array<bool,19> enabled=[](){std::array<bool,19> a;a.fill(true);return a;}();
  const char* types[]={"Empty group","Missing classname","Missing definition","Empty brush entity","Point entity with brushes","Empty property key","Empty property value","Long property key","Long property value","Quotation marks","Backslash paths","Missing link target","Missing link source","Invalid UV scale","Non-integer vertices","World bounds","Soft map bounds","Mixed content flags","Missing mod directory"};
  ImGui::SetNextWindowSize({720,380},ImGuiCond_FirstUseEver);
  if(ImGui::Begin("Issues",&issuesWindow,uiPanelFlags()))
  {
    if(ImGui::Button("Refresh"))command("ftebroom_issue scan\n");ImGui::SameLine();
    if(ImGui::Button("Filter"))ImGui::OpenPopup("Issue filters");
    if(ImGui::BeginPopup("Issue filters")){for(int i=0;i<19;++i)ImGui::Checkbox(types[i],&enabled[i]);ImGui::EndPopup();}
    ImGui::SameLine();ImGui::Checkbox("Show hidden issues",&showHidden);
    ImGui::Text("%zu issues. Right-click a row for fixes or Hide/Show.",items.size());
    if(ImGui::BeginTable("Issue list",2,ImGuiTableFlags_Borders|ImGuiTableFlags_ScrollY|ImGuiTableFlags_RowBg,{0,0}))
    {
      ImGui::TableSetupColumn("MAP line",ImGuiTableColumnFlags_WidthFixed,75);ImGui::TableSetupColumn("Issue");ImGui::TableHeadersRow();
      for(const auto& issue:items)
      {
        if(issue.type<0||issue.type>=19||!enabled[issue.type])continue;
        const auto key=std::to_string(issue.type)+":"+std::to_string(issue.model)+":"+std::to_string(issue.id)+":"+issue.key;
        bool isHidden=hidden.count(key);if(isHidden&&!showHidden)continue;
        ImGui::PushID(key.c_str());ImGui::TableNextRow();ImGui::TableNextColumn();
        if(issue.line)ImGui::Text("%d",issue.line);else ImGui::TextDisabled("New");
        ImGui::TableNextColumn();if(isHidden)ImGui::PushStyleColor(ImGuiCol_Text,ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        const auto suffix=std::to_string(issue.index)+" "+std::to_string(epoch)+"\n";
        if(ImGui::Selectable(issue.message.c_str(),false,ImGuiSelectableFlags_SpanAllColumns))action(("ftebroom_issue select "+suffix).c_str());
        if(ImGui::BeginPopupContextItem())
        {
          if(ImGui::MenuItem("Select and focus"))action(("ftebroom_issue select "+suffix+"ftebroom_camera_focus\n").c_str());
          if(!issue.fix.empty()&&ImGui::BeginMenu("Fix")){if(ImGui::MenuItem(issue.fix.c_str()))action((issue.type==18?"ftebroom_issue removemod "+organizationQuote(issue.key)+" "+std::to_string(epoch)+"\n":"ftebroom_issue fix "+suffix).c_str());ImGui::EndMenu();}
          if(ImGui::MenuItem(isHidden?"Show":"Hide")){if(isHidden)hidden.erase(key);else hidden.insert(key);}
          ImGui::EndPopup();
        }
        if(isHidden)ImGui::PopStyleColor();ImGui::PopID();
      }
      ImGui::EndTable();
    }
  }
  ImGui::End();
}
