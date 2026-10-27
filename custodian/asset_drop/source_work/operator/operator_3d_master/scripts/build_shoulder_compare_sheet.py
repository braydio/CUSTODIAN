#!/usr/bin/env python3
"""Task 009 controlled comparison: canonical / exp-007 / exp-008 at the common 45deg 50px/m projection (8 dirs) + eye-level S/E before/after."""
import hashlib, pathlib, sys
from PIL import Image, ImageDraw
ROOT = pathlib.Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT / 'scripts'))
from build_review import src_cell, SRC, DIRS, BG
assert hashlib.sha256(SRC.read_bytes()).hexdigest() == 'd4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3'
R = ROOT / 'review_pack'; Z = 2; W = 128 * Z
rows = [('SOURCE idle f0 (locked)', lambda n: src_cell(DIRS.index(n))),
        ('exp-007 @45deg 50px/m (plate span 1.336 m)', lambda n: Image.open(R / f'projection45_exp007/el45_{n}.png')),
        ('exp-008 @45deg 50px/m (plate span 1.068 m)', lambda n: Image.open(R / f'projection45_exp008/el45_{n}.png'))]
H = W + 14; sheet = Image.new('RGBA', (W * 8, H * 4), BG); d = ImageDraw.Draw(sheet)
for r, (lab, fn) in enumerate(rows):
    d.text((4, H * r + 1), lab, fill=(255, 255, 0, 255))
    for c, n in enumerate(DIRS):
        cell = Image.new('RGBA', (128, 128), BG); cell.alpha_composite(fn(n).convert('RGBA')); sheet.paste(cell.resize((W, W), Image.NEAREST), (W * c, H * r + 14)); d.text((W * c + 4, H * r + 16), n, fill=(255, 255, 0, 255))
d.text((4, H * 3 + 1), 'EYE-LEVEL 0deg reference only (S,E): exp-007 | exp-008, anatomy not a game view', fill=(255, 255, 0, 255))
for i, (e, n) in enumerate((('007', 'S'), ('008', 'S'), ('007', 'E'), ('008', 'E'))):
    cell = Image.new('RGBA', (128, 128), BG); cell.alpha_composite(Image.open(R / f'eyelevel_exp{e}/el00_{n}.png').convert('RGBA')); sheet.paste(cell.resize((W, W), Image.NEAREST), (W * i, H * 3 + 14)); d.text((W * i + 4, H * 3 + 16), f'exp-{e} {n}', fill=(255, 255, 0, 255))
sheet.convert('RGB').save(R / 'projection45_exp007_vs_exp008.png')
