"""Compare the 21 unique target run frames with source Mixamo motion and stable foot landmarks.
Usage: blender -b <run.blend> --python compare_run_gait.py -- <Running.fbx> <report.json>
Read-only: emits rest-axis, joint-tracking, and fixed-index heel/toe contact diagnostics."""
import bpy, sys, json, math
import numpy as np
from mathutils import Matrix

fbx, out = sys.argv[sys.argv.index('--') + 1:]
scene = bpy.context.scene
TARGET = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
TARGET_ACTION = TARGET.animation_data.action
MESH = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
BONE_NAMES = ('mixamorig:Hips','mixamorig:LeftUpLeg','mixamorig:RightUpLeg',
              'mixamorig:LeftLeg','mixamorig:RightLeg','mixamorig:LeftFoot',
              'mixamorig:RightFoot','mixamorig:LeftToeBase','mixamorig:RightToeBase',
              'mixamorig:LeftArm','mixamorig:RightArm','mixamorig:LeftForeArm','mixamorig:RightForeArm')

def vec(arm, bone, point):
    return np.asarray((arm.matrix_world @ getattr(arm.pose.bones[bone], point))[:], dtype=float)

def unit(a):
    n = np.linalg.norm(a)
    return a / n if n else a

def angle_deg(a, b):
    return math.degrees(math.acos(float(np.clip(np.dot(unit(a), unit(b)), -1, 1))))

def yaw_deg(v, lateral, forward):
    return math.degrees(math.atan2(float(np.dot(v, lateral)), float(np.dot(v, forward))))

def reset_rest(arm):
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix()
    scene.frame_set(0)
    bpy.context.view_layer.update()

def sample(arm, action, frame):
    arm.animation_data.action = action
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    hip_l = vec(arm, 'mixamorig:LeftUpLeg', 'head')
    hip_r = vec(arm, 'mixamorig:RightUpLeg', 'head')
    lateral = hip_r - hip_l
    lateral[2] = 0
    lateral = unit(lateral)
    # Operator front faces -Y; up x left-to-right gives the forward axis.
    forward = unit(np.cross(np.array([0., 0., 1.]), lateral))
    hip_center = (hip_l + hip_r) * 0.5
    hip_width = abs(float(np.dot(hip_r - hip_l, lateral)))
    d = {'hip_width_m': hip_width, 'hip_center_world_m': hip_center.tolist()}
    knees, ankles = {}, {}
    for side in ('Left', 'Right'):
        name = side.lower()
        knee = vec(arm, f'mixamorig:{side}Leg', 'head')
        ankle = vec(arm, f'mixamorig:{side}Foot', 'head')
        up = vec(arm, f'mixamorig:{side}UpLeg', 'head')
        upper_vec = knee - up
        lower_vec = ankle - knee
        foot_axis = vec(arm, f'mixamorig:{side}Foot', 'tail') - ankle
        toe_axis = vec(arm, f'mixamorig:{side}ToeBase', 'tail') - vec(arm, f'mixamorig:{side}ToeBase', 'head')
        d[name+'_knee_lateral_m'] = float(np.dot(knee-hip_center, lateral))
        d[name+'_knee_forward_m'] = float(np.dot(knee-hip_center, forward))
        d[name+'_ankle_lateral_m'] = float(np.dot(ankle-hip_center, lateral))
        d[name+'_ankle_forward_m'] = float(np.dot(ankle-hip_center, forward))
        d[name+'_ankle_z_m'] = float(ankle[2])
        d[name+'_foot_axis_yaw_deg'] = yaw_deg(foot_axis, lateral, forward)
        d[name+'_toe_axis_yaw_deg'] = yaw_deg(toe_axis, lateral, forward)
        knees[name] = knee
        ankles[name] = ankle
        arm_vec = vec(arm,f'mixamorig:{side}Arm','tail')-vec(arm,f'mixamorig:{side}Arm','head')
        fore_vec = vec(arm,f'mixamorig:{side}ForeArm','tail')-vec(arm,f'mixamorig:{side}ForeArm','head')
        d[name+'_upperarm_swing_deg'] = math.degrees(math.atan2(float(np.dot(arm_vec,forward)),float(arm_vec[2])))
        d[name+'_forearm_swing_deg'] = math.degrees(math.atan2(float(np.dot(fore_vec,forward)),float(fore_vec[2])))
        d[name+'_thigh_length_m'] = float(np.linalg.norm(upper_vec))
        d[name+'_calf_length_m'] = float(np.linalg.norm(lower_vec))
    d['knee_width_over_hip_width'] = abs(float(np.dot(knees['right']-knees['left'],lateral)))/hip_width
    d['stance_width_over_hip_width'] = abs(float(np.dot(ankles['right']-ankles['left'],lateral)))/hip_width
    return d

