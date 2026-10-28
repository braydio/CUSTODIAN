"""Task 014 Phase A: retarget the real Mixamo Running.fbx onto the iter-002 corrected rig (world-space delta retarget), bake keys,
sample deformation over the whole clip, save derivative .blend, export GLB with the baked action, re-import and replay.
usage: blender -b --python retarget_run.py -- <iter002.blend> <Running.fbx> <outdir>"""
import bpy, sys, os, json, math, hashlib
import numpy as np
from mathutils import Matrix, Vector, Quaternion
blend, fbx, out = sys.argv[sys.argv.index('--') + 1:][:3]; os.makedirs(out, exist_ok=True)
ACT = 'operator_run_mixamo_iter001'
GROUND_OFFSET = float(os.environ.get('GROUND_OFFSET', '0'))      # ONE constant hips-height offset for the whole clip (recorded in meta); no per-frame root edits
FOLLOW_ON = os.environ.get('FOLLOW', '1') == '1'
# Meshy-only cloth/armour chains have no Mixamo counterpart; without this they stay rigid with Hips while thighs swing. They follow a reference bone's motion at FACTOR.
FOLLOW = {'Bone_005': 'mixamorig:RightUpLeg', 'Bone_004': 'mixamorig:RightUpLeg', 'Bone_012': 'mixamorig:LeftUpLeg', 'Bone_011': 'mixamorig:LeftUpLeg',
          'Bone_010': 'mixamorig:Spine1', 'Bone_009': 'mixamorig:Spine1', 'Bone_008': 'mixamorig:Spine1', 'Bone_007': 'AVG_UPLEG', 'Bone_006': 'AVG_UPLEG', 'Bone_013': 'AVG_UPLEG'}
FACTOR = 0.5
bpy.ops.wm.open_mainfile(filepath=blend)
arm_t = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
sc = bpy.context.scene
def verts():
    dg = bpy.context.evaluated_depsgraph_get(); ev = me.evaluated_get(dg); m = ev.to_mesh()
    a = np.array([me.matrix_world @ v.co for v in m.vertices]); ev.to_mesh_clear(); return a
