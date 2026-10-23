#!/usr/bin/env python3
"""Losslessly partition the visible pixels of CUSTODIAN's flattened south Operator.

No hallucinated hidden surfaces: the output is a visible-surface segmentation with
an explicit, hypothetical overlap/hierarchy ledger. This script is calibrated
ONLY for frame index 4 of the pinned eight-view 128x128 Aseprite source.

Usage:
  python3 scripts/extract_operator_south_rig.py \
      --source source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite \
      --out extracted
Dependencies: Pillow. Pure Python Aseprite reader/writer for the scoped data.
"""
from __future__ import annotations

import argparse
import hashlib
import csv
import json
import struct
import zlib
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw

SOURCE_SHA256 = '61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3'
PROFILE_SHA256 = '05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761'
SOURCE_FRAME_INDEX = 4  # zero-based south; original directions N,NE,E,SE,S,SW,W,NW
W = H = 128
ROOT = [64, 106]
GROUND = [64, 107]

# Hand-traced part ownership ROIs from the nearest-neighbor 8px annotated source.
# Later ROIs resolve semantic precedence in intersecting *visible* pixel areas.
# Coordinates are pixel centers, 0-based, and intentionally stay human-editable.
# This is a surface classification, not hidden pixel reconstruction.
PARTS = [
    ('cape_back_left', None, 10, False, [(51,55),(59,57),(57,65),(51,76),(47,80),(43,77),(47,67)]),
    ('cape_back_right', None, 20, False, [(72,56),(78,56),(84,65),(87,78),(82,81),(75,75),(72,64)]),
    ('thigh_screen_left', 'pelvis', 30, True, [(48,73),(62,73),(60,85),(55,89),(48,87),(44,80)]),
    ('shin_screen_left', 'thigh_screen_left', 40, True, [(48,83),(59,83),(57,93),(48,94),(45,90)]),
    ('boot_screen_left', 'shin_screen_left', 50, True, [(47,88),(59,89),(56,97),(44,97),(39,94),(40,89)]),
    ('thigh_screen_right', 'pelvis', 60, True, [(70,72),(81,74),(84,89),(73,91),(69,82)]),
    ('shin_screen_right', 'thigh_screen_right', 70, True, [(73,82),(82,82),(83,96),(73,96)]),
    ('boot_screen_right', 'shin_screen_right', 80, True, [(73,92),(84,93),(87,106),(77,106),(73,102)]),
    ('torso', None, 90, False, [(53,39),(76,39),(81,50),(77,60),(72,63),(56,63),(50,54)]),
    ('pelvis', 'torso', 100, False, [(55,56),(72,56),(76,66),(69,72),(60,70),(51,64)]),
    ('tabard_screen_left', 'pelvis', 110, True, [(55,60),(65,62),(64,82),(59,88),(51,83),(46,79),(49,69)]),
    ('tabard_screen_right', 'pelvis', 120, True, [(65,61),(75,61),(82,73),(84,78),(76,85),(68,88),(65,80)]),
    ('tabard_center_fold', 'pelvis', 130, True, [(60,62),(70,63),(74,78),(68,86),(64,87),(59,79)]),
    ('arm_upper_screen_left', 'torso', 140, True, [(45,41),(56,43),(55,53),(49,59),(42,56),(42,47)]),
    ('arm_forearm_screen_left', 'arm_upper_screen_left', 150, True, [(42,50),(50,52),(50,64),(44,66),(39,60)]),
    ('hand_screen_left', 'arm_forearm_screen_left', 160, True, [(40,59),(49,60),(49,70),(39,71),(37,65)]),
    ('arm_upper_screen_right', 'torso', 170, True, [(74,40),(84,40),(89,47),(87,57),(77,58),(73,51)]),
    ('arm_forearm_screen_right', 'arm_upper_screen_right', 180, True, [(80,50),(89,51),(90,64),(82,67),(79,61)]),
    ('hand_screen_right', 'arm_forearm_screen_right', 190, True, [(82,59),(92,59),(93,70),(81,72),(80,65)]),
    ('belt_clasp', 'pelvis', 200, False, [(53,55),(75,55),(76,62),(71,65),(57,64),(52,60)]),
    ('hood', 'torso', 210, True, [(64,18),(71,20),(76,26),(79,35),(76,42),(71,46),(59,46),(52,43),(49,36),(54,25),(58,20)]),
    ('pauldron_screen_left', 'torso', 220, True, [(48,32),(55,33),(59,40),(56,46),(49,48),(43,44),(42,39)]),
    ('pauldron_screen_right', 'torso', 230, True, [(75,32),(82,35),(88,42),(85,46),(76,48),(71,43)]),
]

