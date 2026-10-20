"""Deterministic Blender render pass for the Broken Warrant pixel proof.

This script never saves the Blender file. Render-only LOD toggles and emission
mask materials exist only in this process and are restored before exit.
"""
from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
SOURCE_DIR = REPO / "custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d"
DEFAULT_BLEND = SOURCE_DIR / "broken_warrant_material_master_source.blend"
DEFAULT_OUT = SOURCE_DIR / "proof"

sys.path.insert(0, str(HERE))
from surface_contract import FRAME_SIZE, ORTHO_SCALE, ROOT_PIXEL, SUPERSAMPLE  # noqa: E402

ANGLE_CAMERAS = {
    "front": "BW_CAMERA_FRONT",
    "three_quarter": "BW_CAMERA_THREE_QUARTER",
    "back": "BW_CAMERA_BACK",
}


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, default=DEFAULT_BLEND)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUT)
    return parser.parse_args(argv)


def projected_bounds(scene, camera, obj, width, height):
    projected = []
    for corner in obj.bound_box:
        world = obj.matrix_world @ Vector(corner)
        p = world_to_camera_view(scene, camera, world)
        projected.append((float(p.x * width), float((1.0 - p.y) * height), float(p.z)))
    xs = [p[0] for p in projected]
    ys = [p[1] for p in projected]
    return {
        "width_px": max(xs) - min(xs),
        "height_px": max(ys) - min(ys),
        "min_x_px": min(xs), "max_x_px": max(xs),
        "min_y_px": min(ys), "max_y_px": max(ys),
    }


def detail_lod(meshes, cameras, scene):
    measurements = {}
    hidden = []
    essential = ("hood", "apron", "mantle", "tank", "cannon", "energy_cable", "backpack", "boot", "pauldron_shell", "luminous", "amber")
    for obj in meshes:
        name = obj.name.split("__", 1)[1].rsplit("__BONE_", 1)[0]
        low = name.lower()
        bounds = {angle: projected_bounds(scene, camera, obj, FRAME_SIZE, FRAME_SIZE) for angle, camera in cameras.items()}
        max_extent = max(max(v["width_px"], v["height_px"]) for v in bounds.values())
        reason = None
        if "insignia_pillar" in low and max_extent < 1.6:
            reason = "subpixel shoulder-symbol pillar omitted in render-only LOD"
        elif "insignia_ring" in low and ("_seg" in low or "_joint" in low) and max_extent < 1.6:
            reason = "subpixel shoulder-symbol ring fragment omitted in render-only LOD"
        elif "rivet" in low and max_extent < 1.15:
            reason = "subpixel rivet omitted in render-only LOD"
        elif any(token in low for token in ("_joint", "_seg")) and max_extent < 0.65 and not any(token in low for token in essential):
            reason = "subpixel mechanical trim omitted in render-only LOD"
        measurements[obj.name] = {"max_extent_px": round(max_extent, 4), "views": bounds, "hidden_reason": reason}
        if reason:
            hidden.append(obj)
    return measurements, hidden


def set_output(scene, filepath, size):
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.render.filepath = str(filepath)


def render(scene, camera, filepath, size):
    set_output(scene, filepath, size)
    scene.camera = camera
    bpy.context.view_layer.update()
    bpy.ops.render.render(write_still=True)
    strip_volatile_png_metadata(filepath)


def strip_volatile_png_metadata(filepath: Path):
    """Remove Blender's timestamp/path/render-time chunks without changing pixels."""
    payload = filepath.read_bytes()
    signature = b"\x89PNG\r\n\x1a\n"
    if not payload.startswith(signature):
        raise RuntimeError(f"Renderer did not write a PNG: {filepath}")
    chunks = []
    offset = len(signature)
    while offset < len(payload):
        length = struct.unpack(">I", payload[offset:offset + 4])[0]
        end = offset + 12 + length
        if end > len(payload):
            raise RuntimeError(f"Malformed PNG chunk at byte {offset}: {filepath}")
        kind = payload[offset + 4:offset + 8]
        if kind not in {b"tEXt", b"zTXt", b"iTXt", b"eXIf"}:
            chunks.append(payload[offset:end])
        offset = end
        if kind == b"IEND":
            break
    if offset != len(payload):
        raise RuntimeError(f"Trailing or malformed PNG data: {filepath}")
    filepath.write_bytes(signature + b"".join(chunks))


