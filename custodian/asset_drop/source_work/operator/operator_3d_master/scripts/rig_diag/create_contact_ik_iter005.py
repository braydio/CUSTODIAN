"""Create one reversible, contact-gated two-bone IK derivative from ITER003.

Usage: blender -b <iter003.blend> --python create_contact_ik_iter005.py -- \
       <gait_comparison.json> <out.blend> <solver_report.json>

Contact is established from the existing fixed heel/toe centroids (40mm band)
and from actual foot/toe-group mesh vertices that cross the ground plane. For
each active frame, the IK pole angle is calibrated against the existing knee
position before applying the minimum upward ankle target translation needed
for 1mm sole clearance. No other root, mesh, weight, or animation channels are
intentionally changed. The output action is baked with original ITER003 kept.
"""
import bpy
import sys
import json
import math
import numpy as np
from mathutils import Matrix, Vector


gait_path, out_blend, out_report = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
scene = bpy.context.scene
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
mesh = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
source_action = arm.animation_data.action
gait = json.load(open(gait_path))
fixed = gait['stable_landmark_indices']
fps = scene.render.fps / scene.render.fps_base
if abs(fps - 30.0) > 1e-6 or source_action is None:
    raise RuntimeError(f'expected an animated 30fps source, got fps={fps}, action={source_action}')
if abs(source_action.frame_range[0] - 1.0) > 1e-6 or abs(source_action.frame_range[1] - 22.0) > 1e-6:
    raise RuntimeError(f'unexpected source action range: {tuple(source_action.frame_range)}')

def evaluated_points():
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = mesh.evaluated_get(depsgraph)
    evaluated_mesh = evaluated.to_mesh()
    points = np.asarray([mesh.matrix_world @ v.co for v in evaluated_mesh.vertices], dtype=np.float64)
    evaluated.to_mesh_clear()
    return points

def world_point(pose_bone, point_name):
    return arm.matrix_world @ getattr(pose_bone, point_name)

def smooth_contact_weight(height_m):
    # Full IK in the 0-30mm contact core, eased to zero at the established
    # 40mm diagnostic boundary. Actual penetration always activates at 1.
    if height_m <= 0.030:
        return 1.0
    if height_m >= 0.040:
        return 0.0
    t = (height_m - 0.030) / 0.010
    return 1.0 - (3.0 * t * t - 2.0 * t * t * t)

def point_state(points, side):
    side_key = side.lower()
    landmarks = {}
    for region in ('heel', 'toe'):
        ids = np.asarray(fixed[side_key][region], dtype=np.int64)
        landmarks[region] = points[ids].mean(axis=0)
    anchor = min(float(p[2]) for p in landmarks.values())
    return landmarks, anchor

def foot_group_ids(side):
    names = {f'mixamorig:{side}Foot', f'mixamorig:{side}ToeBase'}
    return np.asarray([
        vertex.index for vertex in mesh.data.vertices
        if any(mesh.vertex_groups[g.group].name in names and g.weight >= 0.20 for g in vertex.groups)
    ], dtype=np.int64)

# Capture true rest edge lengths and the untouched action's complete samples.
arm.animation_data.action = None
for pose_bone in arm.pose.bones:
    pose_bone.matrix_basis = Matrix()
scene.frame_set(0)
bpy.context.view_layer.update()
rest_points = evaluated_points()
edges = np.asarray([tuple(e.vertices) for e in mesh.data.edges], dtype=np.int64)
rest_edge_lengths = np.linalg.norm(rest_points[edges[:, 0]] - rest_points[edges[:, 1]], axis=1)
arm.animation_data.action = source_action
baseline = {}
for frame in range(1, 23):
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    points = evaluated_points()
    row = {'points': points}
    for side in ('Left', 'Right'):
        up = arm.pose.bones[f'mixamorig:{side}UpLeg']
        leg = arm.pose.bones[f'mixamorig:{side}Leg']
        foot = arm.pose.bones[f'mixamorig:{side}Foot']
        landmarks, anchor = point_state(points, side)
        sole_ids = foot_group_ids(side)
        sole_index = int(sole_ids[np.argmin(points[sole_ids, 2])])
        row[side] = {
            'hip': world_point(up, 'head').copy(),
            'knee': world_point(leg, 'head').copy(),
            'ankle': world_point(leg, 'tail').copy(),
            'foot_rotation': (arm.matrix_world @ foot.matrix).to_quaternion().copy(),
            'landmarks': landmarks,
            'anchor_z_m': anchor,
            'sole_ids': sole_ids,
            'sole_min_z_m': float(points[sole_index, 2]),
            'sole_min_vertex': sole_index,
        }
    baseline[frame] = row

