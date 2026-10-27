#!/usr/bin/env python3
"""Mechanical candidate safety checks; never equates technical PASS to art acceptance."""
import argparse,hashlib,json,pathlib,math
import numpy as np
import trimesh
P=pathlib.Path

def check(path,config):
    path=P(path);conf=json.loads(P(config).read_text());rece=json.loads(path.with_suffix('.manifest.json').read_text())
    failures=[];warnings=[]
    if hashlib.sha256(path.read_bytes()).hexdigest()!=rece['asset_sha256']:failures.append('GLB hash differs from immutable manifest')
    scene=trimesh.load(path,force='scene')
    parts=list(scene.dump(concatenate=False))
    if len(parts)<60:failures.append('Fewer than 60 named editable parts')
    allv=np.vstack([m.vertices for m in parts]);bounds=np.array([allv.min(axis=0),allv.max(axis=0)])
    if not np.isfinite(allv).all():failures.append('Nonfinite mesh coordinates')
    up=1 if conf.get('export_y_up') else 2;side=[i for i in range(3) if i!=up]
    if np.linalg.norm(bounds[0][side])>2 or np.linalg.norm(bounds[1][side])>2:failures.append('Model beyond declared local character bounds')
    if bounds[0][up]<-.01 or bounds[1][up]>2.15:failures.append('Ground/height contract violated')
    if len(parts)!=rece['geometry_count']:failures.append('Part count manifest mismatch')
    if not any(np.max(m.visual.vertex_colors[:,:3].mean(axis=0))>200 for m in parts if hasattr(m.visual,'vertex_colors')):warnings.append('No bright color accent; verify amber visor manually')
    names=list(scene.geometry.keys());req=['Head__visor_amber','Cloak__one_piece_folded_fabric','Boot_L__sole','Boot_R__sole','Torso__core']
    for prefix in req:
        if not any(s.startswith(prefix) for s in names):failures.append('Missing expected semantic mesh '+prefix)
    # open-drapery sheets intentionally need not be watertight.
    openparts=sum(not m.is_watertight for m in parts)
    if openparts:warnings.append(f'{openparts} nonwatertight surfaces (expected open cape/hood; inspect those only)')
    if conf['source_contract']['art_generation']!='operator_2_5d_128':failures.append('Wrong target generation')
    if conf['status']!='BLOCKOUT_NOT_CANONICAL':failures.append('Candidate falsely claims visual approval')
    result={'schema':'custodian.operator_3d_candidate_qa.v1','status':'TECHNICAL_PASS_ART_UNREVIEWED' if not failures else 'FAIL','asset_sha256':rece['asset_sha256'],'geometry_count':len(parts),'bounds_xyz_m':bounds.round(4).tolist(),'nonwatertight_parts':openparts,'failures':failures,'warnings':warnings,'subjective_art_accepted':False,'blender_animation_tested':False}
    path.with_suffix('.qa.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    print(json.dumps(result,indent=2));return 1 if failures else 0
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--glb',required=True);p.add_argument('--config',required=True);a=p.parse_args();raise SystemExit(check(a.glb,a.config))
