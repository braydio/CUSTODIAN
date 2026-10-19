#!/usr/bin/env python3
"""Produce real Operator NE Skin V2 neutral-cutout and 3-apron-state art review.

Source-locked, review-only, no Asset Pipeline V2 import or runtime publication.
Usage from repository root: python3 .../skin_v2/run.py --donor-bundle ...
    --rig ... --baseline ... --output FRESH_DIRECTORY
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent))
from knight_skin_poc import run as poc
from knight_skin_poc import pose_map, skin_renderer
from skin_v2.apron_authority import (
    FRAME_VARIANT, ORDER, FULL, audit_neutral, art_gap_report,
    compose_frame, count, sha256, palette,
)

FRAMES=(1,5,7,12,15)
OUTPUTS=(
    'SKIN_V2_5POSE_640x128.png',
    'SKIN_V2_NEUTRAL_OWNER_AUDIT.png',
    'SKIN_V2_5POSE_APRON_REVIEW.png',
    'SKIN_V2_GAP_AND_OCCLUSION_MAP.png',
    'SKIN_V2_ART_REQUIREMENTS.json',
    'REVIEW_PIXELS.json',
    'REVIEW_NOTES.md',
)
FONT=ImageFont.load_default()


def rgba(arr):
    return Image.fromarray(arr.astype('uint8'),mode='RGBA')


def colored_overlay(labels, colors):
    a=np.zeros((128,128,4),dtype=np.uint8)
    for value,color in colors.items():a[labels==value]=color
    return rgba(a)


def tile(frame, label, scale=2, background=(30,30,36,255)):
    image=Image.new('RGBA',(128*scale,128*scale+24),background)
    dr=ImageDraw.Draw(image)
    dr.text((5,4),label,font=FONT,fill=(235,235,235,255))
    image.alpha_composite(frame.resize((128*scale,128*scale),Image.Resampling.NEAREST),(0,24))
    return image


def sheet(rows,cols):
    tw,th=rows[0][0].size
    out=Image.new('RGBA',(cols*tw,len(rows)*th),(26,26,32,255))
    for i,row in enumerate(rows):
        if len(row)!=cols:raise ValueError('inconsistent contact-sheet columns')
        for j,img in enumerate(row):out.alpha_composite(img,(j*tw,i*th))
    return out


def image_hash(img):
    blob=io.BytesIO();img.save(blob,format='PNG',optimize=False)
    return blob.getvalue(),hashlib.sha256(blob.getvalue()).hexdigest()


def main(argv=None):
    root=Path.home()/'Downloads/operator_ne_master_audit_implementation_v1'
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--donor-bundle',type=Path,required=True)
    p.add_argument('--rig',type=Path,required=True)
    p.add_argument('--baseline',type=Path,required=True)
    p.add_argument('--annotations',type=Path,default=HERE.parent/'annotations.json')
    p.add_argument('--source-aseprite',type=Path,default=Path.home()/'Downloads/SINGLE_FRAME.aseprite')
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args(argv)
    args.output=args.output.expanduser().resolve()
    if args.output.exists():raise FileExistsError(f'output must be fresh, refusing overwrite: {args.output}')
    # Reuse the verified POC source SHA and 15-frame near/far donor-identity gates.
    inputs=poc.load_inputs(args)
    rig=inputs['rig']
    residual,neutral_audit,upper_labels=audit_neutral(rig)
    existing=skin_renderer.validate_rig_and_neutral(rig)
    if not np.array_equal(residual,existing['residual']):
        raise ValueError('Skin V2 rest decomposition differs from verified POC')
    mapped,scale,scale_terms=pose_map.map_all(inputs['annotations'])
    by_frame={x['frame']:x for x in mapped}
    r2=skin_renderer._r2_helpers()
    baselineframes={}
    rendered={};ownerframes={};overlays={};records=[]
    for n in FRAMES:
        target=pose_map.validate_support_authority(inputs['annotations'][n-1],inputs['report']['frames'][n-1])
        posed=pose_map.translate_pose_to_contact(by_frame[n],target)
        old,oldowner,oldreport=skin_renderer.render_pose(existing|{'rig':rig},posed)
        new,newowner,newreport=compose_frame(rig,residual,posed,r2.rigid_warp,skin_renderer._row_shear)
        repeated,second_owner,_=compose_frame(rig,residual,posed,r2.rigid_warp,skin_renderer._row_shear)
        if not np.array_equal(new,repeated) or not np.array_equal(newowner,second_owner):
            raise ValueError(f'F{n:02d}: nondeterministic source pixel composition')
        if n in (1,15) and not np.array_equal(old,new):
            raise ValueError(f'F{n:02d}: neutral must match prior Knight POC byte-for-byte')
        if n in (5,7,12) and np.array_equal(old,new):
            raise ValueError(f'F{n:02d}: authored apron variant did not change the costume')
        # Preserve original motion/support; don't infer a new planted contact from cloth.
        support=oldreport['support_raster']; final_id=2+ORDER.index('foot_'+posed['support']+'_visible')
        foot_mask=(newowner==final_id)
        visible_sole=bool(support['nearest_source_foot_pixel'] and
              foot_mask[support['nearest_source_foot_pixel'][1],support['nearest_source_foot_pixel'][0]])
        if n!=7 and not visible_sole:
            raise ValueError(f'F{n:02d}: new apron occluded the original planted support toe')
        if n==7 and visible_sole:
            raise ValueError('F07: far supporting toe was exposed against accepted semantic occlusion')
        if not palette(new).issubset(palette(rig[FULL])):
            raise ValueError(f'F{n:02d}: novel palette')
        gap,gap_image=art_gap_report(old,new,oldowner,newowner)
        baselineframes[n]=old;rendered[n]=new;ownerframes[n]=newowner;overlays[n]=gap_image
        old_parts=oldreport['visible_part_reports']; far_foot_visible=old_parts['foot_far_visible']['visible_pixels']
        records.append({'frame':n,'variant':FRAME_VARIANT[n],
                        'rendered_sha256':hashlib.sha256(new.tobytes()).hexdigest(),
                        'changed_rgba_pixels':count(np.any(new!=old,axis=2)),
                        'root_offset':posed['translation'],
                        'support_side':posed['support'],
                        'support_toe_target':target,
                        'original_support_visibility_preserved':True,
                        'original_far_foot_visible_pixels':far_foot_visible,
                        'new_far_foot_visible_pixels':count(newowner == 2+ORDER.index('foot_far_visible')),
                        'apron':newreport,'unfilled_cloth_requirements':gap})
    # Repeat the pinned source checks after rendering.
    poc._verify_immutable_inputs(args,inputs['hashes'])
    source_thumb=rgba(rig[FULL]);static=rgba(residual)
    owner_keys={1:(87,137,230,255),2:(208,111,196,255),3:(234,169,67,255)}
    audit_sheet=sheet([[tile(source_thumb,'Locked neutral'),
                        tile(static,'Static residual'),
                        tile(colored_overlay(upper_labels,owner_keys),'Provisional bins only')]],3)
    rows=[];gap_rows=[]
    for n in FRAMES:
        candidate=rgba(rendered[n]); prior=rgba(baselineframes[n]); donor=rgba(inputs['donor_frames'][n-1]);
        owner=colored_overlay(ownerframes[n],{
            1:(101,133,184,255),
            2+ORDER.index('foot_near_visible'):(237,102,80,255),
            2+ORDER.index('foot_far_visible'):(75,192,218,255),
            2+ORDER.index('robe_near'):(198,80,207,255),
            2+ORDER.index('robe_far'):(205,181,83,255),
            2+ORDER.index('robe_center'):(178,110,211,255),
        })
        rows.append([tile(donor,f'F{n:02d} Knight'),tile(prior,'Earlier Knight skin'),
                     tile(candidate,'Skin V2 '+FRAME_VARIANT[n]),tile(owner,'Layer provenance')])
        gap_rows.append([tile(prior,f'F{n:02d} before'),tile(candidate,'V2 apron'),
                         tile(rgba(overlays[n]),'Red: newly clear | blue: filled')])
    review=sheet(rows,4);gap_sheet=sheet(gap_rows,3)
    sprite=np.zeros((128,640,4),dtype=np.uint8)
    for i,n in enumerate(FRAMES):sprite[:,128*i:128*(i+1)]=rendered[n]
    pictures={
        OUTPUTS[0]:rgba(sprite),OUTPUTS[1]:audit_sheet,
        OUTPUTS[2]:review,OUTPUTS[3]:gap_sheet,
    }
    report={'schema':'custodian.operator_ne_skin_v2_art_authoring.v1',
            'workstream':'operator-2-5d-ne-walk-retargeting','iteration':10,
            'source_hashes':inputs['hashes'],'rendered_frames':list(FRAMES),
            'numerically_verified_donor_frames':15,'neutral_owner_audit':neutral_audit,
            'variants':FRAME_VARIANT,'art_variants_from_source_palette_only':True,
            'new_hidden_backing_pixels_authored':0,
            'art_accepted':False,'fps':None,'runtime_ready':False,
            'upper_body_articulated':False,
            'limits':['review-only: not a valid full walk cycle',
                      'apron variants are derived cutouts, not missing hidden-source paintings',
                      'F05 far boot remains subject to user art-occlusion review'],
            'frames':records}
    if not any(x['unfilled_cloth_requirements']['unverified_hidden_backing_required'] for x in records):
        report['no_revealed_gaps_detected']=True
    else:report['no_revealed_gaps_detected']=False
    # No post-render source mutation; full output exists only after all checks.
    args.output.parent.mkdir(parents=True,exist_ok=True)
    tmp=Path(tempfile.mkdtemp(dir=args.output.parent,prefix='.'+args.output.name+'.tmp-'))
    try:
        for name,picture in pictures.items():picture.save(tmp/name,format='PNG',optimize=False)
        report['artifact_sha256']={k:sha256(tmp/k) for k in pictures}
        (tmp/OUTPUTS[4]).write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
        bridges={'schema':'custodian.operator_ne_skin_v2_review_pixels.v1','images':{}}
        for name in (OUTPUTS[1],OUTPUTS[2],OUTPUTS[3]):
            im=pictures[name]
            blob=(tmp/name).read_bytes()
            bridges['images'][name]={'mime_type':'image/png','width':im.width,'height':im.height,
                                     'sha256':hashlib.sha256(blob).hexdigest(),
                                     'base64':base64.b64encode(blob).decode('ascii')}
        (tmp/OUTPUTS[5]).write_text(json.dumps(bridges,indent=2)+'\n',encoding='utf8')
        (tmp/OUTPUTS[6]).write_text('''# Operator NE Skin V2 · Cutout and apron proof

Source-authoritative review only. Five sparse poses F01/F05/F07/F12/F15; not an animation loop.
No FPS, runtime integration, or hidden pixel authoring. Neutral reconstructed with exact source pixels.

Review (1) Does F05/F07 crossover become clearer or does far boot need independently authored visibility?
(2) Does F12 apron actually open around the stride without tearing the hem?
(3) Which red (newly transparent) gaps need costume backing before final authoring?
(4) Are provisional hood/torso/pelvis partitions credible enough to plan an upper-body rig?

Red gap pixels are art-authoring questions, not automatically defects. All new costume art must go through Asset Pipeline V2 after separate approval.
''',encoding='utf8')
        if sorted(p.name for p in tmp.iterdir()) != sorted(OUTPUTS):raise ValueError('incomplete review files')
        tmp.rename(args.output)
    except Exception:
        shutil.rmtree(tmp,ignore_errors=True)
        raise
    print(json.dumps({'result':'REVIEW_ONLY','output':str(args.output),'artifacts':list(OUTPUTS),
                      'source_input_hashes_locked':True,
                      'neutral_reassembly_changed_pixels':0,
                      'hidden_backing_authored_pixels':0,'need_real_art_review':True},indent=2))
    return 0

if __name__=='__main__':
    try:raise SystemExit(main())
    except Exception as error:
        print('FAIL CLOSED Skin V2: '+str(error),file=sys.stderr)
        raise SystemExit(2)
