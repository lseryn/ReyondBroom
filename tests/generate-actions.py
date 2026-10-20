from pathlib import Path
import json
p=Path(__file__).resolve().parents[1]
rows=[]
def add(group,label,key="",context="CtxAny",command=None,gesture=""):
    rows.append(dict(id=f"Menu/{group}/{label}",label=label,keys=key,context=context,command=command,gesture=gesture))
for label,key in [
("New","Ctrl+n"),("Open...","Ctrl+o"),("Save","Ctrl+s"),("Save as...","Ctrl+Shift+s"),("Close","Ctrl+w"),
("Reload Material Collections","f5"),("Reload Entity Definitions","f6"),("Preferences...",""),
("Export Map...",""),("Export OBJ...",""),("Load Point File...",""),("Reload Point File",""),("Unload Point File",""),
("Load Portal File...",""),("Reload Portal File",""),("Unload Portal File",""),("Revert",""),("Game / resources...",""),("Exit","")]:
    cmd={"New":"ftebroom_ui new","Close":"ftebroom_ui close","Exit":"ftebroom_ui exit","Save as...":"ftebroom_ui save","Open...":"ftebroom_ui open","Save":"ftebroom_ui save","Game / resources...":"ftebroom_ui resources","Reload Material Collections":"ftebroom_assets_ready","Preferences...":"ftebroom_ui preferences"}.get(label)
    add("File",label,key,command=cmd)
for label,key in [
("Undo","Ctrl+z"),("Redo","Ctrl+Shift+z;Ctrl+y"),("Repeat Last Commands","Ctrl+r"),("Clear Repeatable Commands","Ctrl+Shift+r"),
("Cut","Ctrl+x"),("Copy","Ctrl+c"),("Paste","Ctrl+v"),("Paste at Original Position","Ctrl+Alt+v"),
("Duplicate","Ctrl+d"),("Delete","del"),("Move objects...","Ctrl+Alt+m"),("Select All","Ctrl+a"),
("Deselect All","Ctrl+Shift+a"),("Invert Selection","Ctrl+Alt+a"),("Select Siblings","Ctrl+b"),
("Select Touching","Ctrl+t"),("Select Inside","Ctrl+e"),("Select Tall","Ctrl+Shift+e"),
("Group","Ctrl+g"),("Ungroup","Ctrl+Shift+g"),("Rename Groups","Ctrl+Alt+g"),("Create Linked Duplicate","Ctrl+Shift+d"),
("CSG Convex Merge","Ctrl+j"),("CSG Subtract","Ctrl+k"),("CSG Hollow","Ctrl+Shift+k"),("CSG Intersect","Ctrl+l"),
("Snap Vertices to Integer","Ctrl+Shift+v"),("Snap Vertices to Grid","Ctrl+Alt+Shift+v"),("Convert Selection to Patches","Ctrl+p"),
("UV Lock","u"),("Texture Lock",""),("Make Structural","Alt+s")]:
    ctx="CtxAny"
    if label=="Delete":ctx="CtxNodeSelection|CtxNoTool|CtxBrushTool|CtxRotateTool|CtxScaleTool|CtxShearTool|CtxSweepTool"
    if label=="Select Tall":ctx="CtxView2D"
    if label=="Make Structural" or label=="Move objects...":ctx="CtxNodeSelection"
    add("Edit",label,key,ctx,{"Undo":"ftebroom_undo","Redo":"ftebroom_redo","Delete":"ftebroom_delete","Texture Lock":"ftebroom_ui texturelock","UV Lock":"ftebroom_ui uvlock"}.get(label))
for label,key in [("Brush","b"),("Clip","c"),("Rotate","r"),("Sweep","y"),("Scale","t"),("Shear","g"),("Vertex","v"),("Edge","e"),("Face","f"),("Control Point","p")]:
    add("Tools",label,key,"CtxAnyView","ftebroom_tool_toggle "+label.lower().replace(" ",""))
