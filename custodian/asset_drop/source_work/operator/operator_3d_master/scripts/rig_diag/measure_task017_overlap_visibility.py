#!/usr/bin/env python3
"""Ray-test whether measured shoulder/body overlaps are exposed to fixed cameras."""

import argparse
import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


def args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, required=True)
    parser.add_argument("--validation", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:])


def main():
    opts = args()
    script = Path(__file__).with_name("render_shoulder_plate_study.py")
    spec = importlib.util.spec_from_file_location("fixed_camera_helpers", script)
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    bpy.ops.wm.open_mainfile(filepath=str(opts.blend.resolve()))
    arm = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    body = bpy.data.objects["output_unwrapped"]
    helper.reset_pose(arm)
    scene, _light, camera = helper.configure_scene(body, arm, None, 1.23547)
    validation = json.loads(opts.validation.read_text())
    depsgraph = bpy.context.evaluated_depsgraph_get()
    per_frame = []
    exposed_total = {"Left": set(), "Right": set()}

    for frame in range(scene.frame_start, scene.frame_end + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        body_eval = body.evaluated_get(depsgraph)
        body_data = body_eval.to_mesh()
        world_vertices = [body_eval.matrix_world @ vertex.co for vertex in body_data.vertices]
        faces = [tuple(poly.vertices) for poly in body_data.polygons]
        frame_row = {"frame": frame, "views": {}}
        for direction, azimuth_deg in helper.DIRECTIONS.items():
            azimuth = math.radians(azimuth_deg)
            elevation = math.radians(45.0)
            camera.location = (10 * math.sin(azimuth) * math.cos(elevation),
                               -10 * math.cos(azimuth) * math.cos(elevation),
                               10 * math.sin(elevation))
            camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
            bpy.context.view_layer.update()
            view_direction = camera.matrix_world.to_3x3() @ Vector((0.0, 0.0, -1.0))
            visible = {}
            for side in ("Left", "Right"):
                face_ids = validation["run_frames"][frame - scene.frame_start]["shells"][side]["overlap_body_face_indices"]
                body_hits, in_frame = [], 0
                for face_index in face_ids:
                    if face_index >= len(faces):
                        continue
                    vertices = faces[face_index]
                    target = sum((world_vertices[index] for index in vertices), Vector()) / len(vertices)
                    projected = world_to_camera_view(scene, camera, target)
                    if not (0.0 <= projected.x <= 1.0 and 0.0 <= projected.y <= 1.0):
                        continue
                    in_frame += 1
                    ray_origin = target - view_direction * 10.0
                    hit, _location, _normal, hit_face, hit_obj, _matrix = scene.ray_cast(
                        depsgraph, ray_origin, view_direction, distance=20.0)
                    if hit and hit_obj and hit_obj.original == body and hit_face == face_index:
                        body_hits.append(face_index)
                visible[side] = {"overlap_body_faces_in_frame": in_frame,
                                 "visible_as_first_surface": len(body_hits),
                                 "visible_face_indices": body_hits}
                exposed_total[side].update(body_hits)
            frame_row["views"][direction] = visible
        body_eval.to_mesh_clear()
        per_frame.append(frame_row)

    result = {"schema": "custodian.operator_task017_overlap_visibility.v1",
              "candidate": str(opts.blend), "method": "fixed-camera scene ray cast at centers of body faces intersecting a pauldron surface in that frame",
              "camera": {"scale": 1.23547, "elevation_deg": 45,
                         "pixels_per_meter_at_128": 50, "root_pixel": [64, 106]},
              "unique_exposed_body_overlap_faces_by_side": {
                  side: sorted(values) for side, values in exposed_total.items()},
              "unique_exposed_body_overlap_face_counts_by_side": {
                  side: len(values) for side, values in exposed_total.items()},
              "frames": per_frame}
    opts.out.parent.mkdir(parents=True, exist_ok=True)
    opts.out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result["unique_exposed_body_overlap_face_counts_by_side"], indent=2))


if __name__ == "__main__":
    main()