# Approximate joint pivots: geometric *authoring hints*, NOT reference-derived anatomical truth.
# The MF1 engine currently treats pivots/parents as metadata (no joint rotations).
# These anatomical/behind-front-cloth components cannot be recovered from
# the flattened front frame. Keep their rig anchor layers EMPTY, not tiny stray
# pixels masquerading as complete movable geometry.
HIDDEN_PLACEHOLDERS = frozenset({
    'cape_back_left', 'cape_back_right', 'thigh_screen_left',
    'thigh_screen_right', 'pelvis',
})

PIVOTS = {
    'cape_back_left': (53, 57), 'cape_back_right': (76, 57),
    'thigh_screen_left': (57, 75), 'shin_screen_left': (52, 84), 'boot_screen_left': (52, 92),
    'thigh_screen_right': (75, 76), 'shin_screen_right': (79, 86), 'boot_screen_right': (79, 97),
    'torso': (64, 52), 'pelvis': (64, 61),
    'tabard_screen_left': (57, 63), 'tabard_screen_right': (73, 63), 'tabard_center_fold': (64, 63),
    'arm_upper_screen_left': (50, 45), 'arm_forearm_screen_left': (45, 54), 'hand_screen_left': (45, 63),
    'arm_upper_screen_right': (80, 45), 'arm_forearm_screen_right': (84, 54), 'hand_screen_right': (85, 64),
    'belt_clasp': (64, 59), 'hood': (64, 40), 'pauldron_screen_left': (51, 39), 'pauldron_screen_right': (80, 39),
}

