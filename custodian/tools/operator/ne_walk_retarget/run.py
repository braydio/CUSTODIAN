#!/usr/bin/env python3
"""Isolated, hash-bound NE gait experiment. Never publishes Operator sources."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import warnings
from pathlib import Path
import subprocess
import sys
from PIL import Image, ImageDraw

warnings.filterwarnings('ignore', category=DeprecationWarning, message='Image.Image.getdata*')

HERE = Path(__file__).resolve().parent
JOINTS = ('pelvis','hip_near','knee_near','ankle_near','toe_near','hip_far','knee_far','ankle_far','toe_far')

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def write(path, data):
    Path(path).write_text(json.dumps(data, indent=2, allow_nan=False)+'\n')

def distance(a,b):
    return math.hypot(a['x']-b['x'],a['y']-b['y'])

def validate(bundle, annotations):
    assert annotations['timing_fps'] is None, 'timing selection is outside this experiment'
    assert annotations['registration']=={'center_x':64,'root':[64,106],'ground_y':107}, 'registration drift'
    controls=annotations['controls']
    assert 0<=controls['swing_reference_blend']<=1
    assert abs(controls['upper_body_counter_motion_degrees'])<=10
    assert 0<=controls['robe_response_gain']<=0.35
    assert all(controls[k]>0 for k in ('max_knee_fit_error_px','max_joint_step_px','max_rotation_step_degrees'))
    m=json.loads((bundle/'MANIFEST.json').read_text())
    strip=bundle/'reference/knight_ne_walk_reference_15f_128.png'
    assert sha(strip)==m['source_sha256']==annotations['source_sha256'], 'source hash mismatch'
    source=Image.open(strip)
    assert source.mode=='RGBA' and source.size==(1920,128)
    assert len(m['frames_metadata'])==len(annotations['frames'])==15
    rebuilt=Image.new('RGBA',(1920,128))
    marker_findings=[]
    for i,(metadata,record) in enumerate(zip(m['frames_metadata'],annotations['frames'])):
        path=bundle/'reference/frames'/metadata['name']
        assert sha(path)==metadata['sha256']==record['source_sha256'], f'frame {i+1} hash'
        frame=Image.open(path)
        assert frame.mode=='RGBA' and frame.size==(128,128)
        assert source.crop((i*128,0,(i+1)*128,128)).tobytes()==frame.tobytes()
        rebuilt.paste(frame,(i*128,0))
        assert record['frame']==i+1 and set(record['landmarks'])==set(JOINTS)
        assert record['support'] in ('near','far')
        for name,l in record['landmarks'].items():
            assert l['id']==f'f{i+1:02}.{name}' and l['provenance']
            assert l['visibility'] in ('visible_estimate','occluded_inference')
            x,y=l['xy'];assert isinstance(x,int) and isinstance(y,int) and 0<=x<128 and 0<=y<128
            pixel=frame.getpixel((x,y))
            # Black/dim pixels cannot authenticate a visible anatomy marker.
            if l['visibility']=='visible_estimate' and name.startswith(('ankle','toe')) and (pixel[3]<255 or max(pixel[:3])<55):
                review=l.get('sample_review',{})
                if pixel[3]==255 and review.get('decision')=='opaque_boot_material' and review.get('rgba')==list(pixel) and review.get('evidence'):
                    continue
                marker_findings.append({'frame':i+1,'joint':name,'rgba':pixel,'reason':'visible_boot_marker_not_established'})
        assert len({tuple(l['xy']) for l in record['landmarks'].values()})==9
    assert rebuilt.tobytes()==source.tobytes()
    return {'source_hash':sha(strip),'frame_hashes_passed':15,'pixel_reassembly_exact':True,'marker_findings':marker_findings}


def alpha_voids(image):
    """Return enclosed transparent components; topology is a diagnostic, not art approval."""
    alpha=image.getchannel('A');w,h=image.size
    empty={(x,y) for y in range(h) for x in range(w) if alpha.getpixel((x,y))==0}
    components=[]
    while empty:
        seed=empty.pop();todo=[seed];edge=False
        for x,y in todo:
            edge |= x in (0,w-1) or y in (0,h-1)
            for p in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if p in empty:empty.remove(p);todo.append(p)
        if not edge:components.append({'pixels':len(todo),'bbox':[min(x for x,y in todo),min(y for x,y in todo),max(x for x,y in todo)+1,max(y for x,y in todo)+1]})
    return sorted(components,key=lambda c:(c['bbox'][1],c['bbox'][0]))

def validate_baseline(path,rig_sha,annotations_sha,source_hash):
    baseline=json.loads(path.read_text())
    if baseline.get('schema')!='custodian.ne_walk_preview.v1':raise ValueError('baseline report schema mismatch')
    if baseline.get('rig_sha256')!=rig_sha:raise ValueError('baseline rig SHA mismatch')
    if baseline.get('annotations_sha256')!=annotations_sha:raise ValueError('baseline annotations SHA mismatch')
    if baseline.get('input_validation',{}).get('source_hash')!=source_hash:raise ValueError('baseline donor source hash mismatch')
    frames=baseline.get('frames')
    if not isinstance(frames,list) or len(frames)!=15 or [f.get('frame') for f in frames]!=list(range(1,16)):
        raise ValueError('baseline frame count/schema mismatch')
    if any(not isinstance(f.get('legs'),dict) or set(('near','far'))-set(f['legs']) or
           'reference_pitch_filter_deviation_deg' not in f['legs']['near'] or
           'reference_pitch_filter_deviation_deg' not in f['legs']['far'] or
           not isinstance(f.get('contact'),dict) for f in frames):
        raise ValueError('baseline frame pitch/contact schema mismatch')
    if not isinstance(baseline.get('calibration_deviations'),dict):raise ValueError('baseline calibration envelope schema mismatch')
    return baseline

def crossover_signs(report):
    return [1 if row['legs']['near']['ankle']['x']-row['legs']['far']['ankle']['x']>0 else -1
            for row in report['frames']]

def wrapped_pitch_error_deg(actual,target):
    delta=math.radians(actual-target)
    return math.degrees(math.atan2(math.sin(delta),math.cos(delta)))

def pitch_quality_gate(baseline_errors,candidate_errors,supports):
    baseline_weighted=candidate_weighted=0.0;max_worsening=0.0;worst=None
    for i,(old,new,support) in enumerate(zip(baseline_errors,candidate_errors,supports),1):
        for side in ('near','far'):
            weight=1.0 if support!=side else .25
            old_abs=abs(float(old[side]));new_abs=abs(float(new[side]))
            baseline_weighted+=weight*old_abs;candidate_weighted+=weight*new_abs
            worsening=new_abs-old_abs
            if worsening>max_worsening:max_worsening=worsening;worst={'frame':i,'side':side,'degrees':worsening}
    improvement=(baseline_weighted-candidate_weighted)/baseline_weighted if baseline_weighted else 0.0
    gates={'weighted_error_improved_by_at_least_10_percent':improvement>=.10,
        'no_frame_side_worsened_by_more_than_5_degrees':max_worsening<=5.0}
    return {'baseline_weighted':baseline_weighted,'candidate_weighted':candidate_weighted,
        'improvement_fraction':improvement,'maximum_single_frame_worsening_deg':max_worsening,
        'worst_worsening':worst,'quality_gate':gates,'passed':all(gates.values())}

def pitch_comparison(candidate,baseline):
    frames=[];baseline_errors=[];candidate_errors=[];supports=[]
    for old,new in zip(baseline['frames'],candidate['frames']):
        frame={'frame':new['frame'],'support':new['support'],'sides':{}}
        old_row_errors={};new_row_errors={}
        for side in ('near','far'):
            old_leg,new_leg=old['legs'][side],new['legs'][side]
            old_abs=float(old_leg['reference_pitch_filter_deviation_deg'])
            new_signed=float(new_leg['reference_pitch_filter_signed_deviation_deg'])
            new_abs=abs(new_signed);weight=1.0 if new['support']!=side else .25
            old_row_errors[side]=old_abs;new_row_errors[side]=new_abs
            frame['sides'][side]={'weight':weight,'baseline_abs_error_deg':old_abs,
                'candidate_signed_error_deg':new_signed,'candidate_abs_error_deg':new_abs,
                'delta_abs_error_deg':new_abs-old_abs}
        old_cal=baseline.get('calibration_deviations',{}).get(str(new['frame']))
        new_cal=candidate.get('calibration_deviations',{}).get(str(new['frame']))
        frame['contacts']={'baseline':old.get('contact'),'candidate':new.get('contact')}
        frame['calibration_joint_envelope']={'baseline':old_cal,'candidate':new_cal}
        frames.append(frame)
        baseline_errors.append(old_row_errors);candidate_errors.append(new_row_errors);supports.append(new['support'])
    old_signs=crossover_signs(baseline);new_signs=crossover_signs(candidate)
    def changes(signs):return [[i,i+1] for i in range(1,len(signs)) if signs[i]!=signs[i-1]]
    quality=pitch_quality_gate(baseline_errors,candidate_errors,supports)
    return {'schema':'custodian.operator_ne_pitch_comparison.v1','baseline_schema':baseline['schema'],
        'candidate_schema':candidate['schema'],'frames':frames,
        'weighted_absolute_error_sum_deg':{'baseline':quality['baseline_weighted'],'candidate':quality['candidate_weighted'],
            'improvement_fraction':quality['improvement_fraction']},
        'maximum_single_frame_worsening_deg':quality['maximum_single_frame_worsening_deg'],
        'worst_worsening':quality['worst_worsening'],'baseline_crossover_signs':old_signs,'candidate_crossover_signs':new_signs,
        'baseline_crossover_changes':changes(old_signs),'candidate_crossover_changes':changes(new_signs),
        'quality_gate':quality['quality_gate'],'passed':quality['passed'],
        'visual_approval':'not claimed'}

def analyze(out, annotations, preflight, rig_sha, core_sha):
    r=json.loads((out/'aseprite_report.json').read_text())
    r.update(implementation_sha256={name:sha(HERE/name) for name in ('motion_plan.py','continuity.py','occlusion.lua','batch.lua','rigid_raster.lua','run.py','review_viewer.py')},controls=annotations['controls'],input_validation=preflight, rig_sha256=rig_sha, v55_sha256=core_sha,
             annotations_sha256=sha(out/'annotations.json'),timing_fps=None,
             accepted=False,human_visual_review='pending',timing_authority=False)
    limits=annotations['controls']
    from motion_plan import check_limits
    check_limits(limits)
    for finding in preflight['marker_findings']:
        r['frames'][finding['frame']-1]['failures'].append(f"reference_{finding['joint']}_not_established")
    sheet=Image.open(out/'operator_ne_walk_v6_15f.png')
    assert sheet.mode=='RGBA' and sheet.size==(1920,128)
    transitions=[]
    palette=set()
    for row in r['frames']:
        if 'legs' not in row: continue
        frame=Image.open(out/f"frame_{row['frame']:02}.png")
        assert frame.mode=='RGBA' and frame.size==(128,128)
        colors=set(frame.getdata());palette|={c for c in colors if c[3]}
        if any(c[3] not in (0,255) for c in colors): row['failures'].append('partial_alpha')
        row['enclosed_alpha_voids']=alpha_voids(frame)
        bb=frame.getbbox();row['alpha_bbox']=bb
        if bb and (bb[0]==0 or bb[1]==0 or bb[2]==128 or bb[3]==128): row['failures'].append('canvas_edge_clipping_risk')
        row['pelvis_within_bounds']=abs(row['pelvis']['x']-61)<=7 and abs(row['pelvis']['y']-66)<=6
        if not row['pelvis_within_bounds']:row['failures'].append('pelvis_motion_bounds')
        for side,leg in row['legs'].items():
            metric=r['rig_metrics'][side]
            marker=annotations['frames'][row['frame']-1]['landmarks']
            ankle_ref=marker['ankle_'+side]['xy'];toe_ref=marker['toe_'+side]['xy']
            raw_pitch=math.degrees(math.atan2(toe_ref[1]-ankle_ref[1],toe_ref[0]-ankle_ref[0])-metric['source_foot_angle'])
            raw_pitch=max(-24,min(24,(raw_pitch+180)%360-180))
            leg['reference_pitch_filter_signed_deviation_deg']=wrapped_pitch_error_deg(leg['foot_delta'],raw_pitch)
            leg['reference_pitch_filter_deviation_deg']=abs(leg['reference_pitch_filter_signed_deviation_deg'])
            leg['reference_pitch_target_deg']=raw_pitch
            leg['thigh_length_error']=abs(distance(leg['hip'],leg['knee'])-metric['thigh_len'])
            leg['shin_length_error']=abs(distance(leg['knee'],leg['ankle'])-metric['shin_len'])
            if max(leg['thigh_length_error'],leg['shin_length_error'])>1e-6:row['failures'].append(side+'_accepted_segment_length_changed')
            boot=leg.get('rendered_boot_contact')
            # Different neutral near/far planes are preserved; this residual is
            # descriptive, not a false common-screen-ground assertion.
            leg['screen_ground_delta']=107-boot['y'] if boot else None
        prev=r['frames'][row['frame']-2]
        if 'legs' not in prev: continue
        t={'from':prev['frame'],'to':row['frame'],'support_transition':prev['support']!=row['support'],'joint_steps':{},'branch_flips':[],'rotation_steps':{}}
        for side in ('near','far'):
            a,b=prev['legs'][side],row['legs'][side]
            for joint in ('hip','knee','ankle','toe'):
                step=distance(a[joint],b[joint]);t['joint_steps'][f'{side}.{joint}']=step
                if step>limits['max_joint_step_px']: row['failures'].append(f'{side}_{joint}_jump')
            for segment in ('thigh','shin','foot'):
                delta=abs((b[segment+'_delta']-a[segment+'_delta']+180)%360-180)
                t['rotation_steps'][f'{side}.{segment}']=delta
                if delta>limits['max_rotation_step_degrees']:row['failures'].append(f'{side}_{segment}_rotation_jump')
            if a['knee_branch']*b['knee_branch']<0:
                t['branch_flips'].append(side);row['failures'].append(side+'_knee_branch_flip')
        fa=sheet.crop(((prev['frame']-1)*128,0,prev['frame']*128,128))
        fb=sheet.crop(((row['frame']-1)*128,0,row['frame']*128,128))
        t['changed_pixels']=sum(a!=b for a,b in zip(fa.getdata(),fb.getdata()))
        t['max_joint_step_px']=max(t['joint_steps'].values())
        transitions.append(t)
    from continuity import validate_crossover
    acceptance=json.loads((HERE/'crossover_acceptance.json').read_text())
    rendered={'frames':r['frames']}
    try:validate_crossover(rendered,annotations,acceptance)
    except ValueError as e:
        r['crossover_validation_error']=str(e)
        for row in r['frames']:row['failures'].append('accepted_crossover_contract')
    r['calibration_acceptance']=acceptance
    r['continuity_plan']=json.loads((out/'motion_plan.json').read_text())
    r['maximum_continuity_target_deviation_px']=max(l.get('reference_filter_deviation_px',0) for f in r['frames'] for l in f['legs'].values())
    r['calibration_deviations']={key:{s:{j:distance(r['frames'][int(key)-1]['legs'][s][j],expected[j]) for j in ('hip','knee','ankle','toe')} for s,expected in legs.items()} for key,legs in acceptance['pose_locks'].items()}
    r['reference_transitions']=[]
    for i,f in enumerate(annotations['frames']):
        prev=annotations['frames'][i-1]
        steps={name:math.dist(prev['landmarks'][name]['xy'],f['landmarks'][name]['xy']) for name in JOINTS}
        r['reference_transitions'].append({'from':prev['frame'],'to':f['frame'],'joint_steps':steps,
            'support_changed':prev['support']!=f['support']})
    intervals=[]
    for frame in annotations['frames']:
        if not intervals or intervals[-1]['side']!=frame['support']:
            intervals.append({'side':frame['support'],'frames':[]})
        intervals[-1]['frames'].append(frame['frame'])
    r['provisional_support_intervals']=intervals
    r['transitions']=transitions
    r['loop_seam']=next((t for t in transitions if t['from']==15 and t['to']==1),None)
    for row in r['frames']:row['pass']=not row['failures']
    r['passing_frames']=sum(row['pass'] for row in r['frames'])
    r['preview_geometry_passed']=r['passing_frames']==15
    r['maximum_reference_filter_deviation_px']=max(l.get('reference_filter_deviation_px',0) for f in r['frames'] for l in f.get('legs',{}).values())
    r['maximum_enclosed_alpha_void_pixels']=max(sum(c['pixels'] for c in f.get('enclosed_alpha_voids',[])) for f in r['frames'])
    r['output_palette_size']=len(palette)
    source_colors={c for c in Image.open(out/'source_palette.png').getdata() if c[3]}
    r['palette_identity_passed']=palette <= source_colors
    assert r['palette_identity_passed'], 'preview invented source colors'
    r['rig_diagnostics']={side:{'shin_length_px':m['shin_len'],'thigh_length_px':m['thigh_len'],
        'shin_to_thigh_ratio':m['shin_len']/m['thigh_len']} for side,m in r['rig_metrics'].items()}
    r['limitations']=['Crossover identities accepted; support handoffs 6/7 and 13/14 provisionally accepted for dynamic review.',
        'Upper body and robe additions use explicit phase controls; timing remains unknown.',
        'Source rig neutral far/near soles lie on different screen-depth planes.',
        'No true world-space support-plane or swing-clearance inference from this single view.',
        'Enclosed transparent components are reported; intentional limb gaps require human interpretation.',
        'Loop metrics measure adjacent authored poses; no interpolated in-betweens are generated.',
        'Aseprite 100ms editor durations are placeholders, not selected timing.',
        'No Godot runtime tests: no runtime/source/ingress mutation is permitted.']
    write(out/'report.json',r)
    # Compact diagnostics, no resampling of production assets.
    contact=Image.new('RGB',(5*256,3*170),'#252525');d=ImageDraw.Draw(contact)
    for row in r['frames']:
        i=row['frame']-1;x=(i%5)*256;y=(i//5)*170
        if 'legs' in row:
            f=sheet.crop((i*128,0,(i+1)*128,128));contact.paste(f,(x,y+24),f)
            for side,color in (('near','#ff8080'),('far','#80c0ff')):
                leg=row['legs'][side]
                points=[(x+leg[j]['x'],y+24+leg[j]['y']) for j in ('hip','knee','ankle','toe')]
                d.line(points,fill=color,width=1)
        d.text((x+3,y+3),f"F{i+1:02} {row['support']} {'PASS' if row['pass'] else 'FAIL'}",fill='white')
        c=row.get('contact',{});d.text((x+130,y+28),f"dx={c.get('dx','?')}\ndy={c.get('dy','?')}\nissues={len(row['failures'])}",fill='white')
    contact.save(out/'contact_sheet.png')
    return r

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bundle',required=True,type=Path)
    p.add_argument('--rig',required=True,type=Path)
    p.add_argument('--v55',type=Path,default=Path.home()/'.config/aseprite/scripts/operator_ne_pose_builder_v0_5_5_swing_stride_control.lua')
    p.add_argument('--annotations',type=Path,default=HERE/'annotations.json')
    p.add_argument('--output',required=True,type=Path)
    p.add_argument('--baseline-report',type=Path,help='immutable preceding review report for bounded pitch comparison')
    p.add_argument('--aseprite',default='aseprite')
    a=p.parse_args();a.bundle=a.bundle.resolve();a.rig=a.rig.resolve();a.output=a.output.resolve()
    # An immutable run directory prevents old successful frames masking failures.
    assert not a.output.exists(), 'choose a fresh output directory'
    repo=HERE.parents[3]
    assert not a.output.is_relative_to(repo/'custodian'), 'output must stay outside active project'
    annotations=json.loads(a.annotations.read_text())
    authority=json.loads((HERE/'donor_authority.json').read_text())
    assert annotations['source_sha256']==authority['source_sha256'], 'superseded donor authority'
    from continuity import require_authority
    require_authority(annotations,authority,json.loads((HERE/'crossover_acceptance.json').read_text()))
    preflight=validate(a.bundle,annotations)
    dep=json.loads((HERE/'v55_dependency.json').read_text());assert sha(a.v55)==dep['sha256'],'V5.5 dependency drift'
    rig_sha=sha(a.rig)
    acceptance=json.loads((HERE/'rig_acceptance.json').read_text())
    assert rig_sha==acceptance['rig_sha256'],'V6 must use the human-accepted rig baseline'
    assert rig_sha==json.loads((HERE/'crossover_acceptance.json').read_text())['rig_sha256'],'crossover rig identity changed'
    baseline=None
    annotations_sha=hashlib.sha256(json.dumps(annotations,indent=2,allow_nan=False).encode()).hexdigest()
    if a.baseline_report:
        a.baseline_report=a.baseline_report.resolve()
        baseline=validate_baseline(a.baseline_report,rig_sha,sha(a.annotations),preflight['source_hash'])
    a.output.mkdir(parents=True)
    write(a.output/'annotations.json',annotations)
    write(a.output/'input_validation.json',preflight)
    source=a.v55.read_text()
    boundary='-- UI\n-- ============================================================================'
    assert source.count(boundary)==1
    core=source.split(boundary)[0]
    # Strip the obsolete embedded image/markers completely from the batch core.
    start=core.index('local KNIGHT_F1_EMBEDDED =')
    end=core.index('local function clamp(v,lo,hi)',start)
    core=core[:start]+core[end:]
    # Rig validation is separate from the unchanged V6 solver. Refuse the
    # known empty-shin / missing-foot regression before rendering 15 frames.
    from master_audit import export as audit_rig
    rig_audit,_,_=audit_rig(a.aseprite,a.rig,a.output/'rig_preflight',core)
    if not rig_audit['structural_gate_passed']:
        write(a.output/'RIG_BLOCKED.json',{'rig_sha256':rig_sha,
              'blocking_findings':rig_audit['blocking_findings'],'v6_solver_started':False})
        raise RuntimeError('Rig gate refused before V6: '+', '.join(rig_audit['blocking_findings']))
    from continuity import fit
    motion=fit(annotations,rig_audit)
    write(a.output/'motion_plan.json',motion)
    driver=a.output/'batch_generated.lua';driver.write_text(core+'\n'+(HERE/'rigid_raster.lua').read_text()+'\n'+(HERE/'occlusion.lua').read_text()+'\n'+(HERE/'batch.lua').read_text())
    cfg={'bundle':str(a.bundle),'output':str(a.output),'annotations':annotations,'motion_plan':motion}
    command=[a.aseprite,'-b',str(a.rig),'--script-param','config='+json.dumps(cfg,separators=(',',':')),'--script',str(driver)]
    result=subprocess.run(command,capture_output=True,text=True)
    (a.output/'aseprite.log').write_text(result.stdout+result.stderr)
    assert sha(a.rig)==rig_sha,'source rig mutated'
    if result.returncode or not (a.output/'aseprite_report.json').exists():
        raise RuntimeError('Aseprite failed: '+result.stdout+result.stderr)
    r=analyze(a.output,annotations,preflight,rig_sha,sha(a.v55))
    comparison=None
    if baseline is not None:
        comparison=pitch_comparison(r,baseline)
        write(a.output/'PITCH_COMPARISON.json',comparison)
        r['pitch_comparison_gate']=comparison['quality_gate']
        r['pitch_comparison_passed']=comparison['passed']
        write(a.output/'report.json',r)
    from review_viewer import write_viewer
    write_viewer(a.output,a.bundle,r)
    write(a.output/'run_receipt.json',{'command':command,'source_rig_unchanged':True,'rig_sha256':rig_sha,
          'output':str(a.output),'baseline_report':str(a.baseline_report) if baseline is not None else None,
          'preview_geometry_passed':r['preview_geometry_passed'],'pitch_comparison_passed':comparison['passed'] if comparison else None,'accepted':False})
    print(json.dumps({'report':str(a.output/'report.json'),'passing_frames':r['passing_frames'],'frames':15,'pitch_comparison_passed':comparison['passed'] if comparison else None,'accepted':False}))
    if not r['preview_geometry_passed']:return 2
    return 0 if comparison is None or comparison['passed'] else 3

if __name__=='__main__':
    sys.exit(main())
