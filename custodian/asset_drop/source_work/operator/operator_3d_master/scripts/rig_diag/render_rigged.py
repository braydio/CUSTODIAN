"""Rig-aware animated renderer (separate from the static asset_pipeline.py, which rejects skins). Same camera contract:
45 deg, 50 px/m ortho (ortho_scale=128/50), root (64,106), 8 unmirrored dirs, ONE uniform scale fitted from the REST-pose S view to 85 px
and held for every frame/direction; grounding/centring computed ONCE from the rest pose (no per-frame root or zoom edits).
usage: blender -b --python render_rigged.py -- <anim.blend> <outdir> [frame_first frame_last]"""
import bpy, sys, os, json, math
import numpy as np
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; blend, out = a[0], a[1]; os.makedirs(out, exist_ok=True)
ELEV, PPM, TARGET = 45.0, 50.0, 85.0; EL = math.radians(ELEV)
AZ = {'N': 180, 'NE': -135, 'E': -90, 'SE': -45, 'S': 0, 'SW': 45, 'W': 90, 'NW': 135}
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene; arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
act = arm.animation_data.action; f0, f1 = (int(a[2]), int(a[3])) if len(a) >= 4 else (int(act.frame_range[0]), int(act.frame_range[1]) - 1)   # last frame duplicates first (loop seam 0.0 deg)
root = bpy.data.objects.new('ASSET_ROOT', None); sc.collection.objects.link(root); arm.parent = root; me.parent = root if me.parent is None else me.parent
def ev_verts():
    dg = bpy.context.evaluated_depsgraph_get(); e = me.evaluated_get(dg); m = e.to_mesh(); v = np.array([me.matrix_world @ x.co for x in m.vertices]); e.to_mesh_clear(); return v
arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis = pb.matrix_basis.__class__()
bpy.context.view_layer.update(); root.scale = (1, 1, 1); root.location = (0, 0, 0); bpy.context.view_layer.update()
v = ev_verts(); lo, hi = v.min(0), v.max(0); raw_h = hi[2] - lo[2]; cx, cy = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
def place(s): root.scale = (s,) * 3; root.location = (-cx * s, -cy * s, -lo[2] * s); bpy.context.view_layer.update()
sc.render.engine = 'BLENDER_EEVEE'; sc.render.film_transparent = True; sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
w = bpy.data.worlds.new('w'); w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (.45, .45, .5, 1); w.node_tree.nodes['Background'].inputs[1].default_value = .8; sc.world = w
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 3.0; sc.collection.objects.link(sun)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); cam.data.type = 'ORTHO'; sc.collection.objects.link(cam); sc.camera = cam
def shoot(d, res, path):
    cam.data.ortho_scale = 128 / PPM; cam.data.shift_y = (106 - 64) / 128; sc.render.resolution_x = sc.render.resolution_y = res; sc.render.filter_size = 0.0 if res == 128 else 1.5
    r = math.radians(AZ[d]); cam.location = (10 * math.sin(r) * math.cos(EL), -10 * math.cos(r) * math.cos(EL), 10 * math.sin(EL))
    cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat('-Z', 'Y').to_euler(); sun.rotation_euler = (math.radians(50), 0, r - math.radians(35))
    sc.render.filepath = str(path); bpy.ops.render.render(write_still=True)
def height_px(path):
    im = bpy.data.images.load(str(path)); b = np.empty(len(im.pixels), np.float32); im.pixels.foreach_get(b); b = b.reshape(im.size[1], im.size[0], 4)[..., 3]; bpy.data.images.remove(im)
    ys = np.where((b > 32 / 255).any(1))[0]; return int(ys.max() - ys.min() + 1)
scale = 1.0; log = []
for _ in range(3):
    place(scale); shoot('S', 128, f'{out}/_probe.png'); h = height_px(f'{out}/_probe.png'); log.append([round(scale, 5), h])
    if abs(h - TARGET) <= .5: break
    scale *= TARGET / h
os.remove(f'{out}/_probe.png'); place(scale)
for d in ('S',): shoot(d, 128, f'{out}/rest_128_S.png')       # rest reference, same scale
arm.animation_data.action = act
heights = {}
for f in range(f0, f1 + 1):
    sc.frame_set(f)
    for res in (128, 512):
        for d in AZ: shoot(d, res, f'{out}/{res}_{d}_{f:02d}.png')
    heights[f] = height_px(f'{out}/128_S_{f:02d}.png')
info = {'raw_rest_height_m': round(float(raw_h), 4), 'applied_scale': round(scale, 5), 'scale_search_[scale,S_height_px]': log, 'frames': [f0, f1], 'S_view_silhouette_height_px_per_frame': heights,
        'S_height_px_min_max': [min(heights.values()), max(heights.values())], 'camera': {'elev_deg': ELEV, 'px_per_m': PPM, 'ortho_scale': 128 / PPM, 'root_px': [64, 106], 'mirroring': False, 'view_transform': sc.view_settings.view_transform}}
json.dump(info, open(f'{out}/render_info.json', 'w'), indent=1); print('RENDER_INFO', json.dumps(info)[:600])
