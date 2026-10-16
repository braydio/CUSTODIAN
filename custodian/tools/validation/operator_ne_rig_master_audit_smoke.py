#!/usr/bin/env python3
"""Portable regressions for empty-shin misclassification and source ownership."""
from __future__ import annotations
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
TOOLS=ROOT/'custodian/tools/operator/ne_walk_retarget'
spec=importlib.util.spec_from_file_location('ne_master_audit',TOOLS/'master_audit.py')
audit=importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)
sys.path.insert(0,str(TOOLS))
import recover


def fixture(root,regressed=False,duplicate=False,recolor=False,missing_foot=False):
    root.mkdir()
    source=Image.new('RGBA',(128,128));layers={}
    for side,x in [('near',62),('far',47)]:
        shin=Image.new('RGBA',(128,128));foot=Image.new('RGBA',(128,128))
        for y in range(84,94):
            for xx in range(x,x+3):shin.putpixel((xx,y),(80,70,50,255));source.putpixel((xx,y),(80,70,50,255))
        if not missing_foot or side!='far':
            for y in range(94,101):
                for xx in range(x,x+8):foot.putpixel((xx,y),(30,25,20,255));source.putpixel((xx,y),(30,25,20,255))
        layers[audit.PART+'shin_'+side+'_visible']=shin
        layers[audit.PART+'foot_'+side+'_visible']=foot
        layers[audit.HIDDEN+'shin_'+side+'_completion']=Image.new('RGBA',(128,128))
    if regressed:
        layers[audit.PART+'foot_far_visible'].alpha_composite(layers[audit.PART+'shin_far_visible'])
        layers[audit.PART+'shin_far_visible']=Image.new('RGBA',(128,128))
    if duplicate:layers[audit.PART+'duplicate']=layers[audit.PART+'shin_near_visible'].copy()
    if recolor:layers[audit.PART+'shin_near_visible'].putpixel((62,84),(90,70,50,255))
    # A source-preservation fixture with the selected master's 2191-pixel count.
    body=Image.new('RGBA',(128,128));remaining=2191-sum(bool(p[3]) for p in audit.pixels(source))
    for y in range(128):
        for x in range(128):
            if remaining and not source.getpixel((x,y))[3]:
                source.putpixel((x,y),(60,50,40,255));body.putpixel((x,y),(60,50,40,255));remaining-=1
    layers[audit.PART+'torso_locked']=body
    layers[audit.SOURCE]=source
    layers['__RIG_UNCLASSIFIED_VISIBLE']=Image.new('RGBA',(128,128))
    report={'layers':{},'pivots':{str(i):{'x':i,'y':0} for i in range(18)},'metrics':{},'feet':{}}
    for side,x in [('near',62),('far',47)]:
        report['metrics'][side]={'hip':{'x':x,'y':74},'knee':{'x':x,'y':86},'ankle':{'x':x,'y':96},'toe':{'x':x+5,'y':99},'thigh_len':12,'shin_len':10}
        report['feet'][side]={'valid':not(missing_foot and side=='far'), 'bbox':{'minx':x,'maxx':x+7,'miny':94,'maxy':100}}
    for name,image in layers.items():
        filename=name+'.png';image.save(root/filename)
        report['layers'][name]={'file':filename,'count':sum(bool(p[3]) for p in audit.pixels(image))}
    audit.write(root/'export.json',report)
    return audit.inspect_export(root)


def main():
    with tempfile.TemporaryDirectory() as td:
        root=Path(td)
        good=fixture(root/'good');assert good[0]['structural_gate_passed']
        # Even all structural checks passing never grants art acceptance.
        assert not good[0]['anatomy_accepted'] and not good[0]['ready_for_v6']
        candidate=fixture(root/'candidate')
        probes=[{'contact':{'pass':True},'target_clamped':False,'shin_length_error':0,'thigh_length_error':0} for _ in range(6)]
        recover.verify_recovery(good,candidate,good[1][audit.SOURCE],probes)
        damaged=fixture(root/'damaged')
        damaged[1][audit.PART+'foot_near_visible'].putpixel((62,94),(1,2,3,255))
        try:recover.verify_recovery(good,damaged,good[1][audit.SOURCE],probes)
        except AssertionError:pass
        else:raise AssertionError('near-leg mutation must fail')
        modified_source=fixture(root/'modified_source')
        modified_source[1][audit.SOURCE].putpixel((0,0),(7,8,9,255))
        try:recover.verify_recovery(good,modified_source,good[1][audit.SOURCE],probes)
        except AssertionError:pass
        else:raise AssertionError('locked source mutation must fail')
        bad=fixture(root/'regressed',regressed=True)
        assert bad[0]['visible_partition']['exact'],'old structural tests would pass'
        assert 'far_shin_has_no_art' in bad[0]['blocking_findings']
        comp=audit.compare(good,bad)
        assert comp['source_difference_count']==0
        assert comp['recovered_far_foot_previous_owners'][audit.PART+'shin_far_visible']==30
        assert not fixture(root/'duplicate',duplicate=True)[0]['visible_partition']['exact']
        assert not fixture(root/'recolor',recolor=True)[0]['visible_partition']['exact']
        assert 'far_foot_geometry_missing_or_invalid' in fixture(root/'missing',missing_foot=True)[0]['blocking_findings']
        info=json.loads((root/'good/export.json').read_text())
        info['metrics']['far']['shin_len']=3.606
        info['metrics']['far']['toe']={'x':45,'y':120}
        audit.write(root/'good/export.json',info)
        findings=audit.inspect_export(root/'good')[0]['blocking_findings']
        assert 'far_short_shin_requires_anatomy_review' in findings and 'far_toe_outside_boot_envelope' in findings
    print('PASS operator_ne_rig_master_audit: ownership, recolor, missing boot, empty shin, short chain, toe envelope; no automatic acceptance')

if __name__=='__main__':main()
