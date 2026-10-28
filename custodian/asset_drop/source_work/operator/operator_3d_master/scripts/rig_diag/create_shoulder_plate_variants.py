#!/usr/bin/env python3
"""Create static BASELINE/A/B shoulder plate study blends from the ITER005 rig."""

import argparse
import json
from pathlib import Path

import bpy


def parser():
    result = argparse.ArgumentParser()
    result.add_argument("--source", type=Path, required=True)
    result.add_argument("--outdir", type=Path, required=True)
    return result


def open_neutral(path):
    bpy.ops.wm.open_mainfile(filepath=str(path.resolve()))
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    mesh = next(obj for obj in bpy.data.objects if obj.type == "MESH" and obj.vertex_groups)
    if armature.animation_data:
        armature.animation_data.action = None
    for pose_bone in armature.pose.bones:
        pose_bone.matrix_basis = pose_bone.matrix_basis.__class__()
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    return armature, mesh


def shoulder_patch(mesh):
    group_ids = {group.name: group.index for group in mesh.vertex_groups}
    selected = []
    for poly in mesh.data.polygons:
        x, _y, z = poly.center
        side = "Left" if x >= 0 else "Right"
        group_id = group_ids[f"mixamorig:{side}Shoulder"]
        mean_weight = sum(
            next((weight.weight for weight in mesh.data.vertices[index].groups
                  if weight.group == group_id), 0.0)
            for index in poly.vertices
        ) / len(poly.vertices)
        selected.append(0.14 <= abs(x) <= 0.34 and 1.20 <= z <= 1.48
                        and mean_weight > 0.20)
    indices = [index for index, keep in enumerate(selected) if keep]
    if len(indices) != 917:
        raise RuntimeError(f"shoulder selection changed unexpectedly: {len(indices)} faces")
    return indices


def make_overlay(mesh_obj, poly_indices, name, offset_x, offset_z, thickness):
    src_mesh = mesh_obj.data
    chosen = [src_mesh.polygons[index] for index in poly_indices]
    vertex_map = {}
    source_indices = []
    faces = []
    for poly in chosen:
        face = []
        for old_index in poly.vertices:
            if old_index not in vertex_map:
                vertex_map[old_index] = len(source_indices)
                source_indices.append(old_index)
            face.append(vertex_map[old_index])
        faces.append(face)

    coordinates = []
    group_ids = {group.name: group.index for group in mesh_obj.vertex_groups}
    for old_index in source_indices:
        vertex = src_mesh.vertices[old_index]
        left_weight = next((w.weight for w in vertex.groups if w.group == group_ids["mixamorig:LeftShoulder"]), 0.0)
        right_weight = next((w.weight for w in vertex.groups if w.group == group_ids["mixamorig:RightShoulder"]), 0.0)
        side = 1.0 if left_weight > right_weight else -1.0
        if abs(left_weight - right_weight) < 0.05:
            side = 1.0 if vertex.co.x >= 0 else -1.0
        coordinates.append((vertex.co.x + side * offset_x,
                            vertex.co.y,
                            vertex.co.z + offset_z))

    new_mesh = bpy.data.meshes.new(f"{name}_geometry")
    new_mesh.from_pydata(coordinates, [], faces)
    new_mesh.update()
    for material in src_mesh.materials:
        new_mesh.materials.append(material)
    uv_source = src_mesh.uv_layers.active
    if uv_source:
        uv_dest = new_mesh.uv_layers.new(name=uv_source.name)
        for new_poly, source_poly in zip(new_mesh.polygons, chosen):
            for new_loop, source_loop in zip(new_poly.loop_indices, source_poly.loop_indices):
                uv_dest.data[new_loop].uv = uv_source.data[source_loop].uv
            new_poly.material_index = source_poly.material_index
    else:
        for new_poly, source_poly in zip(new_mesh.polygons, chosen):
            new_poly.material_index = source_poly.material_index

    overlay = bpy.data.objects.new(name, new_mesh)
    bpy.context.scene.collection.objects.link(overlay)
    overlay.matrix_world = mesh_obj.matrix_world.copy()
    solidify = overlay.modifiers.new("thin plate edge", "SOLIDIFY")
    solidify.thickness = thickness
    solidify.offset = 1.0
    solidify.use_rim = True
    bpy.context.view_layer.objects.active = overlay
    overlay.select_set(True)
    bpy.ops.object.modifier_apply(modifier=solidify.name)
    overlay.select_set(False)
    return overlay, len(source_indices), len(faces)


def create_variant(source, outdir, name, offset_x=0.0, offset_z=0.0, thickness=0.0):
    armature, mesh = open_neutral(source)
    poly_indices = shoulder_patch(mesh)
    overlay_info = None
    if offset_x:
        overlay, vertex_count, face_count = make_overlay(
            mesh, poly_indices, f"SHOULDER_PLATE_OVERLAY_{name}", offset_x, offset_z, thickness)
        overlay_info = {"object": overlay.name, "source_vertices": vertex_count,
                        "source_faces": face_count, "outward_offset_m": offset_x,
                        "vertical_offset_m": offset_z, "solidify_thickness_m": thickness,
                        "weights_changed": False, "material_source": mesh.data.materials[0].name}
    bpy.ops.object.select_all(action="DESELECT")
    path = outdir / f"{name}.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(path), check_existing=False)
    return {"variant": name, "blend": str(path), "overlay": overlay_info,
            "source_mesh_object": mesh.name, "source_action_disabled_for_static_pose": True,
            "shoulder_patch_source_faces": len(poly_indices)}


if __name__ == "__main__":
    argv = __import__("sys").argv
    cli_args = argv[argv.index("--") + 1:] if "--" in argv else []
    opts = parser().parse_args(cli_args)
    opts.outdir.mkdir(parents=True, exist_ok=True)
    variants = [
        create_variant(opts.source, opts.outdir, "BASELINE"),
        create_variant(opts.source, opts.outdir, "VARIANT_A_MODERATE", 0.04, 0.015, 0.004),
        create_variant(opts.source, opts.outdir, "VARIANT_B_LAYERED", 0.065, 0.02, 0.008),
    ]
    (opts.outdir / "variant_generation_report.json").write_text(
        json.dumps({"schema": "custodian.operator_shoulder_plate_study.v1",
                    "source": str(opts.source), "variants": variants}, indent=2) + "\n")
    print(json.dumps(variants, indent=2))
