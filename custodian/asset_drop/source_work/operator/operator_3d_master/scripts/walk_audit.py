#!/usr/bin/env python3
"""Run in Blender: blender -b X.blend --python scripts/walk_audit.py -- out.json
Measures the evaluated boot-sole meshes per frame (not IK reach error): sole min Z, heel/toe Z, sole centroid, hip height."""
import json, sys, bpy
out = sys.argv[sys.argv.index('--') + 1]
scene = bpy.context.scene; rig = bpy.data.objects['RIG__Operator_3D']
def snap():
    dg = bpy.context.evaluated_depsgraph_get(); r = {}
    for s in 'LR':
        o = bpy.data.objects[f'Boot_{s}__sole'].evaluated_get(dg)
        vs = [o.matrix_world @ v.co for v in o.data.vertices]
        ys = sorted(v.y for v in vs); front = [v for v in vs if v.y <= ys[len(ys) // 4]]; back = [v for v in vs if v.y >= ys[3 * len(ys) // 4]]
        r[s] = {'min_z': min(v.z for v in vs), 'toe_min_z': min(v.z for v in front), 'heel_min_z': min(v.z for v in back),
                'cx': sum(v.x for v in vs) / len(vs), 'cy': sum(v.y for v in vs) / len(vs)}
    ev = rig.evaluated_get(dg); r['hips_z'] = (ev.matrix_world @ ev.pose.bones['Hips'].head).z
    return r
res = {'frames': []}
for f in range(1, 16):
    scene.frame_set(f); bpy.context.view_layer.update(); res['frames'].append(snap())
json.dump(res, open(out, 'w'), indent=1)
