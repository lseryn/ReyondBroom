// SPDX-License-Identifier: GPL-2.0-or-later
struct EntityListEntry {int id=0,kind=0,flags=0;std::string name,classname,search;};
static std::vector<EntityListEntry> entityListEntries;
static std::vector<int> entityListMatches;
static int entityListEpoch=-1,entityListMapEpoch=-1;
static bool entityListWindow=false;
static char entityListFilter[256]{};
static std::string entityListLastFilter;
static void entityListLoad(){
  int epoch=(int)cvars->GetFloat("ftebroom_tree_epoch");
  if(epoch!=entityListEpoch||entityListMapEpoch!=organizationMapEpoch){
    std::ifstream input(documentPath("data/ftebroom-entity-list.txt"));std::vector<EntityListEntry> next;EntityListEntry e;
    while(next.size()<65536&&input>>e.id>>e.kind>>e.flags>>std::quoted(e.name)>>std::quoted(e.classname)){
      e.search=entityLower(e.name+" "+e.classname+" "+(e.kind==2?"group":"entity"));next.push_back(e);
    }
    if(!input.eof())return;
    std::stable_sort(next.begin(),next.end(),[](const auto& a,const auto& b){return a.search<b.search;});entityListEntries=std::move(next);
    entityListEpoch=epoch;entityListMapEpoch=organizationMapEpoch;entityListLastFilter="\xff";
  }
  auto filter=entityLower(entityListFilter);if(filter!=entityListLastFilter){entityListLastFilter=filter;entityListMatches.clear();for(int i=0;i<(int)entityListEntries.size();i++)if(entityListEntries[i].search.find(filter)!=std::string::npos)entityListMatches.push_back(i);}
}
static void entityListPanel(){
  if(!entityListWindow)return;auto viewport=ImGui::GetMainViewport();ImGui::SetNextWindowSize({std::min(540*uiScale(),viewport->WorkSize.x-20),std::min(460*uiScale(),viewport->WorkSize.y-30)},ImGuiCond_FirstUseEver);
  ImGui::SetNextWindowPos({viewport->WorkPos.x+viewport->WorkSize.x*.5f,viewport->WorkPos.y+viewport->WorkSize.y*.5f},ImGuiCond_FirstUseEver,{.5f,.5f});
  if(ImGui::Begin("Entity list",&entityListWindow)){
    ImGui::InputText("Filter name / class",entityListFilter,sizeof entityListFilter);entityListLoad();ImGui::TextDisabled("%d / %d objects. Double-click to select and focus.",int(entityListMatches.size()),int(entityListEntries.size()));
    ImGui::BeginChild("Entity results",{0,0});ImGuiListClipper clipper;clipper.Begin(entityListMatches.size());
    while(clipper.Step())for(int row=clipper.DisplayStart;row<clipper.DisplayEnd;row++){
      const auto& entry=entityListEntries[entityListMatches[row]];ImGui::PushID(entry.id);auto pos=ImGui::GetCursorScreenPos();
      if(ImGui::Selectable("##entry",false,ImGuiSelectableFlags_AllowDoubleClick,{0,ImGui::GetTextLineHeight()})&&ImGui::IsMouseDoubleClicked(0))organize("focus",entry.id);
      auto label=(entry.kind==2?"Group: ":"Entity: ")+entry.name;if(entry.kind!=2&&entry.name!=entry.classname)label+="  ("+entry.classname+")";
      auto end=ImGui::GetItemRectMax();auto draw=ImGui::GetWindowDrawList();draw->PushClipRect(pos,end,true);draw->AddText(pos,ImGui::GetColorU32(ImGuiCol_Text),label.c_str());draw->PopClipRect();
      if(ImGui::IsItemHovered())ImGui::SetTooltip("%s",label.c_str());ImGui::PopID();
    }ImGui::EndChild();
  }ImGui::End();
}
