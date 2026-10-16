#!/usr/bin/env python3
"""Reproducible disposable recovery bound to the human-selected SINGLE_FRAME."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import subprocess
from PIL import Image
from master_audit import HERE, SOURCE, PART, HIDDEN, export, pixels, sha, write

SELECTED_SHA='0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149'


def verify_recovery(before,after,neutral,probes):
    old,old_layers,_=before;new,new_layers,_=after
    assert new['structural_gate_passed'],new['blocking_findings']
    assert pixels(old_layers[SOURCE])==pixels(new_layers[SOURCE]),'locked source changed'
    assert pixels(old_layers[SOURCE])==pixels(neutral),'rendered neutral changed'
    assert sum(bool(c[3]) for c in pixels(neutral))==2191
    for name,image in old_layers.items():
        mutable=(name in (PART+'thigh_far_visible',PART+'shin_far_visible',PART+'foot_far_visible',
                          HIDDEN+'shin_far_completion',HIDDEN+'foot_far_completion','__RIG_PIVOTS'))
        if not mutable:assert pixels(image)==pixels(new_layers[name]),'unrelated layer changed: '+name
    source_colors={c for c in pixels(old_layers[SOURCE]) if c[3]}
    for name,image in new_layers.items():
        if name.startswith((PART,HIDDEN)):
            assert {c for c in pixels(image) if c[3]}<=source_colors,'new palette color'
    for side in ('near','far'):
        assert new['metrics'][side]['shin_len']>0 and new['metrics'][side]['thigh_len']>0
    assert len(probes)==6
    assert all(p['contact']['pass'] and not p['target_clamped'] and p['shin_length_error']<1e-8 and p['thigh_length_error']<1e-8 for p in probes)
    assert new['visible_partition']['exact']


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--original',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--v55',type=Path,default=Path.home()/'.config/aseprite/scripts/operator_ne_pose_builder_v0_5_5_swing_stride_control.lua')
    p.add_argument('--aseprite',default='aseprite')
    a=p.parse_args();a.output=a.output.resolve();a.original=a.original.resolve()
    assert sha(a.original)==SELECTED_SHA,'not the human-selected original'
    assert not a.output.exists(),'fresh output directory required'
    assert not a.output.is_relative_to(HERE.parents[3]/'custodian'),'local recovery output only'
    assert sha(a.v55)==json.loads((HERE/'v55_dependency.json').read_text())['sha256'],'V5.5 drift'
    a.output.mkdir(parents=True)
    core=a.v55.read_text().split('-- UI\n-- ============================================================================')[0]
    start=core.index('local KNIGHT_F1_EMBEDDED =');end=core.index('local function clamp(v,lo,hi)',start)
    core=core[:start]+core[end:]
    before=export(a.aseprite,a.original,a.output/'original_audit',core)
    script=a.output/'recover_generated.lua';script.write_text(core+'\n'+(HERE/'recover_far_leg.lua').read_text())
    command=[a.aseprite,'-b',str(a.original),'--script-param','recovery_config='+json.dumps({'output':str(a.output)}),'--script',str(script)]
    result=subprocess.run(command,capture_output=True,text=True,timeout=60)
    (a.output/'aseprite.log').write_text(result.stdout+result.stderr)
    assert sha(a.original)==SELECTED_SHA,'original changed'
    report_file=a.output/'recovery_report.json'
    if result.returncode or not report_file.exists():raise RuntimeError(result.stdout+result.stderr)
    r=json.loads(report_file.read_text())
    candidate=a.output/'operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite'
    after=export(a.aseprite,candidate,a.output/'candidate_audit',core)
    verify_recovery(before,after,Image.open(a.output/'neutral_reconstructed.png').convert('RGBA'),r['contact_probes'])
    r.update(original_sha256=SELECTED_SHA,candidate_sha256=sha(candidate),command=command,
             structural_articulation_contact_passed=True,human_visual_acceptance=False,
             original_source_pixels=2191,neutral_identity_exact=True,solver_sha256=sha(HERE/'batch.lua'))
    write(report_file,r)
    print(json.dumps({'candidate':str(candidate),'technical_checks_passed':True,'human_visual_acceptance':False}))

if __name__=='__main__':main()
