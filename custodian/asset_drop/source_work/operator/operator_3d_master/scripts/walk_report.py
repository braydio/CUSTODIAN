#!/usr/bin/env python3
"""Host-side analysis of walk_audit_raw.json: planted foot displacement (body frame), ground contact, seam, hover."""
import json, sys, pathlib
e = pathlib.Path(sys.argv[1]); raw = json.load(open(e / 'walk_audit_raw.json'))['frames']; TOL = .006
rep = {'contact_tolerance_m': TOL, 'sides': {}}
for s in 'LR':
    F = [f[s] for f in raw]
    flat = [f['heel_min_z'] < TOL and f['toe_min_z'] < TOL for f in F]
    swing_min = [round(min(f['min_z'] for f in F), 4)]
    # planted runs; displacement only between consecutive planted frames (transition/lift frames excluded)
    steps = [F[i + 1]['cy'] - F[i]['cy'] for i in range(14) if flat[i] and flat[i + 1]]
    mean = sum(steps) / len(steps) if steps else None
    dev = [abs(x - mean) * 1000 for x in steps] if steps else []
    rep['sides'][s] = {'planted_frames': sum(flat), 'planted_mask': ''.join('P' if x else '.' for x in flat),
        'min_sole_z_over_loop_m': round(min(f['min_z'] for f in F), 4), 'max_sole_z_when_flat_m': round(max(f['min_z'] for f in F if f['heel_min_z'] < TOL and f['toe_min_z'] < TOL), 4) if any(flat) else None,
        'planted_body_frame_step_mean_m': round(mean, 4) if mean is not None else None,
        'planted_skate_max_dev_mm_per_frame': round(max(dev), 2) if dev else None,
        'swing_peak_clearance_m': round(max(f['min_z'] for f in F), 4)}
L = rep['sides']
rep['alternation'] = {'left_planted_when_right_swing_frames': sum(1 for a, b in zip(L['L']['planted_mask'], L['R']['planted_mask']) if a != b),
                      'both_planted_frames': sum(1 for a, b in zip(L['L']['planted_mask'], L['R']['planted_mask']) if a == b == 'P')}
step = lambda a, b: max(abs(raw[a][s][k] - raw[b][s][k]) for s in 'LR' for k in ('cx', 'cy', 'min_z'))
inner = [step(i, i + 1) for i in range(14)]; seam = step(14, 0)
rep['loop_seam'] = {'f15_to_f01_max_foot_delta_m': round(seam, 4), 'inner_step_max_m': round(max(inner), 4), 'inner_step_mean_m': round(sum(inner) / 14, 4)}
rep['hips_z_range_m'] = round(max(f['hips_z'] for f in raw) - min(f['hips_z'] for f in raw), 4)
json.dump(rep, open(e / 'walk_audit.json', 'w'), indent=1); print(json.dumps(rep))
