#!/usr/bin/env python3
"""Task 009 sheet: source / candidate at the common 45 deg projection / silhouette overlay, 8 directions. Triage metrics only; no approval.
usage: build_projection_sheet.py FRAMES_DIR OUT_PNG OUT_JSON LABEL"""
import hashlib, json, pathlib, sys
import numpy as np
from PIL import Image, ImageDraw
ROOT = pathlib.Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT / 'scripts'))
from build_review import src_cell, SRC, DIRS, BG
assert hashlib.sha256(SRC.read_bytes()).hexdigest() == 'd4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3', 'source idle is not the locked bytes'
F = pathlib.Path(sys.argv[1]); outp = pathlib.Path(sys.argv[2]); outj = pathlib.Path(sys.argv[3]); label = sys.argv[4]
raw = json.load(open(F / 'sweep_raw.json'))['frames'] if (F / 'sweep_raw.json').exists() else {}
Z = 2; W = 128 * Z
def mask(im): return np.array(im.convert('RGBA'))[..., 3] > 32
def box(m):
    ys, xs = np.where(m); return {'bbox_xyxy': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())], 'height_px': int(ys.max() - ys.min() + 1), 'width_px': int(xs.max() - xs.min() + 1)}
rows = ['SOURCE idle f0 (locked)', label, 'overlay: red=source only, blue=model only, white=both']
sheet = Image.new('RGBA', (W * 8, (W + 14) * 3), BG); d = ImageDraw.Draw(sheet); met = {}
for c, n in enumerate(DIRS):
    s = src_cell(DIRS.index(n)).convert('RGBA'); m = Image.open(F / f'el45_{n}.png').convert('RGBA')
    ms, mm = mask(s), mask(m)
    ov = np.zeros((128, 128, 4), np.uint8); ov[..., 3] = 255; ov[ms & ~mm] = (230, 40, 40, 255); ov[mm & ~ms] = (60, 90, 255, 255); ov[ms & mm] = (235, 235, 235, 255)
    for r, im in enumerate((s, m, Image.fromarray(ov))):
        cell = Image.new('RGBA', (128, 128), BG); cell.alpha_composite(im); sheet.paste(cell.resize((W, W), Image.NEAREST), (W * c, (W + 14) * r + 14))
        if c == 0: d.text((4, (W + 14) * r + 1), rows[r], fill=(255, 255, 0, 255))
        d.text((W * c + 4, (W + 14) * r + 16), n, fill=(255, 255, 0, 255))
    key = f'el45_{n}.png'
    met[n] = {'model': box(mm), 'source': box(ms), 'silhouette_iou': round(float((mm & ms).sum() / (mm | ms).sum()), 3),
              'projected_root_px': raw.get(key, {}).get('projected_root_px'), 'ortho_scale': raw.get(key, {}).get('ortho_scale')}
sheet.convert('RGB').save(outp)
json.dump({'note': 'IoU is triage only; no approval', 'label': label, 'per_direction': met, 'mean_iou': round(sum(v['silhouette_iou'] for v in met.values()) / 8, 3),
           'height_px_range': [min(v['model']['height_px'] for v in met.values()), max(v['model']['height_px'] for v in met.values())]}, open(outj, 'w'), indent=1)
print(outj.read_text()[-200:])
