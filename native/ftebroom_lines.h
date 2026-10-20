// SPDX-License-Identifier: GPL-2.0-or-later
#include <sstream>
// Index structural opening braces, ignoring braces inside strings and comments.
static bool selectLineRequest;
static void documentIndexLines(const std::filesystem::path& path)
{
  std::ifstream in(path, std::ios::binary);
  std::ostringstream out;
  int line = 1, depth = 0, entity = -1, brush = 0;
  bool quoted = false, escaped = false, comment = false, block = false;
  char c;
  while (in.get(c))
  {
    if (c == '\n')
    {
      ++line;
      comment = false;
    }
    if (comment)
      continue;
    if (block)
    {
      if (c == '*' && in.peek() == '/')
      {
        in.get();
        block = false;
      }
      continue;
    }
    if (quoted)
    {
      if (escaped)
        escaped = false;
      else if (c == '\\')
        escaped = true;
      else if (c == '"')
        quoted = false;
      continue;
    }
    if (c == '"')
    {
      quoted = true;
      continue;
    }
    if (c == '/' && in.peek() == '/')
    {
      in.get();
      comment = true;
      continue;
    }
    if (c == '/' && in.peek() == '*')
    {
      in.get();
      block = true;
      continue;
    }
    if (c == '{')
    {
      if (depth == 0)
      {
        ++entity;
        brush = 0;
        out << line << ' ' << entity << " -1\n";
      }
      if (depth == 1)
        out << line << ' ' << entity << ' ' << brush++ << '\n';
      ++depth;
    }
    else if (c == '}')
      --depth;
  }
  auto text = out.str();
  qhandle_t handle;
  if (files->Open("data/map-lines.txt", &handle, 2) < 0)
    return;
  files->Write(handle, text.data(), static_cast<int>(text.size()));
  files->Close(handle);
  command("ftebroom_line_index\n");
}
static void selectLineDialog()
{
  static int line = 1;
  if (selectLineRequest)
  {
    selectLineRequest = false;
    ImGui::OpenPopup("Select by Line Number");
  }
  if (
    ImGui::BeginPopupModal(
      "Select by Line Number", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
  {
    ImGui::TextUnformatted("Line in the last opened or saved MAP file.");
    ImGui::InputInt("Line", &line);
    ImGui::BeginDisabled(line < 1);
    if (ImGui::Button("Select"))
    {
      action(("ftebroom_select_line " + std::to_string(line) + "\n").c_str());
      ImGui::CloseCurrentPopup();
    }
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape))
      ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
  }
}
