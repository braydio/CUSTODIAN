"""Batch renderer: one action on the verified master, eight independent 128px RGBA camera directions.

Run:
  blender -b --factory-startup --python render_operator.py -- \
      --action running --clip inputs/animations/running.glb --out output/raw --meta reports/render_running.json

Contract (full_body_8dir_128_v1):
  128x128 RGBA, transparent background, Eevee, 45 deg elevation, 50 px/m (ortho width 2.56 m),
  root (feet origin, world 0,0,0) at pixel (64,106), no mirroring, fixed camera zoom and lighting.

Direction convention (matches the verified turnaround angles): S=0, SE=45, E=90, NE=135,
N=180, NW=225, W=270, SW=315. Camera azimuth A places the camera at (-sin A, -cos A) horizontally, so
A=0 views the character's front (it faces -Y). Each direction is an independent camera render.

Root motion: horizontal (XY) translation of the Hips root bone is removed from the sprite pose and
recorded per sample in the metadata trajectory. Vertical bob stays in the pose.

Frames are sampled at 24 fps from the authored action range. Existing PNGs are skipped (resumable).
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
args = {"action": None, "clip": None, "out": None, "meta": None, "master": "inputs/character_master.glb", "fps": 24, "samples": 64, "ppm": 50.0, "canvas": 128, "root_mode": "object"}
i = 0
while i < len(argv):
    k = argv[i]
    if k in ("--action", "--clip", "--out", "--meta", "--master"):
        args[k[2:]] = argv[i + 1]; i += 1
    elif k == "--fps":
        args["fps"] = int(argv[i + 1]); i += 1
    elif k == "--samples":
        args["samples"] = int(argv[i + 1]); i += 1
    elif k == "--ppm":
        args["ppm"] = float(argv[i + 1]); i += 1
    elif k == "--canvas":
        args["canvas"] = int(argv[i + 1]); i += 1
    elif k == "--root-mode":
        args["root_mode"] = argv[i + 1]; i += 1
    i += 1

# Master comes from --master (default: inputs/ under the working directory). Never derived from this file's location.
MASTER = Path(args["master"]).expanduser().resolve()
PX = args["canvas"]
PX_PER_M = args["ppm"]
ROOT_PIXEL = (PX / 2, PX * 106 / 128)
ELEVATION = math.radians(45.0)
DIRS = [("S", 0), ("SE", 45), ("E", 90), ("NE", 135), ("N", 180), ("NW", 225), ("W", 270), ("SW", 315)]
ROOT_BONE = "Hips"
LOOP_TOL_M = 0.02


def fcurves_of(act):
    return [fc for layer in act.layers for s in layer.strips for cb in getattr(s, "channelbags", []) for fc in cb.fcurves]


def camera_for(azimuth_deg, cam):
    """Orthographic camera whose root point sits at ROOT_PIXEL for every direction."""
    A = math.radians(azimuth_deg)
    offset_dir = Vector((-math.sin(A) * math.cos(ELEVATION), -math.cos(A) * math.cos(ELEVATION), math.sin(ELEVATION)))
    forward = -offset_dir
    quat = forward.to_track_quat("-Z", "Y")
    up = quat @ Vector((0, 1, 0))
    # root is (64,106): 42 px below image centre = 0.84 m below the centre along screen-up
    below_m = (ROOT_PIXEL[1] - PX / 2) / PX_PER_M
    root = Vector((0, 0, 0))
    target = root + up * below_m
    cam.location = target + offset_dir * 50.0
    cam.rotation_euler = quat.to_euler()
    cam.data.ortho_scale = PX / PX_PER_M


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pre = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(MASTER))
    master_objs = set(bpy.data.objects) - pre
    for o in list(pre):
        bpy.data.objects.remove(o, do_unlink=True)
    for o in master_objs:
        if any(c.name == "glTF_not_exported" for c in o.users_collection):
            o.hide_render = True
    arm = next(o for o in master_objs if o.type == "ARMATURE")
    meshes = [o for o in master_objs if o.type == "MESH" and not o.hide_render]

    # Import clip, keep its action, delete its duplicate skeleton/mesh objects.
    clip_before = set(bpy.data.objects)
    actions_before = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=args["clip"])
    clip_objs = set(bpy.data.objects) - clip_before
    clip_actions = [a for a in bpy.data.actions if a not in actions_before]
    if len(clip_actions) != 1:
        raise SystemExit(f"expected one clip action, found {[a.name for a in clip_actions]}")
    act = clip_actions[0]
    for o in list(clip_objs):
        bpy.data.objects.remove(o, do_unlink=True)

    # Bind the clip action to the master armature (bone-name targets; rest compatibility verified upstream).
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and act.slots:
        arm.animation_data.action_slot = act.slots[0]

    scene = bpy.context.scene
    scene.render.fps = args["fps"]
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = args["samples"]
    scene.render.resolution_x = scene.render.resolution_y = PX
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"

    world = bpy.data.worlds.new("OperatorWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.2, 0.2, 0.2, 1.0)
    scene.world = world
    for name, loc, energy in [("Key", (-2.5, -3.5, 4.0), 900.0), ("Fill", (3.0, -2.0, 2.5), 300.0)]:
        ld = bpy.data.lights.new(name, type="AREA")
        ld.energy = energy
        ld.size = 4.0
        lo = bpy.data.objects.new(name, ld)
        lo.location = loc
        scene.collection.objects.link(lo)
        lo.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    cam_data = bpy.data.cameras.new("OperatorCam")
    cam_data.type = "ORTHO"
    cam_data.clip_start, cam_data.clip_end = 0.01, 200.0
    cam = bpy.data.objects.new("OperatorCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

    pb_root = arm.pose.bones[ROOT_BONE]
    bone_root = arm.data.bones[ROOT_BONE]
    rest_head = bone_root.head_local.copy()  # armature space
    rot_rest_inv = bone_root.matrix_local.to_3x3().inverted()

    t0, t1 = act.frame_range
    duration_frames = t1 - t0
    n = int(round(duration_frames * args["fps"] / scene.render.fps))
    frames = [t0 + k * (scene.render.fps / args["fps"]) for k in range(n)]

    def pose_snapshot(frame):
        scene.frame_set(int(math.floor(frame)), subframe=frame - math.floor(frame))
        bpy.context.view_layer.update()
        return {b.name: list(b.head) for b in arm.pose.bones}

    # Endpoint continuity for loop declaration: compare pose at authored end vs start.
    start_pose = pose_snapshot(t0)
    end_pose = pose_snapshot(t1)
    max_d = max((Vector(end_pose[k]) - Vector(start_pose[k])).length for k in start_pose)
    is_loop = max_d < LOOP_TOL_M

    raw_root = Path(args["out"])
    trajectory = []
    corrections = []
    residuals = []
    for k, frame in enumerate(frames):
        scene.frame_set(int(math.floor(frame)), subframe=frame - math.floor(frame))
        bpy.context.view_layer.update()
        head_arm = Vector(pb_root.head)
        head_world = arm.matrix_world @ head_arm
        trajectory.append({"sample": k, "frame": round(frame, 4), "time_s": round((frame - t0) / args["fps"], 6),
                           "hips_world_m": [round(x, 6) for x in head_world]})
        # Remove horizontal root translation from the sprite pose (keep vertical bob).
        delta_arm = Vector((rest_head.x - head_arm.x, rest_head.y - head_arm.y, 0.0))
        if args["root_mode"] == "bone":
            # DEFECTIVE (kept for regression comparison): bone-level correction is discarded at render time
            pb_root.location += rot_rest_inv @ delta_arm
        else:
            # Object-level offset: the animation cannot overwrite it, so it survives the render.
            arm.location = Vector((delta_arm.x * arm.scale.x, delta_arm.y * arm.scale.x, 0.0))
        bpy.context.view_layer.update()
        resid = Vector(pb_root.head) - Vector((rest_head.x, rest_head.y, pb_root.head.z))
        residuals.append(round(resid.length, 7))
        corrections.append([round(x, 6) for x in delta_arm])
        for name, az in DIRS:
            out_png = raw_root / f"c{PX}_{PX_PER_M:g}" / args["action"] / name / f"frame_{k:02d}.png"
            if out_png.exists():
                continue
            out_png.parent.mkdir(parents=True, exist_ok=True)
            camera_for(az, cam)
            scene.render.filepath = str(out_png)
            bpy.ops.render.render(write_still=True)

    meta = {
        "action": args["action"],
        "clip_action_name": act.name,
        "authored_frame_range": [t0, t1],
        "authored_duration_s": round(duration_frames / args["fps"], 6),
        "sampling_target_fps": args["fps"],
        "sample_count": len(frames),
        "sample_timestamps_s": [round((f - t0) / args["fps"], 6) for f in frames],
        "loop": is_loop,
        "endpoint_max_bone_head_delta_m": round(max_d, 6),
        "root_motion_policy": "extract_to_metadata",
        "root_bone": ROOT_BONE,
        "root_trajectory_world_m": trajectory,
        "root_xy_correction_arm_m": corrections,
        "root_xy_residual_after_m": residuals,
        "directions": {n: a for n, a in DIRS},
        "camera": {"projection": "ORTHO", "elevation_deg": 45, "ortho_scale_m": PX / PX_PER_M,
                   "pixels_per_m": PX_PER_M, "root_pixel": list(ROOT_PIXEL), "root_point_world": [0, 0, 0]},
        "renderer": {"engine": "BLENDER_EEVEE", "samples": args["samples"], "blender": bpy.app.version_string},
    }
    Path(args["meta"]).parent.mkdir(parents=True, exist_ok=True)
    Path(args["meta"]).write_text(json.dumps(meta, indent=1) + "\n")
    print("RENDER_DONE", meta["action"], "samples", len(frames), "loop", is_loop, "max_resid", max(residuals))


main()
