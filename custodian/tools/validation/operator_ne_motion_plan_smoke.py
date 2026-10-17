#!/usr/bin/env python3
"""Numerical regressions independent of Aseprite and the user's local master."""
from pathlib import Path
import copy
import hashlib
import json
import math
import sys
import tempfile
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/'custodian/tools/operator/ne_walk_retarget'))
from motion_plan import two_bone, transition_cost, validate_plan, dist
from run import (build_upper_body_comparison, pitch_quality_gate,
                 upper_body_terms, validate_upper_body_angles, wrapped_pitch_error_deg)
from review_viewer import BACKGROUND, _write_pair_sheet

LIMITS={'max_knee_fit_error_px':8,'max_joint_step_px':8,'max_rotation_step_degrees':60}
def pose(x=0):
    leg={'hip':{'x':x,'y':0},'knee':{'x':x+3,'y':4},'ankle':{'x':x,'y':8},'toe':{'x':x+2,'y':8},'thigh_delta':0,'shin_delta':0,'foot_delta':0}
    return {'legs':{'near':copy.deepcopy(leg),'far':copy.deepcopy(leg)}}

def main():
    upper_body_regressions()
    reference_pairing_regressions()
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

def upper_body_regressions():
    amount=2.0
    terms=upper_body_terms(10,25,0,amount)
    assert terms['normalized_stride']==1.0 and terms['upper_body_stride_bias']==-0.75
    assert terms['upper_body']==terms['upper_body_base']-0.75
    negative=upper_body_terms(1,0,25,amount)
    assert negative['normalized_stride']==-1.0 and negative['upper_body_stride_bias']==0.75
    zero=upper_body_terms(4,12,12,amount)
    assert zero['normalized_stride']==0.0 and zero['upper_body_stride_bias']==0.0
    assert upper_body_terms(1,100,0,amount)['normalized_stride']==1.0
    assert upper_body_terms(1,0,100,amount)['normalized_stride']==-1.0
    try:validate_upper_body_angles([0.0,3.0]+[0.0]*13)
    except ValueError:pass
    else:raise AssertionError('adjacent upper-body step above 2 degrees must fail')
    try:validate_upper_body_angles([0.0]*14+[1.01])
    except ValueError:pass
    else:raise AssertionError('upper-body loop seam above 1 degree must fail')

    baseline={'schema':'custodian.ne_walk_preview.v1','rig_sha256':'b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5','annotations_sha256':'annotations',
        'input_validation':{'source_hash':'20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba'},'frames':[]}
    candidate={'schema':'custodian.ne_walk_preview.v1','rig_sha256':baseline['rig_sha256'],'annotations_sha256':'annotations',
        'input_validation':{'source_hash':baseline['input_validation']['source_hash']},'frames':[]}
    plan={'frames':[]}
    for i in range(1,16):
        nd=10*math.sin(i*math.pi/7);fd=0.0
        legs={'near':{'hip':{'x':1,'y':2},'ankle':{'x':1+nd,'y':8}},
              'far':{'hip':{'x':3,'y':2},'ankle':{'x':3+fd,'y':8}}}
        plan['frames'].append({'legs':legs})
        baseline['frames'].append({'frame':i,'support':'near' if i<7 else 'far',
            'legs':copy.deepcopy({side:{**copy.deepcopy(legs[side]),'knee':{'x':4,'y':5},'toe':{'x':6,'y':7}} for side in legs}),
            'secondary':{'upper_body':0.0}})
        terms=upper_body_terms(i,legs['near']['ankle']['x']-legs['near']['hip']['x'],
            legs['far']['ankle']['x']-legs['far']['hip']['x'],amount)
        candidate['frames'].append({'frame':i,'support':baseline['frames'][-1]['support'],
            'legs':copy.deepcopy(baseline['frames'][-1]['legs']),
            'secondary':{'upper_body':terms['upper_body'],'upper_body_base':terms['upper_body_base'],
                'upper_body_stride_bias':terms['upper_body_stride_bias'],'normalized_stride':terms['normalized_stride']}})
    result=build_upper_body_comparison(candidate,baseline,plan,amount,'3cc70f881d04cae1ab8217aa46481cf40344c30a4a0523270488d26da0acded4')
    assert len(result['frames'])==15 and result['geometry_unchanged'] and result['passed']
    bad=copy.deepcopy(candidate);bad['frames'][9]['secondary']['upper_body']+=0.02
    try:build_upper_body_comparison(bad,baseline,plan,amount,'3cc70f881d04cae1ab8217aa46481cf40344c30a4a0523270488d26da0acded4')
    except ValueError:pass
    else:raise AssertionError('tampered applied-angle report must fail')
    bad=copy.deepcopy(candidate);bad['frames'][4]['legs']['near']['toe']['x']+=0.002
    try:build_upper_body_comparison(bad,baseline,plan,amount,'3cc70f881d04cae1ab8217aa46481cf40344c30a4a0523270488d26da0acded4')
    except ValueError:pass
    else:raise AssertionError('changed leg geometry must fail')
    print('PASS upper-body follow-through: stride sign/bounds, signed bias, report formula, unchanged leg geometry, adjacent/seam gates, tamper negative controls')

