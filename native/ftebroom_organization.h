// SPDX-License-Identifier: GPL-2.0-or-later
#include <iomanip>
#include <sstream>
struct OrganizationNode
{
  int kind, id, flags, omit, order;
  std::string name;
};
static std::vector<OrganizationNode> organizationNodes;
static int organizationReadEpoch = -1;
static void organizationLoad()
{
  auto& epoch = organizationReadEpoch;
  int next = (int)cvars->GetFloat("ftebroom_tree_epoch");
  if (next == epoch)
    return;
  std::ifstream in(documentPath("data/ftebroom-ui-tree.txt"));
  if (!in)
    return;
  std::vector<OrganizationNode> nodes;
  OrganizationNode node;
  while (in >> node.kind >> node.id >> node.flags >> node.omit >> node.order
         >> std::quoted(node.name))
    nodes.push_back(node);
  if (!in.eof())
    return;
  organizationNodes = std::move(nodes);
  epoch = next;
  std::stable_sort(
    organizationNodes.begin(), organizationNodes.end(), [](const auto& a, const auto& b) {
      if (!a.id || !b.id)
        return a.id < b.id;
      return a.order < b.order;
    });
}
static std::string organizationQuote(const std::string& value)
{
  std::ostringstream out;
  out << std::quoted(value);
  return out.str();
}
static void organize(const char* operation, int target = 0, const std::string& value = "")
{
  command(("ftebroom_organize " + std::string(operation) + " " + std::to_string(target)
           + " " + organizationQuote(value) + "\n")
            .c_str());
}
static void organizationPanel()
{
  organizationLoad();
  if (ImGui::CollapsingHeader("Groups and visibility", ImGuiTreeNodeFlags_DefaultOpen))
  {
    static char name[256] = "Group";
    ImGui::InputText("Name##group", name, sizeof name);
    if (ImGui::Button("Group"))
      command(("ftebroom_group " + organizationQuote(name) + "\n").c_str());
    ImGui::SameLine();
    if (ImGui::Button("Ungroup"))
      organize("ungroup");
    ImGui::SameLine();
    if (ImGui::Button("Rename"))
      organize("rename", 0, name);
    if (ImGui::Button("Hide"))
      command("ftebroom_visibility hide\n");
    ImGui::SameLine();
    if (ImGui::Button("Isolate"))
      command("ftebroom_visibility isolate\n");
    ImGui::SameLine();
    if (ImGui::Button("Show all"))
      command("ftebroom_visibility showall\n");
    if (ImGui::BeginCombo("Add selection to group", "Choose group..."))
    {
      for (const auto& node : organizationNodes)
        if (node.kind == 2)
        {
          ImGui::PushID(node.id);
          if (ImGui::Selectable(node.name.c_str()))
            organize("move", node.id);
          ImGui::PopID();
        }
      ImGui::EndCombo();
    }
    if (ImGui::Button("Remove from group"))
      organize("removefromgroup");
    ImGui::SameLine();
    if (ImGui::Button("Make structural"))
      organize("structural");
  }
  if (ImGui::CollapsingHeader("Layers", ImGuiTreeNodeFlags_DefaultOpen))
  {
    static char name[256] = "New layer";
    ImGui::InputText("Name##layer", name, sizeof name);
    if (ImGui::Button("+ New layer"))
      organize("layernew", 0, name);
    ImGui::TextDisabled("Active / Visible / Locked / Omit export");
    int active = (int)cvars->GetFloat("ftebroom_active_layer");
    for (const auto& node : organizationNodes)
      if (node.kind == 1)
      {
        ImGui::PushID(node.id);
        if (ImGui::RadioButton("##active", active == node.id))
          organize("layeractive", node.id);
        ImGui::SameLine();
        bool visible = !(node.flags & 1), locked = node.flags & 2, omit = node.omit;
        if (ImGui::Checkbox("##visible", &visible))
          organize("layerhidden", node.id, visible ? "0" : "1");
        ImGui::SameLine();
        if (ImGui::Checkbox("##locked", &locked))
          organize("layerlocked", node.id, locked ? "1" : "0");
        ImGui::SameLine();
        if (ImGui::Checkbox("##omit", &omit))
          organize("layeromit", node.id, omit ? "1" : "0");
        ImGui::SameLine();
        if (
          ImGui::Selectable(
            node.name.c_str(), active == node.id, ImGuiSelectableFlags_AllowDoubleClick))
        {
          if (ImGui::IsMouseDoubleClicked(0))
            organize("layeractive", node.id);
        }
        if (node.id && ImGui::BeginDragDropSource())
        {
          ImGui::SetDragDropPayload("FTE_LAYER", &node.id, sizeof node.id);
          ImGui::TextUnformatted(node.name.c_str());
          ImGui::EndDragDropSource();
        }
        if (node.id && ImGui::BeginDragDropTarget())
        {
          if (auto payload = ImGui::AcceptDragDropPayload("FTE_LAYER"))
          {
            int moved = *(const int*)payload->Data;
            int order = 1;
            for (const auto& item : organizationNodes)
              if (item.kind == 1 && item.id && item.id != moved)
              {
                if (item.id == node.id)
                  organize("layersort", moved, std::to_string(order++));
                organize("layersort", item.id, std::to_string(order++));
              }
          }
          ImGui::EndDragDropTarget();
        }
        if (ImGui::BeginPopupContextItem())
        {
          if (ImGui::MenuItem("Make active"))
            organize("layeractive", node.id);
          if (ImGui::MenuItem("Move selection here"))
            organize("move", node.id);
          if (ImGui::MenuItem("Select contents"))
            organize("layerselect", node.id);
          if (ImGui::MenuItem("Isolate layer"))
          {
            for (const auto& item : organizationNodes)
              if (item.kind == 1)
                organize("layerhidden", item.id, item.id == node.id ? "0" : "1");
          }
          if (ImGui::MenuItem("Rename using Name field", nullptr, false, node.id != 0))
            organize("layerrename", node.id, name);
          if (
            ImGui::MenuItem("Remove layer (keep objects)", nullptr, false, node.id != 0))
            organize("layerremove", node.id);
          ImGui::Separator();
          for (int mode = 0; mode < 4; mode++)
            if (
              ImGui::MenuItem(
                mode == 0   ? "Show all layers"
                : mode == 1 ? "Hide all layers"
                : mode == 2 ? "Unlock all layers"
                            : "Lock all layers"))
            {
              for (const auto& item : organizationNodes)
                if (item.kind == 1)
                  organize(
                    mode < 2 ? "layerhidden" : "layerlocked",
                    item.id,
                    (mode & 1) ? "1" : "0");
            }
          ImGui::EndPopup();
        }
        ImGui::PopID();
      }
  }
}
