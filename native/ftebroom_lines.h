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
  int brushLine=0;std::string faceLine;std::map<int,int> firstContents;std::set<int> mixedContents;
  char c;
  while (in.get(c))
  {
    if (c == '\n')
    {
      if(depth>=2 && brushLine)
      {
        size_t cursor=0;std::vector<std::string> words;std::string word;
        while(!(word=token(faceLine,cursor)).empty())words.push_back(word);
        bool valve=std::find(words.begin(),words.end(),"[")!=words.end();
        bool primitive=words.size()>5 && words[5]==")";
        if(!words.empty() && words[0]=="(" && words.size()>=(primitive?20u:valve?34u:24u))
        {
          try {size_t used=0;auto value=std::stoll(words[words.size()-3],&used);
            if(used==words[words.size()-3].size() && value>=INT32_MIN && value<=INT32_MAX)
            {auto inserted=firstContents.emplace(brushLine,(int)value);if(!inserted.second&&inserted.first->second!=value)mixedContents.insert(brushLine);}}
          catch(const std::exception&){}
        }
      }
      faceLine.clear();
      ++line;
      comment = false;
    }
    else faceLine+=c;
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
      {
        brushLine=line;
        out << line << ' ' << entity << ' ' << brush++ << '\n';
      }
      ++depth;
    }
    else if (c == '}')
      --depth;
  }
  for(int mixed:mixedContents)out<<"mixed "<<mixed<<'\n';
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
  if (uiDialog("Select by Line Number"))
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
