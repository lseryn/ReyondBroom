// SPDX-License-Identifier: GPL-2.0-or-later
vector *fb_trace_points;
vector *fb_trace_portals;
int *fb_trace_sizes;
int fb_trace_count,fb_trace_portal_count,fb_trace_index;
void fb_trace_unload(int portals)
{
    if(portals){memfree(fb_trace_portals);memfree(fb_trace_sizes);fb_trace_portals=__NULL__;fb_trace_sizes=__NULL__;fb_trace_portal_count=0;}
    else {memfree(fb_trace_points);fb_trace_points=__NULL__;fb_trace_count=0;fb_trace_index=-1;}
}
void fb_trace_load(int portals)
{
    filestream file=fopen(portals?"portals.txt":"leak.txt",FILE_READ);if((float)file<0)return;
    int count=0,polygons=0;string line;
    while((line=fgets(file))) {
        if(portals){int n=stoi(line);if(n<3 || n>1024 || count+n>262144){fclose(file);return;}
            polygons++;count+=n;for(int i=0;i<n;i++)if(!fgets(file)){fclose(file);return;}}
        else if(++count>262144){fclose(file);return;}
    }
    fclose(file);fb_trace_unload(portals);if(!count)return;
    file=fopen(portals?"portals.txt":"leak.txt",FILE_READ);if((float)file<0)return;
    if(portals) {
        fb_trace_portals=memalloc(sizeof(vector)*count);fb_trace_sizes=memalloc(sizeof(int)*polygons);
        fb_trace_portal_count=polygons;int offset=0;
        for(int p=0;p<polygons;p++){int vertices=stoi(fgets(file));fb_trace_sizes[p]=vertices;
            for(int v=0;v<vertices;v++)fb_trace_portals[offset++]=stov(fgets(file));}
    }else {fb_trace_points=memalloc(sizeof(vector)*count);fb_trace_count=count;
        for(int j=0;j<count;j++)fb_trace_points[j]=stov(fgets(file));}
    fclose(file);
}
void fb_trace_step(int step)
{
    if(!fb_trace_count)return;
    fb_trace_index=bound(0,fb_trace_index+step,fb_trace_count-1);fb_focus_active=FALSE;
    fb_camera_position(fb_trace_points[fb_trace_index]);
    int next=min(fb_trace_count-1,fb_trace_index+1),previous=max(0,fb_trace_index-1);
    vector direction=fb_trace_points[next]-fb_trace_points[fb_trace_index];
    if(vlen(direction)<0.001)direction=fb_trace_points[fb_trace_index]-fb_trace_points[previous];
    if(vlen(direction)>0.001)setproperty(VF_CL_VIEWANGLES,fb_camera_angles(direction));
}
void fb_trace_draw()
{
    if(fb_trace_count>1) {
        shaderforname("ftebroom/leak","{\n{\nmap $whiteimage\nrgbgen vertex\nalphagen vertex\n}\n}");
        R_BeginPolygon("ftebroom/leak",3);
        for(int i=1;i<fb_trace_count;i++){R_PolygonVertex(fb_trace_points[i-1],'0 0 0','1 0.15 0.05',1);R_PolygonVertex(fb_trace_points[i],'0 0 0','1 0.15 0.05',1);R_EndPolygon();}
    }
    if(fb_trace_portal_count) {
        shaderforname("ftebroom/portals","{\ncull none\n{\nmap $whiteimage\nrgbgen vertex\nalphagen vertex\nblendfunc blend\n}\n}");
        int offset=0;
        for(int p=0;p<fb_trace_portal_count;p++) {
            R_BeginPolygon("ftebroom/portals",0);
            for(int v=0;v<fb_trace_sizes[p];v++)R_PolygonVertex(fb_trace_portals[offset++],'0 0 0','0.2 0.7 1',0.25);
            R_EndPolygon();
        }
    }
}
int fb_trace_command()
{
    if(argv(0)!="ftebroom_trace")return FALSE;
    string kind=argv(1);
    if(kind=="loadpoints")fb_trace_load(FALSE);else if(kind=="loadportals")fb_trace_load(TRUE);
    else if(kind=="unloadpoints")fb_trace_unload(FALSE);else if(kind=="unloadportals")fb_trace_unload(TRUE);
    else fb_trace_step(kind=="previous"?-1:1);return TRUE;
}
