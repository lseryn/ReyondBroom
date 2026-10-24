// SPDX-License-Identifier: GPL-3.0-or-later
// Relinking changes metadata only. Geometry is matched before opening a transaction.
int fb_symmetry_match_work,fb_symmetry_match_scans;
int fb_symmetry_match_node(int a,int b,fb_affine_t *matrix,int *mapping,int depth)
{
    if(++fb_symmetry_match_work>20000||fb_symmetry_match_scans>1000000||depth>32||fb_nodes[a].kind!=fb_nodes[b].kind)return FALSE;
    fb_node_t source=fb_nodes[a],target=fb_nodes[b];int valid;int *used;
    if(source.kind==FB_NODE_BRUSH){
        fb_poly_t left={0},right={0};valid=fb_poly_from_brush(source.model,source.id,&left);
        if(valid)valid=fb_poly_from_brush(target.model,target.id,&right);
        if(valid)valid=left.nv==right.nv;
        used=memalloc(right.nv*sizeof(int));
        for(int i=0;i<left.nv&&valid;i++){
            vector point=fb_affine_point(matrix,left.vertices[i]);int found=-1;
            for(int j=0;j<right.nv;j++)if(!used[j]&&vlen(point-right.vertices[j])<.1){found=j;break;}
            if(found<0)valid=FALSE;else used[found]=TRUE;
        }
        memfree(used);fb_poly_free(&left);fb_poly_free(&right);return valid;
    }
    if(source.kind==FB_NODE_PATCH){
        patchinfo_t li,ri;int lc=patch_getcp(source.model,source.id,__NULL__,0,&li),rc=patch_getcp(target.model,target.id,__NULL__,0,&ri);
        if(lc!=rc||lc<1||lc>1024||li.cpwidth!=ri.cpwidth||li.cpheight!=ri.cpheight)return FALSE;
        patchvert_t *lp=memalloc(lc*sizeof(patchvert_t));patchvert_t *rp=memalloc(rc*sizeof(patchvert_t));patch_getcp(source.model,source.id,lp,lc,&li);patch_getcp(target.model,target.id,rp,rc,&ri);valid=TRUE;
        for(int i=0;i<lc;i++){int j=i;if(matrix->determinant<0){int row=i/li.cpwidth,col=i-row*li.cpwidth;j=row*li.cpwidth+li.cpwidth-1-col;}if(vlen(fb_affine_point(matrix,lp[i].xyz)-rp[j].xyz)>=.1)valid=FALSE;}
        memfree(lp);memfree(rp);return valid;
    }
    if(source.fields["_tb_linked_group_id"]!=""||target.fields["_tb_linked_group_id"]!="")return FALSE;
    if(source.kind==FB_NODE_ENTITY){
        string sourceClass=source.fields["classname"],targetClass=target.fields["classname"];if(sourceClass!=targetClass)return FALSE;
        string origin=source.fields["origin"],other=target.fields["origin"];
        if((origin=="")!=(other==""))return FALSE;
        if(origin!="")if(vlen(fb_affine_point(matrix,stov(origin))-stov(other))>=.1)return FALSE;
    }
    fb_symmetry_match_scans+=fb_node_count;
    int leftCount=0,rightCount=0;for(int n=2;n<fb_node_count;n++){if(fb_nodes[n].parent==a)leftCount++;if(fb_nodes[n].parent==b)rightCount++;}
    if(leftCount!=rightCount||leftCount>1024)return FALSE;
    used=memalloc(fb_node_count*sizeof(int));valid=TRUE;
    for(int n=2;n<fb_node_count&&valid;n++)if(fb_nodes[n].parent==a){
        fb_symmetry_match_scans+=fb_node_count;int found=-1;for(int peer=2;peer<fb_node_count;peer++)if(fb_nodes[peer].parent==b&&!used[peer])if(fb_symmetry_match_node(n,peer,matrix,mapping,depth+1)){found=peer;break;}
        if(found<0)valid=FALSE;else used[found]=TRUE;
    }
    memfree(used);if(valid)mapping[a]=b;return valid;
}
int fb_symmetry_relink(int sides,int rotateCopies)
{
    if(fb_node_count>8192)return FALSE;
    int root=-1,groups=0,parent=fb_selection_open_node();if(parent<0)parent=fb_organize_node(fb_active_layer);
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].parent==parent&&fb_selection_selected(n)){root=n;groups++;}
    if(groups!=1||root<2)return FALSE;
    if(fb_nodes[root].fields["_tb_linked_group_id"]!="")return FALSE;
    for(int n=2;n<fb_node_count;n++)if(fb_selection_leaf(n)&&fb_selection_selected(n)&&!fb_selection_descendant(n,root))return FALSE;
    vector bounds[2];if(!fb_container_bounds(root,bounds))return FALSE;
    vector center=(bounds[0]+bounds[1])*.5;
    if(cvar("ftebroom_symmetry_custom_center"))center=[cvar("ftebroom_symmetry_center_x"),cvar("ftebroom_symmetry_center_y"),cvar("ftebroom_symmetry_center_z")];
    if(!fb_geom_point(center))return FALSE;
    float angle=cvar("ftebroom_symmetry_angle")*M_PI/180;
    int peers[8];peers[0]=root;int *allMappings=memalloc(sides*fb_node_count*sizeof(int));int valid=TRUE;fb_symmetry_match_work=0;fb_symmetry_match_scans=0;
    for(int side=1;side<sides&&valid;side++){
        fb_affine_t matrix;fb_symmetry_matrix(center,angle,side,sides,rotateCopies,&matrix);
        vector expectedLow='1000000000 1000000000 1000000000',expectedHigh=-expectedLow;
        for(int corner=0;corner<8;corner++){vector point=[bounds[corner&1?1:0][0],bounds[corner&2?1:0][1],bounds[corner&4?1:0][2]];point=fb_affine_point(&matrix,point);for(int axis=0;axis<3;axis++){expectedLow[axis]=min(expectedLow[axis],point[axis]);expectedHigh[axis]=max(expectedHigh[axis],point[axis]);}}
        int found=-1,candidates=0;int *mapping=allMappings+side*fb_node_count;
        for(int n=2;n<fb_node_count;n++)if(n!=root&&fb_nodes[n].kind==FB_NODE_GROUP&&fb_nodes[n].parent==parent&&fb_nodes[n].fields["_tb_linked_group_id"]==""){
            int claimed=FALSE;for(int previous=0;previous<side;previous++)if(peers[previous]==n)claimed=TRUE;if(claimed)continue;
            vector actual[2];if(!fb_container_bounds(n,actual))continue;
            if(vlen(actual[0]-expectedLow)>=.1||vlen(actual[1]-expectedHigh)>=.1)continue;
            if(++candidates>16)break;
            memfill8((__variant*)mapping,0,fb_node_count*sizeof(int));
            if(fb_symmetry_match_node(root,n,&matrix,mapping,0)){found=n;break;}
            if(fb_symmetry_match_work>20000)break;
        }
        if(found<0)valid=FALSE;else peers[side]=found;
    }
    if(valid){
        string link=strzone(fb_linked_uuid());fb_tx_begin("Relink symmetry");fb_linked_busy=TRUE;
        for(int side=0;side<sides;side++){
            fb_affine_t matrix;if(side)fb_symmetry_matrix(center,angle,side,sides,rotateCopies,&matrix);else fb_linked_matrix("",&matrix);
            int id=fb_nodes[peers[side]].id;
            fb_tx_set_key(id,"_tb_linked_group_id",link,HIST_TREE);fb_tx_set_key(id,"_tb_transformation",fb_linked_matrix_text(&matrix),HIST_TREE);
            fb_tx_set_key(id,"_ftebroom_symmetry",sprintf("%g %g",(float)sides,(float)rotateCopies),HIST_TREE);
            fb_tx_set_key(id,"_ftebroom_symmetry_center",vtos(center),HIST_TREE);fb_tx_set_key(id,"_ftebroom_symmetry_angle",ftos(angle),HIST_TREE);
        }
        for(int n=2;n<fb_node_count;n++)if(n!=root&&fb_nodes[n].kind<FB_NODE_BRUSH&&fb_selection_descendant(n,root)){
            string member=strzone(fb_linked_uuid());fb_tx_set_key(fb_nodes[n].id,"_ftebroom_link_member",member,HIST_TREE);
            for(int side=1;side<sides;side++){int peer=allMappings[side*fb_node_count+n];if(peer>=2)fb_tx_set_key(fb_nodes[peer].id,"_ftebroom_link_member",member,HIST_TREE);}strunzone(member);
        }
        fb_tx_commit();fb_linked_busy=FALSE;strunzone(link);fb_document_tick();cvar_set("ftebroom_selection_status","Existing symmetry groups linked without replacing geometry.");
    }
    memfree(allMappings);return valid;
}
