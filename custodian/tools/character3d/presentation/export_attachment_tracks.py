"""Export raw attachment samples through the same camera and root registration as the sprite render.

Run inside Blender (headless). This is the spatial authority for socket coordinates: bone positions are
read from the posed rig, after the same horizontal root-motion removal the sprite renderer applies, and
projected through an orthographic camera placed with the render's formula (root point at a fixed pixel).

  blender -b --factory-startup --python custodian/tools/character3d/presentation/export_attachment_tracks.py -- \
    --glb <source.glb> --map <attachment_map.json> --action running --frame-start 0.8 --frame-count 15 \
    --fps 24 --scene-fps 24 --canvas 256 --ppm 80 --root-pixel 128 212 --out <raw.json>

Output is raw data only (canvas-space pixels, world depth, world foot heights). The Python builder
(build_presentation_tracks.py) adds provenance, cue derivation and validation.
Exit status: nonzero on any refusal; nothing is written unless every sample is valid.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ELEVATION = math.radians(45.0)
DIRECTIONS = [("S", 0), ("SE", 45), ("E", 90), ("NE", 135), ("N", 180), ("NW", 225), ("W", 270), ("SW", 315)]
ROOT_BONE = "Hips"
DECIMALS = 6


def parse_args(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--master", required=True, type=Path, help="character master GLB that the sprites are rendered on")
    ap.add_argument("--glb", required=True, type=Path, help="motion clip GLB whose action is bound to the master")
    ap.add_argument("--map", required=True, type=Path)
    ap.add_argument("--action", required=True)
    ap.add_argument("--frame-start", required=True, type=float)
    ap.add_argument("--frame-count", required=True, type=int)
    ap.add_argument("--fps", required=True, type=float)
    ap.add_argument("--scene-fps", required=True, type=float)
    ap.add_argument("--canvas", required=True, type=int)
    ap.add_argument("--ppm", required=True, type=float)
    ap.add_argument("--root-pixel", required=True, type=float, nargs=2)
    ap.add_argument("--out", required=True, type=Path)
    return ap.parse_args(argv)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def refuse(message: str):
    print(f"REFUSED: {message}", file=sys.stderr)
    sys.exit(1)


def place_camera(cam, azimuth_deg, canvas, ppm, root_pixel):
    """Same placement as the sprite renderer: world origin (feet root) lands on root_pixel."""
    a = math.radians(azimuth_deg)
    offset = Vector((-math.sin(a) * math.cos(ELEVATION), -math.cos(a) * math.cos(ELEVATION), math.sin(ELEVATION)))
    forward = -offset
    quat = forward.to_track_quat("-Z", "Y")
    up = quat @ Vector((0, 1, 0))
    below_m = (root_pixel[1] - canvas / 2) / ppm
    cam.location = up * below_m + offset * 50.0
    cam.rotation_euler = quat.to_euler()


def project(scene, cam, world_point, canvas):
    x, y, depth = world_to_camera_view(scene, cam, world_point)
    return x * canvas, (1.0 - y) * canvas, depth


def main():
    args = parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if not args.glb.is_file() or not args.master.is_file():
        refuse(f"source GLB missing: {args.glb} or {args.master}")
    mapping = json.loads(args.map.read_text())
    sockets = mapping["sockets"]

    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Same binding as the sprite renderer: master armature and meshes, clip action bound by bone name.
    bpy.ops.import_scene.gltf(filepath=str(args.master))
    arm = next((o for o in bpy.data.objects if o.type == "ARMATURE"), None)
    if arm is None:
        refuse("master GLB has no armature")
    before_actions = set(bpy.data.actions)
    before_objects = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(args.glb))
    clip_actions = [a for a in bpy.data.actions if a not in before_actions]
    if len(clip_actions) != 1:
        refuse(f"expected one clip action, found {[a.name for a in clip_actions]}")
    action = clip_actions[0]
    for obj in set(bpy.data.objects) - before_objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    if hasattr(arm.animation_data, "action_slot") and action.slots:
        arm.animation_data.action_slot = action.slots[0]
    if args.action not in mapping.get("actions", {}):
        refuse(f"action {args.action} has no reviewed attachment mapping")
    scene = bpy.context.scene
    scene.render.fps = int(round(args.scene_fps))
    scene.render.resolution_x = scene.render.resolution_y = args.canvas
    scene.render.resolution_percentage = 100
    t0, t1 = action.frame_range
    duration_frames = t1 - t0
    n = int(round(duration_frames * args.fps / args.scene_fps))
    if n != args.frame_count:
        refuse(f"sampling yields {n} samples, contract declares {args.frame_count}")
    if abs(t0 - args.frame_start) > 1e-3:
        refuse(f"authored start {t0} differs from contract start {args.frame_start}")

    cam_data = bpy.data.cameras.new("AttachmentCamera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = args.canvas / args.ppm
    cam = bpy.data.objects.new("AttachmentCamera", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

    pb_root = arm.pose.bones[ROOT_BONE]
    rest_head = arm.data.bones[ROOT_BONE].head_local.copy()
    rot_rest_inv = arm.data.bones[ROOT_BONE].matrix_local.to_3x3().inverted()
    root_pixel = tuple(args.root_pixel)
    scale = args.scene_fps and (args.fps / args.scene_fps)
    samples = {d: [] for d, _ in DIRECTIONS}
    world = []
    max_residual = 0.0
    for k in range(n):
        frame = t0 + k * (args.scene_fps / args.fps)
        scene.frame_set(int(math.floor(frame)), subframe=frame - math.floor(frame))
        bpy.context.view_layer.update()
        head_arm = Vector(pb_root.head)
        delta = Vector((rest_head.x - head_arm.x, rest_head.y - head_arm.y, 0.0))
        pb_root.location += rot_rest_inv @ delta
        bpy.context.view_layer.update()
        residual = Vector(pb_root.head) - Vector((rest_head.x, rest_head.y, pb_root.head.z))
        max_residual = max(max_residual, residual.length)
        points = {}
        for socket, spec in sockets.items():
            if spec.get("status") != "resolved":
                continue
            pb = arm.pose.bones[spec["bone"]]
            local = pb.head if spec["point"] == "head" else pb.tail
            points[socket] = arm.matrix_world @ local
        points["root"] = Vector((0.0, 0.0, 0.0))
        world.append({"index": k, "time_s": round((frame - t0) / args.fps, DECIMALS),
                      "frame": round(frame, DECIMALS),
                      "world_m": {socket: [round(c, DECIMALS) for c in p] for socket, p in points.items()}})
        for direction, azimuth in DIRECTIONS:
            place_camera(cam, azimuth, args.canvas, args.ppm, root_pixel)
            bpy.context.view_layer.update()
            projected = {}
            for socket, point in points.items():
                x, y, depth = project(scene, cam, point, args.canvas)
                inside = 0.0 <= x < args.canvas and 0.0 <= y < args.canvas
                projected[socket] = {"x": round(x, DECIMALS), "y": round(y, DECIMALS),
                                     "depth_m": round(depth, DECIMALS), "in_canvas": bool(inside)}
            samples[direction].append({"index": k, "points": projected})

    raw = {
        "schema": "custodian.character3d_attachment_raw.v1",
        "action": args.action,
        "glb": {"path": str(args.glb), "sha256": sha256(args.glb)},
        "master": {"path": str(args.master), "sha256": sha256(args.master)},
        "mapping_sha256": sha256(args.map),
        "sample_count": n, "frame_start": t0, "sampling_fps": args.fps, "scene_fps": args.scene_fps,
        "canvas": args.canvas, "ppm": args.ppm, "root_pixel": list(root_pixel),
        "max_root_residual_m": round(max_residual, DECIMALS),
        "sockets": {name: spec for name, spec in sockets.items()},
        "world": world,
        "directions": {d: {"azimuth_deg": a, "samples": samples[d]} for d, a in DIRECTIONS},
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    temp = args.out.with_name(args.out.name + ".tmp")
    temp.write_text(json.dumps(raw, indent=1, sort_keys=True) + "\n")
    temp.replace(args.out)
    print(f"EXPORTED {args.action} {n} samples x {len(DIRECTIONS)} directions -> {args.out}")


if __name__ == "__main__":
    main()
