import bpy, sys, json, numpy as np
from collections import Counter
blend = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.open_mainfile(filepath=blend); sc = bpy.context.scene
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
def verts():
    dg = bpy.context.evaluated_depsgraph_get(); e = me.evaluated_get(dg); m = e.to_mesh(); v = np.array([me.matrix_world @ x.co for x in m.vertices]); e.to_mesh_clear(); return v
act = arm.animation_data.action; arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis = pb.matrix_basis.__class__()
bpy.context.view_layer.update(); rest = verts(); arm.animation_data.action = act
edges = np.array([e.vertices[:] for e in me.data.edges]); L0 = np.linalg.norm(rest[edges[:, 0]] - rest[edges[:, 1]], axis=1)
vg = [g.name for g in me.vertex_groups]; W = [{vg[g.group]: round(g.weight, 2) for g in v.groups if g.weight > 0.02} for v in me.data.vertices]
dom = [max(w, key=w.get) for w in W]
cnt = Counter(); persistent = Counter(); vcount = Counter()
for f in range(1, 22):
    sc.frame_set(f); v = verts(); r = np.linalg.norm(v[edges[:, 0]] - v[edges[:, 1]], axis=1) / L0
    for e in np.where(r > 3)[0]:
        pair = '|'.join(sorted((dom[edges[e, 0]], dom[edges[e, 1]]))); cnt[pair] += 1; persistent[int(e)] += 1
        for k in edges[e]: vcount[int(k)] += 1
print('pair counts over 21 frames:', cnt.most_common(12))
print('edges >3x in >=15 of 21 frames:', sum(1 for c in persistent.values() if c >= 15), 'distinct edges ever >3x:', len(persistent))
top = [k for k, _ in vcount.most_common(8)]
for k in top: print('vert', k, 'rest', rest[k].round(3).tolist(), 'weights', W[k])
sc.frame_set(13); v = verts(); r = np.linalg.norm(v[edges[:, 0]] - v[edges[:, 1]], axis=1) / L0
for e in np.argsort(-r)[:6]: print('f13 edge', int(e), 'ratio %.2f rest %.1fmm' % (r[e], L0[e] * 1000), 'rest_z %.2f' % rest[edges[e, 0]][2], [W[k] for k in edges[e]])
