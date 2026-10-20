// SPDX-License-Identifier: GPL-2.0-or-later
static bool moveObjectsRequest;
static void moveObjectsDialog()
{
  static float delta[3] = {};
  if (moveObjectsRequest)
  {
    moveObjectsRequest = false;
    ImGui::OpenPopup("Move Objects");
  }
  if (ImGui::BeginPopupModal("Move Objects", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
  {
    ImGui::InputFloat3("Delta X Y Z", delta);
    bool valid = true;
    for (float value : delta)
      valid &= std::isfinite(value) && std::abs(value) <= 131072;
    ImGui::BeginDisabled(!valid);
    if (ImGui::Button("Move"))
    {
      char text[160];
      std::snprintf(
        text,
        sizeof text,
        "ftebroom_move %.9g %.9g %.9g\n",
        delta[0],
        delta[1],
        delta[2]);
      action(text);
      ImGui::CloseCurrentPopup();
    }
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape))
      ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
  }
}
