"""Are the detached single-triangle islands visible at REST from any of the 8 contract camera directions? (BVH ray test, 45deg elevation)
usage: blender -b --python island_occlusion.py -- <blend> <report.json>"""
import bpy, sys, json, math, numpy as np
from collections import Counter
from mathutils import Vector
from mathutils.bvhtree import BVHTree
blend, rep = sys.argv[sys.argv.index('--') + 1:][:2]
bpy.ops.wm.open_mainfile(filepath=blend)
me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]; m = me.data; m.calc_loop_triangles()
uses = Counter(); 
for p in m.polygons:
    for v in p.vertices: uses[v] += 1
isl = [p.index for p in m.polygons if all(uses[v] == 1 for v in p.vertices)]
vs = [me.matrix_world @ v.co for v in m.vertices]; polys = [tuple(p.vertices) for p in m.polygons]
bvh = BVHTree.FromPolygons(vs, polys)
EL = math.radians(45); AZ = [180, -135, -90, -45, 0, 45, 90, 135]
dirs = [Vector((math.sin(math.radians(a)) * math.cos(EL), -math.cos(math.radians(a)) * math.cos(EL), math.sin(EL))) for a in AZ]
vis = []; areas = []
for pi in isl:
    p = m.polygons[pi]; c = sum((vs[v] for v in p.vertices), Vector()) / 3; n = 0
    for d in dirs:
        hit = bvh.ray_cast(c + d * 5e-4, d, 5.0)
        if hit[0] is None: n += 1            # nothing between the island and the camera -> visible from this direction
    vis.append(n); areas.append(p.area)
vis = np.array(vis)
r = {'island_triangles': len(isl), 'visible_from_any_of_8_dirs_at_rest': int((vis > 0).sum()), 'visible_from_all_8': int((vis == 8).sum()), 'visible_dirs_histogram': {int(k): int((vis == k).sum()) for k in range(9)},
     'island_area_cm2': float(sum(areas) * 1e4), 'visible_island_area_cm2': float(sum(a for a, v in zip(areas, vis) if v > 0) * 1e4), 'total_triangles': len(m.polygons)}
json.dump(r, open(rep, 'w'), indent=1); print(json.dumps(r, indent=1))