# Visual layer-order guesses for where the flattened character obscures parts.
# These are descriptive; pixel assignments are exact but invisible surfaces are absent.
OVERLAP = [
    {'front':'tabard_screen_left','behind':'thigh_screen_left','type':'waist-drape','uncertainty':'high'},
    {'front':'tabard_screen_right','behind':'thigh_screen_right','type':'waist-drape','uncertainty':'high'},
    {'front':'tabard_center_fold','behind':'tabard_screen_left','type':'overlapping-front-fold','uncertainty':'high'},
    {'front':'tabard_center_fold','behind':'tabard_screen_right','type':'overlapping-front-fold','uncertainty':'high'},
    {'front':'hood','behind':'torso','type':'cowl-at-collar','uncertainty':'medium'},
    {'front':'pauldron_screen_left','behind':'arm_upper_screen_left','type':'shoulder-armor','uncertainty':'medium'},
    {'front':'pauldron_screen_right','behind':'arm_upper_screen_right','type':'shoulder-armor','uncertainty':'medium'},
    {'front':'belt_clasp','behind':'pelvis','type':'belt-layer','uncertainty':'medium'},
    {'front':'hand_screen_left','behind':'arm_forearm_screen_left','type':'glove-cuff','uncertainty':'medium'},
    {'front':'hand_screen_right','behind':'arm_forearm_screen_right','type':'glove-cuff','uncertainty':'medium'},
    {'front':'torso','behind':'cape_back_left','type':'back-cloak-root','uncertainty':'high'},
    {'front':'torso','behind':'cape_back_right','type':'back-cloak-root','uncertainty':'high'},
]


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def aseprite_frames(raw: bytes) -> list[Image.Image]:
    """Read exact scoped Aseprite: 32-bit RGBA, normal visible image layers, 8 frames.

    A restrictive parser intentionally refuses unsupported blends and multi-layer
    source documents instead of silently creating an incorrect projection.
    """
    if len(raw) < 128:
        raise ValueError('Aseprite header truncated')
    sz, magic, nframes, width, height, depth = struct.unpack_from('<IHHHHH', raw, 0)
    if sz != len(raw) or magic != 0xA5E0 or (nframes, width, height, depth) != (8, W, H, 32):
        raise ValueError('Unexpected source file format or frame dimensions')
    layers: list[tuple[int,int,int,int,str]] = []
    frames: list[Image.Image] = []
    off = 128
    for fi in range(nframes):
        if off + 16 > len(raw):
            raise ValueError('Truncated Aseprite frame header')
        flen, fmagic, oldchunks, duration, _, n_chunks = struct.unpack_from('<IHHHHI', raw, off)
        if fmagic != 0xF1FA or flen < 16 or off + flen > len(raw):
            raise ValueError('Invalid Aseprite frame header')
        count = n_chunks or oldchunks
        pos = off + 16
        chunks_end = off + flen
        cels: list[tuple[int,int,int,int,Image.Image]] = []
        for _ in range(count):
            if pos + 6 > chunks_end:
                raise ValueError('Truncated chunk')
            clen, ctype = struct.unpack_from('<IH', raw, pos)
            if clen < 6 or pos + clen > chunks_end:
                raise ValueError('Invalid chunk bounds')
            payload = raw[pos+6:pos+clen]
            if ctype == 0x2004:
                if len(payload) < 18:
                    raise ValueError('Layer chunk truncated')
                flags, typ, level, _, _, blend = struct.unpack_from('<HHHHHH', payload, 0)
                opacity = payload[12]
                nlen = struct.unpack_from('<H', payload, 16)[0]
                name = payload[18:18+nlen].decode('utf-8')
                if len(name.encode('utf-8')) != nlen:
                    raise ValueError('Layer name truncated')
                layers.append((flags,typ,level,opacity,name))
                if typ != 0 or blend != 0 or level != 0 or opacity != 255:
                    raise ValueError('Source contains unsupported layer composition')
            elif ctype == 0x2005:
                if len(payload) < 16:
                    raise ValueError('Cel chunk truncated')
                li, x, y, opacity, celtype, z = struct.unpack_from('<HhhBHh', payload, 0)
                if li >= len(layers) or opacity != 255 or z != 0 or celtype not in (0,2):
                    raise ValueError('Source cel has unsupported composition')
                cw, ch = struct.unpack_from('<HH',payload,16)
                pix = payload[20:]
                if celtype==2:
                    pix = zlib.decompress(pix)
                if len(pix) != cw*ch*4:
                    raise ValueError('Invalid source cel decompressed length')
                cels.append((li,x,y,opacity,Image.frombytes('RGBA',(cw,ch),pix)))
            pos += clen
        if pos != chunks_end:
            raise ValueError('Aseprite frame chunk mismatch')
        # The supplied source contains exactly one visible, opaque image layer.
        if len(layers) != 1 or not layers[0][0] & 1 or len(cels) != 1:
            raise ValueError('Expected the pinned single-layer flattened character')
        canvas = Image.new('RGBA',(W,H),(0,0,0,0))
        _,x,y,_,img = cels[0]
        canvas.alpha_composite(img,(x,y))
        frames.append(canvas)
        off += flen
    if off != len(raw):
        raise ValueError('Trailing data beyond last Aseprite frame')
    return frames


def polygon_mask(points: list[tuple[int,int]]) -> Image.Image:
    mask = Image.new('1',(W,H),0)
    ImageDraw.Draw(mask).polygon(points,fill=1)
    return mask


