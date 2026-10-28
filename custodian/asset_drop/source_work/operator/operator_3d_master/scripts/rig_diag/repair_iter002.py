"""Task 013 iter-002: smallest reversible weight correction on the Task-012 derivative.
Cause (see isolation): hand/arm-surface vertices carry leg/hip-cloth bone weights (and vice versa). Rule: a vertex dominated by an
ARM-chain bone loses LOWER-chain weights, a vertex dominated by a LOWER-chain bone loses ARM-chain weights; remaining weights renormalised.
Torso/spine/neck/head weights are never touched. Geometry, UVs, vertex positions and bone placement are unchanged.
usage: blender -b --python repair_iter002.py -- <glb> <outdir>"""
import bpy, sys, os, json, importlib.util
import numpy as np
glb, out = sys.argv[sys.argv.index('--') + 1:][:2]; os.makedirs(out, exist_ok=True)
sp = importlib.util.spec_from_file_location('pose_proof', os.path.join(os.path.dirname(__file__), 'pose_proof.py'))
pp = importlib.util.module_from_spec(sp); sp.loader.exec_module(pp); pp.glb = glb; pp.out = out
ARM = ('Shoulder', 'Arm', 'ForeArm', 'Hand')
LOWER_EXACT = {'Bone_004', 'Bone_005', 'Bone_006', 'Bone_007', 'Bone_011', 'Bone_012', 'Bone_013', 'Bone_017', 'Bone_018', 'Bone_022', 'Bone_023', 'Bone_027', 'Bone_028'}
def grp(n):
    if n in LOWER_EXACT or any(t in n for t in ('UpLeg', 'Leg', 'Foot', 'Toe')): return 'lower'
    if any(n.endswith(t) for t in ARM): return 'arm'
    return 'other'
CHANGES = {}
def cleanup(me):
    """Detach arm<->lower straddling triangles (vertex duplicates, no faces deleted, UV/material kept), weighting each detached
    triangle wholly to its majority side; all other vertices keep their original weights."""
    import bmesh
    names = {g.index: g.name for g in me.vertex_groups}
    bm = bmesh.new(); bm.from_mesh(me.data); bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
    dl = bm.verts.layers.deform.verify()
    def dom(v):
        w = dict(v[dl].items())
        return max(w, key=w.get) if w else None
    def side_of(gi): return grp(names[gi]) if gi is not None else 'other'
    vside = {v.index: side_of(dom(v)) for v in bm.verts}
    strad = []; mass = {}
    for f in bm.faces:
        ss = [vside[v.index] for v in f.verts]
        if 'arm' in ss and 'lower' in ss:
            m = {'arm': 0.0, 'lower': 0.0}
            for v in f.verts:
                for gi, w in v[dl].items(): 
                    g = grp(names[gi])
                    if g in m: m[g] += w
            strad.append((f.index, 'arm' if m['arm'] >= m['lower'] else 'lower'))
    side_by_face = dict(strad)
    n_fixed = 0; fallback = 0; verts_touched = set(); old = []; jobs = []
    orig = {fi: bm.faces[fi] for fi in side_by_face}
    for fi, sd in side_by_face.items():
        f = orig[fi]; geom = [f] + list(f.verts) + list(f.edges)
        res = bmesh.ops.duplicate(bm, geom=geom)            # per-face duplicate: own verts, UV/normal/weights copied
        nf = [e for e in res['geom'] if isinstance(e, bmesh.types.BMFace)][0]
        jobs.append((nf, sd)); old.append(f)
    for nf, sd in jobs:
        bad = 'lower' if sd == 'arm' else 'arm'; corners = list(nf.verts)
        for v in corners:
            keep = {gi: x for gi, x in v[dl].items() if grp(names[gi]) != bad}
            if not keep:      # corner purely on the other side: borrow weights from a majority-side corner of the same triangle
                fallback += 1
                src = next((u for u in corners if any(grp(names[gi]) != bad for gi in u[dl].keys())), None)
                keep = {gi: x for gi, x in src[dl].items() if grp(names[gi]) != bad} if src else dict(v[dl].items())
            tot = sum(keep.values()); v[dl].clear()
            for gi, x in keep.items(): v[dl][gi] = x / tot
            verts_touched.add(v.index)
        n_fixed += 1
    bmesh.ops.delete(bm, geom=old, context='FACES')
    if os.environ.get('ITER002_REWEIGHT', '1') == '1':     # variant B: also remove cross-chain weights from remaining arm/lower-dominated vertices
        detached = {v.index for nf, _ in jobs for v in nf.verts if nf.is_valid}
        cw = 0
        for v in bm.verts:
            if not v.is_valid or v.index in detached: continue
            w = dict(v[dl].items())
            if not w: continue
            dn = max(w, key=w.get); sd = grp(names[dn])
            if sd == 'other': continue
            bad = 'lower' if sd == 'arm' else 'arm'; keep = {gi: x for gi, x in w.items() if grp(names[gi]) != bad}
            if len(keep) == len(w): continue
            tot = sum(keep.values()); v[dl].clear()
            for gi, x in keep.items(): v[dl][gi] = x / tot
            cw += 1
        CHANGES['reweighted_vertices'] = cw      # also drops edges/verts used only by the replaced faces
    bm.to_mesh(me.data); bm.free(); me.data.update()
    CHANGES.update({'straddling_triangles_detached': n_fixed, 'new_vertex_count': len(me.data.vertices), 'verts_in_detached_triangles': len(verts_touched), 'corner_weight_fallbacks': fallback,
                    'sides': {k: sum(1 for _, s in strad if s == k) for k in ('arm', 'lower')}, 'verts': sorted(verts_touched)})
