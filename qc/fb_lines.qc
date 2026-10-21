// SPDX-License-Identifier: GPL-2.0-or-later
typedef struct {int line,model,id,entity,mixed;} fb_line_t;
fb_line_t *fb_lines;
int fb_line_count;
void fb_lines_copy(int model,int oldid,int newid)
{
    if(!newid || oldid==newid) return;
    int count=fb_line_count;
    for(int i=0;i<count;i++) if(fb_lines[i].model==model && fb_lines[i].id==oldid) {
        fb_line_t *expanded=memalloc(sizeof(fb_line_t)*(fb_line_count+1));
        memcpy(expanded,fb_lines,sizeof(fb_line_t)*fb_line_count);
        expanded[fb_line_count]=fb_lines[i];expanded[fb_line_count++].id=newid;
        memfree(fb_lines);fb_lines=expanded;
    }
}
void fb_lines_remap(int model,int oldid,int newid)
{
    for(int i=0;i<fb_line_count;i++) if(fb_lines[i].model==model && fb_lines[i].id==oldid) {fb_lines[i].id=newid;fb_lines[i].mixed=FALSE;}
}
void fb_lines_index()
{
    fb_document_tick();memfree(fb_lines);fb_line_count=0;
    fb_lines=memalloc(sizeof(fb_line_t)*fb_node_count);
    filestream file=fopen("map-lines.txt",FILE_READ);
    if((float)file<0) return;
    string row;int entityCount=terrain_edit(TEREDIT_ENT_COUNT);
    while((row=fgets(file))) {
        int words=tokenize(row);
        if(words==2 && argv(0)=="mixed") {int mixedLine=stoi(argv(1));for(int m=0;m<fb_line_count;m++)if(fb_lines[m].line==mixedLine)fb_lines[m].mixed=TRUE;continue;}
        if(words!=3) continue;
        int line=stoi(argv(0)),entityOrdinal=stoi(argv(1)),brushOrdinal=stoi(argv(2));
        int ordinal=0,entityIndex=-1;
        for(int e=0;e<entityCount;e++) {
            string fields=terrain_edit(TEREDIT_ENT_GET,e);
            if(fields=="") continue;
            if(ordinal++==entityOrdinal) {entityIndex=e;break;}
        }
        int parent=-1;
        if(entityIndex==0) parent=1;
        else for(int n=2;n<fb_node_count;n++) if(fb_nodes[n].kind<FB_NODE_BRUSH && fb_nodes[n].id==entityIndex) {parent=n;break;}
        if(parent<0 || fb_line_count>=fb_node_count) continue;
        fb_line_t item={0};item.line=line;item.entity=entityIndex;
        if(brushOrdinal>=0) {
            int brush=0,found=FALSE;
            for(int n=0;n<fb_node_count;n++) if(fb_nodes[n].kind>=FB_NODE_BRUSH && fb_nodes[n].parent==parent) {
                if(brush++==brushOrdinal) {item.model=fb_nodes[n].model;item.id=fb_nodes[n].id;found=TRUE;break;}
            }
            if(!found) continue;
        }
        fb_lines[fb_line_count++]=item;
    }
    fclose(file);
    if(cvar("ftebroom_debug_lines")) print(sprintf("FTEBROOM_LINE_INDEX %i\n",fb_line_count));
}
void fb_select_line(int line)
{
    fb_tool_refresh();fb_document_tick();
    for(int i=0;i<fb_line_count;i++) if(fb_lines[i].line==line) {
        for(int n=0;n<fb_node_count;n++) {
            int match=FALSE;
            if(fb_lines[i].model) match=fb_nodes[n].kind>=FB_NODE_BRUSH && fb_nodes[n].model==fb_lines[i].model && fb_nodes[n].id==fb_lines[i].id;
            else match=fb_nodes[n].kind<FB_NODE_BRUSH && fb_nodes[n].kind!=FB_NODE_WORLD && fb_nodes[n].id==fb_lines[i].entity;
            if(match && fb_select_in_scope(n)) {
                fb_selection_click(fb_selection_target(n),FALSE);
                cvar_set("ftebroom_selection_status","");return;
            }
        }
    }
    cvar_set("ftebroom_selection_status","No selectable object starts on this MAP line.");
}
