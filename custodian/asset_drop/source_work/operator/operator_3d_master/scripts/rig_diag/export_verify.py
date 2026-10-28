"""Export iter-002 derivative as a rigged GLB (NO animation), re-import in a clean scene, verify skin/UV/material, replay P1-P5.
usage: blender -b --python export_verify.py -- <iter002.blend> <out.glb> <outdir>"""
import bpy, sys, os, json, importlib.util, hashlib
import numpy as np
blend, glb_out, out = sys.argv[sys.argv.index('--') + 1:][:3]; os.makedirs(out, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=blend)
src_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]; src_me = [o for o in bpy.data.objects if o.type == 'MESH' and len(o.vertex_groups)][0]
from mathutils import Matrix
for pb in src_arm.pose.bones: pb.matrix_basis = Matrix()
bpy.ops.object.select_all(action='DESELECT'); src_arm.select_set(True); src_me.select_set(True); bpy.context.view_layer.objects.active = src_arm
bpy.ops.export_scene.gltf(filepath=glb_out, export_format='GLB', use_selection=True, export_animations=False, export_skins=True, export_yup=True, export_image_format='AUTO')
h = hashlib.sha256(open(glb_out, 'rb').read()).hexdigest()
sys.path.insert(0, os.path.dirname(__file__))
sp = importlib.util.spec_from_file_location('pose_proof', os.path.join(os.path.dirname(__file__), 'pose_proof.py'))
pp = importlib.util.module_from_spec(sp); sp.loader.exec_module(pp); pp.glb = glb_out; pp.out = out
ref = json.load(open(os.path.join(os.path.dirname(blend), 'metrics_iter002.json')))['corrected']['poses']
pp.POSES['P5_modest_20_30deg'] = [('mixamorig:LeftArm', 'X', 25), ('mixamorig:RightArm', 'X', -25), ('mixamorig:LeftForeArm', 'X', 30), ('mixamorig:RightForeArm', 'X', 30),
    ('mixamorig:LeftHand', 'X', 25), ('mixamorig:LeftUpLeg', 'X', 25), ('mixamorig:RightUpLeg', 'X', -25), ('mixamorig:LeftLeg', 'X', -30), ('mixamorig:LeftFoot', 'X', 20)]
res, V, me, arm = pp.analyse('baseline')       # clean scene, re-imported exported GLB, NO further fixes applied
# structural checks on the re-import
bones = {b.name: (b.parent.name if b.parent else None) for b in arm.data.bones}
chk = {'glb_sha256': h, 'glb_bytes': os.path.getsize(glb_out), 'bones': len(bones), 'animations_in_blender': len(bpy.data.actions),
       'reparent_survived': {k: bones.get(k) for k in pp.FIXES}, 'reparent_expected': pp.FIXES}
bad = 0; maxinf = 0
for v in me.data.vertices:
    w = [g.weight for g in v.groups if g.weight > 0]; maxinf = max(maxinf, len(w)); bad += abs(sum(w) - 1) > 1e-3
chk.update({'verts': len(me.data.vertices), 'tris': len(me.data.polygons), 'verts_not_normalised': int(bad), 'max_influences': maxinf, 'uv_layers': [u.name for u in me.data.uv_layers],
            'materials': [m.name for m in me.data.materials], 'images': {i.name: list(i.size) for i in bpy.data.images}})
mat = me.data.materials[0]; chk['material_nodes'] = sorted({n.bl_idname for n in mat.node_tree.nodes}) if mat and mat.node_tree else None
chk['replay_vs_blend'] = {p: {'reexport_max': res['poses'][p]['edge_stretch_max'], 'blend_max': ref[p]['edge_stretch_max'], 'reexport_gt3x': res['poses'][p]['edges_gt3x'], 'blend_gt3x': ref[p]['edges_gt3x']} for p in ref if p in res['poses']}
chk['replay_boots_mean_disp'] = {p: d['region_mean_disp_m']['boots(z<0.10)'] for p, d in res['poses'].items()}
json.dump(chk, open(os.path.join(out, 'export_verify.json'), 'w'), indent=1, default=lambda o: o.item() if hasattr(o, 'item') else str(o)); print(json.dumps(chk, indent=1, default=str))
