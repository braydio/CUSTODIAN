"""Diagnose ITER003 penetration and cycle-derived planted-foot travel.

Usage: blender -b <iter003.blend> --python diagnose_run_contact_iter004.py -- <gait_comparison.json> <report.json>

Uses the previously selected fixed 12-vertex heel/toe landmarks unchanged.
Forward is derived in rest pose as world up crossed with right-minus-left hip;
for this rig it points Operator -Y. In-place forward root speed is the negative median signed
forward velocity of pelvis-relative fixed landmarks over adjacent samples where
both points lie in the existing 40mm contact band. Reconstructed world motion
adds that single cycle-derived constant forward velocity to the observed pelvis
trajectory; residual planted-point displacement is then measured per contact
pair. This is an inference from contact-phase motion, not source locomotion data.
"""
import bpy, sys, json, math, statistics
import numpy as np
from mathutils import Matrix, Vector

gait_path, out = sys.argv[sys.argv.index('--') + 1:]
scene=bpy.context.scene
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
mesh=next(o for o in bpy.data.objects if o.type=='MESH' and len(o.vertex_groups))
action=arm.animation_data.action
gait=json.load(open(gait_path))
fixed=gait['stable_landmark_indices']
fps=scene.render.fps/scene.render.fps_base
threshold=0.04

def evaluated_points():
    dg=bpy.context.evaluated_depsgraph_get(); ev=mesh.evaluated_get(dg); em=ev.to_mesh()
    pts=np.asarray([mesh.matrix_world @ v.co for v in em.vertices],dtype=np.float64)
    ev.to_mesh_clear(); return pts

# True unanimated rest, and rest-pose sole/landmark calibration.
arm.animation_data.action=None
for pb in arm.pose.bones: pb.matrix_basis=Matrix()
scene.frame_set(0); bpy.context.view_layer.update()
rest=evaluated_points()
rest_lo=rest.min(axis=0); rest_hi=rest.max(axis=0)
camera_transform={'uniform_scale':1.23547,'rest_bounds_min_m':rest_lo.tolist(),'rest_bounds_max_m':rest_hi.tolist(),
                  'pivot_center_xy_m':[((rest_lo[0]+rest_hi[0])*0.5),((rest_lo[1]+rest_hi[1])*0.5)],
                  'ground_pivot_z_m':float(rest_lo[2]),'root_pixel_128':[64,106],
                  'elevation_deg':45.0,'pixels_per_meter_at_128':50.0}
left=arm.matrix_world @ arm.pose.bones['mixamorig:LeftUpLeg'].head
right=arm.matrix_world @ arm.pose.bones['mixamorig:RightUpLeg'].head
lateral=(right-left).copy(); lateral.z=0; lateral.normalize()
forward=Vector((0,0,1)).cross(lateral); forward.normalize()
arm.animation_data.action=action

