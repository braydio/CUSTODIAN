import bpy, math, sys
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[sys.argv.index('--')+1])
o=[x for x in bpy.data.objects if x.type=='MESH'][0]; bpy.context.view_layer.update()
pts=[o.matrix_world@Vector(c) for c in o.bound_box]; mnz=min(p.z for p in pts); cx=(min(p.x for p in pts)+max(p.x for p in pts))/2; cy=(min(p.y for p in pts)+max(p.y for p in pts))/2
o.location += Vector((-cx,-cy,-mnz)); bpy.context.view_layer.update()
pass
bpy.ops.object.shade_smooth() if False else None
sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE'; sc.render.film_transparent=True; sc.render.image_settings.file_format='PNG'; sc.render.image_settings.color_mode='RGBA'
w=bpy.data.worlds.new('w'); w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(.45,.45,.5,1); w.node_tree.nodes['Background'].inputs[1].default_value=.8; sc.world=w
az={'N':180,'NE':-135,'E':-90,'SE':-45,'S':0,'SW':45,'W':90,'NW':135}; EL=math.radians(45)
sun=bpy.data.objects.new('sun',bpy.data.lights.new('sun','SUN')); sun.data.energy=3.0; sc.collection.objects.link(sun)
cam=bpy.data.objects.new('cam',bpy.data.cameras.new('cam')); cam.data.type='ORTHO'; sc.collection.objects.link(cam); sc.camera=cam
for px,res in ((50,512),(50,128)):
    cam.data.ortho_scale=128/px; cam.data.shift_y=(106-64)/128; sc.render.resolution_x=sc.render.resolution_y=res; sc.render.filter_size=0.0 if res==128 else 1.5
    for d,a in az.items():
        r=math.radians(a); cam.location=(10*math.sin(r)*math.cos(EL),-10*math.cos(r)*math.cos(EL),10*math.sin(EL))
        cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler()
        sun.rotation_euler=(math.radians(50),0,r+math.radians(-35)); 
        sc.render.filepath=f'/tmp/claude-1000/-home-braydenchaffee-Projects-CUSTODIAN/15be8ace-6e52-46fd-9d3e-0f65dc494c58/scratchpad/meshy3_out/{res}_{d}.png'; bpy.ops.render.render(write_still=True)
print('DONE')
