"""Compile and exercise the exact camera hook from the engine patch."""
import pathlib
import subprocess
import tempfile

patch = (pathlib.Path(__file__).parents[1] / 'patches/editor-embedded-preview.patch').read_text()
added = '\n'.join(line[1:] for line in patch.splitlines() if line.startswith('+') and not line.startswith('+++'))
start = added.index('static void FTEBroom_PreviewCamera')
end = added.index('\n\tFTEBroom_PreviewCamera();', start)
function = added[start:end]
stub = r'''
#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <algorithm>
using std::max;
#define M_PI 3.14159265358979323846
typedef float vec3_t[3]; typedef bool qboolean;
#define VectorCopy(a,b) memcpy(b,a,3*sizeof(float))
#define VectorEquals(a,b) (memcmp(a,b,3*sizeof(float))==0)
#define RDF_NOWORLDMODEL 1
struct {int recurse=0,flags=0;float vieworg[3]{},pvsorigin[3]{},viewangles[3]{};bool externalview=false;float fov_x=0,fov_y=0;struct{int width=800,height=600;}vrect;} r_refdef;
bool enabled=false,play=false;const char* state="32 -160 96 15 90 0 90";
int COM_CheckParm(const char*){return enabled;}
const char* Cvar_VariableString(const char*){return state;}
float Cvar_VariableValue(const char* name){return !strcmp(name,"ftebroom_preview_play")&&play;}
'''
checks = r'''
int main(){
 FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==0);
 enabled=true;r_refdef.recurse=1;FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==0);
 r_refdef.recurse=0;r_refdef.flags=1;FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==0);
 r_refdef.flags=0;FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==32&&r_refdef.pvsorigin[1]==-160);
 assert(r_refdef.viewangles[0]==15&&r_refdef.externalview&&fabs(r_refdef.fov_y-73.7398)<.01);
 play=true;r_refdef.vieworg[0]=123;FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==123);
 play=false;FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==32);
 const char* bad[]={"1 2", "nan 2 3 0 0 0 90", "inf 0 0 0 0 0 90", "1 2 3 0 0 0 0", "1 2 3 0 0 0 180"};
 for(auto value:bad){state=value;FTEBroom_PreviewCamera();assert(r_refdef.vieworg[0]==32);}
}
'''
with tempfile.TemporaryDirectory(prefix='ftebroom-camera-') as directory:
    source = pathlib.Path(directory) / 'camera.cpp'
    executable = pathlib.Path(directory) / 'camera.exe'
    source.write_text(stub + function + checks)
    subprocess.run(['g++', '-std=c++17', '-static', str(source), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
print('PASS: preview gate, recursive views, PVS origin, camera angles/FOV and invalid input')
