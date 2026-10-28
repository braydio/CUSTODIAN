#!/usr/bin/env python3
"""Render Task 017 static and ITER005 comparison evidence under fixed cameras."""

import argparse
import hashlib
import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont


DIRECTIONS = {"N": 180, "NE": -135, "E": -90, "SE": -45,
              "S": 0, "SW": 45, "W": 90, "NW": 135}
FOCUS_DIRECTIONS = ("S", "E", "N", "W")
CHECKPOINTS = (6, 16, 13)
MODELS = ("BASELINE", "VARIANT_A_MODERATE", "CORRECTED_TASK017")
BACKGROUND = (30, 32, 37)
ROOT_SCALE = 1.23547
RENDER_SCRIPT = Path(__file__).with_name("render_shoulder_plate_study.py")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--variant-a", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--motion-source", type=Path, required=True)
    parser.add_argument("--validation", type=Path, required=True)
    parser.add_argument("--outdir", type=Path, required=True)
    parser.add_argument("--motion-baseline-only", action="store_true")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:])


def load_helpers():
    spec = importlib.util.spec_from_file_location("shoulder_render_helpers", RENDER_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.DIRECTIONS = DIRECTIONS
    module.VARIANTS = MODELS
    return module


def open_model(path, static, helpers):
    bpy.ops.wm.open_mainfile(filepath=str(path.resolve()))
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    mesh = bpy.data.objects["output_unwrapped"]
    overlay = next((obj for obj in bpy.data.objects
                    if obj.name.startswith("SHOULDER_PLATE_OVERLAY_")), None)
    if static:
        helpers.reset_pose(armature)
    scene, light, camera = helpers.configure_scene(mesh, armature, overlay, ROOT_SCALE)
    return scene, light, camera, armature, mesh


def render_one(helpers, scene, light, camera, direction, resolution, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    helpers.render_direction(scene, light, camera, direction, resolution, path)


def composite(path):
    image = Image.open(path).convert("RGBA")
    background = Image.new("RGBA", image.size, (*BACKGROUND, 255))
    background.alpha_composite(image)
    return background.convert("RGB")


def label_tile(image, label, size=None):
    if size is None:
        size = image.width
    tile = Image.new("RGB", (image.width, image.height + 24), BACKGROUND)
    tile.paste(image, (0, 24))
    ImageDraw.Draw(tile).text((5, 5), label, fill=(245, 245, 245))
    return tile


def make_static_sheets(outdir):
    render_root = outdir / "renders" / "static"
    sheets = {}
    for resolution, filename in ((128, "static_128_all8_three_way.png"),
                                 (512, "static_512_all8_three_way.png")):
        label_width = 132
        sheet = Image.new("RGB", (label_width + resolution * 8, (resolution + 24) * 3), BACKGROUND)
        draw = ImageDraw.Draw(sheet)
        display_names = {"BASELINE": "BASELINE", "VARIANT_A_MODERATE": "ORIGINAL A",
                         "CORRECTED_TASK017": "TASK 017"}
        for row, model in enumerate(MODELS):
            y = row * (resolution + 24)
            draw.text((5, y + 5), display_names[model], fill=(245, 245, 245))
            for column, direction in enumerate(DIRECTIONS):
                image = composite(render_root / model / str(resolution)
                                  / f"{resolution}_{direction}.png")
                tile = label_tile(image, direction)
                sheet.paste(tile, (label_width + column * resolution, y))
        sheet.save(outdir / filename, optimize=True)
        sheets[filename] = filename

    directions = ("S", "SE", "E", "N", "NW", "W")
    crop_box = (64, 86, 448, 330)
    crop_w, crop_h = crop_box[2] - crop_box[0], crop_box[3] - crop_box[1]
    close = Image.new("RGB", (crop_w * len(directions), (crop_h + 24) * 3), BACKGROUND)
    for row, model in enumerate(MODELS):
        for column, direction in enumerate(directions):
            image = composite(render_root / model / "512" / f"512_{direction}.png")
            tile = label_tile(image.crop(crop_box), f"{model} | {direction}")
            close.paste(tile, (column * crop_w, row * (crop_h + 24)))
    close.save(outdir / "static_512_shoulder_closeups.png", optimize=True)
    sheets["static_512_shoulder_closeups.png"] = "static_512_shoulder_closeups.png"

    silhouette = Image.new("RGB", (128 * 8, (128 + 24) * 3), BACKGROUND)
    draw = ImageDraw.Draw(silhouette)
    for row, model in enumerate(MODELS):
        for column, direction in enumerate(DIRECTIONS):
            rgba = Image.open(render_root / model / "128" / f"128_{direction}.png").convert("RGBA")
            mask = rgba.getchannel("A").point(lambda value: 255 if value > 8 else 0)
            tile = Image.new("RGB", (128, 128), BACKGROUND)
            tile.paste((0, 0, 0), (0, 0, 128, 128), mask)
            x, y = column * 128, row * 152
            silhouette.paste(tile, (x, y + 24))
            draw.text((x + 4, y + 5), f"{model[:8]} | {direction}", fill="white")
    silhouette.save(outdir / "static_128_silhouette_three_way.png", optimize=True)
    sheets["static_128_silhouette_three_way.png"] = "static_128_silhouette_three_way.png"
    return sheets


def make_loop_gif(outdir):
    images = []
    for frame in range(1, 22):
        row = []
        for direction in DIRECTIONS:
            path = outdir / "renders" / "motion" / "128" / f"frame_{frame:02d}_{direction}.png"
            row.append(label_tile(composite(path), f"{direction}"))
        label_width = 92
        canvas = Image.new("RGB", (label_width + 128 * 8, 152), BACKGROUND)
        for column, tile in enumerate(row):
            canvas.paste(tile, (label_width + column * 128, 0))
        ImageDraw.Draw(canvas).text((4, 5), f"frame {frame:02d}/21", fill=(255, 255, 255))
        images.append(canvas)
    images[0].save(outdir / "iter005_clean_pauldrons_loop_128_all8.gif", save_all=True,
                   append_images=images[1:], duration=33, loop=0, optimize=True)


def make_motion_comparison(outdir):
    directions = FOCUS_DIRECTIONS
    tile_w, tile_h = 128, 152
    label_width = 142
    sheet = Image.new("RGB", (label_width + tile_w * len(directions),
                               tile_h * len(CHECKPOINTS) * 2), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    for row, frame in enumerate(CHECKPOINTS):
        for model_index, model in enumerate(("ITER005_BASELINE", "CORRECTED_TASK017")):
            y = (row * 2 + model_index) * tile_h
            draw.text((5, y + 4), f"frame {frame}", fill="white")
            display_model = "ITER005" if model == "ITER005_BASELINE" else "TASK017"
            draw.text((5, y + 20), display_model, fill="white")
            for column, direction in enumerate(directions):
                if model == "CORRECTED_TASK017":
                    source = outdir / "renders" / "motion" / "128" / f"frame_{frame:02d}_{direction}.png"
                else:
                    source = outdir / "renders" / "focus_baseline" / str(frame) / f"128_{direction}.png"
                image = composite(source)
                tile = label_tile(image, direction)
                sheet.paste(tile, (label_width + column * tile_w, y))
    sheet.save(outdir / "iter005_running_arm_swing_before_after_128.png", optimize=True)


def emission_material(name, color):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs[0].default_value = (*color, 1.0)
    material.node_tree.links.new(emission.outputs[0], output.inputs["Surface"])
    return material


def render_geometry_diagnostic(args, helpers, outdir, validation):
    bpy.ops.wm.open_mainfile(filepath=str(args.candidate.resolve()))
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    mesh = bpy.data.objects["output_unwrapped"]
    plates = {"Left": bpy.data.objects["PAULDRON_Left_TASK017"],
              "Right": bpy.data.objects["PAULDRON_Right_TASK017"]}
    helpers.reset_pose(armature)
    scene, light, camera = helpers.configure_scene(mesh, armature, None, ROOT_SCALE)

    cyan = emission_material("TASK017_PAULDRON_BASE_DIAG", (0.02, 0.62, 0.86))
    orange = emission_material("TASK017_PAULDRON_RIM_DIAG", (1.0, 0.46, 0.04))
    red = emission_material("TASK017_INTERSECTION_DIAG", (1.0, 0.01, 0.02))
    magenta = emission_material("TASK017_BODY_INTERSECTION_DIAG", (1.0, 0.0, 0.65))
    # Mark every shell face that intersected the source body at any sampled
    # running frame. The rim remains orange unless it is a measured intersection.
    for side, plate in plates.items():
        plate.data.materials.clear()
        for material in (cyan, orange, red):
            plate.data.materials.append(material)
        overlap_ids = set(validation["body_overlap_union_across_cycle"][side]["shell_face_indices"])
        rim_start = len(plate.data.polygons) - 24
        for poly in plate.data.polygons:
            if poly.index in overlap_ids:
                poly.material_index = 2
            elif poly.index >= rim_start:
                poly.material_index = 1
            else:
                poly.material_index = 0

    body_faces = sorted({face_id for side in plates
                         for face_id in validation["body_overlap_union_across_cycle"][side]["body_face_indices"]})
    mesh.data.materials.append(magenta)
    for face_id in body_faces:
        if face_id < len(mesh.data.polygons):
            mesh.data.polygons[face_id].material_index = len(mesh.data.materials) - 1

    # Draw explicit shoulder-joint anchors in render space.
    anchor_mat = emission_material("TASK017_ATTACHMENT_ANCHOR", (0.1, 1.0, 0.2))
    anchors = []
    for side in plates:
        bone = armature.pose.bones[f"mixamorig:{side}Shoulder"]
        point = armature.matrix_world @ bone.tail
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.014,
                                             location=point)
        marker = bpy.context.object
        marker.name = f"DEBUG_ANCHOR_{side}"
        marker.data.materials.append(anchor_mat)
        anchors.append((side, point))

    legend = ImageFont.load_default()
    output = []
    for direction in ("S", "N", "E", "W"):
        raw_path = outdir / "renders" / "geometry_debug" / f"{direction}.png"
        render_one(helpers, scene, light, camera, direction, 512, raw_path)
        image = composite(raw_path)
        painter = ImageDraw.Draw(image)
        for side, point in anchors:
            projected = world_to_camera_view(scene, camera, point)
            px, py = int(projected.x * 512), int((1.0 - projected.y) * 512)
            painter.ellipse((px - 8, py - 8, px + 8, py + 8), outline=(30, 255, 40), width=3)
        output.append(label_tile(image, f"{direction} | shell / overlaps"))
    sheet = Image.new("RGB", (512 * 4, 536), BACKGROUND)
    for column, tile in enumerate(output):
        sheet.paste(tile, (512 * column, 0))
    sheet.save(outdir / "pauldron_geometry_attachment_intersections_512.png", optimize=True)


def main():
    args = parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)
    helpers = load_helpers()
    if args.motion_baseline_only:
        scene, light, camera, _armature, _mesh = open_model(args.motion_source, False, helpers)
        for frame in CHECKPOINTS:
            scene.frame_set(frame)
            bpy.context.view_layer.update()
            for direction in FOCUS_DIRECTIONS:
                destination = args.outdir / "renders" / "focus_baseline" / str(frame) / f"128_{direction}.png"
                render_one(helpers, scene, light, camera, direction, 128, destination)
        make_motion_comparison(args.outdir)
        print("ITER005 focused motion baseline rendered from the specified motion source", flush=True)
        return
    paths = {"BASELINE": args.baseline, "VARIANT_A_MODERATE": args.variant_a,
             "CORRECTED_TASK017": args.candidate}
    render_metadata = {"schema": "custodian.operator_task017_render_evidence.v1",
                       "camera": {"scale": ROOT_SCALE, "elevation_deg": 45,
                                  "pixels_per_meter_at_128": 50, "root_pixel": [64, 106],
                                  "direction_mirroring": False},
                       "static_models": {}, "motion_frames": list(range(1, 22)),
                       "motion_endpoint_frame": 22, "motion_checkpoints": list(CHECKPOINTS)}

    for model, path in paths.items():
        scene, light, camera, _armature, _mesh = open_model(path, True, helpers)
        model_metrics = {"alpha_bounds_px_128": {}, "alpha_bounds_px_512": {}}
        for resolution in (128, 512):
            for direction in DIRECTIONS:
                destination = (args.outdir / "renders" / "static" / model / str(resolution)
                               / f"{resolution}_{direction}.png")
                render_one(helpers, scene, light, camera, direction, resolution, destination)
                model_metrics[f"alpha_bounds_px_{resolution}"][direction] = helpers.alpha_bounds(destination)
        render_metadata["static_models"][model] = model_metrics
        print(f"static renders complete: {model}", flush=True)

    for model, path in (("CORRECTED_TASK017", args.candidate), ("ITER005_BASELINE", args.motion_source)):
        scene, light, camera, armature, _mesh = open_model(path, False, helpers)
        for frame in range(1, 22):
            scene.frame_set(frame)
            bpy.context.view_layer.update()
            for direction in DIRECTIONS:
                if model == "CORRECTED_TASK017":
                    destination = args.outdir / "renders" / "motion" / "128" / f"frame_{frame:02d}_{direction}.png"
                elif frame in CHECKPOINTS and direction in FOCUS_DIRECTIONS:
                    destination = args.outdir / "renders" / "focus_baseline" / str(frame) / f"128_{direction}.png"
                else:
                    continue
                render_one(helpers, scene, light, camera, direction, 128, destination)
            if model == "CORRECTED_TASK017":
                print(f"motion frame {frame}/21", flush=True)
        if model == "CORRECTED_TASK017":
            scene.frame_set(22)
            bpy.context.view_layer.update()
            render_one(helpers, scene, light, camera, "S", 128,
                       args.outdir / "renders" / "motion" / "128" / "endpoint_22_S.png")

    artifacts = make_static_sheets(args.outdir)
    make_loop_gif(args.outdir)
    make_motion_comparison(args.outdir)
    render_geometry_diagnostic(args, helpers, args.outdir, json.loads(args.validation.read_text()))
    render_metadata["review_artifacts"] = {
        **artifacts,
        "motion_loop": "iter005_clean_pauldrons_loop_128_all8.gif",
        "motion_comparison": "iter005_running_arm_swing_before_after_128.png",
        "geometry_diagnostic": "pauldron_geometry_attachment_intersections_512.png",
    }
    (args.outdir / "render_metadata.json").write_text(json.dumps(render_metadata, indent=2) + "\n")
    manifest = {}
    for path in sorted(args.outdir.rglob("*")):
        if path.is_file() and path.name != "evidence_sha256.json":
            manifest[str(path.relative_to(args.outdir))] = {
                "bytes": path.stat().st_size,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            }
    (args.outdir / "evidence_sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"artifacts": render_metadata["review_artifacts"],
                      "sha_manifest_entries": len(manifest)}, indent=2), flush=True)


if __name__ == "__main__":
    main()
