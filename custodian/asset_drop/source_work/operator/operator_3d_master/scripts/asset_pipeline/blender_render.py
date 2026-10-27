"""Run inside Blender: blender -b --python blender_render.py -- ASSET.glb OUT_DIR ELEV_DEG PX_PER_M TARGET_S_HEIGHT_PX
Imports an (uncompressed) GLB, grounds it (min Z=0, xy centred), scales it ONCE so the S view at the common projection is TARGET px tall,
then renders the 8 unmirrored directions at native 128 and 512 with the asset's own materials. Same camera model as create_blend.py:
orthographic, ortho_scale=128/px_per_m, root at (64,106). Prints PIPELINE_JSON {...}."""
import json, math, pathlib, sys
import bpy, numpy as np
from mathutils import Vector
glb, out, elev, ppm, target = sys.argv[sys.argv.index('--') + 1:][:5]; out = pathlib.Path(out); out.mkdir(parents=True, exist_ok=True)
elev, ppm, target = float(elev), float(ppm), float(target); EL = math.radians(elev)
AZ = {'N': 180, 'NE': -135, 'E': -90, 'SE': -45, 'S': 0, 'SW': 45, 'W': 90, 'NW': 135}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
meshes = [x for x in bpy.data.objects if x.type == 'MESH']
if not meshes: raise SystemExit('no mesh in asset')
root = bpy.data.objects.new('ASSET_ROOT', None); bpy.context.scene.collection.objects.link(root)
for o in [x for x in bpy.data.objects if x.parent is None and x is not root]: o.parent = root   # root is identity now, so world transforms (incl. glTF node scale) are preserved
broken = [i.name for i in bpy.data.images if i.name != 'Render Result' and (i.size[0] == 0 or i.size[1] == 0)]
if broken: print('PIPELINE_ERROR texture image(s) failed to decode: ' + ', '.join(broken)); sys.exit(2)
def bbox():
    bpy.context.view_layer.update(); pts = [m.matrix_world @ Vector(c) for m in meshes for c in m.bound_box]
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]
def place(scale):
    root.scale = (scale,) * 3; root.location = (0, 0, 0); lo, hi = bbox()
    root.location = (-(lo[0] + hi[0]) / 2, -(lo[1] + hi[1]) / 2, -lo[2]); return bbox()
sc = bpy.context.scene; sc.render.engine = 'BLENDER_EEVEE'; sc.render.film_transparent = True
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
w = bpy.data.worlds.new('w'); w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (.45, .45, .5, 1); w.node_tree.nodes['Background'].inputs[1].default_value = .8; sc.world = w
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 3.0; sc.collection.objects.link(sun)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); cam.data.type = 'ORTHO'; sc.collection.objects.link(cam); sc.camera = cam
def shoot(d, res, path):
    cam.data.ortho_scale = 128 / ppm; cam.data.shift_y = (106 - 64) / 128; sc.render.resolution_x = sc.render.resolution_y = res; sc.render.filter_size = 0.0 if res == 128 else 1.5
    r = math.radians(AZ[d]); cam.location = (10 * math.sin(r) * math.cos(EL), -10 * math.cos(r) * math.cos(EL), 10 * math.sin(EL))
    cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat('-Z', 'Y').to_euler(); sun.rotation_euler = (math.radians(50), 0, r - math.radians(35))
    sc.render.filepath = str(path); bpy.ops.render.render(write_still=True)
def height_px(path):
    im = bpy.data.images.load(str(path)); a = np.empty(len(im.pixels), np.float32); im.pixels.foreach_get(a); a = a.reshape(im.size[1], im.size[0], 4)[..., 3]; bpy.data.images.remove(im)
    ys = np.where((a > 32 / 255).any(1))[0]; return int(ys.max() - ys.min() + 1)
lo, hi = place(1.0); raw_h = hi[2] - lo[2]; scale = 1.0; log = []
for _ in range(3):                                    # measure the S silhouette at the common projection and correct the single scale
    place(scale); shoot('S', 128, out / '_probe.png'); h = height_px(out / '_probe.png'); log.append([round(scale, 5), h])
    if abs(h - target) <= .5: break
    scale *= target / h
(out / '_probe.png').unlink()
lo, hi = place(scale)
for res in (128, 512):
    for d in AZ: shoot(d, res, out / f'{res}_{d}.png')
info = {'raw_height_m': round(raw_h, 4), 'applied_scale': round(scale, 5), 'normalised_height_m': round(hi[2] - lo[2], 4), 'normalised_dims_m': [round(hi[i] - lo[i], 4) for i in range(3)],
        'scale_search_[scale,S_height_px]': log, 'verts': sum(len(m.data.vertices) for m in meshes), 'tris': sum(len(m.data.polygons) for m in meshes),
        'uv_layers': [u.name for m in meshes for u in m.data.uv_layers], 'images': [[i.name, list(i.size)] for i in bpy.data.images if i.name != 'Render Result']}
print('PIPELINE_JSON' + json.dumps(info))
