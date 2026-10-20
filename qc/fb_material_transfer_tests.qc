// SPDX-License-Identifier: GPL-2.0-or-later
float fb_transfer_testcommand()
{
    if(argv(0)!="ftebroom_test_transfer" || !cvar("ftebroom_skip_setup")) return FALSE;
    brushface_t source={0},target={0};source.planenormal='0 0 1';source.planedist=0;
    source.sdir='2 0 0';source.tdir='0 -0.5 0';source.sbias=13;source.tbias=7;source.shadername="ftebroom/qa_red";source.surfaceflags=42;
    target.planenormal='0 1 0';target.planedist=0;target.sdir='1 0 0';target.tdir='0 0 -1';target.surfaceflags=123;
    brushface_t original=target;fb_transfer_attributes(&source,&target,1);
    vector edge='32 0 0';
    fb_transform_expect(fabs(source.sdir*edge+source.sbias-target.sdir*edge-target.sbias)<0.0001 && fabs(source.tdir*edge+source.tbias-target.tdir*edge-target.tbias)<0.0001,"rotated_transfer_continuous_at_edge");
    fb_transform_expect(target.planenormal==original.planenormal && target.planedist==original.planedist && fabs(vlen(target.sdir)-2)<0.0001 && fabs(vlen(target.tdir)-0.5)<0.0001,"transfer_preserves_plane_scale");
    target=original;fb_transfer_attributes(&source,&target,2);
    fb_transform_expect(target.shadername==source.shadername && target.sdir==original.sdir && target.surfaceflags==123,"material_only_preserves_target_attributes");
    target=original;fb_transfer_attributes(&source,&target,0);
    fb_transform_expect(target.sdir==source.sdir && target.sbias==source.sbias && target.surfaceflags==42,"projection_copies_face_attributes");
    cvar_set("ca_newbrushtexture","ftebroom/qa_red");int first=fb_createbox('0 0 128','64 64 64');
    cvar_set("ca_newbrushtexture","ftebroom/qa_blue");int second=fb_createbox('128 0 128','64 64 64');
    fb_faces_click(1,first,3,0);
    setproperty(VF_ORIGIN,'0 0 512');setproperty(VF_ANGLES,'90 0 0');setproperty(VF_PERSPECTIVE,TRUE);setproperty(VF_AFOV,90);
    vector pixel=project('128 0 160');pixel_z=0;
    int marker=history;
    fb_transform_expect(fb_transfer_begin(pixel,TRUE,FALSE),"transfer_begin_picks_destination");
    fb_transfer_finish(FALSE);
    fb_transform_expect(history==marker && fb_faces_count()==1,"transfer_cancel_preserves_selection_history");
    fb_transform_expect(fb_transfer_begin(pixel,TRUE,FALSE),"transfer_begin_after_cancel");fb_transfer_finish(TRUE);
    fb_transform_expect(fb_faces_count()==1 && history>marker,"transfer_commit_retains_source_selection");
    brush_undo();fb_transform_expect(history==marker,"transfer_single_undo");
    return TRUE;
}
