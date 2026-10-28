#!/usr/bin/env python3
"""Objective geometry checks for the static shoulder plate study variants."""

import json
import sys
import hashlib
from pathlib import Path

import bpy
from mathutils.bvhtree import BVHTree


def selected_polygons(mesh):
    group_ids = {group.name: group.index for group in mesh.vertex_groups}
    result = []
    for index, poly in enumerate(mesh.data.polygons):
        x, _y, z = poly.center
        side = "Left" if x >= 0 else "Right"
        group_id = group_ids[f"mixamorig:{side}Shoulder"]
        weight = sum(next((w.weight for w in mesh.data.vertices[v].groups
                          if w.group == group_id), 0.0) for v in poly.vertices) / len(poly.vertices)
        result.append(0.14 <= abs(x) <= 0.34 and 1.20 <= z <= 1.48 and weight > 0.20)
    return result


def mesh_geometry(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    data = evaluated.to_mesh()
    vertices = [obj.matrix_world @ vertex.co for vertex in data.vertices]
    polygons = [tuple(poly.vertices) for poly in data.polygons]
    evaluated.to_mesh_clear()
    return vertices, polygons


def hash_rows(rows):
    return hashlib.sha256(json.dumps(rows, separators=(",", ":")).encode()).hexdigest()


def base_hashes(mesh):
    coordinates = [[round(float(value), 9) for value in vertex.co] for vertex in mesh.data.vertices]
    edges = [list(edge.vertices) for edge in mesh.data.edges]
    faces = [list(poly.vertices) for poly in mesh.data.polygons]
    weights = [[(group.group, round(float(group.weight), 8)) for group in vertex.groups]
               for vertex in mesh.data.vertices]
    uv = []
    if mesh.data.uv_layers.active:
        uv = [[round(float(component), 9) for component in item.uv]
              for item in mesh.data.uv_layers.active.data]
    return {"vertices": hash_rows(coordinates), "topology": hash_rows([edges, faces]),
            "weights": hash_rows(weights), "uv": hash_rows(uv),
            "materials": hash_rows([material.name for material in mesh.data.materials])}


def inspect(path):
    bpy.ops.wm.open_mainfile(filepath=str(path.resolve()))
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    if armature.animation_data:
        armature.animation_data.action = None
    for pose_bone in armature.pose.bones:
        pose_bone.matrix_basis = pose_bone.matrix_basis.__class__()
    bpy.context.view_layer.update()
    mesh = next(obj for obj in bpy.data.objects if obj.type == "MESH" and obj.vertex_groups)
    overlay = next((obj for obj in bpy.data.objects if obj.name.startswith("SHOULDER_PLATE_OVERLAY_")), None)
    selected = selected_polygons(mesh)
    base_vertices = [mesh.matrix_world @ vertex.co for vertex in mesh.data.vertices]
    base_polygons = [tuple(poly.vertices) for poly, use in zip(mesh.data.polygons, selected) if not use]
    base_bvh = BVHTree.FromPolygons(base_vertices, base_polygons, all_triangles=False)
    result = {"variant": path.stem, "source_mesh_vertices": len(mesh.data.vertices),
              "source_mesh_faces": len(mesh.data.polygons), "replaced_surface_faces": sum(selected),
              "source_material_count": len(mesh.data.materials),
              "base_mesh_hashes": base_hashes(mesh),
              "source_action_disabled": armature.animation_data is None or armature.animation_data.action is None}
    if overlay:
        out_vertices, out_polygons = mesh_geometry(overlay)
        overlay_bvh = BVHTree.FromPolygons(out_vertices, out_polygons, all_triangles=False)
        pairs = base_bvh.overlap(overlay_bvh)
        intersecting_faces = sorted({overlay_index for _base_index, overlay_index in pairs})
        intersecting_centers = [
            [sum(out_vertices[index][axis] for index in out_polygons[face]) / len(out_polygons[face])
             for axis in range(3)]
            for face in intersecting_faces
        ]
        intersection_bounds = None
        if intersecting_centers:
            intersection_bounds = [[round(min(point[axis] for point in intersecting_centers), 4),
                                    round(max(point[axis] for point in intersecting_centers), 4)]
                                   for axis in range(3)]
        result.update({"overlay_object": overlay.name, "overlay_vertices_after_thickness": len(out_vertices),
                       "overlay_faces_after_thickness": len(out_polygons),
                       "triangle_intersections_with_non_plate_base_surface": len(pairs),
                       "distinct_overlay_faces_intersecting_base": len(intersecting_faces),
                       "intersection_face_bounds_xyz_m": intersection_bounds,
                       "overlay_material_count": len(overlay.data.materials)})
        distances = [base_bvh.find_nearest(point) for point in out_vertices]
        finite = [item[3] for item in distances if item and item[3] is not None]
        result["minimum_distance_to_non_plate_base_surface_mm"] = round(min(finite) * 1000, 3) if finite else None
    else:
        result["overlay_object"] = None
    return result


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    variant_dir, out = Path(args[0]), Path(args[1])
    variants = [inspect(variant_dir / f"{name}.blend") for name in
                ("BASELINE", "VARIANT_A_MODERATE", "VARIANT_B_LAYERED")]
    baseline_hashes = variants[0]["base_mesh_hashes"]
    for variant in variants:
        variant["base_mesh_matches_baseline"] = {
            key: variant["base_mesh_hashes"][key] == baseline_hashes[key]
            for key in baseline_hashes}
        variant["weights_unchanged"] = variant["base_mesh_matches_baseline"]["weights"]
    result = {"schema": "custodian.operator_shoulder_plate_geometry_validation.v1",
              "variants": variants}
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
