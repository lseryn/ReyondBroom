// SPDX-License-Identifier: GPL-2.0-or-later
static void publishMaterialTags()
{
  std::ofstream out(documentPath("ftebroom-material-tags.txt"));
  for (const auto& item : materials)
  {
    auto name = item.first;
    if (name.rfind("textures/", 0) == 0)
      name = name.substr(9);
    out << std::quoted(name) << ' ' << item.second.tags << ' '
        << std::quoted(item.second.preview) << '\n';
  }
  out.close();
  if (out)
    cvars->SetFloat(
      "ftebroom_material_tag_epoch", cvars->GetFloat("ftebroom_material_tag_epoch") + 1);
}
static void viewOption(const char* label, const char* cvar)
{
  bool value = cvars->GetFloat(cvar) != 0;
  if (ImGui::Checkbox(label, &value))
    cvars->SetFloat(cvar, value);
}
static void viewOptionsPanel()
{
  if (!ImGui::CollapsingHeader("View options"))
    return;
  viewOption("Brushes", "ftebroom_show_brushes");
  viewOption("Sky surface overlays", "ftebroom_sky_overlays");
  const char* tags[] = {
    "Trigger",
    "Clip",
    "Caulk",
    "Hint",
    "Detail",
    "Liquid",
    "Translucent",
    "Areaportal",
    "Clusterportal"};
  int hidden = (int)cvars->GetFloat("ftebroom_hidden_tags");
  for (int i = 0; i < 9; i++)
  {
    bool show = !(hidden & (1 << i));
    if (ImGui::Checkbox(tags[i], &show))
    {
      hidden = show ? hidden & ~(1 << i) : hidden | (1 << i);
      cvars->SetFloat("ftebroom_hidden_tags", float(hidden));
    }
    if (i % 3 != 2)
      ImGui::SameLine();
  }
  ImGui::SeparatorText("Entities");
  viewOption("Point entities", "ftebroom_show_points");
  viewOption("Models", "ftebroom_show_models");
  viewOption("Class names", "ftebroom_show_entity_names");
  viewOption("Point bounds", "ftebroom_show_entity_bounds");
  viewOption("Group bounds", "ftebroom_show_group_bounds");
  viewOption("Brush entity bounds", "ftebroom_show_brush_entity_bounds");
  static char query[128]{};
  ImGui::InputTextWithHint(
    "##classvisibility", "Filter entity classes", query, sizeof query);
  char hiddenBuffer[16384]{};
  cvars->GetString("ftebroom_hidden_classes", hiddenBuffer, sizeof hiddenBuffer);
  std::string hiddenClasses = hiddenBuffer;
  if (ImGui::Button("Show all classes"))
    cvars->SetString("ftebroom_hidden_classes", "");
  ImGui::SameLine();
  if (ImGui::Button("Hide all classes"))
  {
    hiddenClasses.clear();
    std::set<std::string> names;
    for (const auto& item : entityDefinitions)
      names.insert(item.first);
    for (const auto& item : entityUsage)
      names.insert(item.first);
    for (const auto& name : names)
      if (name != "worldspawn")
        hiddenClasses += "|" + name + "|";
    cvars->SetString("ftebroom_hidden_classes", hiddenClasses.c_str());
  }
  ImGui::BeginChild(
    "Class visibility",
    {0, 140 * uiScale()},
    ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeY);
  std::map<std::string, std::vector<std::string>> categories;
  std::set<std::string> names;
  for (const auto& item : entityDefinitions)
    names.insert(item.first);
  for (const auto& item : entityUsage)
    names.insert(item.first);
  for (const auto& name : names)
    if (
      name != "worldspawn"
      && entityLower(name).find(entityLower(query)) != std::string::npos)
      categories[name.substr(0, name.find('_'))].push_back(name);
  for (const auto& category : categories)
    if (ImGui::TreeNodeEx(category.first.c_str(), ImGuiTreeNodeFlags_DefaultOpen))
    {
      for (const auto& name : category.second)
      {
        std::string token = "|" + name + "|";
        auto at = hiddenClasses.find(token);
        bool show = at == std::string::npos;
        if (ImGui::Checkbox(name.c_str(), &show))
        {
          if (show)
            hiddenClasses.erase(at, token.size());
          else
            hiddenClasses += token;
          cvars->SetString("ftebroom_hidden_classes", hiddenClasses.c_str());
        }
      }
      ImGui::TreePop();
    }
  ImGui::EndChild();
  ImGui::SeparatorText("Renderer");
  int mode = (int)cvars->GetFloat("ftebroom_render_faces");
  if (ImGui::Combo("Faces", &mode, "Textured\0Flat color\0Wireframe\0"))
    cvars->SetFloat("ftebroom_render_faces", float(mode));
  viewOption("Shade faces", "ftebroom_shade_faces");
  viewOption("Use fog", "r_fog_enabled");
  viewOption("Edges", "ftebroom_show_edges");
  viewOption("Soft map bounds", "ftebroom_bounds_visible");
  int links = (int)cvars->GetFloat("ftebroom_entity_links");
  if (ImGui::Combo("Entity links", &links, "None\0Direct\0Transitive\0All\0"))
    cvars->SetFloat("ftebroom_entity_links", float(links));
  ImGui::SeparatorText("Selection tags");
  for (const char* type : {"trigger", "clip", "caulk", "hint", "detail"})
  {
    ImGui::PushID(type);
    ImGui::TextUnformatted(type);
    ImGui::SameLine();
    if (ImGui::SmallButton("Set"))
      command(("ftebroom_tag " + std::string(type) + " 1\n").c_str());
    ImGui::SameLine();
    if (ImGui::SmallButton("Remove"))
      command(("ftebroom_tag " + std::string(type) + " 0\n").c_str());
    ImGui::PopID();
  }
}
