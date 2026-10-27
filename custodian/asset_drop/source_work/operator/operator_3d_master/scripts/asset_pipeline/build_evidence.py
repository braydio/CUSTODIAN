#!/usr/bin/env python3
"""Compose the 11-file textured review pack from evidence_render.py frames + the frozen pipeline_report. Host side (PIL/numpy), no model edits.
usage: build_evidence.py FRAMES_DIR NORMALIZED_DIR DECODED_GLB OUT_DIR"""
import json, pathlib, struct, sys
import numpy as np
from PIL import Image, ImageDraw
F, N, GLB, OUT = (pathlib.Path(x) for x in sys.argv[1:5]); OUT.mkdir(parents=True, exist_ok=True)
BG = (62, 62, 70); Y = (255, 255, 0)
DIRS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
def cell(p, size): im = Image.open(p).convert('RGBA'); c = Image.new('RGBA', im.size, BG + (255,)); c.alpha_composite(im); return c.convert('RGB').resize((size, size), Image.NEAREST if size == im.size[0] * (size // im.size[0]) and im.size[0] <= 128 else Image.LANCZOS)
def grid(imgs, labels, cols, title):
    w, h = imgs[0].size; rows = (len(imgs) + cols - 1) // cols; s = Image.new('RGB', (w * cols, (h + 14) * rows + 16), BG); d = ImageDraw.Draw(s); d.text((4, 2), title, fill=Y)
    for i, (im, lb) in enumerate(zip(imgs, labels)):
        x, y = (i % cols) * w, 16 + (i // cols) * (h + 14); s.paste(im, (x, y + 14)); d.text((x + 4, y + 1), lb, fill=Y)
    return s
rep = json.load(open(N / 'pipeline_report.json')); diag = json.load(open(F / 'diagnostics.json'))
# 1 native 128 (3x nearest, plus 1:1 strip) -- frames are native 128 renders from the frozen normalisation run
c128 = [cell(N / f'renders/128_{d}.png', 384) for d in DIRS]; g = grid(c128, DIRS, 4, '%s textured, NATIVE 128px renders shown 3x nearest | 45deg 50px/m ortho, one uniform scale x%s | asset pose retained (not necessarily idle)' % (rep.get('name', 'asset'), rep['asset']['applied_scale']))
strip = Image.new('RGB', (1024, 142), BG); ds = ImageDraw.Draw(strip); ds.text((4, 2), '1:1 native 128px strip (N NE E SE S SW W NW)', fill=Y)
for i, d in enumerate(DIRS): im = Image.open(N / f'renders/128_{d}.png').convert('RGBA'); c = Image.new('RGBA', (128, 128), BG + (255,)); c.alpha_composite(im); strip.paste(c.convert('RGB'), (i * 128, 14))
out = Image.new('RGB', (g.width, g.height + 142), BG); out.paste(g, (0, 0)); out.paste(strip, (0, g.height)); out.save(OUT / 'textured_8dir_128_contact.png')
# 2 512 independently rendered
grid([cell(N / f'renders/512_{d}.png', 512) for d in DIRS], DIRS, 4, '%s: independently rendered 512px (not upscaled 128) | same 45deg/50px/m, same scale' % rep.get('name', 'asset')).save(OUT / 'textured_8dir_512_contact.png')
# 3 eye-level
grid([cell(F / f'eye_{n}.png', 768) for n in ('front_S', 'profile_E', 'rear_N')], ['front (S)', 'profile (E)', 'rear (N)'], 3, 'genuine eye-level (0 deg) ortho 2.4 m frame, fixed scale, same model/lighting | reference anatomy, NOT a game view').save(OUT / 'eye_level_front_side_back.png')
# 4-6 details
for reg, ttl in (('hood_neck', 'hood / neck'), ('shoulders_armor', 'shoulders / armor'), ('tabard_gold_boots', 'tabard / gold trim / boots')):
    grid([cell(F / f'detail_{reg}_{d}.png', 768) for d in ('S', 'NE')], ['S front', 'NE three-quarter'], 2, f'DETAIL {ttl}: real camera crops, 20deg elevation, 768px, no painted corrections').save(OUT / f'details_{reg}.png')
# 7 material proof
tex = Image.open(F / 'tex_base_color_512.png').convert('RGB') if (F / 'tex_base_color_512.png').exists() else Image.new('RGB', (512, 512), BG)
panels = [cell(F / 'mat_textured.png', 512), cell(F / 'mat_textured_standard.png', 512), cell(F / 'mat_clay.png', 512), tex]
mp = grid(panels, ['textured (AgX, as in all other sheets)', 'textured (Standard view transform)', 'neutral clay, same camera/light', 'base-colour map Image_0 (4096^2, shown 512)'], 4, 'MATERIAL PROOF: the same imported model with its PBR textures vs clay')
if diag['materials']:
    m = diag['materials'][0]; mp0 = next((n for n in m['nodes'] if 'mapping_scale' in n), None); lines = ['Live Blender node tree (imported, unedited): ' + ' ; '.join(m['links'][:13])]
    lines += ['Images: ' + (' | '.join(f"{n['image']} {n['size'][0]}x{n['size'][1]} {n['colorspace']}" for n in m['nodes'] if 'image' in n) or 'none')]
    if mp0 and diag['uv_range']: lines += ['KHR_texture_transform -> Mapping nodes: scale %s loc %s ; UV range of mesh u[%.3f,%.3f] v[%.3f,%.3f]' % (mp0['mapping_scale'][:2], mp0['mapping_loc'][:2], *diag['uv_range'][0])]
    lines += ['backface culling: %s ; default view transform: %s' % (m['use_backface_culling'], diag['view_transform_default'])]
else: lines = ['No Blender material node tree on this asset (untextured / vertex-colour only); default view transform: %s' % diag['view_transform_default']]
s = Image.new('RGB', (mp.width, mp.height + 16 * len(lines) + 8), BG); s.paste(mp, (0, 0)); dd = ImageDraw.Draw(s)
for i, l in enumerate(lines): dd.text((4, mp.height + 4 + 16 * i), l[:330], fill=(220, 220, 220))
s.save(OUT / 'material_proof.png')
# 8 geometry proof + open-edge analysis straight from the decoded GLB bytes
d = GLB.read_bytes(); jl = struct.unpack_from('<I', d, 12)[0]; j = json.loads(d[20:20 + jl]); bin0 = 20 + jl + 8
def acc(i):
    a = j['accessors'][i]; bv = j['bufferViews'][a['bufferView']]; dt = {5123: '<u2', 5125: '<u4', 5120: 'i1', 5126: '<f4'}[a['componentType']]; nc = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3}[a['type']]
    stride = bv.get('byteStride'); base = bin0 + bv.get('byteOffset', 0) + a.get('byteOffset', 0); isz = np.dtype(dt).itemsize
    if stride and stride != isz * nc:
        raw = np.frombuffer(d, np.uint8, count=a['count'] * stride, offset=base).reshape(a['count'], stride)[:, :isz * nc]; return np.ascontiguousarray(raw).view(dt).reshape(a['count'], nc)
    return np.frombuffer(d, dt, count=a['count'] * nc, offset=base).reshape(a['count'], nc)
prim = j['meshes'][0]['primitives'][0]; pos = acc(prim['attributes']['POSITION']); idx = acc(prim['indices']).reshape(-1)
_, weld = np.unique(pos, axis=0, return_inverse=True); weld = weld.reshape(-1); tri = weld[idx].reshape(-1, 3)
e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]]); e.sort(1); _, cnt = np.unique(e[:, 0].astype(np.int64) * (weld.max() + 1) + e[:, 1], return_counts=True)
geo = {'welded_unique_positions': int(weld.max() + 1), 'edges': int(len(cnt)), 'boundary_edges_(count==1)': int((cnt == 1).sum()), 'non_manifold_edges_(count>2)': int((cnt > 2).sum()), 'degenerate_triangles': int(((tri[:, 0] == tri[:, 1]) | (tri[:, 1] == tri[:, 2]) | (tri[:, 0] == tri[:, 2])).sum()), 'triangles': int(len(tri))}
gp = grid([cell(F / 'geo_rear_solid.png', 768), cell(F / 'geo_wire_hood.png', 768), cell(F / 'geo_wire_boots.png', 768)], ['rear solid (N, 20deg) - rear surface present?', 'wireframe hood/shoulder crop', 'wireframe boot crop'], 3, 'GEOMETRY PROOF (real 1.25M-tri mesh; rear solid = Workbench, wire = EEVEE Wireframe node 1px): ' + json.dumps(geo))
gp.save(OUT / 'geometry_proof.png')
# 9 compare sheet with caveat footer (original pixels untouched, footer appended)
cs = Image.open(N / 'compare_8dir.png').convert('RGB'); foot = Image.new('RGB', (cs.width, 34), BG); fd = ImageDraw.Draw(foot)
fd.text((4, 2), 'CAVEATS: asset pose is whatever the export has (compare vs the canonical IDLE); ONE uniform scale fitted from the S view only (other directions deviate); reference-experiment row (if present) has its own scale basis;', fill=Y)
fd.text((4, 18), 'IoU is triage only, not an equalised score and not approval. Original compare_8dir.png pixels unchanged; this footer added.', fill=Y)
o = Image.new('RGB', (cs.width, cs.height + 34), BG); o.paste(cs, (0, 0)); o.paste(foot, (0, cs.height)); o.save(OUT / 'compare_8dir.png')
# 10 report
(OUT / 'pipeline_report.json').write_text(json.dumps({'frozen_pipeline_report': rep, 'evidence_diagnostics': {k: v for k, v in diag.items()}, 'geometry_analysis': geo}, indent=1))
ga = rep.get('decoded_audit', {})
(OUT / 'REVIEW_NOTES.md').write_text(f'''# {rep.get('name', 'asset')} - review notes ({rep.get('status', 'IMPORTED_REFERENCE_CANDIDATE_NOT_APPROVED')})

Not approved, not selected, no runtime use. Every image is rendered from the imported asset (no concept art, no painting, no edits).

**Input:** {rep.get('input', {}).get('basename')} sha256 `{rep.get('input', {}).get('sha256')}`; container `{rep.get('container', {}).get('kind')}`; decoded GLB sha256 `{rep.get('decoded_sha256')}`.
**Mesh:** {ga.get('vertices')} verts / {ga.get('triangles')} tris; boundary edges {geo['boundary_edges_(count==1)']}, non-manifold edges {geo['non_manifold_edges_(count>2)']}, degenerate tris {geo['degenerate_triangles']}; UV: {ga.get('has_texcoord0')}; textures: {ga.get('textures')} (base {ga.get('has_base_color_texture')}, metal-rough {ga.get('has_metal_rough_texture')}, normal {ga.get('has_normal_texture')}); texture transform: {ga.get('texture_transform_used')}.
**Render contract:** {rep.get('render_contract', {}).get('elev_deg')} deg elevation, {rep.get('render_contract', {}).get('px_per_m')} px/m orthographic, root (64,106), unmirrored N NE E SE S SW W NW, ONE uniform scale x{rep['asset']['applied_scale']} fitted from the S view to {rep.get('render_contract', {}).get('target_S_height_px')} px (other directions deviate); view transform {diag['view_transform_default']}. 128 px frames are native renders; 512 px frames are independent renders.
**Known limits:** asset pose retained (no rig/pose/retopology); IoU is triage only; no approval.

**Questions for the reviewer (judgment is the user's, not the agent's):** pass them to publish-review with --question.
''')
print(json.dumps(geo))
