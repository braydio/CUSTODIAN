#!/usr/bin/env python3
"""Content-addressed journal of a Blender proof; never confers art approval."""
import argparse,hashlib,json,pathlib,datetime
P=pathlib.Path
p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);p.add_argument('--notes',required=True);a=p.parse_args()
base=P(__file__).resolve().parents[1] / 'experiments' / a.experiment
if not base.is_dir():raise SystemExit('Unknown experiment: '+a.experiment)
out=base/'blender_proof_frozen.json'
if out.exists():raise SystemExit('Already frozen; create a new immutable experiment')
files=[]
for path in sorted(base.rglob('*')):
    if path.is_file() and path!=out:
        files.append({'path':path.relative_to(base).as_posix(),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
if not any(x['path'].endswith('.blend') for x in files):raise SystemExit('No Blender .blend to freeze')
if not any('walk_NE_' in x['path'] for x in files):raise SystemExit('No actual Blender-rendered NE frames to freeze')
report={'schema':'custodian.operator_3d_blender_proof.v1','experiment':a.experiment,'files':files,'notes':a.notes,'frozen_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'art_approved':False,'gameplay_published':False}
out.write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
print('Frozen',len(files),'files; art approval still pending:',out)
