"""Reopen and validate the packed Blender material master.

Run:
  blender --background --factory-startup --python validate_materials.py -- --blend <master.blend> --output <proof/material_master_validation.json>
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
SOURCE_DIR = REPO / "custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d"
sys.path.insert(0, str(HERE))
from build_materials import geometry_fingerprint  # noqa: E402
from surface_contract import EXPECTED_BONE_NAMES, EXPECTED_BONES, EXPECTED_MESHES, EXPECTED_TRIANGLES, ORTHO_SCALE  # noqa: E402


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, default=SOURCE_DIR / "broken_warrant_material_master_source.blend")
    parser.add_argument("--source", type=Path, default=SOURCE_DIR / "Broken_Warrant_3D_Master_source.glb")
    parser.add_argument("--reference", type=Path, default=SOURCE_DIR / "broken_warrant_turnaround_source.png")
    parser.add_argument("--palette", type=Path, default=HERE / "material_palette.json")
    parser.add_argument("--output", type=Path, default=SOURCE_DIR / "proof/material_master_validation.json")
    return parser.parse_args(argv)


def main():
    cfg = parse_args()
    for path in (cfg.blend, cfg.source, cfg.reference, cfg.palette):
        if not path.is_file():
            raise FileNotFoundError(path)
    bpy.ops.wm.open_mainfile(filepath=str(cfg.blend))
    scene = bpy.context.scene
    meshes = [obj for obj in scene.objects if obj.type == "MESH"]
    armatures = [obj for obj in scene.objects if obj.type == "ARMATURE"]
    triangles = sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons)
    assignments = Counter()
    unknown = []
    material_errors = []
    bone_errors = []
    for obj in meshes:
        semantic = obj.get("bw_semantic_material")
        source_name = obj.get("bw_source_mesh_name")
        if source_name != obj.name or not semantic:
            unknown.append(obj.name)
        if len(obj.data.materials) != 1 or obj.data.materials[0] is None:
            material_errors.append({"mesh": obj.name, "reason": "missing or multiple material slots"})
        else:
            material = obj.data.materials[0]
            assignments[semantic] += 1
            if material.get("bw_semantic_material") != semantic or not material.get("bw_opaque", False):
                material_errors.append({"mesh": obj.name, "reason": "semantic/opaque metadata mismatch"})
            if not material.use_nodes or material.node_tree is None:
                material_errors.append({"mesh": obj.name, "reason": "nodes unavailable"})
            else:
                nodes = list(material.node_tree.nodes)
                forbidden = [node.type for node in nodes if node.type in {"TEX_IMAGE", "BSDF_TRANSPARENT", "HOLDOUT"}]
                if forbidden:
                    material_errors.append({"mesh": obj.name, "reason": f"forbidden shader nodes {forbidden}"})
                principled = [node for node in nodes if node.type == "BSDF_PRINCIPLED"]
                outputs = [node for node in nodes if node.type == "OUTPUT_MATERIAL"]
                if len(principled) != 1 or len(outputs) != 1:
                    material_errors.append({"mesh": obj.name, "reason": "expected one Principled and one Material Output"})
                elif abs(float(principled[0].inputs["Alpha"].default_value) - 1.0) > 1e-7:
                    material_errors.append({"mesh": obj.name, "reason": "material alpha is not opaque"})
                elif principled[0].inputs["Alpha"].is_linked:
                    material_errors.append({"mesh": obj.name, "reason": "alpha has a node connection"})

        rig_bone = obj.get("bw_rig_bone")
        if rig_bone not in EXPECTED_BONE_NAMES:
            bone_errors.append({"mesh": obj.name, "reason": f"invalid bone tag: {rig_bone}"})
            continue
        groups = [group for group in obj.vertex_groups if group.name == rig_bone]
        arm_modifiers = [modifier for modifier in obj.modifiers if modifier.type == "ARMATURE"]
        if len(obj.vertex_groups) != 1 or len(groups) != 1 or len(arm_modifiers) != 1:
            bone_errors.append({"mesh": obj.name, "reason": "expected one rigid vertex group and one armature modifier"})
        elif arm_modifiers[0].object not in armatures or arm_modifiers[0].object.name != "BW_CHARACTER_RIG":
            bone_errors.append({"mesh": obj.name, "reason": "mesh armature modifier does not target unique rig"})
        else:
            group = groups[0]
            for vertex in obj.data.vertices:
                assignments_for_vertex = [g.weight for g in vertex.groups if g.group == group.index]
                if len(assignments_for_vertex) != 1 or abs(assignments_for_vertex[0] - 1.0) > 1e-6:
                    bone_errors.append({"mesh": obj.name, "reason": f"vertex {vertex.index} missing full rigid weight"})
                    break

    bone_names = sorted(armatures[0].data.bones.keys()) if len(armatures) == 1 else []
    images = []
    for image in bpy.data.images:
        connected = any(
            node.type == "TEX_IMAGE" and node.image == image
            for material in bpy.data.materials if material.use_nodes and material.node_tree
            for node in material.node_tree.nodes
        )
        images.append({
            "name": image.name,
            "packed": image.packed_file is not None,
            "connected_to_shader": connected,
            "size": [int(image.size[0]), int(image.size[1])],
        })
    geometry_hash = geometry_fingerprint(meshes)
    camera_names = {"BW_CAMERA_FRONT", "BW_CAMERA_THREE_QUARTER", "BW_CAMERA_BACK"}
    cameras = [obj for obj in scene.objects if obj.type == "CAMERA" and obj.name in camera_names]
    image_ok = len(images) == 1 and images[0]["packed"] and not images[0]["connected_to_shader"] and images[0]["size"] == [2043, 770]
    checks = {
        "source_glb_hash_unchanged": sha256(cfg.source) == "e1a9ef843561a7a31b0ba60600de97d909fbfe8a780b9c0882b3ef7bc6ea4ea6" and scene.get("bw_source_glb_sha256") == sha256(cfg.source),
        "reference_hash_unchanged": sha256(cfg.reference) == "5f7eaf60f54164896fe7284f8963cab13c00b18fc934fe982c5a1acb309cc7ac" and scene.get("bw_reference_sha256") == sha256(cfg.reference),
        "palette_hash_matches": scene.get("bw_material_palette_sha256") == sha256(cfg.palette),
        "mesh_count_503": len(meshes) == EXPECTED_MESHES,
        "triangles_45998": triangles == EXPECTED_TRIANGLES,
        "one_15_bone_rig": len(armatures) == 1 and len(bone_names) == EXPECTED_BONES and bone_names == sorted(EXPECTED_BONE_NAMES),
        "all_parts_have_one_semantic_material": not unknown and not material_errors and sum(assignments.values()) == EXPECTED_MESHES,
        "all_parts_have_rigid_bone_assignment": not bone_errors,
        "source_geometry_fingerprint_unchanged": geometry_hash == scene.get("bw_geometry_fingerprint"),
        "packed_reference_resolves_without_shader_projection": image_ok,
        "three_fixed_orthographic_cameras": len(cameras) == 3 and all(abs(obj.data.ortho_scale - ORTHO_SCALE) < 1e-6 for obj in cameras),
        "no_rejected_atlas_or_image_nodes": all(not path for path in []),
        "source_only_art_stage": scene.get("bw_human_art_acceptance") == "pending" and "SOURCE-ONLY" in scene.get("asset_stage", ""),
    }
    rejected_refs = []
    for image in bpy.data.images:
        path = image.filepath.lower()
        if "rejected_bad" in path or "texture_atlas" in path or "texture_atlas" in image.name.lower():
            rejected_refs.append({"name": image.name, "path": image.filepath})
    checks["no_rejected_atlas_or_image_nodes"] = not rejected_refs and not any(
        node.type == "TEX_IMAGE"
        for material in bpy.data.materials if material.use_nodes and material.node_tree
        for node in material.node_tree.nodes
    )

    report = {
        "schema": "custodian.broken_warrant.material_master_validation.v1",
        "blend_path": str(cfg.blend),
        "blend_sha256": sha256(cfg.blend),
        "source_glb_sha256": sha256(cfg.source),
        "reference_sha256": sha256(cfg.reference),
        "geometry_fingerprint": geometry_hash,
        "counts": {"mesh_objects": len(meshes), "triangles": triangles, "armature_objects": len(armatures), "bones": len(bone_names)},
        "bone_names": bone_names,
        "material_mesh_counts": dict(sorted(assignments.items())),
        "images": images,
        "unknown_objects": unknown,
        "material_errors": material_errors,
        "bone_errors": bone_errors,
        "rejected_references": rejected_refs,
        "checks": checks,
        "passed": all(checks.values()),
        "human_art_acceptance": "pending",
    }
    cfg.output.parent.mkdir(parents=True, exist_ok=True)
    cfg.output.write_text(json.dumps(report, indent=2) + "\n")
    print("MATERIAL_MASTER_VALIDATION", json.dumps({"passed": report["passed"], "checks": checks, "counts": report["counts"], "material_mesh_counts": report["material_mesh_counts"], "errors": {"unknown": len(unknown), "materials": len(material_errors), "bones": len(bone_errors)}}))
    if not report["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
