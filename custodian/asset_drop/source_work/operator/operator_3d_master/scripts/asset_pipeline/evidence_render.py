"""Run inside Blender: blender -b --python evidence_render.py -- DECODED.glb OUT_DIR SCALE [ELEV_DEG=45 PX_PER_M=50]
Textured review evidence from the imported model with the SAME grounding/camera/light model as blender_render.py and the SAME single uniform SCALE
(taken from the frozen pipeline_report). Writes raw frames + diagnostics.json; the host (build_evidence.py) composes the contact sheets.
No model/texture edits. Material diagnostics are read from the live Blender node tree."""
import json, math, pathlib, sys
import bpy
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; glb, out, scale = a[0], pathlib.Path(a[1]), float(a[2]); elev = float(a[3]) if len(a) > 3 else 45.0; ppm = float(a[4]) if len(a) > 4 else 50.0
out.mkdir(parents=True, exist_ok=True)
AZ = {'N': 180, 'NE': -135, 'E': -90, 'SE': -45, 'S': 0, 'SW': 45, 'W': 90, 'NW': 135}
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb)
meshes = [x for x in bpy.data.objects if x.type == 'MESH']
root = bpy.data.objects.new('ASSET_ROOT', None); bpy.context.scene.collection.objects.link(root)
for o in [x for x in bpy.data.objects if x.parent is None and x is not root]: o.parent = root
def bbox():
    bpy.context.view_layer.update(); pts = [m.matrix_world @ Vector(c) for m in meshes for c in m.bound_box]
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]
root.scale = (scale,) * 3; lo, hi = bbox(); root.location = (-(lo[0] + hi[0]) / 2, -(lo[1] + hi[1]) / 2, -lo[2]); lo, hi = bbox()
sc = bpy.context.scene; sc.render.film_transparent = True; sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
w = bpy.data.worlds.new('w'); w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (.45, .45, .5, 1); w.node_tree.nodes['Background'].inputs[1].default_value = .8; sc.world = w
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 3.0; sc.collection.objects.link(sun)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); cam.data.type = 'ORTHO'; sc.collection.objects.link(cam); sc.camera = cam
diag = {'scale': scale, 'height_m': round(hi[2] - lo[2], 4), 'view_transform_default': sc.view_settings.view_transform, 'look': sc.view_settings.look, 'engine_default': 'BLENDER_EEVEE'}
def shoot(name, d, el, res, ortho, target=None, engine='BLENDER_EEVEE', view='Default'):
    sc.render.engine = engine; sc.render.resolution_x = sc.render.resolution_y = res; sc.render.filter_size = 1.5
    if view != 'Default': sc.view_settings.view_transform = view
    else: sc.view_settings.view_transform = diag['view_transform_default']
    cam.data.ortho_scale = ortho; r = math.radians(AZ[d]); e = math.radians(el); t = Vector(target or (0, 0, 0))
    cam.data.shift_y = 0; cam.data.shift_x = 0
    cam.location = t + Vector((10 * math.sin(r) * math.cos(e), -10 * math.cos(r) * math.cos(e), 10 * math.sin(e)))
    cam.rotation_euler = (t - cam.location).to_track_quat('-Z', 'Y').to_euler(); sun.rotation_euler = (math.radians(50), 0, r - math.radians(35))
    sc.render.filepath = str(out / name); bpy.ops.render.render(write_still=True)
# 1. eye-level front / profile / rear at one fixed scale (0 deg elevation)
for n, d in (('front_S', 'S'), ('profile_E', 'E'), ('rear_N', 'N')): shoot(f'eye_{n}.png', d, 0, 768, 2.4, (0, 0, 1.05))
# 2. detail crops (two views each, fixed per-region ortho)
for reg, z, ortho in (('hood_neck', 1.82, .75), ('shoulders_armor', 1.52, 1.0), ('tabard_gold_boots', .62, 1.25)):
    for d in ('S', 'NE'): shoot(f'detail_{reg}_{d}.png', d, 20, 768, ortho, (0, 0, z))
