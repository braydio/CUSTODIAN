"""Bounded continuity fit around the human-accepted crossover mapping and poses."""
from __future__ import annotations
import copy
import hashlib
import json
import math
from pathlib import Path
from motion_plan import SIDES, sub, angle, dist, check_limits, validate_plan


def require_authority(annotations, authority, acceptance):
    here=Path(__file__).resolve().parent
    if not authority.get('full_cycle_regeneration_authorized') or authority.get('calibration_decision')!='accepted_for_continuity_fitting':
        raise ValueError('five crossover calibration poses require human acceptance before full-cycle regeneration')
    if acceptance.get('accepted_by')!='human_user' or acceptance.get('checkpoint')!='65369509d':
        raise ValueError('missing human crossover acceptance receipt')
    if annotations!=json.loads((here/'annotations.json').read_text()) or hashlib.sha256((here/'annotations.json').read_bytes()).hexdigest()!=acceptance['annotations_sha256']:
        raise ValueError('accepted annotations changed')
    if hashlib.sha256((here/'crossover.py').read_bytes()).hexdigest()!=acceptance['mapping_sha256']:
        raise ValueError('accepted crossover mapping changed')
    if annotations['source_sha256']!=authority['source_sha256'] or authority['source_sha256']!=acceptance['source_sha256']:
        raise ValueError('accepted donor changed')


