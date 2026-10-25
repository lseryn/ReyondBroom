from pathlib import Path
import hashlib,json,sys
root=Path(sys.argv[1]);log=(root/"editor/ftebroom/qconsole.log").read_text(encoding="utf-8",errors="replace")
assert "DESKTOP_FAIL" not in log and "CSQC_Abort" not in log
for name in ("external69_mount","external69_ready","external69_pak_and_mod_priority","external69_loose","external69_palette","external69_packed_model","external69_nested_wad","external69_saved_absolute_mod","external69_empty_mod_accepted","external69_old_mount_removed"):
 assert "DESKTOP_PASS "+name in log,name
expected=json.loads((root/"external69-resources.json").read_text(encoding="utf-8"))
actual={p.relative_to(root).as_posix() for parent in (root/"External games Ж",root/"Standalone mod Ж",root/"Empty mod") for p in parent.rglob("*") if p.is_file()}
assert actual==set(expected),"game resource files were added or removed"
for name,value in expected.items():assert hashlib.sha256((root/name).read_bytes()).hexdigest()==value,name
print("PASS: external game root/id1/mod, packed/loose assets, nested WADs, mod priority, empty mod and resource files unchanged")
