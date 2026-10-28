"""Task 015: dense REST-pose visibility of given triangles (BVH ray test from a Fibonacci sphere of directions, 3 sample points per triangle).
A triangle is 'visible from a direction' if an offset ray along that direction escapes the mesh. Read-only.
usage: blender -b --python hidden_test.py -- <anim.blend> <tris.json (list of tri idx)> <out.json> [n_dirs]"""
import bpy, sys, json, math, numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
a = sys.argv[sys.argv.index('--') + 1:]; blend, tj, out = a[:3]; N = int(a[3]) if len(a) > 3 else 200
bpy.ops.wm.open_mainfile(filepath=blend)
me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]; arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
arm.animation_data.action = None
for pb in arm.pose.bones: pb.matrix_basis = pb.matrix_basis.__class__()
bpy.context.view_layer.update(); m = me.data
vs = [me.matrix_world @ v.co for v in m.vertices]; polys = [tuple(p.vertices) for p in m.polygons]; bvh = BVHTree.FromPolygons(vs, polys)
i = np.arange(N) + .5; ph = np.arccos(1 - 2 * i / N); th = math.pi * (1 + 5 ** .5) * i; D = [Vector((math.cos(t) * math.sin(p), math.sin(t) * math.sin(p), math.cos(p))) for t, p in zip(th, ph)]
res = {}
for ti in json.load(open(tj)):
    p = polys[ti]; c = sum((vs[v] for v in p), Vector()) / 3; pts = [c] + [c * .6 + vs[v] * .4 for v in p]; vis = 0
    for d in D:
        if any(bvh.ray_cast(q + d * 3e-4, d, 10.0)[0] is None for q in pts): vis += 1
    res[ti] = vis
json.dump({'n_dirs': N, 'visible_dir_count': res}, open(out, 'w')); print('HIDDEN', sum(1 for v in res.values() if v == 0), 'of', len(res))
