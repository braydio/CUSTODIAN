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
            if name.startswith(('ankle','toe')) and (pixel[3]<255 or max(pixel[:3])<55):
                marker_findings.append({'frame':i+1,'joint':name,'rgba':pixel,'reason':'visible_boot_marker_not_established'})
        assert len({tuple(l['xy']) for l in record['landmarks'].values()})==9
    assert rebuilt.tobytes()==source.tobytes()
    return {'source_hash':sha(strip),'frame_hashes_passed':15,'pixel_reassembly_exact':True,'marker_findings':marker_findings}

def analyze(out, annotations, preflight, rig_sha, core_sha):
    r=json.loads((out/'aseprite_report.json').read_text())
    r.update(input_validation=preflight, rig_sha256=rig_sha, v55_sha256=core_sha,
             annotations_sha256=sha(out/'annotations.json'),timing_fps=None,
             accepted=False,human_visual_review='pending',timing_authority=False)
    limits=annotations['controls']
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
        bb=frame.getbbox();row['alpha_bbox']=bb
        if bb and (bb[0]==0 or bb[1]==0 or bb[2]==128 or bb[3]==128): row['failures'].append('canvas_edge_clipping_risk')
        for side,leg in row['legs'].items():
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
    r['output_palette_size']=len(palette)
    source_colors={c for c in Image.open(out/'source_palette.png').getdata() if c[3]}
    r['palette_identity_passed']=palette <= source_colors
    assert r['palette_identity_passed'], 'preview invented source colors'
    r['rig_diagnostics']={side:{'shin_length_px':m['shin_len'],'thigh_length_px':m['thigh_len'],
        'shin_to_thigh_ratio':m['shin_len']/m['thigh_len']} for side,m in r['rig_metrics'].items()}
    r['limitations']=['Provisional agent traces and support schedule require human confirmation.',
        'Upper body counter-motion and robe additions are independent controls, disabled in baseline.',
        'Source rig neutral far/near soles lie on different screen-depth planes.',
        'No true world-space support-plane or swing-clearance inference from this single view.',
        'Pixel holes require an authored coverage mask; none is supplied, so no pixel-hole PASS is claimed.',
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
    p.add_argument('--aseprite',default='aseprite')
    a=p.parse_args();a.bundle=a.bundle.resolve();a.rig=a.rig.resolve();a.output=a.output.resolve()
    # An immutable run directory prevents old successful frames masking failures.
    assert not a.output.exists(), 'choose a fresh output directory'
    repo=HERE.parents[3]
    assert not a.output.is_relative_to(repo/'custodian'), 'output must stay outside active project'
    annotations=json.loads(a.annotations.read_text())
    preflight=validate(a.bundle,annotations)
    dep=json.loads((HERE/'v55_dependency.json').read_text());assert sha(a.v55)==dep['sha256'],'V5.5 dependency drift'
    rig_sha=sha(a.rig)
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
    driver=a.output/'batch_generated.lua';driver.write_text(core+'\n'+(HERE/'batch.lua').read_text())
    cfg={'bundle':str(a.bundle),'output':str(a.output),'annotations':annotations}
    command=[a.aseprite,'-b',str(a.rig),'--script-param','config='+json.dumps(cfg,separators=(',',':')),'--script',str(driver)]
    result=subprocess.run(command,capture_output=True,text=True)
    (a.output/'aseprite.log').write_text(result.stdout+result.stderr)
    assert sha(a.rig)==rig_sha,'source rig mutated'
    if result.returncode or not (a.output/'aseprite_report.json').exists():
        raise RuntimeError('Aseprite failed: '+result.stdout+result.stderr)
    r=analyze(a.output,annotations,preflight,rig_sha,sha(a.v55))
    write(a.output/'run_receipt.json',{'command':command,'source_rig_unchanged':True,'rig_sha256':rig_sha,
          'output':str(a.output),'preview_geometry_passed':r['preview_geometry_passed'],'accepted':False})
    print(json.dumps({'report':str(a.output/'report.json'),'passing_frames':r['passing_frames'],'frames':15,'accepted':False}))
    return 0 if r['preview_geometry_passed'] else 2

if __name__=='__main__':
    sys.exit(main())
