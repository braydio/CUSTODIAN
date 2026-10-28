import bpy,sys,json,numpy as np
from mathutils import Vector
glb=sys.argv[sys.argv.index('--')+1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
arm=[o for o in bpy.data.objects if o.type=='ARMATURE'][0]; me=[o for o in bpy.data.objects if o.type=='MESH'][0]
print('ARM',arm.name,'scale',tuple(arm.scale),'rot',tuple(arm.rotation_euler),'MESH',me.name,'parent',me.parent.name if me.parent else None,'mscale',tuple(me.scale))
M=arm.matrix_world
for b in arm.data.bones:
    h=M@b.head_local;t=M@b.tail_local
    print('%-24s par=%-22s len=%.3f head=(%.3f,%.3f,%.3f) deform=%s'%(b.name,b.parent.name if b.parent else '-',(t-h).length,h.x,h.y,h.z,b.use_deform))
print('vgroups',len(me.vertex_groups),'mods',[m.type for m in me.modifiers])
