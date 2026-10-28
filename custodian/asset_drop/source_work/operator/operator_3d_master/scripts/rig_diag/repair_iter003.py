"""iter-003 (derivative of iter-002): same detach+reweight treatment as iter-002 but for the ARM <-> TORSO (Hips/Spine/belt-cloth) contact below the armpit
(rest z < ZMAX). Shoulder, neck, head, legs untouched. Positions/UVs unchanged; no faces deleted.
usage: blender -b --python repair_iter003.py -- <iter002.blend> <iter003.blend> <report.json>"""
import bpy, sys, json, numpy as np, bmesh
from scipy.spatial import cKDTree
src, dst, rep = sys.argv[sys.argv.index('--') + 1:][:3]; ZMAX = 1.25
bpy.ops.wm.open_mainfile(filepath=src)
me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]; names = {g.index: g.name for g in me.vertex_groups}
TORSO = {'mixamorig:Hips', 'mixamorig:Spine', 'mixamorig:Spine1', 'Bone_008', 'Bone_009', 'Bone_010'}
def grp(n):
    if n in TORSO: return 'torso'
    if n.endswith('Arm') and 'Shoulder' not in n or n.endswith('ForeArm') or n.endswith('Hand'): return 'arm'
    return 'other'
before = np.array([me.matrix_world @ v.co for v in me.data.vertices])
bm = bmesh.new(); bm.from_mesh(me.data); bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table(); dl = bm.verts.layers.deform.verify()
def dom(v): w = dict(v[dl].items()); return max(w, key=w.get) if w else None
zlow = lambda v: (me.matrix_world @ v.co).z < ZMAX
vside = {v.index: (grp(names[dom(v)]) if dom(v) is not None and zlow(v) else 'other') for v in bm.verts}
strad = {}
for f in bm.faces:
    ss = [vside[v.index] for v in f.verts]
    if 'arm' in ss and 'torso' in ss:
        m = {'arm': 0.0, 'torso': 0.0}
        for v in f.verts:
            for gi, w in v[dl].items():
                g = grp(names[gi]); 
                if g in m: m[g] += w
        strad[f.index] = 'arm' if m['arm'] >= m['torso'] else 'torso'
orig = {fi: bm.faces[fi] for fi in strad}; old = []; jobs = []
for fi, sd in strad.items():
    f = orig[fi]; res = bmesh.ops.duplicate(bm, geom=[f] + list(f.verts) + list(f.edges)); jobs.append(([e for e in res['geom'] if isinstance(e, bmesh.types.BMFace)][0], sd)); old.append(f)
fb = 0
for nf, sd in jobs:
    bad = 'torso' if sd == 'arm' else 'arm'; corners = list(nf.verts)
    for v in corners:
        keep = {gi: x for gi, x in v[dl].items() if grp(names[gi]) != bad}
        if not keep:
            fb += 1; s = next((u for u in corners if any(grp(names[gi]) != bad for gi in u[dl].keys())), None); keep = {gi: x for gi, x in s[dl].items() if grp(names[gi]) != bad} if s else dict(v[dl].items())
        t = sum(keep.values()); v[dl].clear()
        for gi, x in keep.items(): v[dl][gi] = x / t
bmesh.ops.delete(bm, geom=old, context='FACES')
detached = {v.index for nf, _ in jobs if nf.is_valid for v in nf.verts}; rw = 0
for v in bm.verts:
    if not v.is_valid or v.index in detached or not zlow(v): continue
    w = dict(v[dl].items())
    if not w: continue
    sd = grp(names[max(w, key=w.get)])
    if sd == 'other': continue
    bad = 'torso' if sd == 'arm' else 'arm'; keep = {gi: x for gi, x in w.items() if grp(names[gi]) != bad}
    if len(keep) == len(w): continue
    t = sum(keep.values()); v[dl].clear()
    for gi, x in keep.items(): v[dl][gi] = x / t
    rw += 1
bm.to_mesh(me.data); bm.free(); me.data.update()
after = np.array([me.matrix_world @ v.co for v in me.data.vertices])
bad_norm = sum(abs(sum(g.weight for g in v.groups) - 1) > 1e-4 for v in me.data.vertices); maxinf = max(len(v.groups) for v in me.data.vertices)
r = {'zmax': ZMAX, 'straddling_triangles_detached': len(jobs), 'sides': {k: sum(1 for s in strad.values() if s == k) for k in ('arm', 'torso')}, 'reweighted_vertices': rw, 'weight_fallbacks': fb,
     'verts_before': len(before), 'verts_after': len(after), 'triangles': len(me.data.polygons), 'verts_not_normalised': int(bad_norm), 'max_influences': int(maxinf),
     'rest_point_set_change_mm': float(max(cKDTree(before).query(after)[0].max(), cKDTree(after).query(before)[0].max()) * 1000)}
json.dump(r, open(rep, 'w'), indent=1); print(json.dumps(r, indent=1)); bpy.ops.wm.save_as_mainfile(filepath=dst)
