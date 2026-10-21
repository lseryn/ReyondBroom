// SPDX-License-Identifier: GPL-2.0-or-later
void fb_primitive_expect(int ok,string label) {print(strcat(ok?"FTEBROOM_PRIMITIVE_PASS ":"FTEBROOM_PRIMITIVE_FAIL ",label,"\n"));if(!ok) print(strcat(fb_geom_error,"\n"));}
float fb_primitive_volume() {float volume=0;for(int b=0;b<fb_csg_count;b++) volume+=fb_csg_results[b].poly.volume;return volume;}
float fb_primitive_testcommand()
{
    if(argv(0)!="ftebroom_test_primitives" || !cvar("ftebroom_skip_setup")) return FALSE;
    cvar_set("ftebroom_shape_axis","2");cvar_set("ftebroom_shape_sides","8");cvar_set("ftebroom_shape_circle","edge");
    cvar_set("ftebroom_shape_hollow","0");cvar_set("ftebroom_shape_thickness","16");
    int ok=fb_primitive_build("cuboid",'0 0 0','128 128 128');fb_primitive_expect(ok && fb_csg_count==1 && fabs(fb_primitive_volume()-128*128*128)<2,"cuboid_volume");
    ok=fb_primitive_build("cylinder",'0 0 0','128 128 128');float outer=fb_primitive_volume();fb_primitive_expect(ok && fb_csg_results[0].poly.nf==10,"cylinder_eight_sides");
    cvar_set("ftebroom_shape_hollow","1");ok=fb_primitive_build("cylinder",'0 0 0','128 128 128');
    fb_primitive_expect(ok && fb_csg_count==8 && fb_primitive_volume()<outer,"hollow_cylinder_eight_walls");
    cvar_set("ftebroom_shape_thickness","80");ok=fb_primitive_build("cylinder",'0 0 0','128 128 128');fb_primitive_expect(!ok,"reject_excessive_thickness");
    cvar_set("ftebroom_shape_thickness","16");cvar_set("ftebroom_shape_hollow","0");
    ok=fb_primitive_build("cone",'0 0 0','128 128 128');fb_primitive_expect(ok && fabs(fb_primitive_volume()*3-outer)<3,"cone_volume");
    cvar_set("ftebroom_shape_rings","6");ok=fb_primitive_build("uvsphere",'0 0 0','128 128 128');fb_primitive_expect(ok && fb_csg_results[0].poly.nf==48,"uv_sphere_48_faces");
    cvar_set("ftebroom_shape_rings","9");ok=fb_primitive_build("uvsphere",'0 0 0','128 128 128');fb_primitive_expect(!ok,"sphere_face_limit");
    cvar_set("ftebroom_shape_accuracy","0");ok=fb_primitive_build("icosphere",'0 0 0','128 128 128');fb_primitive_expect(ok && fb_csg_results[0].poly.nf==20,"icosahedron_20_faces");
    cvar_set("ftebroom_shape_accuracy","1");ok=fb_primitive_build("icosphere",'0 0 0','128 128 128');fb_primitive_expect(!ok,"icosahedron_face_limit");
    cvar_set("ftebroom_shape_step","16");cvar_set("ftebroom_shape_stairdir","0");ok=fb_primitive_build("stairs",'0 0 0','128 64 64');
    fb_primitive_expect(ok && fb_csg_count==4 && fabs(fb_primitive_volume()-32*64*(16+32+48+64))<2,"four_stairs_volume");
    cvar_set("ftebroom_shape_circle","scalable");cvar_set("ftebroom_shape_sides","12");fb_primitive_circle(64,64);int grid=TRUE;
    for(int p=0;p<fb_primitive_sides;p++) for(int a=0;a<2;a++) if(fabs(fb_primitive_outer[p][a]/8-rint(fb_primitive_outer[p][a]/8))>0.0001) grid=FALSE;
    fb_primitive_expect(grid && fb_primitive_sides==12,"scalable_circle_grid");
    cvar_set("ftebroom_shape_circle","edge");cvar_set("ftebroom_shape_sides","8");cvar_set("ftebroom_shape_axis","1");cvar_set("ftebroom_shape_spandrel","0");
    ok=fb_primitive_build("arch",'0 0 0','128 64 128');float arch=fb_primitive_volume();fb_primitive_expect(ok && fb_csg_count>0,"arch_valid");
    cvar_set("ftebroom_shape_spandrel","1");ok=fb_primitive_build("arch",'0 0 0','128 64 128');fb_primitive_expect(ok && fb_primitive_volume()>arch,"arch_spandrels_fill_corners");fb_csg_clear();
    fb_selection_clear();fb_createbox('0 0 64','128 128 128');int marker=history;
    cvar_set("ftebroom_shape","stairs");fb_primitive_apply();fb_primitive_expect(selectedbrushcount==8,"replace_selection_with_shape");
    brush_undo();fb_primitive_expect(history==marker && selectedbrushcount==1,"shape_single_undo");
    cvar_set("ftebroom_shape","cuboid");cvar_set("ftebroom_shape_axis","2");cvar_set("ftebroom_shape_rings","8");cvar_set("ftebroom_shape_accuracy","0");
    cvar_set("ftebroom_shape_circle","vertex");fb_primitive_circle(128,256);fb_primitive_inset(16,128,256,FALSE);
    vector inner=fb_primitive_inner[0];fb_primitive_circle(96,224);
    fb_primitive_expect(vlen(inner-fb_primitive_outer[0]-'16 16 0')<0.0001,"inner_circle_uses_inset_box");
    cvar_set("ftebroom_shape_circle","edge");
    return TRUE;
}