def classify_pixels(frame: Image.Image) -> tuple[list[list[int]],dict[str,int],int]:
    alpha = frame.getchannel('A')
    ids = [[-1]*W for _ in range(H)]
    painted=0
    for i, (name,_,_,_,polygon) in enumerate(PARTS):
        if name in HIDDEN_PLACEHOLDERS:
            continue
        p=polygon_mask(polygon)
        for y in range(H):
            for x in range(W):
                if alpha.getpixel((x,y)) and p.getpixel((x,y)):
                    ids[y][x]=i
    # Handle a sparse edge fringe with nearest *visible* classified pixel.
    # This is not inpainting. No source pixel is created or modified.
    known=[(x,y,ids[y][x]) for y in range(H) for x in range(W) if ids[y][x]>=0]
    if not known:
        raise ValueError('No layer polygons overlap visible pixels')
    for y in range(H):
        for x in range(W):
            if alpha.getpixel((x,y)) and ids[y][x]<0:
                _,_,part=min(known,key=lambda t:((x-t[0])**2+(y-t[1])**2,t[2]))
                ids[y][x]=part
                painted+=1
    counts=Counter(ids[y][x] for y in range(H) for x in range(W) if alpha.getpixel((x,y)))
    if any(counts[i]==0 for i in range(len(PARTS)) if PARTS[i][0] not in HIDDEN_PLACEHOLDERS):
        raise ValueError('Empty segmentation part: '+','.join(PARTS[i][0] for i in range(len(PARTS)) if counts[i]==0 and PARTS[i][0] not in HIDDEN_PLACEHOLDERS))
    return ids,{PARTS[i][0]:counts[i] for i in range(len(PARTS))},painted


def write_aseprite(parts: list[tuple[str,Image.Image]], path: Path) -> None:
    """Make one-frame layered native Aseprite source; verify with strict parser separately."""
    chunks=[]
    for name,_ in parts:
        n=name.encode('utf-8')
        payload=struct.pack('<HHHHHHB3sH',3,0,0,W,H,0,255,b'\0\0\0',len(n))+n
        chunks.append(struct.pack('<IH',len(payload)+6,0x2004)+payload)
    for idx,(name,img) in enumerate(parts):
        payload=struct.pack('<HhhBHh5sHH',idx,0,0,255,2,0,b'\0'*5,W,H)+zlib.compress(img.tobytes(),9)
        chunks.append(struct.pack('<IH',len(payload)+6,0x2005)+payload)
    frame_body=b''.join(chunks)
    frame=struct.pack('<IHHHHI',16+len(frame_body),0xF1FA,0,100,0,len(chunks))+frame_body
    header=bytearray(128)
    struct.pack_into('<IHHHHH',header,0,128+len(frame),0xA5E0,1,W,H,32)
    struct.pack_into('<I',header,14,1)
    struct.pack_into('<H',header,18,100)
    struct.pack_into('<H',header,32,256)
    struct.pack_into('<BBhhHH',header,34,1,1,0,0,16,16)
    path.write_bytes(header+frame)


def read_layered_aseprite(data: bytes) -> tuple[list[Image.Image],list[str]]:
    """Independent readback of generated layered file for reconstruction QA."""
    _,magic,nframes,w,h,d=struct.unpack_from('<IHHHHH',data,0)
    if magic!=0xA5E0 or nframes!=1 or (w,h,d)!=(W,H,32):
        raise ValueError('Broken generated Aseprite header')
    off=128;length,fmagic,_,_,_,chunks=struct.unpack_from('<IHHHHI',data,off)
    if fmagic != 0xF1FA or off+length !=len(data):
        raise ValueError('Invalid generated Aseprite frame')
    pos=144;names=[];cels={}
    for _ in range(chunks):
        clen,typ=struct.unpack_from('<IH',data,pos);p=data[pos+6:pos+clen]
        if typ==0x2004:
            ln=struct.unpack_from('<H',p,16)[0];names.append(p[18:18+ln].decode())
        elif typ==0x2005:
            li,x,y,op,ct,_=struct.unpack_from('<HhhBHh',p,0)
            cw,ch=struct.unpack_from('<HH',p,16)
            pixels=zlib.decompress(p[20:]);cels[li]=(Image.frombytes('RGBA',(cw,ch),pixels),x,y)
        pos+=clen
    if pos!=len(data) or len(cels)!=len(names):
        raise ValueError('Invalid generated Aseprite layers')
    canvas=Image.new('RGBA',(W,H))
    for i in range(len(names)):
        img,x,y=cels[i];canvas.alpha_composite(img,(x,y))
    return [canvas],names