penetration=[]; rows=[]; stable={key:{kind:[] for kind in value} for key,value in fixed.items()}
for frame in range(1,22):
    scene.frame_set(frame); bpy.context.view_layer.update(); pts=evaluated_points()
    hip_l=arm.matrix_world @ arm.pose.bones['mixamorig:LeftUpLeg'].head
    hip_r=arm.matrix_world @ arm.pose.bones['mixamorig:RightUpLeg'].head
    hip=(hip_l+hip_r)*0.5
    low=np.flatnonzero(pts[:,2] < -0.005)
    entries=[]
    for vi in low:
        v=mesh.data.vertices[int(vi)]
        wg=sorted(((mesh.vertex_groups[g.group].name,float(g.weight)) for g in v.groups),key=lambda x:-x[1])
        entry={'vertex':int(vi),'xyz_m':pts[vi].round(6).tolist(),'z_mm':round(float(pts[vi,2]*1000),3),'dominant_weights':wg[:4]}
        entries.append(entry); penetration.append({'frame':frame,**entry})
    landmark_frame={}
    for side,regions in fixed.items():
        for kind,ids in regions.items():
            p=pts[np.asarray(ids,dtype=np.int64)].mean(axis=0)
            stable[side][kind].append(p)
            v_z=pts[np.asarray(ids,dtype=np.int64),2]*1000
            landmark_frame[f'{side}_{kind}']={'xyz_m':p.tolist(),'z_mm':float(p[2]*1000),
                                               'fixed_vertex_z_mm_min':float(v_z.min()),'fixed_vertex_z_mm_max':float(v_z.max())}
    toe_pb=arm.pose.bones['mixamorig:RightToeBase']; foot_pb=arm.pose.bones['mixamorig:RightFoot']
    right_bones={'foot_head_xyz_m':list(arm.matrix_world@foot_pb.head),'toe_head_xyz_m':list(arm.matrix_world@toe_pb.head),'toe_tail_xyz_m':list(arm.matrix_world@toe_pb.tail)}
    rows.append({'frame':frame,'time_s':(frame-1)/fps,'hip_center_xyz_m':list(hip),'vertices_below_minus5mm':int(len(low)),
                 'min_mesh_z_mm':float(pts[:,2].min()*1000),'penetrating_vertices':entries,'fixed_landmarks':landmark_frame,
                 'right_foot_bones':right_bones})

# Signed forward contact estimates from fixed points relative to pelvis.
forward_np=np.asarray(forward[:],dtype=np.float64)
lateral_np=np.asarray(lateral[:],dtype=np.float64)
hip=np.asarray([r['hip_center_xyz_m'] for r in rows],dtype=np.float64)
pair_data=[]
for side,regions in fixed.items():
    for kind,ids in regions.items():
        points=np.asarray(stable[side][kind]); rel=points-hip
        for i in range(20):
            if points[i,2] <= threshold and points[i+1,2] <= threshold:
                dt=1/fps
                relv=(rel[i+1]-rel[i])/dt
                pair_data.append({'landmark':f'{side}_{kind}','frame_pair':[i+1,i+2],
                                  'contact_height_mm':[float(points[i,2]*1000),float(points[i+1,2]*1000)],
                                  'relative_velocity_forward_mps':float(np.dot(relv,forward_np)),
                                  'relative_velocity_lateral_mps':float(np.dot(relv,lateral_np)),
                                  'estimated_root_forward_mps':float(-np.dot(relv,forward_np))})
if not pair_data:
    raise RuntimeError('no adjacent fixed-landmark contact samples; root travel cannot be reconstructed')
root_v=float(statistics.median(p['estimated_root_forward_mps'] for p in pair_data))
reconstructed=[]
for p in pair_data:
    side,kind=p['landmark'].split('_',1); f0,f1=p['frame_pair']
    p0=np.asarray(stable[side][kind][f0-1]); p1=np.asarray(stable[side][kind][f1-1])
    residual=(p1-p0)/ (1/fps)+forward_np*root_v
    p['reconstructed_velocity_forward_mps']=float(np.dot(residual,forward_np))
    p['reconstructed_velocity_lateral_mps']=float(residual[0])
    p['reconstructed_horizontal_speed_mps']=float(np.linalg.norm(residual[:2]))
    reconstructed.append(p['reconstructed_horizontal_speed_mps'])

contact_frames={}
contact_intervals={}
for side,regions in fixed.items():
    for kind in regions:
        ps=np.asarray(stable[side][kind])
        key=f'{side}_{kind}'
        hits=[i for i,p in enumerate(ps) if p[2]<=threshold]
        contact_frames[key]=[i+1 for i in hits]
        runs=[]
        for i in hits:
            if not runs or i != runs[-1][-1]+1: runs.append([i])
            else: runs[-1].append(i)
        intervals=[]
        for run in runs:
            if len(run)<2: continue
            rec=np.asarray([ps[i]+forward_np*root_v*(i/fps) for i in run])
            deltas=np.diff(rec[:,:2],axis=0)
            intervals.append({'frames':[run[0]+1,run[-1]+1],'sample_count':len(run),
                              'reconstructed_net_displacement_xy_m':(rec[-1,:2]-rec[0,:2]).tolist(),
                              'reconstructed_net_displacement_mm':float(np.linalg.norm(rec[-1,:2]-rec[0,:2])*1000),
                              'reconstructed_path_length_mm':float(np.linalg.norm(deltas,axis=1).sum()*1000),
                              'max_reconstructed_pair_displacement_mm':float(np.linalg.norm(deltas,axis=1).max()*1000)})
        contact_intervals[key]=intervals

