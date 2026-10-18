#!/usr/bin/env python3
"""Idempotent focused validation owner for authored R3 topology toolchain."""
from pathlib import Path
import json
p=Path('custodian/tools/validation/validation_manifest.json')
if not p.is_file():raise SystemExit('ERROR: run at CUSTODIAN repo root')
s=p.read_text();o=json.loads(s)
if o.get('schema_version')!=1 or not isinstance(o.get('tests'),list):raise SystemExit('unexpected validation registry schema')
owner={'id':'operator_ne_r3_topology','type':'python',
       'script':'custodian/tools/validation/operator_ne_r3_topology_smoke.py',
       'tier':'unit','tags':['operator','art','source','negative_control','topology'],
       'owners':['custodian/tools/operator/ne_walk_retarget/clean_silhouette_r3.py',
         'custodian/tools/operator/ne_walk_retarget/smoke_clean_silhouette_r3.py',
         'custodian/tools/operator/ne_walk_retarget/register_r3_validation.py',
         'custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r3.sh',
         'custodian/tools/validation/operator_ne_r3_topology_smoke.py',
         'docs/R3_AUTHORING_SPEC.md','docs/R3_EXECUTION.md','docs/R3_PACKAGE_MANIFEST.json'],
        'timeout_sec':90,'needs_import':False}
seen=[t for t in o['tests'] if t.get('id')==owner['id']]
if seen:
    if seen!=[owner]:raise SystemExit('ERROR R3 registry entry differs; do not overwrite')
    print('PASS R3 registry already exact');raise SystemExit(0)
token='"tests": ['
if s.count(token)!=1:raise SystemExit('registry layout changed; STOP')
entry='\n    '+json.dumps(owner,ensure_ascii=False,indent=2).replace('\n','\n    ') + (',' if o['tests'] else '')
p.write_text(s.replace(token,token+entry,1))
assert sum(x.get('id')=='operator_ne_r3_topology' for x in json.loads(p.read_text())['tests'])==1
print('PASS R3 registry owner added once')
