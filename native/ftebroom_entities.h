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
static std::map<int, std::map<std::string, std::string>> entityProperties;
static std::map<std::string, int> entityUsage;
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
      std::string probe;
      path = definitionsReadSource("scripts/entities.def", probe) ? "scripts/entities.def"
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
          << std::quoted(model) << ' ' << std::quoted(d.modelKey) << '\n';
      for (const auto& prop : d.properties)
        out << "property " << std::quoted(d.name) << ' ' << std::quoted(prop.first) << ' '
            << std::quoted(prop.second.value) << '\n';
    }
    out.close();
    if (!out)
      throw std::runtime_error("Cannot write entity definition cache");
    entityDefinitions = std::move(loaded);
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
    if (kind == 'u' && row >> std::quoted(key))
      usage[key]++;
    if (kind == 'd' && row >> std::quoted(path))
    {
    }
  }
  entityProperties = std::move(properties);
  entityUsage = std::move(usage);
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
static void entityPanel()
{
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
      if (ImGui::Button("Reload (F6)"))
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
      std::map<std::string, ftebroom::EntityProperty> known;
      std::set<std::string> keys;
      for (const auto& entity : entityProperties)
      {
        auto classname = entity.second.find("classname");
        if (classname != entity.second.end())
          if (
            auto def = entityDefinitions.find(classname->second);
            def != entityDefinitions.end())
            for (const auto& p : def->second.properties)
            {
              known.emplace(p);
              keys.insert(p.first);
            }
        for (const auto& p : entity.second)
          keys.insert(p.first);
      }
      static bool defaults = true;
      ImGui::Checkbox("Show defaults", &defaults);
      if (ImGui::BeginMenu("Set default properties"))
      {
        for (const char* mode : {"existing", "missing", "all"})
          if (ImGui::MenuItem(mode))
            command((std::string("ftebroom_entity_defaults ") + mode + "\n").c_str());
        ImGui::EndMenu();
      }
      ImGui::BeginChild(
        "Property list",
        {0, 260 * uiScale()},
        ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeY);
      static std::string focusProperty;
      static int focusColumn = 0;
      static std::map<std::string, std::array<char, 4096>> propertyBuffers;
      static std::string editingProperty;
      static int editingColumn = -1;
      static std::vector<int> previousTargets;
      std::vector<int> currentTargets;
      for (const auto& entity : entityProperties)
        currentTargets.push_back(entity.first);
      if (currentTargets != previousTargets)
      {
        if (!editingProperty.empty())
          ImGui::ClearActiveID();
        editingProperty.clear();
        editingColumn = -1;
        propertyBuffers.clear();
        previousTargets = currentTargets;
      }
      const bool propertyTable = ImGui::BeginTable(
        "Properties table",
        2,
        ImGuiTableFlags_Resizable | ImGuiTableFlags_BordersInnerV
          | ImGuiTableFlags_RowBg);
      if (propertyTable)
      {
        ImGui::TableSetupColumn("Key", ImGuiTableColumnFlags_WidthStretch, 0.4f);
        ImGui::TableSetupColumn("Value", ImGuiTableColumnFlags_WidthStretch, 0.6f);
        ImGui::TableHeadersRow();
        for (const auto& key : keys)
        {
          if (key.rfind("_tb_", 0) == 0)
            continue;
          bool first = true, mixed = false, anyExplicit = false, allExplicit = true;
          std::string value;
          for (const auto& entity : entityProperties)
          {
            auto found = entity.second.find(key);
            anyExplicit |= found != entity.second.end();
            allExplicit &= found != entity.second.end();
            std::string current;
            if (found != entity.second.end())
              current = found->second;
            else if (
              auto cls = entity.second.find("classname"); cls != entity.second.end())
              if (
                auto def = entityDefinitions.find(cls->second);
                def != entityDefinitions.end())
                if (
                  auto property = def->second.properties.find(key);
                  property != def->second.properties.end())
                  current = property->second.value;
            if (first)
            {
              value = current;
              first = false;
            }
            else if (value != current)
              mixed = true;
          }
          if (!anyExplicit && !defaults)
            continue;
          ImGui::PushID(key.c_str());
          ImGui::TableNextRow();
          ImGui::TableSetColumnIndex(0);
          if (!allExplicit)
            ImGui::PushStyleColor(
              ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
          auto definition = known.find(key);
          std::string label = key;
          if (definition != known.end() && !definition->second.label.empty())
            label = definition->second.label + " (" + key + ")";
          auto& keyBuffer = propertyBuffers["key/" + key];
          if (editingProperty != key || editingColumn != 0)
            std::snprintf(keyBuffer.data(), keyBuffer.size(), "%s", key.c_str());
          if (focusProperty == key && focusColumn == 0)
          {
            ImGui::SetKeyboardFocusHere();
            focusProperty.clear();
          }
          ImGui::SetNextItemWidth(-1);
          bool keyEnter = ImGui::InputText(
            "##key",
            keyBuffer.data(),
            keyBuffer.size(),
            ImGuiInputTextFlags_EnterReturnsTrue
              | (key == "classname" ? ImGuiInputTextFlags_ReadOnly : 0));
          entityTestItem("key/" + key);
          if (ImGui::IsItemActive())
          {
            editingProperty = key;
            editingColumn = 0;
          }
          if (
            (keyEnter || ImGui::IsItemDeactivatedAfterEdit()) && key != keyBuffer.data())
          {
            entityProperty("rename", key, keyBuffer.data());
            // Renaming changes the row's ImGui ID; restore the Tab destination
            // after QC publishes the renamed property on the following frame.
            if (!keyEnter)
            {
              focusProperty = keyBuffer.data();
              focusColumn = ImGui::GetIO().KeyShift ? 0 : 1;
            }
          }
          if (keyEnter)
          {
            auto next = keys.upper_bound(key);
            if (next != keys.end())
            {
              focusProperty = *next;
              focusColumn = 0;
            }
          }
          if (!allExplicit)
            ImGui::PopStyleColor();
          if (ImGui::IsItemHovered() && definition != known.end())
            ImGui::SetTooltip("%s", definition->second.description.c_str());
          ImGui::TableSetColumnIndex(1);
          bool internal = key == "model" && !value.empty() && value[0] == '*';
          ImGui::BeginDisabled(internal);
          auto& buffer = propertyBuffers["value/" + key];
          if (editingProperty != key || editingColumn != 1)
            std::snprintf(buffer.data(), buffer.size(), "%s", mixed ? "" : value.c_str());
          if (focusProperty == key && focusColumn == 1)
          {
            ImGui::SetKeyboardFocusHere();
            focusProperty.clear();
          }
          ImGui::SetNextItemWidth(-1);
          bool valueEnter = ImGui::InputTextWithHint(
            "##value",
            mixed ? "<multiple values>" : "",
            buffer.data(),
            buffer.size(),
            ImGuiInputTextFlags_EnterReturnsTrue);
          entityTestItem("value/" + key);
          if (ImGui::IsItemActive())
          {
            editingProperty = key;
            editingColumn = 1;
          }
          if (valueEnter || ImGui::IsItemDeactivatedAfterEdit())
            if (mixed || value != buffer.data())
              entityProperty("set", key, buffer.data());
          if (valueEnter)
          {
            auto next = keys.upper_bound(key);
            if (next != keys.end())
            {
              focusProperty = *next;
              focusColumn = 1;
            }
          }
          if (ImGui::BeginPopupContextItem("Property actions"))
          {
            if (ImGui::MenuItem("Remove property", nullptr, false, key != "classname"))
              entityProperty("remove", key);
            if (
              ImGui::MenuItem(
                "Reset to default", nullptr, false, definition != known.end()))
              entityProperty("remove", key);
            static char renamed[256]{};
            ImGui::InputText("New key", renamed, sizeof renamed);
            if (ImGui::Button("Rename") && *renamed)
            {
              entityProperty("rename", key, renamed);
              ImGui::CloseCurrentPopup();
            }
            ImGui::EndPopup();
          }
          if (definition != known.end())
          {
            auto& prop = definition->second;
            if (prop.type == "flags")
            {
              unsigned flags = 0;
              try
              {
                flags = std::stoul(value);
              }
              catch (...)
              {
              }
              for (const auto& choice : prop.choices)
              {
                unsigned bit = 0;
                try
                {
                  bit = std::stoul(choice.value);
                }
                catch (...)
                {
                  continue;
                }
                bool enabled = (flags & bit) != 0, bitMixed = false, firstBit = true;
                for (const auto& entity : entityProperties)
                {
                  std::string flagValue;
                  auto found = entity.second.find(key);
                  if (found != entity.second.end())
                    flagValue = found->second;
                  else if (
                    auto cls = entity.second.find("classname");
                    cls != entity.second.end())
                    if (
                      auto def = entityDefinitions.find(cls->second);
                      def != entityDefinitions.end())
                      if (
                        auto p = def->second.properties.find(key);
                        p != def->second.properties.end())
                        flagValue = p->second.value;
                  unsigned currentFlags = 0;
                  try
                  {
                    currentFlags = std::stoul(flagValue);
                  }
                  catch (...)
                  {
                  }
                  bool current = (currentFlags & bit) != 0;
                  if (firstBit)
                  {
                    enabled = current;
                    firstBit = false;
                  }
                  else
                    bitMixed |= enabled != current;
                }
                if (bitMixed)
                  ImGui::PushItemFlag(ImGuiItemFlags_MixedValue, true);
                bool changed = ImGui::Checkbox(choice.label.c_str(), &enabled);
                if (bitMixed)
                  ImGui::PopItemFlag();
                if (changed)
                  entityProperty(
                    enabled ? "setflag" : "clearflag", key, std::to_string(bit));
              }
            }
            else if (!prop.choices.empty())
            {
              if (
                ImGui::BeginCombo("Choose", mixed ? "<multiple values>" : value.c_str()))
              {
                for (const auto& choice : prop.choices)
                  if (ImGui::Selectable(choice.label.c_str(), choice.value == value))
                    entityProperty("set", key, choice.value);
                ImGui::EndCombo();
              }
            }
            else if (prop.type == "color" || prop.type == "color255" || key == "_color")
            {
              static std::map<std::string, std::array<float, 3>> colorBuffers;
              static std::string activeColor;
              auto& rgb = colorBuffers[key];
              if (activeColor != key)
              {
                rgb = {1, 1, 1};
                std::sscanf(value.c_str(), "%f %f %f", &rgb[0], &rgb[1], &rgb[2]);
                if (prop.type == "color255")
                  for (auto& c : rgb)
                    c /= 255;
              }
              bool changed = ImGui::ColorEdit3("Color", rgb.data());
              if (ImGui::IsItemActive() || changed)
                activeColor = key;
              if (ImGui::IsItemDeactivatedAfterEdit())
              {
                std::ostringstream out;
                float scale = prop.type == "color255" ? 255 : 1;
                out << rgb[0] * scale << ' ' << rgb[1] * scale << ' ' << rgb[2] * scale;
                entityProperty("set", key, out.str());
                activeColor.clear();
              }
            }
          }
          ImGui::EndDisabled();
          ImGui::PopID();
        }
        ImGui::EndTable();
      }
      if (!ImGui::IsAnyItemActive())
      {
        editingProperty.clear();
        editingColumn = -1;
      }
      ImGui::EndChild();
      if (ImGui::Button("+ New property") ||
          (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) &&
           ImGui::GetIO().KeyCtrl && ImGui::IsKeyPressed(ImGuiKey_Enter, false)))
      {
        int number = 1;
        while (keys.count("property " + std::to_string(number)))
          ++number;
        focusProperty = "property " + std::to_string(number);
        focusColumn = 0;
        entityProperty("set", focusProperty, "");
      }
      static char key[256]{}, value[1024]{};
      ImGui::InputText("Key", key, sizeof key);
      ImGui::InputText("Value", value, sizeof value);
      if (ImGui::Button("Add / set property") && *key)
        entityProperty("set", key, value);
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
      ImGui::TextDisabled("Double-click a class to create it.");
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
      for (const auto* def : classes)
      {
        auto prefix = def->name.substr(0, def->name.find('_'));
        if (grouped && prefix != group)
        {
          group = prefix;
          ImGui::SeparatorText(group.c_str());
        }
        ImGui::PushID(def->name.c_str());
        ImVec2 tile = ImGui::GetCursorScreenPos();
        float size = 42 * uiScale();
        ImGui::Dummy({size, size});
        ImVec2 points[8];
        float extent = 1;
        for (int axis = 0; axis < 3; ++axis)
          extent = std::max(extent, def->maxs[axis] - def->mins[axis]);
        for (int corner = 0; corner < 8; ++corner)
        {
          float v[3];
          for (int axis = 0; axis < 3; ++axis)
            v[axis] = ((corner & (1 << axis)) ? 0.5f : -0.5f)
                      * (def->maxs[axis] - def->mins[axis]) / extent;
          points[corner] = {
            tile.x + size * (0.5f + 0.55f * (v[0] - v[1])),
            tile.y + size * (0.5f + 0.25f * (v[0] + v[1]) - 0.65f * v[2])};
        }
        auto color = ImGui::ColorConvertFloat4ToU32(
          {def->color[0], def->color[1], def->color[2], 1});
        for (int corner = 0; corner < 8; ++corner)
          for (int axis = 0; axis < 3; ++axis)
            if (!(corner & (1 << axis)))
              ImGui::GetWindowDrawList()->AddLine(
                points[corner], points[corner | (1 << axis)], color, uiScale());
        ImGui::SameLine();
        if (
          ImGui::Selectable(
            (def->name + "  (" + std::to_string(entityUsage[def->name]) + ")").c_str(),
            false,
            ImGuiSelectableFlags_AllowDoubleClick))
          if (ImGui::IsMouseDoubleClicked(0))
            entityCreate(*def, position);
        if (ImGui::IsItemHovered())
          ImGui::SetTooltip(
            "%s\n%s",
            def->brush ? "Brush entity: select brushes first" : "Point entity",
            def->description.c_str());
        if (!def->brush && ImGui::BeginDragDropSource())
        {
          ImGui::SetDragDropPayload(
            "FTE_ENTITY", def->name.c_str(), def->name.size() + 1);
          ImGui::TextUnformatted(def->name.c_str());
          cvars->SetString("ftebroom_entity_ghost", def->name.c_str());
          ImGui::EndDragDropSource();
        }
        ImGui::PopID();
      }
      ImGui::EndChild();
    }
  }
  ImGui::End();
  selectEntityTab = false;
}
