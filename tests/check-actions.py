"""Validate the engine's action dump and the keyboard-routing MAP regression."""
from pathlib import Path
import json
import itertools
import re
import sys

root=Path(sys.argv[1])
log=(root/"qconsole.log").read_text(errors="replace").rsplit("Engine Version:",1)[-1]
assert "FTEBROOM_ACTIONS_END" in log,"Missing action dump"
records=[]
for line in log.splitlines():
    if "FTEBROOM_ACTION\t" not in line: continue
    parts=line.split("FTEBROOM_ACTION\t",1)[1].split("\t")
    records.append(dict(id=parts[0],label=parts[1],context=int(parts[2]),
                        shortcuts=parts[3],codes=parts[4].split(";") if parts[4] else [],status=parts[5]))
catalog=json.loads((Path(__file__).with_name("actions-catalog.json")).read_text())
assert {r["id"] for r in catalog} <= {r["id"] for r in records},"Incomplete action catalogue"
assert any(r["id"] == "View Filter/Entity class/light" for r in records)
assert any(r["id"] == "Create Entity/light" for r in records)
assert len(records)==len({r["id"] for r in records})
for r in records:
    assert not any(re.search(r"(?:^|\+)f(?:[1-9]|1[0-2])$",chord,re.I) for chord in r["shortcuts"].split(";")),r
    assert all(int(c.split(":")[0])>0 for c in r["codes"]),f"Unknown FTE key: {r}"
groups=(3,28,2097120)
def overlap(a,b):
    return all(not(a&g) or not(b&g) or (a&b&g) for g in groups)
for a,b in itertools.combinations(records,2):
    common=set(a["codes"])&set(b["codes"])
    assert not(common and overlap(a["context"],b["context"])),f"Conflicting shortcuts: {a['id']} / {b['id']}: {common}"
assert "ambiguous shortcut" not in log
def faces(name):
    return sorted(line for line in (root/"maps"/f"actions_{name}.map").read_text().splitlines() if line.startswith("( "))
assert len(faces("start"))==12 and len(faces("undo"))==6
for name in ["redo","redo_y","text","popup","reserved"]:
    assert faces(name)==faces("start"),name
assert faces("backspace_text")==faces("start")
assert len(faces("backspace"))==6
assert faces("backspace_undo")==faces("start")
assert '"ftebroom_tool" is "2"' in log
assert "Focus Camera on Selection is not implemented yet" not in log
assert 'Unknown command "ftebroom_camera_focus"' not in log
for action in ("Menu/Camera/Up","Menu/Camera/Down","Menu/View/Reset camera zoom","Menu/View/Focus Camera on Selection","Menu/View/Move Camera to..."):
    assert next(r for r in records if r["id"]==action)["status"]=="implemented"
assert "FTEBroom: unknown action" in log
assert (root/"actions.png").is_file()
if len(sys.argv)>2:
    doc=Path(sys.argv[2])
    lines=["<!-- Generated from ftebroom_actions_dump. Do not edit by hand. -->",
           "| Action | Shortcut | Status |","|---|---|---|"]
    lines += [f"| {r['id']} | {r['shortcuts'] or '—'} | {r['status']} |" for r in records if r["codes"]]
    doc.write_text("\n".join(lines)+"\n",encoding="utf8")
print(f"PASS: {len(records)} actions, no overlapping shortcuts; native Undo/Redo, text/popup guards and reserved actions")
