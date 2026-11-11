"""Numerical root-motion audit (no rendering) for one derived action.

Replays the renderer's horizontal-root-removal step on every sample frame and records:
  - authored Hips world position (metres), before removal
  - the XY correction applied, and the post-correction residual
  - posed mesh centroid and vertical extents, before and after removal
  - lowest mesh point (foot-contact proxy) per frame

Run: blender -b --factory-startup --python root_motion_audit.py -- DERIVED.glb ACTION FPS OUT.json
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
derived, action_name, fps, out = Path(argv[0]), argv[1], int(argv[2]), Path(argv[3])
ROOT = "Hips"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps = fps
bpy.ops.import_scene.gltf(filepath=str(derived))
bpy.context.view_layer.update()
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE" and len(o.data.bones) > 0)
mesh = next(o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm)
act = next(a for a in bpy.data.actions if a.name == action_name) if any(a.name == action_name for a in bpy.data.actions) else max(bpy.data.actions, key=lambda x: x.frame_range[1] - x.frame_range[0])
if arm.animation_data is None:
    arm.animation_data_create()
arm.animation_data.action = act
if act.slots and hasattr(arm.animation_data, "action_slot"):
    arm.animation_data.action_slot = act.slots[0]

pb = arm.pose.bones[ROOT]
rest_head = arm.data.bones[ROOT].head_local.copy()
rot_inv = arm.data.bones[ROOT].matrix_local.to_3x3().inverted()
t0, t1 = act.frame_range
n = int(round((t1 - t0) * fps / bpy.context.scene.render.fps))
frames = [t0 + k * (bpy.context.scene.render.fps / fps) for k in range(n)]


def mesh_world_points():
    ev = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    me = ev.to_mesh()
    pts = [arm.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    return pts


rows = []
for k, f in enumerate(frames):
    bpy.context.scene.frame_set(int(math.floor(f)), subframe=f - math.floor(f))
    bpy.context.view_layer.update()
    head_arm = Vector(pb.head)
    hips_world = arm.matrix_world @ head_arm
    pre = mesh_world_points()
    delta_arm = Vector((rest_head.x - head_arm.x, rest_head.y - head_arm.y, 0.0))
    pb.location += rot_inv @ delta_arm
    bpy.context.view_layer.update()
    residual = Vector(pb.head) - Vector((rest_head.x, rest_head.y, pb.head.z))
    post = mesh_world_points()

    def stats(pts):
        cx = sum(p.x for p in pts) / len(pts)
        cy = sum(p.y for p in pts) / len(pts)
        cz = sum(p.z for p in pts) / len(pts)
        zmin = min(p.z for p in pts)
        return {"centroid_xy_m": [round(cx, 5), round(cy, 5)], "centroid_z_m": round(cz, 5),
                "min_z_m": round(zmin, 5), "max_z_m": round(max(p.z for p in pts), 5),
                "max_xy_radius_m": round(max(math.hypot(p.x, p.y) for p in pts), 5),
                "min_z_vertex_count": sum(1 for p in pts if p.z - zmin < 0.01)}
    rows.append({"sample": k, "time_s": round((f - t0) / fps, 6),
                 "hips_world_m": [round(x, 5) for x in hips_world],
                 "xy_correction_arm_units": [round(x, 6) for x in delta_arm],
                 "residual_xy_arm_units": round(residual.length, 9),
                 "pre": stats(pre), "post": stats(post)})

out.write_text(json.dumps({"derived": str(derived), "action": act.name, "fps": fps, "samples": len(rows), "root": ROOT, "rows": rows}, indent=1) + "\n")
print("AUDIT_DONE", act.name, len(rows))
