#!/usr/bin/env python3
"""Render three static shoulder-study blends under one fixed camera contract."""

import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector
from PIL import Image, ImageDraw


VARIANTS = ("BASELINE", "VARIANT_A_MODERATE", "VARIANT_B_LAYERED")
DIRECTIONS = {"N": 180, "NE": -135, "E": -90, "SE": -45,
              "S": 0, "SW": 45, "W": 90, "NW": 135}
CLOSEUP_DIRECTIONS = ("S", "SE", "E", "N", "NW")
CAMERA_SCALE = 1.23547
ELEVATION = math.radians(45.0)
PIXELS_PER_METER_128 = 50.0
ROOT_PIXEL = (64, 106)
BACKGROUND = (30, 32, 37)


def reset_pose(armature):
    if armature.animation_data:
        armature.animation_data.action = None
    for pose_bone in armature.pose.bones:
        pose_bone.matrix_basis = pose_bone.matrix_basis.__class__()
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()


def configure_scene(mesh, armature, overlay, scale):
    scene = bpy.context.scene
    bounds = [mesh.matrix_world @ vertex.co for vertex in mesh.data.vertices]
    lo = [min(point[axis] for point in bounds) for axis in range(3)]
    hi = [max(point[axis] for point in bounds) for axis in range(3)]
    center_x, center_y = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
    root = bpy.data.objects.new("SHOULDER_STUDY_ROOT", None)
    scene.collection.objects.link(root)
    for obj in (mesh, armature, overlay):
        if obj:
            obj.parent = root
    root.scale = (scale, scale, scale)
    root.location = (-center_x * scale, -center_y * scale, -lo[2] * scale)
    bpy.context.view_layer.update()

    scene.render.engine = "BLENDER_EEVEE"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.filter_size = 0.0
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("shoulder_study_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.10, 0.11, 0.13, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scene.world = world

    light_data = bpy.data.lights.new("shoulder_study_sun", "SUN")
    light_data.energy = 3.0
    light = bpy.data.objects.new("shoulder_study_sun", light_data)
    scene.collection.objects.link(light)
    camera_data = bpy.data.cameras.new("shoulder_study_camera")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("shoulder_study_camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return scene, light, camera


def render_direction(scene, light, camera, direction, resolution, destination):
    scene.render.resolution_x = scene.render.resolution_y = resolution
    scene.render.filter_size = 0.0 if resolution == 128 else 1.5
    camera.data.ortho_scale = 128.0 / PIXELS_PER_METER_128
    camera.data.shift_y = (ROOT_PIXEL[1] - ROOT_PIXEL[0]) / 128.0
    azimuth = math.radians(DIRECTIONS[direction])
    camera.location = (10 * math.sin(azimuth) * math.cos(ELEVATION),
                      -10 * math.cos(azimuth) * math.cos(ELEVATION),
                      10 * math.sin(ELEVATION))
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    light.rotation_euler = (math.radians(50), 0, azimuth - math.radians(35))
    scene.render.filepath = str(destination)
    bpy.ops.render.render(write_still=True)


def composite(path):
    image = Image.open(path).convert("RGBA")
    background = Image.new("RGBA", image.size, (*BACKGROUND, 255))
    background.alpha_composite(image)
    return background.convert("RGB")


def alpha_bounds(path):
    alpha = np.asarray(Image.open(path).convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > 8)
    if not len(xs):
        return [0, 0]
    return [int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)]


def upper_body_band_width(path, y0=32, y1=56):
    alpha = np.asarray(Image.open(path).convert("RGBA"))[:, :, 3]
    widths = []
    for y in range(y0, y1 + 1):
        xs = np.where(alpha[y] > 8)[0]
        if len(xs):
            widths.append((int(xs.max() - xs.min() + 1), y))
    return list(max(widths)) if widths else [0, y0]


def labeled_tile(image, title, width):
    tile = Image.new("RGB", (width, image.height + 22), BACKGROUND)
    tile.paste(image, (0, 22))
    ImageDraw.Draw(tile).text((4, 4), title, fill=(255, 255, 255))
    return tile


def assemble(outdir, metrics):
    root = outdir / "renders"
    # Direction columns, variant rows.
    sheets = {}
    for resolution, filename in ((128, "shoulder_128_all8_three_variants.png"),
                                 (512, "shoulder_512_all8_three_variants.png")):
        cell_rows = []
        for variant in VARIANTS:
            row = [labeled_tile(composite(root / variant / str(resolution) / f"{resolution}_{direction}.png"),
                                f"{variant} · {direction}", resolution)
                   for direction in DIRECTIONS]
            cell_rows.append(row)
        sheet = Image.new("RGB", (resolution * len(DIRECTIONS), sum(row[0].height for row in cell_rows)), BACKGROUND)
        y = 0
        for row in cell_rows:
            x = 0
            for tile in row:
                sheet.paste(tile, (x, y))
                x += tile.width
            y += row[0].height
        sheet.save(outdir / filename, optimize=True)
        sheets[str(resolution)] = filename

    crops = []
    for variant in VARIANTS:
        for direction in CLOSEUP_DIRECTIONS:
            image = composite(root / variant / "512" / f"512_{direction}.png")
            crop = image.crop((96, 90, 416, 300))
            crops.append(labeled_tile(crop, f"{variant} · {direction}", crop.width))
    closeup = Image.new("RGB", (320 * len(CLOSEUP_DIRECTIONS), crops[0].height * len(VARIANTS)), BACKGROUND)
    for row, variant in enumerate(VARIANTS):
        for col in range(len(CLOSEUP_DIRECTIONS)):
            closeup.paste(crops[row * len(CLOSEUP_DIRECTIONS) + col], (col * 320, row * crops[0].height))
    closeup.save(outdir / "shoulder_512_closeups_five_views.png", optimize=True)

    silhouette = Image.new("RGB", (128 * len(DIRECTIONS), 3 * (128 + 22)), BACKGROUND)
    draw = ImageDraw.Draw(silhouette)
    for row, variant in enumerate(VARIANTS):
        for col, direction in enumerate(DIRECTIONS):
            rgba = Image.open(root / variant / "128" / f"128_{direction}.png").convert("RGBA")
            mask = rgba.getchannel("A").point(lambda alpha: 255 if alpha > 8 else 0)
            tile = Image.new("RGB", (128, 128), BACKGROUND)
            tile.paste((0, 0, 0), (0, 0, 128, 128), mask)
            y = row * (128 + 22)
            silhouette.paste(tile, (col * 128, y + 22))
            draw.text((col * 128 + 4, y + 4), f"{variant[:8]} {direction}", fill="white")
    silhouette.save(outdir / "shoulder_128_silhouette_optional.png", optimize=True)
    return {"sheets": sheets,
            "closeups": "shoulder_512_closeups_five_views.png",
            "silhouette": "shoulder_128_silhouette_optional.png"}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    source_dir, outdir = Path(argv[0]), Path(argv[1])
    outdir.mkdir(parents=True, exist_ok=True)
    metrics = {"schema": "custodian.operator_shoulder_plate_render.v1", "camera": {
        "elevation_deg": 45, "pixels_per_meter_at_128": 50, "root_pixel_128": [64, 106],
        "uniform_scale": CAMERA_SCALE, "background_rgb": list(BACKGROUND),
        "lighting": "single sun, energy 3, per-view rotation; identical for all variants",
        "pose": "armature rest pose, action disabled, identity pose-bone transforms; same for all variants"},
        "shoulder_band_pixel_measurement": {
            "resolution": 128, "rows_inclusive": [32, 56],
            "meaning": "maximum character alpha width within the fixed upper-body image band; a coarse silhouette measure, not an aesthetic score"},
        "variants": {}}
    for variant in VARIANTS:
        bpy.ops.wm.open_mainfile(filepath=str((source_dir / f"{variant}.blend").resolve()))
        armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
        mesh = next(obj for obj in bpy.data.objects if obj.type == "MESH" and obj.vertex_groups)
        overlay = next((obj for obj in bpy.data.objects if obj.name.startswith("SHOULDER_PLATE_OVERLAY_")), None)
        reset_pose(armature)
        scene, light, camera = configure_scene(mesh, armature, overlay, CAMERA_SCALE)
        variant_metrics = {"silhouette_bounds_px": {"128": {}, "512": {}},
                           "upper_body_band_width_px": {}}
        for resolution in (128, 512):
            for direction in DIRECTIONS:
                destination = outdir / "renders" / variant / str(resolution) / f"{resolution}_{direction}.png"
                destination.parent.mkdir(parents=True, exist_ok=True)
                render_direction(scene, light, camera, direction, resolution, destination)
                variant_metrics["silhouette_bounds_px"][str(resolution)][direction] = alpha_bounds(destination)
                if resolution == 128:
                    variant_metrics["upper_body_band_width_px"][direction] = upper_body_band_width(destination)
        metrics["variants"][variant] = variant_metrics

    baseline = metrics["variants"]["BASELINE"]["silhouette_bounds_px"]["128"]
    for variant in VARIANTS[1:]:
        widths = metrics["variants"][variant]["silhouette_bounds_px"]["128"]
        metrics["variants"][variant]["width_change_percent_vs_baseline"] = {
            direction: round((widths[direction][0] / baseline[direction][0] - 1) * 100, 2)
            for direction in DIRECTIONS}
        band = metrics["variants"][variant]["upper_body_band_width_px"]
        baseline_band = metrics["variants"]["BASELINE"]["upper_body_band_width_px"]
        metrics["variants"][variant]["upper_body_band_change_percent_vs_baseline"] = {
            direction: round((band[direction][0] / baseline_band[direction][0] - 1) * 100, 2)
            for direction in DIRECTIONS}
    metrics["review_artifacts"] = assemble(outdir, metrics)
    (outdir / "render_metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(json.dumps({"camera": metrics["camera"], "variants": metrics["variants"],
                      "review_artifacts": metrics["review_artifacts"]}, indent=2))


if __name__ == "__main__":
    main()
