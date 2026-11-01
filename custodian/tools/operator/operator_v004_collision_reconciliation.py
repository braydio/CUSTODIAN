"""Build and validate the bounded V004 right-pauldron underside refit.

Run with Blender 5.2:
  blender -b --python operator_v004_collision_reconciliation.py -- build SOURCE.blend OUTPUT.blend REPORT.json
  blender -b --python operator_v004_collision_reconciliation.py -- validate SOURCE.blend OUTPUT.blend REPORT.json
"""
from __future__ import annotations

import hashlib
import json
import math
import struct
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

SOURCE_SHA256 = "17c3cc57ce58aff1e400636d8b5f1db5bc97058d7028d6de587803514a131589"
SOURCE_OBJECT = "output_unwrapped"
LEFT_OBJECT = "Operator_Pauldron_Left_V003"
RIGHT_OBJECT = "Operator_Pauldron_Right_V003"
ARMATURE_OBJECT = "SmartRigArmature"
IDLE_ACTION = "V003 Neutral Idle Upper Body Candidate"
RUN_ACTION = "operator_run_mixamo_iter005_contact_ik.001"
RIGHT_FACE = 31
BODY_FACE = 1455
PATCH_VERTICES = (134, 135, 136)
PATCH_NEIGHBOR_FACES = (31, 44)
CORRECTION_M = 0.006
TARGET_IDLE = (1, 6, 13, 16, 22, 132, 263)
TARGET_RUNNING = (1, 6, 13, 16, 22)