def inspect_seams(ids: list[list[int]]) -> list[dict]:
    seams=Counter()
    for y in range(H):
        for x in range(W):
            i=ids[y][x]
            if i<0:continue
            for nx,ny in ((x+1,y),(x,y+1)):
                if nx<W and ny<H and (j:=ids[ny][nx])>=0 and j!=i:
                    a,b=sorted((PARTS[i][0],PARTS[j][0]));seams[(a,b)]+=1
    return [{'parts':list(k),'boundary_pixel_edges':v} for k,v in sorted(seams.items(),key=lambda z:(-z[1],z[0]))]


def touching_seam(ids: list[list[int]], x: int, y: int) -> bool:
    owner=ids[y][x]
    if owner<0:return False
    return any(0<=nx<W and 0<=ny<H and ids[ny][nx]>=0 and ids[ny][nx]!=owner
               for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)))


def colorize_map(frame: Image.Image, ids: list[list[int]], out: Path) -> None:
    palette=[(228,98,97),(249,183,84),(212,215,90),(111,196,133),(89,199,194),(91,153,217),
             (170,136,220),(230,127,183),(176,198,100),(232,160,123),(129,194,224)]
    col=Image.new('RGBA',(W,H))
    for y in range(H):
        for x in range(W):
            if ids[y][x]>=0:
                r,g,b=palette[ids[y][x]%len(palette)]
                col.putpixel((x,y),(r,g,b,255))
    scale=7
    # Structured diagram: original, part owner map, reconstructed.
    panel=Image.new('RGB',(W*scale*3, H*scale+90),(38,40,44))
    input_panel=Image.new('RGBA',(W,H),(42,44,48,255));input_panel.alpha_composite(frame)
    for i,im in enumerate((input_panel,col,frame)):
        if im.mode=='RGBA':
            bkg=Image.new('RGBA',(W,H),(42,44,48,255));bkg.alpha_composite(im);im=bkg
        panel.paste(im.convert('RGB').resize((W*scale,H*scale),Image.Resampling.NEAREST),(i*W*scale,70))
    d=ImageDraw.Draw(panel)
    for i,s in enumerate(('SOURCE 128x128, SOUTH','PIXEL OWNER ID / SEMANTIC MASK','EXACT NEUTRAL REASSEMBLY')):
        d.text((i*W*scale+15,17),s,fill=(245,245,245))
    panel.save(out)