rest = verts(); nv = len(rest)
edges = np.array([e.vertices[:] for e in me.data.edges]); L0 = np.linalg.norm(rest[edges[:, 0]] - rest[edges[:, 1]], axis=1) + 1e-9
vg = [g.name for g in me.vertex_groups]; dom = np.array([max(v.groups, key=lambda g: g.weight).group for v in me.data.vertices])
before = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=fbx, automatic_bone_orientation=False)
arm_f = [o for o in bpy.data.objects if o not in before and o.type == 'ARMATURE'][0]
src_act = arm_f.animation_data.action
fr0, fr1 = [int(x) for x in src_act.frame_range]
meta = {'arm_retarget': 'joint-direction matching (Arm, ForeArm); wrist keeps rest relation to forearm; other bones world-delta', 'ground_offset_m_constant': GROUND_OFFSET, 'follow_chains': FOLLOW if FOLLOW_ON else None, 'follow_factor': FACTOR, 'fbx_fps': sc.render.fps, 'fbx_action': src_act.name, 'fbx_frames': [fr0, fr1], 'fbx_bones': len(arm_f.data.bones), 'target_bones': len(arm_t.data.bones)}
names_f = {b.name for b in arm_f.data.bones}; mapped = [b for b in arm_t.data.bones if b.name in names_f]
meta['mapped_bones'] = len(mapped); meta['unmapped_target_bones(follow parent, no motion)'] = sorted(b.name for b in arm_t.data.bones if b.name not in names_f)
meta['fbx_only_bones_ignored'] = len(names_f - {b.name for b in arm_t.data.bones})
rot = lambda M: M.to_3x3().normalized()
Rrest_t = {b.name: rot(arm_t.matrix_world @ b.matrix_local) for b in arm_t.data.bones}
Rrest_f = {b.name: rot(arm_f.matrix_world @ b.matrix_local) for b in arm_f.data.bones}
hips_t = (arm_t.matrix_world @ arm_t.data.bones['mixamorig:Hips'].head_local).copy(); hips_f = (arm_f.matrix_world @ arm_f.data.bones['mixamorig:Hips'].head_local).copy()
k = hips_t.z / hips_f.z; meta['hips_height_target_m'] = round(hips_t.z, 4); meta['hips_height_fbx_m'] = round(hips_f.z, 4); meta['translation_scale'] = round(k, 4)
ARM_CHILD = {'mixamorig:RightArm': 'mixamorig:RightForeArm', 'mixamorig:RightForeArm': 'mixamorig:RightHand', 'mixamorig:LeftArm': 'mixamorig:LeftForeArm', 'mixamorig:LeftForeArm': 'mixamorig:LeftHand'}
HAND_OF = {'mixamorig:RightHand': 'mixamorig:RightForeArm', 'mixamorig:LeftHand': 'mixamorig:LeftForeArm'}
depth = lambda b: len(b.parent_recursive)
order = sorted(mapped, key=depth)
for pb in arm_t.pose.bones: pb.rotation_mode = 'QUATERNION'; pb.matrix_basis = Matrix()
mod = [m for m in me.modifiers if m.type == 'ARMATURE']; [setattr(m, 'show_viewport', False) for m in mod]
frames = list(range(fr0, fr1 + 1)); store = {}; fbx_rot = {}
for f in frames:
    sc.frame_set(f); bpy.context.view_layer.update(); fbx_rot[f] = {n: rot(arm_f.matrix_world @ arm_f.pose.bones[n].matrix) for n in names_f}
    RtW = {}
    for b in order:
        Mp = arm_f.matrix_world @ arm_f.pose.bones[b.name].matrix
        Rt = (rot(Mp) @ Rrest_f[b.name].inverted()) @ Rrest_t[b.name]
        side = 'Right' if 'Right' in b.name else 'Left'
        if b.name in ARM_CHILD:      # T-pose clip on an A-pose rig: match joint DIRECTIONS (shoulder>elbow>wrist) instead of copying world deltas
            ch = ARM_CHILD[b.name]; dsrc = (arm_f.matrix_world @ arm_f.pose.bones[ch].head) - (arm_f.matrix_world @ arm_f.pose.bones[b.name].head)
            drest = (arm_t.matrix_world @ arm_t.data.bones[ch].head_local) - (arm_t.matrix_world @ arm_t.data.bones[b.name].head_local)
            Rt = drest.rotation_difference(dsrc).to_matrix() @ Rrest_t[b.name]
        elif b.name in HAND_OF:      # wrist: keep the target's rest relation to the forearm (no wrist motion transferred)
            fa = HAND_OF[b.name]; Rt = RtW[fa] @ (Rrest_t[fa].inverted() @ Rrest_t[b.name])
        RtW[b.name] = Rt
        pbt = arm_t.pose.bones[b.name]
        tr = hips_t + (Mp.translation - hips_f) * k + Vector((0, 0, GROUND_OFFSET)) if b.name == 'mixamorig:Hips' else pbt.matrix.translation.copy()
        pbt.matrix = Matrix.Translation(tr) @ Rt.to_4x4(); bpy.context.view_layer.update()
    if FOLLOW_ON:
        delta = {b.name: rot(arm_f.matrix_world @ arm_f.pose.bones[b.name].matrix) @ Rrest_f[b.name].inverted() for b in mapped}
        fb = sorted([arm_t.data.bones[n] for n in FOLLOW], key=depth)
        for b in fb:
            ref = FOLLOW[b.name]
            if ref == 'AVG_UPLEG': q = delta['mixamorig:LeftUpLeg'].to_quaternion().slerp(delta['mixamorig:RightUpLeg'].to_quaternion(), 0.5)
            else: q = delta[ref].to_quaternion()
            q = Quaternion((1, 0, 0, 0)).slerp(q, FACTOR); pbt = arm_t.pose.bones[b.name]
            pbt.matrix = Matrix.Translation(pbt.matrix.translation.copy()) @ (q.to_matrix() @ Rrest_t[b.name]).to_4x4(); bpy.context.view_layer.update()
    store[f] = {pb.name: (pb.location.copy(), pb.rotation_quaternion.copy()) for pb in arm_t.pose.bones}
# loop seam on the SOURCE motion
ang = lambda a, b: math.degrees((a @ b.inverted()).to_quaternion().angle)
seam = max(ang(fbx_rot[fr1][n], fbx_rot[fr0][n]) for n in names_f); step = np.mean([max(ang(fbx_rot[f + 1][n], fbx_rot[f][n]) for n in names_f) for f in range(fr0, fr1)])
meta['loop_seam_max_bone_deg_last_vs_first'] = round(seam, 3); meta['mean_per_frame_max_bone_step_deg'] = round(float(step), 3)
# drop the FBX armature, bake our action
fa = arm_f.animation_data.action
bpy.data.objects.remove(arm_f, do_unlink=True); bpy.data.actions.remove(fa)
for pb in arm_t.pose.bones: pb.matrix_basis = Matrix()
arm_t.animation_data_create(); act = bpy.data.actions.new(ACT); arm_t.animation_data.action = act
for f in frames:
    for pb in arm_t.pose.bones:
        loc, q = store[f][pb.name]; pb.location = loc; pb.rotation_quaternion = q
        pb.keyframe_insert('location', frame=f); pb.keyframe_insert('rotation_quaternion', frame=f)
