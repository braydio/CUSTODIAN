"""Rig deformation diagnostic for meshy-004_rigged. Labeled SYNTHETIC diagnostic poses (not a run cycle).
usage: blender -b --python pose_proof.py -- <glb> <outdir>
Builds baseline + derivative (localized reparenting, world rest pose preserved), poses both, writes metrics.json + renders."""
import bpy, sys, json, math, os
import numpy as np
from mathutils import Matrix, Vector, Euler
glb = out = None   # set by main() or by importing scripts

# bone -> new parent. Evidence: joint world positions + weighted vertex heights (see REPORT.md)
FIXES = {
    'Bone_013': 'Bone_006',                                   # front tabard chain 007>006>013 was parented to Head
    'Bone_023': 'mixamorig:LeftFoot',  'Bone_027': 'mixamorig:LeftFoot',   # foot-level joints were under Left hand/forearm
    'Bone_018': 'mixamorig:RightFoot', 'Bone_028': 'mixamorig:RightFoot',  # ... and under Right hand/forearm
}
POSES = {  # (bone, world axis, degrees); SYNTHETIC diagnostic poses
    'P1_arms_elbows': [('mixamorig:LeftArm', 'X', 50), ('mixamorig:RightArm', 'X', -50), ('mixamorig:LeftForeArm', 'X', 60), ('mixamorig:RightForeArm', 'X', 60)],
    'P2_legs_knees_ankles': [('mixamorig:LeftUpLeg', 'X', 35), ('mixamorig:LeftLeg', 'X', -60), ('mixamorig:LeftFoot', 'X', 25), ('mixamorig:RightUpLeg', 'X', -25), ('mixamorig:RightFoot', 'X', -20)],
    'P3_wrists': [('mixamorig:LeftHand', 'X', 45), ('mixamorig:RightHand', 'Y', 50), ('mixamorig:LeftForeArm', 'X', 20)],
    'P4_head_turn': [('mixamorig:Head', 'Z', 40), ('mixamorig:Neck', 'X', 15)],
}

def load():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb)
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
    return arm, me

def reparent(arm):
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    for b, p in FIXES.items():
        h, t, roll = eb[b].head.copy(), eb[b].tail.copy(), eb[b].roll
        eb[b].parent = eb[p]; eb[b].use_connect = False
        eb[b].head, eb[b].tail, eb[b].roll = h, t, roll
    bpy.ops.object.mode_set(mode='OBJECT')

def pose(arm, ops):
    for pb in arm.pose.bones: pb.matrix_basis = Matrix()
    bpy.context.view_layer.update()
    order = {b.name: i for i, b in enumerate(arm.data.bones)}
    for name, ax, deg in ops:
        pb = arm.pose.bones[name]
        p = arm.matrix_world @ pb.head
        R = Matrix.Rotation(math.radians(deg), 4, ax)
        pb.matrix = Matrix.Translation(p) @ R @ Matrix.Translation(-p) @ pb.matrix   # world-axis rotation about the joint
        bpy.context.view_layer.update()

def verts(me):
    dg = bpy.context.evaluated_depsgraph_get(); ev = me.evaluated_get(dg)
    m = ev.to_mesh(); a = np.array([me.matrix_world @ v.co for v in m.vertices]); ev.to_mesh_clear(); return a

CLEANUP = None   # optional callable(me) applied for variant 'corrected' (iter-002)

def analyse(variant):
    arm, me = load()
    if variant in ('fixed', 'corrected'): reparent(arm)
    if variant == 'corrected': CLEANUP(me)
    bpy.context.view_layer.update()
    rest = verts(me)
    edges = np.array([e.vertices[:] for e in me.data.edges]); L0 = np.linalg.norm(rest[edges[:, 0]] - rest[edges[:, 1]], axis=1) + 1e-9
    z = rest[:, 2]
    vg = me.vertex_groups
    dom = [max(v.groups, key=lambda g: g.weight).group for v in me.data.vertices]
    dom_name = lambda i: vg[dom[i]].name
    regions = {'boots(z<0.10)': z < 0.10, 'hands(z 0.6-0.95,|x|>0.25)': (z > .6) & (z < .95) & (np.abs(rest[:, 0]) > .25), 'tabard(z 0.37-0.73,|x|<0.2)': (z > .37) & (z < .73) & (np.abs(rest[:, 0]) < .2)}
    res = {'min_rest_edge_mm': float(L0.min() * 1000), 'poses': {}}
    outv = {'rest': rest}
    for name, ops in POSES.items():
        pose(arm, ops); v = verts(me); outv[name] = v
        d = np.linalg.norm(v - rest, axis=1)
        L = np.linalg.norm(v[edges[:, 0]] - v[edges[:, 1]], axis=1); r = L / L0
        worst = np.argsort(-r)[:200]
        from collections import Counter
        wc = Counter(f'{dom_name(edges[i,0])}|{dom_name(edges[i,1])}' for i in worst)
        res['poses'][name] = {'worst200_edge_dominant_bone_pairs': wc.most_common(6), 'edge_stretch_max': float(r.max()), 'edge_stretch_p999': float(np.percentile(r, 99.9)), 'edges_gt1.5x': int((r > 1.5).sum()), 'edges_gt3x': int((r > 3).sum()),
                              'region_mean_disp_m': {k: float(d[m].mean()) for k, m in regions.items()}, 'region_max_disp_m': {k: float(d[m].max()) for k, m in regions.items()}}
    pose(arm, []); render_set(variant, arm, me, out)
    return res, outv, me, arm

def render_set(variant, arm, me, out):
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'TEXTURE'; sc.display.shading.show_cavity = False
    sc.render.film_transparent = False; sc.world = bpy.data.worlds.new('w'); sc.world.color = (.24, .25, .28)
    sc.render.resolution_x = sc.render.resolution_y = 700; sc.render.image_settings.file_format = 'PNG'
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.type = 'ORTHO'
    def shoot(tag, loc, target, ortho):
        cam.data.ortho_scale = ortho; cam.location = loc
        cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = f'{out}/{variant}_{tag}.png'; bpy.ops.render.render(write_still=True)
    for name, ops in POSES.items():
        pose(arm, ops)
        shoot(name + '_full34', (2.2, -3.0, 1.6), (0, 0, .95), 2.3)
        if name in ('P1_arms_elbows', 'P3_wrists'):
            shoot(name + '_hands', (1.5, -2.0, 1.0), (.35, 0, .55), 1.4)
        if name in ('P2_legs_knees_ankles', 'P1_arms_elbows'):
            shoot(name + '_feet', (1.5, -2.0, .55), (.2, 0, .1), 1.1)
        if name == 'P4_head_turn':
            shoot(name + '_tabard', (1.5, -2.2, .9), (0, 0, .6), 1.4)
    pose(arm, [])

def main():
    global glb, out
    glb, out = sys.argv[sys.argv.index('--') + 1:][:2]
    os.makedirs(out, exist_ok=True)
    _main()

def _main():
  R = {}; V = {}
  for var in ('baseline', 'fixed'):
      R[var], V[var], _, _ = analyse(var)
  R['rest_pose_change_max_m'] = float(np.abs(V['fixed']['rest'] - V['baseline']['rest']).max())
  R['reparented'] = FIXES
  json.dump(R, open(f'{out}/metrics.json', 'w'), indent=1); print(json.dumps(R, indent=1))

if __name__ == '__main__' and '--' in sys.argv:
    main()