# 3. material proof: textured / Standard view transform / clay, same NE 45 deg view
shoot('mat_textured.png', 'NE', elev, 512, 128 / ppm * 0.9, (0, 0, 1.0)); shoot('mat_textured_standard.png', 'NE', elev, 512, 128 / ppm * 0.9, (0, 0, 1.0), view='Standard')
saved = [list(m.data.materials) for m in meshes]
clay = bpy.data.materials.new('clay'); clay.use_nodes = True; clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (.55, .55, .57, 1); clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = .6
for m in meshes: m.data.materials.clear(); m.data.materials.append(clay)
shoot('mat_clay.png', 'NE', elev, 512, 128 / ppm * 0.9, (0, 0, 1.0))
# 4. geometry proof (Workbench): rear clay, wireframe close-ups
sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'SINGLE'; sc.display.shading.single_color = (.7, .7, .72)
shoot('geo_rear_solid.png', 'N', 20, 768, 2.4, (0, 0, 1.05), engine='BLENDER_WORKBENCH')
# Workbench ignores wireframe in final renders, so draw the real mesh edges with EEVEE's Wireframe shader node (1 px lines) over dark clay
wm = bpy.data.materials.new('wire'); wm.use_nodes = True; nt = wm.node_tree; nt.nodes.clear()
wf = nt.nodes.new('ShaderNodeWireframe'); wf.use_pixel_size = True; wf.inputs['Size'].default_value = 1.0
dk = nt.nodes.new('ShaderNodeBsdfDiffuse'); dk.inputs['Color'].default_value = (.06, .06, .08, 1); em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value = (.9, .95, 1, 1)
mx = nt.nodes.new('ShaderNodeMixShader'); o = nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(wf.outputs['Fac'], mx.inputs['Fac']); nt.links.new(dk.outputs[0], mx.inputs[1]); nt.links.new(em.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], o.inputs['Surface'])
for m in meshes: m.data.materials.clear(); m.data.materials.append(wm)
shoot('geo_wire_hood.png', 'S', 20, 768, .75, (0, 0, 1.82)); shoot('geo_wire_boots.png', 'S', 20, 768, .9, (0, 0, .35))
# material / texture diagnostics from the live node tree (restore original materials first)
for m, ms in zip(meshes, saved): m.data.materials.clear(); [m.data.materials.append(x) for x in ms]
md = []
for mat in bpy.data.materials:
    if mat.name == 'clay' or not mat.use_nodes: continue
    nodes = [{'name': n.name, 'type': n.bl_idname, **({'image': n.image.name, 'size': list(n.image.size), 'colorspace': n.image.colorspace_settings.name, 'interp': n.interpolation, 'ext': n.extension} if n.bl_idname == 'ShaderNodeTexImage' and n.image else {}),
              **({'mapping_scale': [round(v, 5) for v in n.inputs['Scale'].default_value], 'mapping_loc': [round(v, 8) for v in n.inputs['Location'].default_value]} if n.bl_idname == 'ShaderNodeMapping' else {})} for n in mat.node_tree.nodes]
    links = [f'{l.from_node.name}.{l.from_socket.name} -> {l.to_node.name}.{l.to_socket.name}' for l in mat.node_tree.links]
    md.append({'material': mat.name, 'blend_method': getattr(mat, 'blend_method', None), 'use_backface_culling': mat.use_backface_culling, 'nodes': nodes, 'links': links})
diag['materials'] = md
diag['uv_range'] = [[round(min(l.uv[0] for l in uv.data), 4), round(max(l.uv[0] for l in uv.data), 4), round(min(l.uv[1] for l in uv.data), 4), round(max(l.uv[1] for l in uv.data), 4)] for m in meshes for uv in m.data.uv_layers[:1]]
diag['tris'] = sum(len(m.data.polygons) for m in meshes); diag['verts'] = sum(len(m.data.vertices) for m in meshes)
thumb = [i for i in bpy.data.images if i.size[0] == 4096][:1]
if thumb:
    t = thumb[0].copy(); t.scale(512, 512); t.filepath_raw = str(out / 'tex_base_color_512.png'); t.file_format = 'PNG'; t.save()
(out / 'diagnostics.json').write_text(json.dumps(diag, indent=1)); print('EVIDENCE_DONE')
