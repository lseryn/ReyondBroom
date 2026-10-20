// SPDX-License-Identifier: GPL-2.0-or-later
// Action contexts are OR alternatives within each group and AND between groups.
enum ActionContext : uint32_t
{
  CtxAny = 0,
  CtxView3D = 1 << 0,
  CtxView2D = 1 << 1,
  CtxAnyView = 3,
  CtxNoSelection = 1 << 2,
  CtxNodeSelection = 1 << 3,
  CtxFaceSelection = 1 << 4,
  CtxAnySelection = CtxNodeSelection | CtxFaceSelection,
  CtxAnyOrNoSelection = CtxNoSelection | CtxAnySelection,
  CtxNoTool = 1 << 5,
  CtxBrushTool = 1 << 6,
  CtxClipTool = 1 << 7,
  CtxRotateTool = 1 << 8,
  CtxScaleTool = 1 << 9,
  CtxShearTool = 1 << 10,
  CtxVertexTool = 1 << 11,
  CtxEdgeTool = 1 << 12,
  CtxFaceTool = 1 << 13,
  CtxControlPointTool = 1 << 14,
  CtxSweepTool = 1 << 15,
  CtxAnyHandleTool = CtxVertexTool | CtxEdgeTool | CtxFaceTool | CtxControlPointTool,
  CtxAnyTool = 0xffc0,
  CtxAnyOrNoTool = 0xffe0
};
struct KeyChord
{
  int key;
  bool ctrl, alt, shift;
};
struct Action
{
  const char* id;
  const char* label;
  uint32_t context;
  std::vector<KeyChord> defaults;
  const char* command;
  bool (*enabled)();
  std::string shortcutText;
  const char* gesture;
};
static std::vector<Action> actions;
static bool actionReference = false, selectMaterialTab = false,
            preferencesRequest = false;
