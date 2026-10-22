// SPDX-License-Identifier: GPL-2.0-or-later
#include "ftebroom_entity_defs.h"
static std::string entityLower(std::string value)
{
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
    return char(std::tolower(c));
  });
  return value;
}
static ftebroom::EntityDefinitions entityDefinitions;
static int entityDefinitionEpoch = 0;
static bool entityPropertyFocused = false;
static std::map<int, std::map<std::string, std::string>> entityProperties;
static std::map<std::string, int> entityUsage;
static std::set<std::string> entityMapColors;
static std::string definitionSource, definitionError, definitionMapPath;
static std::map<std::string, ImVec2> entityTestItems;
static void entityTestItem(const std::string& name)
{
  if (cvars->GetFloat("ftebroom_skip_setup"))
  {
    auto a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
    entityTestItems[name] = {(a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f};
  }
}
static bool selectEntityTab = false, definitionRequestPending = false;
static bool definitionsReadSource(const std::string& path, std::string& source)
{
  std::ifstream in(std::filesystem::u8path(path), std::ios::binary);
  if (in)
  {
    source.assign(std::istreambuf_iterator<char>(in), {});
    return true;
  }
  size_t size = 0;
  auto data = (char*)files->LoadFile(path.c_str(), &size);
  if (!data)
    return false;
  source.assign(data, size);
  core->Free(data);
  return true;
}
static std::string definitionsExpand(
  const std::string& path, std::set<std::string>& stack)
{
  if (stack.size() > 32 || !stack.insert(path).second)
    throw std::runtime_error("Cyclic or excessively deep FGD include: " + path);
  std::string source;
  if (!definitionsReadSource(path, source))
    throw std::runtime_error("Cannot read entity definitions: " + path);
  if (source.size() > 16 * 1024 * 1024)
    throw std::runtime_error("Definition file exceeds 16 MiB");
  // Includes occupy their own directive line; leave comments and descriptions intact.
  std::istringstream lines(source);
  std::string line, result;
  while (std::getline(lines, line))
  {
    auto trimmed = ftebroom::entityTrim(line);
    if (trimmed.rfind("@include", 0) == 0)
    {
      auto words = ftebroom::entityTokens(trimmed);
      if (words.size() != 2)
        throw std::runtime_error("Malformed FGD include");
      auto included = (std::filesystem::u8path(path).parent_path()
                       / std::filesystem::u8path(words[1].text))
                        .lexically_normal()
                        .generic_u8string();
      result += definitionsExpand(included, stack) + "\n";
    }
    else
      result += line + "\n";
    if (result.size() > 16 * 1024 * 1024)
      throw std::runtime_error("Expanded definitions exceed 16 MiB");
  }
  stack.erase(path);
  return result;
}
static void definitionsLoadCommand()
{
  if (commands->IsInsecure())
    return;
  char argument[4096]{};
  commands->Argv(1, argument, sizeof argument);
  std::string path = argument;
  if (path.empty())
    path = definitionMapPath;
  if (path.rfind("external:", 0) == 0)
    path = path.substr(9);
  if (path.rfind("builtin:", 0) == 0)
    path.clear();
  try
  {
    if (path.empty())
    {
      path=gameDefinitionPath();
      std::string probe;
      if(path.empty())path = definitionsReadSource("scripts/entities.def", probe) ? "scripts/entities.def"
                                                                  : "entities.ent";
    }
    std::set<std::string> includes;
    auto source = definitionsExpand(path, includes);
    auto loaded =
      ftebroom::entityRead(source, std::filesystem::u8path(path).extension().u8string());
    std::ofstream out(documentPath("ftebroom-entity-definitions.txt"), std::ios::binary);
    for (const auto& item : loaded)
    {
      const auto& d = item.second;
      auto vec = [](const auto& v) {
        std::ostringstream s;
        s << v[0] << ' ' << v[1] << ' ' << v[2];
        return s.str();
      };
      // Expressions remain in the inspector; only literal model paths reach the renderer.
      std::string model = d.model;
      if (model.find_first_of("{}()\"'") != std::string::npos)
        model.clear();
      out << std::quoted(d.name) << ' ' << std::quoted(vec(d.mins)) << ' '
          << std::quoted(vec(d.maxs)) << ' ' << std::quoted(vec(d.color)) << ' '
          << std::quoted(model) << ' ' << std::quoted(d.modelKey) << ' '
          << std::quoted(d.modelSkin) << ' ' << std::quoted(d.modelFrame) << ' '
          << std::quoted(d.modelScale) << '\n';
      out << "kind " << std::quoted(d.name) << ' ' << (d.brush ? 1 : 0) << '\n';
      for (const auto& prop : d.properties)
        out << "property " << std::quoted(d.name) << ' ' << std::quoted(prop.first) << ' '
            << std::quoted(prop.second.value) << '\n';
    }
    out.close();
    if (!out)
      throw std::runtime_error("Cannot write entity definition cache");
    entityDefinitions = std::move(loaded);
    ++entityDefinitionEpoch;
    definitionSource = path;
    definitionError.clear();
    command("ftebroom_entity_definitions_loaded\n");
    core->Print(("FTEBroom: loaded " + std::to_string(entityDefinitions.size())
                 + " entity definitions from " + path + "\n")
                  .c_str());
  }
  catch (const std::exception& e)
  {
    definitionError = e.what();
    core->Print(("FTEBroom: " + definitionError + "\n").c_str());
  }
  definitionRequestPending = false;
}
static void definitionsChoose(const std::filesystem::path& path)
{
  auto name = path.generic_u8string();
  command(("ftebroom_entity_definition_path " + organizationQuote("external:" + name)
           + "\nftebroom_definitions " + organizationQuote(name) + "\n")
            .c_str());
}
static int entitySelectionEpoch = -1;
static void entitySelectionLoad()
{
  auto& epoch = entitySelectionEpoch;
  int next = (int)cvars->GetFloat("ftebroom_property_epoch");
  if (next == epoch)
    return;
  std::ifstream in(documentPath("data/ftebroom-entity-selection.txt"));
  if (!in)
    return;
  std::map<int, std::map<std::string, std::string>> properties;
  std::map<std::string, int> usage;
  std::set<std::string> colors;
  std::string line, path;
  while (std::getline(in, line))
  {
    std::istringstream row(line);
    char kind;
    int id;
    std::string key, value;
    if (!(row >> kind >> id))
      continue;
    if (kind == 'e')
      properties[id];
    if (kind == 'p' && row >> std::quoted(key) >> std::quoted(value))
      properties[id][key] = value;
    if (kind == 'c' && row >> std::quoted(key))
      colors.insert(key);
    if (kind == 'u' && row >> std::quoted(key))
      usage[key]++;
    if (kind == 'd' && row >> std::quoted(path))
    {
    }
  }
  entityProperties = std::move(properties);
  entityUsage = std::move(usage);
  entityMapColors = std::move(colors);
  epoch = next;
  if (definitionMapPath != path || (entityDefinitions.empty() && definitionError.empty()))
  {
    definitionMapPath = path;
    if (!definitionRequestPending)
    {
      definitionRequestPending = true;
      command("ftebroom_definitions\n");
    }
  }
}
static void entityProperty(
  const char* op, const std::string& key, const std::string& value = "")
{
  command(("ftebroom_entity_property " + std::string(op) + " " + organizationQuote(key)
           + " " + organizationQuote(value) + "\n")
            .c_str());
}
static void entityCreate(const ftebroom::EntityDefinition& d, const float* position)
{
  std::ostringstream point;
  point << position[0] << ' ' << position[1] << ' ' << position[2];
  command(("ftebroom_entity_create " + organizationQuote(d.name) + " "
           + (d.brush ? "1 " : "0 ") + organizationQuote(point.str()) + "\n")
            .c_str());
}
#include "ftebroom_property_table.h"
static void entityPanel()
{
  entityPropertyFocused = false;
  entitySelectionLoad();
  cvars->SetString("ftebroom_entity_ghost", "");
  if (selectEntityTab)
    ImGui::SetNextWindowFocus();
  if (ImGui::Begin("Entity", nullptr, uiPanelFlags()))
  {
    if (ImGui::CollapsingHeader("Entity definitions"))
    {
      ImGui::TextWrapped("%s", definitionSource.c_str());
      if (ImGui::Button("Browse definitions..."))
        definitionsRequest = true;
      ImGui::SameLine();
      if (ImGui::Button("Reload"))
        command("ftebroom_definitions\n");
      if (ImGui::Button("Use game defaults"))
      {
        definitionMapPath.clear();
        command("ftebroom_entity_definition_path \"\"\nftebroom_definitions\n");
      }
      if (!definitionError.empty())
        ImGui::TextWrapped("%s", definitionError.c_str());
    }
    bool instantiateDefaults = cvars->GetFloat("ftebroom_instantiate_defaults") != 0;
    if (ImGui::Checkbox("Instantiate defaults on creation", &instantiateDefaults))
      cvars->SetFloat("ftebroom_instantiate_defaults", instantiateDefaults);
    if (ImGui::CollapsingHeader("Properties", ImGuiTreeNodeFlags_DefaultOpen))
    {
      ImGui::Text(
        "Editing %u entit%s",
        (unsigned)entityProperties.size(),
        entityProperties.size() == 1 ? "y" : "ies");
      entityPropertyTable();
    }
    if (ImGui::CollapsingHeader("Entity browser", ImGuiTreeNodeFlags_DefaultOpen))
    {
      static char filter[256]{};
      static bool used = false, grouped = true;
      static int kind = 0, sort = 0;
      static float position[3] = {0, 0, 64};
      ImGui::InputTextWithHint("##classfilter", "Filter classes", filter, sizeof filter);
      ImGui::Checkbox("Used only", &used);
      ImGui::SameLine();
      ImGui::Checkbox("Group by prefix", &grouped);
      ImGui::Combo("Type", &kind, "All\0Point\0Brush\0");
      ImGui::Combo("Sort", &sort, "Name\0Usage\0");
      ImGui::InputFloat3("Create at", position);
      static int thumbnailSize=80;
      ImGui::SliderInt("Thumbnail size",&thumbnailSize,48,160);
      ImGui::TextWrapped("Click: change selected entity class. Double-click: create. Drag a point entity into a viewport to place it.");
      std::vector<const ftebroom::EntityDefinition*> classes;
      std::string query = entityLower(filter);
      for (const auto& item : entityDefinitions)
      {
        const auto& d = item.second;
        if (
          d.name == "worldspawn" || (used && !entityUsage[d.name])
          || (kind == 1 && d.brush) || (kind == 2 && !d.brush)
          || entityLower(d.name).find(query) == std::string::npos)
          continue;
        classes.push_back(&d);
      }
      std::stable_sort(classes.begin(), classes.end(), [&](auto a, auto b) {
        if (sort && entityUsage[a->name] != entityUsage[b->name])
          return entityUsage[a->name] > entityUsage[b->name];
        return a->name < b->name;
      });
      ImGui::BeginChild(
        "Classes",
        {0, 220 * uiScale()},
        ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeY);
      std::string group;
      int column=0;
      float size=thumbnailSize*uiScale(),rowTop=ImGui::GetCursorPosY();
      float cellWidth=size+12*uiScale(),cellHeight=size+ImGui::GetTextLineHeightWithSpacing()*2+8;
      int columns=std::max(1,int(ImGui::GetContentRegionAvail().x/cellWidth));
      static std::string chosen;
      for (const auto* def : classes)
      {
        auto prefix=def->name.substr(0,def->name.find('_'));
        if(grouped && prefix!=group) {
          if(column){ImGui::SetCursorPosY(rowTop+cellHeight);column=0;}
          group=prefix;ImGui::SeparatorText(group.c_str());rowTop=ImGui::GetCursorPosY();
        }
        ImGui::SetCursorPos({8+column*cellWidth,rowTop});ImGui::PushID(def->name.c_str());
        ImVec2 tile=ImGui::GetCursorScreenPos();
        bool selected=chosen==def->name;
        for(const auto& e:entityProperties){auto c=e.second.find("classname");if(e.first>0 && c!=e.second.end() && c->second==def->name)selected=true;}
        if(ImGui::InvisibleButton("tile",{size,cellHeight-4})) {
          chosen=def->name;
          bool hasEntity=false,compatible=true;
          for(const auto& e:entityProperties)if(e.first>0) {
            hasEntity=true;auto model=e.second.find("model");
            bool brush=model!=e.second.end() && !model->second.empty() && model->second[0]=='*';
            auto groupType=e.second.find("_tb_type");
            if(brush!=def->brush || groupType!=e.second.end())compatible=false;
          }
          if(hasEntity && compatible)
            command(("ftebroom_entity_property set classname "+organizationQuote(def->name)+"\n").c_str());
          else if(hasEntity)cvars->SetString("ftebroom_selection_status","Choose a compatible point/brush entity class; groups cannot be reclassified.");
          else if(ImGui::IsMouseDoubleClicked(0))entityCreate(*def,position);
        }
        entityTestItem("class:"+def->name);
        if(!def->brush && ImGui::BeginDragDropSource()) {
          ImGui::SetDragDropPayload("FTE_ENTITY",def->name.c_str(),def->name.size()+1);
          ImGui::TextUnformatted(def->name.c_str());cvars->SetString("ftebroom_entity_ghost",def->name.c_str());ImGui::EndDragDropSource();
        }
        auto drawList=ImGui::GetWindowDrawList();
        drawList->AddRectFilled(tile,{tile.x+size,tile.y+size},IM_COL32(55,58,62,255));
        ImVec2 points[8];float extent=1;
        for(int axis=0;axis<3;axis++)extent=std::max(extent,def->maxs[axis]-def->mins[axis]);
        for(int corner=0;corner<8;corner++) {
          float v[3];for(int axis=0;axis<3;axis++)v[axis]=((corner&(1<<axis))?0.5f:-0.5f)*(def->maxs[axis]-def->mins[axis])/extent;
          points[corner]={tile.x+size*(.5f+.55f*(v[0]-v[1])),tile.y+size*(.5f+.25f*(v[0]+v[1])-.65f*v[2])};
        }
        auto color=ImGui::ColorConvertFloat4ToU32({def->color[0],def->color[1],def->color[2],1});
        for(int corner=0;corner<8;corner++)for(int axis=0;axis<3;axis++)if(!(corner&(1<<axis)))
          drawList->AddLine(points[corner],points[corner|(1<<axis)],color,uiScale());
        if(selected)drawList->AddRect(tile,{tile.x+size,tile.y+size},IM_COL32(225,95,55,255),0,0,2);
        drawList->PushClipRect({tile.x,tile.y+size+2},{tile.x+size,tile.y+cellHeight-2},true);
        drawList->AddText({tile.x,tile.y+size+2},ImGui::GetColorU32(ImGuiCol_Text),def->name.c_str());drawList->PopClipRect();
        if(ImGui::IsItemHovered())ImGui::SetTooltip("%s\n%s\n%s",def->name.c_str(),def->brush?"Brush entity: select brushes first":"Point entity",def->description.c_str());
        ImGui::PopID();
        if(++column==columns){column=0;rowTop+=cellHeight;}
      }
      ImGui::SetCursorPosY(rowTop+(column?cellHeight:0));ImGui::Dummy({0,0});
      ImGui::EndChild();
    }
  }
  ImGui::End();
  selectEntityTab = false;
}