[setattr(m, 'show_viewport', True) for m in mod]
sc.frame_start, sc.frame_end = fr0, fr1; sc.render.fps = 30; sc.render.fps_base = 1.0
fcs = [fc for l in act.layers for st in l.strips for cb in st.channelbags for fc in cb.fcurves]
meta['baked_action'] = ACT; meta['baked_fcurves'] = len(fcs); meta['baked_keyframes'] = sum(len(fc.keyframe_points) for fc in fcs); meta['baked_frame_range'] = [fr0, fr1]
# ---- whole-clip deformation sampling
region = lambda sub: np.array([any(t in vg[d] for t in sub) for d in dom])
hand_m = region(('Hand',)); foot_m = region(('Foot', 'Toe')); tab_m = region(('Bone_006', 'Bone_007', 'Bone_013'))
PER = []; V = {}
for f in frames:
    sc.frame_set(f); v = verts(); V[f] = v
    L = np.linalg.norm(v[edges[:, 0]] - v[edges[:, 1]], axis=1); r = L / L0
    worst = np.argsort(-r)[:20]
    PER.append({'frame': f, 'max': float(r.max()), 'p999': float(np.percentile(r, 99.9)), 'gt1.5': int((r > 1.5).sum()), 'gt3': int((r > 3).sum()), 'worst_edge_bone_pairs': sorted({f'{vg[dom[edges[e,0]]]}|{vg[dom[edges[e,1]]]}' for e in worst})[:4],
                'min_z': float(v[:, 2].min()), 'max_z': float(v[:, 2].max()), 'bbox_xy': [float(v[:, 0].min()), float(v[:, 0].max()), float(v[:, 1].min()), float(v[:, 1].max())],
                'foot_min_z': float(v[foot_m, 2].min()), 'foot_min_xyz': v[foot_m][np.argmin(v[foot_m, 2])].round(4).tolist(),
                'hand_spike_max_mm': float(np.linalg.norm(v[hand_m] - rest[hand_m], axis=1).max() * 1000)})
# hand spike metric: how far hand-region verts sit from the (moving) hand-region centroid, vs rest
rc = rest[hand_m].mean(0); rest_spread = np.linalg.norm(rest[hand_m] - rc, axis=1).max()
spread = [float(np.linalg.norm(V[f][hand_m] - V[f][hand_m].mean(0), axis=1).max()) for f in frames]
# foot contact / skating: for the lowest foot vertex (stance), horizontal speed (m/s) per frame pair while within 2 cm of the ground
fz = np.array([p['foot_min_z'] for p in PER]); spd = {}
for side in ('Left', 'Right'):
    m = np.array([side in vg[d] and ('Foot' in vg[d] or 'Toe' in vg[d]) for d in dom]); lo = np.array([V[f][m][np.argmin(V[f][m, 2])] for f in frames]); z = lo[:, 2]
    st = z < z.min() + 0.03; sp = [float(np.linalg.norm(lo[i + 1, :2] - lo[i, :2]) * 30) for i in range(len(frames) - 1) if st[i] and st[i + 1]]
    spd[side] = {'stance_frames': int(st.sum()), 'pairs': len(sp), 'speed_mps_min_max_mean': [min(sp), max(sp), float(np.mean(sp))] if sp else None, 'lowest_z_range_m': [float(z.min()), float(z.max())]}
# penetration: hand verts vs non-arm body (BVH nearest-face signed distance)
import bmesh
from mathutils.bvhtree import BVHTree
def pen(frame):
    sc.frame_set(frame); dg = bpy.context.evaluated_depsgraph_get(); ev = me.evaluated_get(dg); m = ev.to_mesh(); m.calc_loop_triangles()
    vs = [me.matrix_world @ v.co for v in m.vertices]; tris = [t for t in m.loop_triangles if not hand_m[t.vertices[0]] and not hand_m[t.vertices[1]] and not hand_m[t.vertices[2]]
                                                                and not any(vg[dom[i]].find('Arm') >= 0 or vg[dom[i]].find('Shoulder') >= 0 for i in t.vertices)]
    bvh = BVHTree.FromPolygons(vs, [tuple(t.vertices) for t in tris]); nrm = {tuple(t.vertices): t.normal for t in tris}
    depths = []
    for i in np.where(hand_m)[0]:
        loc, n, idx, dist = bvh.find_nearest(vs[i], 0.02)
        if loc is not None:
            d = (vs[i] - loc).dot(n)
            if d < 0: depths.append(-d)
    ev.to_mesh_clear(); return (len(depths), max(depths) * 1000 if depths else 0.0)