# Preserve the source action and edit only a copy.
derivative_action = source_action.copy()
derivative_action.name = 'operator_run_mixamo_iter005_contact_ik'
arm.animation_data.action = derivative_action

controls = {}
for side in ('Left', 'Right'):
    leg = arm.pose.bones[f'mixamorig:{side}Leg']
    foot = arm.pose.bones[f'mixamorig:{side}Foot']
    names = [f'ITER005_{side}_ankle_target', f'ITER005_{side}_knee_pole', f'ITER005_{side}_foot_rotation']
    objects = []
    for name in names:
        obj = bpy.data.objects.new(name, None)
        obj.empty_display_type = 'SPHERE'
        obj.empty_display_size = 0.01
        scene.collection.objects.link(obj)
        objects.append(obj)
    target, pole, rotation_target = objects
    rotation_target.rotation_mode = 'QUATERNION'
    ik = leg.constraints.new('IK')
    ik.name = f'ITER005_{side}_contact_2bone_IK'
    ik.target = target
    ik.pole_target = pole
    ik.chain_count = 2
    ik.use_stretch = False
    ik.influence = 0.0
    copy_rotation = foot.constraints.new('COPY_ROTATION')
    copy_rotation.name = f'ITER005_{side}_preserve_foot_orientation'
    copy_rotation.target = rotation_target
    copy_rotation.owner_space = 'WORLD'
    copy_rotation.target_space = 'WORLD'
    copy_rotation.mix_mode = 'REPLACE'
    copy_rotation.influence = 0.0
    controls[side] = (target, pole, rotation_target, ik, copy_rotation)

def calibrate_pole(side, frame, target, pole, rotation_target, ik, copy_rotation, base):
    """Choose a per-sample pole angle that reproduces the baseline knee."""
    target.location = base['ankle']
    pole.location = base['knee']
    rotation_target.rotation_quaternion = base['foot_rotation']
    ik.influence = 1.0
    copy_rotation.influence = 1.0
    best = None
    for degrees in range(-180, 181, 5):
        ik.pole_angle = math.radians(degrees)
        bpy.context.view_layer.update()
        knee = world_point(arm.pose.bones[f'mixamorig:{side}Leg'], 'head')
        error = (knee - base['knee']).length
        if best is None or error < best[0]:
            best = (error, float(degrees))
    fine_best = best
    for degrees in np.arange(best[1] - 5.0, best[1] + 5.0001, 0.25):
        ik.pole_angle = math.radians(float(degrees))
        bpy.context.view_layer.update()
        knee = world_point(arm.pose.bones[f'mixamorig:{side}Leg'], 'head')
        error = (knee - base['knee']).length
        if error < fine_best[0]:
            fine_best = (float(error), float(degrees))
    return fine_best

solver_rows = []
for side in ('Left', 'Right'):
    target, pole, rotation_target, ik, copy_rotation = controls[side]
    for frame in range(1, 23):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        base = baseline[frame][side]
        # Keep the other leg's keyed constraint state independent.
        ik.influence = 0.0
        copy_rotation.influence = 0.0
        activation_reason = []
        if base['anchor_z_m'] <= 0.040:
            activation_reason.append('fixed_heel_or_toe_centroid_within_40mm')
        if base['sole_min_z_m'] <= 0.0:
            activation_reason.append('weighted_foot_toe_surface_crosses_ground')
        active = bool(activation_reason)
        if active:
            calibrated_error, pole_degrees = calibrate_pole(
                side, frame, target, pole, rotation_target, ik, copy_rotation, base)
            alpha = 1.0 if base['sole_min_z_m'] <= 0.0 else smooth_contact_weight(base['anchor_z_m'])
        else:
            calibrated_error, pole_degrees, alpha = 0.0, -90.0, 0.0
        delta = max(0.0, 0.001 - base['sole_min_z_m']) if active else 0.0
        ik.pole_angle = math.radians(pole_degrees)
        ik.influence = alpha
        copy_rotation.influence = alpha
        target.location = base['ankle'] + Vector((0.0, 0.0, delta))
        pole.location = base['knee']
        rotation_target.rotation_quaternion = base['foot_rotation']
        for obj in (target, pole):
            obj.keyframe_insert(data_path='location', frame=frame)
        rotation_target.keyframe_insert(data_path='rotation_quaternion', frame=frame)
        ik.keyframe_insert(data_path='pole_angle', frame=frame)
        ik.keyframe_insert(data_path='influence', frame=frame)
        copy_rotation.keyframe_insert(data_path='influence', frame=frame)
        bpy.context.view_layer.update()
        points = evaluated_points()
        sole_min = float(points[base['sole_ids'], 2].min())
        knee = world_point(arm.pose.bones[f'mixamorig:{side}Leg'], 'head')
        ankle = world_point(arm.pose.bones[f'mixamorig:{side}Leg'], 'tail')
        solver_rows.append({
            'side': side, 'frame': frame, 'active': active,
            'activation_reason': activation_reason,
            'anchor_z_mm': base['anchor_z_m'] * 1000.0,
            'baseline_sole_min_mm': base['sole_min_z_m'] * 1000.0,
            'sole_min_vertex_id': base['sole_min_vertex'],
            'ankle_target_rise_mm': delta * 1000.0,
            'contact_blend_weight': alpha,
            'calibrated_pole_angle_deg': pole_degrees,
            'baseline_knee_reconstruction_error_mm': calibrated_error * 1000.0,
            'corrected_sole_min_mm': sole_min * 1000.0,
            'corrected_knee_displacement_mm': (knee - base['knee']).length * 1000.0,
            'ik_end_target_error_mm': (ankle - (base['ankle'] + Vector((0.0, 0.0, delta)))).length * 1000.0,
        })