def write_outputs(source: Path, out: Path, *, strict_hash: bool = True) -> dict:
    raw=source.read_bytes();source_sha=sha(raw)
    if strict_hash and source_sha != SOURCE_SHA256:
        raise ValueError('Original character source has changed; refuse to reuse calibrated semantic polygons')
    frames=aseprite_frames(raw)
    frame=frames[SOURCE_FRAME_INDEX]
    if set(frame.getchannel('A').tobytes()) != {0,255}:
        raise ValueError('Source frame is not binary alpha')
    # Refuse to create anything until source content, frame geometry and polygons pass.
    ids,counts,fallback=classify_pixels(frame)
    source_pixels=sum(a>0 for a in frame.getchannel('A').tobytes())
    if source_pixels!=sum(counts.values()):
        raise ValueError('Partition is not exhaustive')
    parts=[]
    for i,(name,parent,order,movable,poly) in enumerate(PARTS):
        layer=Image.new('RGBA',(W,H),(0,0,0,0))
        for y in range(H):
            for x in range(W):
                if ids[y][x]==i:
                    layer.putpixel((x,y),frame.getpixel((x,y)))
        parts.append((name,layer))
    # Exact pixel-level compositing must be identical, including transparent RGB.
    reconstructed=Image.new('RGBA',(W,H),(0,0,0,0))
    for _,layer in parts:
        reconstructed.alpha_composite(layer)
    if reconstructed.tobytes()!=frame.tobytes():
        raise ValueError('Neutral reconstruction not byte-identical: overlapping or missing source pixels')
    out.mkdir(parents=True,exist_ok=True)
    for sub in ('parts','preview'):(out/sub).mkdir(exist_ok=True)
    input_copy=out/'source_south_visible_frame.png';frame.save(input_copy)
    reconstructed.save(out/'reassembled_exact.png')
    rig_parts=[]
    for name,img in parts:
        dest=out/'parts'/f'{name}.png'
        img.save(dest,optimize=False,compress_level=9)
        idx=next(i for i,p in enumerate(PARTS) if p[0]==name)
        _,parent,order,movable,polygon=PARTS[idx]
        # MF1's source paths are relative to --source-root (the output's /parts).
        rig_parts.append({'id':name,'source':dest.name,'sha256':sha(dest.read_bytes()),
                          'pivot':list(PIVOTS[name]),'parent':parent,'draw_order':order,'movable':movable})
    rig={'schema':'custodian.motion_foundry.rig.v1','rig_id':'operator_south_visible_surface_v1',
         'owner':'operator','art_generation':'operator_2_5d_128','direction':'s',
         'frame_size':[W,H],'root':ROOT,'ground':GROUND,
         'reference_profile_sha256':PROFILE_SHA256,'parts':rig_parts}
    (out/'rig.json').write_text(json.dumps(rig,indent=2)+'\n')
    # The sample timeline is deliberately static. We must not call moving uncovered
    # seams or hidden anatomy correct without explicit art remediation.
    motion={'schema':'custodian.motion_foundry.motion.v1','motion_id':'visible_surface_rest_pose_v1',
            'rig_id':rig['rig_id'],'profile':'unarmed','group':'posture','action':'idle_relaxed_01',
            'direction':'s','frame_count':15,'fps':None,'loop':True,
            'interpolation':'linear_integer_half_away_from_zero','tracks':[
                {'part':name,'keys':[{'frame':0,'offset':[0,0]},{'frame':14,'offset':[0,0]}]}
                for name,_ in parts], 'contacts':[]}
    (out/'motion_static_proof.json').write_text(json.dumps(motion,indent=2)+'\n')
    write_aseprite(parts,out/'operator_south_segmented_source.aseprite')
    proof,names=read_layered_aseprite((out/'operator_south_segmented_source.aseprite').read_bytes())
    if proof[0].tobytes()!=frame.tobytes() or names!=[name for name,_ in parts]:
        raise ValueError('Native layered Aseprite export did not roundtrip pixel-identically')
    seams=inspect_seams(ids)
    # Forensic pixel ledger: every visible source pixel, unchanged RGBA, with
    # semantic owner ID and classification method, suitable for paintover review.
    owner_masks=[polygon_mask(p[-1]) if p[0] not in HIDDEN_PLACEHOLDERS else Image.new('1',(W,H),0) for p in PARTS]
    seam_mask=Image.new('RGBA',(W,H))
    seam_count=0
    with (out/'pixel_ownership.csv').open('w',newline='',encoding='utf-8') as f:
        writer=csv.writer(f)
        writer.writerow(('x','y','r','g','b','a','part_id','assignment_method','touches_cross_part_seam'))
        for y in range(H):
            for x in range(W):
                rgba=frame.getpixel((x,y))
                if rgba[3]:
                    i=ids[y][x]
                    method='polygon' if any(mask.getpixel((x,y)) for mask in owner_masks) else 'nearest_fallback'
                    boundary=touching_seam(ids,x,y)
                    seam_count+=int(boundary)
                    if boundary:seam_mask.putpixel((x,y),(255,70,182,255))
                    writer.writerow((x,y,*rgba,PARTS[i][0],method,int(boundary)))
    seam_mask.save(out/'preview/seam_review_mask_128.png')
    part_bboxes={name:list(im.getchannel('A').getbbox() or []) for name,im in parts}
    hierarchy=[{'part':name,'parent':parent,'pivot_estimate':list(PIVOTS[name]),
                'draw_order':order,'movable':movable,'visible_pixel_count':counts[name],
                'visible_bbox_exclusive':part_bboxes[name],
                'is_intentionally_blank_placeholder':name in HIDDEN_PLACEHOLDERS,
                'is_complete_anatomical_geometry':False,
                'readiness':'visible_surface_only_hidden_underpaint_missing'}
               for name,parent,order,movable,_ in PARTS]
    (out/'hierarchy_and_overlap.json').write_text(json.dumps({
        'schema':'custodian.operator_motion_foundry.visible_layer_topology.v1',
        'hierarchy':hierarchy,'hypothetical_front_behind':OVERLAP,
        'measured_touching_seams':seams,
        'notes':['Every visible original pixel has exactly one owner.',
                 'Folds under frontal cloth are impossible to recover from one flattened view.',
                 'Do not rotate parts without manually authoring underlap/connection pixels.']
    },indent=2)+'\n')
    a=frame.getchannel('A').getbbox()
    metadata={'schema':'custodian.operator_motion_foundry.visible_surface_partition.v1',
              'status':'candidate_not_approved',
              'source_path':source.name,'source_sha256':source_sha,
              'source_animation_frame_index_zero_based':SOURCE_FRAME_INDEX,
              'source_frame_duration_ms':100,
              'source_direction_order':['n','ne','e','se','s','sw','w','nw'],
              'direction':'s','frame_size':[W,H],'visible_alpha_bbox_exclusive':list(a),
              'root':ROOT,'ground':GROUND,'visible_pixel_count':source_pixels,
              'fallback_nearest_assigned_pixels':fallback,
              'cross_part_seam_review_pixels':seam_count,
              'blank_occluded_rig_parts':sorted(HIDDEN_PLACEHOLDERS),
              'part_visible_pixel_counts':counts,'seam_adjacencies':seams,
              'overlap_hypotheses':OVERLAP,
              'partition_rule':'exactly one semantic owner per nontransparent original pixel',
              'source_pixel_modified':False,'original_pixel_reassembly_exact':True,
              'aseprite_layered_file_roundtrip_exact':True,
              'occluded_pixels_known':False,'hidden_geometry_reconstructed':False,
              'warnings':['Flat art cannot reveal pixels hidden under cape, belts, overlapping tabs, shoulders or hands',
                          'Five intentionally blank joint/behind-cloth placeholders are NOT extracted art',
                          'Visible folds are classified by annotated boundaries; confidence must be artist-reviewed',
                          'Pivots/parents are estimates only; MF1 does not rotate or deform joints',
                          'Original root at 64,106 is below visible silhouette bottom; do not align to alpha bbox',
                          'Static proof motion is not a true animated idle or approved animation.']}
    (out/'segmentation_manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
    colorize_map(frame,ids,out/'preview/segmentation_comparison.png')
    # Every export is 128x128 original-coordinate PNG. This *preview only*
    # zooms each visible bbox so partial geometry remains legible.
    cell=205;columns=4;rows=(len(parts)+columns-1)//columns
    contact=Image.new('RGB',(columns*cell,rows*cell),(38,41,47))
    d=ImageDraw.Draw(contact)
    for i,(name,img) in enumerate(parts):
        x=(i%columns)*cell;y=(i//columns)*cell
        bbox=img.getchannel('A').getbbox()
        if bbox:
            cx=(bbox[0]+bbox[2])//2;cy=(bbox[1]+bbox[3])//2
            half=19
            x0=max(0,min(W-2*half,cx-half));y0=max(0,min(H-2*half,cy-half))
            crop=img.crop((x0,y0,x0+2*half,y0+2*half))
            under=Image.new('RGBA',crop.size,(57,61,68,255));under.alpha_composite(crop)
            contact.paste(under.convert('RGB').resize((152,152),Image.Resampling.NEAREST),(x+26,y+7))
        label=name.replace('_screen_', '_').replace('arm_', 'arm_')
        d.text((x+5,y+164),label,fill=(235,235,238))
        d.text((x+5,y+179),f'{counts[name]} visible pixels, crop preview',fill=(190,192,198))
    contact.save(out/'preview/parts_contact_sheet.png')
    # Record the script itself as the re-runnable method only through bundled path.
    return metadata


def main() -> int:
    pa=argparse.ArgumentParser(description=__doc__)
    pa.add_argument('--source',type=Path,required=True)
    pa.add_argument('--out',type=Path,required=True)
    pa.add_argument('--allow-unpinned-source',action='store_true',help='Unsafe analysis-only mode; never use for production authority')
    args=pa.parse_args()
    summary=write_outputs(args.source,args.out,strict_hash=not args.allow_unpinned_source)
    print(json.dumps({key:summary[key] for key in ('status','source_sha256','visible_pixel_count','fallback_nearest_assigned_pixels','original_pixel_reassembly_exact','aseprite_layered_file_roundtrip_exact')},indent=2))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
