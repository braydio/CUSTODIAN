#!/usr/bin/env python3
"""Read-only anatomical/ownership audit; source-preserving disposable recovery."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
SOURCE='__RIG_REFERENCE_LOCKED_FULL_BODY'
PART='__RIG_PART_'
HIDDEN='__RIG_HIDDEN_'

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def write(path,data):
    Path(path).write_text(json.dumps(data,indent=2)+'\n')

def pixels(image):
    return list(image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata())

def inspect_export(root):
    report=json.loads((root/'export.json').read_text())
    layers={name:Image.open(root/info['file']).convert('RGBA') for name,info in report['layers'].items()}
    assert all(im.size==(128,128) for im in layers.values()),'wrong rig canvas'
    source=pixels(layers[SOURCE])
    parts={name:pixels(image) for name,image in layers.items() if name.startswith(PART)}
    ownership=[[] for _ in source]
    mismatches=[]
    for name,values in parts.items():
        for i,pixel in enumerate(values):
            if pixel[3]:ownership[i].append(name)
    duplicates=[];unowned=[];extraneous=[]
    for i,(pixel,owners) in enumerate(zip(source,ownership)):
        if len(owners)>1:duplicates.append([i%128,i//128])
        if pixel[3] and not owners:unowned.append([i%128,i//128])
        if not pixel[3] and owners:extraneous.append([i%128,i//128])
        if pixel[3] and (len(owners)!=1 or parts[owners[0]][i]!=pixel):mismatches.append([i%128,i//128])
    gates=[]
    if duplicates or unowned or extraneous or mismatches:gates.append('visible_partition_not_exact')
    if report['layers']['__RIG_UNCLASSIFIED_VISIBLE']['count']:gates.append('unclassified_pixels')
    if len(report['pivots'])!=18:gates.append('pivot_count')
    for side in ('near','far'):
        foot=report['feet'][side];metric=report['metrics'][side]
        if not foot['valid']:gates.append(side+'_foot_geometry_missing_or_invalid')
        shin_pixels=report['layers'][PART+'shin_'+side+'_visible']['count']+report['layers'][HIDDEN+'shin_'+side+'_completion']['count']
        if not shin_pixels:gates.append(side+'_shin_has_no_art')
        if metric['thigh_len']<=0 or metric['shin_len']<=0:gates.append(side+'_nonpositive_segment')
        # A lopsided chain is an objective review trigger, not an anatomy fix or
        # universal projected-limb proportion rule. No tolerance is changed in V6.
        if metric['shin_len']/metric['thigh_len']<0.4:gates.append(side+'_short_shin_requires_anatomy_review')
        if foot['valid']:
            b=foot['bbox'];ankle=metric['ankle'];toe=metric['toe']
            if not(b['minx']-5<=toe['x']<=b['maxx']+5 and b['miny']-5<=toe['y']<=b['maxy']+5):
                gates.append(side+'_toe_outside_boot_envelope')
        for joint in ('knee','ankle','toe'):
            point=metric[joint];i=point['y']*128+point['x']
            report.setdefault('joint_source_samples',{})[side+'.'+joint]={'xy':point,'rgba':source[i],'owners':ownership[i]}
    report.update(visible_partition={'duplicates':duplicates,'unowned':unowned,'extraneous':extraneous,
                                    'color_mismatches':mismatches,'exact':not(duplicates or unowned or extraneous or mismatches)},
                  blocking_findings=gates,structural_gate_passed=not gates,anatomy_accepted=False,
                  ready_for_v6=False)
    write(root/'audit.json',report)
    return report,layers,ownership

def compare(original,recovered):
    a,al,ao=original;b,bl,bo=recovered
    before=pixels(al[SOURCE]);after=pixels(bl[SOURCE]);differences=[]
    for i,(x,y) in enumerate(zip(before,after)):
        if x!=y:differences.append({'xy':[i%128,i//128],'original':x,'recovered':y})
    reassigned={}
    for i,color in enumerate(pixels(bl[PART+'foot_far_visible'])):
        if color[3]:
            for owner in ao[i] or ['new_opaque_location']:
                reassigned[owner]=reassigned.get(owner,0)+1
    return {'source_differences':differences,'source_difference_count':len(differences),
            'recovered_far_foot_previous_owners':reassigned,
            'original_shin_pixels':a['layers'][PART+'shin_far_visible']['count'],
            'recovered_shin_pixels':b['layers'][PART+'shin_far_visible']['count'],
            'source_versions_identical':not differences}

def export(aseprite,source,root,core,candidate=None):
    root.mkdir()
    cfg={'output':str(root)}
    if candidate:cfg['candidate']=str(candidate)
    script=root/'audit_generated.lua';script.write_text(core+'\n'+(HERE/'rig_audit.lua').read_text())
    command=[aseprite,'-b',str(source),'--script-param','audit_config='+json.dumps(cfg), '--script',str(script)]
    before=sha(source)
    result=subprocess.run(command,capture_output=True,text=True,timeout=60)
    (root/'aseprite.log').write_text(result.stdout+result.stderr)
    assert sha(source)==before,'immutable source changed'
    if result.returncode or not(root/'export.json').is_file():raise RuntimeError(result.stdout+result.stderr)
    return inspect_export(root)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--original',required=True,type=Path)
    p.add_argument('--recovered',required=True,type=Path)
    p.add_argument('--output',required=True,type=Path)
    p.add_argument('--v55',type=Path,default=Path.home()/'.config/aseprite/scripts/operator_ne_pose_builder_v0_5_5_swing_stride_control.lua')
    p.add_argument('--aseprite',default='aseprite')
    args=p.parse_args();args.output=args.output.resolve()
    assert not args.output.exists(),'fresh output directory required'
    assert not args.output.is_relative_to(HERE.parents[3]/'custodian'),'review output must stay outside runtime'
    dep=json.loads((HERE/'v55_dependency.json').read_text());assert sha(args.v55)==dep['sha256'],'V5.5 drift'
    hashes={str(path.resolve()):sha(path) for path in (args.original,args.recovered)}
    args.output.mkdir(parents=True)
    source=args.v55.read_text();core=source.split('-- UI\n-- ============================================================================')[0]
    begin=core.index('local KNIGHT_F1_EMBEDDED =');end=core.index('local function clamp(v,lo,hi)',begin)
    core=core[:begin]+core[end:]
    candidate=args.output/'operator_ne_rig_SEGMENTATION_RESTORED_FOOT_INCOMPLETE.aseprite'
    original=export(args.aseprite,args.original,args.output/'original',core,candidate)
    recovered=export(args.aseprite,args.recovered,args.output/'recovered',core)
    roundtrip=export(args.aseprite,candidate,args.output/'candidate_roundtrip',core)
    # The candidate preserves one entire source version, including all 29 shin
    # pixels. No cross-version merging, pixel invention or pivot reset occurs.
    for name,image in original[1].items():
        assert pixels(image)==pixels(roundtrip[1][name]),'candidate altered original '+name
    comparison=compare(original,recovered)
    result={'schema':'custodian.ne_master_audit.v1','input_hashes':hashes,'comparison':comparison,
            'candidate':str(candidate),'candidate_sha256':sha(candidate),'candidate_preserves_original_layers':True,
            'source_authority':'SINGLE_FRAME_provisional_human_review_required',
            'rig_validated':False,'v6_rerun_permitted':False,
            'candidate_blockers':roundtrip[0]['blocking_findings'],
            'solver_batch_sha256':sha(HERE/'batch.lua')}
    assert all(sha(path)==digest for path,digest in hashes.items())
    write(args.output/'MASTER_AUDIT_REPORT.json',result)
    # A tight source comparison and foot ROI are diagnostic charts, not art edits.
    sheet=Image.new('RGB',(520,200),'#252525');d=ImageDraw.Draw(sheet)
    for col,(label,data) in enumerate((('Original source',original),('Recovered source',recovered))):
        image=data[1][SOURCE];sheet.paste(image,(col*260,24),image)
        d.text((col*260+4,4),label,fill='white')
        for xy in comparison['source_differences']:
            x,y=xy['xy'];d.point((col*260+x,24+y),fill='#ff50ff')
        d.text((col*260+4,160),'Magenta: differing source pixels',fill='white')
    sheet.save(args.output/'source_difference_contact_sheet.png')
    print(json.dumps(result,indent=2))
    return 0

if __name__=='__main__':raise SystemExit(main())
