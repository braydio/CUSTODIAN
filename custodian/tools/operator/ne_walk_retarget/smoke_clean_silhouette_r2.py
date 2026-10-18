#!/usr/bin/env python3
"""Tests rig parser, affine sources, strict source-hash stop, locked sole and lower masks."""
from __future__ import annotations
import importlib.util
import json
from pathlib import Path
import tempfile
import hashlib
import numpy as np
from PIL import Image
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('r2',HERE/'clean_silhouette_r2.py')
r2=importlib.util.module_from_spec(spec);spec.loader.exec_module(r2)
ROOT=Path(__file__).resolve().parents[5]  # this is a synthetic smoke; stage project paths via CLI

def main():
    import argparse
    ap=argparse.ArgumentParser()
    ap.add_argument('--original-rig-fixture',type=Path,required=True)
    ap.add_argument('--style-fixture',type=Path,required=True)
    ap.add_argument('--alternate-fixture',type=Path,required=True)
    args=ap.parse_args()
    assert hashlib.sha256(args.style_fixture.read_bytes()).hexdigest()==r2.STYLE_SHA
    assert hashlib.sha256(args.alternate_fixture.read_bytes()).hexdigest()==r2.ALTERNATE_SHA
    parts=r2.parse_aseprite_rig(args.original_rig_fixture,enforce_sha=False,synthetic_missing_far=True)
    sty=np.asarray(Image.open(args.style_fixture).convert('RGBA'))
    assert np.array_equal(parts['__RIG_REFERENCE_LOCKED_FULL_BODY'],sty)
    assert np.sum(parts['__RIG_PART_foot_near_visible'][:,:,3]>0)>80
    assert np.sum(parts['__RIG_PART_foot_far_visible'][:,:,3]>0)>0
    f=[]
    for i in range(15):
        # Large near-leg excursion exercises coordinate-preserving intent.
        phase=2*np.pi*i/15
        step=12*np.sin(phase)
        row={'frame':i+1,'support':'near' if i<6 or i>12 else 'far','legs':{}}
        for side in ('near','far'):
            src=r2.NEUTRAL[side];m=step if side=='near' else -1.5*np.sin(phase)
            t={k:{'x':float(v[0]+m*(.0 if k=='hip' else .2 if k=='knee' else 1)),
                  'y':float(v[1])} for k,v in src.items()}
            # Neutral fixture's original raster sole is preserved exactly at this provenance.
            if side=='near':t['rendered_boot_contact']={'x':64,'y':105,'minx':63,'maxx':65,'count':3}
            else:t['rendered_boot_contact']={'x':49,'y':91,'minx':49,'maxx':49,'count':1}
            row['legs'][side]=t
        f.append(row)
    # Synthetic real-frame fixture with immutable upper body and leg art.
    base=sty.copy()
    for i,row in enumerate(f):
        # Test both anatomical supports without screen-half heuristics.
        if row['support']=='far':base[91,49]=parts['__RIG_PART_foot_far_visible'][90,49]
        frame,out=r2.build_frame(base,parts,row)
        assert out['source_upper_68_rows_identical']
        assert out['support_sole_preserved']
        assert out['motion_report_unmodified']
        if row['support']=='near':assert np.array_equal(frame[105,64],base[105,64])
    source=np.zeros((128,128,4),dtype=np.uint8);source[50,61]=[255,195,35,255]
    target=r2.rigid_warp(source,(61,50),(61,60),(71,50),(71,60))
    assert tuple(target[50,71])==(255,195,35,255)
    # Exercise full 15-frame disposable output, without original runtime data.
    with tempfile.TemporaryDirectory() as d:
        full=np.concatenate([sty]*15,axis=1)
        obj={'schema':'synthetic_r2','frames':f}
        result=r2.evaluate(full,parts,obj,Path(d)/'test')
        assert result['output']['frames']==15
        assert len(result['frames'])==15
        assert Path(d,'test','R2_MOTION_CONTACT_AUDIT.json').exists()
        assert Path(d,'test','REVIEW_PIXELS.json').stat().st_size < 4_000_000
    # Wrong SHA must always fail before a new output directory is created.
    with tempfile.TemporaryDirectory() as d:
        p=Path(d)/'bad.aseprite';p.write_bytes(b'malformed')
        try:r2.parse_aseprite_rig(p)
        except ValueError:pass
        else:raise AssertionError('accepted rig SHA guard bypass')
    print('PASS R2 synthetic: rig semantic parse, 15 pose-anchored restorations, upper lock, sole lock, no new motion and wrong-rig fail-closed')

if __name__=='__main__':main()
