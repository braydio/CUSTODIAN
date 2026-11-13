import bpy, os, math
from mathutils import Vector
OUT = os.environ["CRECHE_OUT"]
bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, "creche_assembled.blend"))
scene = bpy.context.scene
for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        scene.render.engine = eng
        break
    except TypeError:
        pass
scene.render.resolution_x, scene.render.resolution_y = 960, 704
scene.render.image_settings.file_format = "PNG"
cam = bpy.data.cameras.new("RenderCam")
camo = bpy.data.objects.new("RenderCam", cam)
scene.collection.objects.link(camo)
scene.camera = camo
sun = bpy.data.lights.new("RenderSun", "SUN"); sun.energy = 3.0
sunobj = bpy.data.objects.new("RenderSun", sun); scene.collection.objects.link(sunobj)
sunobj.rotation_euler = (math.radians(50), 0, math.radians(30))

# top-down orthographic, 30 m horizontal span, centered (0,0)
cam.type = "ORTHO"; cam.ortho_scale = 30.0
camo.location = (0, 0, 40); camo.rotation_euler = (0, 0, 0)
scene.render.filepath = os.path.join(OUT, "creche_topdown_render.png")
bpy.ops.render.render(write_still=True)

# elevated game-style perspective from the south-east
cam.type = "PERSP"; cam.lens = 35
camo.location = (9.0, -20.0, 11.0)
direction = Vector((0, 0, 2.0)) - camo.location
camo.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
scene.render.filepath = os.path.join(OUT, "creche_elevated_render.png")
bpy.ops.render.render(write_still=True)
print("RENDER_OK")
