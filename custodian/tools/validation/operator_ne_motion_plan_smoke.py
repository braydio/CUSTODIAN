#!/usr/bin/env python3
"""Numerical regressions independent of Aseprite and the user's local master."""
from pathlib import Path
import copy
import json
import math
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/'custodian/tools/operator/ne_walk_retarget'))
from motion_plan import two_bone, transition_cost, validate_plan, dist
from run import pitch_quality_gate, wrapped_pitch_error_deg

LIMITS={'max_knee_fit_error_px':8,'max_joint_step_px':8,'max_rotation_step_degrees':60}
def pose(x=0):
    leg={'hip':{'x':x,'y':0},'knee':{'x':x+3,'y':4},'ankle':{'x':x,'y':8},'toe':{'x':x+2,'y':8},'thigh_delta':0,'shin_delta':0,'foot_delta':0}
    return {'legs':{'near':copy.deepcopy(leg),'far':copy.deepcopy(leg)}}

def main():
    assert abs(abs(wrapped_pitch_error_deg(179,-179))-2.0)<1e-10
    weighted=pitch_quality_gate([{'near':4,'far':8}],[{'near':4,'far':8}],['near'])
    assert weighted['baseline_weighted']==9.0 and weighted['candidate_weighted']==9.0
    # A large swing improvement can hide a visually important stance-foot
    # regression in the weighted aggregate; the per-side 5-degree gate catches it.
    masked=pitch_quality_gate([{'near':10,'far':10}],[{'near':16,'far':2}],['near'])
    assert masked['improvement_fraction']>=.10
    assert masked['maximum_single_frame_worsening_deg']==6.0 and not masked['passed']
    hip={'x':0,'y':0};ankle={'x':0,'y':8}
    for sign in (-1,1):
        k=two_bone(hip,ankle,5,5,sign)
        assert abs(dist(k,hip)-5)<1e-8 and abs(dist(k,ankle)-5)<1e-8
        assert math.copysign(1,k['x']*8)==sign
    assert two_bone(hip,{'x':0,'y':11},5,5,1) is None
    assert math.isfinite(transition_cost(pose(),pose(8),LIMITS))
    assert not math.isfinite(transition_cost(pose(),pose(8.01),LIMITS))
    # A stationary ankle is insufficient: a long boot's pitch can move its toe.
    pitch=pose();pitch['legs']['near']['toe']['x']=11
    assert not math.isfinite(transition_cost(pose(),pitch,LIMITS))
    # Frame-local checks cannot waive the cyclic seam.
    poses=[pose(i*.7) for i in range(15)]
    assert all(math.isfinite(transition_cost(poses[i-1],poses[i],LIMITS)) for i in range(1,15))
    assert not math.isfinite(transition_cost(poses[-1],poses[0],LIMITS))
    rig={'pivots':{'pelvis':{'x':0,'y':0}},'metrics':{side:{'hip':{'x':0,'y':0},'thigh_len':5,'shin_len':5} for side in ('near','far')}}
    row=pose();row['pelvis']={'x':0,'y':0}
    for leg in row['legs'].values():leg['knee_fit_error']=0
    valid={'frames':[copy.deepcopy(row) for _ in range(15)],'branches':{'near':1,'far':1}}
    validate_plan(valid,{'controls':LIMITS},rig)
    for label,mutate in (
        ('root bounds',lambda p:p['frames'][4]['pelvis'].update(x=8)),
        ('segment length',lambda p:p['frames'][4]['legs']['far']['knee'].update(y=5)),
        ('branch flip',lambda p:p['branches'].update(far=-1))):
        bad=copy.deepcopy(valid);mutate(bad)
        try:validate_plan(bad,{'controls':LIMITS},rig)
        except ValueError:pass
        else:raise AssertionError(label+' must fail')
    try:validate_plan({}, {'controls':{**LIMITS,'max_joint_step_px':9}}, {})
    except ValueError:pass
    else:raise AssertionError('widened thresholds must be rejected')
    crossover_regressions()
    print('PASS operator_ne_motion_plan: wrapped pitch, swing/stance weighting, masked-regression negative control, exact lengths, branches, unreachable target, toe pitch, cyclic seam, fixed limits')
