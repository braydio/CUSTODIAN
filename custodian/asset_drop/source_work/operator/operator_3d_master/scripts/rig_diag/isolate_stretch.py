"""Task 013: classify every >3x edge on the fixed (Task 012) derivative under synthetic P1/P3.
usage: blender -b --python isolate_stretch.py -- <glb> <outdir>"""
import bpy, sys, os, json, math, importlib.util
import numpy as np
from collections import Counter, defaultdict
from mathutils import Matrix
glb, out = sys.argv[sys.argv.index('--') + 1:][:2]
os.makedirs(out, exist_ok=True)
sp = importlib.util.spec_from_file_location('pose_proof', os.path.join(os.path.dirname(__file__), 'pose_proof.py'))
pp = importlib.util.module_from_spec(sp); sp.loader.exec_module(pp); pp.glb = glb; pp.out = out

arm, me = pp.load(); pp.reparent(arm); bpy.context.view_layer.update()
rest = pp.verts(me); nv = len(rest)
edges = np.array([e.vertices[:] for e in me.data.edges]); L0 = np.linalg.norm(rest[edges[:, 0]] - rest[edges[:, 1]], axis=1)
vg = [g.name for g in me.vertex_groups]
W = [{vg[g.group]: g.weight for g in v.groups if g.weight > 1e-4} for v in me.data.vertices]
dom = [max(w, key=w.get) for w in W]
def part(b):
    for k, t in (('hand', ('Hand', 'Bone_027', 'Bone_023', 'Bone_022', 'Bone_028', 'Bone_018', 'Bone_017')), ('thigh', ('UpLeg', 'Bone_005', 'Bone_004', 'Bone_007', 'Bone_006', 'Bone_012', 'Bone_011'))):
        if any(x in b for x in t): return k
    return 'other'
# components (edge-connected) and position-welded components
def comps(keyfn):
    par = list(range(nv))
    def f(x):
        while par[x] != x: par[x] = par[par[x]]; x = par[x]
        return x
    for a, b in edges: par[f(keyfn(a))] = f(keyfn(b))
    return [f(keyfn(i)) for i in range(nv)]
cid = comps(lambda i: i)
q = {}; pk = [q.setdefault(tuple(np.round(rest[i], 5)), i) for i in range(nv)]
wid = comps(lambda i: pk[i])
res = {'verts': nv, 'edges': len(edges), 'edge_components': len(set(cid)), 'position_welded_components': len(set(wid)),
       'unique_positions': len(set(pk)), 'min_rest_edge_mm': float(L0.min() * 1000), 'zero_len_edges(<0.01mm)': int((L0 < 1e-5).sum())}
# seam duplicates: same position, different dominant/weights
byp = defaultdict(list)
for i in range(nv): byp[pk[i]].append(i)
dups = [v for v in byp.values() if len(v) > 1]
def wdiff(a, b): return sum(abs(W[a].get(k, 0) - W[b].get(k, 0)) for k in set(W[a]) | set(W[b]))
res['coincident_position_groups'] = len(dups); res['coincident_groups_with_weight_mismatch(>0.05)'] = sum(1 for v in dups if max(wdiff(v[0], x) for x in v[1:]) > 0.05)
# hand-thigh rest adjacency
pr = np.array([[part(dom[a]), part(dom[b])] for a, b in edges])
res['rest_edges_hand_to_thigh'] = int(sum(1 for a, b in pr if {a, b} == {'hand', 'thigh'}))

def posed(name):
    pp.pose(arm, pp.POSES[name]); v = pp.verts(me); pp.pose(arm, []); return v
