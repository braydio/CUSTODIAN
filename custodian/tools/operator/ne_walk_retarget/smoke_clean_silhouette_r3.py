#!/usr/bin/env python3
"""R3 final-composite topology regression, no runtime art or Aseprite calls."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import tempfile
from pathlib import Path
import numpy as np
from PIL import Image
import clean_silhouette_r2 as r2
import clean_silhouette_r3 as r3

HERE=Path(__file__).resolve().parent
BOOT=(26,23,27,255)
GOLD=(194,116,25,255)


def sample_frame():
    source=np.zeros((128,128,4),dtype=np.uint8)
    source[38:91,60:65]=BOOT
    source[95,62]=GOLD
    return source


def sample_motion(contact=95):
    parts={}
    for side in ('near','far'):
        hip,knee,ankle,toe=([(62,72),(62,83),(62,90),(62,96)] if side=='near'
                          else [(52,74),(51,83),(51,89),(51,93)])
        parts[side]={k:{'x':p[0],'y':p[1]} for k,p in zip(('hip','knee','ankle','toe'),(hip,knee,ankle,toe))}
        parts[side]['rendered_boot_contact']={'x':62 if side=='near' else 51,'y':contact if side=='near' else 93,
               'minx':62 if side=='near' else 51,'maxx':62 if side=='near' else 51,'count':1}
    return {'frame':7,'support':'near','legs':parts}


def fixtures():
    img=np.zeros((128,128,4),dtype=np.uint8)
    img[85:96,60:65]=BOOT
    owner={'near':{'foot':img,'shin':img},'far':{'foot':img,'shin':img}}
    return owner


def must_fail(fn,text):
    try:fn()
    except ValueError as e:
        assert text in str(e),f'expected {text}, got {e}'
    else:raise AssertionError('negative control failed to reject: '+text)


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--original-rig-fixture',type=Path,required=True)
    ap.add_argument('--style-fixture',type=Path,required=True)
    ap.add_argument('--alternate-fixture',type=Path,required=True)
    a=ap.parse_args()
    # Established R2 fixture and exact source hashes are reusable and read-only.
    assert r2.sha(a.style_fixture)==r2.STYLE_SHA
    assert r2.sha(a.alternate_fixture)==r2.ALTERNATE_SHA
    parts=r2.parse_aseprite_rig(a.original_rig_fixture,enforce_sha=False,synthetic_missing_far=True)
    assert int(np.count_nonzero(parts['__RIG_PART_foot_near_visible'][:,:,3]))>80
    active=sample_frame()
    damaged=active.copy();damaged[91:95,62]=0
    owner=fixtures();motion=sample_motion()
    out,record=r3.connect_support_sole(active,damaged,owner,motion)
    assert record['support_connected_before']==False
    assert record['support_connected_after'] and record['new_bridge_pixels']==4
    assert len(r3.components(out[:,:,3]>0))==1
    assert np.array_equal(out[95,62],active[95,62]);assert np.array_equal(out[:68],active[:68])
    assert not record['lower_orphan_components']
    assert all(tuple(out[y,x]) in {tuple(BOOT),tuple(GOLD)} for x,y in record['new_bridge_coordinates'])
    # The only allowed source of new bridge colors is the semantic boot layer.
    assert record['final_distal_orphan_count']==0
    # Source sole tamper and overly distant orphan must stop before output.
    tampered=damaged.copy();tampered[95,62]=BOOT
    must_fail(lambda:r3.connect_support_sole(active,tampered,owner,motion),'sole changed')
    distant=damaged.copy();distant[90,60:65]=0;distant[80:90,60:65]=0
    must_fail(lambda:r3.connect_support_sole(active,distant,owner,motion),'no body-connected')
    # Novel floating foot fragment not touching the support sole is a genuine
    # post-composite issue; it is NOT cleared by R2's per-part join distances.
    isolated=out.copy();isolated[95,70]=GOLD
    orphan=r3.inspect_orphans(isolated,active,motion)
    assert len(orphan)==1 and orphan[0]['distal_leg_risk']
    assert orphan[0]['changed_rgba_pixels']==1
    # Targeted bridge for a newly created small distal boot island, not a lone
    # untouched baseline shadow.
    fixed,fixes=r3.repair_distal_islands(isolated.copy(),active,owner,motion)
    assert len(fixes)==1 and fixes[0]['owner']=='near'
    assert len(r3.components(fixed[:,:,3]>0))==1
    # No screen-left/right heuristic, no resetting source art or joints.
    assert r3.path_8(62,90,62,95)==[(62,y) for y in range(90,96)]
    # Full 15-frame synthetic preview with moving target landmarks (up to 8px)
    # and original support changes. It is NOT a substitute for a real rig render.
    sty=np.asarray(Image.open(a.style_fixture).convert('RGBA'))
    frames=[]
    for i in range(15):
        step=8*math.sin(2*math.pi*i/15)
        f={'frame':i+1,'support':'near' if i<6 or i>12 else 'far','legs':{}}
        for side in ('near','far'):
            shift=step if side=='near' else -step/8
            f['legs'][side]={k:{'x':float(p[0]+shift*(0 if k=='hip' else .2 if k=='knee' else 1)),
                                'y':float(p[1])} for k,p in r2.NEUTRAL[side].items()}
            f['legs'][side]['rendered_boot_contact']=(
                {'x':64,'y':105,'minx':63,'maxx':65,'count':3} if side=='near' else
                {'x':49,'y':91,'minx':49,'maxx':49,'count':1})
        frames.append(f)
    with tempfile.TemporaryDirectory() as d:
        dest=Path(d)/'generated'
        generated=r3.evaluate(np.concatenate([sty]*15,axis=1),parts,{'frames':frames},dest)
        assert generated['output']['frames']==15
        assert generated['status']=='REVIEW_ONLY' and not generated['animation_approved']
        assert all(z['support_connected_after'] and z['final_distal_orphan_count']==0 for z in generated['frames'])
        assert (dest/'REVIEW_PIXELS.json').is_file()
        assert (dest/'R3_R2_BEFORE_AFTER_15_POSES.png').is_file()
        assert (dest/'R3_BOOT_SOLE_CLOSEUPS_10_POSES.png').is_file()
        assert len(generated['frames'])==15
    print('PASS R3: 15 synthetic moving frames with support handoff + boot bridge negative controls; actual accepted rig remains pending')

if __name__=='__main__':main()
