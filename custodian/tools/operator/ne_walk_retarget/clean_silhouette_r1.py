#!/usr/bin/env python3
"""CUSTODIAN Operator NE: reference-guided *review-only* 15-frame art cleanup.

Preserve the active candidate above a smooth waistline seam; transplant intact
apron, leg and boot pixels from the user-approved cleaner 15-frame Operator
walk below the seam. This deliberately does NOT claim to preserve exact IK,
plant coordinates, or rendered support-contact validation. Those are verified
again by human review and a separate animation acceptance pass.

Inputs are immutable. Output is a new RGBA 1920x128 horizontal strip plus
frame-by-frame provenance, diff and before/after review sheets. No blur,
interpolation, alpha feathering, recoloring, image generation or new pixel hues.

Requires Python 3.10+, Pillow and numpy. Fail closed on source/version drift.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from dataclasses import asdict, dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

W, H, N = 128, 128, 15
SHA_ALT = '2ecbde5f764bea4b86666abb26f5acf54e18f103d180290b491663b5129de2ea'
SHA_STYLE = '00a04e87a93ebf6c4de9040538453c2e44f72fbdf1a417bc8529aa22a2cc5551'
SHA_IDLE = '451eed81d8451aa0b5f81ce50144af05253d641c19cf04be74c96f348c1de802'
SHA_ACTIVE = 'e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a'
SHA_REPORT = '88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a'
SHA_DONOR = '20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba'  # Knight NE motion-report authority, used by smoke too.

# Deliberately authored, not inferred by a coding executor.  These waist seam
# heights (source-local pixel coordinates) move the intact alternate tabard
# and legs into the validated cycle, while retaining hood/shoulders/arms.
# The 15-frame source has the same root convention and 128x128 registration.
# F05/F07: protect overlap. F11-F13: carry cloth mass with extended near leg.
SEAM_Y = (66, 66, 65, 64, 63, 63, 63, 64, 65, 64, 62, 62, 62, 64, 65)
PHASES = (
    'contact_near', 'near_approach', 'near_to_far_transition',
    'far_swing', 'opposite_lead', 'far_swing_return',
    'contact_far', 'far_contact', 'far_drive',
    'far_to_near_recovery', 'near_extension', 'near_full_extension',
    'near_recovery', 'contact_near_return', 'seam_return',
)
REVIEW_FRAMES = (1, 2, 5, 7, 9, 11, 12, 13, 14, 15)
BG = (35, 36, 42, 255)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(path: Path, expected_sha: str, dims: tuple[int, int], label: str) -> np.ndarray:
    if not path.is_file():
        raise ValueError(f'{label}: required file not found: {path}')
    actual = sha(path)
    if actual != expected_sha:
        raise ValueError(f'{label}: immutable SHA256 mismatch: {actual} != {expected_sha}')
    with Image.open(path) as im:
        if im.size != dims or im.mode != 'RGBA':
            raise ValueError(f'{label}: expected RGBA {dims}, found {im.mode} {im.size}')
        pixels = np.array(im, dtype=np.uint8)
    if np.any((pixels[:, :, 3] != 0) & (pixels[:, :, 3] != 255)):
        raise ValueError(f'{label}: unexpected nonbinary alpha')
    return pixels


def frame(img: np.ndarray, i: int) -> np.ndarray:
    return img[:, i*W:(i+1)*W].copy()


def seam_at_columns(active: np.ndarray, clean: np.ndarray, center: int) -> np.ndarray:
    """Continuity-constrained graph path through the overlapping waistline.

    Cost is low in mutual transparency and at visually identical pixels.
    Adjacent columns move at most one raster pixel, to avoid zipper seams.
    The join remains in y=center +/-4; it cannot reach the legs or hood.
    """
    lo, hi = center - 4, center + 4
    ys = list(range(lo, hi+1))
    scores = np.zeros((W, len(ys)), dtype=np.float64)
    for x in range(W):
        for j, y in enumerate(ys):
            p, q = active[y, x], clean[y, x]
            av, bv = p[3] > 0, q[3] > 0
            # Color distance is relevant only when both are actually visible.
            color = float(np.abs(p[:3].astype('int16') - q[:3].astype('int16')).mean()) / 255 if av and bv else 0
            scores[x, j] = (2.4 if av != bv else 0) + (0.5*color) + 0.055*abs(y-center)
            # Prefer seams through an unobstructed gap rather than gold outlines.
            if av and bv:
                scores[x, j] += 0.08
    dp = np.full_like(scores, np.inf)
    back = np.zeros(scores.shape, dtype=np.int16)
    dp[0] = scores[0]
    for x in range(1, W):
        for j in range(len(ys)):
            possible = [(dp[x-1, k] + 0.20*abs(j-k), k)
                        for k in (j-1, j, j+1) if 0 <= k < len(ys)]
            best, prev = min(possible)
            dp[x, j] = best + scores[x, j]
            back[x, j] = prev
    chain = np.zeros(W, dtype=np.int16)
    chain[-1] = int(np.argmin(dp[-1]))
    for x in range(W-1, 0, -1):
        chain[x-1] = back[x, chain[x]]
    seam = np.array([ys[idx] for idx in chain], dtype=np.int16)
    if np.any(np.abs(np.diff(seam)) > 1):
        raise AssertionError('waist seam has a >1px adjacent jump')
    return seam


def composite_frame(active: np.ndarray, clean: np.ndarray, seam: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    yy = np.arange(H, dtype=np.int16)[:, None]
    replace = yy >= seam[None, :]
    dst = np.where(replace[:, :, None], clean, active).astype(np.uint8)
    if not np.array_equal(dst[~replace], active[~replace]) or not np.array_equal(dst[replace], clean[replace]):
        raise AssertionError('raster provenance mismatch during deterministic transplant')
    return dst, replace


def rgba_identity_colors(candidate: np.ndarray, first: np.ndarray, second: np.ndarray) -> bool:
    """Every pixel is copied verbatim from an input at its existing XY."""
    return bool(np.all(np.all(candidate == first, axis=2) | np.all(candidate == second, axis=2)))


def diff_count(a: np.ndarray, b: np.ndarray) -> int:
    return int(np.any(a != b, axis=2).sum())


def foreground_bbox(a: np.ndarray, y0: int, y1: int, x0: int, x1: int) -> list[int] | None:
    mask = a[y0:y1, x0:x1, 3] != 0
    ys, xs = np.where(mask)
    if not len(xs):
        return None
    return [int(x0 + xs.min()), int(y0 + ys.min()), int(x0 + xs.max()+1), int(y0 + ys.max()+1)]


def footprint(a: np.ndarray) -> dict:
    # Diagnostic only; pixels are NOT anatomical joint landmarks or an IK pass.
    def bottom_extent(x0: int, x1: int) -> dict:
        ys, xs = np.where(a[85:112, x0:x1, 3] != 0)
        if not len(xs):
            return {'bottom_y': None, 'bottom_row_x': None}
        yy = int(85+ys.max())
        xx = (np.where(a[yy, x0:x1, 3] != 0)[0]+x0)
        return {'bottom_y': yy, 'bottom_row_x': round(float(np.mean(xx)), 2) if len(xx) else None}
    return {'far_screen_left': bottom_extent(39, 64), 'near_screen_right': bottom_extent(64, 100)}


def emit_sheet(frames_in: list[np.ndarray], frames_out: list[np.ndarray], indices: tuple[int, ...], path: Path) -> None:
    # Each review entry is 2x128 native panels, framed on a neutral background.
    cols, rows = 2, math.ceil(len(indices)/2)
    canvas = Image.new('RGB', (cols*256, rows*152), BG[:3])
    draw = ImageDraw.Draw(canvas)
    for k, idx in enumerate(indices):
        x, y = (k % cols)*256, (k // cols)*152
        for src, dx in [(frames_in[idx-1], 0), (frames_out[idx-1], 128)]:
            tile = Image.new('RGBA', (128, 128), BG)
            tile.alpha_composite(Image.fromarray(src, 'RGBA'))
            canvas.paste(tile.convert('RGB'), (x+dx, y+17))
        draw.text((x+3, y+3), f'F{idx:02} CURRENT', fill='#b6c4db')
        draw.text((x+132, y+3), f'F{idx:02} CLEANUP', fill='#f2c985')
    canvas.save(path)


def emit_15_sheet(frames_in: list[np.ndarray], frames_out: list[np.ndarray], path: Path) -> None:
    canvas=Image.new('RGB', (1280, 480), BG[:3]);d=ImageDraw.Draw(canvas)
    for i,(src,dst) in enumerate(zip(frames_in,frames_out)):
        x,y=(i%5)*256,(i//5)*160
        d.text((x+3,y+3),f'F{i+1:02} {PHASES[i]}',fill='#eceef5')
        for pixels,dx in ((src,0),(dst,128)):
            tile=Image.new('RGBA',(128,128),BG)
            tile.alpha_composite(Image.fromarray(pixels,'RGBA'))
            canvas.paste(tile.convert('RGB'),(x+dx,y+20))
        d.text((x+3,y+149),'Validated-current',fill='#b6c4db')
        d.text((x+132,y+149),'Cleanup candidate',fill='#f2c985')
    canvas.save(path)


def emit_seam_sheet(frames: list[np.ndarray], joins: list[np.ndarray], path: Path) -> None:
    canvas=Image.new('RGB',(5*256,3*200),BG[:3]);d=ImageDraw.Draw(canvas)
    for i,(pixels,seam) in enumerate(zip(frames,joins)):
        x,y=(i%5)*256,(i//5)*200
        tile=Image.new('RGBA',(128,128),BG)
        tile.alpha_composite(Image.fromarray(pixels,'RGBA'))
        t=tile.resize((256,256),Image.Resampling.NEAREST)
        # Crop includes torso/waist-to-robe join only; red seam is diagnostic.
        view=t.crop((0,64,256,224))
        canvas.paste(view.convert('RGB'),(x,y+20))
        for col in range(W):
            px=2*col;py=2*int(seam[col])-64+y+20
            if y+20 <= py < y+180:
                canvas.putpixel((x+px,py),(243,106,196))
        d.text((x+3,y+3),f'F{i+1:02} waist join',fill='#ede5f3')
    canvas.save(path)


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--active',type=Path,required=True,help='unchanged Iteration 004 Operator strip')
    p.add_argument('--alternate',type=Path,required=True,help='user-uploaded cleaner 15-frame walk')
    p.add_argument('--report',type=Path,required=True,help='immutable Iteration 004 numerical report; read-only')
    p.add_argument('--style',type=Path,required=True,help='user-uploaded immutable 128x128 style lock')
    p.add_argument('--idle',type=Path,required=True,help='user-uploaded neutral 15-frame lock; provenance only')
    p.add_argument('--output-dir',type=Path,required=True,help='NEW directory; never overwrite existing evidence')
    p.add_argument('--allow-active-sha',default=SHA_ACTIVE,help='pinned candidate SHA, do not override without review approval')
    args=p.parse_args()
    if args.output_dir.exists():p.error('output directory must not exist; refuse to overwrite')
    if sha(args.report)!=SHA_REPORT:
        p.error('active Iteration 004 report SHA256 mismatch; no execution')
    report=json.loads(args.report.read_text())
    if report.get('schema')!='custodian.ne_walk_preview.v1' or len(report.get('frames',[]))!=15:
        p.error('active motion report schema/15-frame authority mismatch')
    if report.get('input_validation',{}).get('source_hash')!=SHA_DONOR:
        p.error('superseded Knight NE donor hash in motion report')
    active=verify(args.active,args.allow_active_sha,(N*W,H),'active walk')
    alternate=verify(args.alternate,SHA_ALT,(N*W,H),'alternate walk')
    style=verify(args.style,SHA_STYLE,(W,H),'style lock')
    idle=verify(args.idle,SHA_IDLE,(N*W,H),'idle lock')
    # Both references are source authority, never silently substituted.
    assert style.shape==(128,128,4) and idle.shape==(128,1920,4)
    frames_in,frames_out,joins,metrics=[],[],[],[]
    for i in range(N):
        old=frame(active,i);ref=frame(alternate,i)
        seam=seam_at_columns(old,ref,SEAM_Y[i])
        clean,replace=composite_frame(old,ref,seam)
        if not rgba_identity_colors(clean,old,ref):
            raise AssertionError(f'F{i+1:02}: invented pixel colors')
        original_pixels=int(np.count_nonzero(old[:,:,3]))
        changed=diff_count(old,clean)
        exact_upper=int(np.any(clean[:SEAM_Y[i]-4]!=old[:SEAM_Y[i]-4],axis=2).sum())
        if exact_upper:raise AssertionError(f'F{i+1:02}: upper style lock modified')
        def changed_foot(side: str) -> dict:
            oldfoot=footprint(old)[side];newfoot=footprint(clean)[side]
            dx=(newfoot['bottom_row_x']-oldfoot['bottom_row_x']) if oldfoot['bottom_row_x'] is not None and newfoot['bottom_row_x'] is not None else None
            dy=(newfoot['bottom_y']-oldfoot['bottom_y']) if oldfoot['bottom_y'] is not None and newfoot['bottom_y'] is not None else None
            return {'dx':round(dx,2) if dx is not None else None,'dy':dy,
               'contact_change_unverified': (dx is None or dy is None or abs(dx)>2 or abs(dy)>1)}
        metrics.append({'frame':i+1,'phase':PHASES[i],
            'support_authority':report['frames'][i]['support'],
            'support_footprint_change':changed_foot('near_screen_right' if report['frames'][i]['support']=='near' else 'far_screen_left'),
            'authored_seam_center_y':SEAM_Y[i], 'seam_min_y':int(seam.min()), 'seam_max_y':int(seam.max()),
            'seam_max_horizontal_step':int(np.abs(np.diff(seam)).max()),
            'changed_rgba_pixels':changed,'active_opaque_pixels':original_pixels,
            'output_opaque_pixels':int(np.count_nonzero(clean[:,:,3])),
            'transplanted_region_pixels':int(replace.sum()),
            'upper_locked_pixels_changed':exact_upper,
            'new_rgba_colors_invented':False,
            'active_bottom_footprint':footprint(old),
            'candidate_bottom_footprint':footprint(clean),
            'active_leg_bbox':foreground_bbox(old,78,112,39,101),
            'candidate_leg_bbox':foreground_bbox(clean,78,112,39,101)})
        frames_in.append(old);frames_out.append(clean);joins.append(seam)
    output=np.concatenate(frames_out,axis=1)
    args.output_dir.mkdir(parents=True)
    candidate_path=args.output_dir/'operator_ne_walk_cleanup_candidate_15f_1920x128.png'
    Image.fromarray(output,'RGBA').save(candidate_path)
    emit_sheet(frames_in,frames_out,REVIEW_FRAMES,args.output_dir/'BEFORE_AFTER_10_POSES.png')
    emit_15_sheet(frames_in,frames_out,args.output_dir/'BEFORE_AFTER_15_POSES.png')
    emit_seam_sheet(frames_out,joins,args.output_dir/'WAIST_JOIN_DIAGNOSTIC.png')
    comparison={'schema':'custodian.operator_ne_silhouette_cleanup_r1',
      'status':'REVIEW_ONLY / NO IK OR RUNTIME ACCEPTANCE',
      'input_sha256':{'validated_active':sha(args.active),'active_report':sha(args.report),'cleaner_15f':sha(args.alternate),
         'single_style':sha(args.style),'neutral_idle':sha(args.idle)},
      'output':{'filename':candidate_path.name,'sha256':sha(candidate_path),'dimensions':[1920,128],
                'frames':15,'frame_dimensions':[128,128],'layout':'horizontal','alpha':'binary'},
      'authoring':'per-frame low-waist join, source-pixel-only apron and both legs; near leg inherits intact NE reference contour',
      'support_phase_sequence':[f['support'] for f in report['frames']],
      'contact_pixel_diagnostics_failed':[v['frame'] for v in metrics if v['support_footprint_change']['contact_change_unverified']],
      'explicit_non_claims':['support foot contact not revalidated','IK joint positions of this raster output are not proven',
         'gait timing/FPS not selected','art not approved','runtime not published'],
      'provenance':{'all candidate pixels copied from active or clean reference at frame-local XY':True,
          'style and idle read-only':True,'NE frames reordered':False},
      'frames':metrics}
    (args.output_dir/'CLEANUP_REPORT.json').write_text(json.dumps(comparison,indent=2,allow_nan=False)+'\n')
    print(json.dumps({'result':'PREVIEW_CREATED','candidate':str(candidate_path),
         'candidate_sha256':sha(candidate_path),'changed_pixels_total':sum(x['changed_rgba_pixels'] for x in metrics),
         'output_dir':str(args.output_dir),'artistically_accepted':False}))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
