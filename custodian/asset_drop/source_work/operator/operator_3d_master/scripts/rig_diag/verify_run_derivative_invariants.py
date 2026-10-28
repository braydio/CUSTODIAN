"""Compare rest geometry, skin weights, rig and materials across run derivatives.

Usage: blender -b <baseline.blend> --python verify_run_derivative_invariants.py -- <candidate.blend> <report.json>
"""
import bpy, sys, json, hashlib
import numpy as np
from mathutils import Matrix

candidate_path, out = sys.argv[sys.argv.index('--') + 1:]

def snapshot(label):
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    mesh = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
    action = arm.animation_data.action if arm.animation_data else None
    if arm.animation_data:
        arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix()
    bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get(); ev=mesh.evaluated_get(dg); em=ev.to_mesh()
    points=np.asarray([mesh.matrix_world @ v.co for v in em.vertices],dtype=np.float64); ev.to_mesh_clear()
    weight_rows=[]
    for vertex in mesh.data.vertices:
        weight_rows.append(sorted((mesh.vertex_groups[g.group].name,round(float(g.weight),8)) for g in vertex.groups))
    faces=[tuple(int(x) for x in p.vertices) for p in mesh.data.polygons]
    mats=[s.material.name if s.material else None for s in mesh.material_slots]
    data={'label':label,'vertices':len(mesh.data.vertices),'triangles':len(mesh.data.polygons),
          'bones':sorted(b.name for b in arm.data.bones),'uv_layers':[u.name for u in mesh.data.uv_layers],
          'materials':mats,'action_name':action.name if action else None,
          'action_range':[float(x) for x in action.frame_range] if action else None,
          'rest_positions_sha256':hashlib.sha256(points.tobytes()).hexdigest(),
          'skin_weights_sha256':hashlib.sha256(json.dumps(weight_rows,separators=(',',':')).encode()).hexdigest(),
          'face_topology_sha256':hashlib.sha256(json.dumps(faces,separators=(',',':')).encode()).hexdigest()}
    if arm.animation_data:
        arm.animation_data.action=action
    return data

baseline=snapshot('iter002')
bpy.ops.wm.open_mainfile(filepath=candidate_path)
candidate=snapshot('iter003')
same={k:baseline[k]==candidate[k] for k in ('vertices','triangles','bones','uv_layers','materials','rest_positions_sha256','skin_weights_sha256','face_topology_sha256')}
out_data={'schema':'custodian.operator_run_derivative_invariants.v1','baseline':baseline,'candidate':candidate,'invariants_equal':same}
json.dump(out_data,open(out,'w'),indent=2)
print(json.dumps({'invariants_equal':same,'baseline_action':baseline['action_name'],'candidate_action':candidate['action_name']},indent=2))
if not all(same.values()): raise RuntimeError('candidate changed a preserved geometry/rig/material/weight invariant')