def ratios(v): return np.linalg.norm(v[edges[:, 0]] - v[edges[:, 1]], axis=1) / (L0 + 1e-12)
records = []; summary = {}
for pname in ('P1_arms_elbows', 'P3_wrists'):
    v = posed(pname); r = ratios(v); idx = np.where(r > 3)[0]
    cat = Counter()
    for e in idx:
        a, b = edges[e]
        wa, wb = W[a], W[b]
        pa, pb = part(dom[a]), part(dom[b])
        mixed = lambda w: sum(x for k, x in w.items() if part(k) == 'thigh') > .2 and sum(x for k, x in w.items() if part(k) == 'hand') > .2
        shared = set(wa) & set(wb)
        wmism = wdiff(a, b)
        d_mm = (np.linalg.norm(v[a] - v[b]) - L0[e]) * 1000
        # single-bone attribution: which bones, when rotated alone, stretch this edge >1.5x
        if L0[e] * 1000 < 2.0 and abs(d_mm) < 20: c = 'b_tiny_rest_edge_ratio_artifact'
        elif {pa, pb} == {'hand', 'thigh'} and wmism < .3: c = 'a_topological_bridge_hand_thigh_distinct_weights' if False else 'a_bridge_across_parts'
        elif mixed(wa) or mixed(wb): c = 'c_mixed_hand_thigh_weights_on_endpoint'
        elif pa == pb and wmism < .05: c = 'd_same_weights_pose_magnitude'
        else: c = 'c_weight_mismatch_between_endpoints'
        cat[c] += 1
        records.append({'pose': pname, 'edge': int(e), 'v': [int(a), int(b)], 'rest_len_mm': round(float(L0[e] * 1000), 3), 'posed_len_mm': round(float(np.linalg.norm(v[a] - v[b]) * 1000), 1), 'ratio': round(float(r[e]), 2), 'delta_mm': round(float(d_mm), 1),
                        'rest_pos_a': rest[a].round(4).tolist(), 'rest_pos_b': rest[b].round(4).tolist(), 'component_a': int(cid[a]), 'component_b': int(cid[b]), 'same_position_welded_component': wid[a] == wid[b],
                        'weights_a': {k: round(x, 3) for k, x in sorted(wa.items(), key=lambda t: -t[1])}, 'weights_b': {k: round(x, 3) for k, x in sorted(wb.items(), key=lambda t: -t[1])},
                        'weight_L1_mismatch': round(wmism, 3), 'cause': c})
    summary[pname] = {'edges_gt3x': int(len(idx)), 'by_cause': dict(cat), 'max_ratio': float(r.max()), 'max_delta_mm': float(max(x['delta_mm'] for x in records if x['pose'] == pname)) if len(idx) else 0}
res['summary'] = summary
# face-level: triangles that straddle hand-part and thigh-part (by dominant bone), rest area
tris = np.array([p.vertices[:] for p in me.data.polygons]); assert tris.shape[1] == 3
area = lambda t: 0.5 * np.linalg.norm(np.cross(rest[t[1]] - rest[t[0]], rest[t[2]] - rest[t[0]]))
tot_area = sum(area(t) for t in tris)
strad = [i for i, t in enumerate(tris) if {part(dom[v]) for v in t} >= {'hand', 'thigh'}]
sa = sum(area(tris[i]) for i in strad)
sel = {int(i) for i in strad}
le = [max(np.linalg.norm(rest[tris[i][a]] - rest[tris[i][b]]) for a, b in ((0, 1), (1, 2), (2, 0))) * 1000 for i in strad]
mixv = [i for i in range(nv) if any(part(k) == 'hand' and x > .2 for k, x in W[i].items()) and any(part(k) == 'thigh' and x > .2 for k, x in W[i].items())]
res['faces'] = {'triangles': len(tris), 'straddling_hand_thigh_triangles': len(strad), 'straddle_area_cm2': round(sa * 1e4, 2), 'total_area_cm2': round(tot_area * 1e4, 1),
    'straddle_area_pct': round(100 * sa / tot_area, 3), 'straddle_max_rest_edge_mm_range': [round(min(le), 1), round(max(le), 1)] if le else None, 'straddle_triangle_indices': [int(i) for i in strad[:60]],
    'verts_with_hand_and_thigh_weights_gt0.2': len(mixv), 'mixed_vert_indices': mixv[:60]}
of = {tuple(sorted(e)) for e in map(tuple, edges)}
cnt = Counter()
for rec in records:
    a, b = rec['v']; ta = {i for i in strad}; 
    in_strad = any((a in tris[i] and b in tris[i]) for i in strad)
    rec['edge_in_straddling_triangle'] = bool(in_strad); rec['endpoint_mixed_weights'] = a in set(mixv) or b in set(mixv)
    cnt[(rec['pose'], in_strad, rec['endpoint_mixed_weights'])] += 1
res['outlier_edges_by_(pose,in_straddle_tri,endpoint_mixed)'] = {str(k): v for k, v in cnt.items()}
# single-bone perturbation: stretch contributed by rotating ONE bone 30deg
sb = {}
for bone in [b.name for b in arm.data.bones if any(t in b.name for t in ('Hand', 'ForeArm', 'UpLeg', 'Arm', 'Bone_0'))]:
    pp.pose(arm, [(bone, 'X', 30)]); v = pp.verts(me); pp.pose(arm, [])
    r = ratios(v); big = np.where((r > 1.5) & (L0 > 2e-3))[0]
    sb[bone] = {'edges_gt1.5x_rest>2mm': int(len(big)), 'max_ratio_rest>2mm': round(float(r[L0 > 2e-3].max()), 2), 'max_edge_delta_mm': round(float(((np.linalg.norm(v[edges[:, 0]] - v[edges[:, 1]], axis=1) - L0) * 1000).max()), 1)}
res['single_bone_30deg'] = sb
json.dump(res, open(f'{out}/isolation_summary.json', 'w'), indent=1, default=lambda o: o.item() if hasattr(o, 'item') else str(o))
json.dump(records, open(f'{out}/outlier_edges.json', 'w'), default=lambda o: o.item() if hasattr(o, 'item') else str(o))
print(json.dumps({k: v for k, v in res.items() if k != 'single_bone_30deg'}, indent=1))
