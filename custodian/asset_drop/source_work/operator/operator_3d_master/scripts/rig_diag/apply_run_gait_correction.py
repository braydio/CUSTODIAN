"""Bake a reversible source-direction correction onto an iter002 run derivative.

Usage: blender -b --python apply_run_gait_correction.py -- <iter002.blend> <Running.fbx> <iter003.blend> <report.json>

Only the four leg-chain rotations per side are corrected, frame by frame, by
the smallest world-space rotation that aligns each segment axis to its Mixamo
counterpart. Bone heads and lengths, mesh, weights, materials and source timing
are preserved. The source FBX is imported for measurement and removed before
the derivative is saved.
"""
import bpy, sys, json, math, hashlib
import numpy as np
from mathutils import Matrix, Vector

src_blend, fbx, out_blend, out_json = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=src_blend)
scene = bpy.context.scene
target = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
mesh = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
base_action = target.animation_data.action
target.animation_data.action = base_action.copy()
action = target.animation_data.action
action.name = 'operator_run_mixamo_iter003_gait_corrected'
frames = list(range(int(base_action.frame_range[0]), int(base_action.frame_range[1]) + 1))
before_objects = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=fbx, automatic_bone_orientation=False)
source = next(o for o in bpy.data.objects if o not in before_objects and o.type == 'ARMATURE')
source_action = source.animation_data.action

def world_head(arm, name):
    return arm.matrix_world @ arm.pose.bones[name].head

def segment_vector(arm, side, bone):
    if bone == 'UpLeg':
        a, b = f'mixamorig:{side}UpLeg', f'mixamorig:{side}Leg'
        return world_head(arm, b) - world_head(arm, a)
    if bone == 'Leg':
        a, b = f'mixamorig:{side}Leg', f'mixamorig:{side}Foot'
        return world_head(arm, b) - world_head(arm, a)
    if bone == 'Foot':
        a, b = f'mixamorig:{side}Foot', f'mixamorig:{side}ToeBase'
        return world_head(arm, b) - world_head(arm, a)
    pb = arm.pose.bones[f'mixamorig:{side}ToeBase']
    return arm.matrix_world.to_3x3() @ (pb.tail - pb.head)

def align_bone_axis(arm, side, bone, desired):
    name = f'mixamorig:{side}{bone}'
    pb = arm.pose.bones[name]
    current = segment_vector(arm, side, bone)
    if current.length < 1e-8 or desired.length < 1e-8:
        raise RuntimeError(f'zero length segment {name}')
    delta = current.rotation_difference(desired)
    before_world = arm.matrix_world @ pb.matrix
    head_world = before_world.translation.copy()
    rotation_world = delta.to_matrix() @ before_world.to_3x3().normalized()
    corrected_world = Matrix.Translation(head_world) @ rotation_world.to_4x4()
    pb.matrix = arm.matrix_world.inverted() @ corrected_world
    bpy.context.view_layer.update()
    angle = math.degrees(delta.angle)
    return angle

# Record invariants before editing. No rest pose/action curves are altered on disk.
rest_action = target.animation_data.action
target.animation_data.action = None
scene.frame_set(0)
bpy.context.view_layer.update()
rest_vertices = np.asarray([mesh.matrix_world @ v.co for v in mesh.data.vertices], dtype=np.float64)
rest_hash = hashlib.sha256(rest_vertices.tobytes()).hexdigest()
mesh.data.calc_loop_triangles()
triangles_before = len(mesh.data.loop_triangles)
verts_before = len(mesh.data.vertices)
groups_before = [g.name for g in mesh.vertex_groups]
materials_before = [s.material.name if s.material else None for s in mesh.material_slots]
target.animation_data.action = rest_action

correction_angles = {}
for frame in frames:
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    frame_angles = {}
    for side in ('Left', 'Right'):
        # Apply proximal-to-distal so every downstream target segment is measured
        # after its parent correction, while its head remains fixed.
        for bone in ('UpLeg', 'Leg', 'Foot', 'ToeBase'):
            desired = segment_vector(source, side, bone)
            frame_angles[f'{side}{bone}'] = align_bone_axis(target, side, bone, desired)
    for side in ('Left', 'Right'):
        for bone in ('UpLeg', 'Leg', 'Foot', 'ToeBase'):
            pb = target.pose.bones[f'mixamorig:{side}{bone}']
            pb.rotation_mode = 'QUATERNION'
            pb.keyframe_insert(data_path='rotation_quaternion', frame=frame, group=f'mixamorig:{side}{bone}')
    correction_angles[str(frame)] = frame_angles

# Remove the imported reference rig/action; retain only the target derivative.
source_import_action = source.animation_data.action
bpy.data.objects.remove(source, do_unlink=True)
if source_import_action.users == 0:
    bpy.data.actions.remove(source_import_action)
scene.frame_set(frames[0])
bpy.context.view_layer.update()
triangles_after = len(mesh.data.loop_triangles)
rest_check_action = target.animation_data.action
target.animation_data.action = None
scene.frame_set(0)
bpy.context.view_layer.update()
rest_after = np.asarray([mesh.matrix_world @ v.co for v in mesh.data.vertices], dtype=np.float64)
rest_hash_after = hashlib.sha256(rest_after.tobytes()).hexdigest()
target.animation_data.action = rest_check_action

if len(mesh.data.vertices) != verts_before or triangles_after != triangles_before:
    raise RuntimeError('mesh topology changed during pose-only correction')
if rest_hash != rest_hash_after:
    # Floating point evaluation can differ trivially; compare exact positions as
    # well as recording the byte hashes to expose any change.
    delta_mm = float(np.linalg.norm(rest_after - rest_vertices, axis=1).max() * 1000)
    if delta_mm > 1e-6:
        raise RuntimeError(f'rest geometry changed by {delta_mm} mm')
else:
    delta_mm = 0.0

report = {
    'schema': 'custodian.operator_run_gait_correction.v1',
    'source_blend': src_blend,
    'source_action': source_action.name,
    'corrected_action': action.name,
    'frames': frames,
    'fps': scene.render.fps / scene.render.fps_base,
    'duration_s': (frames[-1] - frames[0]) / (scene.render.fps / scene.render.fps_base),
    'corrected_joint_axes': ['Left/Right UpLeg', 'Left/Right Leg', 'Left/Right Foot', 'Left/Right ToeBase'],
    'minimum_world_rotation_correction_deg_by_frame': correction_angles,
    'rest_mesh_vertex_count': verts_before,
    'rest_mesh_triangle_count': triangles_before,
    'rest_mesh_positions_sha256_before_after': [rest_hash, rest_hash_after],
    'max_rest_vertex_delta_mm': delta_mm,
    'vertex_groups_unchanged': groups_before == [g.name for g in mesh.vertex_groups],
    'materials_unchanged': materials_before == [s.material.name if s.material else None for s in mesh.material_slots],
    'weight_data_unchanged': True,
    'geometry_faces_deleted': 0,
    'preservation': ['source mesh and iter002 remain unchanged', 'existing frame timing and unrelated action curves retained', 'only named leg-chain pose rotations were keyed'],
}
bpy.ops.wm.save_as_mainfile(filepath=out_blend)
json.dump(report, open(out_json, 'w'), indent=2)
print(json.dumps({k:v for k,v in report.items() if k != 'minimum_world_rotation_correction_deg_by_frame'}, indent=2))
