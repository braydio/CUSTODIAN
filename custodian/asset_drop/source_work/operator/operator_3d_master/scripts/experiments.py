#!/usr/bin/env python3
"""Append-only experiment registry and manually chosen best pointer. Never publishes runtime."""
import argparse,hashlib,json,pathlib,shutil,subprocess,sys,datetime
P=pathlib.Path
ROOT=P(__file__).resolve().parents[1];ED=ROOT/'experiments'
def digest(p):return hashlib.sha256(P(p).read_bytes()).hexdigest()
def record(exp):
    folder=ED/exp
    m=folder/'candidate.manifest.json'
    if not m.exists():raise RuntimeError('Missing built candidate manifest')
    return json.loads(m.read_text())
def main():
    p=argparse.ArgumentParser();sub=p.add_subparsers(dest='command',required=True)
    new=sub.add_parser('new');new.add_argument('--id',required=True);new.add_argument('--config',required=True)
    accept=sub.add_parser('select-best');accept.add_argument('--id',required=True);accept.add_argument('--reason',required=True);accept.add_argument('--reviewed-by-human',action='store_true')
    sub.add_parser('status')
    a=p.parse_args();ED.mkdir(exist_ok=True)
    if a.command=='new':
        if not a.id.startswith('exp-') or '/' in a.id or '..' in a.id:raise RuntimeError('Experiment ID must start exp- and contain no separators')
        out=ED/a.id
        if out.exists():raise RuntimeError('Experiment already exists. Never overwrite a candidate; choose new ID.')
        out.mkdir();snapshot=out/'shape.json';shutil.copyfile(a.config,snapshot)
        subprocess.run([sys.executable,str(ROOT/'scripts/generate_mesh.py'),'--config',str(snapshot),'--out',str(out/'candidate.glb')],check=True)
        subprocess.run([sys.executable,str(ROOT/'scripts/verify_candidate.py'),'--config',str(snapshot),'--glb',str(out/'candidate.glb')],check=True)
        (out/'REVIEW_PENDING.txt').write_text('TECHNICAL PASS IS NOT ART APPROVAL. Open the eight-direction proof and Blender animated NE proof before selecting best.\n')
        print('Immutable experiment staged:',out)
    elif a.command=='select-best':
        if not a.reviewed_by_human:raise RuntimeError('Only record selection after explicit user visual review; --reviewed-by-human required')
        folder=ED/a.id
        if not folder.is_dir():raise RuntimeError('Unknown experiment ID')
        manifest=record(a.id);prev=ROOT/'best_candidate.json'
        old=json.loads(prev.read_text()) if prev.exists() else None
        payload={'schema':'custodian.operator_3d_best_candidate.v1','experiment_id':a.id,'candidate_sha256':manifest['asset_sha256'],'previous_best':old['experiment_id'] if old else None,'reason':a.reason,'reviewed_by_human':True,'selected_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'runtime_published':False}
        # Selection history is append-only and best pointer is reversible; original candidate immutable.
        hist=ROOT/'selection_history.jsonl'
        with hist.open('a') as f:f.write(json.dumps(payload,sort_keys=True)+'\n')
        prev.write_text(json.dumps(payload,indent=2,sort_keys=True)+'\n')
        print('Selected best, originals preserved. Runtime unchanged:',a.id)
    else:
        print(json.dumps({'experiments':sorted(x.name for x in ED.iterdir() if x.is_dir()),'best':json.loads((ROOT/'best_candidate.json').read_text()) if (ROOT/'best_candidate.json').exists() else None},indent=2))
if __name__=='__main__':main()
