"""Compare the 21 unique target run frames with source Mixamo joint motion.
Usage: blender -b <run_iter002.blend> --python compare_run_gait.py -- <Running.fbx> <report.json>
This is read-only and reports rest-axis offsets separately from animated joint deltas."""
import bpy, sys, json, math
import numpy as np
from mathutils import Matrix

fbx, out = sys.argv[sys.argv.index('--') + 1:]
scene = bpy.context.scene
TARGET = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
TARGET_ACTION = TARGET.animation_data.action
MESH = next(o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups))
BONES = ('mixamorig:Hips','mixamorig:LeftUpLeg','mixamorig:RightUpLeg',
         'mixamorig:LeftFoot','mixamorig:RightFoot','mixamorig:LeftToeBase',
         'mixamorig:RightToeBase','mixamorig:LeftArm','mixamorig:RightArm',
         'mixamorig:LeftForeArm','mixamorig:RightForeArm')

def vec(arm, bone, point):
    return np.asarray((arm.matrix_world @ getattr(arm.pose.bones[bone], point))[:], dtype=float)

def sample(arm, action, frame):
    arm.animation_data.action = action
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    L = vec(arm, 'mixamorig:LeftUpLeg', 'head')
    R = vec(arm, 'mixamorig:RightUpLeg', 'head')
    lateral = R - L; lateral[2] = 0
    lateral /= np.linalg.norm(lateral)
    forward = np.cross(lateral, np.array([0., 0., 1.]))
    def dot(a,b): return float(np.dot(a,b))
    d = {'hip_width_m': float(np.linalg.norm(R[:2]-L[:2]))}
    for side in ('Left','Right'):
        lower = side.lower()
        fh = vec(arm, f'mixamorig:{side}Foot', 'head')
        ft = vec(arm, f'mixamorig:{side}Foot', 'tail')
        th = vec(arm, f'mixamorig:{side}ToeBase', 'head')
        tt = vec(arm, f'mixamorig:{side}ToeBase', 'tail')
        d[lower+'_foot_axis_yaw_deg'] = math.degrees(math.atan2(dot(ft-fh,lateral),dot(ft-fh,forward)))
        d[lower+'_toe_axis_yaw_deg'] = math.degrees(math.atan2(dot(tt-th,lateral),dot(tt-th,forward)))
        d[lower+'_ankle_lateral_m'] = dot(fh,lateral)
        d[lower+'_ankle_forward_m'] = dot(fh,forward)
        d[lower+'_ankle_z_m'] = float(fh[2])
        armv = vec(arm,f'mixamorig:{side}Arm','tail')-vec(arm,f'mixamorig:{side}Arm','head')
        forev = vec(arm,f'mixamorig:{side}ForeArm','tail')-vec(arm,f'mixamorig:{side}ForeArm','head')
        d[lower+'_upperarm_pitch_deg'] = math.degrees(math.atan2(dot(armv,forward),dot(armv,np.array([0.,0.,1.]))))
        d[lower+'_forearm_pitch_deg'] = math.degrees(math.atan2(dot(forev,forward),dot(forev,np.array([0.,0.,1.]))))
    d['stance_width_over_hip_width'] = abs(d['right_ankle_lateral_m']-d['left_ankle_lateral_m'])/d['hip_width_m']
    return d

GROUP_NAMES=[g.name for g in MESH.vertex_groups]
DOMINANT=np.array([max(v.groups,key=lambda g:g.weight).group if v.groups else -1 for v in MESH.data.vertices])
GROUP_MASKS={side:np.array([i>=0 and side in GROUP_NAMES[i] and ('Foot' in GROUP_NAMES[i] or 'Toe' in GROUP_NAMES[i]) for i in DOMINANT]) for side in ('Left','Right')}
def foot_contact():
    dg=bpy.context.evaluated_depsgraph_get(); ev=MESH.evaluated_get(dg); em=ev.to_mesh()
    points=np.array([MESH.matrix_world@v.co for v in em.vertices]); ev.to_mesh_clear(); result={}
    for side,mask in GROUP_MASKS.items():
        q=points[mask]; zmin=float(q[:,2].min()); near=q[q[:,2]<=zmin+0.005]; xy=near[:,:2].mean(axis=0)
        result[side.lower()]={'min_z_m':zmin,'ground_band_vertices':int(len(near)),'lowest_band_xy_m':[float(x) for x in xy]}
    return result
