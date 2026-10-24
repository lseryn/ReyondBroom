// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <string>
static std::string gameWallReadFile(const std::filesystem::path& path){
 auto ext=path.extension().u8string();for(char& c:ext)if(c>='A'&&c<='Z')c+=32;
 if(ext!=".glsl")throw std::runtime_error("Choose a .glsl file.");
 std::ifstream input(path,std::ios::binary);if(!input)throw std::runtime_error("Cannot open the selected GLSL file.");
 std::string bytes(1024*1024+1,'\0');input.read(bytes.data(),bytes.size());bytes.resize(size_t(input.gcount()));
 if(input.bad()||bytes.empty()||bytes.size()>1024*1024||bytes.find('\0')!=std::string::npos)throw std::runtime_error("Choose a nonempty text GLSL file, at most 1 MiB.");
 return bytes;
}