def evaluated_mesh_world():
    dg = bpy.context.evaluated_depsgraph_get()
    ev = MESH.evaluated_get(dg)
    em = ev.to_mesh()
    points = np.asarray([MESH.matrix_world @ v.co for v in em.vertices], dtype=float)
    ev.to_mesh_clear()
    return points

def build_stable_landmarks(rest_points):
    group_indices = {g.name:g.index for g in MESH.vertex_groups}
    result = {}
    for side in ('Left','Right'):
        foot_i = group_indices[f'mixamorig:{side}Foot']
        toe_i = group_indices[f'mixamorig:{side}ToeBase']
        foot_ids, toe_ids = [], []
        for v in MESH.data.vertices:
            weights = {g.group:g.weight for g in v.groups}
            if weights.get(foot_i,0) >= 0.20 and weights.get(foot_i,0) >= weights.get(toe_i,0): foot_ids.append(v.index)
            if weights.get(toe_i,0) >= 0.20: toe_ids.append(v.index)
        toe_origin = vec(TARGET,f'mixamorig:{side}ToeBase','head')
        axis = unit(np.cross(np.array([0.,0.,1.]), unit(vec(TARGET,'mixamorig:RightUpLeg','head')-vec(TARGET,'mixamorig:LeftUpLeg','head'))))
        proj = rest_points @ axis
        # Fixed vertex indices at the rear/front extremes of weighted foot regions.
        heel_ids = sorted(foot_ids,key=lambda i:proj[i])[:12]
        tip_ids = sorted(toe_ids,key=lambda i:proj[i],reverse=True)[:12]
        if len(heel_ids)<3 or len(tip_ids)<3:
            raise RuntimeError(f'insufficient fixed-index foot landmarks for {side}: heel={len(heel_ids)} toe={len(tip_ids)}')
        result[side.lower()]={'heel':heel_ids,'toe':tip_ids}
    return result

def landmark_positions(ids, points):
    return {side:{kind:points[np.asarray(indices)].mean(axis=0).tolist() for kind,indices in landmarks.items()} for side,landmarks in ids.items()}

# Capture true rest pose, then derive fixed mesh vertex indices before restoring animations.
reset_rest(TARGET)
bpy.context.view_layer.update()
target_rest = sample(TARGET, None, 0)
rest_points = evaluated_mesh_world()
before=set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=fbx, automatic_bone_orientation=False)
SOURCE=next(o for o in bpy.data.objects if o not in before and o.type=='ARMATURE')
SOURCE_ACTION=SOURCE.animation_data.action
reset_rest(SOURCE)
source_rest=sample(SOURCE,None,0)
landmark_ids=build_stable_landmarks(rest_points)
rows=[]
for frame in range(1,22):
    t=sample(TARGET,TARGET_ACTION,frame)
    target_points=evaluated_mesh_world()
    landmarks=landmark_positions(landmark_ids,target_points)
    s=sample(SOURCE,SOURCE_ACTION,frame)
    errors={}
    for side in ('Left','Right'):
        target_thigh=vec(TARGET,f'mixamorig:{side}Leg','head')-vec(TARGET,f'mixamorig:{side}UpLeg','head')
        source_thigh=vec(SOURCE,f'mixamorig:{side}Leg','head')-vec(SOURCE,f'mixamorig:{side}UpLeg','head')
        target_calf=vec(TARGET,f'mixamorig:{side}Foot','head')-vec(TARGET,f'mixamorig:{side}Leg','head')
        source_calf=vec(SOURCE,f'mixamorig:{side}Foot','head')-vec(SOURCE,f'mixamorig:{side}Leg','head')
        target_foot=vec(TARGET,f'mixamorig:{side}Foot','tail')-vec(TARGET,f'mixamorig:{side}Foot','head')
        source_foot=vec(SOURCE,f'mixamorig:{side}Foot','tail')-vec(SOURCE,f'mixamorig:{side}Foot','head')
        target_toe=vec(TARGET,f'mixamorig:{side}ToeBase','tail')-vec(TARGET,f'mixamorig:{side}ToeBase','head')
        source_toe=vec(SOURCE,f'mixamorig:{side}ToeBase','tail')-vec(SOURCE,f'mixamorig:{side}ToeBase','head')
        errors[f'{side}_thigh_direction_error_deg']=angle_deg(target_thigh,source_thigh)
        errors[f'{side}_calf_direction_error_deg']=angle_deg(target_calf,source_calf)
        errors[f'{side}_foot_axis_error_deg']=angle_deg(target_foot,source_foot)
        errors[f'{side}_toe_axis_error_deg']=angle_deg(target_toe,source_toe)
        for name in ('Arm','ForeArm'):
            errors[f'{side}_{name}_direction_error_deg']=angle_deg(vec(TARGET,f'mixamorig:{side}{name}','tail')-vec(TARGET,f'mixamorig:{side}{name}','head'),vec(SOURCE,f'mixamorig:{side}{name}','tail')-vec(SOURCE,f'mixamorig:{side}{name}','head'))
    rows.append({'frame':frame,'time_s':(frame-1)/30,'target':t,'source':s,'joint_direction_errors':errors,'stable_landmarks':landmarks})

