"""Reproduce the bundled, asset-independent manual acceptance scenes."""
from pathlib import Path
import re
import struct

root = Path(__file__).resolve().parents[1]
runtime = root / "runtime"
template = (runtime / "maps/start.map").read_text().splitlines()
template = [line for line in template if line.startswith("( ")]


def box(center, size, material):
    lines = ["{"]
    for line in template:
        def point(match):
            p = list(map(float, match.groups()))
            unit = [p[0] / 256, p[1] / 256, (p[2] + 8) / 8]
            q = [center[i] + unit[i] * size[i] / 2 for i in range(3)]
            return "( " + " ".join(f"{v:g}" for v in q) + " )"
        line = re.sub(r"\( ([\d.-]+) ([\d.-]+) ([\d.-]+) \)", point, line)
        lines.append(line.replace("ftebroom/grid", material))
    return "\n".join(lines + ["}"])


def world(name, objects, entities=""):
    (runtime / "maps" / f"{name}.map").write_text(
        '{\n"classname" "worldspawn"\n' + "\n".join(objects) + "\n}\n" + entities,
        encoding="utf-8",
    )


for name, rgb in [("qa_red", (200, 65, 45)), ("qa_blue", (50, 110, 225)), ("qa_green", (70, 180, 95))]:
    # Original procedural grid textures, no external artwork or game assets.
    data = bytearray(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, 32, 32, 24, 32))
    for y in range(32):
        for x in range(32):
            scale = .55 if x == 0 or y == 0 else 1
            data.extend(int(channel * scale) for channel in rgb[::-1])
    (runtime / "textures/ftebroom" / f"{name}.tga").write_bytes(data)

world("qa_overlap", [
    box((0, 0, 96), (192, 64, 192), "ftebroom/qa_red"),
    box((0, 160, 96), (64, 64, 64), "ftebroom/qa_blue"),
])
cp = []
for y in range(3):
    row = []
    for x in range(3):
        z = 192 if x == y == 1 else 64
        row.append(f"( {x*96-96} {y*96-96} {z} {x} {y} )")
    cp.append("( " + " ".join(row) + " )")
patch = '{\npatchDef3\n{\n"ftebroom/qa_green"\n( 3 3 8 8 0 1 1 )\n(\n' + "\n".join(reversed(cp)) + "\n)\n}\n}"
entity = '{\n"classname" "info_player_deathmatch"\n"origin" "180 -80 48"\n"angle" "90"\n}\n'
world("qa_patch", [patch], entity)
world("qa_clip", [box((0, 0, 64), (128, 128, 128), "ftebroom/qa_blue")])
world("qa_camera", [box((0, 0, 64), (128, 128, 128), "ftebroom/qa_blue")])
for name, mapname, view, camera in [
    ("perspective", "overlap", 0, "0 -512 96 0 90 0"),
    ("2d", "overlap", 2, "0 -512 96 0 90 0"),
    ("patch", "patch", 0, "320 -400 280 25 130 0"),
    ("clip", "clip", 0, "320 -400 280 25 130 0"),
]:
    (runtime / f"qa-{name}.cfg").write_text(
        f"exec ftebroom.cfg\nset ftebroom_skip_setup 1\n"
        f"in 7 mapedit maps/qa_{mapname}.map\n"
        f"in 10 setpos {camera}\nin 10 set ca_brush_view {view}\n"
        f"in 10 set ca_brush_viewsize {1024 if name == '2d' else 512}\n",
        encoding="utf-8",
    )
(runtime / "qa-camera.cfg").write_text(
    "exec ftebroom.cfg\nset ftebroom_skip_setup 1\n"
    "set ftebroom_test_camera_persistence 1\n"
    "in 7 mapedit maps/qa_camera.map\nin 10 set ca_brush_view 0\n",
    encoding="utf-8",
)
(runtime / "qa-views.cfg").write_text(
    "exec ftebroom.cfg\nset ftebroom_skip_setup 1\n"
    "in 7 mapedit maps/qa_camera.map\nin 10 set ca_brush_view 2\n"
    "in 10 set ca_brush_viewsize 1024\n",encoding="utf-8",
)
(runtime / "qa-layouts.cfg").write_text("exec qa-views.cfg\nin 11 set ftebroom_view_layout 4\n")
print("Generated four maps, seven camera presets and three grid textures.")


if "--benchmark" in __import__("sys").argv:
    world("qa_2000", [box((x*80-760,y*80-760,z*80), (48,48,48), "ftebroom/qa_blue") for z in range(5) for y in range(20) for x in range(20)])
