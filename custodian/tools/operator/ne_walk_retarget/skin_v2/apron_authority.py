#!/usr/bin/env python3
"""ChatGPT-authored Skin V2 offline sprite-cutout and apron *proof*, not production art.

Never fabricates hidden pixels or changes a source file. Any visible holes become
explicit human art requirements; these variants are NOT animation acceptance.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
from pathlib import Path
from typing import Callable

import numpy as np

W = H = 128
SIDES = ('near', 'far')
ORDER = ('thigh_far_visible', 'shin_far_visible', 'foot_far_visible', 'robe_far',
         'thigh_near_visible', 'shin_near_visible', 'foot_near_visible',
         'robe_center', 'robe_near')
PARTS = tuple('__RIG_PART_' + x for x in ORDER)
FULL = '__RIG_REFERENCE_LOCKED_FULL_BODY'

# Pixel-authoring parameters. One source-palette-only experiment, no tuning by executor.
# Each x/y value is the signed displacement at the garment hem, in source pixels.
# Positive x moves a panel toward screen right. F01/F15 retain the POC's exact
# existing bounded shear; far-cross/near-open are *different* cloth silhouettes.
VARIANT_HEM = {
    'far_cross': {'robe_far': (-2, 0), 'robe_center': (2, 1), 'robe_near': (3, 1)},
    'near_open': {'robe_far': (0, 0), 'robe_center': (-2, -1), 'robe_near': (-5, -2)},
}
FRAME_VARIANT = {1: 'neutral', 5: 'far_cross', 7: 'far_cross',
                 12: 'near_open', 15: 'neutral'}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def count(mask: np.ndarray) -> int:
    return int(np.count_nonzero(mask))


def palette(rgba: np.ndarray) -> set[tuple[int, int, int, int]]:
    return {tuple(map(int, p)) for p in rgba.reshape(-1, 4) if p[3] > 0}


def audit_neutral(rig: dict[str, np.ndarray]) -> tuple[np.ndarray, dict, np.ndarray]:
    """Subtract only true semantic owners; prove byte-identical rest reconstruction.

    Upper-body subdivisions below are *spatial proposals*, never accepted rig owners.
    Their cut positions must be reviewed before a new pivot is given authority.
    """
    required = [FULL, *PARTS]
    missing = [n for n in required if n not in rig]
    if missing:
        raise ValueError(f'missing accepted semantic layers: {missing}')
    full = rig[FULL]
    if full.shape != (128, 128, 4) or not np.isin(full[:, :, 3], [0, 255]).all():
        raise ValueError('locked original must be binary RGBA 128x128')
    mask_union = np.zeros((H, W), dtype=bool)
    for name in PARTS:
        cel = rig[name]
        if cel.shape != full.shape or not np.isin(cel[:, :, 3], [0, 255]).all():
            raise ValueError(f'invalid semantic part shape/alpha: {name}')
        mask = cel[:, :, 3] > 0
        if count(mask) < 4 or np.any(mask & mask_union):
            raise ValueError(f'missing or overlapping semantic part owner {name}')
        if not np.array_equal(cel[mask], full[mask]):
            raise ValueError(f'part differs from immutable locked-source pixels: {name}')
        mask_union |= mask
    residual = full.copy()
    residual[mask_union] = 0
    rebuilt = residual.copy()
    for name in ORDER:
        cel = rig['__RIG_PART_' + name]
        mask = cel[:, :, 3] > 0
        rebuilt[mask] = cel[mask]
    diff = np.any(rebuilt != full, axis=2)
    if count(diff):
        raise ValueError(f'neutral source is not byte-exact, {count(diff)} changed pixels')
    ys, xs = np.indices((H, W))
    # HEURISTIC topographic bands; alpha remains in unmodified residual.
    # We do not assign shoulders/arms semantic ownership without real cels.
    opaque = residual[:, :, 3] > 0
    label = np.zeros((H, W), dtype=np.uint8)
    label[opaque & (ys < 54)] = 1            # head/hood provisional
    label[opaque & (ys >= 54) & (ys < 67)] = 2  # upper-body provisional
    label[opaque & (ys >= 67)] = 3            # pelvis/other unresolved
    report = {
        'schema': 'custodian.skin_v2.source_audit.v1',
        'neutral_reassembly_changed_pixels': count(diff),
        'locked_opaque_pixels': count(full[:, :, 3]),
        'dynamic_owned_pixels': count(mask_union),
        'static_residual_pixels': count(opaque),
        'upper_body_articulation_authorized': False,
        'heuristic_source_bands_are_semantic_layers': False,
        'proposed_hood_pixels': count(label == 1),
        'proposed_upper_body_pixels': count(label == 2),
        'unresolved_static_pixels': count(label == 3),
        'missing_independent_parts': ['hood/head pivot', 'torso pivot',
                                      'shoulder near/far', 'upper arm near/far',
                                      'forearm near/far', 'covered costume backing'],
    }
    return residual, report, label


def aperture_warp(src: np.ndarray, panel: str, variant: str) -> np.ndarray:
    """Inverse nearest-sample a *real* rig panel; holds waistband exactly fixed.

    Opening a panel exposes transparent pixels only. It does NOT paint hidden
    armor or infer cloth colors; those gaps are recorded in the gap ledger.
    """
    if variant not in VARIANT_HEM or panel not in VARIANT_HEM[variant]:
        raise ValueError(f'unsupported authored apron variant/panel: {variant}/{panel}')
    if src.shape != (128, 128, 4):
        raise ValueError('apron cel shape is not 128x128 RGBA')
    mask = src[:, :, 3] > 0
    if not mask.any():
        raise ValueError(f'empty cloth cel {panel}')
    yy = np.where(mask)[0]
    # Bounds come from the actual cel. Preserve top 3 rows entirely.
    waist = int(yy.min()) + 3
    hem = int(yy.max())
    if hem - waist < 4:
        raise ValueError(f'{panel} insufficient vertical source coverage for an opening')
    dx_hem, dy_hem = VARIANT_HEM[variant][panel]
    out = np.zeros_like(src)
    xs = np.arange(W)
    for y in range(H):
        t = float(np.clip((y - waist) / (hem - waist), 0.0, 1.0))
        # Hold everything above the waist and move the lower edge gradually.
        shift_x = int(np.rint(dx_hem * t))
        shift_y = int(np.rint(dy_hem * t))
        source_y = y - shift_y
        source_x = xs - shift_x
        ok = (0 <= source_y < H) & (source_x >= 0) & (source_x < W)
        if 0 <= source_y < H:
            out[y, ok] = src[source_y, source_x[ok]]
    if not palette(out).issubset(palette(src)):
        raise ValueError('apron warp invented colors')
    if not np.array_equal(out[:waist], src[:waist]):
        raise ValueError('apron waist was not pixel locked')
    if not np.isin(out[:, :, 3], [0, 255]).all():
        raise ValueError('non-binary apron alpha')
    return out


def compose_frame(rig: dict[str, np.ndarray], residual: np.ndarray,
                  pose: dict, warp_limb: Callable, 
                  baseline_shear: Callable) -> tuple[np.ndarray, np.ndarray, dict]:
    """Recompose exact source-part pixels at the PoC's Knight joint targets.

    warp_limb = R2 inverse-nearest rigid_warp, baseline_shear = already-
    approved POC _row_shear. Neither is duplicated or retuned here.
    """
    frame = int(pose['frame'])
    if frame not in FRAME_VARIANT:
        raise ValueError(f'unsupported five-pose index {frame}')
    variant = FRAME_VARIANT[frame]
    points = pose['posed']
    delta = np.asarray(pose['translation'], dtype=float)
    translate = tuple(int(np.rint(v)) for v in delta)
    canvas = translate_nearest(residual, translate)
    owner = np.zeros((H, W), dtype=np.uint8)
    owner[canvas[:, :, 3] > 0] = 1
    warped = {}
    neutral = {
        'near': {'hip':(63,75), 'knee':(65,89), 'ankle':(66,100), 'toe':(75,104)},
        'far': {'hip':(53,75), 'knee':(52,83), 'ankle':(50,88), 'toe':(48,91)},
    }
    for side in SIDES:
        for kind, start, end in [('thigh', 'hip', 'knee'), ('shin', 'knee', 'ankle'),
                                 ('foot', 'ankle', 'toe')]:
            key = f'{kind}_{side}_visible'
            warped[key] = warp_limb(rig['__RIG_PART_'+key],
                                    neutral[side][start], neutral[side][end],
                                    points[side][start], points[side][end])
    near, far = points['near'], points['far']
    stride = ((near['ankle'][0] - near['hip'][0]) -
              (far['ankle'][0] - far['hip'][0]))
    for panel in ('robe_far', 'robe_center', 'robe_near'):
        src = rig['__RIG_PART_' + panel]
        if variant == 'neutral':
            warped_panel = baseline_shear(src, panel.removeprefix('robe_'), stride)
        else:
            warped_panel = aperture_warp(src, panel, variant)
        warped[panel] = translate_nearest(warped_panel, translate)
    for name in ORDER:
        alpha = warped[name][:, :, 3] > 0
        canvas[alpha] = warped[name][alpha]
        owner[alpha] = 2 + ORDER.index(name)
    if not np.isin(canvas[:, :, 3], [0, 255]).all():
        raise ValueError('non-binary output alpha')
    if not palette(canvas).issubset(palette(rig[FULL])):
        raise ValueError('new or mixed source palette colors')
    if count((canvas[:, :, 3] > 0) & (owner == 0)):
        raise ValueError('ownerless rendered alpha')
    return canvas, owner, {'frame':frame, 'variant':variant,
                           'stride':float(stride),
                           'robe_visible_pixels':{p:count(owner == 2+ORDER.index(p))
                                                   for p in ('robe_far','robe_center','robe_near')},
                           'source_only_palette':True}


def translate_nearest(image: np.ndarray, xy: tuple[int,int]) -> np.ndarray:
    dx,dy=xy
    out = np.zeros_like(image)
    x0,y0 = max(0,-dx),max(0,-dy)
    x1,y1 = min(W,W-dx),min(H,H-dy)
    if x0 < x1 and y0 < y1:
        out[y0+dy:y1+dy,x0+dx:x1+dx] = image[y0:y1,x0:x1]
    return out


def art_gap_report(baseline: np.ndarray, trial: np.ndarray, baseline_owner: np.ndarray,
                   trial_owner: np.ndarray) -> tuple[dict, np.ndarray]:
    """Expose all newly transparent source areas as requirements, not fake fills."""
    if any(a.shape != (H,W,4) for a in (baseline,trial)):
        raise ValueError('shape mismatch in gap report')
    source_alpha = baseline[:, :, 3] > 0
    new_alpha = trial[:, :, 3] > 0
    y,x = np.indices((H,W))
    apron_range = (y>=64)&(y<=99)&(x>=32)&(x<=105)
    lost = source_alpha & ~new_alpha & apron_range
    gained = ~source_alpha & new_alpha & apron_range
    # No automatic claim all lost alpha is invalid; some is an intended opening.
    # Red means a potential backing requirement, not a regression verdict.
    overlay = np.zeros((H,W,4),dtype=np.uint8)
    overlay[lost] = (255,65,92,255)
    overlay[gained] = (61,195,235,255)
    report = {'newly_transparent_apron_region_pixels':count(lost),
              'newly_opaque_apron_region_pixels':count(gained),
              'unverified_hidden_backing_required':bool(lost.any()),
              'newly_transparent_bbox':None,
              'art_acceptance':False}
    if lost.any():
        yy,xx=np.where(lost)
        report['newly_transparent_bbox']=[int(xx.min()),int(yy.min()),int(xx.max()),int(yy.max())]
    return report,overlay