sc.frame_set(fr0); pen_rest = None
for pb in arm_t.pose.bones: pass
pen_frames = {f: pen(f) for f in (fr0, fr0 + 5, fr0 + 10, fr0 + 15, fr1)}
seam_disp = float(np.linalg.norm(V[fr1] - V[fr0], axis=1).max() * 1000); step_disp = float(np.mean([np.linalg.norm(V[f + 1] - V[f], axis=1).max() for f in range(fr0, fr1)]) * 1000)
W = {'per_frame': PER, 'summary': {'max_edge_stretch_over_clip': max(p['max'] for p in PER), 'worst_frame': max(PER, key=lambda p: p['max'])['frame'], 'max_p999_over_clip': max(p['p999'] for p in PER),
      'max_edges_gt1.5x_in_a_frame': max(p['gt1.5'] for p in PER), 'max_edges_gt3x_in_a_frame': max(p['gt3'] for p in PER), 'frames_with_any_gt3x': [p['frame'] for p in PER if p['gt3']],
      'rest_min_z_m': float(rest[:, 2].min()), 'clip_min_z_m': min(p['min_z'] for p in PER), 'clip_max_z_m': max(p['max_z'] for p in PER),
      'foot_lowest_z_range_m': [float(fz.min()), float(fz.max())], 'per_foot_stance': spd,
      'hand_region_spread_m': {'rest': float(rest_spread), 'clip_max': max(spread), 'clip_min': min(spread)}, 'hand_penetration_(count_of_hand_verts_<=2cm_inside, max_depth_mm)': {str(k_): v for k_, v in pen_frames.items()},
      'loop_seam_vertex_displacement_mm_last_vs_first': seam_disp, 'mean_vertex_step_mm_per_frame': step_disp, 'rest_pose_unchanged_check_note': 'rest edge lengths from frame-less rest evaluation before baking'}}
json.dump({'meta': meta, 'deformation': W}, open(f'{out}/retarget_and_deformation.json', 'w'), indent=1, default=lambda o: o.item() if hasattr(o, 'item') else str(o))
sc.frame_set(fr0); bpy.ops.wm.save_as_mainfile(filepath=f'{out}/{ACT}.blend')
# ---- export GLB with the baked action, re-import clean, replay
glb = f'{out}/{ACT}.glb'
bpy.ops.object.select_all(action='DESELECT'); arm_t.select_set(True); me.select_set(True); bpy.context.view_layer.objects.active = arm_t
bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', use_selection=True, export_animations=True, export_skins=True, export_yup=True, export_frame_range=True, export_force_sampling=True)
ref12 = V[fr0 + 10]
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb)
a2 = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; m2 = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
sc2 = bpy.context.scene
act2 = [a for a in bpy.data.actions]
fr = act2[0].frame_range if act2 else None
sc2.frame_set(int(fr[0] + 10 * sc2.render.fps / 30.0), subframe=(fr[0] + 10 * sc2.render.fps / 30.0) % 1)
dg = bpy.context.evaluated_depsgraph_get(); ev = m2.evaluated_get(dg); mm = ev.to_mesh(); rv = np.array([m2.matrix_world @ v.co for v in mm.vertices]); ev.to_mesh_clear()
from scipy.spatial import cKDTree
d = cKDTree(rv).query(ref12)[0]
chk = {'glb': os.path.basename(glb), 'glb_sha256': hashlib.sha256(open(glb, 'rb').read()).hexdigest(), 'glb_bytes': os.path.getsize(glb), 'reimport_actions': [(a.name, list(map(float, a.frame_range))) for a in act2],
       'reimport_bones': len(a2.data.bones), 'reimport_verts': len(m2.data.vertices), 'reimport_tris': len(m2.data.polygons), 'uv': [u.name for u in m2.data.uv_layers], 'images': {i.name: list(i.size) for i in bpy.data.images if i.name != 'Render Result'},
       'replay_frame_offset10_max_vertex_diff_mm_vs_blend': float(d.max() * 1000), 'replay_p99_mm': float(np.percentile(d, 99) * 1000), 'scene_fps_after_import': sc2.render.fps}
json.dump(chk, open(f'{out}/export_reimport.json', 'w'), indent=1); print(json.dumps({'meta': meta, 'summary': W['summary'], 'reimport': chk}, indent=1, default=str)[:6000])
