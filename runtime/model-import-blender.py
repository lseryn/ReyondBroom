# SPDX-License-Identifier: GPL-2.0-or-later
"""Run with Blender --background --disable-autoexec --python ... -- arguments.

Only writes to the private staging directory. Never saves the source .blend.
"""
import argparse
import json
import math
from pathlib import Path
import sys
import traceback
import bpy
sys.dont_write_bytecode = True


def main(args):
    source = Path(args.source).resolve()
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    for marker in ('success.txt', 'error.txt'):
        (output / marker).unlink(missing_ok=True)
    ext = source.suffix.lower()
    if ext == '.blend':
        bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
    else:
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete(use_global=False)
        if ext == '.fbx':
            bpy.ops.import_scene.fbx(filepath=str(source), global_scale=1.0)
        elif ext in ('.glb', '.gltf'):
            bpy.ops.import_scene.gltf(filepath=str(source))
        elif ext in ('.smd', '.dmx'):
            try:
                sys.path.insert(0, str(Path(__file__).resolve().parent / 'blender-addons'))
                import io_scene_valvesource
                io_scene_valvesource.register()
                bpy.ops.import_scene.smd(filepath=str(source))
            except Exception as exc:
                raise RuntimeError('The bundled Source importer could not run. Use Blender 4.1 or newer; see the import error log.') from exc
        else:
            raise RuntimeError('Unsupported Blender bridge source: ' + ext)
    scene = bpy.context.scene
    objects = sorted((o for o in scene.objects if o.type == 'MESH' and not o.hide_render), key=lambda o: o.name)
    if not objects:
        raise RuntimeError('No visible mesh objects in the source.')
    # Bake the diffuse/base colour into a separate atlas per object. New UVs do
    # not affect source texture sampling: the original UV layer remains active
    # for rendering, while the new layer is the explicit bake destination.
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 1
    surfaces = []
    for index, obj in enumerate(objects):
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        # Keep an independent mesh so linked objects can receive their own UVs.
        obj.data = obj.data.copy()
        if not obj.data.uv_layers:
            obj.data.uv_layers.new(name='SourceUV')
        source_uv = obj.data.uv_layers.active
        source_uv.active_render = True
        source_uv_name = source_uv.name
        atlas_uv = obj.data.uv_layers.new(name='FTEBroomAtlas')
        obj.data.uv_layers.active = atlas_uv
        atlas_uv_name = atlas_uv.name
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(island_margin=0.02)
        bpy.ops.object.mode_set(mode='OBJECT')
        # Missing source images are an error, not silently baked pink textures.
        image = bpy.data.images.new('FTEBroomBake', width=512, height=512, alpha=False)
        if not obj.data.materials:
            mat = bpy.data.materials.new('Untextured')
            mat.use_nodes = True
            obj.data.materials.append(mat)
        for slot in obj.material_slots:
            mat = slot.material.copy() if slot.material else bpy.data.materials.new('Untextured')
            slot.material = mat
            mat.use_nodes = True
            if ext in ('.smd', '.dmx') and not any(n.type == 'TEX_IMAGE' for n in mat.node_tree.nodes):
                name = mat.name.removesuffix('.001')
                candidates = [source.parent / name, source.parent / 'materials' / name]
                texture = next((Path(str(p) + suffix) for p in candidates for suffix in ('', '.png', '.tga', '.jpg') if Path(str(p) + suffix).is_file()), None)
                if texture is None:
                    raise RuntimeError('Missing diffuse texture for Source material ' + name + '. Supply PNG/TGA/JPEG beside the model, or prepare the material in Blender.')
                node = mat.node_tree.nodes.new('ShaderNodeTexImage')
                node.image = bpy.data.images.load(str(texture))
                shader = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
                if shader is None:
                    raise RuntimeError('Source material has no supported base-colour shader: ' + name)
                mat.node_tree.links.new(node.outputs['Color'], shader.inputs['Base Color'])
            for node in list(mat.node_tree.nodes):
                if node.type == 'TEX_IMAGE' and node.image and not node.image.has_data:
                    # Blender loads file images lazily; has_data alone is not
                    # evidence that an on-disk image is missing.
                    if not len(node.image.pixels):
                        raise RuntimeError('Missing texture: ' + node.image.filepath)
                # Explicitly bind previously implicit UV inputs to the source UV.
                if node.type == 'TEX_IMAGE' and not node.inputs['Vector'].is_linked:
                    uv_node = mat.node_tree.nodes.new('ShaderNodeUVMap')
                    uv_node.uv_map = source_uv_name
                    mat.node_tree.links.new(uv_node.outputs['UV'], node.inputs['Vector'])
            target = mat.node_tree.nodes.new('ShaderNodeTexImage')
            target.image = image
            mat.node_tree.nodes.active = target
        bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, use_clear=True, margin=8, uv_layer=atlas_uv_name)
        image.filepath_raw = str(output / f'skin{index}.tga')
        image.file_format = 'TARGA'
        image.save()
        surfaces.append((obj, atlas_uv_name, f'skin{index}.tga'))
    lines = [f'FTEBROOM_MESH 1 {args.frames} {len(surfaces)}']
    total = 0
    for frame in range(args.frames):
        time = args.start + frame * scene.render.fps / max(1.0, args.fps)
        scene.frame_set(math.floor(time), subframe=time - math.floor(time))
        deps = bpy.context.evaluated_depsgraph_get()
        for obj, uv_name, material in surfaces:
            evaluated = obj.evaluated_get(deps)
            mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=deps)
            try:
                mesh.calc_loop_triangles()
                uv = mesh.uv_layers[uv_name].data
                matrix = evaluated.matrix_world
                normals = matrix.to_3x3().inverted_safe().transposed()
                vertices, triangles, lookup = [], [], {}
                for tri in mesh.loop_triangles:
                    corners = list(tri.loops)
                    if matrix.determinant() < 0:
                        corners.reverse()
                    indices = []
                    for loop in corners:
                        vertex = mesh.loops[loop].vertex_index
                        point = matrix @ mesh.vertices[vertex].co
                        normal = (normals @ mesh.corner_normals[loop].vector).normalized()
                        tex = uv[loop].uv
                        values = (*point, *normal, tex.x, 1.0 - tex.y)
                        # Split normal/UV seams, but retain shared triangle vertices.
                        key = (vertex, *values)
                        if key not in lookup:
                            lookup[key] = len(vertices)
                            vertices.append(values)
                        indices.append(lookup[key])
                    triangles.append(indices)
                total += len(vertices)
                if total > 4000000 or len(vertices) > 65536 or len(triangles) > 131072:
                    raise RuntimeError('Model exceeds conversion geometry limits.')
                lines.append(f'{json.dumps(material)} {len(vertices)} {len(triangles)}')
                lines.extend(' '.join(format(v, '.9g') for v in values) for values in vertices)
                lines.extend(' '.join(map(str, tri)) for tri in triangles)
            finally:
                evaluated.to_mesh_clear()
    (output / 'model.mesh').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    (output / 'success.txt').write_text('ok', encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--frames', type=int, default=1)
    parser.add_argument('--start', type=int, default=1)
    parser.add_argument('--fps', type=float, default=24)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    try:
        if not 1 <= args.frames <= 1024:
            raise RuntimeError('Frame count must be between 1 and 1024.')
        main(args)
    except Exception as exc:
        Path(args.output).mkdir(parents=True, exist_ok=True)
        (Path(args.output) / 'error.txt').write_text(str(exc), encoding='utf-8')
        traceback.print_exc()
        sys.exit(1)
