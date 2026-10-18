#!/usr/bin/env python3
"""Single idempotent registration for exact R2 reference manifest/part authoring owners."""
from pathlib import Path
import json
p=Path('custodian/tools/validation/validation_manifest.json')
if not p.is_file():raise SystemExit('ERROR run at repository root')
s=p.read_text()
o=json.loads(s)
if o.get('schema_version')!=1 or not isinstance(o.get('tests'),list):raise SystemExit('unknown registry schema')
key='operator_ne_r2_reference_manifest'
owner={'id':key,'type':'python',
  'script':'custodian/tools/validation/operator_ne_r2_reference_smoke.py',
  'tier':'unit','tags':['operator','art','source','negative_control'],
  'owners':['docs/REFERENCE_MANIFEST.json',
    'custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1/**',
    'custodian/tools/operator/ne_walk_retarget/clean_silhouette_r2.py',
    'custodian/tools/operator/ne_walk_retarget/smoke_clean_silhouette_r2.py',
    'custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r2.sh',
    'custodian/tools/operator/ne_walk_retarget/register_r2_validation.py',
    'custodian/tools/operator/ne_walk_retarget/fixtures/SINGLE_FRAME.aseprite',
    'docs/R2_PACKAGE_MANIFEST.json',
    'custodian/tools/validation/operator_ne_r2_reference_smoke.py'],
  'timeout_sec':30,'needs_import':False}
seen=[t for t in o['tests'] if t.get('id')==key]
if seen:
 if seen!=[owner]:raise SystemExit('ERROR existing R2 test registration differs; do not override')
 print('R2 validation owner already exact');raise SystemExit(0)
# Insert a compact JSON entry to preserve the existing registry formatting and test order.
token='"tests": ['
if s.count(token)!=1:raise SystemExit('ERROR unexpected validation registry formatting')
insertion=token+'\n    '+json.dumps(owner,ensure_ascii=False,indent=2).replace('\n','\n    ')+','
p.write_text(s.replace(token,insertion,1))
verify=json.loads(p.read_text())
assert any(t.get('id')==key for t in verify['tests'])
print('PASS R2 validation owner inserted (narrow manifest/source/script scope)')