def reference_pairing_regressions():
    with tempfile.TemporaryDirectory(prefix='operator-ne-reference-pair-') as temp:
        root=Path(temp);donor_dir=root/'donor';candidate_dir=root/'candidate';donor_dir.mkdir();candidate_dir.mkdir()
        donor_strip=Image.new('RGBA',(1920,128));candidate_strip=Image.new('RGBA',(1920,128))
        donor_paths=[];candidate_paths=[];donor_file_hashes=[];supports=[]
        for i in range(15):
            gray=Image.new('RGBA',(128,128));gold=Image.new('RGBA',(128,128))
            for y in range(128):
                for x in range(128):
                    alpha=0 if (x+y+i)%19==0 else 255
                    shade=35+(i*7+x+y)%90
                    gray.putpixel((x,y),(shade,shade,shade,alpha))
                    gold.putpixel((x,y),(150+(i%8),82+(x%40),20+(y%30),alpha))
            donor_strip.paste(gray,(i*128,0));candidate_strip.paste(gold,(i*128,0))
            dp=donor_dir/f'f{i+1:02}.png';cp=candidate_dir/f'f{i+1:02}.png';gray.save(dp);gold.save(cp)
            donor_paths.append(dp);candidate_paths.append(cp);donor_file_hashes.append(hashlib.sha256(dp.read_bytes()).hexdigest())
            supports.append('near' if i%2==0 else 'far')
        donor_path=root/'knight_ne.png';candidate_path=candidate_dir/'operator_ne_walk_v6_15f.png'
        donor_strip.save(donor_path);candidate_strip.save(candidate_path)
        report={'frames':[{'frame':i+1,'support':supports[i]} for i in range(15)]}
        (candidate_dir/'report.json').write_text(json.dumps(report))
        review=root/'review';review.mkdir()
        expected_donor_sha=hashlib.sha256(donor_path.read_bytes()).hexdigest()
        provenance=_write_pair_sheet(donor_path,candidate_path,donor_paths,candidate_paths,
            report,review,expected_donor_sha,donor_file_hashes)
        sheet=Image.open(review/'REFERENCE_OPERATOR_15_POSES.png').convert('RGB')
        assert sheet.size==(1280,480) and len(provenance['frames'])==15
        for i in range(15):
            col=i%5;row=i//5;x=col*256;y=row*160+20
            expected_gray=Image.new('RGBA',(128,128),BACKGROUND);expected_gray.alpha_composite(Image.open(donor_paths[i]).convert('RGBA'))
            expected_gold=Image.new('RGBA',(128,128),BACKGROUND);expected_gold.alpha_composite(Image.open(candidate_paths[i]).convert('RGBA'))
            assert sheet.crop((x,y,x+128,y+128)).tobytes()==expected_gray.convert('RGB').tobytes()
            assert sheet.crop((x+128,y,x+256,y+128)).tobytes()==expected_gold.convert('RGB').tobytes()
            receipt=provenance['frames'][i]
            assert receipt['frame']==i+1 and receipt['support']==supports[i]
            assert receipt['donor_rgba_pixels_sha256']==hashlib.sha256(Image.open(donor_paths[i]).tobytes()).hexdigest()
            assert receipt['candidate_rgba_pixels_sha256']==hashlib.sha256(Image.open(candidate_paths[i]).tobytes()).hexdigest()
            assert receipt['donor_background_composited_match'] and receipt['candidate_background_composited_match']
        def reject(donor,candidate,expected):
            target=root/f'reject_{len(list(root.glob("reject_*")))}';target.mkdir()
            try:_write_pair_sheet(donor,candidate,donor_paths,candidate_paths,report,target,expected,donor_file_hashes)
            except ValueError:return
            raise AssertionError('invalid reference-pair identity was accepted')
        reject(candidate_path,donor_path,expected_donor_sha)  # Swapped left/right source inputs.
        reject(donor_path,candidate_path,'0'*64)  # Spoofed donor digest.
        reject(donor_path,donor_path,expected_donor_sha)  # Same-sprite substitution.
    print('PASS reference pairing: 15 ordered gray/gold frame pairs, alpha compositing, source hashes, layout, swap/spoof/duplicate negative controls')
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
