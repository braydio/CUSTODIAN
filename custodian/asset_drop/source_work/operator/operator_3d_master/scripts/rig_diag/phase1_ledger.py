"""Task 015 Phase 1 (read-only): render beauty + per-triangle face-ID masks with the EXACT run_iter001 camera/scale contract and map visible pixels to triangle IDs.
Outputs per (frame,dir): ledger rows for (a) alpha components disconnected from the main body, (b) pixel clusters belonging to small index-connected mesh components.
usage: blender -b --python phase1_ledger.py -- <anim.blend> <outdir> <res> <frames csv|all (0 = rest pose)> <dirs csv|all> [scale]
No model edits. Frames/IDs are written to <outdir>/ids/{res}_{dir}_{frame:02d}.npy (uint32, 0=background, tri index+1) and beauty PNGs to <outdir>/beauty."""
import bpy, sys, os, json, math
import numpy as np
from mathutils import Vector
from scipy import ndimage
a = sys.argv[sys.argv.index('--') + 1:]; blend, out, RES = a[0], a[1], int(a[2])
AZ = {'N': 180, 'NE': -135, 'E': -90, 'SE': -45, 'S': 0, 'SW': 45, 'W': 90, 'NW': 135}
ELEV, PPM = 45.0, 50.0; EL = math.radians(ELEV)
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene; arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
act = arm.animation_data.action; f0, f1 = int(act.frame_range[0]), int(act.frame_range[1]) - 1
FR = list(range(f0, f1 + 1)) if a[3] == 'all' else [int(x) for x in a[3].split(',')]; DR = list(AZ) if a[4] == 'all' else a[4].split(',')
scale = float(a[5]) if len(a) > 5 else 1.23547
os.makedirs(f'{out}/ids', exist_ok=True); os.makedirs(f'{out}/beauty', exist_ok=True)
root = bpy.data.objects.new('ASSET_ROOT', None); sc.collection.objects.link(root); arm.parent = root; me.parent = root if me.parent is None else me.parent
def ev_verts():
    dg = bpy.context.evaluated_depsgraph_get(); e = me.evaluated_get(dg); m = e.to_mesh(); v = np.array([me.matrix_world @ x.co for x in m.vertices]); e.to_mesh_clear(); return v
arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis = pb.matrix_basis.__class__()
bpy.context.view_layer.update(); root.scale = (1, 1, 1); root.location = (0, 0, 0); bpy.context.view_layer.update()
v = ev_verts(); lo, hi = v.min(0), v.max(0); cx, cy = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
root.scale = (scale,) * 3; root.location = (-cx * scale, -cy * scale, -lo[2] * scale); bpy.context.view_layer.update(); arm.animation_data.action = act
sc.render.engine = 'BLENDER_EEVEE'; sc.render.film_transparent = True; sc.render.dither_intensity = 0.0; sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
w = bpy.data.worlds.new('w'); w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (.45, .45, .5, 1); w.node_tree.nodes['Background'].inputs[1].default_value = .8; sc.world = w
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 3.0; sc.collection.objects.link(sun)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); cam.data.type = 'ORTHO'; sc.collection.objects.link(cam); sc.camera = cam
beauty_vt = sc.view_settings.view_transform
# --- ID material: per-corner BYTE_COLOR encodes tri index+1 in RGB (exact with Standard view transform, 1 sample)
m = me.data; NT = len(m.polygons)
ids = np.arange(1, NT + 1, dtype=np.uint32); rgb = np.stack([ids & 255, (ids >> 8) & 255, (ids >> 16) & 255], 1).astype(np.float32) / 255.0
if 'TRI_ID' in m.color_attributes: m.color_attributes.remove(m.color_attributes['TRI_ID'])
ca = m.color_attributes.new('TRI_ID', 'BYTE_COLOR', 'CORNER')
loop_poly = np.zeros(len(m.loops), np.int64); pstart = np.zeros(NT, np.int64); psz = np.zeros(NT, np.int64)
m.polygons.foreach_get('loop_start', pstart); m.polygons.foreach_get('loop_total', psz)
for p in range(NT): loop_poly[pstart[p]:pstart[p] + psz[p]] = p
cols = np.ones((len(m.loops), 4), np.float32); cols[:, :3] = rgb[loop_poly]
for i, c in enumerate(cols): ca.data[i].color_srgb = c      # exact bytes; shader sees linear, Standard view transform re-encodes to the same bytes
idm = bpy.data.materials.new('IDMAT'); idm.use_nodes = True; nt = idm.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
at = nt.nodes.new('ShaderNodeAttribute'); at.attribute_name = 'TRI_ID'; em = nt.nodes.new('ShaderNodeEmission'); o = nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(at.outputs['Color'], em.inputs['Color']); nt.links.new(em.outputs[0], o.inputs[0])
orig_mats = [s.material for s in me.material_slots]
def set_mode(idmode):
    for s in me.material_slots: s.material = idm if idmode else orig_mats[list(me.material_slots).index(s)]
    sc.view_settings.view_transform = 'Standard' if idmode else beauty_vt; sc.view_settings.look = 'None' if idmode else sc.view_settings.look
    sc.eevee.taa_render_samples = 1 if idmode else sc.eevee.taa_render_samples
    sc.render.filter_size = 0.0 if (idmode or RES == 128) else 1.5
