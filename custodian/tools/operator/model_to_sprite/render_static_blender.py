"""Blender-side static GLB renderer; only invoked by the parent candidate CLI."""
from __future__ import annotations

import json
import math
import pathlib
import sys

import bpy
import numpy as np
from mathutils import Vector


DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
AZIMUTH_DEGREES = {"N": 180, "NE": -135, "E": -90, "SE": -45, "S": 0, "SW": 45, "W": 90, "NW": 135}
ROOT_PIXEL = (64, 106)


def fail(message: str) -> None:
    print("MODEL_TO_SPRITE_ERROR:" + message, flush=True)
    raise SystemExit(2)


def evaluated_bounds(meshes):
    bpy.context.view_layer.update()
    vertices = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    if not vertices:
        fail("NO_MESH_BOUNDS")
    return tuple(min(v[i] for v in vertices) for i in range(3)), tuple(max(v[i] for v in vertices) for i in range(3))


def set_placement(root, meshes, scale: float):
    root.scale = (scale, scale, scale)
    root.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    lower, upper = evaluated_bounds(meshes)
    root.location = (-(lower[0] + upper[0]) / 2, -(lower[1] + upper[1]) / 2, -lower[2])
    bpy.context.view_layer.update()
    return evaluated_bounds(meshes)


def rgba_height(path: pathlib.Path) -> int:
    image = bpy.data.images.load(str(path), check_existing=False)
    try:
        pixels = np.empty(len(image.pixels), dtype=np.float32)
        image.pixels.foreach_get(pixels)
        alpha = pixels.reshape((image.size[1], image.size[0], 4))[..., 3]
        occupied_rows = np.flatnonzero(np.any(alpha > (32.0 / 255.0), axis=1))
        if not len(occupied_rows):
            return 0
        return int(occupied_rows[-1] - occupied_rows[0] + 1)
    finally:
        bpy.data.images.remove(image)


def configure_scene(scene, output_dir: pathlib.Path, elevation: float, pixels_per_meter: float):
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.resolution_percentage = 100
    scene.render.image_settings.compression = 15
    scene.render.filepath = str(output_dir / "render.png")
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0
    scene.render.film_transparent = True
    if scene.world is None:
        scene.world = bpy.data.worlds.new("ModelToSpriteWorld")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.45, 0.45, 0.5, 1.0)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.8

    sun_data = bpy.data.lights.new("ModelToSpriteSun", "SUN")
    sun = bpy.data.objects.new("ModelToSpriteSun", sun_data)
    scene.collection.objects.link(sun)
    sun.data.energy = 3.0
    sun.data.angle = math.radians(0.526)

    camera_data = bpy.data.cameras.new("ModelToSpriteCamera")
    camera = bpy.data.objects.new("ModelToSpriteCamera", camera_data)
    scene.collection.objects.link(camera)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 128.0 / pixels_per_meter
    camera_data.shift_y = (ROOT_PIXEL[1] - 64) / 128.0
    scene.camera = camera
    elevation_radians = math.radians(elevation)

    def shoot(direction: str, size: int, path: pathlib.Path):
        azimuth = math.radians(AZIMUTH_DEGREES[direction])
        camera.location = (10.0 * math.sin(azimuth) * math.cos(elevation_radians),
                           -10.0 * math.cos(azimuth) * math.cos(elevation_radians),
                           10.0 * math.sin(elevation_radians))
        camera.rotation_euler = (Vector((0.0, 0.0, 0.0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
        sun.rotation_euler = (math.radians(50.0), 0.0, azimuth - math.radians(35.0))
        scene.render.resolution_x = size
        scene.render.resolution_y = size
        scene.render.filter_size = 0.0 if size == 128 else 1.5
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)

    return shoot


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) != 5:
        fail("USAGE_EXPECTED_INPUT_OUTPUT_ELEVATION_PPM_TARGET_HEIGHT")
    input_path, output_dir = pathlib.Path(args[0]), pathlib.Path(args[1])
    elevation, ppm, target_height = map(float, args[2:])
    if not input_path.is_file() or not output_dir.is_dir():
        fail("INPUT_OR_OUTPUT_MISSING")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.gltf(filepath=str(input_path))
    except Exception as exc:
        fail("GLB_IMPORT_FAILED:" + type(exc).__name__)
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if not meshes:
        fail("NO_MESH")
    if any(obj.parent and obj.parent.type == "ARMATURE" for obj in meshes) or any(
            any(name in group.name.lower() for group in obj.vertex_groups) for obj in meshes):
        fail("RIGGED_MODEL_REJECTED_USE_ANIMATION_COMPILER")
    broken_images = [image.name for image in bpy.data.images if image.size[0] <= 0 or image.size[1] <= 0]
    if broken_images:
        fail("TEXTURE_IMPORT_FAILED:" + ",".join(sorted(broken_images)))

    scene = bpy.context.scene
    root = bpy.data.objects.new("MODEL_TO_SPRITE_ROOT", None)
    scene.collection.objects.link(root)
    for obj in [o for o in bpy.data.objects if o is not root and o.parent is None]:
        obj.parent = root
    shoot = configure_scene(scene, output_dir, elevation, ppm)

    lower, upper = set_placement(root, meshes, 1.0)
    raw_height_m = upper[2] - lower[2]
    if raw_height_m <= 1e-6:
        fail("ZERO_MODEL_HEIGHT")
    fitted_scale = 1.0
    scale_probe = []
    probe = output_dir / "_scale_probe.png"
    for _ in range(4):
        set_placement(root, meshes, fitted_scale)
        shoot("S", 128, probe)
        measured = rgba_height(probe)
        scale_probe.append({"scale": fitted_scale, "s_height_px": measured})
        if measured <= 0:
            fail("EMPTY_S_VIEW")
        if abs(measured - target_height) <= 0.5:
            break
        fitted_scale *= target_height / measured
    probe.unlink(missing_ok=True)
    lower, upper = set_placement(root, meshes, fitted_scale)
    for size in (128, 512):
        for direction in DIRECTIONS:
            shoot(direction, size, output_dir / f"{size}_{direction}.png")

    dimensions = upper[0] - lower[0], upper[1] - lower[1], upper[2] - lower[2]
    report = {
        "blender_version": bpy.app.version_string,
        "engine": scene.render.engine,
        "color_management": {"view_transform": scene.view_settings.view_transform, "look": scene.view_settings.look,
                             "exposure": scene.view_settings.exposure, "gamma": scene.view_settings.gamma},
        "model": {"mesh_count": len(meshes), "vertices": sum(len(obj.data.vertices) for obj in meshes),
                  "triangles": sum(len(poly.vertices) == 3 for obj in meshes for poly in obj.data.polygons)},
        "normalization": {"raw_height_m": raw_height_m, "applied_uniform_scale": fitted_scale,
                          "normalized_dimensions_m": list(dimensions), "scale_fit_view": "S",
                          "target_s_height_px": target_height, "scale_probe": scale_probe},
        "camera": {"projection": "orthographic", "elevation_degrees": elevation, "pixels_per_meter": ppm,
                   "ortho_scale": 128.0 / ppm, "root_pixel": list(ROOT_PIXEL),
                   "directions": list(DIRECTIONS), "mirroring": False,
                   "registration": "fixed_common_origin_all_directions"},
        "render_sizes": [128, 512],
    }
    print("MODEL_TO_SPRITE_RENDER_JSON:" + json.dumps(report, sort_keys=True, separators=(",", ":")), flush=True)


if __name__ == "__main__":
    main()
