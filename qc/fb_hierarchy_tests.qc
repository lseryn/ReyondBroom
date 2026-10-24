// SPDX-License-Identifier: GPL-2.0-or-later
float fb_hierarchy_testcommand()
{
    if(argv(0)!="ftebroom_test_hierarchy" || !cvar("ftebroom_skip_setup"))return FALSE;
    fb_document_clear();
    fb_document_add(FB_NODE_WORLD,1,0,-1,"World");fb_document_add(FB_NODE_LAYER,0,-1,0,"Default Layer");
    int layer=fb_document_add(FB_NODE_LAYER,0,2,0,"Stress layer");fb_nodes[layer].tbid=strzone("2");
    // Reverse references force the former nested search to scan the entire document.
    for(int i=3;i<56603;i++) {
        int n=fb_document_add(FB_NODE_GROUP,0,i,1,"Stress group");
        fb_nodes[n].tbid=strzone(itos(i));fb_nodes[n].parentref=strzone(itos(i==56602?2:i+1));
    }
    fb_document_resolve();int valid=TRUE;
    for(int i=3;i<56603;i++)if(fb_nodes[i].layer!=layer || fb_nodes[i].parent!=(i==56602?2:i+1))valid=FALSE;
    print(valid?"FTEBROOM_HIERARCHY_PASS large_reverse_chain\n":"FTEBROOM_HIERARCHY_FAIL large_reverse_chain\n");
    strunzone(fb_nodes[56602].parentref);fb_nodes[56602].parentref=strzone("3");
    fb_document_resolve();
    valid=(fb_nodes[3].layer==1 && fb_nodes[56602].layer==1);
    print(valid?"FTEBROOM_HIERARCHY_PASS cycle_recovered\n":"FTEBROOM_HIERARCHY_FAIL cycle_recovered\n");
    fb_document_rebuild();return TRUE;
}
