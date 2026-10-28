"""Task 015 Phase 2 planner (numpy, no Blender): weight-only repair, NO faces deleted, rest geometry untouched.
 (1) fragment patches: each proven floating triangle (frag_tris.json) is re-anchored to the surface it sits on: its vertices copy the full weight vector of the position-welded
     (rest, 0.01 mm) neighbour vertex on the majority-twin bone, so it rides with its neighbours instead of tearing away.
 (2) boundary stretch: edges still >STRETCH_MAX x in any frame get both endpoints (+ their welded UV-seam twins, never patch verts) averaged; iterated, <=MAXI influences kept.
usage: repair_plan_run_iter002.py <base.npz (dump_mesh_motion)> <frag_tris.json> <out_edits.npz> <report.json>"""
import sys, json, numpy as np
from collections import Counter, defaultdict
Z = np.load(sys.argv[1]); rest, T, E, W0, G, K, BN = Z['rest'], Z['tris'], Z['edges'], Z['W'].copy(), list(Z['groups']), Z['K'], list(Z['bone_names'])
frag = json.load(open(sys.argv[2])); out, rep = sys.argv[3], sys.argv[4]; STRETCH_MAX, MAXI = 3.0, int(max((Z['W'] > 0).sum(1)))
idx = [BN.index(g) for g in G]; H = np.concatenate([rest, np.ones((len(rest), 1))], 1)
def lbs(W):
    out_ = np.zeros((K.shape[0], len(rest), 3))
    for gi in range(len(G)):
        m = W[:, gi] > 0
        if m.any(): out_[:, m] += W[m, gi][None, :, None] * np.einsum('fij,vj->fvi', K[:, idx[gi]], H[m])[..., :3]
    return out_
L0 = np.linalg.norm(rest[E[:, 0]] - rest[E[:, 1]], axis=1)
def ratios(P): return np.linalg.norm(P[:, E[:, 0]] - P[:, E[:, 1]], axis=2) / L0
par = list(range(len(rest)))
def fd(x):
    while par[x] != x: par[x] = par[par[x]]; x = par[x]
    return x
for t in T:
    for u in t[1:]: par[fd(u)] = fd(t[0])
vcomp = np.array([fd(i) for i in range(len(rest))]); used = np.zeros(len(rest), bool); used[T.ravel()] = True
csz = Counter(vcomp[T[:, 0]]); patchv = np.zeros(len(rest), bool)      # index-isolated single-triangle components = detached patches
for t in T:
    if csz[vcomp[t[0]]] == 1: patchv[t] = True
wid = {}; W_ID = np.array([wid.setdefault(tuple(p), len(wid)) for p in np.round(rest * 1e5).astype(np.int64)]); byw = defaultdict(list)
for i, w in enumerate(W_ID):
    if used[i]: byw[w].append(i)
dom = np.argmax(W0, 1)
P0 = lbs(W0); R0 = ratios(P0); r = {'before': {'max_edge_stretch': float(R0.max()), 'edges_gt3_ever': int((R0.max(0) > 3).sum()), 'max_gt3_per_frame': int((R0 > 3).sum(1).max())}}
def tear(W, P, verts):
    d = []
    for v in verts:
        tw = [u for u in byw[W_ID[v]] if vcomp[u] != vcomp[v]]
        d.append(min((np.linalg.norm(P[:, v] - P[:, u], axis=1).max() for u in tw), default=0.0))
    return np.array(d) * 1000
# ---- (1) fragment patch re-anchoring
srcmap = {}; W = W0.copy(); fv = sorted({int(v) for t in frag for v in T[t]}); log1 = []; changed = set()
body = np.where(used & ~patchv)[0]          # anchors are ordinary (non-patch) body vertices only, so no anchor is itself re-weighted
for t in frag:
    vs = [int(v) for v in T[t]]; twins = {v: [u for u in byw[W_ID[v]] if not patchv[u]] for v in vs}
    bones = Counter(int(dom[u]) for v in vs for u in twins[v])
    if bones: anchor = bones.most_common(1)[0][0]; aset = np.array([u for v in vs for u in twins[v] if dom[u] == anchor], int)
    else:   # no welded body vertex at all: nearest body vertex to the triangle centroid defines the anchor surface
        c = rest[vs].mean(0); nb = body[np.argsort(np.linalg.norm(rest[body] - c, axis=1))[:6]]; anchor = int(Counter(int(dom[u]) for u in nb).most_common(1)[0][0]); aset = np.array([u for u in nb if dom[u] == anchor], int); bones = Counter({anchor: len(aset)})
    for v in vs:
        cand = [u for u in twins[v] if dom[u] == anchor]
        src = cand[0] if cand else int(aset[np.argmin(np.linalg.norm(rest[aset] - rest[v], axis=1))])
        W[v] = W0[src]; changed.add(v); srcmap[v] = src
    log1.append({'tri': int(t), 'anchor_bone': G[anchor], 'twin_votes': {G[b]: c for b, c in bones.most_common(3)}})
