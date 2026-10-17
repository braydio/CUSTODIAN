#!/usr/bin/env python3
"""Exact NE donor intake and sparse crossover calibration. No full-cycle render."""
from __future__ import annotations
import argparse
import json
import math
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw
from run import HERE, sha, write, validate, distance
from motion_plan import add, sub, mul, angle, rotate, transition_cost, check_limits, two_bone


def calibration_plan(annotations, rig):
    """Transfer segment directions into immutable lengths, without neutral ankle bias.

    No temporal smoothing or swing attenuation: this deliberately exposes donor
    phase/identity errors before attempting another cyclic constrained fit.
    """
    check_limits(annotations['controls'])
    origin=rig['pivots']['pelvis']; rows=[]
    for f in annotations['frames']:
        r={n:dict(zip(('x','y'),l['xy'])) for n,l in f['landmarks'].items()}
        legs={};targets={}
        for side,m in rig['metrics'].items():
            hip=m['hip'].copy()
            thigh=sub(r['knee_'+side],r['hip_'+side]);shin=sub(r['ankle_'+side],r['knee_'+side])
            knee=add(hip,mul(thigh,m['thigh_len']/math.hypot(thigh['x'],thigh['y'])))
            ankle=add(knee,mul(shin,m['shin_len']/math.hypot(shin['x'],shin['y'])))
            raw_foot=math.degrees((angle(sub(r['toe_'+side],r['ankle_'+side]))-m['source_foot_angle']+math.pi)%(2*math.pi)-math.pi)
            foot=max(-24,min(24,raw_foot))
            legs[side]={'hip':hip,'knee':knee,'ankle':ankle,'toe':add(ankle,rotate(sub(m['toe'],m['ankle']),foot)),
                'preferred_knee':knee.copy(),'knee_fit_error':0,'raw_foot_delta':raw_foot,'pitch_clamp_deviation_deg':abs(raw_foot-foot),'thigh_delta':math.degrees(angle(thigh)-m['source_thigh_angle']),
                'shin_delta':math.degrees(angle(shin)-m['source_shin_angle']),'foot_delta':foot}
            targets[side]=ankle.copy()
        # Keep the existing .05px reach safety margin. The normalized trace can
        # be exactly straight; record the small inward target correction rather
        # than lowering the reach gate. Use stable branch signs, not the noise
        # sign of a nearly collinear three-pixel annotation.
        adjustments={}
        donor_dx=r['ankle_near']['x']-r['ankle_far']['x']
        if (legs['near']['ankle']['x']-legs['far']['ankle']['x'])*donor_dx<=0:
            legs['near']['ankle']['x']=legs['far']['ankle']['x']+donor_dx
        for side,l in legs.items():
            m=rig['metrics'][side];v=sub(l['ankle'],l['hip']);reach=math.hypot(v['x'],v['y'])
            safe=min(m['thigh_len']+m['shin_len']-.051,max(abs(m['thigh_len']-m['shin_len'])+.051,reach))
            l['ankle']=add(l['hip'],mul(v,safe/reach))
            knee=two_bone(l['hip'],l['ankle'],m['thigh_len'],m['shin_len'],1 if side=='near' else -1)
            assert knee is not None,'calibration target outside unchanged reach limits'
            l['knee']=knee;l['knee_fit_error']=distance(knee,l['preferred_knee'])
            l['toe']=add(l['ankle'],rotate(sub(m['toe'],m['ankle']),l['foot_delta']))
            l['thigh_delta']=math.degrees(angle(sub(knee,l['hip']))-m['source_thigh_angle'])
            l['shin_delta']=math.degrees(angle(sub(l['ankle'],knee))-m['source_shin_angle'])
            adjustments[side]=sub(l['ankle'],targets[side])
        rows.append({'target_adjustments':adjustments,'pelvis':origin.copy(),'raw_pelvis':origin.copy(),'legs':legs,'targets':targets,'raw_targets':targets})
    return {'schema':'custodian.ne_crossover_calibration.v1','reference_scale':1,
            'mapping':'segment directions normalized to accepted lengths; explicit minimum lead-order/reach corrections; stable near+ / far- IK; no neutral ankle bias, filtering, or swing attenuation',
            'frames':rows,'branches':{'near':1,'far':-1}}


def branch(l):
    k=sub(l['knee'],l['hip']);a=sub(l['ankle'],l['hip'])
    return k['x']*a['y']-k['y']*a['x']