def unit(a):
    n=np.linalg.norm(a)
    return a/n if n else a

def direction_error(a,b):
    return math.degrees(math.acos(float(np.clip(np.dot(unit(a),unit(b)),-1,1))))

def vectors(arm, action, frame, side, name):
    arm.animation_data.action=action; scene.frame_set(frame); bpy.context.view_layer.update()
    bone=arm.pose.bones[f'mixamorig:{side}{name}']
    return np.asarray((arm.matrix_world@bone.tail)[:])-np.asarray((arm.matrix_world@bone.head)[:])

# Frame-zero rest axes are a separate baseline. Do not infer animated errors from them.
before=set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=fbx, automatic_bone_orientation=False)
SOURCE=next(o for o in bpy.data.objects if o not in before and o.type=='ARMATURE')
SOURCE_ACTION=SOURCE.animation_data.action
def rest_pose(arm):
    arm.animation_data.action = None
    for pb in arm.pose.bones: pb.matrix_basis = Matrix()
    return sample(arm,None,0)
rest={'target':rest_pose(TARGET),'source':rest_pose(SOURCE)}
rows=[]
for frame in range(1,22):
    t=sample(TARGET,TARGET_ACTION,frame); s=sample(SOURCE,SOURCE_ACTION,frame)
    errs={}
    for side in ('Left','Right'):
        for name in ('Arm','ForeArm'):
            errs[f'{side}{name}_direction_error_deg']=direction_error(vectors(TARGET,TARGET_ACTION,frame,side,name),vectors(SOURCE,SOURCE_ACTION,frame,side,name))
    contact=foot_contact()
    rows.append({'frame':frame,'time_s':(frame-1)/30,'target':t,'source':s,'arm_direction_errors':errs,'foot_contact_proxy':contact})
summary={}
for label in ('target','source'):
    for metric in ('stance_width_over_hip_width','left_foot_axis_yaw_deg','right_foot_axis_yaw_deg','left_toe_axis_yaw_deg','right_toe_axis_yaw_deg','left_upperarm_pitch_deg','right_upperarm_pitch_deg'):
        vals=[r[label][metric] for r in rows]
        summary[f'{label}.{metric}']={'min':min(vals),'max':max(vals),'mean':float(np.mean(vals))}
for metric in rows[0]['arm_direction_errors']:
    vals=[r['arm_direction_errors'][metric] for r in rows]
    summary[f'arm_direction_error.{metric}']={'max':max(vals),'mean':float(np.mean(vals))}
foot_contact_summary={}
for side in ('left','right'):
    points=[r['foot_contact_proxy'][side] for r in rows]; active=[p['min_z_m']<=0.04 for p in points]; speeds=[]
    for i in range(20):
        if active[i] and active[i+1]: speeds.append(float(np.linalg.norm(np.array(points[i+1]['lowest_band_xy_m'])-np.array(points[i]['lowest_band_xy_m']))*30))
    foot_contact_summary[side]={'contact_threshold_m':0.04,'contact_frames':sum(active),'consecutive_pairs':len(speeds),'speed_mps_min_max_mean':([min(speeds),max(speeds),float(np.mean(speeds))] if speeds else None),'proxy':'centroid of per-frame lowest 5mm of vertices dominated by foot/toe groups'}
report={'schema':'custodian.operator_run_gait_comparison.v1','fps':30,'unique_frames':21,'source_action':SOURCE_ACTION.name,'target_action':TARGET_ACTION.name,'rest_axes':rest,'summary':summary,'foot_contact_proxy_summary':foot_contact_summary,'frames':rows,'interpretation_limits':['Foot/toe axes are measured from rig bones; rest-axis offsets are reported separately and are not automatically corrected.','Arm direction errors compare upper-arm and forearm bone directions; this does not judge whether the motion looks natural.','Stance width is normalized to the inter-UpLeg-head distance; different rig proportions can affect this ratio.','Foot contact speeds use the lowest 5mm of a per-frame foot/toe vertex subset and are only a proxy because the lowest vertices can change as the sole rolls.']}
json.dump(report,open(out,'w'),indent=2)
print(json.dumps({'schema':report['schema'],'rest_axes':rest,'summary':summary,'foot_contact_proxy_summary':foot_contact_summary},indent=2))
