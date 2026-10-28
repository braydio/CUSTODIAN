"""Compare whole-clip edge deformation and seam across two run derivatives.

Usage: blender -b <baseline.blend> --python compare_run_deformation.py -- <corrected.blend> <report.json>
"""
import bpy, sys, json
import numpy as np
from mathutils import Matrix

corrected_path, out = sys.argv[sys.argv.index('--') + 1:]

def evaluate(label):
    scene = bpy.context.scene
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    mesh = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
    action = arm.animation_data.action
    edges = np.asarray([e.vertices[:] for e in mesh.data.edges], dtype=np.int64)
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix()
    scene.frame_set(0)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg); em = ev.to_mesh()
    rest = np.asarray([mesh.matrix_world @ v.co for v in em.vertices], dtype=np.float64)
    ev.to_mesh_clear()
    lengths0 = np.linalg.norm(rest[edges[:, 0]] - rest[edges[:, 1]], axis=1) + 1e-12
    arm.animation_data.action = action
    rows = []; positions = {}; unique_bad_edges = set()
    for frame in range(1, 22):
        scene.frame_set(frame); bpy.context.view_layer.update()
        ev = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); em = ev.to_mesh()
        points = np.asarray([mesh.matrix_world @ v.co for v in em.vertices], dtype=np.float64)
        ev.to_mesh_clear(); positions[frame] = points
        ratio = np.linalg.norm(points[edges[:, 0]] - points[edges[:, 1]], axis=1) / lengths0
        unique_bad_edges.update(np.flatnonzero(ratio > 3).tolist())
        rows.append({'frame':frame,'max_stretch':float(ratio.max()),'p999_stretch':float(np.percentile(ratio,99.9)),
                     'edges_over_3x':int((ratio>3).sum()),'vertices_below_ground':int((points[:,2]<-0.005).sum()),
                     'min_z_m':float(points[:,2].min()),'max_z_m':float(points[:,2].max())})
    scene.frame_set(22); bpy.context.view_layer.update()
    ev = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); em = ev.to_mesh()
    end = np.asarray([mesh.matrix_world @ v.co for v in em.vertices], dtype=np.float64); ev.to_mesh_clear()
    seam = np.linalg.norm(end - positions[1], axis=1) * 1000
    return {'label':label,'action':action.name,'vertices':len(mesh.data.vertices),'triangles':len(mesh.data.loop_triangles),
            'fps':scene.render.fps/scene.render.fps_base,'duration_s':0.7,'per_frame':rows,
            'summary':{'max_stretch':max(r['max_stretch'] for r in rows),'max_p999_stretch':max(r['p999_stretch'] for r in rows),
                       'distinct_edges_over_3x':len(unique_bad_edges),'max_edges_over_3x_in_one_frame':max(r['edges_over_3x'] for r in rows),'frames_with_edges_over_3x':[r['frame'] for r in rows if r['edges_over_3x']],
                       'max_vertices_below_ground':max(r['vertices_below_ground'] for r in rows),'min_z_m':min(r['min_z_m'] for r in rows),
                       'loop_seam_max_vertex_delta_mm':float(seam.max()),'loop_seam_p99_vertex_delta_mm':float(np.percentile(seam,99))}}

baseline = evaluate('iter002')
bpy.ops.wm.open_mainfile(filepath=corrected_path)
corrected = evaluate('iter003')
report={'schema':'custodian.operator_run_deformation_comparison.v1','baseline':baseline,'corrected':corrected,
        'interpretation':['Edge stretch uses each mesh edge against its own frame-zero length over frames 1–21.',
                          'The loop seam compares frame 22 with frame 1 by corresponding vertex index.',
                          'Ground check counts vertices below -5 mm; armor/cloth geometry may extend below the nominal sole.']}
json.dump(report,open(out,'w'),indent=2)
print(json.dumps({'baseline':baseline['summary'],'corrected':corrected['summary']},indent=2))
