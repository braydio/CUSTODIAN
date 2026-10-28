"""Task 015 animated GLB export and clean-scene replay verification.
Usage: blender -b <run_iter002.blend> --python export_verify_run_iter002.py -- <out.glb> <report.json>
"""
import bpy,sys,json,os,hashlib
import numpy as np
from mathutils import Matrix
from scipy.spatial import cKDTree
glb,report=sys.argv[sys.argv.index('--')+1:]
sc=bpy.context.scene
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE'); me=next(o for o in bpy.data.objects if o.type=='MESH' and len(o.vertex_groups)); act=arm.animation_data.action
frames=range(1,22); ref=[]
def verts(a,m):
 dg=bpy.context.evaluated_depsgraph_get(); ev=m.evaluated_get(dg); em=ev.to_mesh(); v=np.array([m.matrix_world@x.co for x in em.vertices]); ev.to_mesh_clear(); return v
for f in frames: sc.frame_set(f); ref.append(verts(arm,me))
sc.frame_set(1); bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); me.select_set(True); bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=glb,export_format='GLB',use_selection=True,export_animations=True,export_skins=True,export_yup=True,export_frame_range=True,export_force_sampling=True,export_image_format='AUTO')
sha=hashlib.sha256(open(glb,'rb').read()).hexdigest(); size=os.path.getsize(glb)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb); sc=bpy.context.scene
arms=[o for o in bpy.data.objects if o.type=='ARMATURE']; meshes=[o for o in bpy.data.objects if o.type=='MESH' and len(o.vertex_groups)]
if len(arms)!=1 or len(meshes)!=1: raise RuntimeError(f'expected 1 armature+mesh; got {len(arms)} {len(meshes)}')
a,m=arms[0],meshes[0]; fps=sc.render.fps/sc.render.fps_base; acts=list(bpy.data.actions)
if not acts: raise RuntimeError('GLB reimport has no animation action')
act2=acts[0]; start,end=act2.frame_range; diffs=[]; sample_times=[]
for i,rv in enumerate(ref):
 t=i/30.0; fr=start+t*fps; lo=int(np.floor(fr)); sc.frame_set(lo,subframe=fr-lo); pv=verts(a,m); d=cKDTree(pv).query(rv)[0]*1000; diffs.append({'frame':i+1,'time_s':t,'max_nearest_vertex_mm':float(d.max()),'p99_mm':float(np.percentile(d,99))}); sample_times.append(fr)
# Loop endpoint frame 22 corresponds 21/30s; compare endpoint to first within same imported animation.
fr=start+21/30.0*fps; lo=int(np.floor(fr)); sc.frame_set(lo,subframe=fr-lo); endv=verts(a,m); fr=start; lo=int(np.floor(fr)); sc.frame_set(lo,subframe=fr-lo); firstv=verts(a,m); seam=cKDTree(firstv).query(endv)[0]*1000
bad=sum(abs(sum(g.weight for g in v.groups)-1)>1e-3 for v in m.data.vertices); maxinf=max(len(v.groups) for v in m.data.vertices)
out={'glb_sha256':sha,'glb_bytes':size,'action_name':act2.name,'action_frame_range':[float(start),float(end)],'import_fps':fps,'duration_s':(end-start)/fps,'frames_sampled':len(ref),'frame_samples':diffs,'max_sample_vertex_delta_mm':max(x['max_nearest_vertex_mm'] for x in diffs),'max_p99_delta_mm':max(x['p99_mm'] for x in diffs),'loop_seam_max_delta_mm':float(seam.max()),'bones':len(a.data.bones),'mesh_vertices':len(m.data.vertices),'mesh_triangles':len(m.data.polygons),'weights_not_normalized':int(bad),'max_influences':int(maxinf),'uv_layers':[u.name for u in m.data.uv_layers],'materials':[x.name for x in m.data.materials],'images':{x.name:list(x.size) for x in bpy.data.images}}
json.dump(out,open(report,'w'),indent=2); print(json.dumps(out,indent=2))
