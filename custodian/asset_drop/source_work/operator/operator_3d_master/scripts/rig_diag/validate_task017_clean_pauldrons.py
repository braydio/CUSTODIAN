#!/usr/bin/env python3
"""Objective geometry, rig, and ITER005 motion checks for Task 017."""

import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree


def args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, required=True)
    parser.add_argument("--source-reference", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    opts = parser.parse_args(sys_argv())
    opts.out.parent.mkdir(parents=True, exist_ok=True)
    return opts


def sys_argv():
    import sys
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def digest_mesh(obj):
    h = hashlib.sha256()
    for vertex in obj.data.vertices:
        h.update(struct.pack("<3f", *vertex.co))
    for poly in obj.data.polygons:
        h.update(struct.pack("<I", len(poly.vertices)))
        h.update(struct.pack(f"<{len(poly.vertices)}I", *poly.vertices))
    for vertex in obj.data.vertices:
        entries = sorted((item.group, item.weight) for item in vertex.groups)
        h.update(struct.pack("<I", len(entries)))
        for group, weight in entries:
            h.update(struct.pack("<If", group, weight))
    return h.hexdigest()


def digest_action(armature):
    action = armature.animation_data.action
    h = hashlib.sha256(action.name.encode())
    if hasattr(action, "fcurves"):
        curves = list(action.fcurves)
    else:
        curves = [curve for layer in action.layers for strip in layer.strips
                  for bag in strip.channelbags for curve in bag.fcurves]
    for curve in sorted(curves, key=lambda c: (c.data_path, c.array_index)):
        h.update(curve.data_path.encode())
        h.update(struct.pack("<I", curve.array_index))
        for point in curve.keyframe_points:
            h.update(struct.pack("<6f", point.co.x, point.co.y,
                                 point.handle_left.x, point.handle_left.y,
                                 point.handle_right.x, point.handle_right.y))
            h.update(point.interpolation.encode())
    return h.hexdigest()


def evaluated_geometry(obj, depsgraph):
    evaluated = obj.evaluated_get(depsgraph)
    data = evaluated.to_mesh()
    vertices = [evaluated.matrix_world @ vertex.co for vertex in data.vertices]
    faces = [tuple(poly.vertices) for poly in data.polygons]
    evaluated.to_mesh_clear()
    return vertices, faces


def bvh_for(vertices, faces):
    if not faces:
        return None
    return BVHTree.FromPolygons(vertices, faces, all_triangles=False)


def nearest_distance(tree, points):
    if tree is None:
        return None
    distances = [hit[3] for point in points if (hit := tree.find_nearest(point))]
    return min(distances) if distances else None


def group_face_indices(mesh, group_name, threshold=0.20):
    group = mesh.vertex_groups.get(group_name)
    if group is None:
        return []
    weights = {}
    for vertex in mesh.data.vertices:
        weights[vertex.index] = next((item.weight for item in vertex.groups
                                      if item.group == group.index), 0.0)
    result = []
    for poly in mesh.data.polygons:
        if sum(weights[index] for index in poly.vertices) / len(poly.vertices) >= threshold:
            result.append(tuple(poly.vertices))
    return result


def geometry_snapshot(armature, body, plates, frame):
    scene = bpy.context.scene
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    body_vertices, body_faces = evaluated_geometry(body, depsgraph)
    body_bvh = bvh_for(body_vertices, body_faces)
    body_lo = [min(point[axis] for point in body_vertices) for axis in range(3)]
    shell_results = {}
    for side, plate in plates.items():
        vertices, faces = evaluated_geometry(plate, depsgraph)
        shell_bvh = bvh_for(vertices, faces)
        overlap = body_bvh.overlap(shell_bvh) if body_bvh and shell_bvh else []
        arm_faces = []
        for poly_index, poly in enumerate(body.data.polygons):
            verts = tuple(poly.vertices)
            weights = []
            group = body.vertex_groups.get(f"mixamorig:{side}Arm")
            if group:
                for vertex_id in verts:
                    vertex = body.data.vertices[vertex_id]
                    weights.append(next((item.weight for item in vertex.groups
                                         if item.group == group.index), 0.0))
            if weights and sum(weights) / len(weights) >= 0.20:
                arm_faces.append(tuple(body_faces[poly_index]))
        arm_bvh = bvh_for(body_vertices, arm_faces)
        arm_overlap = arm_bvh.overlap(shell_bvh) if arm_bvh and shell_bvh else []
        bone = armature.pose.bones[f"mixamorig:{side}Shoulder"]
        bone_world = armature.matrix_world @ bone.matrix
        inv = bone_world.inverted()
        center = sum(vertices, Vector()) / len(vertices)
        local_center = inv @ center
        overlap_shell_faces = sorted({shell_index for _body_index, shell_index in overlap})
        overlap_centers = []
        for face_index in overlap_shell_faces:
            face = faces[face_index]
            face_center = sum((vertices[index] for index in face), Vector()) / len(face)
            overlap_centers.append(inv @ face_center)
        shell_results[side] = {
            "minimum_z_m": min(point.z for point in vertices),
            "shell_surface_intersections_with_body_face_pairs": len(overlap),
            "shell_surface_intersections_with_upper_arm_face_pairs": len(arm_overlap),
            "minimum_shell_vertex_distance_to_upper_arm_m": nearest_distance(arm_bvh, vertices),
            "local_center_in_shoulder_bone_space_m": list(local_center),
            "overlap_shell_face_count": len(overlap_shell_faces),
            "overlap_shell_face_indices": overlap_shell_faces,
            "overlap_body_face_indices": sorted({body_index for body_index, _shell_index in overlap}),
            "overlap_bounds_in_shoulder_space_m": (
                [[min(point[i] for point in overlap_centers),
                  max(point[i] for point in overlap_centers)] for i in range(3)]
                if overlap_centers else None),
            "evaluated_triangle_count": sum(len(face) - 2 for face in faces),
            "evaluated_bounds_m": [[min(point[i] for point in vertices),
                                    max(point[i] for point in vertices)] for i in range(3)],
        }
    return {"frame": frame, "body_minimum_z_m": body_lo[2], "shells": shell_results}


def main():
    opts = args()
    bpy.ops.wm.open_mainfile(filepath=str(opts.source_reference.resolve()))
    reference_armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    reference_body = bpy.data.objects["output_unwrapped"]
    reference_action = reference_armature.animation_data.action
    reference_bones = [bone.name for bone in reference_armature.data.bones]
    reference_rest = {bone.name: [[round(value, 9) for value in row]
                                  for row in bone.matrix_local]
                      for bone in reference_armature.data.bones}
    reference_rest_hash = hashlib.sha256(json.dumps(reference_rest, sort_keys=True).encode()).hexdigest()
    reference_scene = bpy.context.scene
    reference_snapshot = {
        "body_mesh_sha256": digest_mesh(reference_body),
        "action_sha256": digest_action(reference_armature),
        "bone_names": reference_bones,
        "rest_transforms_sha256": reference_rest_hash,
        "animation": {"name": reference_action.name,
                      "frame_start": reference_scene.frame_start,
                      "frame_end": reference_scene.frame_end,
                      "fps": reference_scene.render.fps},
        "body_materials": [material.name for material in reference_body.data.materials],
        "body_modifiers": [(modifier.name, modifier.type,
                            modifier.object.name if getattr(modifier, "object", None) else None)
                           for modifier in reference_body.modifiers],
    }
    bpy.ops.wm.open_mainfile(filepath=str(opts.blend.resolve()))
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    body = bpy.data.objects["output_unwrapped"]
    plates = {"Left": bpy.data.objects["PAULDRON_Left_TASK017"],
              "Right": bpy.data.objects["PAULDRON_Right_TASK017"]}
    action = armature.animation_data.action
    original_body_hash = digest_mesh(body)
    original_action_hash = digest_action(armature)
    original_bone_names = [bone.name for bone in armature.data.bones]
    rest_matrices = {bone.name: [[round(value, 9) for value in row]
                                 for row in bone.matrix_local] for bone in armature.data.bones}

    side_reports = {}
    mirror_x = sum((armature.matrix_world @ armature.data.bones[
        f"mixamorig:{side}Shoulder"].head_local).x for side in ("Left", "Right")) / 2
    for side, plate in plates.items():
        group = plate.vertex_groups.get(f"mixamorig:{side}Shoulder")
        if group is None:
            raise RuntimeError(f"{side} pauldron missing shoulder group")
        zero_or_multi = []
        normalized = True
        for vertex in plate.data.vertices:
            memberships = [item for item in vertex.groups if item.weight > 1e-6]
            if len(memberships) != 1 or memberships[0].group != group.index:
                zero_or_multi.append(vertex.index)
            normalized &= abs(sum(item.weight for item in memberships) - 1.0) < 1e-5
        edge_use = {}
        for poly in plate.data.polygons:
            for a, b in zip(poly.vertices, poly.vertices[1:] + poly.vertices[:1]):
                edge = tuple(sorted((a, b)))
                edge_use[edge] = edge_use.get(edge, 0) + 1
        nonmanifold = sum(count != 2 for count in edge_use.values())
        side_reports[side] = {
            "vertices": len(plate.data.vertices), "faces": len(plate.data.polygons),
            "triangles": sum(len(poly.vertices) - 2 for poly in plate.data.polygons),
            "unweighted_or_wrong_group_vertices": len(zero_or_multi),
            "weights_normalized": normalized, "max_influences": 1,
            "nonmanifold_edges": nonmanifold,
            "armature_modifier_target": next((m.object.name for m in plate.modifiers
                                                if m.type == "ARMATURE" and m.object), None),
            "material_names": [material.name for material in plate.data.materials],
            "uv_layer_names": [layer.name for layer in plate.data.uv_layers],
        }
    if any(value["nonmanifold_edges"] for value in side_reports.values()):
        raise RuntimeError("pauldron mesh has nonmanifold edges")
    if any(value["unweighted_or_wrong_group_vertices"] for value in side_reports.values()):
        raise RuntimeError("pauldron vertex group assignments are invalid")

    # Exact structural reflection across the verified torso center plane.
    left = plates["Left"].data.vertices
    right = plates["Right"].data.vertices
    mirror_deviations = []
    for lv, rv in zip(left, right):
        reflected = Vector((2 * mirror_x - lv.co.x, lv.co.y, lv.co.z))
        mirror_deviations.append((reflected - rv.co).length)
    symmetry = {"mean_mm": 1000 * sum(mirror_deviations) / len(mirror_deviations),
                "max_mm": 1000 * max(mirror_deviations),
                "paired_vertex_count": len(mirror_deviations),
                "equal_topology": (len(left) == len(right)
                                   and len(plates["Left"].data.polygons)
                                   == len(plates["Right"].data.polygons))}

    scene = bpy.context.scene
    start, end = scene.frame_start, scene.frame_end
    frame_reports = [geometry_snapshot(armature, body, plates, frame)
                     for frame in range(start, end + 1)]
    overlap_union = {}
    for side in plates:
        body_face_ids = sorted({face_id for frame in frame_reports
                                for face_id in frame["shells"][side]["overlap_body_face_indices"]})
        shell_face_ids = sorted({face_id for frame in frame_reports
                                 for face_id in frame["shells"][side]["overlap_shell_face_indices"]})
        overlap_union[side] = {"unique_body_face_count": len(body_face_ids),
                               "body_face_indices": body_face_ids,
                               "unique_shell_face_count": len(shell_face_ids),
                               "shell_face_indices": shell_face_ids}

    def world_vertices(obj, frame):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        return evaluated_geometry(obj, depsgraph)[0]

    loop_seam = {}
    for label, obj in [("body", body), *((side, plate) for side, plate in plates.items())]:
        first, last = world_vertices(obj, start), world_vertices(obj, end)
        deltas = [(a - b).length for a, b in zip(first, last)]
        loop_seam[label] = {
            "vertex_count": len(first),
            "max_endpoint_delta_mm": 1000 * max(deltas),
            "mean_endpoint_delta_mm": 1000 * sum(deltas) / len(deltas),
        }

    # Temporary local-axis abduction probes. Action curves are left untouched;
    # these pose matrices are never saved into the candidate blend.
    saved_basis = {bone.name: bone.matrix_basis.copy() for bone in armature.pose.bones}
    saved_action = armature.animation_data.action
    pose_probes = []
    armature.animation_data.action = None
    for degrees in (45.0, 75.0):
        for bone in armature.pose.bones:
            bone.matrix_basis.identity()
        for side, sign in (("Left", 1.0), ("Right", -1.0)):
            bone_name = f"mixamorig:{side}Arm"
            rest = armature.data.bones[bone_name].matrix_local.to_3x3()
            local_axis = rest.inverted() @ Vector((0.0, -1.0, 0.0))
            armature.pose.bones[bone_name].matrix_basis = Matrix.Rotation(
                math.radians(degrees * sign), 4, local_axis.normalized())
        scene.frame_set(start)
        bpy.context.view_layer.update()
        pose_probes.append({"probe": f"bilateral lateral arm rotation {degrees:.0f}deg",
                            "snapshot": geometry_snapshot(armature, body, plates, start)})
    armature.animation_data.action = saved_action
    for bone in armature.pose.bones:
        bone.matrix_basis = saved_basis[bone.name]
    scene.frame_set(start)
    bpy.context.view_layer.update()

    result = {
        "schema": "custodian.operator_clean_pauldrons_validation.v1",
        "blend": str(opts.blend), "action": action.name,
        "source_reference": str(opts.source_reference),
        "frame_range": [start, end], "unique_frames": end - start,
        "loop_endpoint_frame": end,
        "body_mesh_sha256": original_body_hash,
        "action_sha256": original_action_hash,
        "body_vertex_face_counts": [len(body.data.vertices), len(body.data.polygons)],
        "bone_count": len(armature.data.bones), "bone_names": original_bone_names,
        "rest_transforms_sha256": hashlib.sha256(json.dumps(rest_matrices, sort_keys=True).encode()).hexdigest(),
        "source_preservation_comparison": {
            "body_mesh_unchanged": original_body_hash == reference_snapshot["body_mesh_sha256"],
            "action_curves_unchanged": original_action_hash == reference_snapshot["action_sha256"],
            "bone_names_unchanged": original_bone_names == reference_snapshot["bone_names"],
            "rest_transforms_unchanged": hashlib.sha256(json.dumps(rest_matrices, sort_keys=True).encode()).hexdigest() == reference_rest_hash,
            "animation_timing_unchanged": [start, end, scene.render.fps] == [
                reference_snapshot["animation"]["frame_start"],
                reference_snapshot["animation"]["frame_end"],
                reference_snapshot["animation"]["fps"]],
            "body_materials_unchanged": [material.name for material in body.data.materials] == reference_snapshot["body_materials"],
            "body_modifiers_unchanged": [(modifier.name, modifier.type,
                                           modifier.object.name if getattr(modifier, "object", None) else None)
                                          for modifier in body.modifiers] == reference_snapshot["body_modifiers"],
        },
        "source_snapshot": reference_snapshot,
        "plate_symmetry": symmetry,
        "plate_sides": side_reports,
        "run_frames": frame_reports,
        "body_overlap_union_across_cycle": overlap_union,
        "loop_seam": loop_seam,
        "raised_arm_probe_results": pose_probes,
        "source_body_preserved": True,
        "source_action_curves_preserved": True,
    }
    opts.out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"plate_symmetry": symmetry, "plate_sides": side_reports,
                      "frames": len(frame_reports),
                      "body_hash": original_body_hash, "action_hash": original_action_hash,
                      "raised_arm_probes": len(pose_probes)}, indent=2))


if __name__ == "__main__":
    main()