def audit_annotations(a, motion):
    signs=[];transitions=[];branch_changes=[];jumps=[]
    for i,(f,row) in enumerate(zip(a['frames'],motion['frames'])):
        lm=f['landmarks'];dx=lm['ankle_near']['xy'][0]-lm['ankle_far']['xy'][0]
        signs.append(1 if dx>0 else -1 if dx<0 else 0)
        prev=motion['frames'][i-1]
        if not math.isfinite(transition_cost(prev,row,a['controls'])):jumps.append([((i-1)%15)+1,i+1])
        for s in ('near','far'):
            if branch(prev['legs'][s])*branch(row['legs'][s])<=0:branch_changes.append({'transition':[((i-1)%15)+1,i+1],'side':s})
    for i in range(15):
        if signs[i-1]!=signs[i]:transitions.append([((i-1)%15)+1,i+1])
    return {'lead_definition':'screen x of anatomical ankle; separate from depth ownership and sole support',
            'ankle_x_order_changes':transitions,'direct_mapping_joint_or_rotation_failures':jumps,
            'direct_mapping_branch_changes':branch_changes,
            'knee_fit_failures':[{'frame':i+1,'side':s,'error_px':l['knee_fit_error']} for i,row in enumerate(motion['frames']) for s,l in row['legs'].items() if l['knee_fit_error']>a['controls']['max_knee_fit_error_px']],
            'support_transitions':[[((i-1)%15)+1,i+1] for i in range(15) if a['frames'][i-1]['support']!=a['frames'][i]['support']],
            'support_status':'provisional; hidden swing and exact handoffs need human confirmation',
            'full_cycle_pass':False,'full_cycle_rendered':False}