add("Tools","Cancel","escape",command="ftebroom_ui cancel")
add("Tools","Deactivate current tool","Shift+escape",command="ftebroom_tool_deactivate")
for label,key,ctx,cmd in [
("Create brush","enter","CtxView3D|CtxBrushTool",None),("Perform clip","enter","CtxClipTool","ftebroom_clip apply"),
("Toggle clip side","Ctrl+enter","CtxClipTool","ftebroom_tool_key side"),("Perform sweep","enter","CtxSweepTool",None),
("Increase sweep scale","]","CtxSweepTool",None),("Decrease sweep scale","[","CtxSweepTool",None),
("Delete last clip point","del","CtxClipTool","ftebroom_tool_key back"),("Delete vertices","del","CtxAnyHandleTool",None)]:
    add("Tools",label,key,ctx,cmd)
directions=[("Forward","uparrow"),("Back","downarrow"),("Left","leftarrow"),("Right","rightarrow"),("Up","pgup"),("Down","pgdn")]
for label,key in directions:
    add("Transform","Move "+label,key,"CtxAnyView|CtxNodeSelection",command="ftebroom_nudge "+{"Forward":"1 1","Back":"1 -1","Left":"0 -1","Right":"0 1","Up":"2 1","Down":"2 -1"}[label])
    add("Transform","Duplicate and move "+label,"Ctrl+"+key,"CtxAnyView|CtxNodeSelection")
    add("Transform","Rotate "+label,"Alt+"+key,"CtxAnyView|CtxNodeSelection")
for label,key in [("Flip horizontal","Ctrl+f"),("Flip vertical","Ctrl+Alt+f")]:
    add("Transform",label,key,"CtxAnyView|CtxNodeSelection")
for label,key in directions:
    for suffix,mod in [("",""),(" coarse","Shift+"),(" fine","Ctrl+")]:
        add("Textures",("Rotate " if key in ("pgup","pgdn") else "Move ")+label+suffix,mod+key,"CtxView3D|CtxFaceSelection")
for label,key in [("Flip horizontal","Ctrl+f"),("Flip vertical","Ctrl+Alt+f")]:
    add("Textures",label,key,"CtxView3D|CtxFaceSelection")
add("Textures","Reset alignment","Shift+r","CtxAnyView|CtxAnySelection")
add("Textures","Reset to world aligned","Alt+Shift+r","CtxAnyView|CtxAnySelection")
for label,key,ctx,cmd in [
("Show Grid","0","CtxAny","ftebroom_grid visible"),("Snap to Grid","Alt+0","CtxAny","ftebroom_grid snap"),
("Increase Grid Size","+;=;Shift+=;kp_plus","CtxAnyView","ftebroom_grid step 1"),("Decrease Grid Size","-;kp_minus","CtxAnyView","ftebroom_grid step -1"),
("Next Point",".","CtxAnyView",None),("Previous Point",",","CtxAnyView",None),("Reset 2D Cameras","Ctrl+Shift+u","CtxAny",None),
("Focus Camera on Selection","Ctrl+u","CtxAny",None),("Reset camera zoom","Ctrl+Alt+z","CtxView3D",None),
("Cycle map view","space","CtxAnyView",None),("Maximize current view","Ctrl+space","CtxAnyView",None),
("Isolate","Ctrl+i","CtxAny",None),("Hide","Ctrl+Alt+i","CtxAny",None),("Show All","Ctrl+Shift+i","CtxAny",None),
("Map Inspector","Ctrl+1","CtxAny","ftebroom_ui map"),("Entity Inspector","Ctrl+2","CtxAny",None),
("Face Inspector","Ctrl+3","CtxAny","ftebroom_ui material"),("Toggle Info Panel","Ctrl+4","CtxAny",None),
("Toggle Inspector","Ctrl+5","CtxAny",None),("Toggle Toolbar","Ctrl+Alt+t","CtxAny",None),
("Open Inspector","f1","CtxAny","ftebroom_ui inspector")]:
    add("View/Grid" if "Grid" in label else "View",label,key,ctx,cmd)
