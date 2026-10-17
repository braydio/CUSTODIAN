#!/usr/bin/env python3
"""Numerical regressions independent of Aseprite and the user's local master."""
from pathlib import Path
import copy
import math
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/'custodian/tools/operator/ne_walk_retarget'))
from motion_plan import two_bone, transition_cost, validate_plan, dist

LIMITS={'max_knee_fit_error_px':8,'max_joint_step_px':8,'max_rotation_step_degrees':60}
def pose(x=0):
    leg={'hip':{'x':x,'y':0},'knee':{'x':x+3,'y':4},'ankle':{'x':x,'y':8},'toe':{'x':x+2,'y':8},'thigh_delta':0,'shin_delta':0,'foot_delta':0}
    return {'legs':{'near':copy.deepcopy(leg),'far':copy.deepcopy(leg)}}

def main():
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
    print('PASS operator_ne_motion_plan: exact lengths, branches, unreachable target, toe pitch, cyclic seam, fixed limits')
if __name__=='__main__':main()
