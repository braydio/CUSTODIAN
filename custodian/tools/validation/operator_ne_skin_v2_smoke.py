#!/usr/bin/env python3
"""Focused deterministic Skin V2 art-authoring negatives; no game or Aseprite required."""
import importlib.util
from pathlib import Path
import sys
import numpy as np

MODULE = Path(__file__).resolve().parents[1] / 'operator/ne_walk_retarget/skin_v2/apron_authority.py'
spec = importlib.util.spec_from_file_location('skin_v2_apron_authority', MODULE)
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
spec.loader.exec_module(m)


def fake_rig():
    rig = {}
    full = np.zeros((128,128,4),dtype=np.uint8)
    # Neutral parts have non-overlapping squares; source colors unique.
    for i,name in enumerate(m.ORDER):
        cel = np.zeros_like(full)
        x=35+(i%4)*12
        y=72+(i//4)*10
        cel[y:y+8,x:x+9] = (40+i*8,72+i*5,91+i*6,255)
        rig['__RIG_PART_'+name]=cel
        full[cel[:,:,3]>0]=cel[cel[:,:,3]>0]
    full[30:59,56:73]=(40,48,62,255)
    rig[m.FULL]=full
    return rig


def fake_pose(frame):
    return {'frame':frame,'translation':[0,0],
            'posed':{'near':{'hip':[63,75],'knee':[65,89], 'ankle':[70 if frame==12 else 66,100], 'toe':[75,104]},
                     'far':{'hip':[53,75],'knee':[52,83], 'ankle':[50,88], 'toe':[48,91]}}}


def identity_warp(src,*args):
    return src.copy()


def neutral_shear(src,*args):
    return src.copy()


def expect_raises(fn, label):
    try:
        fn()
    except (ValueError,FileExistsError):
        return
    raise AssertionError('negative control did not fail closed: '+label)


def main():
    rig=fake_rig()
    rest,report,labels=m.audit_neutral(rig)
    assert report['neutral_reassembly_changed_pixels']==0
    assert report['dynamic_owned_pixels']==sum(np.count_nonzero(x[:,:,3]) for k,x in rig.items() if k.startswith('__RIG_PART_'))
    assert report['static_residual_pixels']>0 and not report['upper_body_articulation_authorized']
    assert np.count_nonzero(labels==1)>0
    sourcepalette=m.palette(rig[m.FULL])
    base,baseowner,_=m.compose_frame(rig,rest,fake_pose(1),identity_warp,neutral_shear)
    assert np.array_equal(base,rig[m.FULL])
    for frame in (5,7,12):
        image,owner,record=m.compose_frame(rig,rest,fake_pose(frame),identity_warp,neutral_shear)
        assert record['variant']==('near_open' if frame==12 else 'far_cross')
        assert not np.array_equal(image,base),'different apron configuration must change pixels'
        assert m.palette(image).issubset(sourcepalette)
        assert set(np.unique(image[:,:,3])).issubset({0,255})
        gaps,overlay=m.art_gap_report(base,image,baseowner,owner)
        assert overlay.shape==base.shape and 'newly_transparent_apron_region_pixels' in gaps
        assert np.array_equal(image,m.compose_frame(rig,rest,fake_pose(frame),identity_warp,neutral_shear)[0])
    # Missing layer, mixed original palette, overlapping owner, alpha corruption,
    # failed waist protection, and rejected unsupported design choice.
    bad=dict(rig);bad.pop('__RIG_PART_foot_far_visible')
    expect_raises(lambda:m.audit_neutral(bad),'missing anatomical owner')
    bad={k:v.copy() for k,v in rig.items()}
    bad['__RIG_PART_robe_near'][80,70]=(255,0,0,255)
    expect_raises(lambda:m.audit_neutral(bad),'unsourced inserted pixel')
    bad={k:v.copy() for k,v in rig.items()}
    bad['__RIG_PART_robe_near'][:]=bad['__RIG_PART_robe_far']
    expect_raises(lambda:m.audit_neutral(bad),'overlap owners')
    bad={k:v.copy() for k,v in rig.items()}
    bad[m.FULL][35,65,3]=90
    expect_raises(lambda:m.audit_neutral(bad),'nonbinary source alpha')
    expect_raises(lambda:m.aperture_warp(rig['__RIG_PART_robe_near'],'robe_near','invented'),'bad variant')
    print('PASS Skin V2: neutral 0-pixel delta; deterministic 3 garment variants; source palette, alpha, ownership, gaps; 5 negative controls')


if __name__=='__main__':
    main()
