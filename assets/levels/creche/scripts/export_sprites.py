"""Export one transparent full-frame sprite per placed socket from the assembled Creche.

Every sprite uses the same elevated camera and the same 960x704 frame, so the
Godot 2D scene can stack them at the origin without projection math. Sprites
are drawn back to front by socket depth (Y, then Z) in the manifest order.
"""
import bpy
import json
import math
import os
from mathutils import Vector

ASSEMBLY = os.environ["CRECHE_ASSEMBLY"]
SPRITE_DIR = os.environ["CRECHE_SPRITE_DIR"]

bpy.ops.wm.open_mainfile(filepath=os.path.join(ASSEMBLY, "creche_assembled.blend"))
scene = bpy.context.scene
for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        scene.render.engine = eng
        break
    except TypeError:
        pass
scene.render.resolution_x, scene.render.resolution_y = 960, 704
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"

cam = bpy.data.cameras.new("SpriteCam")
cam.type = "PERSP"
cam.lens = 35
camo = bpy.data.objects.new("SpriteCam", cam)
scene.collection.objects.link(camo)
scene.camera = camo
camo.location = (9.0, -20.0, 11.0)
camo.rotation_euler = (Vector((0, 0, 2.0)) - camo.location).to_track_quat("-Z", "Y").to_euler()

sun = bpy.data.lights.new("SpriteSun", "SUN")
sun.energy = 3.0
sunobj = bpy.data.objects.new("SpriteSun", sun)
scene.collection.objects.link(sunobj)
sunobj.rotation_euler = (math.radians(50), 0, math.radians(30))

manifest = json.load(open(os.path.join(ASSEMBLY, "placement_manifest.json")))
placed = [r for r in manifest if r["status"] == "PLACED_UNIFORM_FIT"]
placed.sort(key=lambda r: (r["center_m"][1], r["center_m"][2]))

os.makedirs(SPRITE_DIR, exist_ok=True)
original_hide = {o.name: o.hide_render for o in bpy.data.objects}
out = []
for rec in placed:
    sid = rec["socket"]
    for o in bpy.data.objects:
        if o.name == camo.name or o.name == sunobj.name:
            continue
        owned = o.name.startswith(sid + "__") or o.name == "SOCKET_" + sid
        o.hide_render = not owned
    path = os.path.join(SPRITE_DIR, sid + ".png")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    out.append({"socket": sid, "sprite": os.path.basename(path),
                "source_glb": rec["source_glb"], "source_sha256": rec["source_sha256"],
                "translation_m": rec["translation_m"], "uniform_scale": rec["uniform_scale"],
                "repeat_count": rec["repeat_count"], "depth_order": len(out)})

for o in bpy.data.objects:
    if o.name in original_hide:
        o.hide_render = original_hide[o.name]
json.dump(out, open(os.path.join(SPRITE_DIR, "sprite_manifest.json"), "w"), indent=2)
print("SPRITES_OK", len(out))