def crossover_regressions():
    from crossover import calibration_plan, audit_annotations, branch
    from run import HERE
    annotations=json.loads((HERE/'annotations.json').read_text())
    authority=json.loads((HERE/'donor_authority.json').read_text())
    assert annotations['source_sha256']==authority['source_sha256']
    assert authority['full_cycle_regeneration_authorized'] is True
    assert len(set(authority['calibration_frames']))==5
    pivots={'near':[(63,75),(65,89),(66,100),(75,104)],'far':[(53,75),(52,83),(50,88),(48,91)]}
    rig={'pivots':{'pelvis':{'x':61,'y':66}},'metrics':{}}
    for side,pts in pivots.items():
        hip,knee,ankle,toe=[dict(zip(('x','y'),p)) for p in pts]
        rig['metrics'][side]={'hip':hip,'ankle':ankle,'toe':toe,'thigh_len':dist(hip,knee),'shin_len':dist(knee,ankle),
            'source_thigh_angle':math.atan2(knee['y']-hip['y'],knee['x']-hip['x']),
            'source_shin_angle':math.atan2(ankle['y']-knee['y'],ankle['x']-knee['x']),
            'source_foot_angle':math.atan2(toe['y']-ankle['y'],toe['x']-ankle['x'])}
    result=calibration_plan(annotations,rig);audit=audit_annotations(annotations,result)
    assert len(result['frames'])==15
    assert audit['ankle_x_order_changes']==[[2,3],[7,8]]
    assert audit['support_transitions']==[[6,7],[13,14]]
    assert not audit['direct_mapping_branch_changes'] and not audit['knee_fit_failures']
    assert audit['direct_mapping_joint_or_rotation_failures'] and not audit['full_cycle_pass']
    for i,row in enumerate(result['frames']):
        source=annotations['frames'][i]['landmarks']
        dx=source['ankle_near']['xy'][0]-source['ankle_far']['xy'][0]
        assert (row['legs']['near']['ankle']['x']-row['legs']['far']['ankle']['x'])*dx>0
        for side,leg in row['legs'].items():
            m=rig['metrics'][side]
            assert abs(dist(leg['hip'],leg['knee'])-m['thigh_len'])<1e-7
            assert abs(dist(leg['knee'],leg['ankle'])-m['shin_len'])<1e-7
            assert branch(leg)*result['branches'][side]>0
            assert leg['knee_fit_error']<=8
    bad=copy.deepcopy(annotations);bad['controls']['max_joint_step_px']=9
    try:calibration_plan(bad,rig)
    except ValueError:pass
    else:raise AssertionError('calibration may not relax V6 thresholds')
    from continuity import fit, validate_crossover, require_authority
    acceptance=json.loads((HERE/'crossover_acceptance.json').read_text())
    require_authority(annotations,authority,acceptance)
    for gate in ('authorization','receipt','annotations'):
        aa,dd,rr=copy.deepcopy(annotations),copy.deepcopy(authority),copy.deepcopy(acceptance)
        if gate=='authorization':dd['full_cycle_regeneration_authorized']=False
        if gate=='receipt':rr['accepted_by']='agent'
        if gate=='annotations':aa['frames'][3]['landmarks']['ankle_near']['xy'][0]+=1
        try:require_authority(aa,dd,rr)
        except ValueError:pass
        else:raise AssertionError('missing/changed acceptance must block '+gate)
    fitted=fit(annotations,rig,acceptance)
    validate_plan(fitted,annotations,rig)
    validate_crossover(fitted,annotations,acceptance)
    assert all(math.isfinite(transition_cost(fitted['frames'][i-1],fitted['frames'][i],LIMITS)) for i in range(15))
    for defect in ('lead','envelope'):
        bad=copy.deepcopy(fitted)
        if defect=='lead':bad['frames'][4]['legs']['near']['ankle']['x']=bad['frames'][4]['legs']['far']['ankle']['x']+1
        else:bad['frames'][11]['legs']['near']['toe']['x']+=20
        try:validate_crossover(bad,annotations,acceptance)
        except ValueError:pass
        else:raise AssertionError('crossover validation missed '+defect)
    print('PASS continuity: six transition failures corrected; accepted mapping/input locks, bounded calibration deviations, cyclic branches, lead order, missing-acceptance and geometry negative controls')
    print('PASS crossover calibration: exact donor lock, 15 traces, two lead reversals, stable branches, five-pose gate, full-cycle failure disclosure')

if __name__=='__main__':main()
