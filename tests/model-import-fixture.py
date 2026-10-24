# SPDX-License-Identifier: GPL-2.0-or-later
"""Create disposable, transformed/textured animated fixtures with Blender."""
from pathlib import Path
import sys
import bpy

output = Path(sys.argv[sys.argv.index('--') + 1])
output.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.mesh.primitive_cube_add(size=16, location=(40, -24, 8))
obj = bpy.context.object
obj.scale = (2, 1, 0.5)
obj.keyframe_insert(data_path='location', frame=1)
obj.location.x = 48
obj.keyframe_insert(data_path='location', frame=2)
bpy.context.scene.frame_set(1)
mat = bpy.data.materials.new('Red')
mat.use_nodes = True
mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (0.8, 0.02, 0.01, 1)
obj.data.materials.append(mat)
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = 2
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'animated.blend'))
bpy.ops.export_scene.gltf(filepath=str(output / 'animated.glb'), export_format='GLB')
bpy.ops.export_scene.fbx(filepath=str(output / 'animated.fbx'), use_selection=True, bake_anim=True)
