// SPDX-License-Identifier: GPL-2.0-or-later
static int uiScaleChoice = 0;
static ImFont* uiFonts[5] = {};
static float uiScale()
{
  return 1.f + .25f * uiScaleChoice;
}
static ImVec4 uiColor(int r, int g, int b)
{
  return {r / 255.f, g / 255.f, b / 255.f, 1};
}
static void uiStyle()
{
  // Match the dark palette's panel, button, text and highlight roles.
  ImGui::StyleColorsDark();
  auto& s = ImGui::GetStyle();
  s = ImGuiStyle();
  ImGui::StyleColorsDark(&s);
  auto& c = s.Colors;
  c[ImGuiCol_Text] = uiColor(207, 207, 207);
  c[ImGuiCol_TextDisabled] = uiColor(128, 128, 128);
  c[ImGuiCol_WindowBg] = uiColor(50, 50, 50);
  c[ImGuiCol_ChildBg] = uiColor(27, 27, 27);
  c[ImGuiCol_PopupBg] = uiColor(35, 35, 35);
  c[ImGuiCol_Border] = uiColor(24, 24, 24);
  c[ImGuiCol_FrameBg] = uiColor(27, 27, 27);
  c[ImGuiCol_FrameBgHovered] = uiColor(55, 55, 55);
  c[ImGuiCol_FrameBgActive] = uiColor(65, 65, 65);
  c[ImGuiCol_TitleBg] = uiColor(40, 40, 40);
  c[ImGuiCol_TitleBgActive] = uiColor(50, 50, 50);
  c[ImGuiCol_MenuBarBg] = uiColor(40, 40, 40);
  c[ImGuiCol_Button] = uiColor(35, 35, 35);
  c[ImGuiCol_ButtonHovered] = uiColor(62, 82, 112);
  c[ImGuiCol_ButtonActive] = uiColor(62, 112, 205);
  c[ImGuiCol_Header] = uiColor(55, 70, 95);
  c[ImGuiCol_HeaderHovered] = uiColor(62, 92, 155);
  c[ImGuiCol_HeaderActive] = uiColor(62, 112, 205);
  c[ImGuiCol_CheckMark] = c[ImGuiCol_SliderGrab] = uiColor(100, 153, 240);
  c[ImGuiCol_SliderGrabActive] = uiColor(140, 180, 250);
  c[ImGuiCol_Tab] = uiColor(35, 35, 35);
  c[ImGuiCol_TabSelected] = uiColor(55, 70, 95);
  c[ImGuiCol_TabHovered] = uiColor(62, 112, 205);
  c[ImGuiCol_TabDimmed] = uiColor(35, 35, 35);
  c[ImGuiCol_TabDimmedSelected] = uiColor(50, 50, 50);
  c[ImGuiCol_TabSelectedOverline] = uiColor(62, 112, 205);
  c[ImGuiCol_Separator] = uiColor(28, 28, 28);
  c[ImGuiCol_SeparatorHovered] = c[ImGuiCol_SeparatorActive] = uiColor(62, 112, 205);
  c[ImGuiCol_DockingEmptyBg] = uiColor(40, 40, 40);
  s.WindowRounding = 3;
  s.ChildRounding = 2;
  s.FrameRounding = 3;
  s.GrabRounding = 3;
  s.PopupRounding = 4;
  s.WindowBorderSize = 1;
  s.FrameBorderSize = 0;
  s.WindowPadding = {8, 8};
  s.FramePadding = {6, 4};
  s.ItemSpacing = {8, 6};
  s.WindowMinSize = {46, 46};
  s.ScaleAllSizes(uiScale());
  ImGui::GetIO().FontDefault = uiFonts[uiScaleChoice];
}
static bool uiDialog(const char* title, ImVec2 initial = {560, 240})
{
  const auto display = ImGui::GetIO().DisplaySize;
  ImGui::SetNextWindowSize(
    {std::min(display.x - 24, initial.x * uiScale()),
     std::min(display.y - 64, initial.y * uiScale())},
    ImGuiCond_FirstUseEver);
  ImGui::SetNextWindowSizeConstraints({280, 120}, ImGui::GetIO().DisplaySize);
  return ImGui::BeginPopupModal(title, nullptr, ImGuiWindowFlags_HorizontalScrollbar);
}