weights={}
penetrating_by_bone={}
for row in penetration:
    dominant=row['dominant_weights'][0][0] if row['dominant_weights'] else 'none'
    penetrating_by_bone[dominant]=penetrating_by_bone.get(dominant,0)+1
rest_sole={}
for side in ('Left','Right'):
    names=(f'mixamorig:{side}Foot',f'mixamorig:{side}ToeBase')
    group_ids={g.name:g.index for g in mesh.vertex_groups}
    ids=[]
    for v in mesh.data.vertices:
        if any(mesh.vertex_groups[g.group].name in names and g.weight>=0.2 for g in v.groups): ids.append(v.index)
    rest_sole[side]={'weighted_vertex_count':len(ids),'min_z_mm':float(rest[np.asarray(ids),2].min()*1000),'min_z_vertex_ids':[int(i) for i in np.asarray(ids)[np.isclose(rest[np.asarray(ids),2],rest[np.asarray(ids),2].min())][:32]]}
dominant_names=set(p['dominant_weights'][0][0] for p in penetration if p['dominant_weights'])
bone_context={}
for name in sorted(dominant_names):
    b=arm.data.bones.get(name)
    if b:
        bone_context[name]={'parent':b.parent.name if b.parent else None,'rest_head_m':list(arm.matrix_world@b.head_local),'rest_tail_m':list(arm.matrix_world@b.tail_local)}

report={'schema':'custodian.operator_run_contact_diagnosis.v1','action':action.name,'fps':fps,'unique_frames':21,'cycle_duration_s':21/fps,
        'ground_plane_z_m':0.0,'penetration_threshold_m':-0.005,'penetrating_vertex_observations':len(penetration),
        'distinct_penetrating_vertices':len({p['vertex'] for p in penetration}),
        'render_camera_contract':camera_transform,
        'penetrating_vertices_by_dominant_group':penetrating_by_bone,
        'penetrating_bone_rest_context':bone_context,
        'frame_summary':[{'frame':r['frame'],'vertices_below_minus5mm':r['vertices_below_minus5mm'],'min_mesh_z_mm':r['min_mesh_z_mm']} for r in rows],
        'rest_pose_foot_geometry':rest_sole,'fixed_landmark_indices':fixed,'contact_frames':contact_frames,
        'reconstructed_contact_intervals':contact_intervals,
        'forward_axis_world':forward_np.tolist(),'lateral_axis_world':lateral_np.tolist(),'root_velocity_method':'negative median signed forward velocity of pelvis-relative fixed heel/toe centroids over adjacent pairs with both heights <=40mm; 21-frame 30fps cycle; root velocity held constant for reconstructed trajectory',
        'estimated_forward_root_velocity_mps':root_v,'contact_pairs':pair_data,
        'reconstructed_contact_horizontal_speed_mps_median_max':[float(statistics.median(reconstructed)),float(max(reconstructed))] if reconstructed else None,
        'frames':rows,
        'interpretation_limits':['Forward travel is inferred from in-place contact-phase motion, not authored root translation.','The inferred constant speed is fit to the same contact windows being evaluated; reconstructed residuals are descriptive, not independent proof of natural planted contact.','Only fixed landmarks from the existing gait report are used; no lowest-vertex identity changes occur.']}
json.dump(report,open(out,'w'),indent=2)
print(json.dumps({k:v for k,v in report.items() if k not in ('frames','contact_pairs')},indent=2))
