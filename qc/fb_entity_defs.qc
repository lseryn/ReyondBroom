// SPDX-License-Identifier: GPL-2.0-or-later
// Native definition parsing publishes a compact cache consumed by the scene renderer.
typedef struct {string classname,model,modelkey;vector mins,maxs,color;} fb_entity_definition_t;
hashtable fb_entity_defaults;
fb_entity_definition_t *fb_entity_definitions;int fb_entity_definition_count;
void fb_entity_definitions_load()
{
    filestream stream=fopen("ftebroom-entity-definitions.txt",FILE_READ);if((float)stream<0) return;
    for(int i=0;i<fb_entity_definition_count;i++) {strunzone(fb_entity_definitions[i].classname);strunzone(fb_entity_definitions[i].model);strunzone(fb_entity_definitions[i].modelkey);}
    memfree(fb_entity_definitions);fb_entity_definitions=__NULL__;fb_entity_definition_count=0;
    if(fb_entity_defaults)hash_destroytab(fb_entity_defaults);fb_entity_defaults=hash_createtab(256,EV_STRING);
    string line;while((line=fgets(stream))) {
        int count=tokenize(line);
        if(count==4 && argv(0)=="property"){fb_entity_defaults[strcat(argv(1),"/",argv(2))]=argv(3);continue;}
        if(count!=6)continue;
        fb_entity_definition_t *items=memalloc((fb_entity_definition_count+1)*sizeof(fb_entity_definition_t));
        memcpy(items,fb_entity_definitions,fb_entity_definition_count*sizeof(fb_entity_definition_t));memfree(fb_entity_definitions);fb_entity_definitions=items;
        fb_entity_definition_t *def=&items[fb_entity_definition_count++];def->classname=strzone(argv(0));def->mins=stov(argv(1));def->maxs=stov(argv(2));def->color=stov(argv(3));def->model=strzone(argv(4));def->modelkey=strzone(argv(5));
    }
    fclose(stream);
}
