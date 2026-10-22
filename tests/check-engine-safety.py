"""Compile the actual patched C functions and exercise crash regressions."""
from pathlib import Path
import subprocess, tempfile, sys
root=Path(sys.argv[1]); cc=sys.argv[2] if len(sys.argv)>2 else 'gcc'
def extract(path,name):
 s=(root/path).read_text(); start=s.index('static ',s.index(name)-40); brace=s.index('{',start); depth=1;i=brace+1
 while depth:
  depth+=(s[i]=='{')-(s[i]=='}');i+=1
 return s[start:i]
flat=extract('engine/common/gl_q2bsp.c','Patch_FlatnessDepth(')
flat+='\n'+extract('engine/common/gl_q2bsp.c','Patch_FlatnessTest(')
text=extract('engine/gl/gl_backend.c','DeformGen_Text(')
prefix=r'''
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
typedef float vec3_t[3],vecV_t[3],vec2_t[2];typedef unsigned short index_t;typedef unsigned char qbyte;
#define max(a,b) ((a)>(b)?(a):(b))
#define VectorCopy(a,b) memcpy(b,a,sizeof(vec3_t))
#define VectorClear(a) memset(a,0,sizeof(vec3_t))
#define VectorSubtract(a,b,c) do{for(int z=0;z<3;z++)(c)[z]=(a)[z]-(b)[z];}while(0)
#define VectorAdd(a,b,c) do{for(int z=0;z<3;z++)(c)[z]=(a)[z]+(b)[z];}while(0)
#define VectorNegate(a,b) do{for(int z=0;z<3;z++)(b)[z]=-(a)[z];}while(0)
#define VectorScale(a,s,b) do{for(int z=0;z<3;z++)(b)[z]=(a)[z]*(s);}while(0)
#define VectorMA(a,s,b,c) do{for(int z=0;z<3;z++)(c)[z]=(a)[z]+(s)*(b)[z];}while(0)
#define VectorAvg(a,b,c) do{for(int z=0;z<3;z++)(c)[z]=((a)[z]+(b)[z])*0.5f;}while(0)
#define DotProduct(a,b) ((a)[0]*(b)[0]+(a)[1]*(b)[1]+(a)[2]*(b)[2])
#define Vector2Set(a,x,y) do{(a)[0]=x;(a)[1]=y;}while(0)
#define Q_snprintfz snprintf
float VectorNormalize(float *v){float n=sqrtf(DotProduct(v,v));if(n)for(int i=0;i<3;i++)v[i]/=n;return n;}
void CrossProduct(float *a,float *b,float *c){c[0]=a[1]*b[2]-a[2]*b[1];c[1]=a[2]*b[0]-a[0]*b[2];c[2]=a[0]*b[1]-a[1]*b[0];}
typedef struct{vec3_t *snormals_array,*tnormals_array,*normals_array;index_t *indexes;vecV_t *xyz_array;vec2_t *st_array;int numindexes,numvertexes;}mesh_t;
vecV_t vertexarray[128];index_t r_quad_indexes[192];struct{int sourcevbo,meshcount;mesh_t **meshes;}shaderstate;
struct variable{char *string;}variable={""};struct variable *Cvar_Get(char*a,char*b,int c,char*d){return &variable;}
void BE_GenTempMeshVBO(int *v,mesh_t*m){assert(m->numvertexes<=128);}
'''
main=r'''
int main(void){
 vec3_t a={0,0,0},b={32,32,0},c={64,0,0},line={32,0,0},nanpoint={NAN,1,0};
 assert(Patch_FlatnessTest(1,a,line,c)==0);
 assert(Patch_FlatnessTest(1,a,b,c)>0);
 assert(Patch_FlatnessTest(0,a,b,c)<=6);
 assert(Patch_FlatnessTest(0,a,nanpoint,c)<=6);
 mesh_t m={0};vecV_t src[4]={{-1,-1,0},{1,-1,0},{1,1,0},{-1,1,0}},dst[4];
 variable.string="test";DeformGen_Text(0,4,src,dst,&m);assert(!memcmp(src,dst,sizeof(src)));
 vec3_t right[1]={{1,0,0}},down[1]={{0,1,0}},normal[1]={{0,0,1}};
 m.snormals_array=right;m.tnormals_array=down;m.normals_array=normal;
 variable.string="";DeformGen_Text(0,4,src,dst,&m);assert(!memcmp(src,dst,sizeof(src)));
 variable.string="test";DeformGen_Text(0,4,src,dst,&m);assert(shaderstate.meshcount==1);
 for(int i=0;i<16;i++)for(int j=0;j<3;j++)assert(isfinite(vertexarray[i][j]));
 puts("PASS: bounded patch subdivision, NaN/zero tolerance, missing tangent basis, empty/nonempty shader text");
}
'''
with tempfile.TemporaryDirectory(prefix='ftebroom-engine-safety-') as directory:
 p=Path(directory);(p/'test.c').write_text(prefix+flat+'\n'+text+'\n'+main)
 subprocess.run([cc,'-std=c99','-O1',str(p/'test.c'),'-lm','-o',str(p/'test.exe')],check=True)
 subprocess.run([str(p/'test.exe')],check=True,timeout=10)
