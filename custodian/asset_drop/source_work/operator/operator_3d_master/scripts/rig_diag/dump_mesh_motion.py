"""Task 015: dump rest + posed (frames 1..21) vertices, triangles, edges, weights, group names, bone head/tail trajectories to an .npz for numpy analysis. Read-only.
usage: blender -b --python dump_mesh_motion.py -- <anim.blend> <out.npz>"""
import bpy, sys, numpy as np, json
blend, out = sys.argv[sys.argv.index('--') + 1:][:2]
bpy.ops.wm.open_mainfile(filepath=blend); sc = bpy.context.scene
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
act = arm.animation_data.action; F = list(range(int(act.frame_range[0]), int(act.frame_range[1])))
def verts():
    dg = bpy.context.evaluated_depsgraph_get(); e = me.evaluated_get(dg); m = e.to_mesh(); v = np.array([me.matrix_world @ x.co for x in m.vertices]); e.to_mesh_clear(); return v
def skin():   # world-space skinning matrices K_b = Aw . (pose_b . rest_b^-1) . Aw^-1 so that posed = sum_b w_b K_b rest_world
    Aw = arm.matrix_world; return np.array([np.array(Aw @ (pb.matrix @ pb.bone.matrix_local.inverted()) @ Aw.inverted()) for pb in arm.pose.bones])
def bones(): return np.array([[(arm.matrix_world @ pb.head)[:], (arm.matrix_world @ pb.tail)[:]] for pb in arm.pose.bones])
arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis = pb.matrix_basis.__class__()
bpy.context.view_layer.update(); rest = verts(); brest = bones(); arm.animation_data.action = act
P = []; B = []; K = []
for f in F: sc.frame_set(f); P.append(verts()); B.append(bones()); K.append(skin())
m = me.data; vg = [g.name for g in me.vertex_groups]
W = np.zeros((len(m.vertices), len(vg)), np.float32)
for v in m.vertices:
    for g in v.groups: W[v.index, g.group] = g.weight
np.savez_compressed(out, rest=rest, posed=np.array(P), frames=np.array(F), tris=np.array([p.vertices[:] for p in m.polygons]), edges=np.array([e.vertices[:] for e in m.edges]), W=W,
                    groups=np.array(vg), bones=np.array([pb.name for pb in arm.pose.bones]), brest=brest, bposed=np.array(B), K=np.array(K), bone_names=np.array([pb.name for pb in arm.pose.bones]), mat=np.array([p.material_index for p in m.polygons]), uv_ok=np.array(len(m.uv_layers)))
print('DUMP', rest.shape, len(F))