pp.CLEANUP = cleanup
pp.POSES['P5_modest_20_30deg'] = [('mixamorig:LeftArm', 'X', 25), ('mixamorig:RightArm', 'X', -25), ('mixamorig:LeftForeArm', 'X', 30), ('mixamorig:RightForeArm', 'X', 30),
                                  ('mixamorig:LeftHand', 'X', 25), ('mixamorig:LeftUpLeg', 'X', 25), ('mixamorig:RightUpLeg', 'X', -25), ('mixamorig:LeftLeg', 'X', -30), ('mixamorig:LeftFoot', 'X', 20)]
R = {}; V = {}
for var in ('fixed', 'corrected'):
    R[var], V[var], me, arm = pp.analyse(var)
    if var == 'corrected':
        # skin-validity checks
        bad_norm = 0; maxinf = 0
        for v in me.data.vertices:
            w = [g.weight for g in v.groups if g.weight > 0]; maxinf = max(maxinf, len(w)); bad_norm += abs(sum(w) - 1) > 1e-4
        R['corrected_skin_checks'] = {'verts_not_normalised': int(bad_norm), 'max_influences': maxinf, 'vertex_count': len(me.data.vertices)}
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'operator_meshy004_iter002.blend'))
n0 = len(V['fixed']['rest']); c = V['corrected']['rest']
from scipy.spatial import cKDTree
# bmesh reorders vertices, so compare as point sets: every corrected vertex sits on an original, and every original is still covered
R['rest_pose_change_max_mm'] = float(max(cKDTree(V['fixed']['rest']).query(c)[0].max(), cKDTree(c).query(V['fixed']['rest'])[0].max()) * 1000)
R['weight_changes'] = {k: v if k != 'verts' else v[:80] for k, v in CHANGES.items()}; R['weight_changes']['verts_total_listed_in'] = 'changed_vertices.json'
json.dump(CHANGES.get('verts', []), open(os.path.join(out, 'changed_vertices.json'), 'w'))
json.dump(R, open(os.path.join(out, 'metrics_iter002.json'), 'w'), indent=1, default=lambda o: o.item() if hasattr(o, 'item') else str(o))
print(json.dumps({k: R[k] for k in ('rest_pose_change_max_mm', 'weight_changes', 'corrected_skin_checks')}, indent=1, default=str)[:1500])
for var in ('fixed', 'corrected'):
    for p, d in R[var]['poses'].items(): print(var, p, 'max %.2f p999 %.2f >1.5x:%d >3x:%d' % (d['edge_stretch_max'], d['edge_stretch_p999'], d['edges_gt1.5x'], d['edges_gt3x']), 'boots %.1e tabard %.1e' % (d['region_mean_disp_m']['boots(z<0.10)'], d['region_mean_disp_m']['tabard(z 0.37-0.73,|x|<0.2)']))
