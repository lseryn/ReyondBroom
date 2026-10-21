// SPDX-License-Identifier: GPL-2.0-or-later
int fb_obj_vertex;
void fb_obj_point(filestream file,vector p,float u,float v)
{
    fputs(file,sprintf("v %.9g %.9g %.9g\n",p_x,p_y,p_z));
    fputs(file,sprintf("vt %.9g %.9g\n",u,1-v));fb_obj_vertex++;
}
void fb_obj_material(filestream file,filestream mtl,hashtable materials,string shader)
{
    string name=strreplace(" ","_",strreplace("\t","_",strreplace("\n","_",strreplace("\r","_",shader))));
    if(name=="")name="untextured";
    if(materials[name]==""){materials[name]="1";fputs(mtl,strcat("newmtl ",name,"\nKd 1 1 1\nd 1\n\n"));}
    fputs(file,strcat("usemtl ",name,"\n"));
}
int fb_obj_export()
{
    cvar_set("ftebroom_obj_status","-1");fb_document_tick();
    filestream file=fopen("export.obj",FILE_WRITE);if((float)file<0)return FALSE;
    filestream mtl=fopen("export.mtl",FILE_WRITE);if((float)mtl<0){fclose(file);return FALSE;}
    fputs(file,"# FTEBroom OBJ: world units, Z up, UV V flipped for OBJ\nmtllib export.mtl\n");
    hashtable materials=hash_createtab(128,EV_STRING);fb_obj_vertex=0;
    for(int n=2;n<fb_node_count;n++)if(fb_nodes[n].kind>=FB_NODE_BRUSH && fb_export_included(n)) {
        int model=fb_nodes[n].model,id=fb_nodes[n].id;fputs(file,sprintf("o object_%i_%i\n",model,id));
        patchinfo_t info;int cpcount=patch_getcp(model,id,__NULL__,0,&info);
        if(cpcount) {
            patchvert_t *cp=memalloc(sizeof(patchvert_t)*cpcount);patch_getcp(model,id,cp,cpcount,&info);
            fb_obj_material(file,mtl,materials,info.shadername);
            int width=(info.cpwidth-1)*4+1,height=(info.cpheight-1)*4+1;
            patchvert_t *rows=memalloc(sizeof(patchvert_t)*width*info.cpheight);
            for(int row=0;row<info.cpheight;row++)for(int col=0;col<width;col++)
                fb_patch_curve(&cp[row*info.cpwidth],info.cpwidth,1,(float)col/(float)(width-1),&rows[row*width+col]);
            int base=fb_obj_vertex+1;
            for(int y=0;y<height;y++)for(int x=0;x<width;x++) {
                patchvert_t point;fb_patch_curve(&rows[x],info.cpheight,width,(float)y/(float)(height-1),&point);
                fb_obj_point(file,point.xyz,point.s,point.t);
            }
            for(int y=0;y<height-1;y++)for(int x=0;x<width-1;x++) {
                int a=base+y*width+x,b=a+1,c=b+width,d=a+width;
                fputs(file,sprintf("f %i/%i %i/%i %i/%i\n",a,a,c,c,b,b));
                fputs(file,sprintf("f %i/%i %i/%i %i/%i\n",a,a,d,d,c,c));
            }
            memfree(rows);memfree(cp);
        }else {
            int count=brush_get(model,id,__NULL__,0,__NULL__);if(!count)continue;
            brushface_t *faces=memalloc(sizeof(brushface_t)*count);brush_get(model,id,faces,count,__NULL__);
            for(int f=0;f<count;f++) {
                static vector points[64];int vertices=brush_getfacepoints(model,id,f+1,points,64);if(vertices<3)continue;
                brushface_t face=faces[f];fb_obj_material(file,mtl,materials,face.shadername);
                vector size=drawgetimagesize(face.shadername);if(size_x<=0)size_x=64;if(size_y<=0)size_y=64;
                int first=fb_obj_vertex+1;
                for(int p=0;p<vertices;p++)fb_obj_point(file,points[p],(face.sdir*points[p]+face.sbias)/size_x,(face.tdir*points[p]+face.tbias)/size_y);
                fputs(file,"f");for(int p=vertices-1;p>=0;p--)fputs(file,sprintf(" %i/%i",first+p,first+p));fputs(file,"\n");
            }
            memfree(faces);
        }
    }
    hash_destroytab(materials);fclose(file);fclose(mtl);cvar_set("ftebroom_obj_status","1");return TRUE;
}
