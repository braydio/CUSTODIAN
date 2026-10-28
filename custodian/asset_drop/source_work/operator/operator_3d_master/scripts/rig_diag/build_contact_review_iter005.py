"""Build ITER003/ITER005 ground-contact overlays, comparison sheets, and loops.

Usage: python build_contact_review_iter005.py <iter003-128> <iter005-128>
       <iter003-512> <iter005-512> <iter003-contact.json>
       <iter005-contact.json> <outdir>
"""
from pathlib import Path
import sys
import json
import math
import numpy as np
from PIL import Image, ImageDraw

before128, after128, before512, after512, before_json, after_json, out = map(Path, sys.argv[1:])
out.mkdir(parents=True, exist_ok=True)
before = json.load(open(before_json))
after = json.load(open(after_json))
camera = after['render_camera_contract']
scale = camera['uniform_scale']
cx, cy = camera['pivot_center_xy_m']
z0 = camera['ground_pivot_z_m']
AZ = {'N': 180, 'NE': -135, 'E': -90, 'SE': -45, 'S': 0, 'SW': 45, 'W': 90, 'NW': 135}
ALL_DIRECTIONS = list(AZ)
FOCUSED_DIRECTIONS = ['N', 'E', 'S', 'SE']
CONTACT_FRAMES = [1, 2, 10, 11, 12, 13, 14, 19, 20, 21]
LABELS = {'left_heel': 'LH', 'left_toe': 'LT', 'right_heel': 'RH', 'right_toe': 'RT'}
COLORS = {'left_heel': (50, 230, 255), 'left_toe': (255, 110, 215),
          'right_heel': (90, 150, 255), 'right_toe': (255, 190, 70)}
SOLE_COLORS = {'Left': (255, 80, 60), 'Right': (255, 220, 40)}

def project(pos, direction, res):
    az = math.radians(AZ[direction])
    elev = math.radians(camera['elevation_deg'])
    cam = np.array([math.sin(az) * math.cos(elev), -math.cos(az) * math.cos(elev), math.sin(elev)])
    view = -cam / np.linalg.norm(cam)
    right = np.cross(view, np.array([0.0, 0.0, 1.0]))
    right /= np.linalg.norm(right)
    up = np.cross(right, view)
    up /= np.linalg.norm(up)
    pivot = np.array([cx, cy, z0])
    q = (np.asarray(pos, dtype=float) - pivot) * scale
    ppm = camera['pixels_per_meter_at_128'] * res / 128.0
    root = np.asarray(camera['root_pixel_128'], dtype=float) * res / 128.0
    return root + np.array([np.dot(q, right), -np.dot(q, up)]) * ppm