def build_review_images(out,bundle,annotations,authority):
    # Native pixel placement only; Operator artwork is never resampled.
    donor=Image.open(bundle/'reference/knight_ne_walk_reference_15f_128.png')
    traces=Image.new('RGBA',(640,462),(40,47,55,255));d=ImageDraw.Draw(traces)
    for i,f in enumerate(annotations['frames']):
        x=i%5*128;y=i//5*154
        traces.alpha_composite(donor.crop((i*128,0,(i+1)*128,128)),(x,y+26))
        d.text((x+2,y+2),f"F{i+1:02} support? {f['support']}",fill='white')
        for side,color in [('near',(0,210,255)),('far',(255,0,190))]:
            pts=[(x+f['landmarks'][j+'_'+side]['xy'][0],y+26+f['landmarks'][j+'_'+side]['xy'][1]) for j in ('hip','knee','ankle','toe')]
            d.line(pts,fill=color,width=1)
            for joint,(px,py) in zip(('hip','knee','ankle','toe'),pts):
                hidden=f['landmarks'][joint+'_'+side]['visibility']=='occluded_inference'
                if hidden:d.ellipse((px-2,py-2,px+2,py+2),outline=color)
                else:d.point((px,py),fill='white')
    traces.save(out/'DONOR_ANNOTATIONS_15.png')
    ownership=Image.new('RGBA',(640,150),(40,47,55,255));d=ImageDraw.Draw(ownership)
    for j,i in enumerate(authority['calibration_frames']):
        ownership.alpha_composite(Image.open(out/f'ownership_f{i:02}.png'),(j*128,22))
        d.text((j*128+2,2),f'F{i:02} ownership',fill='white')
    ownership.save(out/'OWNERSHIP_5_POSES.png')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bundle',required=True,type=Path);p.add_argument('--rig',required=True,type=Path)
    p.add_argument('--output',required=True,type=Path);p.add_argument('--aseprite',default='aseprite')
    p.add_argument('--v55',type=Path,default=Path.home()/'.config/aseprite/scripts/operator_ne_pose_builder_v0_5_5_swing_stride_control.lua')
    args=p.parse_args();out=args.output.resolve();bundle=args.bundle.resolve();rig=args.rig.resolve()
    assert not out.exists(),'fresh output required'
    assert not out.is_relative_to(HERE.parents[3]/'custodian'),'review output must stay outside active project'
    a=json.loads((HERE/'annotations.json').read_text());authority=json.loads((HERE/'donor_authority.json').read_text())
    assert a['source_sha256']==authority['source_sha256']
    preflight=validate(bundle,a)
    acceptance=json.loads((HERE/'rig_acceptance.json').read_text());assert sha(rig)==acceptance['rig_sha256']
    assert sha(args.v55)==json.loads((HERE/'v55_dependency.json').read_text())['sha256']
    out.mkdir(parents=True)
    source=args.v55.read_text();core=source.split('-- UI\n-- ============================================================================')[0]
    start=core.index('local KNIGHT_F1_EMBEDDED =');end=core.index('local function clamp(v,lo,hi)',start);core=core[:start]+core[end:]
    from master_audit import export
    audit,_,_=export(args.aseprite,rig,out/'rig_preflight',core)
    assert audit['structural_gate_passed']
    motion=calibration_plan(a,audit);annotation_audit=audit_annotations(a,motion)
    write(out/'annotations.json',a);write(out/'donor_authority.json',authority);write(out/'motion_plan.json',motion)
    write(out/'annotation_audit.json',annotation_audit);write(out/'input_validation.json',preflight)
    driver=out/'calibration_generated.lua';driver.write_text(core+'\n'+(HERE/'rigid_raster.lua').read_text()+'\n'+(HERE/'calibration.lua').read_text())
    cfg={'output':str(out),'bundle':str(bundle),'annotations':a,'motion_plan':motion,'selected_frames':authority['calibration_frames']}
    command=[args.aseprite,'-b',str(rig),'--script-param','config='+json.dumps(cfg,separators=(',',':')),'--script',str(driver)]
    result=subprocess.run(command,capture_output=True,text=True);(out/'aseprite.log').write_text(result.stdout+result.stderr)
    assert sha(rig)==acceptance['rig_sha256'],'accepted rig mutated'
    assert result.returncode==0 and (out/'calibration_report.json').exists(),result.stdout+result.stderr
    report=json.loads((out/'calibration_report.json').read_text());palette={tuple(c) for c in report.pop('source_colors')}
    sheet=Image.new('RGBA',(5*256,168),(40,47,55,255));d=ImageDraw.Draw(sheet);donor=Image.open(bundle/'reference/knight_ne_walk_reference_15f_128.png')
    for j,row in enumerate(report['frames']):
        i=row['frame'];frame=Image.open(out/f'pose_f{i:02}.png');colors=set(frame.get_flattened_data());fail=row['failures']
        if any(c[3] not in (0,255) for c in colors):fail.append('partial_alpha')
        if not {c for c in colors if c[3]}<=palette:fail.append('source_palette_violation')
        bb=frame.getbbox()
        if not bb or bb[0]<=0 or bb[1]<=0 or bb[2]>=128 or bb[3]>=128:fail.append('canvas_bounds')
        for finding in preflight['marker_findings']:
            if finding['frame']==i:fail.append('donor_'+finding['joint']+'_not_established')
        row['alpha_bbox']=bb;row['lead_order_matches']=row['donor_ankle_dx']*row['operator_ankle_dx']>0
        if not row['lead_order_matches']:fail.append('crossover_order_lost')
        for s,l in row['legs'].items():
            m=audit['metrics'][s]
            if abs(distance(l['hip'],l['knee'])-m['thigh_len'])>1e-6 or abs(distance(l['knee'],l['ankle'])-m['shin_len'])>1e-6:fail.append(s+'_segment_length')
        row['pass']=not fail
        sheet.alpha_composite(donor.crop(((i-1)*128,0,i*128,128)),(j*256,40));sheet.alpha_composite(frame,(j*256+128,40))
        d.text((j*256+4,4),f"F{i:02} {authority['calibration_roles'][j]}\nKnight | Operator",fill='white')
    sheet.save(out/'CROSSOVER_CALIBRATION_5_POSES.png')
    build_review_images(out,bundle,a,authority)
    report.update(annotation_audit=annotation_audit,input_validation=preflight,rig_sha256=sha(rig),source_sha256=a['source_sha256'],timing_fps=None,accepted=False,
        passing_calibration_poses=sum(r['pass'] for r in report['frames']),full_cycle_rendered=False,
        implementation_sha256={n:sha(HERE/n) for n in ('crossover.py','calibration.lua','rigid_raster.lua')})
    write(out/'calibration_report.json',report);write(out/'run_receipt.json',{'command':command,'rig_unchanged':True,'accepted':False,'full_cycle_rendered':False})
    print(json.dumps({'output':str(out),'passing_calibration_poses':report['passing_calibration_poses'],'poses':5,'annotation_audit':annotation_audit}))
    return 0 if report['passing_calibration_poses']==5 else 2

if __name__=='__main__':raise SystemExit(main())