def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def canonical(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def hash_floats(values) -> str:
    h = hashlib.sha256()
    for value in values:
        h.update(struct.pack("<f", float(value)))
    return h.hexdigest()


def mesh_signature(obj) -> dict:
    mesh = obj.data
    vertices = [v.co for v in mesh.vertices]
    topo = []
    for edge in mesh.edges:
        topo.extend(edge.vertices)
    for poly in mesh.polygons:
        topo.append(len(poly.vertices))
        topo.extend(poly.vertices)
        topo.append(poly.material_index)
    uv_data = []
    for layer in mesh.uv_layers:
        uv_data.append(layer.name)
        uv_data.extend(c for item in layer.data for c in item.uv)
    weights = []
    for v in mesh.vertices:
        for g in sorted(v.groups, key=lambda item: item.group):
            weights.extend((g.group, g.weight))
        weights.append(-1)
    return {
        "object": obj.name,
        "mesh": mesh.name,
        "vertex_count": len(mesh.vertices),
        "edge_count": len(mesh.edges),
        "polygon_count": len(mesh.polygons),
        "coordinate_sha256": hash_floats(c for v in vertices for c in v),
        "topology_material_sha256": sha_bytes(canonical(topo)),
        "uv_sha256": sha_bytes(canonical(uv_data)),
        "weights_sha256": sha_bytes(canonical(weights)),
        "materials": [slot.material.name if slot.material else None for slot in obj.material_slots],
    }


def rig_signature(arm) -> str:
    records = []
    for bone in arm.data.bones:
        records.append({
            "name": bone.name,
            "parent": bone.parent.name if bone.parent else None,
            "head": [round(float(x), 8) for x in bone.head_local],
            "tail": [round(float(x), 8) for x in bone.tail_local],
            "matrix": [[round(float(x), 8) for x in row] for row in bone.matrix_local],
        })
    return sha_bytes(canonical(records))


def actions_signature() -> str:
    records = []
    for action in sorted(bpy.data.actions, key=lambda a: a.name):
        curves = []
        for layer in action.layers:
            for strip in layer.strips:
                if strip.type != "KEYFRAME":
                    continue
                for slot in action.slots:
                    try:
                        bag = strip.channelbag(slot)
                    except (RuntimeError, TypeError):
                        bag = None
                    if bag is None:
                        continue
                    for fc in bag.fcurves:
                        curves.append({
                            "path": fc.data_path,
                            "index": fc.array_index,
                            "points": [[round(float(k.co.x), 6), round(float(k.co.y), 8), k.interpolation] for k in fc.keyframe_points],
                        })
        records.append({"name": action.name, "range": list(action.frame_range), "curves": curves})
    return sha_bytes(canonical(records))


def evaluated_triangles(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    coords = [evaluated.matrix_world @ vertex.co for vertex in mesh.vertices]
    triangles = [tuple(triangle.vertices) for triangle in mesh.loop_triangles]
    polygon_ids = [triangle.polygon_index for triangle in mesh.loop_triangles]
    normals = [(evaluated.matrix_world.to_3x3() @ polygon.normal).normalized() for polygon in mesh.polygons]
    tree = BVHTree.FromPolygons(coords, triangles, all_triangles=True, epsilon=0.0)
    evaluated.to_mesh_clear()
    return coords, triangles, polygon_ids, normals, tree


def segment_triangle(p0, p1, a, b, c, tolerance=1e-9):
    direction = p1 - p0
    edge1 = b - a
    edge2 = c - a
    h = direction.cross(edge2)
    determinant = edge1.dot(h)
    if abs(determinant) < tolerance:
        return None
    inv = 1.0 / determinant
    offset = p0 - a
    u = inv * offset.dot(h)
    if u < -tolerance or u > 1.0 + tolerance:
        return None
    q = offset.cross(edge1)
    v = inv * direction.dot(q)
    if v < -tolerance or u + v > 1.0 + tolerance:
        return None
    t = inv * edge2.dot(q)
    if t < -tolerance or t > 1.0 + tolerance:
        return None
    return p0 + direction * t


def exact_contact_points(triangle_a, triangle_b):
    points = []
    for source, target in ((triangle_a, triangle_b), (triangle_b, triangle_a)):
        for index in range(3):
            point = segment_triangle(source[index], source[(index + 1) % 3], *target)
            if point is not None and not any((point - prior).length < 1e-7 for prior in points):
                points.append(point)
    return points


def vertex_weights(obj, indices):
    result = {}
    for index in indices:
        vertex = obj.data.vertices[index]
        result[str(index)] = [
            [obj.vertex_groups[group.group].name, round(float(group.weight), 6)]
            for group in sorted(vertex.groups, key=lambda item: item.group)
        ]
    return result


def collision_sample(body, shells, arm, action, frame, label):
    arm.animation_data_create()
    arm.animation_data.action = action
    if action is None:
        for bone in arm.pose.bones:
            bone.matrix_basis.identity()
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    body_data = evaluated_triangles(body)
    records = []
    for shell in shells:
        shell_data = evaluated_triangles(shell)
        body_coords, body_tris, body_polys, body_normals, body_tree = body_data
        shell_coords, shell_tris, shell_polys, shell_normals, shell_tree = shell_data
        raw = body_tree.overlap(shell_tree)
        contacts = []
        for body_tri_id, shell_tri_id in raw:
            body_tri = body_tris[body_tri_id]
            shell_tri = shell_tris[shell_tri_id]
            a = [body_coords[i] for i in body_tri]
            b = [shell_coords[i] for i in shell_tri]
            points = exact_contact_points(a, b)
            if not points:
                continue
            body_poly = body_polys[body_tri_id]
            shell_poly = shell_polys[shell_tri_id]
            length = max(((p - q).length for p in points for q in points), default=0.0)
            contacts.append({
                "body_triangle_index": body_tri_id,
                "body_polygon_index": body_poly,
                "shell_triangle_index": shell_tri_id,
                "shell_polygon_index": shell_poly,
                "body_triangle_vertex_indices": list(body_tri),
                "shell_triangle_vertex_indices": list(shell_tri),
                "body_triangle_world_xyz": [[round(float(v), 9) for v in p] for p in a],
                "shell_triangle_world_xyz": [[round(float(v), 9) for v in p] for p in b],
                "body_normal_world": [round(float(v), 8) for v in body_normals[body_poly]],
                "shell_normal_world": [round(float(v), 8) for v in shell_normals[shell_poly]],
                "intersection_points_world": [[round(float(v), 9) for v in p] for p in points],
                "intersection_segment_length_mm": round(length * 1000, 6),
                "classification": "crossing_segment" if len(points) >= 2 else "single_point_contact",
                "body_weights": vertex_weights(body, body_tri),
                "shell_weights": vertex_weights(shell, shell_tri),
            })
        records.append({
            "object": shell.name,
            "mesh": shell.data.name,
            "object_to_world": [[round(float(x), 8) for x in row] for row in shell.matrix_world],
            "armature_modifiers": [{
                "name": m.name,
                "armature": m.object.name if m.object else None,
                "use_vertex_groups": m.use_vertex_groups,
                "use_bone_envelopes": m.use_bone_envelopes,
                "use_deform_preserve_volume": m.use_deform_preserve_volume,
            } for m in shell.modifiers if m.type == "ARMATURE"],
            "raw_triangle_overlap_pairs": len(raw),
            "confirmed_contacts": contacts,
        })
    return {"label": label, "frame": frame, "body_object": body.name, "body_mesh": body.data.name, "shells": records}


def evaluate(body, left, right, arm, idle, running, all_idle=False):
    rows = [collision_sample(body, [left, right], arm, None, 1, "rest")]
    idle_frames = range(1, 265) if all_idle else TARGET_IDLE
    for frame in idle_frames:
        rows.append(collision_sample(body, [left, right], arm, idle, frame, "neutral_idle"))
    for frame in TARGET_RUNNING:
        rows.append(collision_sample(body, [left, right], arm, running, frame, "running"))
    return rows


def minimum_vertex_surface_clearance(body, shells, arm, idle, running):
    measurements = {shell.name: None for shell in shells}
    samples = [(idle, frame, "neutral_idle") for frame in range(1, 265)]
    samples += [(running, frame, "running") for frame in TARGET_RUNNING]
    for action, frame, label in samples:
        arm.animation_data_create(); arm.animation_data.action = action
        bpy.context.scene.frame_set(frame); bpy.context.view_layer.update()
        body_data = evaluated_triangles(body)
        body_coords, body_triangles, body_polygons, _, body_tree = body_data
        for shell in shells:
            shell_coords, _, _, _, _ = evaluated_triangles(shell)
            for vertex_index, point in enumerate(shell_coords):
                found = body_tree.find_nearest(point)
                if not found or found[3] is None:
                    continue
                record = {
                    "distance_mm": round(float(found[3]) * 1000, 6),
                    "animation": label,
                    "frame": frame,
                    "shell_vertex_index": vertex_index,
                    "shell_vertex_world": [round(float(v), 9) for v in point],
                    "nearest_body_point_world": [round(float(v), 9) for v in found[0]],
                    "body_triangle_index": int(found[2]),
                    "body_polygon_index": int(body_polygons[found[2]]),
                }
                prior = measurements[shell.name]
                if prior is None or record["distance_mm"] < prior["distance_mm"]:
                    measurements[shell.name] = record
    return {
        "method": "minimum evaluated shell-vertex to evaluated body-triangle-surface Euclidean distance; sampled all 264 idle frames plus five running frames; this is not a signed volume depth or a full continuous surface minimum",
        "by_pauldron": measurements,
    }


def collision_summary(rows):
    summary = {}
    for row in rows:
        for shell in row["shells"]:
            key = f"{row['label']}:{row['frame']}:{shell['object']}"
            summary[key] = {
                "bvh_triangle_pairs": shell["raw_triangle_overlap_pairs"],
                "confirmed_crossings": len(shell["confirmed_contacts"]),
            }
    return summary


def build(source: Path, output: Path, report_path: Path):
    source = source.resolve()
    if sha_file(source) != SOURCE_SHA256:
        raise RuntimeError("V003_SPLIT_SOURCE_SHA256_MISMATCH")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    body = bpy.data.objects.get(SOURCE_OBJECT)
    left = bpy.data.objects.get(LEFT_OBJECT)
    right = bpy.data.objects.get(RIGHT_OBJECT)
    arm = bpy.data.objects.get(ARMATURE_OBJECT)
    idle = bpy.data.actions.get(IDLE_ACTION)
    running = bpy.data.actions.get(RUN_ACTION)
    if not all((body, left, right, arm, idle, running)) or len(arm.data.bones) != 42:
        raise RuntimeError("V003_OBJECT_ACTION_OR_RIG_IDENTITY_MISMATCH")
    if right.data.polygons[RIGHT_FACE].vertices[:] != (134, 135, 136):
        raise RuntimeError("RIGHT_FACE_31_TOPOLOGY_MISMATCH")
    if any(tuple(right.data.polygons[index].vertices) != face for index, face in ((31, (134, 135, 136)), (44, (134, 136, 137)))):
        raise RuntimeError("RIGHT_LOCAL_PATCH_TOPOLOGY_MISMATCH")
    if any(abs(x - y) > 1e-8 for x, y in zip(right.matrix_world.translation, body.matrix_world.translation)):
        raise RuntimeError("PAULDron_BODY_TRANSFORM_MISMATCH")

    before = {
        "body": mesh_signature(body),
        "left_pauldron": mesh_signature(left),
        "right_pauldron": mesh_signature(right),
        "rig_signature": rig_signature(arm),
        "actions_signature": actions_signature(),
        "idle_action_range": list(idle.frame_range),
        "running_action_range": list(running.frame_range),
    }
    baseline_rows = evaluate(body, left, right, arm, idle, running, all_idle=False)
    baseline_summary = collision_summary(baseline_rows)
    body_normal = body.data.polygons[BODY_FACE].normal.normalized()
    local_delta = -body_normal * CORRECTION_M
    for index in PATCH_VERTICES:
        right.data.vertices[index].co += local_delta
    right.data.update()
    after_rows = evaluate(body, left, right, arm, idle, running, all_idle=True)
    after_summary = collision_summary(after_rows)
    clearance = minimum_vertex_surface_clearance(body, [left, right], arm, idle, running)
    unresolved = {key: value for key, value in after_summary.items() if value["confirmed_crossings"] or value["bvh_triangle_pairs"]}
    if unresolved:
        raise RuntimeError("V004_COLLISION_VALIDATION_FAILED:" + json.dumps(unresolved, sort_keys=True))

    # Preserve the source scene's active idle action; evaluation left the run
    # action active and Blender would otherwise discard the now-unused idle.
    arm.animation_data.action = idle
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    after = {
        "body": mesh_signature(body),
        "left_pauldron": mesh_signature(left),
        "right_pauldron": mesh_signature(right),
        "rig_signature": rig_signature(arm),
        "actions_signature": actions_signature(),
        "idle_action_range": list(idle.frame_range),
        "running_action_range": list(running.frame_range),
    }
    report = {
        "schema": "custodian.operator_v004_collision_reconciliation.v1",
        "candidate_state": "candidate_unapproved",
        "source": {"path": str(source), "sha256": SOURCE_SHA256},
        "candidate": {"path": str(output), "sha256": sha_file(output), "bytes": output.stat().st_size},
        "correction": {
            "method": "local inward underside fit along the source body-face normal",
            "source_body_polygon": BODY_FACE,
            "source_right_pauldron_polygon": RIGHT_FACE,
            "right_pauldron_vertices": list(PATCH_VERTICES),
            "neighboring_faces_affected_by_shared_vertices": list(PATCH_NEIGHBOR_FACES),
            "body_face_normal_local": [round(float(v), 9) for v in body_normal],
            "local_vertex_delta_m": [round(float(v), 9) for v in local_delta],
            "displacement_mm": round(local_delta.length * 1000, 6),
            "weights_changed": False,
            "left_pauldron_changed": False,
            "body_geometry_changed": False,
        },
        "collision_reconciliation": {
            "original_v003_build_report_raw_overlap_pairs_right": 2,
            "original_v003_build_report_sha256": sha_file(Path("/home/braydenchaffee/Projects/.operator-3d-animation-proof/operator_3d_visual_fidelity_v3/v003_build_report.json")),
            "original_v003_prejoin_modifier_finding": "The right shell's zero-thickness Solidify modifier emits a coincident duplicate of source shell face 31 as evaluated face 109; both report the same body crossing. The saved integrated and split meshes no longer carry this modifier.",
            "split_source_baseline_rows": baseline_rows,
            "split_source_baseline_summary": baseline_summary,
            "confirmed_contact_classification": "non-coplanar crossing segments, not point/edge touch or BVH-only broad-phase candidates",
        },
        "after_validation": {
            "tested_idle_frames": [1, 6, 13, 16, 22, 132, 263],
            "full_idle_frame_count": 264,
            "full_idle_frames_tested": [1, 264],
            "tested_running_frames": list(TARGET_RUNNING),
            "all_bvh_pairs_zero": True,
            "all_confirmed_crossings_zero": True,
            "summary": after_summary,
            "minimum_sampled_vertex_clearance": clearance,
        },
        "preservation": {
            "before": before,
            "after": after,
            "body_geometry_and_weights_unchanged": before["body"] == after["body"],
            "left_pauldron_unchanged": before["left_pauldron"] == after["left_pauldron"],
            "right_pauldron_weights_topology_material_uv_unchanged": all(before["right_pauldron"][key] == after["right_pauldron"][key] for key in ("topology_material_sha256", "uv_sha256", "weights_sha256", "materials")),
            "rig_rest_signature_unchanged": before["rig_signature"] == after["rig_signature"],
            "actions_unchanged": before["actions_signature"] == after["actions_signature"],
        },
    }
    if not all((report["preservation"]["body_geometry_and_weights_unchanged"], report["preservation"]["left_pauldron_unchanged"], report["preservation"]["right_pauldron_weights_topology_material_uv_unchanged"], report["preservation"]["rig_rest_signature_unchanged"], report["preservation"]["actions_unchanged"])):
        raise RuntimeError("V004_PRESERVATION_SIGNATURE_MISMATCH")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_bytes(canonical(report) + b"\n")
    print(json.dumps({"result": "candidate_built", "candidate_sha256": report["candidate"]["sha256"], "report": str(report_path), "all_collision_pairs_zero": True}))


def validate_reopen(source: Path, candidate: Path, report_path: Path):
    source = source.resolve(); candidate = candidate.resolve(); report_path = report_path.resolve()
    report = json.loads(report_path.read_text())
    if sha_file(source) != SOURCE_SHA256 or sha_file(candidate) != report["candidate"]["sha256"]:
        raise RuntimeError("V004_REOPEN_HASH_MISMATCH")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    source_mesh = {name: mesh_signature(bpy.data.objects[name]) for name in (SOURCE_OBJECT, LEFT_OBJECT, RIGHT_OBJECT)}
    source_arm = rig_signature(bpy.data.objects[ARMATURE_OBJECT])
    source_actions = actions_signature()
    source_right = [tuple(float(c) for c in vertex.co) for vertex in bpy.data.objects[RIGHT_OBJECT].data.vertices]
    source_objects = sorted(o.name for o in bpy.data.objects)
    bpy.ops.wm.open_mainfile(filepath=str(candidate))
    body = bpy.data.objects[SOURCE_OBJECT]; left = bpy.data.objects[LEFT_OBJECT]; right = bpy.data.objects[RIGHT_OBJECT]
    arm = bpy.data.objects[ARMATURE_OBJECT]; idle = bpy.data.actions[IDLE_ACTION]; running = bpy.data.actions[RUN_ACTION]
    candidate_mesh = {name: mesh_signature(bpy.data.objects[name]) for name in (SOURCE_OBJECT, LEFT_OBJECT, RIGHT_OBJECT)}
    changed_indices = []
    for index, (before, after) in enumerate(zip(source_right, (tuple(float(c) for c in v.co) for v in right.data.vertices))):
        if any(abs(x-y) > 1e-8 for x, y in zip(before, after)):
            changed_indices.append(index)
    expected = report["correction"]["local_vertex_delta_m"]
    actual_deltas = {str(i): [round(float(right.data.vertices[i].co[j] - source_right[i][j]), 9) for j in range(3)] for i in changed_indices}
    validation = {
        "source_sha256": sha_file(source),
        "candidate_sha256": sha_file(candidate),
        "reopened_candidate_path": str(candidate),
        "source_and_candidate_object_inventory_equal": source_objects == sorted(o.name for o in bpy.data.objects),
        "changed_mesh_vertex_indices": changed_indices,
        "exact_local_vertex_deltas_m": actual_deltas,
        "changed_vertex_set_expected": changed_indices == list(PATCH_VERTICES),
        "body_signature_matches_source": candidate_mesh[SOURCE_OBJECT] == source_mesh[SOURCE_OBJECT],
        "left_pauldron_signature_matches_source": candidate_mesh[LEFT_OBJECT] == source_mesh[LEFT_OBJECT],
        "right_pauldron_non_coordinate_signature_matches_source": all(candidate_mesh[RIGHT_OBJECT][key] == source_mesh[RIGHT_OBJECT][key] for key in ("topology_material_sha256", "uv_sha256", "weights_sha256", "materials")),
        "rig_rest_matches_source": rig_signature(arm) == source_arm,
        "actions_match_source": actions_signature() == source_actions,
        "reopened_blender_version": bpy.app.version_string,
    }
    if not all(validation[key] for key in ("source_and_candidate_object_inventory_equal", "changed_vertex_set_expected", "body_signature_matches_source", "left_pauldron_signature_matches_source", "right_pauldron_non_coordinate_signature_matches_source", "rig_rest_matches_source", "actions_match_source")):
        raise RuntimeError("V004_REOPEN_PRESERVATION_CHECK_FAILED:" + json.dumps(validation, sort_keys=True))
    rows = evaluate(body, left, right, arm, idle, running, all_idle=True)
    after = collision_summary(rows)
    unresolved = {key: value for key, value in after.items() if value["confirmed_crossings"] or value["bvh_triangle_pairs"]}
    if unresolved:
        raise RuntimeError("V004_REOPEN_COLLISION_CHECK_FAILED:" + json.dumps(unresolved, sort_keys=True))
    validation["reopened_all_264_idle_and_targeted_running_clear"] = True
    validation["reopened_minimum_sampled_vertex_clearance"] = minimum_vertex_surface_clearance(body, [left, right], arm, idle, running)
    validation["reopened_bvh_pair_total"] = sum(v["bvh_triangle_pairs"] for v in after.values())
    validation["reopened_confirmed_crossing_total"] = sum(v["confirmed_crossings"] for v in after.values())
    report["reimport_validation"] = validation
    report["candidate"]["sha256"] = sha_file(candidate)
    report_path.write_bytes(canonical(report) + b"\n")
    print(json.dumps({"result": "reopen_validated", **validation}, sort_keys=True))


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) != 4 or args[0] not in ("build", "validate"):
        raise RuntimeError("USAGE: build SOURCE.blend OUTPUT.blend REPORT.json | validate SOURCE.blend CANDIDATE.blend REPORT.json")
    mode = args[0]
    if mode == "build":
        build(Path(args[1]), Path(args[2]), Path(args[3]))
    else:
        validate_reopen(Path(args[1]), Path(args[2]), Path(args[3]))


if __name__ == "__main__":
    main()