summary={}
for label in ('target','source'):
    for metric in ('knee_width_over_hip_width','stance_width_over_hip_width','left_foot_axis_yaw_deg','right_foot_axis_yaw_deg','left_toe_axis_yaw_deg','right_toe_axis_yaw_deg','left_upperarm_swing_deg','right_upperarm_swing_deg'):
        values=[r[label][metric] for r in rows]
        summary[f'{label}.{metric}']={'min':min(values),'max':max(values),'mean':float(np.mean(values))}
for metric in rows[0]['joint_direction_errors']:
    values=[r['joint_direction_errors'][metric] for r in rows]
    summary[f'joint_direction_error.{metric}']={'max':max(values),'mean':float(np.mean(values))}
contact_summary={}
for side in ('left','right'):
    for kind in ('heel','toe'):
        points=[np.asarray(r['stable_landmarks'][side][kind]) for r in rows]
        pelvis=np.asarray([r['target']['hip_center_world_m'] for r in rows])
        states=[p[2]<=0.04 for p in points]
        speeds=[float(np.linalg.norm(points[i+1][:2]-points[i][:2])*30) for i in range(20) if states[i] and states[i+1]]
        rel=np.asarray([points[i]-pelvis[i] for i in range(21)])
        relative_speeds=[float(np.linalg.norm(rel[i+1][:2]-rel[i][:2])*30) for i in range(20) if states[i] and states[i+1]]
        contact_summary[f'{side}_{kind}']={'fixed_vertex_indices':landmark_ids[side][kind],'ground_threshold_m':0.04,'contact_frames':int(sum(bool(x) for x in states)),'contact_frame_indices':[i+1 for i,x in enumerate(states) if x],'consecutive_pairs':len(speeds),'world_horizontal_speed_mps_min_max_mean':([min(speeds),max(speeds),float(np.mean(speeds))] if speeds else None),'pelvis_relative_horizontal_speed_mps_min_max_mean':([min(relative_speeds),max(relative_speeds),float(np.mean(relative_speeds))] if relative_speeds else None)}
report={'schema':'custodian.operator_run_gait_comparison.v2','fps':30,'unique_frames':21,'source_action':SOURCE_ACTION.name,'target_action':TARGET_ACTION.name,'rest_axes':{'target':target_rest,'source':source_rest},'stable_landmark_indices':landmark_ids,'summary':summary,'stable_heel_toe_contact':contact_summary,'frames':rows,'interpretation_limits':['World toe-axis values use the character forward axis derived from the pelvis; rest-axis offsets are separated from animation deltas.','Stable heel/toe points are fixed vertex-index centroids selected by rest-pose Foot/ToeBase weights; they do not switch to a different lowest vertex each frame.','Contact threshold 40mm is a measurement band; contact counts and speeds require visual interpretation.','Normalized stance width is affected by source/target bone proportions.','Direction error describes retarget fidelity and does not judge naturalness.']}
json.dump(report,open(out,'w'),indent=2)
print(json.dumps({'rest_axes':report['rest_axes'],'summary':summary,'stable_landmark_indices':landmark_ids,'stable_heel_toe_contact':contact_summary},indent=2))
