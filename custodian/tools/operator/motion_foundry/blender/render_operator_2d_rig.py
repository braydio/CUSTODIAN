#!/usr/bin/env python3
"""Render a saved Operator 2D cutout rig from Blender, including its preview."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

import bpy


def args_after_double_dash() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])


def main() -> None:
    args = args_after_double_dash()
    blend = args.blend.resolve()
    output_dir = args.output_dir.resolve()
    source_root = args.source_root.resolve()
    if not blend.is_file():
        raise SystemExit(f"saved Blender rig does not exist: {blend}")
    bpy.ops.wm.open_mainfile(filepath=str(blend))
    scene = bpy.context.scene
    camera = scene.camera
    if camera is None or camera.data.type != "ORTHO" or camera.data.ortho_scale != 128:
        raise SystemExit("rig camera must remain orthographic at exactly 128 pixels")
    if (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage) != (128, 128, 100):
        raise SystemExit("rig render dimensions must remain 128x128 at 100 percent")
    armatures = [obj for obj in scene.objects if obj.type == "ARMATURE"]
    if len(armatures) != 1 or len(armatures[0].data.bones) != 23:
        raise SystemExit("saved rig must contain exactly 23 controls")
    rig = json.loads((source_root / "extracted/rig.json").read_text())
    armature = armatures[0]
    expected = {part["id"]: part for part in rig["parts"]}
    if set(armature.data.bones.keys()) != set(expected):
        raise SystemExit("saved control names do not match the source rig")
    for part_id, part in expected.items():
        bone = armature.data.bones[part_id]
        actual_parent = bone.parent.name if bone.parent else None
        if actual_parent != part.get("parent"):
            raise SystemExit(f"saved parent differs from source rig: {part_id}")
        expected_head = (part["pivot"][0], 128 - part["pivot"][1], 0.0)
        if any(abs(bone.head_local[i] - expected_head[i]) > 1e-5 for i in range(3)):
            raise SystemExit(f"saved pivot differs from source rig: {part_id}")
    planes = [obj for obj in scene.objects if obj.get("part_id") and obj.type == "MESH"]
    if len(planes) != 18 or len({obj["part_id"] for obj in planes}) != 18:
        raise SystemExit("saved rig must contain 18 unique populated image planes")
    source_images = [image for image in bpy.data.images if image.source == "FILE"]
    if len(source_images) != 18 or any(not image.packed_file for image in source_images):
        raise SystemExit("all 18 populated source images must be packed into the saved Blender file")
    if scene.frame_start != 1 or scene.frame_end != 15 or scene.render.fps != 12:
        raise SystemExit("preview must remain a 15-frame, preview-only scene")
    if scene.render.engine != "BLENDER_EEVEE" or scene.render.image_settings.color_depth != "16":
        raise SystemExit("saved rig must use deterministic EEVEE 16-bit RGBA rendering")
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "16"
    scene.render.resolution_percentage = 100
    output_dir.mkdir(parents=True, exist_ok=True)
    for frame in range(1, 16):
        scene.frame_set(frame)
        scene.render.filepath = str(output_dir / f"frame_{frame - 1:03d}.png")
        bpy.ops.render.render(write_still=True)
    scene.frame_set(1)
    scene.render.filepath = str(output_dir / "neutral.png")
    bpy.ops.render.render(write_still=True)
    print(f"rendered_saved_blend={blend} frames=15 output={output_dir}")


if __name__ == "__main__":
    main()
