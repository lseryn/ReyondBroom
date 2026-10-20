// SPDX-License-Identifier: GPL-2.0-or-later
static std::map<std::string, qhandle_t> thumbnailCache;
static std::map<std::string, bool> materialFolders;
static void clearThumbnails()
{
  for (auto& pair : thumbnailCache)
    draw->UnloadImage(pair.second);
  thumbnailCache.clear();
}
static void resetMaterialBrowser()
{
  clearThumbnails();
  materialFolders.clear();
  selectedMaterial.clear();
}
static std::string materialFolder(const std::string& name)
{
  auto slash = name.find_last_of('/');
  return slash == std::string::npos ? "(root)" : name.substr(0, slash);
}
static qhandle_t thumbnail(const std::string& name)
{
  auto cached = thumbnailCache.find(name);
  if (cached != thumbnailCache.end())
    return cached->second;
  auto found = materials.find(name);
  auto image = found != materials.end() && !found->second.preview.empty()
                 ? found->second.preview
                 : name;
  auto handle = draw->LoadImage(image.c_str());
  thumbnailCache[name] = handle;
  return handle;
}
static void chooseMaterial(const std::string& name)
{
  selectedMaterial = name;
  auto brushName = name.rfind("textures/", 0) == 0 ? name.substr(9) : name;
  cvars->SetString("ca_newbrushtexture", brushName.c_str());
  action("ftebroom_material\n");
}
static void uvField(const char* label, const char* op, const char* source, float& value)
{
  ImGui::SetNextItemWidth(160);
  ImGui::InputFloat(label, &value, 0, 0, "%.3f");
  if (ImGui::IsItemDeactivatedAfterEdit())
  {
    char text[96];
    std::snprintf(text, sizeof text, "ftebroom_uv %s %.9g\n", op, value);
    action(text);
  }
  else if (!ImGui::IsItemActive())
    value = cvars->GetFloat(source);
}
static void materialBrowser()
{
  if (thumbnailCache.size() > 512)
    clearThumbnails();
  char current[1024] = {};
  cvars->GetString("ftebroom_current_material", current, sizeof current);
  ImGui::SeparatorText("Selected surfaces");
  if (*current && current[0] != '<')
  {
    auto name = std::string(current);
    if (name.rfind("textures/", 0) != 0 && materials.count("textures/" + name))
      name = "textures/" + name;
    ImGui::Image((ImTextureID)thumbnail(name), {52, 52});
    ImGui::SameLine();
    ImGui::BeginGroup();
    ImGui::TextWrapped("%s", current);
    ImGui::Text("%i faces", (int)cvars->GetFloat("ftebroom_face_count"));
    ImGui::EndGroup();
  }
  else
    ImGui::TextWrapped("%s", *current ? current : "No brush or face selected");
  static float sx = 1, sy = 1, angle = 0;
  ImGui::BeginDisabled(cvars->GetFloat("ftebroom_face_count") == 0);
  uvField("Scale X", "sx", "ftebroom_scale_x", sx);
  uvField("Scale Y", "sy", "ftebroom_scale_y", sy);
  uvField("Angle", "angle", "ftebroom_angle", angle);
  ImGui::EndDisabled();
  if (cvars->GetFloat("ftebroom_uv_mixed"))
    ImGui::TextWrapped("Mixed UV values; editing changes selected faces.");
  ImGui::TextWrapped("Shift+click: select a face. Enter: commit UV.");
  ImGui::SeparatorText("Material collections");
  for (auto& pair : materials)
    materialFolders.emplace(materialFolder(pair.first), true);
  if (ImGui::BeginCombo("##collections", "Choose visible folders..."))
  {
    if (ImGui::Button("All"))
      for (auto& pair : materialFolders)
        pair.second = true;
    ImGui::SameLine();
    if (ImGui::Button("None"))
      for (auto& pair : materialFolders)
        pair.second = false;
    for (auto& pair : materialFolders)
      ImGui::Checkbox(pair.first.c_str(), &pair.second);
    ImGui::EndCombo();
  }
  static ImGuiTextFilter filter;
  ImGui::TextUnformatted("Filter materials");
  filter.Draw("##material_filter", -1);
  static int size = 72;
  ImGui::SetNextItemWidth(160);
  ImGui::SliderInt("Thumbnail size", &size, 48, 128);
  std::vector<const MaterialEntry*> visible;
  for (auto& pair : materials)
    if (
      materialFolders[materialFolder(pair.first)]
      && filter.PassFilter(pair.first.c_str()))
      visible.push_back(&pair.second);
  ImGui::Text("%zu / %zu materials", visible.size(), materials.size());
  ImGui::BeginChild("material_tiles", {0, 0}, ImGuiChildFlags_Borders);
  int columns = std::max(1, int(ImGui::GetContentRegionAvail().x) / (size + 12));
  float rowHeight = float(size + 44);
  ImGuiListClipper clipper;
  clipper.Begin((int(visible.size()) + columns - 1) / columns, rowHeight);
  while (clipper.Step())
    for (int row = clipper.DisplayStart; row < clipper.DisplayEnd; ++row)
    {
      float top = ImGui::GetCursorPosY();
      for (int col = 0; col < columns; ++col)
      {
        size_t index = size_t(row * columns + col);
        if (index >= visible.size())
          break;
        auto& mat = *visible[index];
        ImGui::SetCursorPos({float(8 + col * (size + 12)), top});
        ImGui::PushID(mat.name.c_str());
        auto p = ImGui::GetCursorScreenPos();
        bool selected =
          selectedMaterial == mat.name || mat.name == std::string("textures/") + current;
        if (ImGui::InvisibleButton("tile", {float(size + 6), rowHeight - 4}))
          chooseMaterial(mat.name);
        auto d = ImGui::GetWindowDrawList();
        d->AddRectFilled(p, {p.x + size + 6, p.y + size + 6}, IM_COL32(65, 68, 72, 255));
        auto tex = thumbnail(mat.name);
        float w = 1, h = 1;
        draw->ImageSize(tex, &w, &h);
        float factor = float(size) / std::max(1.f, std::max(w, h));
        ImVec2 lo{p.x + 3 + (size - w * factor) / 2, p.y + 3 + (size - h * factor) / 2};
        d->AddImage((ImTextureID)tex, lo, {lo.x + w * factor, lo.y + h * factor});
        if (selected)
          d->AddRect(
            p, {p.x + size + 6, p.y + size + 6}, IM_COL32(245, 150, 40, 255), 0, 0, 2);
        auto slash = mat.name.find_last_of('/');
        auto label = mat.name.substr(slash == std::string::npos ? 0 : slash + 1);
        d->PushClipRect(
          {p.x, p.y + size + 8}, {p.x + size + 6, p.y + rowHeight - 2}, true);
        d->AddText({p.x, p.y + size + 8}, IM_COL32(40, 40, 40, 255), label.c_str());
        d->PopClipRect();
        if (ImGui::IsItemHovered())
          ImGui::SetTooltip(
            "%s\n%s", mat.name.c_str(), mat.shader ? "Shader" : "Texture");
        ImGui::PopID();
      }
      ImGui::SetCursorPosY(top + rowHeight - ImGui::GetStyle().ItemSpacing.y);
      ImGui::Dummy({0, 0});
    }
  ImGui::EndChild();
}
