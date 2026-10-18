#!/usr/bin/env python3
"""R3: authored post-composite boot/sole topology pass on exact motion-anchored R2.

NOT a gait re-solve, not runtime art. Rejects residual unsupported distal islands;
repairs only short boot-to-sole gaps with already-locked rig palette pixels.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
import clean_silhouette_r2 as r2

W,H,N=r2.W,r2.H,r2.N
MAX_BRIDGE_NEW_PIXELS=8
MAX_BRIDGE_EUCLIDEAN=9.0
CROP_BOX=(34,63,102,116)
FOCUS=(1,2,5,6,7,9,11,12,13,14,15)


def components(alpha:np.ndarray)->list[list[tuple[int,int]]]:
    """Deterministic 8-connected components with coordinates as (x,y)."""
    if alpha.shape!=(H,W): raise ValueError('bad raster shape')
    seen=np.zeros((H,W),bool);out=[]
    yy,xx=np.nonzero(alpha)
    for sx,sy in zip(xx,yy):
        if seen[sy,sx]:continue
        stack=[(int(sx),int(sy))];seen[sy,sx]=True;found=[]
        while stack:
            x,y=stack.pop();found.append((x,y))
            for dy in (-1,0,1):
                for dx in (-1,0,1):
                    if dx==0 and dy==0:continue
                    nx,ny=x+dx,y+dy
                    if 0<=nx<W and 0<=ny<H and alpha[ny,nx] and not seen[ny,nx]:
                        seen[ny,nx]=True;stack.append((nx,ny))
        out.append(found)
    return sorted(out,key=lambda c:(-len(c),min(y for x,y in c),min(x for x,y in c)))


def primary_component(frame:np.ndarray)->set[tuple[int,int]]:
    found=components(frame[:,:,3]>0)
    if not found:raise ValueError('empty candidate silhouette')
    # The body extends into the immutable first 68 rows, unlike a loose sole.
    body=[c for c in found if any(y<68 for x,y in c)]
    if not body:raise ValueError('missing protected upper-body connected component')
    return set(max(body,key=len))


def owners(parts:dict,motion:dict)->dict:
    out={}
    for side in ('near','far'):
        field=r2.bones(motion,side); neutral=r2.NEUTRAL[side];side_out={}
        for key,ends in [('thigh',('hip','knee')),('shin',('knee','ankle')),('foot',('ankle','toe'))]:
            name=f'__RIG_PART_{key}_{side}_visible'
            warped=r2.rigid_warp(parts[name],neutral[ends[0]],neutral[ends[1]],field[ends[0]],field[ends[1]])
            side_out[key]=warped
        out[side]=side_out
    return out


def contact_pixels(active:np.ndarray,motion:dict)->list[tuple[int,int]]:
    side=motion['support'];data=motion['legs'][side]['rendered_boot_contact']
    y=int(round(data['y']));xlo=int(data['minx']);xhi=int(data['maxx'])
    if y<68 or y>=H or xlo<0 or xhi>=W or xlo>xhi or not 0<int(data['count'])<=16:
        raise ValueError('invalid authoritative anatomical sole geometry')
    result=[(x,y) for x in range(xlo,xhi+1) if active[y,x,3]>0]
    if len(result)<1 or len(result)>16:raise ValueError('anatomical planted-sole pixels not present in active source')
    return result


def path_8(x1:int,y1:int,x2:int,y2:int)->list[tuple[int,int]]:
    """8-connected nearest-neighbor line, endpoints included."""
    n=max(abs(x2-x1),abs(y2-y1))
    return list(dict.fromkeys((int(round(x1+(x2-x1)*i/max(n,1))),int(round(y1+(y2-y1)*i/max(n,1)))) for i in range(n+1)))


def source_color(layer:np.ndarray,x:int,y:int)->np.ndarray:
    yy,xx=np.nonzero(layer[:,:,3]>0)
    if len(xx)==0:raise ValueError('empty semantic foot source')
    p=int(np.argmin((xx-x)**2+(yy-y)**2))
    return layer[yy[p],xx[p]].copy()


def attachment_candidate(out:np.ndarray,owner:dict,motion:dict,sole:list[tuple[int,int]])->tuple[tuple[int,int],tuple[int,int],float]:
    """Find a body-attached anatomical foot/shin pixel, not arbitrary robe color."""
    side=motion['support'];field=r2.bones(motion,side)
    ankle=field['ankle'];toe=field['toe']
    body=primary_component(out)
    # Prefer the semantic boot, then the anatomical shin. A robe pixel is not a boot anchor.
    for key in ('foot','shin'):
        mask=owner[side][key][:,:,3]>0
        candidates=[(x,y) for x,y in body if mask[y,x] and y>=68 and
                    min(np.linalg.norm(np.array((x,y))-ankle),np.linalg.norm(np.array((x,y))-toe))<=12.0]
        if not candidates:continue
        scored=[]
        for x,y in candidates:
            for sx,sy in sole:
                distance=math.hypot(sx-x,sy-y)
                # Min-distance selection is deterministic with secondary spatial tie breaks.
                scored.append((distance,abs(y-sy),y,x,sx,sy))
        if scored:
            d,_,y,x,sx,sy=min(scored)
            return (x,y),(sx,sy),d
    raise ValueError(f'no body-connected anatomical {side} foot/shin owner within 12px of ankle/toe')


def inspect_orphans(frame:np.ndarray,original:np.ndarray,motion:dict)->list[dict]:
    """Only assess lower-body novel/detached pixels, never assume x<64 means far."""
    comps=components(frame[:,:,3]>0)
    if not comps:raise ValueError('empty composition')
    main=primary_component(frame)
    result=[]
    targets=[r2.bones(motion,s)[k] for s in ('near','far') for k in ('knee','ankle','toe')]
    for c in comps:
        if (c[0] in main) or not any(68<=y<=116 for x,y in c):continue
        # A detached particle within 12px of actual leg joints is an art-failure risk.
        near=min(float(np.linalg.norm(np.array([x,y])-t)) for x,y in c for t in targets)
        altered=sum(int(not np.array_equal(frame[y,x],original[y,x])) for x,y in c)
        bbox=[min(x for x,y in c),min(y for x,y in c),max(x for x,y in c)+1,max(y for x,y in c)+1]
        result.append({'pixels':len(c),'bbox':bbox,'distance_to_anatomical_leg_px':round(near,3),
                       'changed_rgba_pixels':altered,'distal_leg_risk':bool(near<=12.0)})
    return result


def repair_distal_islands(out:np.ndarray,original:np.ndarray,owner:dict,motion:dict)->tuple[np.ndarray,list[dict]]:
    """Connect only newly detached boot/shin components through same-owner art.

    No deletion, no arbitrary direction changes. Oversized islands/bridges fail.
    """
    edits=[]
    for attempt in range(4):
        groups=components(out[:,:,3]>0);main=primary_component(out)
        interesting=[]
        for group in groups:
            if group[0] in main or not any(68<=y<=116 for x,y in group):continue
            changed=sum(int(not np.array_equal(out[y,x],original[y,x])) for x,y in group)
            if not changed:continue
            scores=[]
            for side in ('near','far'):
                f=r2.bones(motion,side)
                for k in ('ankle','toe'):
                    d=min(math.hypot(x-f[k][0],y-f[k][1]) for x,y in group)
                    scores.append((d,side))
            near,side=min(scores)
            if near<=12.0:interesting.append((group,side,near,changed))
        if not interesting:return out,edits
        if len(interesting)>3:raise ValueError(f'too many distal owner islands: {len(interesting)}')
        group,side,dist,changed=min(interesting,key=lambda g:(g[2],-g[3]))
        if len(group)>10:raise ValueError(f'distal detached component too large for bounded bridge: {len(group)}')
        f=r2.bones(motion,side)
        main_owner=[]
        for key in ('foot','shin'):
            mask=owner[side][key][:,:,3]>0
            main_owner=[(x,y) for x,y in main if mask[y,x] and y>=68 and
                        min(math.hypot(x-f[q][0],y-f[q][1]) for q in ('ankle','toe'))<=14.0]
            if main_owner:break
        if not main_owner:raise ValueError(f'no connected {side} owner art available for distal fragment')
        pairs=[]
        for x,y in group:
            for bx,by in main_owner:
                pairs.append((math.hypot(bx-x,by-y),bx,by,x,y))
        d,bx,by,x,y=min(pairs)
        if d>MAX_BRIDGE_EUCLIDEAN:raise ValueError(f'distal {side} fragment exceeds bridge bound: {d:.3f}px')
        path=path_8(bx,by,x,y)
        missing=[(xx,yy) for xx,yy in path if out[yy,xx,3]==0]
        if len(missing)>MAX_BRIDGE_NEW_PIXELS:raise ValueError('distal owner bridge too expensive')
        if any(yy<68 or yy>116 for xx,yy in missing):raise ValueError('distal bridge crosses protected torso')
        for xx,yy in missing:out[yy,xx]=source_color(owner[side]['foot'],xx,yy)
        edits.append({'owner':side,'size':len(group),'distance_px':round(d,3),'new_pixels':len(missing),
                      'bbox':[min(xx for xx,yy in group),min(yy for xx,yy in group),
                              max(xx for xx,yy in group)+1,max(yy for xx,yy in group)+1]})
        if not missing:raise ValueError('distal component remained disconnected without missing bridge pixels')
    raise ValueError('more than four bounded distal repair attempts')


def connect_support_sole(original:np.ndarray,candidate:np.ndarray,owner:dict,motion:dict)->tuple[np.ndarray,dict]:
    out=candidate.copy();sole=contact_pixels(original,motion)
    for x,y in sole:
        if not np.array_equal(out[y,x],original[y,x]):raise ValueError('source support sole changed before R3')
    comps_before=components(out[:,:,3]>0)
    main=primary_component(out)
    connected_before=all(p in main for p in sole)
    added=[];distance=0.0;anchor=None
    if not connected_before:
        anchor,end,distance=attachment_candidate(out,owner,motion,sole)
        if distance>MAX_BRIDGE_EUCLIDEAN:
            raise ValueError(f'boot-to-sole bridge exceeds anatomical radius: {distance:.3f}px (max {MAX_BRIDGE_EUCLIDEAN})')
        path=path_8(*anchor,*end)
        if any(y<68 or y>116 or x<31 or x>109 for x,y in path):
            raise ValueError('support bridge would escape permitted lower-body raster area')
        missing=[(x,y) for x,y in path if out[y,x,3]==0]
        if len(missing)>MAX_BRIDGE_NEW_PIXELS:
            raise ValueError(f'boot-to-sole bridge needs {len(missing)} new pixels > {MAX_BRIDGE_NEW_PIXELS}')
        foot=owner[motion['support']]['foot']
        for x,y in missing:
            # Copy authentic semantic rig boot color only, never blur or invent palette.
            out[y,x]=source_color(foot,x,y)
            added.append((x,y))
        main=primary_component(out)
        if not all(p in main for p in sole):
            raise ValueError('boot-to-sole bridge failed final assembled connectivity')
    for x,y in sole:
        if not np.array_equal(out[y,x],original[y,x]):raise ValueError('authoritative sole changed after R3')
    if not np.array_equal(out[:68],original[:68]):raise ValueError('protected upper art changed')
    # Evaluate AND repair owner-labeled detached islands in the FINAL raster.
    out,distal_repairs=repair_distal_islands(out,original,owner,motion)
    if not all(p in primary_component(out) for p in sole):
        raise ValueError("secondary distal repair lost anatomical support sole")
    orphan=inspect_orphans(out,original,motion)
    bad=[c for c in orphan if c['distal_leg_risk'] and c['changed_rgba_pixels']>0]
    if bad:raise ValueError(f'novel detached distal component(s) in final composite: {bad}')
    source_rgb={tuple(c) for k in ('near','far') for c in owner[k]['foot'].reshape(-1,4) if c[3]==255}
    if any(tuple(out[y,x]) not in source_rgb for x,y in added):
        raise ValueError('bridge color was not from rig boot palette')
    return out,{'frame':int(motion['frame']),'support':motion['support'],
       'support_connected_before':connected_before,'support_connected_after':True,
       'sole_pixels_exact':len(sole),'new_bridge_pixels':len(added),
       'new_bridge_coordinates':[list(p) for p in added],'bridge_distance_px':round(distance,3),
       'bridge_anchor':list(anchor) if anchor else None,
       'lower_orphan_components':orphan,'distal_repairs':distal_repairs,
       'final_distal_orphan_count':len(bad),
       'composite_components_before':len(comps_before),'composite_components_after':len(components(out[:,:,3]>0))}


def build_frame_r3(active:np.ndarray,parts:dict,motion:dict)->tuple[np.ndarray,dict]:
    r2_candidate,orig_diag=r2.build_frame(active,parts,motion)
    own=owners(parts,motion)
    target,diag=connect_support_sole(active,r2_candidate,own,motion)
    diag['r2_changed_rgba_pixels']=orig_diag['changed_rgba_pixels']
    diag['r3_changed_rgba_pixels']=int(np.count_nonzero(np.any(target!=active,axis=2)))
    diag['changed_since_r2_pixels']=int(np.count_nonzero(np.any(target!=r2_candidate,axis=2)))
    diag['joint_mask_distances']=orig_diag['joint_mask_distances']
    return target,diag


def preview(a:list[np.ndarray],b:list[np.ndarray],out:Path):
    im=Image.new('RGB',(1280,480),r2.BG[:3]);dr=ImageDraw.Draw(im)
    for i in range(15):
        x=(i%5)*256;y=(i//5)*160
        for j,src in enumerate([a[i],b[i]]):
            dr.text((x+j*128+3,y+3),f'F{i+1:02d} '+('R2' if j==0 else 'R3'),fill='#b8ceef' if j==0 else '#efc77e')
            tile=Image.new('RGBA',(W,H),r2.BG);tile.alpha_composite(Image.fromarray(src,'RGBA'))
            im.paste(tile.convert('RGB'),(x+j*128,y+20))
    im.save(out)


def closeups(a:list[np.ndarray],b:list[np.ndarray],out:Path):
    im=Image.new('RGB',(1280,2*152),r2.BG[:3]);dr=ImageDraw.Draw(im)
    for j,idx in enumerate([1,2,5,6,7,9,11,12,13,15]):
        x=(j%5)*256;y=(j//5)*152
        for k,src in enumerate([a[idx-1],b[idx-1]]):
            dr.text((x+k*128+3,y+3),f'F{idx:02d} '+('R2' if k==0 else 'R3'),fill='#b9cbea' if k==0 else '#edce83')
            tile=Image.new('RGBA',(W,H),r2.BG);tile.alpha_composite(Image.fromarray(src,'RGBA'))
            crop=tile.crop(CROP_BOX).resize((128,100),Image.Resampling.NEAREST)
            im.paste(crop.convert('RGB'),(x+k*128,y+20))
    im.save(out)


def evaluate(active:np.ndarray,parts:dict,report:dict,out:Path)->dict:
    if out.exists():raise ValueError('refuse overwrite of R3 review output')
    source=[];retouched=[];stats=[]
    for i,motion in enumerate(report['frames']):
        if motion['frame']!=i+1:raise ValueError('frame order mismatch')
        old=active[:,i*W:(i+1)*W].copy()
        r2candidate,_=r2.build_frame(old,parts,motion)
        r3candidate,metrics=connect_support_sole(old,r2candidate,owners(parts,motion),motion)
        if not np.isin(r3candidate[:,:,3],(0,255)).all():raise ValueError('nonbinary output alpha')
        metrics['r2_changed_rgba_pixels']=int(np.count_nonzero(np.any(r2candidate!=old,axis=2)))
        metrics['r3_changed_rgba_pixels']=int(np.count_nonzero(np.any(r3candidate!=old,axis=2)))
        metrics['changed_since_r2_pixels']=int(np.count_nonzero(np.any(r3candidate!=r2candidate,axis=2)))
        source.append(r2candidate);retouched.append(r3candidate);stats.append(metrics)
    a=np.concatenate(retouched,axis=1)
    out.mkdir(parents=True,exist_ok=False)
    target=out/'operator_ne_walk_r3_connected_candidate_15f_1920x128.png'
    Image.fromarray(a,'RGBA').save(target)
    preview(source,retouched,out/'R3_R2_BEFORE_AFTER_15_POSES.png')
    closeups(source,retouched,out/'R3_BOOT_SOLE_CLOSEUPS_10_POSES.png')
    r2.make_bridge([out/'R3_R2_BEFORE_AFTER_15_POSES.png',out/'R3_BOOT_SOLE_CLOSEUPS_10_POSES.png'],out/'REVIEW_PIXELS.json')
    # Do not assert 15->1 image similarity as a pass: report it for real visual review.
    def delta(a,b):return int(np.count_nonzero((a[:,:,3]>0)!=(b[:,:,3]>0)))
    seam_old=delta(source[14],source[0]);seam_new=delta(retouched[14],retouched[0])
    result={'schema':'custodian.operator_ne_r3_topology_review.v1','status':'REVIEW_ONLY',
      'animation_approved':False,'runtime_approved':False,'fps':None,
      'original_motion_authority':'Iteration 004 source IK report unchanged',
      'r2_candidate_sha256':'51e196c0a6b7dd34a9eb53557ff52528e3ef4cc7bd84b3fab6df8b8cdbc95047',
      'output':{'sha256':r2.sha(target),'frames':N,'size':[W*N,H],'name':target.name},
      'changed_since_r2_total':sum(x['changed_since_r2_pixels'] for x in stats),
      'r3_changed_vs_active_total':sum(x['r3_changed_rgba_pixels'] for x in stats),
      'seam_15_to_1_alpha_delta_r2':seam_old,'seam_15_to_1_alpha_delta_r3':seam_new,
      'frames':stats}
    (out/'R3_TOPOLOGY_AUDIT.json').write_text(json.dumps(result,indent=2)+'\n')
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for opt in ('active','rig','report','alternate','style','idle','r2-candidate','output-dir'):
        parser.add_argument('--'+opt,type=Path,required=True)
    a=parser.parse_args();
    if a.output_dir.exists():parser.error('output directory already exists')
    for p,h in [(a.rig,r2.RIG_SHA),(a.report,r2.REPORT_SHA),
                (a.r2_candidate,'51e196c0a6b7dd34a9eb53557ff52528e3ef4cc7bd84b3fab6df8b8cdbc95047')]:
        r2.require_hash(p,h,p.name)
    active=r2.png(a.active,r2.ACTIVE_SHA,(W*N,H))
    r2.png(a.alternate,r2.ALTERNATE_SHA,(W*N,H));style=r2.png(a.style,r2.STYLE_SHA,(W,H))
    r2.png(a.idle,r2.IDLE_SHA,(W*N,H))
    motion=json.loads(a.report.read_text())
    if motion.get('schema')!='custodian.ne_walk_preview.v1' or len(motion.get('frames',[]))!=N or motion.get('input_validation',{}).get('source_hash')!=r2.DONOR_SHA:
        raise ValueError('superseded or unsupported IK report authority')
    parts=r2.parse_aseprite_rig(a.rig)
    if not np.array_equal(parts['__RIG_REFERENCE_LOCKED_FULL_BODY'],style):raise ValueError('rig/style mismatch')
    # R2 must remain bitwise reproducible: prevent a changed staged R2 compositor.
    originals=[]
    for i,frame in enumerate(motion['frames']):
        preview,_=r2.build_frame(active[:,i*W:(i+1)*W],parts,frame)
        originals.append(preview)
    reproduced=np.concatenate(originals,axis=1)
    # Check exact RGBA pixel equivalence (not PNG encoder bytes) to the published R2 preview.
    with Image.open(a.r2_candidate) as im:raster=np.asarray(im.convert('RGBA'))
    if not np.array_equal(reproduced,raster):raise ValueError('staged R2 no longer reproduces approved reference preview pixels')
    res=evaluate(active,parts,motion,a.output_dir)
    print(json.dumps({'status':'REVIEW_ONLY','frames':N,'sha256':res['output']['sha256'],
           'added_bridge_pixels':res['changed_since_r2_total'],'seam_alpha_delta':res['seam_15_to_1_alpha_delta_r3']}))

if __name__=='__main__':raise SystemExit(main())