static void initActions()
{
  if (!actions.empty())
    return;
  auto add = [](
               const char* id,
               const char* label,
               uint32_t ctx,
               const char* chords,
               const char* cmd,
               const char* gesture) {
    Action a{id, label, ctx, {}, cmd, nullptr, chords, gesture};
    std::string keys = chords;
    size_t start = 0;
    while (start < keys.size())
    {
      auto end = keys.find(';', start);
      auto chord = keys.substr(start, end == std::string::npos ? end : end - start);
      KeyChord k{0, false, false, false};
      for (auto modifier : {"Ctrl+", "Alt+", "Shift+"})
      {
        auto pos = chord.find(modifier);
        if (pos == std::string::npos)
          continue;
        if (modifier[0] == 'C')
          k.ctrl = true;
        else if (modifier[0] == 'A')
          k.alt = true;
        else
          k.shift = true;
        chord.erase(pos, std::char_traits<char>::length(modifier));
      }
      k.key = input->GetKeyCode(chord.c_str(), nullptr);
      a.defaults.push_back(k);
      if (end == std::string::npos)
        break;
      start = end + 1;
    }
    actions.push_back(std::move(a));
  };
#include "ftebroom_actions.inc"
}
static uint32_t currentActionContext()
{
  uint32_t ctx = cvars->GetFloat("ftebroom_ctx_view") == 0 ? CtxView3D : CtxView2D;
  int selection = (int)cvars->GetFloat("ftebroom_ctx_selection");
  ctx |= selection == 2   ? CtxFaceSelection
         : selection == 1 ? CtxNodeSelection
                          : CtxNoSelection;
  static const uint32_t contexts[] = {
    CtxNoTool,
    CtxBrushTool,
    CtxClipTool,
    CtxRotateTool,
    CtxSweepTool,
    CtxScaleTool,
    CtxShearTool,
    CtxVertexTool,
    CtxEdgeTool,
    CtxFaceTool,
    CtxControlPointTool};
  int tool = std::clamp((int)cvars->GetFloat("ftebroom_tool"), 0, 10);
  ctx |= contexts[tool];
  return ctx;
}
static bool actionMatches(uint32_t required, uint32_t current)
{
  for (uint32_t group :
       {uint32_t(CtxAnyView), uint32_t(CtxAnyOrNoSelection), uint32_t(CtxAnyOrNoTool)})
    if ((required & group) && !(required & current & group))
      return false;
  return true;
}
static bool actionAvailable(const Action& a)
{
  return a.command && actionMatches(a.context, currentActionContext())
         && (!a.enabled || a.enabled());
}
static void executeAction(const Action& a, bool down = true)
{
  if (!a.command)
  {
    if (down)
      core->Print(
        (std::string("FTEBroom: ") + a.label + " is not implemented yet\n").c_str());
    return;
  }
  std::string cmd = a.command;
  if (cmd.rfind("ftebroom_hold ", 0) == 0)
  {
    const char* keys = "wsadqx";
    const char* found = std::strchr(keys, cmd.back());
    if (found)
      moveHeld[found - keys] = down;
    return;
  }
  if (!down)
    return;
  if (cmd.rfind("ftebroom_ui ", 0) == 0)
  {
    auto name = cmd.substr(12);
    if (name == "cancel")
    {
      if (popupOpen || ImGui::GetIO().WantTextInput)
        return;
      if (sceneLook)
      {
        cameraEnd();
        return;
      }
      sceneDrag = false;
      command("ftebroom_cancel\n");
    }
    else if (name == "texturelock" || name == "uvlock")
    {
      const char* var =
        name == "texturelock" ? "ftebroom_texture_lock" : "ftebroom_uv_lock";
      cvars->SetFloat(var, !cvars->GetFloat(var));
    }
    else if (name == "cycle" || name == "maximize")
      viewAction(name);
    else if (
      name == "copy" || name == "cut" || name == "paste" || name == "pasteoriginal")
      clipboardAction(name);
    else if (name == "replacematerial")
      replaceMaterialRequest = true;
    else if (name == "moveobjects")
      moveObjectsRequest = true;
    else if (name == "selectline")
      selectLineRequest = true;
    else if (name == "preferences")
      preferencesRequest = true;
    else if (name == "clip")
    {
      cancelGesture();
      command("ftebroom_tool_toggle clip\n");
      selectMapTab = true;
    }
    else if (name == "new" || name == "close")
      documentRequest("__new");
    else if (name == "exit")
      documentRequest("exit");
    else if (name == "save" && !documentUntitled)
      documentSave(documentName);
    else if (name == "save" || name == "saveas")
    {
      saveRequest = true;
      inspector = true;
    }
    else if (name == "open")
    {
      openRequest = true;
      inspector = true;
    }
    else if (name == "cameraposition")
      cameraPositionRequest = true;
    else if (name == "resources")
    {
      cancelGesture();
      setupNeeded = true;
    }
    else if (name == "grid")
      cvars->SetFloat("ftebroom_grid_visible", !cvars->GetFloat("ftebroom_grid_visible"));
    else if (name == "map")
      selectMapTab = true;
    else if (name == "material")
      selectMaterialTab = true;
    else if (name == "actions")
      actionReference = true;
    else if (name == "inspector")
      inspector = true;
    return;
  }
  if (cmd.rfind("ftebroom_tool_", 0) == 0)
  {
    cameraEnd();
    sceneDrag = sceneLook = false;
    selectMapTab = true;
  }
  if (cmd == "ftebroom_undo" || cmd == "ftebroom_redo" || cmd == "ftebroom_delete")
    cancelGesture();
  command((cmd + "\n").c_str());
}
static bool dispatchAction(int key, bool down, bool inScene)
{
  initActions();
  // Key release always clears held actions, even after modifiers or focus changed.
  if (!down)
  {
    for (auto& a : actions)
      if (a.command && std::string(a.command).rfind("ftebroom_hold ", 0) == 0)
        for (auto& k : a.defaults)
          if (k.key == key)
            executeAction(a, false);
    return false;
  }
  const Action* chosen = nullptr;
  // Flight modifiers change speed instead of disabling held movement shortcuts.
  if (
    !ctrlHeld && inScene && !popupOpen && !ImGui::GetIO().WantTextInput && !sceneDrag
    && cvars->GetFloat("ca_brush_view") == 0)
  {
    const char* flight = "wsadqx";
    for (int i = 0; i < 6; i++)
    {
      char name[2] = {flight[i], 0};
      if (key == input->GetKeyCode(name, nullptr))
      {
        moveHeld[i] = true;
        return true;
      }
    }
  }
  for (auto& a : actions)
  {
    if (!actionMatches(a.context, currentActionContext()))
      continue;
    if (a.enabled && !a.enabled())
      continue;
    for (auto& k : a.defaults)
    {
      if (k.key != key || k.ctrl != ctrlHeld || k.alt != altHeld || k.shift != shiftHeld)
        continue;
      bool cancel = std::string(a.id) == "Menu/Tools/Cancel";
      if ((popupOpen || ImGui::GetIO().WantTextInput) && !cancel)
        continue;
      if ((a.context & CtxAnyView) && !inScene)
        continue;
      if (
        a.command && std::string(a.command).rfind("ftebroom_hold ", 0) == 0 && sceneDrag)
        continue;
      if (chosen)
        core->Print("FTEBroom: ambiguous shortcut\n");
      else
        chosen = &a;
    }
  }
  if (chosen)
    executeAction(*chosen);
  return chosen != nullptr;
}
static std::string historyActionLabel(const Action& a);
static void actionButton(const char* id)
{
  initActions();
  for (auto& a : actions)
    if (std::string(a.id) == id)
    {
      ImGui::BeginDisabled(!actionAvailable(a));
      if (ImGui::Button(historyActionLabel(a).c_str()))
        executeAction(a);
      ImGui::EndDisabled();
      return;
    }
}
static std::string historyActionLabel(const Action& a)
{
  const std::string id = a.id;
  if (id != "Menu/Edit/Undo" && id != "Menu/Edit/Redo")
    return a.label;
  char name[160] = {};
  cvars->GetString(
    id == "Menu/Edit/Undo" ? "ftebroom_undo_name" : "ftebroom_redo_name",
    name,
    sizeof name);
  return std::string(a.label) + (*name ? " " + std::string(name) : "");
}
static void actionMenuGroup(const char* group)
{
  std::string prefix = std::string("Menu/") + group + "/";
  for (auto& a : actions)
    if (
      std::string(a.id).rfind(prefix, 0) == 0
      && std::string(a.id).find('/', prefix.size()) == std::string::npos)
    {
      bool held = a.command && std::string(a.command).rfind("ftebroom_hold ", 0) == 0;
      if (
        ImGui::MenuItem(
          historyActionLabel(a).c_str(),
          a.shortcutText.c_str(),
          false,
          actionAvailable(a) && !held))
        executeAction(a);
    }
}
static void actionMenus()
{
  initActions();
  for (auto group : {"File", "Edit", "View", "Run", "Help"})
    if (ImGui::BeginMenu(group))
    {
      actionMenuGroup(group);
      if (std::string(group) == "View" && ImGui::BeginMenu("Grid"))
      {
        actionMenuGroup("View/Grid");
        ImGui::EndMenu();
      }
      if (std::string(group) == "Edit")
        for (auto nested : {"Tools", "Transform", "Textures"})
          if (ImGui::BeginMenu(nested))
          {
            actionMenuGroup(nested);
            ImGui::EndMenu();
          }
      if (std::string(group) == "View" && ImGui::BeginMenu("Camera"))
      {
        actionMenuGroup("Camera");
        ImGui::EndMenu();
      }
      ImGui::EndMenu();
    }
}
static void actionReferenceWindow()
{
  if (actionReference)
  {
    ImGui::OpenPopup("Action reference");
    actionReference = false;
  }
  ImGui::SetNextWindowSize({760, 500}, ImGuiCond_FirstUseEver);
  if (ImGui::BeginPopupModal("Action reference", nullptr))
  {
    if (ImGui::Button("Close") || ImGui::IsKeyPressed(ImGuiKey_Escape))
      ImGui::CloseCurrentPopup();
    ImGui::TextWrapped(
      "Reserved actions are not implemented. Mouse gestures are listed as roadmap "
      "references.");
    if (
      ImGui::BeginTable(
        "actions",
        3,
        ImGuiTableFlags_ScrollY | ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg,
        {0, 400}))
    {
      ImGui::TableSetupColumn("Action", ImGuiTableColumnFlags_WidthStretch, 4);
      ImGui::TableSetupColumn(
        "Shortcut / gesture", ImGuiTableColumnFlags_WidthStretch, 3);
      ImGui::TableSetupColumn("Status", ImGuiTableColumnFlags_WidthStretch, 2);
      ImGui::TableHeadersRow();
      for (auto& a : actions)
      {
        ImGui::TableNextRow();
        ImGui::TableNextColumn();
        ImGui::TextWrapped("%s", a.label);
        if (ImGui::IsItemHovered())
          ImGui::SetTooltip("%s", a.id);
        ImGui::TableNextColumn();
        ImGui::TextWrapped("%s", *a.gesture ? a.gesture : a.shortcutText.c_str());
        ImGui::TableNextColumn();
        ImGui::TextUnformatted(
          *a.gesture  ? "Gesture reference"
          : a.command ? "Implemented"
                      : "Reserved");
      }
      ImGui::EndTable();
    }
    ImGui::EndPopup();
  }
}
static void dumpActions()
{
  initActions();
  core->Print("FTEBROOM_ACTIONS_BEGIN\n");
  for (auto& a : actions)
  {
    std::string codes;
    for (auto& k : a.defaults)
    {
      if (!codes.empty())
        codes += ";";
      codes += std::to_string(k.key) + ":" + std::to_string(k.ctrl)
               + std::to_string(k.alt) + std::to_string(k.shift);
    }
    core->Print((std::string("FTEBROOM_ACTION\t") + a.id + "\t" + a.label + "\t"
                 + std::to_string(a.context) + "\t" + a.shortcutText + "\t" + codes + "\t"
                 + (a.command ? "implemented" : "reserved") + "\t" + a.gesture + "\n")
                  .c_str());
  }
  core->Print("FTEBROOM_ACTIONS_END\n");
}
