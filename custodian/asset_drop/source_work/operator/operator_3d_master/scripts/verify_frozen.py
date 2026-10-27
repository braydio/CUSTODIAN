#!/usr/bin/env python3
"""Recompute SHA256 of every file in each frozen experiment receipt; exit 1 on any drift."""
import hashlib, json, pathlib, sys
R = pathlib.Path(__file__).resolve().parents[1] / 'experiments'; bad = 0
for r in sorted(R.glob('exp-*/blender_proof_frozen.json')):
    j = json.loads(r.read_text()); miss = [f['path'] for f in j['files'] if hashlib.sha256((r.parent / f['path']).read_bytes()).hexdigest() != f['sha256']]
    print(r.parent.name, 'OK' if not miss else f'DRIFT {miss}', len(j['files']), 'files'); bad += bool(miss)
sys.exit(1 if bad else 0)
