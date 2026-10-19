#!/usr/bin/env python3
"""Idempotent focused validation ownership for authored Skin V2 files."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[5]
MANIFEST=ROOT/'custodian/tools/validation/validation_manifest.json'
ID='operator_ne_skin_v2_apron'
OWNERS=[
  'custodian/tools/operator/ne_walk_retarget/skin_v2/apron_authority.py',
  'custodian/tools/operator/ne_walk_retarget/skin_v2/run.py',
  'custodian/tools/operator/ne_walk_retarget/skin_v2/run_skin_v2.sh',
  'custodian/tools/operator/ne_walk_retarget/skin_v2/register_validation.py',
  'custodian/tools/operator/ne_walk_retarget/skin_v2/SKIN_V2_PACKAGE_MANIFEST.json',
  'custodian/tools/validation/operator_ne_skin_v2_smoke.py',
]


def main():
    data=json.loads(MANIFEST.read_text(encoding='utf8'))
    existing=[t for t in data['tests'] if t.get('id')==ID]
    if len(existing)>1:raise ValueError('duplicate test authority')
    entry={'id':ID,'type':'python',
           'script':'custodian/tools/validation/operator_ne_skin_v2_smoke.py',
           'tier':'unit','tags':['operator','art_authoring','skin_v2','source_palette'],
           'owners':OWNERS,'timeout_sec':30,'needs_import':False}
    if existing:
        if existing[0]!=entry:raise ValueError('existing validation ownership conflicts with authored contract')
        print('Skin V2 validation owner already registered');return
    data['tests'].append(entry)
    MANIFEST.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    print('Registered Skin V2 narrow validation owner')


if __name__=='__main__':main()
