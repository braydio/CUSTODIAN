#!/usr/bin/env python3
"""Authored NE Operator part-level reconstruction, review candidate only.

R2 never substitutes a different animation's frame poses. It uses the *accepted*
rig's semantic raster parts, maps each leg piece to the immutable 15-frame IK
landmarks, and protects the already-rendered anatomical support-sole pixels.
This is art authoring, not an IK solver, runtime import, or timing decision.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import math
import struct
import zlib
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

W, H, N = 128, 128, 15
ORIGINAL_SHA = '0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149'
RIG_SHA = 'b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5'
ACTIVE_SHA = 'e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a'
REPORT_SHA = '88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a'
ALTERNATE_SHA = '2ecbde5f764bea4b86666abb26f5acf54e18f103d180290b491663b5129de2ea'
STYLE_SHA = '00a04e87a93ebf6c4de9040538453c2e44f72fbdf1a417bc8529aa22a2cc5551'
IDLE_SHA = '451eed81d8451aa0b5f81ce50144af05253d641c19cf04be74c96f348c1de802'
DONOR_SHA = '20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba'

# Confirmed neutral rig anchors. Far pivots are the human-accepted 8a254e0f1
# anatomy-recovery positions. Near are from the locked V5.5 source geometry.
NEUTRAL = {
    'near': {'hip': (63, 75), 'knee': (65, 89), 'ankle': (66, 100), 'toe': (75, 104)},
    'far': {'hip': (53, 75), 'knee': (52, 83), 'ankle': (50, 88), 'toe': (48, 91)},
}
# Append only if design authority specifically changes; no auto frame refit.
FOCUS = (1, 2, 3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15)
BG=(35, 36, 42, 255)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require_hash(path: Path, digest: str, name: str) -> None:
    if not path.is_file() or sha(path) != digest:
        raise ValueError(f'{name} immutable SHA256/source missing: {path}')


def png(path: Path, digest: str, shape: tuple[int, int]) -> np.ndarray:
    require_hash(path, digest, path.name)
    with Image.open(path) as im:
        if im.mode != 'RGBA' or im.size != shape:
            raise ValueError(f'{path.name} expected RGBA {shape}, got {im.mode} {im.size}')
        a=np.asarray(im, dtype=np.uint8).copy()
    if not np.isin(a[:,:,3], (0,255)).all():
        raise ValueError(f'{path.name}: nonbinary alpha')
    return a


def parse_aseprite_rig(path: Path, enforce_sha: bool = True, synthetic_missing_far: bool = False) -> dict[str, np.ndarray]:
    if enforce_sha: require_hash(path, RIG_SHA, 'human-accepted recovered rig')
    data=path.read_bytes()
    if len(data)<160 or struct.unpack_from('<H',data,4)[0]!=0xA5E0:
        raise ValueError('not a valid Aseprite file')
    w,h,depth=struct.unpack_from('<HHH',data,8)
    if (w,h,depth)!=(128,128,32): raise ValueError('expected one 128x128 RGBA rig')
    size,magic=struct.unpack_from('<IH',data,128)
    if magic!=0xF1FA: raise ValueError('invalid first frame')
    names=[];out={}; pos=144;frame_end=128+size
    while pos<frame_end:
        if pos+6>len(data):raise ValueError('truncated chunk')
        n,kind=struct.unpack_from('<IH',data,pos)
        if n<6 or pos+n>len(data):raise ValueError('bad chunk length')
        payload=data[pos+6:pos+n]
        if kind==0x2004:
            if len(payload)<18:raise ValueError('truncated layer')
            name_len=struct.unpack_from('<H',payload,16)[0]
            names.append(payload[18:18+name_len].decode('utf8'))
        if kind==0x2005:
            idx,x,y,opacity,cel_type=struct.unpack_from('<HhhBH',payload,0)
            if idx>=len(names):raise ValueError('cel refers to missing layer')
            if names[idx] in out:raise ValueError('duplicate semantic cel: '+names[idx])
            if cel_type==2:
                cw,ch=struct.unpack_from('<HH',payload,16)
                raw=zlib.decompress(payload[20:])
                if len(raw)!=cw*ch*4:raise ValueError('bad RGBA cel byte count')
                a=np.frombuffer(raw,dtype=np.uint8).reshape(ch,cw,4)
                full=np.zeros((H,W,4),dtype=np.uint8)
                x0=max(0,x);y0=max(0,y);x1=min(W,x+cw);y1=min(H,y+ch)
                if x0<x1 and y0<y1:full[y0:y1,x0:x1]=a[y0-y:y1-y,x0-x:x1-x]
                out[names[idx]]=full
        pos+=n
    needed=['__RIG_REFERENCE_LOCKED_FULL_BODY']+[f'__RIG_PART_{n}' for n in
      ('thigh_near_visible','shin_near_visible','foot_near_visible',
       'thigh_far_visible','shin_far_visible','foot_far_visible',
       'robe_near','robe_center','robe_far')]
    for n in needed:
        if n not in out:raise ValueError('accepted rig missing '+n)
    if synthetic_missing_far and not np.any(out['__RIG_PART_foot_far_visible'][:,:,3]):
        # Local synthetic-only parser exercise. NEVER used for actual source.
        sample=out['__RIG_PART_foot_near_visible'][99,70].copy()
        out['__RIG_PART_foot_far_visible'][89:93,46:52]=sample
    for n in needed[1:]:
        if int(np.count_nonzero(out[n][:,:,3]))<4:raise ValueError('empty/invalid accepted semantic part '+n)
    return out


def as_point(obj: dict) -> np.ndarray:
    return np.array([float(obj['x']),float(obj['y'])],dtype=float)


def xy(v) -> np.ndarray:
    return np.asarray(v,dtype=float)


def bones(frame: dict, side: str) -> dict[str, np.ndarray]:
    return {k:as_point(frame['legs'][side][k]) for k in ('hip','knee','ankle','toe')}


def rigid_warp(src: np.ndarray, a0, b0, a1, b1, normal_scale: float = 1.) -> np.ndarray:
    """Inverse-map RGBA texels for a semantic part: no scattered forward holes."""
    a0,b0,a1,b1=map(xy,(a0,b0,a1,b1))
    o=b0-a0;t=b1-a1;lo=np.linalg.norm(o);lt=np.linalg.norm(t)
    if not (lo>1 and lt>1) or not np.isfinite([*a0,*b0,*a1,*b1]).all():
        raise ValueError('bad/degenerate bone anchors')
    eo=o/lo;et=t/lt;no=np.array([-eo[1],eo[0]]);nt=np.array([-et[1],et[0]])
    yy,xx=np.mgrid[0:H,0:W];d=np.stack((xx-a1[0], yy-a1[1]),axis=-1)
    along=np.einsum('ijk,k->ij',d,et)*(lo/lt)
    across=np.einsum('ijk,k->ij',d,nt)/normal_scale
    sx=np.rint(a0[0]+along*eo[0]+across*no[0]).astype(int)
    sy=np.rint(a0[1]+along*eo[1]+across*no[1]).astype(int)
    out=np.zeros_like(src);inside=(sx>=0)&(sx<W)&(sy>=0)&(sy<H)
    out[inside]=src[sy[inside],sx[inside]]
    return out


def robe_warp(src: np.ndarray, field: dict, kind: str) -> np.ndarray:
    """Continuous hem shift anchored at waist, bounded by accepted knee travel."""
    nd=field['near']['knee'][0]-NEUTRAL['near']['knee'][0]
    fd=field['far']['knee'][0]-NEUTRAL['far']['knee'][0]
    stride=np.clip((nd-fd)/25.,-1.,1.)
    mode={'far':(.20,fd),'center':(.12,(nd+fd)/2.),'near':(.23,nd)}[kind]
    disp=np.clip(mode[0]*mode[1],-4.0,4.0)
    yy,xx=np.mgrid[0:H,0:W]
    t=np.clip((yy-65)/20.,0,1)
    shift_x=disp*t
    shift_y=(1.25*abs(stride)*t if kind=='near' else -.5*abs(stride)*t)
    sx=np.rint(xx-shift_x).astype(int);sy=np.rint(yy-shift_y).astype(int)
    out=np.zeros_like(src);inside=(sx>=0)&(sx<W)&(sy>=0)&(sy<H)
    out[inside]=src[sy[inside],sx[inside]]
    return out


def over(dst: np.ndarray, source: np.ndarray):
    foreground=source[:,:,3]>0
    dst[foreground]=source[foreground]


def distance_join(a: np.ndarray, b: np.ndarray, center: np.ndarray) -> float:
    ya,xa=np.where(a[:,:,3]>0);yb,xb=np.where(b[:,:,3]>0)
    if not len(xa) or not len(xb):return float('inf')
    # Around an anatomical joint only; not geometric screen-left assumptions.
    p=np.stack((xa,ya),axis=1);q=np.stack((xb,yb),axis=1)
    p=p[np.sum((p-center)**2,axis=1)<100]
    q=q[np.sum((q-center)**2,axis=1)<100]
    if len(p)==0 or len(q)==0:return float('inf')
    return float(np.sqrt(np.min(np.sum((p[:,None,:]-q[None,:,:])**2,axis=2))))


def build_frame(active: np.ndarray, parts: dict, motion: dict) -> tuple[np.ndarray,dict]:
    if motion['support'] not in ('near','far'):raise ValueError('missing support anatomy')
    side_parts={}; fields={side:bones(motion,side) for side in ('near','far')}
    for side in ('far','near'):
        f=fields[side];src=NEUTRAL[side]; side_parts[side]={}
        for key,ends in [('thigh',('hip','knee')),('shin',('knee','ankle')),('foot',('ankle','toe'))]:
            name=f'__RIG_PART_{key}_{side}_visible'
            img=rigid_warp(parts[name],src[ends[0]],src[ends[1]],f[ends[0]],f[ends[1]])
            side_parts[side][key]=img
    # Protect the original anatomical planted sole: the new source boot is
    # clipped BEFORE composition, and old contact pixels are restored below.
    planted=motion['support'];plant_contact=motion['legs'][planted]['rendered_boot_contact']
    contact_y=int(round(plant_contact['y']))
    if not 0<=contact_y<H:raise ValueError('invalid support boot contact row')
    side_parts[planted]['foot'][contact_y:,:,:]=0
    garments={k:robe_warp(parts[f'__RIG_PART_robe_{k}'],fields,k) for k in ('far','center','near')}
    # Reconstruct the lower silhouette as an organized part stack; preserve
    # entire frame elsewhere, including exact torso/hood/arm pixels.
    rebuilt=np.zeros_like(active)
    for img in (side_parts['far']['thigh'],side_parts['far']['shin'],side_parts['far']['foot'],
                garments['far'],side_parts['near']['thigh'],side_parts['near']['shin'],side_parts['near']['foot'],
                garments['center'],garments['near']):over(rebuilt,img)
    result=active.copy()
    # Clear only the original lower-body compartment; never screen-half-classify feet.
    yy,xx=np.mgrid[0:H,0:W]
    erase=(yy>=74)&(yy<=114)&(xx>=39)&(xx<=107)
    # Three robe panels reach above the thigh. Restrict opening to robe's silhouette,
    # avoiding the known near right-arm panel at (x>=77,y<=78).
    erase|=(yy>=68)&(yy<74)&(xx>=43)&(xx<=75)
    result[erase]=0
    # Only reconstructed portions below the top protected split may be pasted.
    paste=(yy>=68)&(xx>=39)&(xx<=107)
    paste&=~((xx>=77)&(yy<79))  # do not shave the near forearm
    mask=(rebuilt[:,:,3]>0)&paste
    result[mask]=rebuilt[mask]
    # Keep the actual sole pixels from the validated support boot. This is a
    # hard pixel preservation constraint, not a new contact fit or estimate.
    support=motion['support'];contact=motion['legs'][support]['rendered_boot_contact']
    cx=int(round(contact['x']));cy=int(round(contact['y']))
    if not 0<=cy<H or not 0<=cx<W or int(contact['count'])<=0:
        raise ValueError('missing actual rendered support boot contact')
    xs=range(max(0,int(contact['minx'])),min(W,int(contact['maxx'])+1))
    # Remove candidate pixels below the verified support sole in its local anatomical
    # boot window, and restore the exact original bottom two rows of the contact.
    bx=int(round(motion['legs'][support]['ankle']['x']))
    x0=max(0,min(cx,bx)-11);x1=min(W,max(cx,bx)+12)
    y0=max(0,cy-2);y1=min(H,cy+8)
    result[cy+1:y1,x0:x1]=0
    original_sole=active[y0:cy+1,x0:x1]
    rr=result[y0:cy+1,x0:x1]
    soles=np.zeros(original_sole.shape[:2],dtype=bool)
    soles[-2:,:]=(original_sole[-2:,:,3]>0)
    rr[soles]=original_sole[soles]
    # Validate exact provenance of bottom-most original foot/contact pixels.
    for sx in xs:
        if active[cy,sx,3]>0 and not np.array_equal(result[cy,sx],active[cy,sx]):
            raise ValueError('support contact pixel overwritten')
    if not np.array_equal(result[:68],active[:68]):
        raise ValueError('protected upper source changed')
    if not np.isin(result[:,:,3],(0,255)).all():raise ValueError('nonbinary output alpha')
    distances={}
    for side in ('near','far'):
        f=fields[side];q=side_parts[side]
        distances[side]={
         'knee_min_distance_px':round(distance_join(q['thigh'],q['shin'],f['knee']),3),
         'ankle_min_distance_px':round(distance_join(q['shin'],q['foot'],f['ankle']),3)}
    # If rig-art geometry physically breaks apart, do NOT fake artistic acceptance.
    if max(d['knee_min_distance_px'] for d in distances.values())>4.5 or \
       max(d['ankle_min_distance_px'] for d in distances.values())>4.5:
        raise ValueError(f'disconnected anatomical part masks: {distances}')
    changed=int(np.count_nonzero(np.any(result!=active,axis=2)))
    return result,{'frame':int(motion['frame']), 'support':support,'changed_rgba_pixels':changed,
         'joint_mask_distances':distances,'support_sole_preserved':True,
         'actual_support_contact':contact, 'motion_report_unmodified':True,
         'source_upper_68_rows_identical':True}


def preview(a: list[np.ndarray], b: list[np.ndarray], path: Path, frames=range(1,16)):
    w,h=5*256,3*160
    image=Image.new('RGB',(w,h),BG[:3]);d=ImageDraw.Draw(image)
    for i in frames:
        p=i-1;x=(p%5)*256;y=(p//5)*160
        d.text((x+4,y+4),f'F{i:02d} ACTIVE',fill='#c0cfdf')
        d.text((x+132,y+4),f'F{i:02d} R2',fill='#e6c176')
        for j,src in enumerate((a[p],b[p])):
            im=Image.new('RGBA',(W,H),BG);im.alpha_composite(Image.fromarray(src,'RGBA'))
            image.paste(im.convert('RGB'),(x+j*128,y+21))
    image.save(path)


def make_closeups(a:list[np.ndarray],b:list[np.ndarray],target:Path):
    picks=(1,2,5,7,9,11,12,13,14,15)
    out=Image.new('RGB',(5*256,2*144),BG[:3]);draw=ImageDraw.Draw(out)
    for j,i in enumerate(picks):
        x=(j%5)*256;y=(j//5)*144
        draw.text((x+3,y+3),f'F{i:02d} original',fill='#bacbe0')
        draw.text((x+133,y+3),f'F{i:02d} R2',fill='#ecd092')
        for offset,im in [(0,a[i-1]),(128,b[i-1])]:
            pil=Image.new('RGBA',(W,H),BG)
            pil.alpha_composite(Image.fromarray(im,'RGBA'))
            # Local pixel rectangle, exactly x=35..99,y=60..118.
            crop=pil.crop((35,60,99,118)).resize((128,116),Image.Resampling.NEAREST)
            out.paste(crop.convert('RGB'),(x+offset,y+20))
    out.save(target)


def make_bridge(paths:list[Path], target:Path):
    imgs=[]
    for p in paths:
        bb=p.read_bytes()
        with Image.open(p) as im:width,height=im.size
        imgs.append({'name':p.name,'sha256':hashlib.sha256(bb).hexdigest(),
            'width':width,'height':height,'mime_type':'image/png',
            'data_uri':'data:image/png;base64,'+base64.b64encode(bb).decode('ascii')})
    doc={'schema':'custodian.operator_ne_r2_review_pixels.v1','images':imgs,
         'art_accepted':False,'runtime_approved':False}
    target.write_text(json.dumps(doc,separators=(',',':')))
    if target.stat().st_size>4_000_000:raise ValueError('review bridge too large')
    for x in imgs:
        assert hashlib.sha256(base64.b64decode(x['data_uri'].split(',',1)[1])).hexdigest()==x['sha256']


def evaluate(active: np.ndarray, parts: dict, report: dict, output:Path):
    originals=[];new=[];stats=[]
    for i,m in enumerate(report['frames']):
        old=active[:,i*W:(i+1)*W].copy()
        art,diag=build_frame(old,parts,m)
        originals.append(old);new.append(art);stats.append(diag)
    candidate=np.concatenate(new,axis=1)
    output.mkdir(parents=True,exist_ok=False)
    target=output/'operator_ne_walk_r2_motion_anchored_candidate_15f_1920x128.png'
    Image.fromarray(candidate,'RGBA').save(target)
    preview(originals,new,output/'R2_BEFORE_AFTER_15_POSES.png')
    make_closeups(originals,new,output/'R2_BOOT_APRON_CLOSEUPS_10_POSES.png')
    make_bridge([output/'R2_BEFORE_AFTER_15_POSES.png', output/'R2_BOOT_APRON_CLOSEUPS_10_POSES.png'],output/'REVIEW_PIXELS.json')
    result={'schema':'custodian.operator_ne_r2_art_preview.v1','status':'REVIEW_ONLY',
            'animation_approved':False,'runtime_approved':False,'fps':None,
            'output':{'name':target.name,'sha256':sha(target),'size':[1920,128], 'frames':15},
            'source':'accepted semantic Aseprite rig art; clean alternate 15-frame is visual QA only',
            'motion_plan':'exact report IK landmarks retained as authority; pixels are art candidates, not measured IK proof',
            'frames':stats,'changed_pixels_total':sum(x['changed_rgba_pixels'] for x in stats)}
    (output/'R2_MOTION_CONTACT_AUDIT.json').write_text(json.dumps(result,indent=2)+'\n')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--active',type=Path,required=True)
    ap.add_argument('--rig',type=Path,required=True)
    ap.add_argument('--report',type=Path,required=True)
    ap.add_argument('--alternate',type=Path,required=True)
    ap.add_argument('--style',type=Path,required=True)
    ap.add_argument('--idle',type=Path,required=True)
    ap.add_argument('--output-dir',type=Path,required=True)
    a=ap.parse_args()
    if a.output_dir.exists():ap.error('refusing to overwrite output')
    for p,h,name in [(a.report,REPORT_SHA,'Iteration004 report'),(a.rig,RIG_SHA,'accepted recovered rig')]:
        require_hash(p,h,name)
    rep=json.loads(a.report.read_text())
    if rep.get('schema')!='custodian.ne_walk_preview.v1' or len(rep.get('frames',[]))!=N or \
       rep.get('input_validation',{}).get('source_hash')!=DONOR_SHA:
        ap.error('invalid/superseded accepted report')
    active=png(a.active,ACTIVE_SHA,(W*N,H))
    style=png(a.style,STYLE_SHA,(W,H))
    png(a.alternate,ALTERNATE_SHA,(W*N,H))
    png(a.idle,IDLE_SHA,(W*N,H))
    parts=parse_aseprite_rig(a.rig)
    if not np.array_equal(parts['__RIG_REFERENCE_LOCKED_FULL_BODY'],style):
        ap.error('style lock and accepted rig source diverge')
    result=evaluate(active,parts,rep,a.output_dir)
    print(json.dumps({'created':True,'candidate':result['output']['sha256'],
        'frames':N,'changed_pixels':result['changed_pixels_total'], 'approved':False}))
    return 0

if __name__=='__main__':raise SystemExit(main())