def make_emission_mask_material(name, color, strength=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = 0.0
    shader.inputs["Roughness"].default_value = 1.0
    shader.inputs["Alpha"].default_value = 1.0
    emission_socket = "Emission Color" if "Emission Color" in shader.inputs else "Emission"
    shader.inputs[emission_socket].default_value = (*color, 1.0)
    shader.inputs["Emission Strength"].default_value = strength
    material.node_tree.links.new(shader.outputs["BSDF"], out.inputs["Surface"])
    return material


def main():
    cfg = parse_args()
    if not cfg.blend.is_file():
        raise FileNotFoundError(cfg.blend)
    cfg.output.mkdir(parents=True, exist_ok=True)
    native_dir = cfg.output / "native_128"
    super_dir = cfg.output / "supersampled_512"
    mask_dir = cfg.output / "emission_mask_512_raw"
    for folder in (native_dir, super_dir, mask_dir):
        folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(cfg.blend))
    scene = bpy.context.scene
    meshes = [obj for obj in scene.objects if obj.type == "MESH"]
    cameras = {angle: bpy.data.objects[name] for angle, name in ANGLE_CAMERAS.items()}
    if len(meshes) != 503 or any(camera is None for camera in cameras.values()):
        raise RuntimeError(f"Master contract mismatch: meshes={len(meshes)}, cameras={list(cameras)}")
    if any(abs(camera.data.ortho_scale - ORTHO_SCALE) > 1e-6 for camera in cameras.values()):
        raise RuntimeError("Fixed camera orthographic scale mismatch")

    source_poses = {}
    for angle, camera in cameras.items():
        projected_root = world_to_camera_view(scene, camera, Vector((0.0, 0.0, 0.0)))
        root_px = (float(projected_root.x * FRAME_SIZE), float((1.0 - projected_root.y) * FRAME_SIZE))
        source_poses[angle] = {"root_px": root_px, "camera": camera.name, "ortho_scale": camera.data.ortho_scale}

    measurements, hidden = detail_lod(meshes, cameras, scene)
    original_hide_render = {obj.name: obj.hide_render for obj in hidden}
    for obj in hidden:
        obj.hide_render = True

    scene.cycles.seed = 1701
    scene.cycles.use_animated_seed = False
    scene.cycles.use_denoising = False
    scene.cycles.samples = 16
    scene.view_settings.view_transform = "Standard"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except (TypeError, ValueError):
        pass

    for angle, camera in cameras.items():
        render(scene, camera, native_dir / f"{angle}.png", FRAME_SIZE)
        render(scene, camera, super_dir / f"{angle}_512.png", FRAME_SIZE * SUPERSAMPLE)

    # Build an occlusion-correct emission-only mask with all meshes still present.
    # Non-emissive surfaces are opaque black; emissive surfaces are opaque white.
    black = make_emission_mask_material("BW_TEMP_EMISSION_MASK_OCCLUDER", (0.0, 0.0, 0.0), 0.0)
    white = make_emission_mask_material("BW_TEMP_EMISSION_MASK_SOURCE", (1.0, 1.0, 1.0), 1.0)
    original_slots = {obj.name: [slot.material for slot in obj.material_slots] for obj in meshes}
    for obj in meshes:
        semantic = obj.get("bw_semantic_material", "")
        if obj.data.materials:
            obj.data.materials[0] = white if semantic == "emission_amber" else black
        else:
            obj.data.materials.append(white if semantic == "emission_amber" else black)
    for angle, camera in cameras.items():
        render(scene, camera, mask_dir / f"{angle}_emission_mask_512.png", FRAME_SIZE * SUPERSAMPLE)
    for obj in meshes:
        slots = original_slots[obj.name]
        obj.data.materials.clear()
        for material in slots:
            obj.data.materials.append(material)
    for obj in hidden:
        obj.hide_render = original_hide_render[obj.name]

    lod = {
        "schema": "custodian.broken_warrant.render_lod.v1",
        "master_geometry_modified": False,
        "lod_visibility_saved_to_master": False,
        "selection_rule": "subpixel rivets, shoulder emblem fragments and mechanical joints only; evaluated in all three camera projections",
        "hidden_count": len(hidden),
        "hidden_objects": [
            {"name": obj.name, **measurements[obj.name]} for obj in hidden
        ],
        "projected_measurements": measurements,
        "views": source_poses,
        "frame_size": FRAME_SIZE,
        "supersample_factor": SUPERSAMPLE,
        "orthographic_scale": ORTHO_SCALE,
        "pixelation_method": "Pillow NEAREST 4x reduction from 512 to 128, followed by NEAREST 4x enlargement only for the comparison sheet",
        "human_art_acceptance": "pending",
    }
    (cfg.output / "render_only_lod.json").write_text(json.dumps(lod, indent=2) + "\n")
    bpy.data.materials.remove(black, do_unlink=True)
    bpy.data.materials.remove(white, do_unlink=True)
    print("PIXEL_PROOF_RENDERED", json.dumps({"native_128": str(native_dir), "supersampled_512": str(super_dir), "emission_mask_512": str(mask_dir), "hidden_render_only_count": len(hidden), "views": source_poses}))
    # Intentionally do not save; all temporary visibility/material changes are render-only.


if __name__ == "__main__":
    main()
