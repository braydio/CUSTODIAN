#!/usr/bin/env python3
"""Review sheets for one experiment: source idle (native 128) vs 3D (native 128), walk strip, loop GIF, metrics.
Machine metrics are triage only; they never stand in for human recognition."""
import argparse, json, pathlib, subprocess
import numpy as np
from PIL import Image, ImageDraw
ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT.parent / 'operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png'
DIRS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
BG = (74, 74, 78, 255)

def src_cell(i, frame=0):
    sheet = Image.open(SRC).convert('RGBA')
    return sheet.crop((frame * 128, i * 128, frame * 128 + 128, i * 128 + 128))

def stats(im):
    a = np.array(im)[..., 3] > 32
    ys, xs = np.where(a)
    return {'bbox': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())], 'height_px': int(ys.max() - ys.min() + 1),
            'width_px': int(xs.max() - xs.min() + 1), 'area_px': int(a.sum())} if len(xs) else {'empty': True}

def iou(a, b):
    A = np.array(a)[..., 3] > 32; B = np.array(b)[..., 3] > 32
    return round(float((A & B).sum() / max(1, (A | B).sum())), 3)

def label(im, text):
    d = ImageDraw.Draw(im); d.text((3, 2), text, fill=(255, 255, 255, 255)); return im

def main():
    p = argparse.ArgumentParser(); p.add_argument('--experiment', required=True); a = p.parse_args()
    base = ROOT / 'experiments' / a.experiment; px = base / 'blender_proof/px128'; out = base / 'review'; out.mkdir(exist_ok=True)
    Z = 3
    sheet = Image.new('RGBA', (128 * Z * 8, 128 * Z * 3), BG); metrics = {}
    for i, d in enumerate(DIRS):
        s = src_cell(i); r = Image.open(px / f'rest_{d}.png').convert('RGBA')
        ov = Image.new('RGBA', (128, 128), BG)
        sa = np.array(s)[..., 3] > 32; ra = np.array(r)[..., 3] > 32
        o = np.zeros((128, 128, 4), np.uint8); o[..., 3] = 255; o[..., :3] = BG[:3]
        o[sa & ~ra] = (230, 60, 60, 255); o[ra & ~sa] = (60, 130, 240, 255); o[sa & ra] = (200, 200, 200, 255)
        for row, im in enumerate((s, r, Image.fromarray(o))):
            c = Image.new('RGBA', (128, 128), BG); c.alpha_composite(im) if row < 2 else c.paste(im)
            c = c.resize((128 * Z, 128 * Z), Image.NEAREST); sheet.paste(c, (128 * Z * i, 128 * Z * row))
        metrics[d] = {'source': stats(s), 'model': stats(r), 'silhouette_iou': iou(s, r)}
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(DIRS): d.text((128 * Z * i + 4, 4), n, fill=(255, 255, 0, 255))
    d.text((4, 128 * Z + 4), 'row2: 3D @128 native', fill=(255, 255, 0, 255)); d.text((4, 256 * Z + 4), 'row3: red=source only, blue=3D only', fill=(255, 255, 0, 255))
    d.text((4, 20), 'row1: source idle f0 @128', fill=(255, 255, 0, 255))
    sheet.convert('RGB').save(out / 'compare_source_vs_3d_8dir.png')
    frames = [Image.open(px / f'walk_NE_{i:02d}.png').convert('RGBA') for i in range(1, 16)]
    strip = Image.new('RGBA', (128 * 8 * 2, 128 * 2 * 2), BG)
    for i, f in enumerate(frames):
        strip.alpha_composite(f.resize((256, 256), Image.NEAREST), (256 * (i % 8), 256 * (i // 8)))
    src_ne = [src_cell(1, k) for k in range(15)]
    strip.convert('RGB').save(out / 'walk_NE_15f_contact.png')
    gif = []
    for f in frames:
        c = Image.new('RGBA', (128, 128), BG); c.alpha_composite(f); gif.append(c.resize((384, 384), Image.NEAREST).convert('P', palette=Image.ADAPTIVE))
    gif[0].save(out / 'walk_NE_loop_PROVISIONAL_cadence.gif', save_all=True, append_images=gif[1:], duration=67, loop=0, disposal=1)
    ankle = json.loads((base / [f for f in base.iterdir() if f.suffix == '.blend'][0].with_suffix('.rig_qa.json').name).read_text())
    metrics['walk_ik_max_reach_error_m'] = max(ankle['ik_reach_error_m'])
    json.dump(metrics, open(out / 'metrics.json', 'w'), indent=1, sort_keys=True)
    print(json.dumps({k: (v['silhouette_iou'], v['model']['height_px'], v['source']['height_px']) if k in DIRS else v for k, v in metrics.items()}))

if __name__ == '__main__': main()
