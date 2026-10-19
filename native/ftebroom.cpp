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
#include <cstdio>
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
static bool ctrlHeld = false;
static bool popupOpen = false, saveRequest = false, openRequest = false;
static float lastX = 0, lastY = 0;
static char mapName[64] = "my_map";
static bool moveHeld[4] = {};
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
static void gridControl(const char* label)
{
  const char* values[] = {"1", "2", "4", "8", "16", "32", "64", "128"};
  int value = (int)cvars->GetFloat("ca_grid"), selected = 0;
  while (selected < 7 && (1 << selected) < value)
    ++selected;
  ImGui::SetNextItemWidth(76);
  if (ImGui::Combo(label, &selected, values, 8))
    cvars->SetFloat("ca_grid", float(1 << selected));
}
static void panel(float w, float h)
{
  auto& io = ImGui::GetIO();
  io.DisplaySize = {w, h};
  auto now = core->GetMilliseconds();
  io.DeltaTime = lastTime ? std::max(.001f, (now - lastTime) / 1000.f) : 1.f / 60;
  lastTime = now;
  ImGui::NewFrame();
  if (ImGui::BeginMainMenuBar())
  {
    if (ImGui::BeginMenu("File"))
    {
      if (ImGui::MenuItem("Save map..."))
      {
        inspector = true;
        saveRequest = true;
      }
      if (ImGui::MenuItem("Open map..."))
      {
        inspector = true;
        openRequest = true;
      }
      ImGui::EndMenu();
    }
    if (ImGui::BeginMenu("Edit"))
    {
      if (ImGui::MenuItem("Undo", "Ctrl+Z"))
        action("brushedit_undo\n");
      if (ImGui::MenuItem("Redo", "Ctrl+Y"))
        action("brushedit_redo\n");
      if (ImGui::MenuItem("Delete", "Delete"))
        action("brushedit_delete\n");
      ImGui::EndMenu();
    }
    if (ImGui::BeginMenu("View"))
    {
      ImGui::MenuItem("Inspector", "F1", &inspector);
      bool grid = cvars->GetFloat("ftebroom_grid_visible") != 0;
      if (ImGui::MenuItem("Show grid", nullptr, &grid))
        cvars->SetFloat("ftebroom_grid_visible", grid);
      gridControl("Grid size");
      ImGui::EndMenu();
    }
    ImGui::TextDisabled("   FTEBroom 0.2");
    ImGui::EndMainMenuBar();
  }
  const auto fixed = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove
                     | ImGuiWindowFlags_NoSavedSettings;
  ImGui::SetNextWindowPos({0, 24});
  ImGui::SetNextWindowSize({w, 46});
  ImGui::Begin("##toolbar", nullptr, fixed);
  if (ImGui::Button("Undo"))
    action("brushedit_undo\n");
  ImGui::SameLine();
  if (ImGui::Button("Redo"))
    action("brushedit_redo\n");
  ImGui::SameLine();
  if (ImGui::Button("Delete"))
    action("brushedit_delete\n");
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
  ImGui::SetNextWindowPos({0, 70});
  ImGui::SetNextWindowSize({48, std::max(1.f, h - 96)});
  ImGui::Begin("##tools", nullptr, fixed);
  const char* labels[] = {"##select", "##move", "##brush"};
  const char* tips[] = {
    "Smart: click selects; drag creates; drag selection moves",
    "Move selected brush",
    "Create brush by dragging"};
  for (int i = 0; i < 3; i++)
  {
    bool active = (int)cvars->GetFloat("ftebroom_tool") == i;
    if (active)
      ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(.96f, .64f, .28f, 1));
    if (ImGui::Button(labels[i], {30, 32}))
    {
      cancelGesture();
      cvars->SetFloat("ftebroom_tool", float(i));
    }
    if (active)
      ImGui::PopStyleColor();
    auto d = ImGui::GetWindowDrawList();
    auto r = ImGui::GetItemRectMin();
    const ImU32 ink = IM_COL32(48, 52, 58, 255);
    auto pt = [&](float x, float y) { return ImVec2(r.x + x, r.y + y); };
    if (i == 0)
    {
      d->AddTriangleFilled(pt(8, 7), pt(8, 24), pt(21, 18), ink);
      d->AddLine(pt(14, 17), pt(21, 26), ink, 2);
    }
    else if (i == 1)
    {
      d->AddLine(pt(15, 6), pt(15, 26), ink, 2);
      d->AddLine(pt(5, 16), pt(25, 16), ink, 2);
      d->AddTriangleFilled(pt(15, 4), pt(11, 10), pt(19, 10), ink);
      d->AddTriangleFilled(pt(15, 28), pt(11, 22), pt(19, 22), ink);
      d->AddTriangleFilled(pt(3, 16), pt(9, 12), pt(9, 20), ink);
      d->AddTriangleFilled(pt(27, 16), pt(21, 12), pt(21, 20), ink);
    }
    else
    {
      d->AddQuad(pt(5, 11), pt(15, 6), pt(25, 11), pt(15, 16), ink, 1.5f);
      d->AddLine(pt(5, 11), pt(5, 22), ink, 1.5f);
      d->AddLine(pt(25, 11), pt(25, 22), ink, 1.5f);
      d->AddLine(pt(15, 16), pt(15, 27), ink, 1.5f);
      d->AddLine(pt(5, 22), pt(15, 27), ink, 1.5f);
      d->AddLine(pt(25, 22), pt(15, 27), ink, 1.5f);
    }
    if (ImGui::IsItemHovered())
      ImGui::SetTooltip("%s", tips[i]);
  }
  ImGui::End();
  if (inspector)
  {
    ImGui::SetNextWindowPos({std::max(48.f, w - 310), 70});
    ImGui::SetNextWindowSize({310, std::max(1.f, h - 96)});
    ImGui::Begin("Inspector", nullptr, fixed);
    if (ImGui::BeginTabBar("InspectorTabs"))
    {
      if (ImGui::BeginTabItem("Map"))
      {
        ImGui::Text(
          "Selection: %i brush(es)", (int)cvars->GetFloat("ftebroom_selection_count"));
        ImGui::SeparatorText("Brush creation");
        float height = cvars->GetFloat("ftebroom_height"),
              plane = cvars->GetFloat("ftebroom_plane");
        ImGui::SetNextItemWidth(120);
        if (ImGui::InputFloat("Height", &height, 16, 64))
          cvars->SetFloat("ftebroom_height", std::clamp(height, 1.f, 8192.f));
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
        if (ImGui::Checkbox("Show construction grid", &visible))
          cvars->SetFloat("ftebroom_grid_visible", visible);
        ImGui::SeparatorText("Document");
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
      if (ImGui::BeginTabItem("Material"))
      {
        static char material[128] = "ftebroom/grid";
        ImGui::InputText("Name", material, sizeof material);
        if (ImGui::Button("Use for new brushes"))
          cvars->SetString("ca_newbrushtexture", material);
        ImGui::TextWrapped(
          "Material names refer to assets in the active FTE game directory.");
        ImGui::EndTabItem();
      }
      ImGui::EndTabBar();
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
      ImGui::Text("Write maps/%s.map? Existing files are replaced.", mapName);
      ImGui::BeginDisabled(!safeName(mapName));
      if (ImGui::Button("Save"))
      {
        action((std::string("mod_terrain_save \"\" ") + mapName + "\n").c_str());
        ImGui::CloseCurrentPopup();
      }
      ImGui::EndDisabled();
      ImGui::SameLine();
      if (ImGui::Button("Cancel"))
        ImGui::CloseCurrentPopup();
      ImGui::EndPopup();
    }
    if (ImGui::BeginPopupModal("Open map?", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
    {
      ImGui::Text("Open maps/%s.map? Unsaved edits are discarded.", mapName);
      ImGui::BeginDisabled(!safeName(mapName));
      if (ImGui::Button("Open"))
      {
        action((std::string("mapedit maps/") + mapName + ".map\n").c_str());
        ImGui::CloseCurrentPopup();
      }
      ImGui::EndDisabled();
      ImGui::SameLine();
      if (ImGui::Button("Cancel"))
        ImGui::CloseCurrentPopup();
      ImGui::EndPopup();
    }
    ImGui::End();
  }
  ImGui::SetNextWindowPos({0, h - 26});
  ImGui::SetNextWindowSize({w, 26});
  ImGui::Begin("##status", nullptr, fixed);
  ImGui::Text(
    "Grid %g | %s | Click: select | Drag: create / move selected | "
    "Alt: Z | RMB: look + WASD | F1: inspector",
    cvars->GetFloat("ca_grid"),
    sceneDrag ? (altHeld ? "Z constraint" : "XY constraint") : "Ready");
  ImGui::End();
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
    x >= 48 && x < (inspector ? w - 310 : w) && y >= 70 && y < h - 26 && !popupOpen;
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
    if (key == input->GetKeyCode("ctrl", nullptr))
      ctrlHeld = down;
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
        const char* stop[] = {"-forward\n", "-back\n", "-moveleft\n", "-moveright\n"};
        for (int i = 0; i < 4; i++)
        {
          if (moveHeld[i])
            command(stop[i]);
          moveHeld[i] = false;
        }
      }
    }
    const char* moveKey[] = {"w", "s", "a", "d"};
    const char* start[] = {"+forward\n", "+back\n", "+moveleft\n", "+moveright\n"};
    const char* stop[] = {"-forward\n", "-back\n", "-moveleft\n", "-moveright\n"};
    for (int i = 0; i < 4; i++)
      if (key == input->GetKeyCode(moveKey[i], nullptr))
      {
        if (down && sceneLook && !moveHeld[i])
        {
          command(start[i]);
          moveHeld[i] = true;
        }
        if (!down && moveHeld[i])
        {
          command(stop[i]);
          moveHeld[i] = false;
        }
      }
    if (down && key == wheelUp)
      io.AddMouseWheelEvent(0, 1);
    if (down && key == wheelDown)
      io.AddMouseWheelEvent(0, -1);
    struct Key
    {
      const char* name;
      ImGuiKey code;
    };
    static const Key keys[] = {
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
    if (down && key == input->GetKeyCode("f1", nullptr) && !popupOpen)
      inspector = !inspector;
    if (down && key == input->GetKeyCode("escape", nullptr))
      cancelGesture();
    if (down && !io.WantTextInput && !popupOpen)
    {
      if (ctrlHeld && key == input->GetKeyCode("z", nullptr))
        action("brushedit_undo\n");
      if (ctrlHeld && key == input->GetKeyCode("y", nullptr))
        action("brushedit_redo\n");
      if (key == input->GetKeyCode("del", nullptr))
        action("brushedit_delete\n");
    }
  }
  return qtrue;
}
static void openPanel()
{
  inspector = true;
  input->SetMenuFocus(qtrue, "", 0, 0, 1);
}
static void shutdown()
{
  if (ready)
  {
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
  if (!commands || !cvars || !draw || !input)
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
  core->ExportFunction("Shutdown", (funcptr_t)shutdown);
  commands->AddCommand("ftebroom", openPanel, "Open the FTEBroom editor panel.");
  core->Print("FTEBroom: native module loaded. Type ftebroom.\n");
  return qtrue;
}
