// Copyright (C) 2026 TrenchBroom contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Seeded ellipsoid sampling and radial shells adapted from UltimateTrenchBroom.
float fb_rock_hash(int x,int y,int z,int seed,int salt)
{
    int h=seed^salt;h^=x+0x9e3779b9i+(h<<6)+((h>>2)&0x3fffffffi);h^=y+0x85ebca6bi+(h<<6)+((h>>2)&0x3fffffffi);h^=z+0xc2b2ae35i+(h<<6)+((h>>2)&0x3fffffffi);
    h^=(h>>16)&0xffffi;h*=0x7feb352di;h^=(h>>15)&0x1ffffi;h*=0x846ca68bi;h^=(h>>16)&0xffffi;return (float)(h&0xffffffi)/16777216;
}
int fb_rock_piece(vector *points,int count,brushface_t *attrs,int nf,int model,int contents)
{
    fb_poly_t part={0};int valid=fb_hull(points,count,&part);
    if(valid){fb_land_attributes(&part,attrs,nf);valid=fb_csg_append(&part,model,contents);}fb_poly_free(&part);return valid;
}
int fb_rock_apply()
{
    int total=selectedbrushcount,segments=bound(4,cvar("ftebroom_rock_segments"),48),rings=bound(2,segments/2,24),seed=cvar("ftebroom_rock_seed"),hollow=cvar("ftebroom_rock_hollow");
    if(total<1||total>16||total*(segments*rings+2)>4096){fb_geom_error="Select 1..16 brushes; reduce detail when the total exceeds 4096 samples.";return FALSE;}
    float thickness=cvar("ftebroom_rock_thickness");if(hollow&&thickness<=0){fb_geom_error="Shell thickness must be positive.";return FALSE;}
    if(cvar("ftebroom_rock_group")&&cvar("ftebroom_tool")!=FB_TOOL_NONE){fb_geom_error="Exit the active modal tool before creating a rock group.";return FALSE;}
    selbrush_t *sources=memalloc(total*sizeof(selbrush_t));memcpy(sources,selectedbrushes,total*sizeof(selbrush_t));fb_csg_clear();fb_csg_results=memalloc(2048*sizeof(fb_csg_item_t));int valid=TRUE;
    for(int b=0;b<total&&valid;b++) {
        int begin=fb_csg_count,model=sources[b].model,id=sources[b].id,contents;static brushface_t attrs[64];int nf=brush_get(model,id,attrs,64,&contents);vector bounds[2];
        if(nf<4||nf>64||brush_getfacepoints(model,id,0,bounds,2)!=2){valid=FALSE;fb_geom_error="Rock requires convex source brushes.";break;}
        for(int f=0;f<nf;f++)attrs[f].shadername=strzone(attrs[f].shadername);
        vector center=(bounds[0]+bounds[1])*.5,radius=(bounds[1]-bounds[0])*.5;for(int a=0;a<3;a++)radius[a]=max(.5,radius[a]);
        int localSeed=seed+b*7919,count=segments*rings+2;vector *points=memalloc(count*sizeof(vector));
        points[0]=center+[0,0,radius_z*(.82+.18*fb_rock_hash(0,0,b,localSeed,0xf00di))];
        for(int ring=1;ring<=rings;ring++) {
            float theta=(float)ring/(rings+1)*M_PI,twist=(fb_rock_hash(ring,0,b,localSeed,0xabc123i)-.5)*M_PI/segments;
            for(int side=0;side<segments;side++) {
                float angle=(float)side/segments*2*M_PI+twist;
                float coarse=fb_rock_hash(ring/2,side/2,b,localSeed,0x6c8e9cf5i),fine=fb_rock_hash(ring,side,b,localSeed,0x4b1d5a3bi),chip=fb_rock_hash(ring*5,side*7,b,localSeed,0x91e10da5i);
                float factor=bound(.55,.64+.25*coarse+.17*fine-.10*chip,1.05);
                points[1+(ring-1)*segments+side]=center+[cos(angle)*sin(theta)*factor*radius_x,sin(angle)*sin(theta)*factor*radius_y,cos(theta)*factor*radius_z];
            }
        }
        points[count-1]=center-[0,0,radius_z*(.82+.18*fb_rock_hash(0,1,b,localSeed,0xbeefi))];
        if(hollow) {
            float minimum=1000000;for(int p=0;p<count;p++)minimum=min(minimum,vlen(points[p]-center));float wall=bound(.001,thickness,minimum*.8);
            for(int ring=0;ring<=rings&&valid;ring++)for(int side=0;side<segments&&valid;side++) {
                int next=side+1;if(next==segments)next=0;int indices[4],corners=4;
                if(!ring){corners=3;indices[0]=0;indices[1]=1+side;indices[2]=1+next;}
                else if(ring==rings){corners=3;indices[0]=count-1;indices[1]=1+(rings-1)*segments+next;indices[2]=1+(rings-1)*segments+side;}
                else {indices[0]=1+(ring-1)*segments+side;indices[1]=1+(ring-1)*segments+next;indices[2]=1+ring*segments+next;indices[3]=1+ring*segments+side;}
                vector shell[8];for(int i=0;i<corners;i++){shell[i]=points[indices[i]];vector delta=shell[i]-center;shell[corners+i]=center+delta*max(.05,(vlen(delta)-wall)/vlen(delta));}
                valid=fb_rock_piece(shell,corners*2,attrs,nf,model,contents);
            }
        }else {
            fb_hull_mesh_t mesh={0};fb_poly_t unused={0};valid=fb_hull_compute(points,count,&unused,&mesh);
            int single=FALSE;if(valid&&mesh.count<=64)single=fb_rock_piece(points,count,attrs,nf,model,contents);
            if(valid&&!single){
                // A triangulated convex hull becomes non-overlapping tetrahedra when
                // it exceeds the engine's per-brush plane limit. Never drop faces.
                for(int t=0;t<mesh.count&&valid;t++){vector tetra[4];tetra[0]=center;tetra[1]=points[mesh.triangles[t].a];tetra[2]=points[mesh.triangles[t].b];tetra[3]=points[mesh.triangles[t].c];valid=fb_rock_piece(tetra,4,attrs,nf,model,contents);}
            }memfree(mesh.triangles);fb_poly_free(&unused);
        }memfree(points);for(int f=0;f<nf;f++)strunzone(attrs[f].shadername);
        for(int i=begin;i<fb_csg_count;i++)fb_csg_results[i].id=b;
    }
    if(valid){
        brush_deselectall();
        for(int b=0;b<total&&valid;b++){
            int destination=sources[b].model;
            if(cvar("ftebroom_rock_group")){
                fb_document_tick();int parent=-1;
                for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_BRUSH&&fb_nodes[n].model==sources[b].model&&fb_nodes[n].id==sources[b].id){parent=fb_nodes[n].parent;break;}
                if(parent<0){valid=FALSE;break;}
                if(fb_nodes[parent].kind==FB_NODE_ENTITY){valid=FALSE;fb_geom_error="Disable rock grouping for brushes inside a gameplay entity; grouping must not discard entity behavior.";break;}
                int group=fb_organize_new("group","Rock",parent);fb_document_rebuild();destination=fb_organize_model(group);if(!destination){valid=FALSE;break;}
            }
            // Keep group allocation and population together for each source brush.
            for(int i=0;i<fb_csg_count&&valid;i++)if(fb_csg_results[i].id==b){fb_csg_item_t *item=&fb_csg_results[i];static brushface_t faces[64];for(int f=0;f<item->poly.nf;f++)faces[f]=item->poly.faces[f].attr;valid=brush_history_create(destination,faces,item->poly.nf,item->contents,TRUE)!=0;}
        }
        if(valid){for(int b=0;b<total;b++)brush_history_delete(sources[b].model,sources[b].id);fb_document_tick();}
    }
    fb_csg_clear();memfree(sources);return valid;
}
