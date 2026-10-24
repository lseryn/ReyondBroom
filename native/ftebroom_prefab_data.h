// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <map>
#include <set>
#include <string>
#include <vector>
#include <stdexcept>
#include <cctype>
namespace ftebroom::prefab {
struct Entity {
  std::map<std::string,std::string> fields;
  std::string geometry;
  int parent=-1;
  std::string get(const std::string& key) const {auto i=fields.find(key);return i==fields.end()?"":i->second;}
};
struct Collection {std::vector<Entity> entities;std::vector<int> groups;};
struct Token {std::string text;size_t begin=0,end=0;bool quoted=false;};
class Lexer {
  const std::string& bytes;size_t cursor=0;
public:
  explicit Lexer(const std::string& value):bytes(value){}
  Token next(){
    while(cursor<bytes.size()){
      if((unsigned char)bytes[cursor]<=32){++cursor;continue;}
      if(bytes.compare(cursor,2,"//")==0){auto end=bytes.find('\n',cursor);cursor=end==bytes.npos?bytes.size():end+1;continue;}
      if(bytes.compare(cursor,2,"/*")==0){auto end=bytes.find("*/",cursor+2);if(end==bytes.npos)throw std::runtime_error("Unclosed MAP comment.");cursor=end+2;continue;}
      break;
    }
    Token t;t.begin=cursor;if(cursor==bytes.size()){t.end=cursor;return t;}
    char first=bytes[cursor++];
    if(first=='"'){
      t.quoted=true;bool closed=false;
      while(cursor<bytes.size()){
        char c=bytes[cursor++];if(c=='"'){closed=true;break;}
        if(c=='\\'&&cursor<bytes.size()){c=bytes[cursor++];if(c=='n')c='\n';}
        t.text+=c;
      }
      if(!closed)throw std::runtime_error("Unclosed MAP string.");
    }else if(first=='{'||first=='}')t.text=first;
    else{t.text=first;while(cursor<bytes.size()&&(unsigned char)bytes[cursor]>32&&bytes[cursor]!='{'&&bytes[cursor]!='}')t.text+=bytes[cursor++];}
    t.end=cursor;return t;
  }
};
inline bool brace(const Token& t,const char* value){return !t.quoted&&t.text==value;}
inline bool group(const Entity& e){auto type=e.get("_tb_type");return e.get("classname")=="func_group"&&(type=="_tb_group"||type=="group");}
inline Collection parse(const std::string& bytes){
  if(bytes.empty()||bytes.size()>16*1024*1024)throw std::runtime_error("Choose a MAP collection up to 16 MiB.");
  Lexer lexer(bytes);Collection result;std::map<std::string,int> identities;
  for(auto token=lexer.next();!token.text.empty();token=lexer.next()){
    if(!brace(token,"{"))throw std::runtime_error("Expected a MAP entity.");
    Entity entity;bool closed=false;
    while(true){
      token=lexer.next();if(token.text.empty()&&!token.quoted)break;
      if(brace(token,"}")){closed=true;break;}
      if(brace(token,"{")){
        auto start=token.begin;int depth=1;
        while(depth){token=lexer.next();if(token.text.empty()&&!token.quoted)throw std::runtime_error("Unclosed MAP geometry.");if(brace(token,"{"))++depth;if(brace(token,"}"))--depth;if(depth>16)throw std::runtime_error("Excessive MAP nesting.");}
        entity.geometry+=bytes.substr(start,token.end-start)+"\n";
      }else{
        auto value=lexer.next();if(!value.quoted&&(value.text.empty()||brace(value,"{")||brace(value,"}")))throw std::runtime_error("Missing MAP property value.");
        entity.fields[token.text]=value.text;
      }
    }
    if(!closed)throw std::runtime_error("Unclosed MAP entity.");
    if(result.entities.size()>=8192)throw std::runtime_error("Collection exceeds 8192 entities.");
    int index=result.entities.size();auto id=entity.get("_tb_id");
    if(!id.empty()&&!identities.emplace(id,index).second)throw std::runtime_error("Duplicate collection group/layer ID.");
    if(group(entity)&&!entity.get("_tb_name").empty()&&!id.empty())result.groups.push_back(index);
    result.entities.push_back(std::move(entity));
  }
  for(auto& e:result.entities){auto parent=identities.find(e.get("_tb_group"));if(parent!=identities.end()){if(!group(result.entities[parent->second]))throw std::runtime_error("Invalid collection parent.");e.parent=parent->second;}}
  for(size_t i=0;i<result.entities.size();i++){int parent=i;for(int depth=0;parent>=0;depth++){if(depth>=64)throw std::runtime_error("Cyclic or excessive collection hierarchy.");parent=result.entities[parent].parent;}}
  if(result.groups.empty())throw std::runtime_error("No named TrenchBroom/ReyondBroom groups in this MAP.");
  return result;
}
inline std::string quote(const std::string& value){std::string out="\"";for(char c:value){if(c=='\\'||c=='"')out+='\\';if(c=='\n')out+="\\n";else out+=c;}return out+'"';}
inline std::string extract(const Collection& collection,int root,const std::string& name){
  if(root<0||size_t(root)>=collection.entities.size()||!group(collection.entities[root]))throw std::runtime_error("Invalid prefab selection.");
  std::string result="{\n\"classname\" \"worldspawn\"\n}\n";
  for(size_t i=0;i<collection.entities.size();i++){
    int p=i;for(int depth=0;p>=0&&p!=root&&depth<64;depth++)p=collection.entities[p].parent;if(p!=root)continue;
    const auto& entity=collection.entities[i];result+="{\n";
    for(const auto& [key,value]:entity.fields){
      // A prefab instance is independent of links, transforms and hidden source layers.
      if(key=="_tb_layer"||key=="_tb_linked_group_id"||key=="_tb_transformation"||key.rfind("_ftebroom_link",0)==0||key.rfind("_ftebroom_symmetry",0)==0)continue;
      if(key=="model"&&(!entity.geometry.empty()||group(entity)))continue;
      if(int(i)==root&&(key=="_tb_group"||key=="_tb_name"))continue;
      result+=quote(key)+" "+quote(value)+"\n";
    }
    if(int(i)==root)result+="\"_tb_name\" "+quote(name)+"\n";
    result+=entity.geometry+"}\n";
  }
  return result;
}
}
