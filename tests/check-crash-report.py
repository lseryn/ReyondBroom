"""Exercise the exact engine crash writer, including Unicode and fallback paths."""
from pathlib import Path
import tempfile, subprocess, sys
engine=Path(sys.argv[1]);s=(engine/'engine/client/sys_win.c').read_text()
code=s[s.index('static void FTEBroom_CrashCopy'):s.index('DWORD CrashExceptionHandler')]
stub=r'''
#include <windows.h>
#include <string>
#include <map>
#include <fstream>
#include <filesystem>
#include <cassert>
using qboolean=bool;
#define countof(x) (sizeof(x)/sizeof((x)[0]))
std::map<std::string,std::string> vars;
const char* Cvar_VariableString(const char* n){return vars[n].c_str();}
'''
test=r'''
int main(){
 auto root=std::filesystem::temp_directory_path()/"ftebroom-crash-writer-test";std::filesystem::create_directories(root);
 auto path=root/std::filesystem::u8path(u8"карта_crash.txt");auto context=root/"context.txt";auto log=root/"console.txt";
 std::ofstream(context)<<"map=test profile=quake1\n";std::ofstream(log)<<"last console message\n";
 vars["ftebroom_crash_path"]=path.u8string();vars["ftebroom_crash_context"]=context.u8string();vars["ftebroom_crash_console"]=log.u8string();vars["ftebroom_crash_fallback"]=(root/"fallback.txt").u8string();
 FTEBroom_CrashReport("exception 0xc0000005",false);FTEBroom_CrashReport("stack: engine -> plugin",true);
 std::ifstream input(path);std::string bytes((std::istreambuf_iterator<char>(input)),{});assert(bytes.find("exception")!=bytes.npos&&bytes.find("profile=quake1")!=bytes.npos&&bytes.find("last console")!=bytes.npos&&bytes.find("stack:")!=bytes.npos);
 vars["ftebroom_crash_path"]=(root/"missing"/"map_crash.txt").u8string();FTEBroom_CrashReport("fallback",false);assert(std::filesystem::file_size(root/"fallback.txt")>8);
}
'''
with tempfile.TemporaryDirectory(prefix='ftebroom-crash-unit-') as tmp:
    cpp=Path(tmp)/'test.cpp';exe=Path(tmp)/'test.exe';cpp.write_text(stub+code+test,encoding='utf-8')
    subprocess.run(['g++','-std=c++17','-static',str(cpp),'-o',str(exe)],check=True);subprocess.run([str(exe)],check=True)
print('PASS: Unicode crash report, reason/context/console/stack, unwritable-map fallback')
