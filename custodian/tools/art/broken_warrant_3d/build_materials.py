"""Build an editable, rigged Broken Warrant material master in Blender.

Run from the repository root:
  blender --background --factory-startup --python custodian/tools/art/broken_warrant_3d/build_materials.py -- --output <path>
Only the original untextured source GLB is imported. Turnaround image use is
limited to a packed, unconnected design-reference image datablock.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import struct
import sys
from collections import Counter
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
SOURCE_DIR = REPO / "custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d"
DEFAULT_SOURCE = SOURCE_DIR / "Broken_Warrant_3D_Master_source.glb"
DEFAULT_REFERENCE = SOURCE_DIR / "broken_warrant_turnaround_source.png"
DEFAULT_OUTPUT = SOURCE_DIR / "broken_warrant_material_master_source.blend"
PROOF_DIR = SOURCE_DIR / "proof"

sys.path.insert(0, str(HERE))
from surface_contract import (  # noqa: E402
    EXPECTED_BONES, EXPECTED_BONE_NAMES, EXPECTED_MESHES, EXPECTED_TRIANGLES,
    FRAME_SIZE, ROOT_PIXEL, ORTHO_SCALE, assigned_bone, material_for_part, split_source_name,
)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--reference", type=Path, default=DEFAULT_REFERENCE)
    parser.add_argument("--palette", type=Path, default=HERE / "material_palette.json")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args(argv)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def srgb_to_linear(value: float) -> float:
    value /= 255.0
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def hex_rgb(value: str) -> tuple[float, float, float, float]:
    color = value.lstrip("#")
    return tuple(srgb_to_linear(int(color[i:i + 2], 16)) for i in (0, 2, 4)) + (1.0,)


def scaled_color(base: tuple[float, ...], factor: float) -> tuple[float, float, float, float]:
    return tuple(min(1.0, max(0.0, base[i] * factor)) for i in range(3)) + (1.0,)


def build_material(name: str, spec: dict):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    mat.diffuse_color = hex_rgb(spec["hex"])
    mat["bw_semantic_material"] = name
    mat["bw_opaque"] = True
    mat["bw_treatment"] = spec["treatment"]
    mat.pass_index = 1 if name == "emission_amber" else 0

    tree = mat.node_tree
    nodes = tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (640, 40)
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.location = (360, 40)
    shader.inputs["Base Color"].default_value = hex_rgb(spec["hex"])
    shader.inputs["Metallic"].default_value = float(spec["metallic"])
    shader.inputs["Roughness"].default_value = float(spec["roughness"])
    shader.inputs["Alpha"].default_value = 1.0
    if name == "emission_amber":
        emission_socket = "Emission Color" if "Emission Color" in shader.inputs else "Emission"
        shader.inputs[emission_socket].default_value = hex_rgb(spec["hex"])
        shader.inputs["Emission Strength"].default_value = float(spec["emission_strength"])

    tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    if float(spec["color_variation"]) > 0:
        geometry = nodes.new("ShaderNodeNewGeometry")
        geometry.location = (-900, 220)
        broad = nodes.new("ShaderNodeTexNoise")
        broad.location = (-680, 220)
        broad.inputs["Scale"].default_value = float(spec["noise_scale"])
        broad.inputs["Detail"].default_value = 2.0
        broad.inputs["Roughness"].default_value = 0.68
        tree.links.new(geometry.outputs["Position"], broad.inputs["Vector"])
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-360, 220)
        base = hex_rgb(spec["hex"])
        amplitude = float(spec["color_variation"])
        ramp.color_ramp.elements[0].position = 0.12
        ramp.color_ramp.elements[0].color = scaled_color(base, 1.0 - amplitude)
        ramp.color_ramp.elements[1].position = 0.88
        ramp.color_ramp.elements[1].color = scaled_color(base, 1.0 + amplitude)
        tree.links.new(broad.outputs["Fac"], ramp.inputs["Fac"])
        tree.links.new(ramp.outputs["Color"], shader.inputs["Base Color"])

        micro = nodes.new("ShaderNodeTexNoise")
        micro.location = (-660, -160)
        micro.inputs["Scale"].default_value = float(spec["micro_scale"])
        micro.inputs["Detail"].default_value = 1.4
        micro.inputs["Roughness"].default_value = 0.58
        tree.links.new(geometry.outputs["Position"], micro.inputs["Vector"])
        bump = nodes.new("ShaderNodeBump")
        bump.location = (100, -100)
        bump.inputs["Strength"].default_value = float(spec["bump_strength"])
        bump.inputs["Distance"].default_value = float(spec["bump_distance"])
        tree.links.new(micro.outputs["Fac"], bump.inputs["Height"])
        tree.links.new(bump.outputs["Normal"], shader.inputs["Normal"])

        roughness_variation = float(spec["roughness_variation"])
        if roughness_variation > 0:
            rough = nodes.new("ShaderNodeMapRange")
            rough.location = (-80, -340)
            rough.clamp = True
            rough.inputs["From Min"].default_value = 0.0
            rough.inputs["From Max"].default_value = 1.0
            rough.inputs["To Min"].default_value = max(0.0, float(spec["roughness"]) - roughness_variation)
            rough.inputs["To Max"].default_value = min(1.0, float(spec["roughness"]) + roughness_variation)
            tree.links.new(micro.outputs["Fac"], rough.inputs["Value"])
            tree.links.new(rough.outputs["Result"], shader.inputs["Roughness"])
    return mat


def geometry_fingerprint(mesh_objects) -> str:
    digest = hashlib.sha256()
    for obj in sorted(mesh_objects, key=lambda item: item.name):
        digest.update(obj.name.encode("utf-8"))
        digest.update(b"\0")
        for vertex in obj.data.vertices:
            digest.update(struct.pack("<fff", *vertex.co))
        for polygon in obj.data.polygons:
            digest.update(struct.pack("<I", len(polygon.vertices)))
            for index in polygon.vertices:
                digest.update(struct.pack("<I", index))
        for row in obj.matrix_world:
            for value in row:
                digest.update(struct.pack("<d", float(value)))
    return digest.hexdigest()


def create_bone(armature, name, head, tail, parent=None):
    # The glTF carries Z-up coordinates. Blender import maps source +Z to world -Y.
    head = (head[0], -head[2], head[1])
    tail = (tail[0], -tail[2], tail[1])
    bone = armature.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.use_connect = False
    if parent:
        bone.parent = armature.edit_bones[parent]
    return bone


def create_rig():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    rig = bpy.context.object
    rig.name = "BW_CHARACTER_RIG"
    rig.data.name = "BW_HUMANOID_SKELETON_15"
    armature = rig.data
    for bone in list(armature.edit_bones):
        armature.edit_bones.remove(bone)

    create_bone(armature, "Root", (0, 0, 0), (0, 0, 0.55))
    create_bone(armature, "Hips", (0, 0, 1.86), (0, 0, 2.05), "Root")
    create_bone(armature, "Spine", (0, 0, 2.05), (0, 0, 2.36), "Hips")
    create_bone(armature, "Chest", (0, 0, 2.36), (0, 0, 2.75), "Spine")
    create_bone(armature, "Neck", (0, 0, 2.74), (0, 0, 2.92), "Chest")
    create_bone(armature, "Head", (0, 0, 2.92), (0, 0, 3.48), "Neck")
    create_bone(armature, "Backpack", (0, 0.45, 2.72), (0, 0.60, 3.40), "Chest")
    for side, sign in (("R", -1), ("L", 1)):
        x = sign * 0.63
        create_bone(armature, f"UpperArm.{side}", (x, 0, 2.63), (sign * 0.76, 0, 2.14), "Chest")
        create_bone(armature, f"Forearm.{side}", (sign * 0.76, 0, 2.14), (sign * 0.81, -0.07, 1.59), f"UpperArm.{side}")
        create_bone(armature, f"UpperLeg.{side}", (sign * 0.265, 0, 1.85), (sign * 0.29, 0, 1.02), "Hips")
        create_bone(armature, f"LowerLeg.{side}", (sign * 0.29, 0, 1.02), (sign * 0.29, 0, 0.25), f"UpperLeg.{side}")
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    rig.display_type = "WIRE"
    return rig


def move_to_collection(obj, collection):
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def point_at(obj, point):
    # Construct a camera frame with local +Y explicitly aligned to source up (-Y).
    forward = (Vector(point) - obj.location).normalized()
    up = Vector((0.0, -1.0, 0.0))
    right = forward.cross(up).normalized()
    up = right.cross(forward).normalized()
    rotation = Matrix((right, up, -forward)).transposed().to_4x4()
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = rotation.to_quaternion()


def create_camera(name, eye, target, collection):
    bpy.ops.object.camera_add(location=eye)
    camera = bpy.context.object
    camera.name = name
    camera.data.name = f"{name}_ORTHO"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ORTHO_SCALE
    camera.data.lens = 50.0
    point_at(camera, target)
    move_to_collection(camera, collection)
    return camera


def create_area_light(name, location, energy, size, color, collection):
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.name = name
    light.data.name = f"{name}_DATA"
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    light.data.color = color
    point_at(light, (0.0, 0.0, 1.9))
    move_to_collection(light, collection)
    return light


def configure_stage():
    scene = bpy.context.scene
    stage = bpy.data.collections.new("BW_STUDIO")
    scene.collection.children.link(stage)
    # Camera optical center registers the source origin at (64,106).
    target_y = -(ROOT_PIXEL[1] - FRAME_SIZE / 2) * ORTHO_SCALE / FRAME_SIZE
    oblique_target_y = target_y
    cameras = {
        "front": create_camera("BW_CAMERA_FRONT", (0.0, target_y, -9.0), (0.0, target_y, 0.0), stage),
        "three_quarter": create_camera("BW_CAMERA_THREE_QUARTER", (5.0, oblique_target_y, -7.70), (0.0, oblique_target_y, 0.0), stage),
        "back": create_camera("BW_CAMERA_BACK", (0.0, target_y, 9.0), (0.0, target_y, 0.0), stage),
    }
    create_area_light("BW_KEY_SOFTBOX", (-3.0, -8.0, -5.0), 900.0, 6.0, (1.0, 0.87, 0.74), stage)
    create_area_light("BW_FILL_SOFTBOX", (4.0, -5.0, -2.0), 550.0, 5.0, (0.77, 0.86, 1.0), stage)
    create_area_light("BW_RIM_WARM", (0.0, -6.0, 4.0), 1000.0, 4.0, (1.0, 0.63, 0.30), stage)

    world = bpy.data.worlds.new("BW_STAGE_WORLD")
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.035, 0.038, 0.045, 1.0)
    background.inputs["Strength"].default_value = 0.28
    scene.world = world
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.cycles.seed = 1701
    scene.cycles.use_animated_seed = False
    scene.cycles.use_denoising = False
    scene.render.resolution_x = 128
    scene.render.resolution_y = 128
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.render.use_file_extension = True
    scene.view_settings.view_transform = "Standard"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except (TypeError, ValueError):
        pass
    scene.camera = cameras["three_quarter"]
    return cameras


def main():
    cfg = parse_args()
    for path in (cfg.source, cfg.reference, cfg.palette):
        if not path.is_file():
            raise FileNotFoundError(path)
    if cfg.source.resolve() == DEFAULT_SOURCE.resolve() and sha256(cfg.source) != "e1a9ef843561a7a31b0ba60600de97d909fbfe8a780b9c0882b3ef7bc6ea4ea6":
        raise RuntimeError("The original source GLB hash does not match the pinned handoff manifest")
    if cfg.reference.resolve() == DEFAULT_REFERENCE.resolve() and sha256(cfg.reference) != "5f7eaf60f54164896fe7284f8963cab13c00b18fc934fe982c5a1acb309cc7ac":
        raise RuntimeError("The original design reference hash does not match the pinned handoff manifest")

    palette = json.loads(cfg.palette.read_text())
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(cfg.source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != EXPECTED_MESHES:
        raise RuntimeError(f"Expected {EXPECTED_MESHES} source meshes, imported {len(meshes)}")
    triangle_count = sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons)
    if triangle_count != EXPECTED_TRIANGLES:
        raise RuntimeError(f"Expected {EXPECTED_TRIANGLES} triangles, imported {triangle_count}")
    source_names = [obj.name for obj in meshes]
    if len(source_names) != len(set(source_names)):
        raise RuntimeError("Blender importer produced duplicate source mesh names")

    # Make direct world transforms explicit before removing importer-only empty nodes.
    for obj in meshes:
        world_matrix = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world_matrix
    for obj in [o for o in bpy.context.scene.objects if o.type not in {"MESH"}]:
        bpy.data.objects.remove(obj, do_unlink=True)

    original_fingerprint = geometry_fingerprint(meshes)
    character_collection = bpy.data.collections.new("BW_CHARACTER_MESHES")
    bpy.context.scene.collection.children.link(character_collection)
    for obj in meshes:
        move_to_collection(obj, character_collection)

    materials = {
        name: build_material(name, spec)
        for name, spec in palette["materials"].items()
    }
    material_counts = Counter()
    bone_counts = Counter()
    assignments = []
    for obj in meshes:
        part, source_bone = split_source_name(obj.name)
        material_name = material_for_part(part)
        if material_name not in materials:
            raise RuntimeError(f"Uncategorized mesh or unknown material: {obj.name} -> {material_name}")
        rig_bone = assigned_bone(source_bone)
        if rig_bone not in EXPECTED_BONE_NAMES:
            raise RuntimeError(f"Unresolved source bone: {obj.name} -> {source_bone} -> {rig_bone}")
        obj.data.materials.clear()
        obj.data.materials.append(materials[material_name])
        obj["bw_source_mesh_name"] = obj.name
        obj["bw_source_part"] = part
        obj["bw_source_bone"] = source_bone
        obj["bw_rig_bone"] = rig_bone
        obj["bw_semantic_material"] = material_name
        material_counts[material_name] += 1
        bone_counts[rig_bone] += 1
        assignments.append({
            "source_mesh": obj.name,
            "part": part,
            "source_bone": source_bone,
            "rig_bone": rig_bone,
            "semantic_material": material_name,
            "vertices": len(obj.data.vertices),
            "triangles": sum(len(poly.vertices) - 2 for poly in obj.data.polygons),
        })

    rig = create_rig()
    rig_collection = bpy.data.collections.new("BW_RIG")
    bpy.context.scene.collection.children.link(rig_collection)
    move_to_collection(rig, rig_collection)
    if len(rig.data.bones) != EXPECTED_BONES or set(rig.data.bones.keys()) != set(EXPECTED_BONE_NAMES):
        raise RuntimeError(f"Rig bone mismatch: {len(rig.data.bones)} {sorted(rig.data.bones.keys())}")
    for obj in meshes:
        bone = obj["bw_rig_bone"]
        group = obj.vertex_groups.new(name=bone)
        if len(obj.data.vertices):
            group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new("BW_Rigid_Plate_Armature", "ARMATURE")
        modifier.object = rig
        modifier.use_deform_preserve_volume = True
        obj["bw_assignment_weight"] = 1.0
        obj.hide_select = False

    final_fingerprint = geometry_fingerprint(meshes)
    if final_fingerprint != original_fingerprint:
        raise RuntimeError("Source mesh geometry or world transforms changed during material/rig build")
    cameras = configure_stage()

    reference = bpy.data.images.load(str(cfg.reference), check_existing=False)
    reference.name = "BW_PACKED_DESIGN_REFERENCE_8VIEW"
    reference.use_fake_user = True
    reference["bw_reference_only"] = True
    reference["bw_source_sha256"] = sha256(cfg.reference)
    reference.pack()

    scene = bpy.context.scene
    scene["character"] = "Broken Warrant"
    scene["asset_stage"] = "SOURCE-ONLY 3D MATERIAL MASTER - human art acceptance pending"
    scene["bw_source_glb_sha256"] = sha256(cfg.source)
    scene["bw_reference_sha256"] = sha256(cfg.reference)
    scene["bw_geometry_fingerprint"] = original_fingerprint
    scene["bw_mesh_count"] = len(meshes)
    scene["bw_triangle_count"] = triangle_count
    scene["bw_bone_count"] = len(rig.data.bones)
    scene["bw_material_palette_sha256"] = sha256(cfg.palette)
    scene["bw_source_reference_policy"] = "packed design reference datablock only; never connected to mesh shaders"
    scene["bw_proof_registration"] = "128x128; root=(64,106); ground_y=107"
    scene["bw_render_only_lod_policy"] = "renderer toggles visibility in memory and does not save or edit master geometry"
    scene["bw_human_art_acceptance"] = "pending"
    scene.render.filepath = "//proof/"

    # Preserve a useful authoring state and pose-ready rig on open.
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    try:
        bpy.ops.object.mode_set(mode="POSE")
    except RuntimeError:
        pass

    cfg.output.parent.mkdir(parents=True, exist_ok=True)
    PROOF_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(cfg.output))
    report = {
        "schema": "custodian.broken_warrant.material_build.v1",
        "source_glb_sha256": sha256(cfg.source),
        "reference_sha256": sha256(cfg.reference),
        "palette_sha256": sha256(cfg.palette),
        "blend_path": str(cfg.output),
        "mesh_count": len(meshes),
        "triangles": triangle_count,
        "bone_count": len(rig.data.bones),
        "bone_names": list(EXPECTED_BONE_NAMES),
        "source_bone_aliases": dict(sorted(__import__("surface_contract").SOURCE_BONE_ALIASES.items())),
        "material_mesh_counts": dict(sorted(material_counts.items())),
        "rig_mesh_counts": dict(sorted(bone_counts.items())),
        "geometry_fingerprint_before": original_fingerprint,
        "geometry_fingerprint_after": final_fingerprint,
        "mesh_assignments": assignments,
        "image_datablocks": [{"name": image.name, "packed": image.packed_file is not None, "connected_to_shader": False} for image in bpy.data.images],
        "human_art_acceptance": "pending",
    }
    (PROOF_DIR / "material_build_report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("WROTE_BLEND", cfg.output, cfg.output.stat().st_size)
    print("MATERIAL_BUILD", json.dumps({k: report[k] for k in ("mesh_count", "triangles", "bone_count", "material_mesh_counts", "geometry_fingerprint_after")}))


if __name__ == "__main__":
    main()
