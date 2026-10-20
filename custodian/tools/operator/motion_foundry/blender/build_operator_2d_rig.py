#!/usr/bin/env python3
"""Build a hash-pinned, editable 2D Operator cutout rig in Blender."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector


SCHEMA = "custodian.motion_foundry.rig.v1"
SIZE = 128


def args_after_double_dash() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pixel_world(x: float, y: float) -> Vector:
    return Vector((x, SIZE - y, 0.0))


def read_inputs(root: Path) -> tuple[dict, list[tuple[dict, Path]]]:
    rig_path = root / "extracted/rig.json"
    rig = json.loads(rig_path.read_text())
    if rig.get("schema") != SCHEMA or rig.get("direction") != "s":
        raise RuntimeError("expected the pinned south-facing Motion Foundry rig schema")
    if rig.get("frame_size") != [SIZE, SIZE] or len(rig.get("parts", [])) != 23:
        raise RuntimeError("expected exactly 23 128x128 rig parts")
    entries = []
    seen = set()
    for part in rig["parts"]:
        part_id = part["id"]
        if part_id in seen:
            raise RuntimeError(f"duplicate part id: {part_id}")
        seen.add(part_id)
        path = (root / "extracted/parts" / part["source"]).resolve()
        if path.parent != (root / "extracted/parts").resolve() or not path.is_file():
            raise RuntimeError(f"invalid or missing source part: {part_id}")
        if sha(path) != part["sha256"]:
            raise RuntimeError(f"source part hash mismatch: {part_id}")
        if len(part.get("pivot", [])) != 2:
            raise RuntimeError(f"invalid pivot: {part_id}")
        entries.append((part, path))
    ids = {part["id"] for part, _ in entries}
    if any(part.get("parent") is not None and part["parent"] not in ids for part, _ in entries):
        raise RuntimeError("rig references an undeclared parent")
    # Fail closed on cycles.
    parents = {part["id"]: part.get("parent") for part, _ in entries}
    for part_id in parents:
        cursor, visited = part_id, set()
        while cursor is not None:
            if cursor in visited:
                raise RuntimeError(f"parent cycle at {part_id}")
            visited.add(cursor)
            cursor = parents[cursor]
    return rig, entries


def emission_material(image: bpy.types.Image, name: str) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.surface_render_method = "BLENDED"
    nodes, links = material.node_tree.nodes, material.node_tree.links
    nodes.clear()
    image_node = nodes.new("ShaderNodeTexImage")
    image_node.image = image
    image_node.interpolation = "Closest"
    image_node.extension = "CLIP"
    emission = nodes.new("ShaderNodeEmission")
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    output = nodes.new("ShaderNodeOutputMaterial")
    links.new(image_node.outputs["Color"], emission.inputs["Color"])
    binary_alpha = nodes.new("ShaderNodeMath")
    binary_alpha.operation = "GREATER_THAN"
    binary_alpha.inputs[1].default_value = 0.5
    links.new(image_node.outputs["Alpha"], binary_alpha.inputs[0])
    links.new(binary_alpha.outputs[0], mix.inputs["Fac"])
    links.new(transparent.outputs["BSDF"], mix.inputs[1])
    links.new(emission.outputs["Emission"], mix.inputs[2])
    links.new(mix.outputs["Shader"], output.inputs["Surface"])
    return material


def main() -> None:
    args = args_after_double_dash()
    root = args.source_root.resolve()
    output = args.output.resolve()
    receipt_path = args.receipt.resolve()
    rig, entries = read_inputs(root)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for data in list(bpy.data.collections):
        if data.name != "Collection":
            bpy.data.collections.remove(data)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 1
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "16"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Raw"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0
    scene.render.image_settings.color_management = "FOLLOW_SCENE"
    scene.render.filepath = "//neutral.png"
    scene.camera = None

    root_collection = scene.collection
    rig_collection = bpy.data.collections.new("Operator South 2D Rig")
    root_collection.children.link(rig_collection)
    source_collection = bpy.data.collections.new("Source Layers • 128px")
    root_collection.children.link(source_collection)

    arm_data = bpy.data.armatures.new("OperatorSouthRig")
    armature = bpy.data.objects.new("Operator South • Cutout Controls", arm_data)
    rig_collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bones = {}
    for part, _ in entries:
        bone = arm_data.edit_bones.new(part["id"])
        bone.head = pixel_world(*part["pivot"])
        bone.tail = bone.head + Vector((0.0, 2.0, 0.0))
        bone.use_connect = False
        bones[part["id"]] = bone
    for part, _ in entries:
        if part.get("parent"):
            bones[part["id"]].parent = bones[part["parent"]]
    bpy.ops.object.mode_set(mode="OBJECT")
    armature["rig_schema"] = SCHEMA
    armature["direction"] = "s"
    armature["root_pixel"] = rig["root"]
    armature["ground_pixel"] = rig["ground"]
    armature["authored_fps"] = "null"

    # Image plane uses exact cell bounds and UVs; all vertices follow one
    # declared part control through an armature modifier.
    image_hashes = {}
    populated, empty = 0, 0
    for part, path in entries:
        image = bpy.data.images.load(str(path), check_existing=False)
        image.colorspace_settings.name = "Non-Color"
        image.pack()
        image_hashes[part["id"]] = sha(path)
        pixels = list(image.pixels)
        has_alpha = any(pixels[i] > 0.0 for i in range(3, len(pixels), 4))
        if not has_alpha:
            empty += 1
            image["guide_only"] = True
            image["part_id"] = part["id"]
            continue
        populated += 1
        mesh = bpy.data.meshes.new(f"{part['id']} • image plane")
        x0, x1, y0, y1 = 0.0, SIZE, 0.0, SIZE
        z = float(part["draw_order"]) / 1000.0
        mesh.from_pydata(
            [(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)],
            [],
            [(0, 1, 2, 3)],
        )
        uv = mesh.uv_layers.new(name="Source cell UV")
        for loop, value in zip(uv.data, [(0, 0), (1, 0), (1, 1), (0, 1)]):
            loop.uv = value
        obj = bpy.data.objects.new(f"Layer • {part['id']}", mesh)
        source_collection.objects.link(obj)
        obj.location = (0.0, 0.0, 0.0)
        obj["part_id"] = part["id"]
        obj["source_sha256"] = part["sha256"]
        obj["draw_order"] = part["draw_order"]
        obj["pivot_pixel"] = part["pivot"]
        obj.data.materials.append(emission_material(image, f"MAT • {part['id']}"))
        group = obj.vertex_groups.new(name=part["id"])
        group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new("2D cutout control", "ARMATURE")
        modifier.object = armature
        modifier.use_vertex_groups = True

    if (populated, empty) != (18, 5):
        raise RuntimeError(f"expected 18 visible and 5 empty parts, got {populated}/{empty}")

    camera_data = bpy.data.cameras.new("South Orthographic • 128px")
    camera = bpy.data.objects.new("Camera • Source Registration", camera_data)
    rig_collection.objects.link(camera)
    camera.location = (64.0, 64.0, 300.0)
    camera.rotation_euler = (0.0, 0.0, 0.0)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = SIZE
    scene.camera = camera
    camera["projection"] = "orthographic"

    # Preview-only breathing is intentionally limited to the upper-arm roots;
    # planted legs and world root have no animation channels.
    scene.frame_start, scene.frame_end = 1, 15
    scene.render.fps = 12
    for bone_name, amount in (("arm_upper_screen_left", 0.04), ("arm_upper_screen_right", -0.04)):
        pose_bone = armature.pose.bones[bone_name]
        pose_bone.rotation_mode = "XYZ"
        for frame, angle in ((1, 0.0), (8, amount), (15, 0.0)):
            pose_bone.rotation_euler.z = angle
            pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)
    scene.frame_set(1)
    scene["preview_only"] = True
    scene["authored_fps"] = "null"
    scene["rig_note"] = "South-facing 2D cutout source-work candidate; no art approval implied."

    # Keep a useful front-ortho viewport on open.
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.region_3d.view_perspective = "CAMERA"

    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(output), compress=True)
    receipt = {
        "schema": "custodian.operator_motion_foundry.blender_rig_receipt.v1",
        "status": "candidate_not_art_approved",
        "direction": "s",
        "frame_size": [SIZE, SIZE],
        "rig_schema": SCHEMA,
        "source_reference_sha256": sha(root / "source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite"),
        "rig_json_sha256": sha(root / "extracted/rig.json"),
        "reference_profile_sha256": rig["reference_profile_sha256"],
        "blender_version": bpy.app.version_string,
        "part_count": len(entries),
        "visible_planes": populated,
        "empty_guide_parts": empty,
        "parts": [
            {"id": part["id"], "parent": part.get("parent"), "pivot": part["pivot"],
             "draw_order": part["draw_order"], "sha256": image_hashes[part["id"]]}
            for part, _ in entries
        ],
        "preview": {"frames": 15, "fps": 12, "authored_fps": None, "preview_only": True},
        "blend_sha256": sha(output),
        "neutral_render": {"path": None, "mismatched_pixels": None},
        "human_review": "Joint seams and idle presentation remain unapproved; inspect the compact proof before any later art decision.",
    }
    receipt_path.parent.mkdir(parents=True, exist_ok=True)
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"blend": str(output), "receipt": str(receipt_path), "parts": len(entries), "planes": populated}))


if __name__ == "__main__":
    main()
