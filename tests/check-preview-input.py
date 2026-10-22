"""Exercise the actual engine input bridge, including release and validation."""
import pathlib
import subprocess
import tempfile

patch = (pathlib.Path(__file__).parents[1] / 'patches/editor-embedded-preview.patch').read_text()
added = '\n'.join(line[1:] for line in patch.splitlines() if line.startswith('+') and not line.startswith('+++'))
start = added.index('static void FTEBroom_PreviewInput_f')
end = added.index('{', start)
depth = 1
end += 1
while depth:
    depth += (added[end] == '{') - (added[end] == '}')
    end += 1
function = added[start:end]
stub = r'''
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
typedef bool qboolean;
bool enabled=false,play=false;
std::vector<const char*> args;
struct Key {int code,unicode;bool down;};std::vector<Key> keys;
int moves=0;float mx=0,my=0;
int COM_CheckParm(const char*){return enabled;}
float Cvar_VariableValue(const char*){return play;}
const char* Cmd_Argv(int n){return n<(int)args.size()?args[n]:"";}
int Cmd_Argc(){return (int)args.size();}
void Key_Event(int,int key,int unicode,bool down){keys.push_back({key,unicode,down});}
void IN_MouseMove(int,int,float x,float y,float,float){moves++;mx=x;my=y;}
'''
checks = r'''
int main(){
 args={"input","key","119","119","1"};FTEBroom_PreviewInput_f();assert(keys.empty());
 enabled=true;FTEBroom_PreviewInput_f();assert(keys.empty());
 play=true;FTEBroom_PreviewInput_f();assert(keys.size()==1&&keys.back().down);
 args={"input","key","512","0","1"};FTEBroom_PreviewInput_f();assert(keys.size()==2);
 play=false;args={"input","reset"};FTEBroom_PreviewInput_f();assert(keys.size()==4&&!keys[2].down&&!keys[3].down);
 FTEBroom_PreviewInput_f();assert(keys.size()==4);
 play=true;
 for(const char* key:{"-1","0","1024"}){args={"input","key",key,"0","1"};FTEBroom_PreviewInput_f();}
 args={"input","key","119","0","2"};FTEBroom_PreviewInput_f();assert(keys.size()==4);
 args={"input","mouse","12.5","-8"};FTEBroom_PreviewInput_f();assert(moves==1&&mx==12.5&&my==-8);
 for(const char* x:{"nan","inf","8193"}){args={"input","mouse",x,"0"};FTEBroom_PreviewInput_f();}
 assert(moves==1);
}
'''
with tempfile.TemporaryDirectory(prefix='ftebroom-input-') as directory:
    source = pathlib.Path(directory) / 'input.cpp'
    executable = pathlib.Path(directory) / 'input.exe'
    source.write_text(stub + function + checks)
    subprocess.run(['g++', '-std=c++17', '-static', str(source), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
print('PASS: input gates, real key codes, release-all across mode changes, pointer validation')
