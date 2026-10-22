"""Exercise the exact palette hook and verify read-only base/mod mount ordering."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
renderer = (root / 'engine/client/renderer.c').read_text()
start = renderer.index('static void FTEBroom_ReloadPalette_f(void)\n{')
end = renderer.index('\nqboolean R_ApplyRenderer', start)
hook = renderer[start:end]
stub = r'''
#include <cassert>
#include <cstdlib>
#include <cstring>
using qbyte=unsigned char;
qbyte default_quakepal[768],*host_basepal=nullptr;
int qrenderer=1,sourceSize=768,updates=0,syncs=0;bool insecure=false;
struct {int fullbright;}vid;
bool Cmd_IsInsecure(){return insecure;}
void COM_WorkerFullSync(){syncs++;}
void BZ_Free(void* p){free(p);}
qbyte* BZ_Malloc(size_t n){return (qbyte*)malloc(n);}
qbyte* FS_LoadMallocFile(const char*,size_t* size){*size=sourceSize;if(!sourceSize)return nullptr;auto p=BZ_Malloc(sourceSize);memset(p,42,sourceSize);return p;}
void R_GenPaletteLookup(){updates++;}
'''
checks = r'''
int main(){
 memset(default_quakepal,17,sizeof default_quakepal);
 insecure=true;FTEBroom_ReloadPalette_f();assert(!syncs&&!updates&&!host_basepal);
 insecure=false;qrenderer=0;FTEBroom_ReloadPalette_f();assert(!syncs);
 qrenderer=1;FTEBroom_ReloadPalette_f();assert(syncs==1&&updates==1&&host_basepal[767]==42&&vid.fullbright==32);
 sourceSize=5;FTEBroom_ReloadPalette_f();assert(updates==2&&host_basepal[767]==17);
 sourceSize=0;FTEBroom_ReloadPalette_f();assert(updates==3&&host_basepal[0]==17);free(host_basepal);
}
'''
with tempfile.TemporaryDirectory(prefix='ftebroom-q1-palette-') as folder:
    cpp=Path(folder)/'check.cpp';exe=Path(folder)/'check.exe'
    cpp.write_text(stub+hook+checks)
    subprocess.run(['g++','-std=c++17','-static',str(cpp),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True)
fs=(root/'engine/common/fs.c').read_text()
mount=fs[fs.index('if (*ftebroom_assetpath.string)'):]
assert mount.index('ftebroom_modassetpath.string')<mount.index('countof(fs_manifest->gamepath)')
assert mount[:mount.index('countof(fs_manifest->gamepath)')].count('SPF_PRIVATE|SPF_COPYPROTECTED')==2
print('PASS: palette lifetime, invalid/missing palette fallback, insecure/renderer gates, read-only base/mod precedence')
