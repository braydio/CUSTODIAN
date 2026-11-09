#!/usr/bin/env python3
"""Self-contained synthetic damage regression for the authored cleanup.

This does not certify actual Iteration 004 pose/contact quality. It tests only
source locks, deterministic raster provenance and repair of intentionally
removed pixels within the copied apron/leg region.
"""
from __future__ import annotations
import hashlib
import json
import sys
import tempfile
from pathlib import Path
import numpy as np
from PIL import Image
import clean_silhouette_r1 as impl


def main() -> int:
    root=Path(__file__).resolve().parents[3] / 'asset_drop/source_work/operator/operator_ne_walk_cleanup_r1'
    alt=root/'alternate_walk_15f_source.png'
    idle=root/'idle_lock_15f_source.png'
    style=root/'single_frame_style_source.png'
    a=np.array(Image.open(alt).convert('RGBA'))
    damaged=a.copy()
    original_opaque=int(np.count_nonzero(a[:,:,3]))
    for i in range(15):
        f=damaged[:,i*128:(i+1)*128,:]
        for y in range(78,110):
            for x in range(48,96):
                if (x*13+y*29+i*17)%37==0 and f[y,x,3]:
                    f[y,x]=0
    with tempfile.TemporaryDirectory() as temp:
        base=Path(temp)
        active=base/'active_synthetic_damage.png'
        Image.fromarray(damaged,'RGBA').save(active)
        report=base/'synthetic_report.json'
        report.write_text(json.dumps({'schema':'custodian.ne_walk_preview.v1',
          'frames':[{'frame':i+1,'support':'near' if i<6 or i>=13 else 'far'} for i in range(15)],
          'input_validation':{'source_hash':impl.SHA_DONOR}}))
        impl.SHA_REPORT=hashlib.sha256(report.read_bytes()).hexdigest()
        # A correct report digest must NOT override a wrong embedded donor hash.
        # Exercise the production donor guard explicitly, without creating output.
        bad_report=base/'wrong_donor_report.json'
        wrong=json.loads(report.read_text())
        wrong['input_validation']['source_hash']='0'*64
        bad_report.write_text(json.dumps(wrong))
        correct_report_sha=impl.SHA_REPORT
        impl.SHA_REPORT=hashlib.sha256(bad_report.read_bytes()).hexdigest()
        import contextlib, io
        bad_args=['smoke','--active',str(active),'--alternate',str(alt),
          '--style',str(style),'--idle',str(idle),'--report',str(bad_report),
          '--output-dir',str(base/'must_not_exist'),
          '--allow-active-sha',hashlib.sha256(active.read_bytes()).hexdigest()]
        original_argv=sys.argv[:]
        try:
            sys.argv=bad_args
            with contextlib.redirect_stderr(io.StringIO()):
                try:impl.main()
                except SystemExit as exc:assert exc.code==2
                else:raise AssertionError('wrong Knight donor was accepted')
            assert not (base/'must_not_exist').exists()
        finally:
            sys.argv=original_argv
            impl.SHA_REPORT=correct_report_sha
        args=['smoke','--active',str(active),'--alternate',str(alt),'--style',str(style),
          '--idle',str(idle),'--report',str(report),'--output-dir',str(base/'out'),
          '--allow-active-sha',hashlib.sha256(active.read_bytes()).hexdigest()]
        prev=sys.argv[:];sys.argv=args
        try:
            assert impl.main()==0
        finally:sys.argv=prev
        candidate=np.array(Image.open(base/'out/operator_ne_walk_cleanup_candidate_15f_1920x128.png'))
        assert candidate.shape==(128,1920,4)
        report_out=json.loads((base/'out/CLEANUP_REPORT.json').read_text())
        assert len(report_out['frames'])==15
        assert all(p['new_rgba_colors_invented'] is False for p in report_out['frames'])
        assert all(p['upper_locked_pixels_changed']==0 for p in report_out['frames'])
        # All synthetic damage was below the authored join and so should be
        # exactly repaired from the clean alternate pixels.
        assert np.array_equal(candidate,a), 'synthetic silhouette repair mismatch'
        assert int(np.count_nonzero(candidate[:,:,3]))==original_opaque
        assert not (base/'out').joinpath('RENDERED_RUNTIME_ASSET.png').exists()
        print(json.dumps({'smoke':'PASS','frames':15,'synthetic_reconstruction_exact':True,
              'changed_pixels':sum(v['changed_rgba_pixels'] for v in report_out['frames'])}))
    return 0

if __name__=='__main__':raise SystemExit(main())
