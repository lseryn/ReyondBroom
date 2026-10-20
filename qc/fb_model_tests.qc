// SPDX-License-Identifier: GPL-2.0-or-later
int fb_model_test_entity;
float fb_model_testcommand()
{
    if(argv(0)!="ftebroom_test_model" || !cvar("ftebroom_skip_setup")) return FALSE;
    if(argv(1)=="create") {
        string name=strzone(brush_model_create());
        fb_transform_expect(name!="","new_submodel_name");
        precache_model(name);
        if(!fb_document_probe) fb_document_probe=spawn();
        setmodel(fb_document_probe,name);
        int model=fb_document_probe.modelindex;
        fb_transform_expect(model!=0,"new_submodel_precache");
        fb_tx_begin("Brush entity");
        fb_model_test_entity=terrain_edit(TEREDIT_ENT_ADD,"");
        fb_tx_entity_set(fb_model_test_entity,strcat("\"classname\" \"func_group\"\n\"model\" \"",name,"\"\n"),HIST_ENTITY);
        static brushface_t faces[6];fb_geom_testbox(faces,32);
        int id=brush_history_create(model,faces,6,CONTENTBIT_SOLID,TRUE);
        fb_tx_commit();strunzone(name);
        fb_transform_expect(id!=0 && brush_get(model,id,__NULL__,0,__NULL__)==6,"new_submodel_geometry");
    } else if(argv(1)=="undo") {
        brush_undo();
        string data=terrain_edit(TEREDIT_ENT_GET,fb_model_test_entity);
        fb_transform_expect(data=="","new_submodel_undo_entity");
    } else if(argv(1)=="redo") {
        brush_redo();fb_document_tick();
        int count=0;
        for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].kind==FB_NODE_BRUSH && fb_nodes[n].model!=1) count++;
        fb_transform_expect(count==1,"new_submodel_redo_geometry");
    }
    return TRUE;
}