P1 = lbs(W); sv = np.array(sorted(srcmap)); ss = np.array([srcmap[v] for v in sv])
tb = np.linalg.norm(P0[:, sv] - P0[:, ss], axis=2).max(0) * 1000; ta = np.linalg.norm(P1[:, sv] - P1[:, ss], axis=2).max(0) * 1000; rd = np.linalg.norm(rest[sv] - rest[ss], axis=1) * 1000
r['patch_step'] = {'fragment_tris': len(frag), 'vertices_reweighted': len(changed), 'anchor_vertex_max_separation_mm_before_p50_p90_max': [float(np.median(tb)), float(np.percentile(tb, 90)), float(tb.max())],
    'anchor_vertex_max_separation_mm_after_p50_p90_max': [float(np.median(ta)), float(np.percentile(ta, 90)), float(ta.max())], 'rest_distance_to_anchor_vertex_mm_max': float(rd.max()),
    'anchor_bone_hist': dict(Counter(x['anchor_bone'] for x in log1 if 'anchor_bone' in x))}
# ---- (2) boundary stretch: cluster-mean harmonisation of vertices on edges >STRETCH_MAX (patch edges: the patch's own verts only; others: + welded UV-seam twins)
edited = set(); it_log = []
for it in range(8):
    P = lbs(W); R = ratios(P); bad = np.where((R.max(0) > STRETCH_MAX) & (L0 > 0))[0]
    it_log.append({'iter': it, 'edges_gt3': int(len(bad)), 'max': float(R.max())})
    if not len(bad): break
    cp = {}
    def cf(x):
        cp.setdefault(x, x)
        while cp[x] != x: cp[x] = cp[cp[x]]; x = cp[x]
        return x
    for e in bad:
        a, b = E[e]; mem = [{a, b}] if (patchv[a] or patchv[b]) else [{u for v in (a, b) for u in byw[W_ID[v]] if not patchv[u]}]
        m = sorted(mem[0]); [cp.__setitem__(cf(u), cf(m[0])) for u in m]
    cl = defaultdict(set)
    for x in list(cp): cl[cf(x)].add(x)
    for g in cl.values():
        g = sorted(g); avg = W[g].mean(0); k = np.argsort(-avg)[:MAXI]; w = np.zeros_like(avg); w[k] = avg[k]; w /= w.sum()
        for u in g: W[u] = w; edited.add(u)
P2 = lbs(W); R2 = ratios(P2); r['stretch_step'] = {'iterations': it_log, 'vertices_edited': len(edited)}
r['after'] = {'max_edge_stretch': float(R2.max()), 'edges_gt3_ever': int((R2.max(0) > 3).sum()), 'max_gt3_per_frame': int((R2 > 3).sum(1).max()), 'p99_9_max_over_frames': float(np.percentile(R2, 99.9, axis=1).max()),
    'rest_max_abs_weight_sum_err': float(np.abs(W.sum(1) - 1).max()), 'max_influences': int((W > 0).sum(1).max())}
allch = sorted(changed | edited); r['changed_vertices'] = len(allch); r['changed_vertex_indices'] = [int(x) for x in allch]; r['patch_log'] = log1
np.savez_compressed(out, W=W.astype(np.float32), changed=np.array(allch)); json.dump(r, open(rep, 'w'), indent=1)
print(json.dumps({k: r[k] for k in ('before', 'patch_step', 'after', 'changed_vertices')}, indent=1)); print(r['stretch_step'])
