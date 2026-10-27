#!/usr/bin/env python3
"""One compact cross-candidate sheet at native 128 (x2): source idle f0 vs each listed experiment, 8 directions."""
import sys, pathlib
from PIL import Image, ImageDraw
ROOT = pathlib.Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT / 'scripts'))
from build_review import src_cell, DIRS, BG
exps = sys.argv[2:]; out = pathlib.Path(sys.argv[1]); Z = 2
sheet = Image.new('RGBA', (128 * Z * 8 + 90, 128 * Z * (1 + len(exps))), BG); d = ImageDraw.Draw(sheet)
d.text((4, 6), 'SOURCE idle f0', fill=(255, 255, 0, 255))
for i, n in enumerate(DIRS):
    d.text((90 + 128 * Z * i + 4, 2), n, fill=(255, 255, 0, 255))
    c = Image.new('RGBA', (128, 128), BG); c.alpha_composite(src_cell(i)); sheet.paste(c.resize((128 * Z, 128 * Z), Image.NEAREST), (90 + 128 * Z * i, 0))
    for r, e in enumerate(exps, 1):
        c = Image.new('RGBA', (128, 128), BG); c.alpha_composite(Image.open(ROOT / f'experiments/{e}/blender_proof/px128/rest_{n}.png').convert('RGBA'))
        sheet.paste(c.resize((128 * Z, 128 * Z), Image.NEAREST), (90 + 128 * Z * i, 128 * Z * r))
for r, e in enumerate(exps, 1): d.text((4, 128 * Z * r + 6), e, fill=(255, 255, 0, 255))
out.parent.mkdir(exist_ok=True); sheet.convert('RGB').save(out); print(out)
