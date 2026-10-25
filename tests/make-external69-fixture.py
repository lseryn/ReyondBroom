from pathlib import Path
import hashlib,json,os,runpy,shutil,struct,sys
src=Path(__file__).resolve().parents[1];os.chdir(src)
root=Path(sys.argv[1]).resolve();sys.argv=["make-linux40-fixture.py",str(root)]
runpy.run_path("tests/make-linux40-fixture.py",run_name="__main__")
game=root/"External games Ж"/"Quake";game.mkdir(parents=True)
shutil.move(str(root/"id1"),str(game/"id1"))
mod=game/"Custom mod";shutil.move(str(root/"custom-mod"),str(mod))
def read_pak(path):
 data=path.read_bytes();offset,size=struct.unpack_from("<II",data,4);result={}
 for n in range(offset,offset+size,64):
  name,start,length=struct.unpack_from("<56sII",data,n);result[name.split(bytes([0]))[0].decode()]=data[start:start+length]
 return result
def write_pak(path,entries):
 data=bytearray(b"PACK"+bytes(8));directory=bytearray()
 for name,value in entries.items():
  directory+=struct.pack("<56sII",name.encode(),len(data),len(value));data+=value
 struct.pack_into("<II",data,4,len(data),len(directory));path.write_bytes(data+directory)
for folder,label in ((game/"id1","base"),(mod,"mod")):
 entries=read_pak(folder/"pak0.pak");entries["gfx/palette.lmp"]=bytes([17])+entries["gfx/palette.lmp"][1:]
 entries["external69-pak.txt"]=label.encode();write_pak(folder/"pak0.pak",entries)
 (folder/"external69-loose.txt").write_text("loose-external")
 (folder/"texture-wads").mkdir();shutil.move(str(folder/"test textures.wad"),str(folder/"texture-wads/library.wad"))
standalone=root/"Standalone mod Ж";shutil.copytree(game/"id1",standalone)
empty=root/"Empty mod";empty.mkdir()
for base in (root/"editor",root/"editor/ftebroom"):
 (base/"ftebroom-project.txt").write_text(game.as_posix(),encoding="utf-8")
 (base/"ftebroom-game-profile.txt").write_text('2 0 "" "" "" ""\n',encoding="utf-8")
 (base/"ftebroom-quake1.txt").write_text('"" '+json.dumps(game.as_posix(),ensure_ascii=False)+' "" "" 1 0 "" 0\n',encoding="utf-8")
lines=["exec ftebroom.cfg","set ftebroom_skip_setup 1"]
for t,folder,expected in ((5,game,"base"),(12,mod,"mod"),(19,standalone,"base"),(26,empty,"empty"),(33,game/"id1","base")):
 lines += [f'in {t} set ftebroom_test_import_root '+json.dumps(folder.as_posix(),ensure_ascii=False),f'in {t} set ftebroom_test_expected {expected}',f'in {t+1} ftebroom_test_desktop external69load',f'in {t+4} ftebroom_test_desktop '+("external69empty" if expected=="empty" else "external69check")]
lines += ["in 39 screenshot external69-resources.png","in 41 quit force"]
(root/"editor/ftebroom/external69.cfg").write_text("\n".join(lines)+"\n",encoding="utf-8")
(root/"editor/ftebroom/external69-restart.cfg").write_text("exec ftebroom.cfg\nset ftebroom_skip_setup 1\nset ftebroom_test_expected base\nin 8 ftebroom_test_desktop external69check\nin 10 quit force\n",encoding="utf-8")
files={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for parent in (game,standalone,empty) for p in parent.rglob("*") if p.is_file()}
(root/"external69-resources.json").write_text(json.dumps(files),encoding="utf-8")
print(root)
