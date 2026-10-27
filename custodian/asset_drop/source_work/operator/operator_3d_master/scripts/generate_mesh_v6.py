#!/usr/bin/env python3
"""Model version 6 (exp-006+): capeless Operator. Selected with `model_version >= 6` in the shape config.

No Cloak__ geometry exists in this path. Fabric is the peaked hood + cowl and the gold-edged tunic panels hanging
from the belt (front, front-side, back, back-side). The legacy path in generate_mesh.py is untouched for exp-001..005.
Authoring space: Z up, character faces -Y, feet on Z=0.
"""
import math
import numpy as np
import trimesh
from generate_mesh import ellipsoid, link, loft_rings, slab_polygon

TR = trimesh.transformations


def hood_shell(rings, a0, a1, num=44):
    """Open-front fabric shell; angle 0 = +X, pi/2 = back (+Y). Front wedge between a1 and 2pi+a0 stays open."""
    vs, fs = [], []
    ang = np.linspace(a0, a1, num + 1)
    for z, w, d, cy in rings:
        for t in ang: vs.append([w * math.cos(t), cy + d * math.sin(t), z])
    for j in range(len(rings) - 1):
        for i in range(num):
            a = j * (num + 1) + i; b = a + 1; c = a + num + 1; d = c + 1
            fs += [(a, b, d), (a, d, c)]
    return trimesh.Trimesh(vertices=vs, faces=fs, process=False)


def panel(tl, tr, br, bl, amp, folds, nx=10, nz=9, thick=.02, trim_r=.0075):
    """Folded cloth panel (two sheets) plus one merged gold edge-trim mesh along both sides and the hem."""
    tl, tr, br, bl = (np.asarray(v, float) for v in (tl, tr, br, bl))
    n = np.cross(tr - tl, bl - tl); n /= np.linalg.norm(n)
    centre = (tl + tr + br + bl) / 4
    if n @ np.array([centre[0], centre[1], 0.0]) < 0: n = -n     # face away from the body axis

    def P(u, v):
        base = (tl * (1 - u) + tr * u) * (1 - v) + (bl * (1 - u) + br * u) * v
        return base + n * amp * math.sin(folds * math.pi * u) * (v ** 1.2) * (1 if folds else 0)
    vs, fs = [], []
    for s, off in ((0, 0.0), (1, -thick)):
        for j in range(nz + 1):
            for i in range(nx + 1): vs.append(P(i / nx, j / nz) + n * off)
    w = nx + 1; S = (nx + 1) * (nz + 1)
    for j in range(nz):
        for i in range(nx):
            a = j * w + i; b = a + 1; c = a + w; d = c + 1
            fs += [(a, c, d), (a, d, b), (S + a, S + d, S + c), (S + a, S + b, S + d)]
    cloth = trimesh.Trimesh(vertices=vs, faces=fs, process=False)
    pts_l = [P(0, j / nz) for j in range(nz + 1)]
    pts_r = [P(1, j / nz) for j in range(nz + 1)]
    pts_h = [P(i / nx, 1) for i in range(nx + 1)]
    segs = []
    for pts in (pts_l, pts_r, pts_h):
        for a, b in zip(pts[:-1], pts[1:]): segs.append(link(a, b, trim_r, trim_r, 6))
    return cloth, trimesh.util.concatenate(segs)


def rot_about(mesh, centre, axis, ang):
    mesh.apply_transform(TR.rotation_matrix(ang, axis, point=centre)); return mesh


