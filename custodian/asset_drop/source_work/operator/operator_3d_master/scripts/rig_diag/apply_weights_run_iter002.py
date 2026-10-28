"""Task 015: write the planned per-vertex weights (repair_plan_run_iter002.py output) into a COPY of the run blend. Geometry, UVs, materials, rig and action untouched; no faces deleted.
usage: blender -b --python apply_weights_run_iter002.py -- <src.blend> <edits.npz> <dst.blend> <report.json>"""
import bpy, sys, json, numpy as np, bmesh
src, ed, dst, rep = sys.argv[sys.argv.index('--') + 1:][:4]
bpy.ops.wm.open_mainfile(filepath=src); Z = np.load(ed); W, ch = Z['W'], Z['changed']
me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]; m = me.data; nv, nt, nl = len(m.vertices), len(m.polygons), len(m.loops)
co0 = np.array([v.co[:] for v in m.vertices]); bm = bmesh.new(); bm.from_mesh(m); bm.verts.ensure_lookup_table(); dl = bm.verts.layers.deform.verify()
for vi in ch:
    v = bm.verts[int(vi)]; v[dl].clear()
    for gi in np.nonzero(W[vi] > 0)[0]: v[dl][int(gi)] = float(W[vi][gi])
bm.to_mesh(m); bm.free(); m.update()
co1 = np.array([v.co[:] for v in m.vertices]); gnames = [g.name for g in me.vertex_groups]
bad = sum(abs(sum(g.weight for g in v.groups) - 1) > 1e-4 for v in m.vertices); mi = max(len(v.groups) for v in m.vertices)
r = {'verts': nv, 'tris': nt, 'loops': nl, 'weights_written_for_vertices': int(len(ch)), 'rest_position_change_mm_max': float(np.abs(co1 - co0).max() * 1000), 'verts_not_normalised': int(bad), 'max_influences': int(mi), 'groups': len(gnames)}
json.dump(r, open(rep, 'w'), indent=1); print('APPLY', json.dumps(r)); bpy.ops.wm.save_as_mainfile(filepath=dst)
