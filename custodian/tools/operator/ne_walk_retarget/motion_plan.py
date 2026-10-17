"""Cyclic constrained IK planning; accepted rig lengths and QA limits stay fixed."""
from __future__ import annotations
import math

SIDES=('near','far')
def add(a,b):return {'x':a['x']+b['x'],'y':a['y']+b['y']}
def sub(a,b):return {'x':a['x']-b['x'],'y':a['y']-b['y']}
def mul(a,t):return {'x':a['x']*t,'y':a['y']*t}
def dist(a,b):return math.hypot(a['x']-b['x'],a['y']-b['y'])
def angle(a):return math.atan2(a['y'],a['x'])
def delta(a,b):return abs((a-b+180)%360-180)
def rotate(v,deg):
    c,s=math.cos(math.radians(deg)),math.sin(math.radians(deg))
    return {'x':v['x']*c-v['y']*s,'y':v['x']*s+v['y']*c}

def two_bone(hip,ankle,l1,l2,branch):
    v=sub(ankle,hip);d=math.hypot(v['x'],v['y'])
    if not abs(l1-l2)+.05<=d<=l1+l2-.05:return None
    u=mul(v,1/d);along=(l1*l1-l2*l2+d*d)/(2*d)
    h=math.sqrt(max(0,l1*l1-along*along))
    # The chosen sign is the cross(knee-hip, ankle-hip) sign.
    return add(add(hip,mul(u,along)),{'x':u['y']*h*branch,'y':-u['x']*h*branch})

def transition_cost(a,b,limits):
    cost=0
    for side in SIDES:
        x,y=a['legs'][side],b['legs'][side]
        for joint in ('hip','knee','ankle','toe'):
            step=dist(x[joint],y[joint])
            if step>limits['max_joint_step_px']+1e-8:return math.inf
            cost+=step*step
        for part in ('thigh','shin','foot'):
            step=delta(x[part+'_delta'],y[part+'_delta'])
            if step>limits['max_rotation_step_degrees']+1e-8:return math.inf
            cost+=.01*step*step
    return cost

def plan(annotations,rig):
    frames=annotations['frames'];limits=annotations['controls'];metrics=rig['metrics'];origin=rig['pivots']['pelvis']
    refs=[{n:{'x':v['xy'][0],'y':v['xy'][1]} for n,v in f['landmarks'].items()} for f in frames]
    n=len(refs)
    canonical=sum(m['thigh_len']+m['shin_len'] for m in metrics.values())/2
    scale=sum(canonical/(sum(dist(r['hip_'+s],r['knee_'+s])+dist(r['knee_'+s],r['ankle_'+s]) for s in SIDES)/2) for r in refs)/n
    means={name:{axis:sum(r[name][axis] for r in refs)/n for axis in ('x','y')} for name in ('pelvis','ankle_near','ankle_far')}
    raw=[];data=[]
    for f,r in zip(frames,refs):
        raw.append({s:add(metrics[s]['ankle'],mul(sub(r['ankle_'+s],means['ankle_'+s]),scale*(1 if f['support']==s else limits['swing_reference_blend']))) for s in SIDES})
    raw_rot=[{s:max(-24,min(24,math.degrees((angle(sub(r['toe_'+s],r['ankle_'+s]))-metrics[s]['source_foot_angle']+math.pi)%(2*math.pi)-math.pi))) for s in SIDES} for r in refs]
    kernel=((-2,1),(-1,4),(0,6),(1,4),(2,1))
    for i,r in enumerate(refs):
        # Position and pitch must be filtered together: a smooth ankle alone
        # can still produce a toe jump from an unfiltered boot rotation.
        targets={s:{axis:sum(raw[(i+o)%n][s][axis]*w for o,w in kernel)/16 for axis in ('x','y')} for s in SIDES}
        foot_rot={s:sum(raw_rot[(i+o)%n][s]*w for o,w in kernel)/16 for s in SIDES}
        data.append({'targets':targets,'raw_targets':raw[i],'foot_rot':foot_rot,
                     'raw_pelvis':add(origin,mul(sub(r['pelvis'],means['pelvis']),scale))})
    best=None
    for branch_near in (1,-1):
      for branch_far in (1,-1):
        branches={'near':branch_near,'far':branch_far};states=[]
        for i,r in enumerate(refs):
            row=[];d=data[i]
            for ix in range(-28,29):
              for iy in range(-24,25):
                pelvis=add(origin,{'x':ix*.25,'y':iy*.25});legs={};local_cost=dist(pelvis,d['raw_pelvis'])**2*.15
                for side in SIDES:
                    m=metrics[side];hip=add(m['hip'],sub(pelvis,origin));ankle=d['targets'][side]
                    knee=two_bone(hip,ankle,m['thigh_len'],m['shin_len'],branches[side])
                    if knee is None:break
                    v=sub(r['knee_'+side],r['hip_'+side]);preferred=add(hip,mul(v,m['thigh_len']/math.hypot(v['x'],v['y'])))
                    fit=dist(knee,preferred)
                    if fit>limits['max_knee_fit_error_px']:break
                    foot=d['foot_rot'][side]
                    legs[side]={'hip':hip,'knee':knee,'ankle':ankle,
                        'toe':add(ankle,rotate(sub(m['toe'],m['ankle']),foot)),
                        'thigh_delta':math.degrees(angle(sub(knee,hip))-m['source_thigh_angle']),
                        'shin_delta':math.degrees(angle(sub(ankle,knee))-m['source_shin_angle']),
                        'foot_delta':foot,'preferred_knee':preferred,'knee_fit_error':fit}
                    local_cost+=fit*fit*.08
                if len(legs)==2:row.append({'pelvis':pelvis,'legs':legs,'local_cost':local_cost,**d})
            row.sort(key=lambda s:s['local_cost']);states.append(row[:96])
        if any(not row for row in states):continue
        # Enumerate initial candidates: the 15->1 constraint participates in
        # selection, rather than being inspected only after a greedy forward run.
        for start in range(min(12,len(states[0]))):
            costs=[math.inf]*len(states[0]);costs[start]=states[0][start]['local_cost'];parents=[]
            for i in range(1,n):
                next_cost=[];prev_indices=[]
                for b in states[i]:
                    choices=[c+transition_cost(a,b,limits) if math.isfinite(c) else math.inf for a,c in zip(states[i-1],costs)]
                    k=min(range(len(choices)),key=choices.__getitem__)
                    next_cost.append(choices[k]+b['local_cost']);prev_indices.append(k)
                costs=next_cost;parents.append(prev_indices)
            finals=[c+transition_cost(s,states[0][start],limits) for s,c in zip(states[-1],costs)]
            end=min(range(len(finals)),key=finals.__getitem__);score=finals[end]
            if not math.isfinite(score) or best and score>=best[0]:continue
            path=[end]
            for table in reversed(parents):path.append(table[path[-1]])
            path.reverse();best=(score,[states[i][k] for i,k in enumerate(path)],branches)
    if best is None:raise ValueError('no cyclic trajectory satisfies fixed reach/fit/joint/rotation limits')
    return {'schema':'custodian.ne_cyclic_motion_plan.v1','reference_scale':scale,
            'filter':'cyclic [1,4,6,4,1]/16 applied to canonical reference ankle positions and boot pitches before IK',
            'score':best[0],'branches':best[2],'frames':best[1]}