def build(add, p):
    mirror = (1, -1)
    # ---- torso / pelvis (unchanged blockout volumes) ----
    add('Pelvis__underplate', loft_rings([(0.92, .22, .16, 0.01), (1.03, .26, .17, 0.01), (1.13, .24, .18, 0.01)]), 'armor_dark', 'Hips')
    add('Torso__core', loft_rings([(1.00, .235, .15, .012), (1.22, .29, .22, 0.0), (1.47, .32, .225, 0.0), (1.59, .275, .19, .012)]), 'armor', 'Spine')
    add('Torso__inner_gorget', loft_rings([(1.50, .20, .155, 0), (1.65, .19, .16, 0)]), 'undercloth', 'Spine')
    add('Torso__breastplate_left', slab_polygon([[.008, -.222, 1.19], [.265, -.11, 1.20], [.29, -.10, 1.47], [.052, -.245, 1.52], [.01, -.263, 1.38]], .045), 'armor_light', 'Spine')
    add('Torso__breastplate_right', slab_polygon([[-.008, -.222, 1.19], [-.265, -.11, 1.20], [-.29, -.10, 1.47], [-.052, -.245, 1.52], [-.01, -.263, 1.38]], .045), 'armor', 'Spine')
    for j in range(3):
        z = 1.10 + j * .068
        add(f'Torso__abdomen_lamella_{j}', loft_rings([(z, .255 - j * .008, .173, 0), (z + .028, .264 - j * .009, .177, -.008)]), 'armor_dark' if j % 2 else 'armor', 'Hips')
    add('Torso__center_bronze', slab_polygon([[-.024, -.253, 1.17], [.024, -.253, 1.17], [.033, -.267, 1.53], [-.033, -.267, 1.53]], .016), 'bronze_dim', 'Spine')
    add('Hips__belt', loft_rings([(1.02, .279, .183, -.004), (1.09, .283, .185, -.006)]), 'undercloth', 'Hips')
    add('Hips__buckle', trimesh.creation.box(extents=[.13, .053, .12], transform=TR.translation_matrix([0, -.210, 1.062])), 'bronze', 'Hips')
    for nm, z, rx, ry in (('belt_trim_top', 1.095, .285, .19), ('belt_trim_bottom', 1.017, .28, .185)):
        m = trimesh.creation.torus(1.0, .011 / ry, 48, 8); m.apply_scale([rx, ry, ry]); m.apply_translation([0, 0, z]); add('Hips__' + nm, m, 'bronze', 'Hips')
    for s in mirror:
        sd = 'L' if s > 0 else 'R'
        add(f'Hips__side_fauld_{sd}', slab_polygon([[s * .255, -.05, 1.015], [s * .33, -.015, 1.0], [s * .4, -.002, .78], [s * .29, -.07, .75]], .035), 'armor', 'Hips')

    # ---- head: forward-peaked fabric hood around a recessed, dark face; no helmet shell, no ring ----
    rings = [(1.50, .30, .25, .05), (1.60, .27, .235, .04), (1.72, .225, .215, .02), (1.84, .19, .195, -.01),
             (1.95, .14, .155, -.05), (2.03, .07, .09, -.10), (2.075, .012, .03, -.155)]
    add('Head__hood_shell', hood_shell(rings, -.6, math.pi + .6), 'cloak', 'Head')
    add('Head__cowl_lower', loft_rings([(1.575, .245, .195, .043), (1.68, .24, .21, .026), (1.765, .195, .18, .055)]), 'cloak', 'Head')
    add('Head__face_recess', ellipsoid([0, -.045, 1.775], [.15, .15, .19], 3), 'armor_dark', 'Head')
    add('Head__visor_amber', slab_polygon([[-.115, -.197, 1.855], [.115, -.197, 1.855], [0.0, -.205, 1.745]], .012), 'visor', 'Head')

    # ---- shoulders: three overlapping flattened plates, rim trimmed in gold ----
    for s in mirror:
        sd = 'L' if s > 0 else 'R'
        add(f'Shoulder_{sd}__joint', ellipsoid([s * .36, 0, 1.50], [.14, .13, .13], 2), 'undercloth', f'UpperArm.{sd}')
        for k, (cx, cz, rx, ry, rz) in enumerate(((.40, 1.625, .15, .16, .042), (.425, 1.58, .19, .19, .048), (.452, 1.525, .22, .215, .052))):
            c = [s * cx, -.012, cz]
            plate = ellipsoid(c, [rx, ry, rz], 2); rot_about(plate, c, [0, 1, 0], s * .35)
            add(f'Shoulder_{sd}__plate_{"ABC"[k]}', plate, 'armor_light' if k == 0 else 'armor', f'UpperArm.{sd}')
            if k > 0:
                ring = trimesh.creation.torus(1.0, .010 / max(rx, ry), 48, 8); ring.apply_scale([rx, ry, max(rx, ry)])
                ring.apply_translation(c); rot_about(ring, c, [0, 1, 0], s * .35)
                add(f'Shoulder_{sd}__plate_{"ABC"[k]}_trim', ring, 'bronze', f'UpperArm.{sd}')
        # tapered articulated arm
        add(f'UpperArm_{sd}__mail', link([s * .39, 0, 1.49], [s * .47, -.01, 1.19], .105, .082, 14), 'undercloth', f'UpperArm.{sd}')
        add(f'UpperArm_{sd}__plate', link([s * .41, -.012, 1.45], [s * .465, -.02, 1.26], .122, .098, 14), 'armor', f'UpperArm.{sd}')
        add(f'Elbow_{sd}__pivot', ellipsoid([s * .475, -.011, 1.20], [.095, .095, .075], 2), 'armor_dark', f'Forearm.{sd}')
        add(f'Forearm_{sd}__sleeve', link([s * .475, -.02, 1.19], [s * .48, -.06, .94], .085, .068, 12), 'undercloth', f'Forearm.{sd}')
        add(f'Forearm_{sd}__vambrace', link([s * .477, -.04, 1.15], [s * .485, -.07, .97], .10, .082, 14), 'armor_light', f'Forearm.{sd}')
        ring = trimesh.creation.torus(1.0, .008 / .085, 40, 8); ring.apply_scale([.085, .085, .085]); ring.apply_translation([s * .485, -.07, .97])
        add(f'Forearm_{sd}__wrist_trim', ring, 'bronze', f'Forearm.{sd}')
        add(f'Hand_{sd}__gauntlet', ellipsoid([s * .48, -.075, .90], [.085, .09, .115], 2), 'armor', f'Forearm.{sd}')

    # ---- legs: tapered volumes, no stacked beads ----
    for s in mirror:
        sd = 'L' if s > 0 else 'R'
        x = s * .165
        add(f'Thigh_{sd}__fabric', link([x, 0, 1.02], [s * .195, -.012, .61], .136, .107, 14), 'undercloth', f'Thigh.{sd}')
        add(f'Thigh_{sd}__outer_plate', link([s * .20, -.03, .98], [s * .20, -.04, .66], .125, .108, 14), 'armor', f'Thigh.{sd}')
        add(f'Knee_{sd}__cup', ellipsoid([s * .19, -.06, .58], [.115, .12, .10], 2), 'armor_light', f'Shin.{sd}')
        add(f'Shin_{sd}__core', link([s * .19, 0, .58], [s * .19, -.008, .20], .106, .08, 12), 'undercloth', f'Shin.{sd}')
        add(f'Shin_{sd}__greave', link([s * .19, -.03, .54], [s * .19, -.025, .26], .115, .088, 14), 'armor', f'Shin.{sd}')
        # boot: sole bottom exactly on Z=0 (ankle bone sits .18 above it), heel stack, instep, toe cap, gold cuff edge
        add(f'Boot_{sd}__shaft', link([s * .19, -.01, .33], [s * .19, -.01, .10], .104, .098, 14), 'armor_dark', f'Foot.{sd}')
        add(f'Boot_{sd}__sole', trimesh.creation.box(extents=[.24, .37, .06], transform=TR.translation_matrix([s * .19, -.085, .03])), 'armor_dark', f'Foot.{sd}')
        add(f'Boot_{sd}__heel', trimesh.creation.box(extents=[.17, .13, .045], transform=TR.translation_matrix([s * .19, .055, .0825])), 'armor_dark', f'Foot.{sd}')
        add(f'Boot_{sd}__instep', ellipsoid([s * .19, -.095, .135], [.105, .17, .08], 2), 'armor_dark', f'Foot.{sd}')
        add(f'Boot_{sd}__toe_cap', ellipsoid([s * .19, -.215, .095], [.108, .15, .06], 2), 'armor', f'Foot.{sd}')
        ring = trimesh.creation.torus(1.0, .008 / .104, 40, 8); ring.apply_scale([.104, .104, .104]); ring.apply_translation([s * .19, -.01, .325])
        add(f'Boot_{sd}__cuff_trim', ring, 'bronze', f'Foot.{sd}')

    # ---- tunic: distinct front / front-side / back / back-side panels hanging from the belt; gold-edged, folded ----
    spec = {
        'front_center': ((-.11, -.215, 1.03), (.11, -.215, 1.03), (.15, -.275, .42), (-.15, -.275, .42), .022, 2),
        'front_L': ((.12, -.21, 1.03), (.27, -.16, 1.01), (.33, -.235, .52), (.16, -.275, .46), .018, 1),
        'back_center': ((-.15, .19, 1.03), (.15, .19, 1.03), (.20, .27, .50), (-.20, .27, .50), .022, 2),
        'back_L': ((.15, .19, 1.03), (.27, .13, 1.0), (.34, .22, .58), (.20, .27, .52), .018, 1),
    }
    for nm, (tl, tr, br, bl, amp, folds) in spec.items():
        variants = [(nm, (tl, tr, br, bl))]
        if nm.endswith('_L'):
            mir = lambda q: (-q[0], q[1], q[2])
            variants.append((nm[:-1] + 'R', (mir(tr), mir(tl), mir(bl), mir(br))))
        for name, (a, b, c, d) in variants:
            cloth, trim = panel(a, b, c, d, amp, folds)
            add(f'Tabard__{name}', cloth, 'cloak', 'Hips')
            add(f'Tabard__{name}_edge_trim', trim, 'bronze', 'Hips')
