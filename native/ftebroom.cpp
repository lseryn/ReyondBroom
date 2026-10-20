// SPDX-License-Identifier: GPL-2.0-or-later
// FTEBroom: Dear ImGui frontend for FTE's native csaddon brush editor.
#include <cstdint>
#define VARGS __cdecl
typedef int uploadfmt_t;
typedef int clipboardtype_t;
typedef struct qdownload_s qdownload_t;
typedef struct downloadlist_s downloadlist_t;
enum dlfailreason_e : int;
enum com_tokentype_e : int;
enum fs_relative : int;
#include "imgui.h"
#include "plugin.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static plugcorefuncs_t* core;
static plugcmdfuncs_t* commands;
static plugcvarfuncs_t* cvars;
static plug2dfuncs_t* draw;
static pluginputfuncs_t* input;
static qhandle_t atlas;
static quintptr_t lastTime;
static int mouseKeys[5], wheelUp, wheelDown;
static bool ready;
static void command(const char* text)
{
  commands->AddText(text, qfalse);
}

struct Vertex
{
  float x, y, u, v, r, g, b, a;
};
static Vertex lerp(const Vertex& a, const Vertex& b, float t)
{
  return {
    a.x + (b.x - a.x) * t,
    a.y + (b.y - a.y) * t,
    a.u + (b.u - a.u) * t,
    a.v + (b.v - a.v) * t,
    a.r + (b.r - a.r) * t,
    a.g + (b.g - a.g) * t,
    a.b + (b.b - a.b) * t,
    a.a + (b.a - a.a) * t};
}
// Clip triangles before submitting them as degenerate quads to FTE's batched 2D
// API.
static void triangle(std::vector<Vertex> polygon, const ImVec4& clip, qhandle_t image)
{
  for (int edge = 0; edge < 4 && !polygon.empty(); ++edge)
  {
    auto distance = [&](const Vertex& p) {
      return edge == 0   ? p.x - clip.x
             : edge == 1 ? clip.z - p.x
             : edge == 2 ? p.y - clip.y
                         : clip.w - p.y;
    };
    std::vector<Vertex> result;
    Vertex previous = polygon.back();
    float pd = distance(previous);
    for (auto current : polygon)
    {
      float cd = distance(current);
      if ((cd >= 0) != (pd >= 0))
        result.push_back(lerp(previous, current, pd / (pd - cd)));
      if (cd >= 0)
        result.push_back(current);
      previous = current;
      pd = cd;
    }
    polygon = std::move(result);
  }
  for (size_t i = 1; i + 1 < polygon.size(); ++i)
  {
    Vertex p[4] = {polygon[0], polygon[i], polygon[i + 1], polygon[i + 1]};
    vec2_t xy[4], uv[4];
    vec4_t color[4];
    for (int j = 0; j < 4; ++j)
    {
      xy[j][0] = p[j].x;
      xy[j][1] = p[j].y;
      uv[j][0] = p[j].u;
      uv[j][1] = p[j].v;
      color[j][0] = p[j].r;
      color[j][1] = p[j].g;
      color[j][2] = p[j].b;
      color[j][3] = p[j].a;
    }
    draw->Image2dQuad(xy, uv, color, image);
  }
}
static void render()
{
  ImGui::Render();
  auto data = ImGui::GetDrawData();
  draw->Colour4f(1, 1, 1, 1);
  for (int n = 0; n < data->CmdListsCount; ++n)
  {
    auto list = data->CmdLists[n];
    for (auto& cmd : list->CmdBuffer)
    {
      if (cmd.UserCallback)
      {
        if (cmd.UserCallback != ImDrawCallback_ResetRenderState)
          cmd.UserCallback(list, &cmd);
        continue;
      }
      for (unsigned int i = 0; i + 2 < cmd.ElemCount; i += 3)
      {
        std::vector<Vertex> p;
        for (int j = 0; j < 3; ++j)
        {
          auto& v =
            list->VtxBuffer[list->IdxBuffer[cmd.IdxOffset + i + j] + cmd.VtxOffset];
          auto c = ImGui::ColorConvertU32ToFloat4(v.col);
          p.push_back({v.pos.x, v.pos.y, v.uv.x, v.uv.y, c.x, c.y, c.z, c.w});
        }
        triangle(std::move(p), cmd.ClipRect, (qhandle_t)cmd.GetTexID());
      }
    }
  }
}
static void initialize()
{
  if (ready)
    return;
  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGui::StyleColorsLight();
  auto& style = ImGui::GetStyle();
  style.WindowRounding = 0;
  style.FrameRounding = 2;
  style.WindowBorderSize = 1;
  style.WindowPadding = {8, 8};
  auto& io = ImGui::GetIO();
  io.IniFilename = nullptr;
  io.LogFilename = nullptr;
  io.BackendRendererName = "FTE native 2D";
  io.BackendPlatformName = "FTE MenuEvent";
  io.Fonts->AddFontDefault();
  unsigned char* pixels;
  int w, h;
  io.Fonts->GetTexDataAsRGBA32(&pixels, &w, &h);
  std::vector<unsigned char> tga(18 + w * h * 4, 0);
  tga[2] = 2;
  tga[12] = w & 255;
  tga[13] = w >> 8;
  tga[14] = h & 255;
  tga[15] = h >> 8;
  tga[16] = 32;
  tga[17] = 0x28;
  for (int i = 0; i < w * h; ++i)
  {
    tga[18 + i * 4] = pixels[i * 4 + 2];
    tga[19 + i * 4] = pixels[i * 4 + 1];
    tga[20 + i * 4] = pixels[i * 4];
    tga[21 + i * 4] = pixels[i * 4 + 3];
  }
  atlas = draw->LoadImageData("ftebroom/font.tga", "image/tga", tga.data(), tga.size());
  atlas = draw->LoadImage("ftebroom/font.tga");
  io.Fonts->SetTexID((ImTextureID)atlas);
  ready = true;
  char status[96];
  std::snprintf(
    status,
    sizeof status,
    "FTEBroom: Dear ImGui renderer initialized (atlas %i).\n",
    (int)atlas);
  core->Print(status);
}
static bool safeName(const char* name)
{
  if (!*name)
    return false;
  for (auto p = name; *p; ++p)
    if (!((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || (*p >= '0' && *p <= '9')
          || *p == '_' || *p == '-'))
      return false;
  return true;
}

static bool inspector = true, sceneDrag = false, sceneLook = false, altHeld = false;
static bool selectMapTab = false;
static bool ctrlHeld = false, shiftHeld = false;
static bool popupOpen = false, saveRequest = false, openRequest = false;
static float lastX = 0, lastY = 0;
static char mapName[64] = "my_map";
static bool moveHeld[4] = {};
static const char* modalNames[] = {
  "Default (Move)",
  "Brush",
  "Clip",
  "Rotate",
  "Sweep",
  "Scale",
  "Shear",
  "Vertex",
  "Edge",
  "Face",
  "Control Point"};
static void pointer(const char* phase, float x, float y)
{
  char b[160];
  std::snprintf(
    b, sizeof b, "ftebroom_pointer %s %g %g %i\n", phase, x, y, altHeld ? 1 : 0);
  command(b);
}
static void cancelGesture()
{
  pointer("cancel", lastX, lastY);
  sceneDrag = false;
}
static void action(const char* cmd)
{
  cancelGesture();
  command(cmd);
}
#include "ftebroom_assets.h"
#include "ftebroom_document.h"
// Actions refer to the resource dialog state declared above.
#include "ftebroom_actions.h"
static void gridControl(const char* label)
{
  const char* values[] = {
    "0.125", "0.25", "0.5", "1", "2", "4", "8", "16", "32", "64", "128", "256"};
  float value = cvars->GetFloat("ca_grid");
  int selected = 0;
  while (selected < 11 && std::ldexp(1.f, selected - 3) < value)
    ++selected;
  ImGui::SetNextItemWidth(76);
  if (ImGui::Combo(label, &selected, values, 12))
    cvars->SetFloat("ca_grid", std::ldexp(1.f, selected - 3));
}
static void panel(float w, float h)
{
  auto& io = ImGui::GetIO();
  io.DisplaySize = {w, h};
  auto now = core->GetMilliseconds();
  io.DeltaTime = lastTime ? std::max(.001f, (now - lastTime) / 1000.f) : 1.f / 60;
  lastTime = now;
  ImGui::NewFrame();
  projectSetup();
  if ((int)cvars->GetFloat("ftebroom_tool") == 2)
  {
    auto overlay = ImGui::GetForegroundDrawList();
    overlay->PushClipRect({48, 114}, {w - 310, h - 26});
    for (int i = 0; i < (int)cvars->GetFloat("ftebroom_clip_points"); ++i)
    {
      char name[64], position[128];
      float x = 0, y = 0;
      std::snprintf(name, sizeof name, "ftebroom_clip_point_%i", i);
      cvars->GetString(name, position, sizeof position);
      if (std::sscanf(position, "%f %f", &x, &y) == 2)
        overlay->AddCircleFilled({x, y}, 5, IM_COL32(255, 140, 30, 255));
    }
    overlay->PopClipRect();
  }
  if (io.WantTextInput || popupOpen || sceneDrag)
    std::fill(std::begin(moveHeld), std::end(moveHeld), false);
  cvars->SetFloat("ftebroom_forward", float(moveHeld[0]) - float(moveHeld[1]));
  cvars->SetFloat("ftebroom_right", float(moveHeld[3]) - float(moveHeld[2]));
  if (ImGui::BeginMainMenuBar())
  {
    actionMenus();
    ImGui::TextDisabled("   FTEBroom 0.5 alpha 6");
    ImGui::EndMainMenuBar();
  }
  const auto fixed = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove
                     | ImGuiWindowFlags_NoSavedSettings;
  ImGui::SetNextWindowPos({0, 24});
  ImGui::SetNextWindowSize({w, 46});
  ImGui::Begin("##toolbar", nullptr, fixed);
  actionButton("Menu/Edit/Undo");
  ImGui::SameLine();
  actionButton("Menu/Edit/Redo");
  ImGui::SameLine();
  actionButton("Menu/Edit/Delete");
  ImGui::SameLine();
  ImGui::TextUnformatted(" | ");
  ImGui::SameLine();
  gridControl("Grid");
  ImGui::SameLine();
  int view = (int)cvars->GetFloat("ca_brush_view");
  ImGui::SetNextItemWidth(135);
  if (ImGui::Combo("View", &view, "Perspective\0X (side)\0Y (front)\0Z (top)\0"))
  {
    cancelGesture();
    cvars->SetFloat("ca_brush_view", view);
  }
  ImGui::SameLine();
  ImGui::TextDisabled("  XY plane / Alt: Z");
  ImGui::End();
  ImGui::SetNextWindowPos({48, 70});
  ImGui::SetNextWindowSize({std::max(1.f, w - 358), 44});
  ImGui::Begin("##tool-info", nullptr, fixed);
  int currentTool = (int)cvars->GetFloat("ftebroom_tool");
  if (currentTool == 2)
  {
    ImGui::TextUnformatted("Clip");
    ImGui::SameLine();
    int keep = (int)cvars->GetFloat("ftebroom_clip_keep");
    ImGui::SetNextItemWidth(150);
    if (ImGui::Combo("Keep", &keep, "Both sides\0Front\0Back\0"))
      cvars->SetFloat("ftebroom_clip_keep", keep);
    ImGui::SameLine();
    if (ImGui::Button("Apply (Enter)"))
      command("ftebroom_tool_key apply\n");
    ImGui::SameLine();
    ImGui::Text("Points: %g / 3", cvars->GetFloat("ftebroom_clip_points"));
  }
  else if (currentTool == 0)
  {
    static float offset[3] = {0, 0, 0};
    ImGui::TextUnformatted("Move objects by:");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(220);
    ImGui::InputFloat3("##move-offset", offset, "%.2f");
    ImGui::SameLine();
    ImGui::BeginDisabled(cvars->GetFloat("ftebroom_ctx_selection") != 1);
    if (ImGui::Button("Apply"))
    {
      char cmd[160];
      std::snprintf(
        cmd, sizeof cmd, "ftebroom_move %g %g %g\n", offset[0], offset[1], offset[2]);
      action(cmd);
    }
    ImGui::EndDisabled();
  }
  else
  {
    ImGui::Text("%s | framework only", modalNames[std::clamp(currentTool, 0, 10)]);
    ImGui::SameLine();
    if (currentTool == 1)
      ImGui::Text(
        "Points: %g | Esc clears points", cvars->GetFloat("ftebroom_shape_points"));
    else
      ImGui::TextUnformatted("Geometry editing is scheduled in a later task");
  }
  ImGui::End();
  ImGui::SetNextWindowPos({0, 70});
  ImGui::SetNextWindowSize({48, std::max(1.f, h - 96)});
  ImGui::Begin("##tools", nullptr, fixed);
  const int toolIds[] = {0, 1, 2, 7, 8, 9, 10, 3, 4, 5, 6};
  const char* toolNames[] = {
    "Default (Move)",
    "Brush",
    "Clip",
    "Vertex",
    "Edge",
    "Face",
    "Control Point",
    "Rotate",
    "Sweep",
    "Scale",
    "Shear"};
  const char* toolGlyphs[] = {">", "B", "C", "V", "E", "F", "P", "R", "Y", "T", "G"};
  for (int i = 0; i < 11; i++)
  {
    int tool = toolIds[i];
    bool active = (int)cvars->GetFloat("ftebroom_tool") == tool;
    const Action* entry = nullptr;
    for (auto& a : actions)
      if (std::string(a.id) == std::string("Menu/Tools/") + toolNames[i])
        entry = &a;
    if (active)
      ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(.96f, .64f, .28f, 1));
    if (ImGui::Button(toolGlyphs[i], {30, 32}))
    {
      sceneDrag = sceneLook = false;
      if (entry)
        executeAction(*entry);
      else
        command("ftebroom_tool_deactivate\n");
    }
    if (active)
      ImGui::PopStyleColor();
    if (ImGui::IsItemHovered())
      ImGui::SetTooltip(
        "%s %s%s",
        toolNames[i],
        entry ? entry->shortcutText.c_str() : "",
        tool > 2 ? " (framework; geometry pending)" : "");
  }
  ImGui::Separator();
  for (auto name : {"ftebroom_texture_lock", "ftebroom_uv_lock"})
  {
    bool uv = std::string(name) == "ftebroom_uv_lock";
    bool on = cvars->GetFloat(name) != 0;
    if (on)
      ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(.96f, .64f, .28f, 1));
    if (ImGui::Button(uv ? "UV" : "TL", {30, 26}))
      cvars->SetFloat(name, !on);
    if (on)
      ImGui::PopStyleColor();
    if (ImGui::IsItemHovered())
      ImGui::SetTooltip(
        "%s",
        uv ? "UV Lock (stored preference; advanced transforms pending)"
           : "Texture Lock: keep texture attached while moving");
  }
  ImGui::End();
  if (inspector)
  {
    ImGui::SetNextWindowPos({std::max(48.f, w - 310), 70});
    ImGui::SetNextWindowSize({310, std::max(1.f, h - 96)});
    ImGui::Begin("Inspector", nullptr, fixed);
    if (ImGui::BeginTabBar("InspectorTabs"))
    {
      if (
        ImGui::BeginTabItem(
          (documentName + ".map" + (cvars->GetFloat("ftebroom_dirty") ? "*" : "")
           + "###Map")
            .c_str(),
          nullptr,
          selectMapTab ? ImGuiTabItemFlags_SetSelected : ImGuiTabItemFlags_None))
      {
        ImGui::Text(
          "Selection: %i brush(es)", (int)cvars->GetFloat("ftebroom_selection_count"));
        char selectedEntity[160] = {};
        cvars->GetString(
          "ftebroom_selected_entity", selectedEntity, sizeof selectedEntity);
        if (*selectedEntity)
          ImGui::Text("Entity: %s", selectedEntity);
        if ((int)cvars->GetFloat("ftebroom_tool") == 2)
        {
          ImGui::SeparatorText("Clip / Cut");
          int keep = (int)cvars->GetFloat("ftebroom_clip_keep");
          if (ImGui::Combo("Keep", &keep, "Both sides\0Front\0Back\0"))
            cvars->SetFloat("ftebroom_clip_keep", float(keep));
          ImGui::Text("Cut points: %i / 3", (int)cvars->GetFloat("ftebroom_clip_points"));
          if (ImGui::Button("Apply cut (Enter)"))
            command("ftebroom_clip apply\n");
          ImGui::SameLine();
          if (ImGui::Button("Reset"))
            command("ftebroom_clip reset\n");
          ImGui::TextWrapped(
            "Orange transparent volume is discarded. Ctrl+Enter changes sides. "
            "Select brushes first. Click two points for a vertical cut, or three for an "
            "arbitrary plane. Escape removes the last point.");
        }
        ImGui::SeparatorText("Brush creation");
        ImGui::Text("Drag height: %g (one grid cell)", cvars->GetFloat("ca_grid"));
        float plane = cvars->GetFloat("ftebroom_plane");
        ImGui::SetNextItemWidth(120);
        if (ImGui::InputFloat("Plane Z", &plane, 16, 64))
          cvars->SetFloat("ftebroom_plane", std::clamp(plane, -16384.f, 16384.f));
        static float origin[3] = {0, 0, 64}, size[3] = {128, 128, 128};
        ImGui::TextUnformatted("Numeric box");
        ImGui::InputFloat3("Centre", origin);
        ImGui::InputFloat3("Size", size);
        if (ImGui::Button("Create box"))
        {
          cancelGesture();
          char b[160];
          std::snprintf(
            b,
            sizeof b,
            "ftebroom_box %g %g %g %g %g %g\n",
            origin[0],
            origin[1],
            origin[2],
            size[0],
            size[1],
            size[2]);
          command(b);
        }
        ImGui::SeparatorText("Grid");
        gridControl("Spacing");
        bool visible = cvars->GetFloat("ftebroom_grid_visible") != 0;
        if (ImGui::Checkbox("Show grid", &visible))
          cvars->SetFloat("ftebroom_grid_visible", visible);
        bool snap = cvars->GetFloat("ftebroom_grid_snap") != 0;
        if (ImGui::Checkbox("Snap to grid", &snap))
          cvars->SetFloat("ftebroom_grid_snap", snap);
        float alpha = cvars->GetFloat("ftebroom_grid_alpha");
        if (ImGui::SliderFloat("Grid opacity", &alpha, 0.f, 1.f))
          cvars->SetFloat("ftebroom_grid_alpha", alpha);
        ImGui::SeparatorText("Document");
        ImGui::Text(
          "%s.map%s", documentName.c_str(), cvars->GetFloat("ftebroom_dirty") ? "*" : "");
        ImGui::InputText("Name", mapName, sizeof mapName);
        ImGui::BeginDisabled(!safeName(mapName));
        if (ImGui::Button("Save .map"))
          saveRequest = true;
        ImGui::SameLine();
        if (ImGui::Button("Open .map"))
          openRequest = true;
        ImGui::EndDisabled();
        ImGui::TextWrapped(
          "Drag in the scene while this inspector stays open. "
          "Esc cancels the current gesture.");
        ImGui::EndTabItem();
      }
      if (
        ImGui::BeginTabItem(
          "Material",
          nullptr,
          selectMaterialTab
              || (cvars->GetFloat("ftebroom_test_material_tab") && cvars->GetFloat("ftebroom_skip_setup"))
            ? ImGuiTabItemFlags_SetSelected
            : ImGuiTabItemFlags_None))
      {
        materialBrowser();
        ImGui::EndTabItem();
      }
      ImGui::EndTabBar();
      selectMapTab = false;
      selectMaterialTab = false;
    }
    if (saveRequest)
    {
      ImGui::OpenPopup("Save map?");
      saveRequest = false;
    }
    if (openRequest)
    {
      ImGui::OpenPopup("Open map?");
      openRequest = false;
    }
    if (ImGui::BeginPopupModal("Save map?", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
    {
      ImGui::InputText("Map name", mapName, sizeof mapName);
      ImGui::Text("Write maps/%s.map? Existing files are replaced.", mapName);
      ImGui::BeginDisabled(!safeName(mapName));
      if (ImGui::Button("Save"))
      {
        documentSave(mapName);
        ImGui::CloseCurrentPopup();
      }
      ImGui::EndDisabled();
      ImGui::SameLine();
      if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape))
      {
        documentNext.clear();
        ImGui::CloseCurrentPopup();
      }
      ImGui::EndPopup();
    }
    if (ImGui::BeginPopupModal("Open map?", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
    {
      ImGui::Text("Open maps/%s.map?", mapName);
      ImGui::BeginDisabled(!safeName(mapName));
      if (ImGui::Button("Open"))
      {
        documentRequest(mapName);
        ImGui::CloseCurrentPopup();
      }
      ImGui::EndDisabled();
      ImGui::SameLine();
      if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape))
        ImGui::CloseCurrentPopup();
      ImGui::EndPopup();
    }
    ImGui::End();
  }
  ImGui::SetNextWindowPos({0, h - 26});
  ImGui::SetNextWindowSize({w, 26});
  ImGui::Begin("##status", nullptr, fixed);
  ImGui::Text(
    "%s | Grid %g | Selected: %g | %s",
    modalNames[std::clamp((int)cvars->GetFloat("ftebroom_tool"), 0, 10)],
    cvars->GetFloat("ca_grid"),
    cvars->GetFloat("ftebroom_selection_count"),
    sceneDrag ? (altHeld ? "Z constraint | Esc cancels" : "XY constraint | Esc cancels")
              : (currentTool == 2
                   ? "Place 2 or 3 points | Enter applies | Ctrl+Enter changes side | "
                     "Esc removes last point"
                   : "Click selects | Drag creates / moves | Shift+Esc exits tool"));
  ImGui::End();
  documentDialogs();
  actionReferenceWindow();
  if (preferencesRequest)
  {
    ImGui::OpenPopup("Preferences");
    preferencesRequest = false;
  }
  if (ImGui::BeginPopupModal("Preferences", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
  {
    bool legacy = cvars->GetFloat("ftebroom_drag_mode") != 0;
    if (ImGui::Checkbox("Drag unselected brushes to move (legacy)", &legacy))
      cvars->SetFloat("ftebroom_drag_mode", legacy);
    bool wheelGrid = cvars->GetFloat("ftebroom_wheel_grid") != 0;
    if (ImGui::Checkbox("Plain wheel changes grid (legacy)", &wheelGrid))
      cvars->SetFloat("ftebroom_wheel_grid", wheelGrid);
    bool wheelInvert = cvars->GetFloat("ftebroom_wheel_invert") != 0;
    if (ImGui::Checkbox("Invert grid wheel", &wheelInvert))
      cvars->SetFloat("ftebroom_wheel_invert", wheelInvert);
    if (ImGui::Button("Close") || ImGui::IsKeyPressed(ImGuiKey_Escape))
      ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
  }
  popupOpen = ImGui::IsPopupOpen(
    nullptr, ImGuiPopupFlags_AnyPopupId | ImGuiPopupFlags_AnyPopupLevel);
  render();
}
static qboolean QDECL
event(int type, int key, int unicode, float x, float y, float w, float h)
{
  initialize();
  auto& io = ImGui::GetIO();
  io.AddMousePosEvent(x, y);
  cvars->SetFloat("ftebroom_mouse_x", x);
  cvars->SetFloat("ftebroom_mouse_y", y);
  bool inScene =
    x >= 48 && x < (inspector ? w - 310 : w) && y >= 114 && y < h - 26 && !popupOpen;
  if (type == 0)
  {
    if (sceneLook && (x != lastX || y != lastY))
    {
      char b[96];
      std::snprintf(b, sizeof b, "ftebroom_look %g %g\n", x - lastX, y - lastY);
      command(b);
    }
    lastX = x;
    lastY = y;
    panel(w, h);
  }
  if (type == 1 || type == 2)
  {
    bool down = type == 1;
    if (key == input->GetKeyCode("shift", nullptr))
    {
      shiftHeld = down;
      cvars->SetFloat("ftebroom_shift", down);
    }
    if (key == input->GetKeyCode("ctrl", nullptr))
    {
      ctrlHeld = down;
      cvars->SetFloat("ftebroom_ctrl", down);
    }
    for (int i = 0; i < 5; i++)
      if (key == mouseKeys[i])
        io.AddMouseButtonEvent(i, down);
    if (key == input->GetKeyCode("alt", nullptr))
    {
      altHeld = down;
      io.AddKeyEvent(ImGuiMod_Alt, down);
      cvars->SetFloat("ftebroom_alt", down);
    }
    if (key == mouseKeys[0])
    {
      if (down && inScene && !sceneLook)
      {
        sceneDrag = true;
        pointer("down", x, y);
      }
      if (!down && sceneDrag)
      {
        pointer("up", x, y);
        sceneDrag = false;
      }
    }
    if (key == mouseKeys[1])
    {
      if (down && inScene)
      {
        cancelGesture();
        sceneLook = true;
        lastX = x;
        lastY = y;
      }
      if (!down)
      {
        sceneLook = false;
      }
    }
    if (down && (key == wheelUp || key == wheelDown))
    {
      if (inScene && !sceneDrag && !sceneLook)
      {
        char gridCommand[96];
        std::snprintf(
          gridCommand,
          sizeof gridCommand,
          "ftebroom_grid wheel %d %d\n",
          key == wheelUp ? 1 : -1,
          ctrlHeld && altHeld);
        if (!io.WantTextInput)
          command(gridCommand);
      }
      else
        io.AddMouseWheelEvent(0, key == wheelUp ? 1.f : -1.f);
    }
    struct Key
    {
      const char* name;
      ImGuiKey code;
    };
    static const Key keys[] = {
      {"escape", ImGuiKey_Escape},
      {"backspace", ImGuiKey_Backspace},
      {"enter", ImGuiKey_Enter},
      {"tab", ImGuiKey_Tab},
      {"del", ImGuiKey_Delete},
      {"leftarrow", ImGuiKey_LeftArrow},
      {"rightarrow", ImGuiKey_RightArrow},
      {"home", ImGuiKey_Home},
      {"end", ImGuiKey_End},
      {"ctrl", ImGuiMod_Ctrl},
      {"shift", ImGuiMod_Shift},
      {"a", ImGuiKey_A},
      {"c", ImGuiKey_C},
      {"v", ImGuiKey_V},
      {"x", ImGuiKey_X},
      {"z", ImGuiKey_Z},
      {"y", ImGuiKey_Y}};
    for (auto k : keys)
      if (key == input->GetKeyCode(k.name, nullptr))
        io.AddKeyEvent(k.code, down);
    if (down && unicode >= 32 && !sceneLook)
      io.AddInputCharacter((unsigned int)unicode);
    dispatchAction(key, down, inScene);
  }
  return qtrue;
}
static void openPanel()
{
  inspector = true;
  input->SetMenuFocus(qtrue, "", 0, 0, 1);
}
static void mapReady()
{
  char loadedName[256];
  if (cvars->GetString("mapname", loadedName, sizeof loadedName))
  {
    auto name = std::filesystem::path(loadedName).stem().string();
    if (safeName(name.c_str()))
    {
      documentUntitled = name.rfind("_ftebroom_new_", 0) == 0;
      documentName = documentUntitled ? "untitled" : name;
    }
    std::snprintf(mapName, sizeof mapName, "%s", documentName.c_str());
  }
  lastBackup = std::chrono::steady_clock::now();
  sceneDrag = sceneLook = false;
  std::fill(std::begin(moveHeld), std::end(moveHeld), false);
  ctrlHeld = shiftHeld = altHeld = false;
  cvars->SetFloat("ftebroom_shift", 0);
  cvars->SetFloat("ftebroom_ctrl", 0);
  cvars->SetFloat("ftebroom_alt", 0);
  cvars->SetFloat("ftebroom_forward", 0);
  cvars->SetFloat("ftebroom_right", 0);
  openPanel();
  core->Print("FTEBroom: permanent workspace restored for map.\n");
}
static void QDECL actionFocusTick(int)
{
  documentTick();
  if (!ready || input->HasMenuFocus())
    return;
  ctrlHeld = shiftHeld = altHeld = false;
  std::fill(std::begin(moveHeld), std::end(moveHeld), false);
  cvars->SetFloat("ftebroom_ctrl", 0);
  cvars->SetFloat("ftebroom_shift", 0);
  cvars->SetFloat("ftebroom_alt", 0);
  cvars->SetFloat("ftebroom_forward", 0);
  cvars->SetFloat("ftebroom_right", 0);
  if (sceneDrag || sceneLook)
  {
    cancelGesture();
    sceneLook = false;
  }
  ImGui::GetIO().ClearInputKeys();
}
static void invokeActionCommand()
{
  char id[256];
  commands->Argv(1, id, sizeof id);
  initActions();
  for (auto& a : actions)
    if (std::string(a.id) == id)
    {
      if (actionMatches(a.context, currentActionContext()))
        executeAction(a);
      else
        core->Print("FTEBroom: action is unavailable in the current context\\n");
      return;
    }
  core->Print("FTEBroom: unknown action\\n");
}
static void uiActionCommand()
{
  char name[64];
  commands->Argv(1, name, sizeof name);
  initActions();
  std::string cmd = std::string("ftebroom_ui ") + name;
  for (auto& a : actions)
    if (a.command && cmd == a.command)
    {
      executeAction(a);
      return;
    }
}
static void testCameraInput()
{
  if (!cvars->GetFloat("ftebroom_skip_setup") || commands->IsInsecure())
    return;
  char state[16];
  commands->Argv(1, state, sizeof state);
  event(state[0] == '1' ? 1 : 2, input->GetKeyCode("w", nullptr), 0, 640, 400, 1280, 800);
}
static void testEditorInput()
{
  if (!cvars->GetFloat("ftebroom_skip_setup") || commands->IsInsecure())
    return;
  char chord[128], guard[32];
  commands->Argv(1, chord, sizeof chord);
  commands->Argv(2, guard, sizeof guard);
  std::string name = chord;
  bool savedText = ImGui::GetIO().WantTextInput, savedPopup = popupOpen;
  if (std::string(guard) == "text")
    ImGui::GetIO().WantTextInput = true;
  if (std::string(guard) == "popup")
    popupOpen = true;
  std::vector<int> mods;
  for (auto mod : {"Ctrl+", "Alt+", "Shift+"})
  {
    auto pos = name.find(mod);
    if (pos == std::string::npos)
      continue;
    const char* key = mod[0] == 'C' ? "ctrl" : mod[0] == 'A' ? "alt" : "shift";
    int code = input->GetKeyCode(key, nullptr);
    mods.push_back(code);
    event(1, code, 0, 640, 400, 1280, 800);
    name.erase(pos, std::strlen(mod));
  }
  int code = input->GetKeyCode(name.c_str(), nullptr);
  event(1, code, 0, 640, 400, 1280, 800);
  event(2, code, 0, 640, 400, 1280, 800);
  for (auto it = mods.rbegin(); it != mods.rend(); ++it)
    event(2, *it, 0, 640, 400, 1280, 800);
  ImGui::GetIO().WantTextInput = savedText;
  popupOpen = savedPopup;
}
static void shutdownEditor()
{
  if (ready)
  {
    clearThumbnails();
    ImGui::DestroyContext();
    draw->UnloadImage(atlas);
    ready = false;
  }
}
extern "C" qboolean NATIVEEXPORT FTEPlug_Init(plugcorefuncs_t* api)
{
  core = api;
  commands =
    (plugcmdfuncs_t*)core->GetEngineInterface(plugcmdfuncs_name, sizeof(*commands));
  cvars = (plugcvarfuncs_t*)core->GetEngineInterface(plugcvarfuncs_name, sizeof(*cvars));
  draw = (plug2dfuncs_t*)core->GetEngineInterface(plug2dfuncs_name, sizeof(*draw));
  input =
    (pluginputfuncs_t*)core->GetEngineInterface(pluginputfuncs_name, sizeof(*input));
  files = (plugfsfuncs_t*)core->GetEngineInterface(plugfsfuncs_name, sizeof(*files));
  if (!commands || !cvars || !draw || !input || !files)
  {
    core->Print("FTEBroom: incompatible FTE plugin API.\n");
    return qfalse;
  }
  for (int i = 0; i < 5; ++i)
  {
    char name[16];
    std::snprintf(name, sizeof name, "mouse%d", i + 1);
    mouseKeys[i] = input->GetKeyCode(name, nullptr);
  }
  wheelUp = input->GetKeyCode("mwheelup", nullptr);
  wheelDown = input->GetKeyCode("mwheeldown", nullptr);
  core->ExportFunction("MenuEvent", (funcptr_t)event);
  core->ExportFunction("Shutdown", (funcptr_t)shutdownEditor);
  core->ExportFunction("Tick", (funcptr_t)actionFocusTick);
  commands->AddCommand(
    "ftebroom_actions_dump", dumpActions, "Dump action ids, contexts and shortcuts.");
  commands->AddCommand(
    "ftebroom_action", invokeActionCommand, "Run a context-aware editor action by id.");
  commands->AddCommand("ftebroom_ui", uiActionCommand, "Run an editor UI action.");
  commands->AddCommand(
    "ftebroom_assets_ready", assetsReady, "Index mounted project assets.");
  commands->AddCommand(
    "ftebroom_project", loadProjectCommand, "Load Quake 3 assets from a baseq3 folder.");
  commands->AddCommand(
    "ftebroom_test_camera",
    testCameraInput,
    "Test editor input routing in automated runs.");
  commands->AddCommand(
    "ftebroom_test_key",
    testEditorInput,
    "Exercise editor key routing in automated tests.");
  commands->AddCommand(
    "ftebroom_map_ready", mapReady, "Restore editor focus after map loading.");
  commands->AddCommand(
    "ftebroom_save_finish", documentSaveFinished, "Complete a verified map save.");
  commands->AddCommand(
    "ftebroom_save", documentSaveCommand, "Save the current document.");
  commands->AddCommand("ftebroom", openPanel, "Open the FTEBroom editor panel.");
  core->Print("FTEBroom: native module loaded. Type ftebroom.\n");
  return qtrue;
}
