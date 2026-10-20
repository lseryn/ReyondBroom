// SPDX-License-Identifier: GPL-2.0-or-later
void fb_geom_expect(int condition,string name)
{
    print(strcat(condition?"FTEBROOM_GEOM_PASS ":"FTEBROOM_GEOM_FAIL ",name,"\n"));
    if(!condition) print(strcat("Geometry detail: ",fb_geom_error,"\n"));
}
void fb_geom_testbox(brushface_t *faces,float size)
{
    static vector normals[6]={'-1 0 0','0 -1 0','0 0 -1','1 0 0','0 1 0','0 0 1'};
    for(int f=0;f<6;f++) {
        brushface_t face={0};face.planenormal=normals[f];face.planedist=size;
        face.shadername="ftebroom/grid";reset_texturecoords(&face);
        face.sdir*=0.5;face.tdir*=0.25;face.sbias=17;face.tbias=-9;faces[f]=face;
    }
}
float fb_geom_testcommand()
{
    if(argv(0)=="ftebroom_test_manual") {
        if(!cvar("ftebroom_skip_setup")) return TRUE;
        string mode=argv(1);vector target='0 0 96';
        if(mode=="patch") target='24 24 88';
        if(mode=="entity") target='180 -80 48';
        if(mode=="clip") target='0 0 64';
        vector pixel=project(target);pixel_z=0;
        fb_begin(pixel,0,cvar("ca_brush_view"));fb_finish(pixel,0,cvar("ca_brush_view"));
        int expected=FALSE;
        if(mode=="entity") expected=fb_selected_entity()==1;
        else if(selectedbrushcount==1) {
            int model=selectedbrushes[0].model,id=selectedbrushes[0].id;
            if(mode=="patch") expected=patch_getcp(model,id,__NULL__,0,__NULL__)>0;
            else {
                static brushface_t picked[64];
                brush_get(model,id,picked,64,__NULL__);
                string material="ftebroom/qa_blue";
                if(mode=="perspective") material="ftebroom/qa_red";
                expected=picked[0].shadername==material;
            }
        }
        print(strcat(expected?"FTEBROOM_MANUAL_PASS ":"FTEBROOM_MANUAL_FAIL ",mode,"\n"));
        if(mode=="clip") {
            cvar_set("ftebroom_tool","2");cvar_set("ftebroom_clip_keep","1");
            fb_clip_points[0]='0 -64 64';fb_clip_points[1]='0 64 64';fb_clip_count=2;
        }
        return TRUE;
    }
    if(argv(0)!="ftebroom_selftest") return FALSE;
    // Tests allocate geometry only. They never change the document or selection.
    static brushface_t faces[64],result[64],bad[65];
    fb_geom_testbox(faces,16);
    fb_poly_t poly={0},hull={0},front={0},back={0};
    int ok=fb_poly_from_faces(faces,6,&poly);
    fb_geom_expect(ok && poly.nv==8 && poly.ne==12 && poly.nf==6,"cube_topology");
    fb_geom_expect(ok && fabs(poly.volume-32768)<0.1,"cube_volume");
    int n=fb_poly_to_faces(&poly,faces,6,result,64),same=n==6;
    if(same) for(int f=0;f<6;f++) {
        if(result[f].planenormal!=faces[f].planenormal || result[f].planedist!=faces[f].planedist) same=FALSE;
        if(result[f].shadername!=faces[f].shadername || result[f].sdir!=faces[f].sdir || result[f].tdir!=faces[f].tdir ||
           result[f].sbias!=faces[f].sbias || result[f].tbias!=faces[f].tbias) same=FALSE;
    }
    fb_geom_expect(same,"cube_plane_and_uv_roundtrip");
    static vector points[130];
    for(int i=0;i<8;i++) points[i]=poly.vertices[i];
    points[8]='0 0 0';points[9]=points[0];
    ok=fb_hull(points,10,&hull);
    fb_geom_expect(ok && hull.nv==8 && hull.ne==12 && hull.nf==6 && fabs(hull.volume-32768)<0.1,"hull_cube_interior_duplicate");
    for(int i=0;i<10;i++) points[i]=points[i]*0.5+'0.25 0.125 0.5';
    ok=fb_hull(points,10,&hull);
    fb_geom_expect(ok && hull.nf==6 && fabs(hull.volume-4096)<0.1,"hull_fractional_coordinates");
    // Rotate and permute a cube; every generated plane must contain all input points.
    for(int i=0;i<8;i++) {
        vector p=poly.vertices[7-i];
        points[i]=[p_x*0.8-p_y*0.6,p_x*0.6+p_y*0.8,p_z]+'120 -40 20';
    }
    ok=fb_hull(points,8,&hull);int enclosed=ok;
    if(ok) for(int f=0;f<hull.nf;f++) for(int i=0;i<8;i++)
        if(points[i]*hull.faces[f].attr.planenormal-hull.faces[f].attr.planedist>0.001) enclosed=FALSE;
    fb_geom_expect(enclosed && hull.nf==6 && fabs(hull.volume-32768)<0.5,"rotated_permuted_hull");
    ok=fb_split(faces,6,'1 0 0',0,&front,&back);
    fb_geom_expect(ok && front.nf==6 && back.nf==6 && fabs(front.volume-16384)<0.1 && fabs(back.volume-16384)<0.1,"split_equal_volumes");
    int preserved=0,cuts=0;
    if(ok) for(int f=0;f<front.nf;f++) {
        brushface_t face=front.faces[f].attr;
        if(fabs(face.planedist)<0.001) {
            if(face.shadername==cvar_string("ca_newbrushtexture") && vlen(face.sdir)==1 && vlen(face.tdir)==1) cuts++;
        } else if(face.sbias==17 && face.tbias==-9 && vlen(face.sdir)==0.5 && vlen(face.tdir)==0.25) preserved++;
    }
    fb_geom_expect(preserved==5 && cuts==1,"split_preserves_uv_and_initializes_cut");
    ok=fb_split(faces,6,normalize('1 1 1'),0,&front,&back);
    fb_geom_expect(ok && fabs(front.volume+back.volume-32768)<1,"oblique_split_conserves_volume");
    fb_geom_expect(!fb_split(faces,6,'1 0 0',16,&front,&back) && !front.nf && !back.nf,"tangent_noop");
    fb_geom_expect(!fb_split(faces,6,'1 0 0',30,&front,&back),"outside_noop");
    fb_geom_expect(!fb_split(faces,6,'0 0 0',0,&front,&back),"zero_split_normal");
    memcpy(bad,faces,sizeof(brushface_t)*6);bad[0].planedist=-16;
    fb_geom_expect(!fb_brush_valid(bad,6),"reject_flat");
    memcpy(bad,faces,sizeof(brushface_t)*6);bad[6]=bad[0];
    fb_geom_expect(!fb_brush_valid(bad,7),"reject_duplicate_plane");
    fb_geom_expect(!fb_brush_valid(faces,5),"reject_unbounded");
    fb_geom_expect(!fb_brush_valid(faces,65),"reject_face_limit");
    fb_geom_testbox(bad,0.1);fb_geom_expect(!fb_brush_valid(bad,6),"reject_tiny_volume");
    fb_geom_testbox(bad,16);bad[0].planenormal='0 0 0';fb_geom_expect(!fb_brush_valid(bad,6),"reject_zero_normal");
    fb_geom_testbox(bad,70000);fb_geom_expect(!fb_brush_valid(bad,6),"reject_world_bounds");
    for(int i=0;i<4;i++) points[i]=[i,i,0];
    fb_geom_expect(!fb_hull(points,4,&hull),"reject_collinear_hull");
    points[0]='0 0 0';points[1]='16 0 0';points[2]='16 16 0';points[3]='0 16 0';
    fb_geom_expect(!fb_hull(points,4,&hull),"reject_flat_hull");
    points[3]='0 0 16';
    ok=fb_hull(points,4,&hull);
    fb_geom_expect(ok && hull.nf==4 && hull.nv==4 && fabs(hull.volume-4096.0/6)<0.1,"tetrahedron_hull");
    // A prism has 62 side planes plus two caps: exercise the full brush limit.
    for(int f=0;f<62;f++) {
        float angle=2*M_PI*f/62;
        brushface_t face={0};face.planenormal=[cos(angle),sin(angle),0];face.planedist=128;
        face.shadername="ftebroom/grid";reset_texturecoords(&face);faces[f]=face;
    }
    faces[62]=faces[0];faces[62].planenormal='0 0 1';faces[62].planedist=32;
    faces[63]=faces[62];faces[63].planenormal='0 0 -1';
    ok=fb_poly_from_faces(faces,64,&poly);
    fb_geom_expect(ok && poly.nf==64 && poly.nv==124 && poly.ne==186,"full_64_face_prism");
    ok=fb_split(faces,64,'1 0 0',0,&front,&back);
    fb_geom_expect(ok && fabs(front.volume+back.volume-poly.volume)<2,"split_64_face_prism");
    // Read a real document brush through the public conversion entry point.
    fb_document_tick();
    int found=FALSE;
    for(int node=0;node<fb_node_count;node++) if(fb_nodes[node].kind==FB_NODE_BRUSH) {
        found=fb_poly_from_brush(fb_nodes[node].model,fb_nodes[node].id,&hull);break;
    }
    fb_geom_expect(found,"document_brush_conversion");
    float begin=gettime(1);
    int validCount=0;
    for(int iteration=0;iteration<10;iteration++) if(fb_brush_valid(faces,64)) validCount++;
    print(sprintf("FTEBROOM_GEOM_BENCH prism64_ms_per_op=%g valid=%i\n",(gettime(1)-begin)*100,validCount));
    fb_geom_testbox(faces,16);begin=gettime(1);validCount=0;
    for(int iteration=0;iteration<500;iteration++) if(fb_brush_valid(faces,6)) validCount++;
    print(sprintf("FTEBROOM_GEOM_BENCH boxes500_ms=%g valid=%i\n",(gettime(1)-begin)*1000,validCount));
    fb_geom_expect(validCount==500,"batch_500_boxes");
    fb_poly_free(&poly);fb_poly_free(&hull);fb_poly_free(&front);fb_poly_free(&back);
    print("FTEBROOM_GEOM_COMPLETE\n");
    return TRUE;
}