# Bake only the leg chains touched by the two-bone solve. Keep the IK controls
# out of the final rig and leave all non-leg source curves as copied originals.
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
for obj in bpy.context.selected_objects:
    if obj != arm:
        obj.select_set(False)
for pose_bone in arm.pose.bones:
    pose_bone.select = pose_bone.name in {
        f'mixamorig:{side}{suffix}'
        for side in ('Left', 'Right')
        for suffix in ('UpLeg', 'Leg', 'Foot')
    }
if arm.mode != 'POSE':
    bpy.ops.object.mode_set(mode='POSE')
bake_result = bpy.ops.nla.bake(
    frame_start=1, frame_end=22, step=1,
    only_selected=True, visual_keying=True, clear_constraints=True,
    clear_parents=False, use_current_action=True, clean_curves=False,
    bake_types={'POSE'}, channel_types={'LOCATION', 'ROTATION', 'SCALE'})
if 'FINISHED' not in bake_result:
    raise RuntimeError(f'pose bake failed: {bake_result}')
bpy.ops.object.mode_set(mode='OBJECT')
for side, bundle in controls.items():
    for obj in bundle[:3]:
        action = obj.animation_data.action if obj.animation_data else None
        bpy.data.objects.remove(obj, do_unlink=True)
        if action and action.users == 0:
            bpy.data.actions.remove(action)
arm.animation_data.action = derivative_action
derivative_action.name = 'operator_run_mixamo_iter005_contact_ik'

# Validate the baked derivative at the 21 unique samples and loop endpoint.
after_rows = []
max_edge_ratio = 0.0
max_seam_mm = 0.0
for frame in range(1, 23):
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    points = evaluated_points()
    low = np.flatnonzero(points[:, 2] < -0.005)
    ratios = np.linalg.norm(points[edges[:, 0]] - points[edges[:, 1]], axis=1) / np.maximum(rest_edge_lengths, 1e-12)
    max_edge_ratio = max(max_edge_ratio, float(ratios.max()))
    if frame == 22:
        max_seam_mm = float(np.linalg.norm(points - after_rows[0]['points'], axis=1).max() * 1000.0)
    frame_row = {
        'frame': frame,
        'time_s': (frame - 1) / fps,
        'minimum_mesh_z_mm': float(points[:, 2].min() * 1000.0),
        'vertices_below_minus5mm': int(len(low)),
        'penetrating_vertex_ids': [int(x) for x in low],
        'points': points,
        'feet': {},
    }
    for side in ('Left', 'Right'):
        base = baseline[frame][side]
        leg = arm.pose.bones[f'mixamorig:{side}Leg']
        foot = arm.pose.bones[f'mixamorig:{side}Foot']
        sole_min = float(points[base['sole_ids'], 2].min())
        fixed_now = {region: float(points[np.asarray(fixed[side.lower()][region], dtype=np.int64), 2].mean()) for region in ('heel', 'toe')}
        frame_row['feet'][side] = {
            'sole_min_z_mm': sole_min * 1000.0,
            'fixed_heel_centroid_z_mm': fixed_now['heel'] * 1000.0,
            'fixed_toe_centroid_z_mm': fixed_now['toe'] * 1000.0,
            'ankle_world_xyz_m': list(world_point(leg, 'tail')),
            'foot_axis_world': list((world_point(foot, 'tail') - world_point(foot, 'head')).normalized()),
        }
    after_rows.append(frame_row)