def paint(img, data, frame, direction, res, label):
    draw = ImageDraw.Draw(img, 'RGBA')
    ground_y = project([cx, cy, 0.0], direction, res)[1]
    draw.line((0, int(round(ground_y)), res, int(round(ground_y))),
              fill=(110, 245, 140, 230), width=max(1, res // 256))
    row = data['frames'][frame - 1]
    for name, short in LABELS.items():
        landmark = row['fixed_landmarks'][name]
        x, y = project(landmark['xyz_m'], direction, res)
        x, y = int(round(x)), int(round(y))
        radius = max(3, res // 64)
        color = COLORS[name]
        draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill=(*color, 245),
                     outline=(0, 0, 0, 255), width=max(1, res // 256))
    for side, short in (('Left', 'L sole'), ('Right', 'R sole')):
        point = row['foot_geometry_min'][side]
        x, y = project(point['xyz_m'], direction, res)
        x, y = int(round(x)), int(round(y))
        radius = max(3, res // 72)
        color = SOLE_COLORS[side]
        draw.rectangle((x-radius, y-radius, x+radius, y+radius), fill=(*color, 245),
                       outline=(0, 0, 0, 255), width=max(1, res // 256))
    draw.text((3, 3), f'{label} f{frame:02d} {direction}', fill=(255, 255, 255, 255),
              stroke_width=1, stroke_fill=(0, 0, 0, 230))
    return img.convert('RGB')

def tile(root, data, res, direction, frame, label):
    image = Image.open(root / f'{res}_{direction}_{frame:02d}.png').convert('RGBA')
    return paint(image, data, frame, direction, res, label)

def comparison_sheet(res, directions, frames, filename):
    roots = (before128, after128) if res == 128 else (before512, after512)
    datasets = (before, after)
    tile_height = res + 20
    sheet = Image.new('RGB', (len(directions) * 2 * res, len(frames) * tile_height), (20, 20, 24))
    draw = ImageDraw.Draw(sheet)
    for ri, frame in enumerate(frames):
        y = ri * tile_height
        for ci, direction in enumerate(directions):
            for vi, (root, data, label) in enumerate(zip(roots, datasets, ('ITER003', 'ITER005'))):
                x = ci * 2 * res + vi * res
                sheet.paste(tile(root, data, res, direction, frame, label), (x, y + 20))
                draw.text((x + 3, y + 3), f'{direction} f{frame:02d} {label}', fill='white')
    sheet.save(out / filename, optimize=True)

comparison_sheet(128, ALL_DIRECTIONS, CONTACT_FRAMES,
                 'contact_128_all8_iter003_vs_iter005.png')
comparison_sheet(512, FOCUSED_DIRECTIONS, CONTACT_FRAMES,
                 'contact_512_native_focused_iter003_vs_iter005.png')

def loop(res, directions, filename):
    frames = []
    display_res = 128
    roots = (before128, after128) if res == 128 else (before512, after512)
    for frame in range(1, 22):
        strips = [Image.new('RGB', (len(directions) * display_res, display_res), (0, 0, 0)) for _ in range(2)]
        for ci, direction in enumerate(directions):
            for vi, (root, data, label) in enumerate(((roots[0], before, 'ITER003'),
                                                       (roots[1], after, 'ITER005'))):
                image = tile(root, data, res, direction, frame, label)
                if res != display_res:
                    image = image.resize((display_res, display_res), Image.Resampling.LANCZOS)
                strips[vi].paste(image, (ci * display_res, 0))
        canvas = Image.new('RGB', (len(directions) * display_res, display_res * 2 + 24), (24, 24, 28))
        canvas.paste(strips[0], (0, 20))
        canvas.paste(strips[1], (0, display_res + 24))
        ImageDraw.Draw(canvas).text((4, 3), f'{res}px render, upper ITER003 / lower ITER005, frame {frame}/21', fill='white')
        frames.append(canvas.convert('P', palette=Image.Palette.ADAPTIVE, colors=128))
    frames[0].save(out / filename, save_all=True, append_images=frames[1:], duration=70,
                   loop=0, optimize=True, disposal=2)

loop(128, ALL_DIRECTIONS, 'contact_loop_128_all8_iter003_vs_iter005.gif')
loop(512, FOCUSED_DIRECTIONS, 'contact_loop_512_focused_iter003_vs_iter005.gif')

metadata = {
    'schema': 'custodian.operator_run_contact_review.v1',
    'before': 'ITER003 gait-corrected Blender asset',
    'after': 'ITER005 experimental contact-phase two-bone IK derivative',
    'camera': camera,
    'contact_frames_in_sheets': CONTACT_FRAMES,
    'directions_128': ALL_DIRECTIONS,
    'directions_native_512': FOCUSED_DIRECTIONS,
    'overlay': 'green line z=0; circular markers in cyan/magenta/blue/orange are LH/LT/RH/RT fixed 12-vertex centroids; red/yellow squares mark per-frame minimum z among Left/Right Foot/ToeBase group-weighted geometry candidates. Exact heights and vertex IDs are in the JSON diagnostics.',
    'sheets': ['contact_128_all8_iter003_vs_iter005.png', 'contact_512_native_focused_iter003_vs_iter005.png'],
    'loops': ['contact_loop_128_all8_iter003_vs_iter005.gif', 'contact_loop_512_focused_iter003_vs_iter005.gif'],
    'render_note': 'ITER005 was independently rendered by render_rigged.py at native 128px and native 512px. The 512px loop is resized for playback; the contact sheet remains native512.'
}
json.dump(metadata, open(out / 'contact_review_metadata.json', 'w'), indent=2)
print(json.dumps(metadata, indent=2))
