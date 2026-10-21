// SPDX-License-Identifier: GPL-2.0-or-later
// Owned polyhedra: initialize to zero, then release with fb_poly_free.
#define FB_GEOM_MERGE 0.03125
#define FB_GEOM_PLANE 0.001
var float autocvar_ftebroom_world_bound = 65536;
typedef struct {int start,count;brushface_t attr;} fb_poly_face_t;
typedef struct {int a,b,face,other;} fb_poly_edge_t;
typedef struct {
    vector *vertices;
    int *indices;
    fb_poly_face_t *faces;
    fb_poly_edge_t *edges;
    int nv,ni,nf,ne;
    float volume;
} fb_poly_t;
string fb_geom_error;
void fb_poly_free(fb_poly_t *poly)
{
    for(int i=0;i<poly->nf;i++) strunzone(poly->faces[i].attr.shadername);
    memfree(poly->vertices);memfree(poly->indices);memfree(poly->faces);memfree(poly->edges);
    fb_poly_t empty={0};*poly=empty;
}
int fb_geom_fail(fb_poly_t *poly,string reason)
{
    fb_geom_error=reason;fb_poly_free(poly);return FALSE;
}
int fb_geom_finite(float value) {return value==value && fabs(value)<1000000000000000000000000000000.0;}
int fb_geom_point(vector point)
{
    float bound=autocvar_ftebroom_world_bound;
    if(!fb_geom_finite(bound) || bound<=0) bound=65536;
    for(int i=0;i<3;i++) if(!fb_geom_finite(point[i]) || fabs(point[i])>bound) return FALSE;
    return TRUE;
}
int fb_geom_sameplane(brushface_t *a,brushface_t *b)
{
    return vlen(a->planenormal-b->planenormal)<0.00001 && fabs(a->planedist-b->planedist)<FB_GEOM_PLANE;
}
// FTE's large seed winding can lose a few thousandths during clipping.
// Refine each corner against three independent supporting planes before merging.
vector fb_geom_refine(vector point,brushface_t *planes,int count,int face)
{
    vector a=planes[face].planenormal;
    int second=-1,third=-1;
    float best=0.00001;
    // At a cone apex many planes meet. The nearest pair can be almost parallel;
    // use the best-conditioned triple among planes incident on this corner.
    for(int i=0;i<count;i++) {
        if(i==face || fabs(point*planes[i].planenormal-planes[i].planedist)>=0.1)continue;
        vector cross=crossproduct(a,planes[i].planenormal);
        for(int j=i+1;j<count;j++) {
            if(j==face || fabs(point*planes[j].planenormal-planes[j].planedist)>=0.1)continue;
            float determinant=fabs(cross*planes[j].planenormal);
            if(determinant>best){best=determinant;second=i;third=j;}
        }
    }
    if(third<0)return point;
    vector b=planes[second].planenormal,ab=crossproduct(a,b);
    vector c=planes[third].planenormal;
    vector correction=(crossproduct(b,c)*(planes[face].planedist-point*a)+
        crossproduct(c,a)*(planes[second].planedist-point*b)+
        ab*(planes[third].planedist-point*c))/(ab*c);
    if(vlen(correction)>0.25) return point;
    return point+correction;
}
// The engine clips each plane against all other planes without creating map objects.
// Closed, oppositely directed edge pairs reject unbounded half-space intersections.
int fb_poly_from_faces(brushface_t *input,int count,fb_poly_t *poly)
{
    fb_poly_free(poly);fb_geom_error="";
    if(count<4 || count>MAX_BRUSHFACES) return fb_geom_fail(poly,"Face count outside 4..64");
    brushface_t *planes=memalloc(sizeof(brushface_t)*count);
    memcpy(planes,input,sizeof(brushface_t)*count);
    int valid=TRUE;
    for(int f=0;f<count;f++) {
        float length=vlen(planes[f].planenormal);
        if(!fb_geom_finite(length) || length<0.000001 || !fb_geom_finite(planes[f].planedist)) {valid=FALSE;break;}
        planes[f].planenormal/=length;planes[f].planedist/=length;
        for(int g=0;g<f;g++) if(fb_geom_sameplane(&planes[f],&planes[g])) {valid=FALSE;break;}
    }
    if(!valid) {memfree(planes);return fb_geom_fail(poly,"Invalid or duplicate plane");}
    int capacity=count*MAX_FACEPOINTS;
    poly->vertices=memalloc(sizeof(vector)*capacity);
    poly->indices=memalloc(sizeof(int)*capacity);
    poly->faces=memalloc(sizeof(fb_poly_face_t)*count);
    poly->edges=memalloc(sizeof(fb_poly_edge_t)*capacity);
    static vector points[MAX_FACEPOINTS+1];
    for(int f=0;f<count;f++) {
        int n=brush_calcfacepoints(f+1,planes,count,points,points.length);
        if(n<3 || n>MAX_FACEPOINTS) {memfree(planes);return fb_geom_fail(poly,"Empty or oversized face");}
        fb_poly_face_t *face=&poly->faces[poly->nf++];
        face->start=poly->ni;face->count=n;face->attr=planes[f];
        face->attr.shadername=strzone(input[f].shadername);
        vector area='0 0 0';
        for(int j=1;j<n-1;j++) area+=crossproduct(points[j]-points[0],points[j+1]-points[0]);
        if(vlen(area)<0.000001) {memfree(planes);return fb_geom_fail(poly,"Zero area face");}
        // Clockwise winding viewed from the outward normal.
        int reverse=area*planes[f].planenormal>0;
        for(int j=0;j<n;j++) {
            int index=j;if(reverse) index=n-1-j;
            vector p=fb_geom_refine(points[index],planes,count,f);
            if(!fb_geom_point(p)) {memfree(planes);return fb_geom_fail(poly,"Vertex outside world bounds");}
            int v;
            for(v=0;v<poly->nv;v++) if(vlen(p-poly->vertices[v])<FB_GEOM_MERGE) break;
            if(v==poly->nv) poly->vertices[poly->nv++]=p;
            // Clipping can split a multi-plane apex into a tiny edge. Refinement
            // reunites its endpoints; discard that edge, not the entire brush.
            if(poly->ni>face->start)if(poly->indices[poly->ni-1]==v)continue;
            if(j==n-1 && poly->ni>face->start)if(poly->indices[face->start]==v)continue;
            for(int k=face->start;k<poly->ni;k++) if(poly->indices[k]==v) {memfree(planes);return fb_geom_fail(poly,"Collapsed face after vertex merge");}
            poly->indices[poly->ni++]=v;
        }
        face->count=poly->ni-face->start;
        if(face->count<3){memfree(planes);return fb_geom_fail(poly,"Collapsed face after vertex merge");}
    }
    memfree(planes);
    vector center='0 0 0';
    for(int v=0;v<poly->nv;v++) center+=poly->vertices[v];
    center=center/(float)poly->nv;
    for(int f=0;f<poly->nf;f++) {
        fb_poly_face_t *face=&poly->faces[f];
        for(int j=0;j<face->count;j++) {
            vector corner=poly->vertices[poly->indices[face->start+j]];
            if(fabs(corner*face->attr.planenormal-face->attr.planedist)>FB_GEOM_PLANE)
                return fb_geom_fail(poly,sprintf("Corner off its face plane (error %g)",corner*face->attr.planenormal-face->attr.planedist));
            int next=j+1;if(next==face->count) next=0;
            int a=poly->indices[face->start+j],b=poly->indices[face->start+next],e;
            for(e=0;e<poly->ne;e++) {
                fb_poly_edge_t *edge=&poly->edges[e];
                if(edge->a==b && edge->b==a) {
                    if(edge->other!=-1) return fb_geom_fail(poly,"Non-manifold edge");
                    edge->other=f;break;
                }
                if(edge->a==a && edge->b==b) return fb_geom_fail(poly,"Inconsistent face winding");
            }
            if(e==poly->ne) {
                fb_poly_edge_t *edge=&poly->edges[poly->ne++];
                edge->a=a;edge->b=b;edge->face=f;edge->other=-1;
            }
        }
        for(int v=0;v<poly->nv;v++)
            if(poly->vertices[v]*face->attr.planenormal-face->attr.planedist>FB_GEOM_PLANE)
                return fb_geom_fail(poly,"Vertex outside a supporting plane");
        vector a=poly->vertices[poly->indices[face->start]]-center;
        for(int j=1;j<face->count-1;j++) {
            vector b=poly->vertices[poly->indices[face->start+j]]-center;
            vector c=poly->vertices[poly->indices[face->start+j+1]]-center;
            poly->volume-=a*crossproduct(b,c)/6;
        }
    }
    for(int e=0;e<poly->ne;e++) if(poly->edges[e].other<0) return fb_geom_fail(poly,"Open or unbounded brush");
    if(poly->nv-poly->ne+poly->nf!=2) return fb_geom_fail(poly,"Invalid polyhedron topology");
    if(!fb_geom_finite(poly->volume) || poly->volume<=0.1) return fb_geom_fail(poly,"Brush volume is too small");
    return TRUE;
}
int fb_poly_from_brush(int model,int id,fb_poly_t *poly)
{
    static brushface_t faces[MAX_BRUSHFACES];
    int n=brush_get(model,id,__NULL__,0,__NULL__);
    if(n<4 || n>MAX_BRUSHFACES) return fb_geom_fail(poly,"Not a supported convex brush");
    brush_get(model,id,faces,faces.length,__NULL__);
    return fb_poly_from_faces(faces,n,poly);
}
int fb_brush_valid(brushface_t *faces,int count)
{
    fb_poly_t poly={0};int ok=fb_poly_from_faces(faces,count,&poly);fb_poly_free(&poly);return ok;
}
// Output strings borrow storage from poly/source. Keep both alive until brush_create.
int fb_poly_to_faces(fb_poly_t *poly,brushface_t *source,int sourceCount,brushface_t *outfaces,int capacity)
{
    if(poly->nf<4 || poly->nf>capacity) return 0;
    for(int f=0;f<poly->nf;f++) {
        fb_poly_face_t *face=&poly->faces[f];
        int ia=0,ib=1,ic=2;
        float farthest=-1;
        for(int i=0;i<face->count;i++) for(int j=i+1;j<face->count;j++) {
            vector delta=poly->vertices[poly->indices[face->start+i]]-poly->vertices[poly->indices[face->start+j]];
            float distance=delta*delta;
            if(distance>farthest) {farthest=distance;ia=i;ib=j;}
        }
        vector a=poly->vertices[poly->indices[face->start+ia]],b=poly->vertices[poly->indices[face->start+ib]];
        float best=-1;
        for(int k=0;k<face->count;k++) {
            vector cross=crossproduct(b-a,poly->vertices[poly->indices[face->start+k]]-a);
            float area=cross*cross;
            if(area>best) {best=area;ic=k;}
        }
        if(best<0.00000001) return 0;
        brushface_t plane={0};
        plane.planenormal=normalize(crossproduct(b-a,poly->vertices[poly->indices[face->start+ic]]-a));
        if(plane.planenormal*face->attr.planenormal<0) plane.planenormal=-plane.planenormal;
        plane.planedist=plane.planenormal*a;
        int match=-1;
        for(int s=0;s<sourceCount;s++) if(fb_geom_sameplane(&plane,&source[s])) {match=s;break;}
        if(match>=0) outfaces[f]=source[match];
        else {
            outfaces[f]=plane;outfaces[f].shadername=cvar_string("ca_newbrushtexture");
            reset_texturecoords(&outfaces[f]);
        }
    }
    return poly->nf;
}
typedef struct {int a,b,c;vector normal;float dist;} fb_hull_tri_t;
void(fb_hull_tri_t *tri,int a,int b,int c,vector *points,vector inside) fb_hull_triangle =
{
    tri->a=a;tri->b=b;tri->c=c;
    tri->normal=normalize(crossproduct(points[b]-points[a],points[c]-points[a]));
    tri->dist=tri->normal*points[a];
    if(tri->normal*inside>tri->dist) {
        tri->b=c;tri->c=b;tri->normal=-tri->normal;tri->dist=-tri->dist;
    }
}
// Incremental tetrahedral hull. Coplanar triangles become one supporting plane.
// Rebrushify requires existing triangulation and rounds positions to whole units;
// neither behavior is appropriate for arbitrary fractional input points here.
int fb_hull(vector *points,int count,fb_poly_t *poly)
{
    fb_poly_free(poly);
    if(count<4 || count>4096) return fb_geom_fail(poly,"Hull requires 4..4096 points");
    for(int p=0;p<count;p++) if(!fb_geom_point(points[p])) return fb_geom_fail(poly,"Invalid hull point");
    int a=0,b=-1,c=-1,d=-1;float best=0;
    for(int p=1;p<count;p++) {
        vector delta=points[p]-points[a];float distance=delta*delta;
        if(distance>best) {best=distance;b=p;}
    }
    if(best<FB_GEOM_MERGE*FB_GEOM_MERGE) return fb_geom_fail(poly,"Coincident hull points");
    best=0;
    for(int p=0;p<count;p++) {
        vector cross=crossproduct(points[b]-points[a],points[p]-points[a]);float area=cross*cross;
        if(area>best) {best=area;c=p;}
    }
    if(best<0.00000001) return fb_geom_fail(poly,"Collinear hull points");
    vector normal=normalize(crossproduct(points[b]-points[a],points[c]-points[a]));
    best=0;
    for(int p=0;p<count;p++) {
        float distance=fabs(normal*(points[p]-points[a]));
        if(distance>best) {best=distance;d=p;}
    }
    if(best<FB_GEOM_PLANE) return fb_geom_fail(poly,"Coplanar hull points");
    vector inside=(points[a]+points[b]+points[c]+points[d])*0.25;
    int capacity=count*2+8,nt=4;
    fb_hull_tri_t *tris=memalloc(sizeof(fb_hull_tri_t)*capacity);
    fb_poly_edge_t *horizon=memalloc(sizeof(fb_poly_edge_t)*capacity*3);
    fb_hull_triangle(&tris[0],a,b,c,points,inside);fb_hull_triangle(&tris[1],a,d,b,points,inside);
    fb_hull_triangle(&tris[2],a,c,d,points,inside);fb_hull_triangle(&tris[3],b,d,c,points,inside);
    for(int p=0;p<count;p++) {
        int nh=0,kept=0;
        for(int t=0;t<nt;t++) {
            if(tris[t].normal*points[p]-tris[t].dist>FB_GEOM_PLANE) {
                for(int e=0;e<3;e++) {
                    int ea=tris[t].a,eb=tris[t].b;
                    if(e==1) {ea=tris[t].b;eb=tris[t].c;}
                    if(e==2) {ea=tris[t].c;eb=tris[t].a;}
                    int h;
                    for(h=0;h<nh;h++) if(horizon[h].a==eb && horizon[h].b==ea) break;
                    if(h<nh) horizon[h]=horizon[--nh];
                    else {horizon[nh].a=ea;horizon[nh++].b=eb;}
                }
            } else tris[kept++]=tris[t];
        }
        nt=kept;
        if(nt+nh>capacity) {memfree(tris);memfree(horizon);return fb_geom_fail(poly,"Hull triangle limit");}
        for(int h=0;h<nh;h++) fb_hull_triangle(&tris[nt++],horizon[h].a,horizon[h].b,p,points,inside);
    }
    static brushface_t faces[MAX_BRUSHFACES];
    int nf=0,ok=TRUE;
    for(int t=0;t<nt;t++) {
        brushface_t plane={0};plane.planenormal=tris[t].normal;plane.planedist=tris[t].dist;
        int f;
        for(f=0;f<nf;f++) if(fb_geom_sameplane(&faces[f],&plane)) break;
        if(f<nf) continue;
        if(nf==MAX_BRUSHFACES) {ok=FALSE;break;}
        plane.shadername=cvar_string("ca_newbrushtexture");reset_texturecoords(&plane);faces[nf++]=plane;
    }
    memfree(tris);memfree(horizon);
    if(!ok) return fb_geom_fail(poly,"Hull exceeds 64 faces");
    return fb_poly_from_faces(faces,nf,poly);
}
// Return both compact halves, or neither. Tangency and invalid input are no-ops.
int fb_split(brushface_t *source,int count,vector normal,float dist,fb_poly_t *front,fb_poly_t *back)
{
    fb_poly_free(front);fb_poly_free(back);
    fb_poly_t original={0};
    if(!fb_poly_from_faces(source,count,&original)) return FALSE;
    float length=vlen(normal);
    if(!fb_geom_finite(length) || length<0.000001 || !fb_geom_finite(dist)) {
        fb_poly_free(&original);fb_geom_error="Invalid split plane";return FALSE;
    }
    normal/=length;dist/=length;
    float lo=1000000000000000000000000000000.0,hi=-1000000000000000000000000000000.0;
    for(int v=0;v<original.nv;v++) {
        float side=original.vertices[v]*normal-dist;lo=min(lo,side);hi=max(hi,side);
    }
    fb_poly_free(&original);
    if(lo>=-FB_GEOM_PLANE || hi<=FB_GEOM_PLANE) {fb_geom_error="Split plane does not cross brush";return FALSE;}
    static brushface_t candidate[MAX_BRUSHFACES+1],compact[MAX_BRUSHFACES];
    static vector points[MAX_FACEPOINTS+1];
    for(int side=0;side<2;side++) {
        memcpy(candidate,source,sizeof(brushface_t)*count);
        brushface_t cut={0};cut.planenormal=normal;cut.planedist=dist;
        if(side==0) {cut.planenormal=-normal;cut.planedist=-dist;}
        cut.shadername=cvar_string("ca_newbrushtexture");reset_texturecoords(&cut);candidate[count]=cut;
        int n=0;
        for(int f=0;f<=count;f++) {
            int np=brush_calcfacepoints(f+1,candidate,count+1,points,points.length);
            if(np<3) continue;
            if(n==MAX_BRUSHFACES) {fb_poly_free(front);fb_poly_free(back);fb_geom_error="Split exceeds 64 faces";return FALSE;}
            compact[n++]=candidate[f];
        }
        fb_poly_t *output=back;if(side==0) output=front;
        if(!fb_poly_from_faces(compact,n,output)) {fb_poly_free(front);fb_poly_free(back);return FALSE;}
    }
    return TRUE;
}