# Quarter-frame contact interpolation check. This is additional to the required
# 21 samples and endpoint; it does not change or extend the authored duration.
subframe_rows = []
for start, end in ((1, 3), (7, 16), (17, 22)):
    for q in range(int(start * 4), int(end * 4) + 1):
        value = q / 4.0
        whole = int(math.floor(value))
        sub = value - whole
        scene.frame_set(whole, subframe=sub)
        bpy.context.view_layer.update()
        points = evaluated_points()
        foot_min = {}
        for side in ('Left', 'Right'):
            ids = baseline[max(1, min(22, whole))][side]['sole_ids']
            foot_min[side] = float(points[ids, 2].min() * 1000.0)
        subframe_rows.append({'frame': value, 'minimum_mesh_z_mm': float(points[:, 2].min() * 1000.0), 'left_sole_min_mm': foot_min['Left'], 'right_sole_min_mm': foot_min['Right']})

penetrating = [r for r in after_rows[:21] if r['vertices_below_minus5mm']]
distinct_penetrating = sorted({vi for row in penetrating for vi in row['penetrating_vertex_ids']})
outside_contact_deltas = []
for row in after_rows[:21]:
    frame = row['frame']
    active_any = any(x['active'] and x['frame'] == frame for x in solver_rows)
    if not active_any:
        delta = float(np.linalg.norm(row['points'] - baseline[frame]['points'], axis=1).max() * 1000.0)
        outside_contact_deltas.append({'frame': frame, 'max_vertex_delta_mm': delta})

report = {
    'schema': 'custodian.operator_run_iter005_contact_ik.v1',
    'status': 'RUN_MOTION_NEEDS_REPAIR',
    'source_action': source_action.name,
    'derivative_action': derivative_action.name,
    'source_action_preserved': source_action.name in bpy.data.actions,
    'source_frame_range': [1.0, 22.0],
    'fps': fps,
    'unique_frames': 21,
    'loop_endpoint_frame': 22,
    'clearance_target_mm': 1.0,
    'contact_detection': {
        'fixed_centroid_band_mm': 40.0,
        'foot_geometry_group_weight_min': 0.20,
        'foot_geometry_contact_rule': 'minimum evaluated vertex among Foot/ToeBase weighted sets below or at z=0 establishes direct surface contact; fixed centroid in the 40mm band establishes the eased contact phase; right-toe contact is not forced',
        'fixed_landmark_indices_reused': fixed,
    },
    'solver': {
        'type': 'two-bone IK on UpLeg+Leg with animated knee pole and Copy Rotation on Foot',
        'stretch_enabled': False,
        'root_pelvis_arms_weights_mesh_materials_timing_edited': False,
        'only leg chains baked': True,
        'per_frame_records': solver_rows,
    },
    'penetration': {
        'threshold_mm': -5.0,
        'vertex_frame_observations': int(sum(r['vertices_below_minus5mm'] for r in after_rows[:21])),
        'distinct_vertex_ids_across_cycle': distinct_penetrating,
        'distinct_vertex_count_across_cycle': len(distinct_penetrating),
        'minimum_mesh_z_mm_across_cycle': min(r['minimum_mesh_z_mm'] for r in after_rows[:21]),
        'frames': [{k: v for k, v in r.items() if k != 'points' and k != 'feet'} for r in after_rows[:21]],
    },
    'max_edge_stretch_over_rest_all_frames': max_edge_ratio,
    'loop_seam_max_vertex_delta_mm_frame22_vs_frame1': max_seam_mm,
    'outside_contact_max_vertex_deltas_mm': outside_contact_deltas,
    'contact_subframe_samples': subframe_rows,
    'interpretation_limits': [
        'Fixed-landmark reconstructed travel speed is inferred from the same contact windows and is not independent gameplay skating evidence.',
        'Foot/toe-group minimum vertices are geometric support candidates; their actual surface appearance remains for human visual review.',
        'A low right-toe centroid is not targeted; right-foot corrections are derived only from measured foot/toe surface clearance and the heel/toe contact evidence.',
    ],
}
for row in after_rows:
    row.pop('points')
json.dump(report, open(out_report, 'w'), indent=2)
bpy.ops.wm.save_as_mainfile(filepath=out_blend)
print(json.dumps({
    'status': report['status'],
    'penetrating_vertex_frame_observations': report['penetration']['vertex_frame_observations'],
    'distinct_penetrating_vertex_count': report['penetration']['distinct_vertex_count_across_cycle'],
    'minimum_mesh_z_mm': report['penetration']['minimum_mesh_z_mm_across_cycle'],
    'max_edge_stretch': max_edge_ratio,
    'loop_seam_mm': max_seam_mm,
    'outside_contact_max_delta_mm': max((r['max_vertex_delta_mm'] for r in outside_contact_deltas), default=0.0),
    'blend': out_blend,
    'report': out_report,
}, indent=2))
