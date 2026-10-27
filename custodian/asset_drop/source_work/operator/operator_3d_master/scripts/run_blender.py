#!/usr/bin/env python3
"""Host-side wrapper: run create_blend.py for an experiment using the `blender` block of its shape.json snapshot."""
import argparse, json, pathlib, shutil, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(); p.add_argument('--experiment', required=True); a = p.parse_args()
e = ROOT / 'experiments' / a.experiment; b = json.loads((e / 'shape.json').read_text()).get('blender', {})
exe = shutil.which('blender') or sys.exit('blender not on PATH')
cmd = [exe, '-b', '-t', '2', '--python', str(ROOT / 'scripts/create_blend.py'), '--', '--glb', str(e / 'candidate.glb'),
       '--manifest', str(e / 'candidate.manifest.json'), '--out', str(e / f'operator_{a.experiment.replace("-", "")}.blend'),
       '--proof', str(e / 'blender_proof'), '--px-per-m', str(b.get('px_per_m', 43.5)), '--scale-xy', str(b.get('scale_xy', 1.0)),
       '--scale-z', str(b.get('scale_z', 1.0)), '--metal-scale', str(b.get('metal_scale', 1.0)),
       '--half-stride', str(b.get('half_stride', .20)), '--lift', str(b.get('lift', .13)), '--arm-swing', str(b.get('arm_swing', .30)),
       '--ankle-z', str(b.get('ankle_z', .158)), '--stance-offset', str(b.get('stance_offset', .02))]
log = subprocess.run(cmd, capture_output=True, text=True)
(e / 'blender_run.log').write_text('\n'.join(l for l in (log.stdout + log.stderr).splitlines() if 'render  ' not in l and 'glTF' not in l and 'Blender create' not in l))
print('blender exit', log.returncode); sys.exit(log.returncode)