def shoot(d, path):
    cam.data.ortho_scale = 128 / PPM; cam.data.shift_y = (106 - 64) / 128; sc.render.resolution_x = sc.render.resolution_y = RES
    r = math.radians(AZ[d]); cam.location = (10 * math.sin(r) * math.cos(EL), -10 * math.cos(r) * math.cos(EL), 10 * math.sin(EL))
    cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat('-Z', 'Y').to_euler(); sun.rotation_euler = (math.radians(50), 0, r - math.radians(35))
    sc.render.filepath = str(path); bpy.ops.render.render(write_still=True)
def load(path):
    im = bpy.data.images.load(str(path)); b = np.empty(len(im.pixels), np.float32); im.pixels.foreach_get(b); b = b.reshape(im.size[1], im.size[0], 4)[::-1]; bpy.data.images.remove(im); return b
# index-connected components of the mesh (iter-002/003 detach duplicates verts, so detached patches are their own components)
par = list(range(len(m.vertices)))
def fd(x):
    while par[x] != x: par[x] = par[par[x]]; x = par[x]
    return x
pv = [tuple(p.vertices) for p in m.polygons]
for t in pv:
    for u in t[1:]: par[fd(u)] = fd(t[0])
comp = np.array([fd(t[0]) for t in pv]); uc, inv, cnt = np.unique(comp, return_inverse=True, return_counts=True); tri_comp_size = cnt[inv]
ledger = []; ssz = 0
for f in FR:
    if f == 0:   # frame 0 = REST pose (no action, identity pose), same scale/placement
        arm.animation_data.action = None
        for pb in arm.pose.bones: pb.matrix_basis = pb.matrix_basis.__class__()
        bpy.context.view_layer.update()
    else:
        arm.animation_data.action = act; sc.frame_set(f)
    for d in DR:
        set_mode(False); shoot(d, f'{out}/beauty/{RES}_{d}_{f:02d}.png'); B = load(f'{out}/beauty/{RES}_{d}_{f:02d}.png')
        set_mode(True); shoot(d, f'{out}/ids/_id.png'); I = load(f'{out}/ids/_id.png')
        iv = np.round(I[..., 0] * 255).astype(np.uint32) | (np.round(I[..., 1] * 255).astype(np.uint32) << 8) | (np.round(I[..., 2] * 255).astype(np.uint32) << 16)
        iv[I[..., 3] < 0.5] = 0; bad = int((iv > NT).sum()); iv[iv > NT] = 0
        np.save(f'{out}/ids/{RES}_{d}_{f:02d}.npy', iv)
        alpha = iv > 0; lab, n = ndimage.label(alpha, structure=np.ones((3, 3)))
        sizes = ndimage.sum(alpha, lab, range(1, n + 1)); main = int(np.argmax(sizes)) + 1 if n else 0
        lum = (B[..., :3] * [.2126, .7152, .0722]).sum(-1)
        def rows(kind, mask):
            l2, n2 = ndimage.label(mask, structure=np.ones((3, 3)))
            for k in range(1, n2 + 1):
                ys, xs = np.where(l2 == k); tri = np.unique(iv[ys, xs]) - 1
                ledger.append({'frame': f, 'dir': d, 'res': RES, 'kind': kind, 'bbox_xyxy': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())], 'pixels': int(len(xs)), 'visible': True,
                               'mean_luma': round(float(lum[ys, xs].mean()), 3), 'tri_ids': [int(t) for t in tri[:64]], 'n_tris': int(len(tri)), 'tri_comp_sizes': sorted({int(tri_comp_size[t]) for t in tri})[:6]})
        rows('alpha_disconnected_from_main', alpha & (lab != main) if n else alpha)
        rows('small_mesh_component_pixels', alpha & (tri_comp_size[np.clip(iv, 1, NT) - 1] <= 8))
        ssz += bad
json.dump({'scale': scale, 'res': RES, 'n_tris': NT, 'invalid_id_pixels': ssz, 'mesh_component_size_hist': {int(s): int(c) for s, c in zip(*np.unique(cnt, return_counts=True))}, 'rows': ledger}, open(f'{out}/ledger_{RES}.json', 'w'))
print('LEDGER', len(ledger), 'invalid_id_pixels', ssz)