def fit(annotations,rig,acceptance=None):
    import numpy as np
    import scipy
    from scipy.optimize import minimize
    from crossover import calibration_plan
    here=Path(__file__).resolve().parent
    if acceptance is None:acceptance=json.loads((here/'crossover_acceptance.json').read_text())
    require_authority(annotations,json.loads((here/'donor_authority.json').read_text()),acceptance)
    check_limits(annotations['controls'])
    base=calibration_plan(annotations,rig)
    locked={int(k)-1 for k in acceptance['pose_locks']}
    # The reviewed pixels are immutable targets, not a branch assignment.
    # Fit a stable branch to those targets rather than inheriting near-straight
    # renderer IK branch choices that varied among the five static poses.
    raw=copy.deepcopy(base)
    free=list(range(15))
    angles=np.zeros((15,2,3))
    for i,row in enumerate(base['frames']):
        for s,side in enumerate(SIDES):
            l=row['legs'][side];a=angle(sub(l['knee'],l['hip']));b=angle(sub(l['ankle'],l['knee']))
            bend=abs((b-a+math.pi)%(2*math.pi)-math.pi)
            angles[i,s]=[a,bend,math.radians(l['foot_delta'])]
    original=angles.copy()
    preferred=np.array([[[row['legs'][s]['preferred_knee'][k] for k in ('x','y')] for s in SIDES] for row in base['frames']])
    hips=np.array([[[row['legs'][s]['hip'][k] for k in ('x','y')] for s in SIDES] for row in base['frames']])
    lengths=np.array([[rig['metrics'][s]['thigh_len'],rig['metrics'][s]['shin_len']] for s in SIDES])
    toe_vec=np.array([[rig['metrics'][s]['toe'][k]-rig['metrics'][s]['ankle'][k] for k in ('x','y')] for s in SIDES])
    signs=np.array([1,-1]);lead=np.array([1 if f['landmarks']['ankle_near']['xy'][0]>f['landmarks']['ankle_far']['xy'][0] else -1 for f in annotations['frames']])
    def decode(x):
        return x.reshape((15,2,3))
    def geometry(a):
        thigh=a[:,:,0];shin=thigh+a[:,:,1]*signs
        knee=hips+lengths[:,0,None]*np.stack((np.cos(thigh),np.sin(thigh)),axis=-1)
        ankle=knee+lengths[:,1,None]*np.stack((np.cos(shin),np.sin(shin)),axis=-1)
        foot=a[:,:,2];c=np.cos(foot);sn=np.sin(foot)
        toe=ankle+np.stack((toe_vec[:,0]*c-toe_vec[:,1]*sn,toe_vec[:,0]*sn+toe_vec[:,1]*c),axis=-1)
        return np.stack((hips,knee,ankle,toe),axis=2),np.stack((thigh,shin,foot),axis=-1)
    baseline,_=geometry(original)
    for key,legs in acceptance['pose_locks'].items():
        for s,side in enumerate(SIDES):
            for j,name in enumerate(('hip','knee','ankle','toe')):
                baseline[int(key)-1,s,j]=[legs[side][name]['x'],legs[side][name]['y']]
    def objective(x):
        a=decode(x);g,_=geometry(a)
        # Stay near the accepted mapping; a small cyclic acceleration term
        # distributes correction without a phase filter or neutral-stride bias.
        e=(g-baseline)**2
        acceleration=np.roll(g,1,axis=0)-2*g+np.roll(g,-1,axis=0)
        weights=np.ones((15,1,1,1));weights[list(locked)]=4
        return float(np.sum(e*weights)+.025*np.sum(acceleration**2))/1000
    def constraints(x):
        a=decode(x);g,rot=geometry(a);step=g-np.roll(g,1,axis=0)
        dr=(rot-np.roll(rot,1,axis=0)+np.pi)%(2*np.pi)-np.pi
        knee_error=np.sum((g[:,:,1]-preferred)**2,axis=-1)
        reach=np.sqrt(np.sum((g[:,:,2]-hips)**2,axis=-1))
        # Preserve the calibrated lead sign on EVERY frame, not just anchors.
        # A .5px internal sign margin protects it against raster-phase correction.
        separation=(g[:,0,2,0]-g[:,1,2,0])*lead
        lead_floor=np.maximum(.5,.75*np.abs(baseline[:,0,2,0]-baseline[:,1,2,0]))
        anchor_error=np.sum((g[list(locked)]-baseline[list(locked)])**2,axis=-1)
        return np.concatenate(((1-np.sum(step**2,axis=-1)/7.6**2).ravel(),
            (1-dr**2/math.radians(58)**2).ravel(),(1-knee_error/8**2).ravel(),
            ((lengths.sum(axis=1)-.05-reach)/10).ravel(),
            ((reach-np.abs(lengths[:,0]-lengths[:,1])-.05)/10).ravel(),(separation-lead_floor)/10,
            (1-anchor_error/6**2).ravel()))
    bounds=[]
    for i in free:
        for s in range(2):bounds.extend([(original[i,s,0]-math.radians(65),original[i,s,0]+math.radians(65)),(.005,math.pi-.005),(-math.radians(24),math.radians(24))])
    result=minimize(objective,original[free].ravel(),method='SLSQP',bounds=bounds,
        constraints={'type':'ineq','fun':constraints},options={'maxiter':1000,'ftol':1e-12})
    residual=float(np.min(constraints(result.x)))
    if not result.success or residual< -1e-7:
        raise ValueError(f'continuity fit failed: {result.message}; minimum constraint {residual}')
    a=decode(result.x);g,rot=geometry(a)
    for i,row in enumerate(base['frames']):
        for s,side in enumerate(SIDES):
            l=row['legs'][side];m=rig['metrics'][side]
            for j,name in enumerate(('hip','knee','ankle','toe')):l[name]=dict(zip(('x','y'),map(float,g[i,s,j])))
            l['thigh_delta']=math.degrees(rot[i,s,0]-m['source_thigh_angle'])
            l['shin_delta']=math.degrees(rot[i,s,1]-m['source_shin_angle'])
            l['foot_delta']=math.degrees(rot[i,s,2])
            l['knee_fit_error']=dist(l['knee'],l['preferred_knee'])
            l['continuity_ankle_correction_px']=dist(l['ankle'],raw['frames'][i]['legs'][side]['ankle'])
            l['continuity_knee_correction_px']=dist(l['knee'],raw['frames'][i]['legs'][side]['knee'])
    base.update(schema='custodian.ne_continuity_plan.v1',filter='bounded constrained angle fit around immutable reviewed mapping targets; all-frame lead sign and 75% separation floor',
        calibration_target_frames=sorted(i+1 for i in locked),calibration_max_joint_deviation_px=6,optimizer={'method':'SLSQP','scipy':scipy.__version__,'numpy':np.__version__,
        'iterations':int(result.nit),'objective':float(result.fun),'minimum_constraint':residual},
        internal_guards={'max_joint_step_px':7.6,'max_rotation_step_degrees':58,'calibration_max_joint_deviation_px':6,'minimum_lead_fraction':.75},
        secondary_motion='existing independent phase controls retained',score=float(result.fun))
    validate_plan(base,annotations,rig)
    validate_crossover(base,annotations,acceptance)
    return base


def validate_crossover(plan,annotations,acceptance):
    if len(plan['frames'])!=15:raise ValueError('15 crossover frames required')
    for i,row in enumerate(plan['frames']):
        f=annotations['frames'][i];lm=f['landmarks']
        dx=lm['ankle_near']['xy'][0]-lm['ankle_far']['xy'][0]
        if (row['legs']['near']['ankle']['x']-row['legs']['far']['ankle']['x'])*dx<=0:
            raise ValueError('accepted crossover ordering changed')
    for key,legs in acceptance['pose_locks'].items():
        row=plan['frames'][int(key)-1]
        for s,expected in legs.items():
            l=row['legs'][s]
            for joint in ('hip','knee','ankle','toe'):
                if dist(l[joint],expected[joint])>6+1e-7:raise ValueError('calibration fitting envelope exceeded')