for n in range(9):add("View/Grid",f"Grid {2**n}",str(n+1),"CtxAnyView",f"ftebroom_grid set {2**n}")
for n in (0.125,0.25,0.5):add("View/Grid",f"Grid {n}",command=f"ftebroom_grid set {n}")
for label,key in [("Forward","w"),("Back","s"),("Left","a"),("Right","d"),("Up","q"),("Down","x")]:
    add("Camera",label,key,"CtxView3D","ftebroom_hold "+key if key in "wsad" else None)
for label in ["Compile...","Launch...","Launch in FTE","Rerun"]:add("Run",label)
add("Help","Action reference",command="ftebroom_ui actions")
gestures=[
("Look","RMB drag","CtxView3D"),("Orbit","Alt+RMB drag","CtxView3D"),("Flight speed","RMB+wheel","CtxView3D"),
("Pan","MMB drag","CtxView3D"),("Move camera","wheel","CtxView3D"),("Temporary zoom","Shift+wheel","CtxView3D"),
("Drill selection","Ctrl+wheel","CtxAnyView"),("Grid wheel","Ctrl+Alt+wheel","CtxAnyView"),
("Select object","LMB click","CtxAnyView|CtxNoTool"),("Toggle object","Ctrl+LMB click","CtxAnyView|CtxNoTool"),
("Paint selection","Ctrl+LMB drag (unselected)","CtxAnyView|CtxNoTool"),("Select face","Shift+LMB click","CtxAnyView|CtxNoTool"),
("Toggle face","Ctrl+Shift+LMB click","CtxAnyView|CtxNoTool"),("Paint faces","Ctrl+Shift+LMB drag","CtxAnyView|CtxNoTool"),
("Select siblings or open group","LMB double click","CtxAnyView|CtxNoTool"),("All brush faces","Shift+LMB double click","CtxAnyView|CtxNoTool"),
("Add all brush faces","Ctrl+Shift+LMB double click","CtxAnyView|CtxNoTool"),("Coplanar flood","Alt+Shift+LMB double click","CtxAnyView|CtxNoTool"),
("Add coplanar flood","Ctrl+Alt+Shift+LMB double click","CtxAnyView|CtxNoTool"),
("Move XY","LMB drag (selected)","CtxAnyView|CtxNoTool"),("Move Z","Alt+LMB drag (selected)","CtxAnyView|CtxNoTool"),
("Move axis locked","Shift+LMB drag (selected)","CtxAnyView|CtxNoTool"),("Duplicate and move","Ctrl+LMB drag (selected)","CtxAnyView|CtxNoTool"),
("Draw shape","LMB drag (empty or unselected)","CtxAnyView|CtxNoTool"),
("Extrude","Shift+LMB drag (face hover)","CtxAnyView|CtxNoTool"),("Split","Ctrl+Shift+LMB drag (face hover)","CtxAnyView|CtxNoTool"),
("Stamp","Ctrl+Alt+Shift+LMB drag (face hover)","CtxAnyView|CtxNoTool"),("Move face","Alt+Shift+LMB drag (face hover)","CtxAnyView|CtxNoTool"),
("Transfer material projection","Alt+LMB click","CtxAnyView|CtxNoTool"),("Transfer material rotation","Alt+Shift+LMB click","CtxAnyView|CtxNoTool"),
("Transfer material only","Ctrl+Alt+LMB click","CtxAnyView|CtxNoTool"),
("Pan 2D","RMB or MMB drag","CtxView2D"),("Zoom 2D","wheel","CtxView2D"),("Select smallest face area","LMB click","CtxView2D|CtxNoTool")]
for label,gesture,ctx in gestures:add("Mouse reference",label,context=ctx,gesture=gesture)
(p/"native/ftebroom_actions.inc").write_text("// Generated by tests/generate-actions.py; edit the catalogue there.\n"+"\n".join("add("+", ".join([json.dumps(r["id"]),json.dumps(r["label"]),r["context"],json.dumps(r["keys"]),json.dumps(r["command"]) if r["command"] else "nullptr",json.dumps(r["gesture"])]) +");" for r in rows)+"\n",encoding="utf8")
(p/"tests/actions-catalog.json").write_text(json.dumps(rows,indent=2)+"\n",encoding="utf8")
print(len(rows),"actions")
