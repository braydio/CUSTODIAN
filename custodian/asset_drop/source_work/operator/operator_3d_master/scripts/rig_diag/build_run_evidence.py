"""Compose compact review evidence from render_rigged.py frames. usage: build_run_evidence.py <frames_dir> <out_dir>"""
import sys, json, pathlib
from PIL import Image, ImageDraw
fr, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
info = json.load(open(fr / 'render_info.json')); f0, f1 = info['frames']; FR = list(range(f0, f1 + 1)); BG = (62, 64, 72)
DIRS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']; SEL = [1, 5, 9, 13, 17, 21]
def load(res, d, f):
    im = Image.open(fr / f'{res}_{d}_{f:02d}.png').convert('RGBA'); bg = Image.new('RGBA', im.size, BG + (255,)); return Image.alpha_composite(bg, im).convert('RGB')
def sheet(res, dirs, name, title):
    pad = 14; W = res * len(SEL); H = (res + pad) * len(dirs) + 18; s = Image.new('RGB', (W, H), (30, 30, 34)); d = ImageDraw.Draw(s); d.text((4, 3), title, fill=(255, 255, 0))
    for i, dr in enumerate(dirs):
        for j, f in enumerate(SEL):
            y = 18 + i * (res + pad); s.paste(load(res, dr, f), (j * res, y + pad)); d.text((j * res + 3, y + 1), f'{dr}  frame {f}', fill=(255, 255, 0))
    s.save(out / name, optimize=True)
cap = f"EXPERIMENTAL_UNAPPROVED - real Mixamo Running.fbx retargeted (22-frame clip @30fps, loop uses frames 1-21) - 45deg/50px/m, one scale x{info['applied_scale']}, unmirrored"
sheet(128, DIRS, 'run_8dir_128_contact.png', 'NATIVE 128px render | ' + cap)
sheet(512, ['S', 'E', 'N', 'SE'], 'run_4dir_512_contact.png', 'independently rendered 512px | ' + cap)
def gif(frames, name, ms=33):
    frames[0].save(out / name, save_all=True, append_images=frames[1:], duration=ms, loop=0, optimize=True, disposal=2)
cells = []
for f in FR:
    g = Image.new('RGB', (128 * 4, 128 * 2), BG)
    for k, dr in enumerate(DIRS): g.paste(load(128, dr, f), ((k % 4) * 128, (k // 4) * 128))
    cells.append(g.quantize(64))
gif(cells, 'run_8dir_128.gif')
for dr in ('S', 'E'): gif([load(512, dr, f).quantize(96) for f in FR], f'run_{dr}_512.gif')
print(sorted(p.name for p in out.iterdir()), [p.stat().st_size for p in sorted(out.iterdir())])
