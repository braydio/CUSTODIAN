#!/usr/bin/env python3
"""Contact sheet + metrics for the camera elevation sweep (diagnostic; never selects an angle)."""
import hashlib, json, pathlib, sys
import numpy as np
from PIL import Image, ImageDraw
ROOT = pathlib.Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT / 'scripts'))
from build_review import src_cell, SRC, DIRS, BG
assert hashlib.sha256(SRC.read_bytes()).hexdigest() == 'd4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3', 'source idle is not the locked bytes (LFS pointer?)'
raw = json.load(open(ROOT / 'review_pack/camera_sweep_exp007/sweep_raw.json')); F = ROOT / 'review_pack/camera_sweep_exp007'
sel = ['N', 'NE', 'E', 'SE', 'S']; Z = 3; W = 128 * Z
def mask(im): return np.array(im.convert('RGBA'))[..., 3] > 32
def box(m):
    ys, xs = np.where(m); return {'bbox_xyxy': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())], 'height_px': int(ys.max() - ys.min() + 1), 'width_px': int(xs.max() - xs.min() + 1)}
rows = [(None, 'SOURCE idle f0 (locked, sha256 verified)')] + [(e, f'{e} deg above horizon (exp-007 mesh, unchanged)') for e in (30, 40, 50, 60)] + [(0, 'REFERENCE ONLY: eye-level 0 deg (S, E) - anatomy, not a game view')]
sheet = Image.new('RGBA', (W * 5, (W + 16) * len(rows)), BG); d = ImageDraw.Draw(sheet); metrics = {'note': 'IoU is triage only; angle NOT selected.', 'anatomy_3d': raw['anatomy_3d'], 'per_angle': {}}
for r, (el, label) in enumerate(rows):
    y0 = (W + 16) * r; d.text((4, y0 + 2), label, fill=(255, 255, 0, 255))
    for c, n in enumerate(sel):
        if el is None: im = src_cell(DIRS.index(n))
        elif el == 0 and n not in ('S', 'E'): continue
        else: im = Image.open(F / f'el{el:02d}_{n}.png')
        cell = Image.new('RGBA', (128, 128), BG); cell.alpha_composite(im.convert('RGBA')); sheet.paste(cell.resize((W, W), Image.NEAREST), (W * c, y0 + 16)); d.text((W * c + 4, y0 + 18), n, fill=(255, 255, 0, 255))
        if el:
            m = mask(im); s = mask(src_cell(DIRS.index(n))); k = f'{el}/{n}'
            metrics['per_angle'][k] = {'model': box(m), 'source': box(s), 'silhouette_iou': round(float((m & s).sum() / (m | s).sum()), 3),
                                       'projected_root_px': raw['frames'][f'el{el:02d}_{n}.png']['projected_root_px'], 'bottom_row_model': box(m)['bbox_xyxy'][3], 'bottom_row_source': box(s)['bbox_xyxy'][3]}
        elif el == 0:
            metrics['per_angle'][f'0 (eye level, reference only)/{n}'] = {'model': box(mask(im)), 'projected_root_px': raw['frames'][f'el00_{n}.png']['projected_root_px']}
sheet.convert('RGB').save(ROOT / 'review_pack/camera_calibration_exp007.png')
mean = {e: round(sum(v['silhouette_iou'] for k, v in metrics['per_angle'].items() if k.startswith(f'{e}/')) / 5, 3) for e in (30, 40, 50, 60)}
metrics['mean_iou_5dir_by_elevation'] = mean; json.dump(metrics, open(ROOT / 'review_pack/camera_calibration_exp007_metrics.json', 'w'), indent=1)
print(mean)
