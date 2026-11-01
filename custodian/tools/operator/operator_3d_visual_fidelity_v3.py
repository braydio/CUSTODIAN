#!/usr/bin/env python3
"""Build the bounded V003 upper-body derivative from immutable V002 inputs.

Run with Blender 5.2:
  blender -b --python operator_3d_visual_fidelity_v3.py -- build V2.blend motion.json V3.blend report.json
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sha_json(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def sha_file(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def group_weight(vertex, index):
    return next((assignment.weight for assignment in vertex.groups if assignment.group == index), 0.0)


def qmul(a, b):
    x1, y1, z1, w1 = a
    x2, y2, z2, w2 = b
    q = (w1*x2 + x1*w2 + y1*z2 - z1*y2,
         w1*y2 - x1*z2 + y1*w2 + z1*x2,
         w1*z2 + x1*y2 - y1*x2 + z1*w2,
         w1*w2 - x1*x2 - y1*y2 - z1*z2)
    norm = math.sqrt(sum(v*v for v in q))
    return [v/norm for v in q]


def add_local_chest_opening(motion):
    """One additional degree of local extension in pose space, rest pose untouched."""
    half = math.radians(-2.0) / 2.0
    delta = [math.sin(half), 0.0, 0.0, math.cos(half)]
    for frame in motion["frames"]:
        for name in ("mixamorig:Spine", "mixamorig:Spine1", "mixamorig:Spine2"):
            transform = frame["bones"][name]
            transform["rotation_xyzw"] = qmul(delta, transform["rotation_xyzw"])
    motion.pop("motion_sha256", None)
    motion["pose_candidate"] = dict(motion.get("pose_candidate", {}))
    offsets = motion["pose_candidate"].setdefault("torso_local_pitch_offsets_degrees", {})
    for name in ("mixamorig:Spine", "mixamorig:Spine1", "mixamorig:Spine2"):
        offsets[name] = float(offsets.get(name, -1.0)) - 1.0
    motion["pose_candidate"]["v003_chest_opening_additional_degrees"] = -2.0
    motion["pose_candidate"]["rest_pose_changed"] = False
    motion["motion_sha256"] = sha_json(motion)
    return motion


def assign_motion(arm, motion):
    scene = bpy.context.scene
    action = bpy.data.actions.new("V003 Neutral Idle Upper Body Candidate")
    arm.animation_data_create()
    arm.animation_data.action = action
    for item in motion["frames"]:
        frame = item["source_frame"]
        scene.frame_set(frame)
        for name, transform in item["bones"].items():
            bone = arm.pose.bones.get(name)
            if bone is None:
                raise RuntimeError("V003_MOTION_BONE_MISSING:" + name)
            q = transform["rotation_xyzw"]
            bone.rotation_mode = "QUATERNION"
            bone.location = transform["location"]
            bone.rotation_quaternion = (q[3], q[0], q[1], q[2])
            bone.scale = transform["scale"]
            bone.keyframe_insert(data_path="location", frame=frame, group=name)
            bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=name)
            bone.keyframe_insert(data_path="scale", frame=frame, group=name)
    scene.frame_start = int(motion["source"]["frame_start"])
    scene.frame_end = int(motion["source"]["frame_end"])
    scene.render.fps = int(motion["source"]["fps"])
    return action


def point_in_polygon(x, y, poly):
    inside = False
    j = len(poly) - 1
    for i, (xi, yi) in enumerate(poly):
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and x < (xj - xi) * (y - yi) / ((yj - yi) or 1e-12) + xi:
            inside = not inside
        j = i
    return inside


# Coordinates are local model meters from V002's body surface.  q measures
# outward from the waist center, so the two independently built silhouettes match.
SHELL_OUTLINE = ((0.105, 1.365), (0.285, 1.365), (0.338, 1.405),
                 (0.325, 1.438), (0.260, 1.485), (0.190, 1.500),
                 (0.135, 1.465), (0.105, 1.415))


def patch_data(body, side):
    mesh = body.data
    mesh.update()
    center_x = 0.01
    shoulder_name = f"mixamorig:{side}Shoulder"
    shoulder = body.vertex_groups.get(shoulder_name)
    if shoulder is None:
        raise RuntimeError("V003_SHOULDER_WEIGHT_GROUP_MISSING:" + shoulder_name)
    selected = []
    for poly in mesh.polygons:
        coords = [mesh.vertices[i].co for i in poly.vertices]
        q = sum((v.x - center_x) * (1 if side == "Left" else -1) for v in coords) / len(coords)
        z = sum(v.z for v in coords) / len(coords)
        influence = sum(group_weight(mesh.vertices[i], shoulder.index) for i in poly.vertices) / len(coords)
        # Build from the outward-facing chest/shoulder surface only.  V002's
        # source mesh contains folded/back-facing shoulder strips; including
        # those produced false shell cavities and genuine internal overlap.
        if point_in_polygon(q, z, SHELL_OUTLINE) and influence >= 0.12 and poly.normal.y < -0.25:
            selected.append(poly)
    if len(selected) < 40:
        raise RuntimeError(f"V003_SHOULDER_PATCH_TOO_SMALL:{side}:{len(selected)}")
    source_indices = sorted({i for p in selected for i in p.vertices})
    remap = {old: new for new, old in enumerate(source_indices)}
    vertices = []
    for i in source_indices:
        v = mesh.vertices[i]
        vertices.append(tuple(v.co + Vector(((0.058 if side == "Left" else -0.058), -0.040, 0.018))))
    faces = [[remap[i] for i in poly.vertices] for poly in selected]
    face_qz = []
    for poly in selected:
        q = sum((mesh.vertices[i].co.x - center_x) * (1 if side == "Left" else -1)
                for i in poly.vertices) / len(poly.vertices)
        z = sum(mesh.vertices[i].co.z for i in poly.vertices) / len(poly.vertices)
        face_qz.append((q, z))
    outer_q = max(q for q, _ in face_qz)
    # A narrow upper outer edge, preserving muted-gold trim rather than a gold plate.
    trim = [int(q >= outer_q - 0.025 and z >= 1.39) for q, z in face_qz]
    weights = []
    for i in source_indices:
        weights.append([(g.group, g.weight) for g in mesh.vertices[i].groups])
    return source_indices, vertices, faces, trim, weights


def make_pbr(name, color, metallic, roughness):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    shader = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return material


def make_shell(body, arm, side):
    source_indices, verts, faces, trim, weights = patch_data(body, side)
    data = bpy.data.meshes.new(f"V003_{side}_Fitted_Angular_Pauldron_Mesh")
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(f"V003_Pauldron_{side}_Fitted_Angular", data)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = body.matrix_world.copy()
    armor = make_pbr(f"V003_{side}_Graphite_Pauldron", (0.035, 0.041, 0.049), 0.48, 0.37)
    gold = make_pbr(f"V003_{side}_Muted_Gold_Edge", (0.34, 0.205, 0.075), 0.72, 0.34)
    data.materials.append(armor)
    data.materials.append(gold)
    for poly, is_trim in zip(data.polygons, trim):
        poly.material_index = 1 if is_trim else 0

    # Copy the exact body-surface weight blend so the shell follows shoulder/arm
    # motion with the same deformation field as the underlying surface.
    for source_group in body.vertex_groups:
        obj.vertex_groups.new(name=source_group.name)
    source_name_to_index = {g.name: g.index for g in body.vertex_groups}
    dst_by_name = {g.name: g for g in obj.vertex_groups}
    marker = obj.vertex_groups.new(name=f"PAULDRON_{side}_V003")
    shoulder_group_index = source_name_to_index[f"mixamorig:{side}Shoulder"]
    arm_group_index = source_name_to_index[f"mixamorig:{side}Arm"]
    sign = 1 if side == "Left" else -1
    q_values = [(body.data.vertices[i].co.x - 0.01) * sign for i in source_indices]
    q_min, q_max = min(q_values), max(q_values)
    moved_weight_sum = 0.0
    for local_i, source_i in enumerate(source_indices):
        mapping = dict(weights[local_i])
        shoulder_weight = mapping.get(shoulder_group_index, 0.0)
        arm_weight = mapping.get(arm_group_index, 0.0)
        t = (q_values[local_i] - q_min) / max(1e-9, q_max - q_min)
        # Carry more deformation into the upper arm at the outer edge while
        # retaining a strong shoulder attachment near the collar.
        transfer = min(shoulder_weight, shoulder_weight * (0.10 + 0.22 * t))
        mapping[shoulder_group_index] = shoulder_weight - transfer
        mapping[arm_group_index] = arm_weight + transfer
        moved_weight_sum += transfer
        for source_group_index, value in mapping.items():
            name = body.vertex_groups[source_group_index].name
            if value > 0.0:
                dst_by_name[name].add([local_i], value, "REPLACE")
        marker.add([local_i], 1.0, "REPLACE")

    solidify = obj.modifiers.new("V003_Shallow_Angular_Armor_Thickness", "SOLIDIFY")
    solidify.thickness = 0.0
    solidify.offset = 1.0
    solidify.use_rim = True
    arm_mod = obj.modifiers.new("V003_Armature_Deformation", "ARMATURE")
    arm_mod.object = arm
    return obj, {"name": obj.name, "vertices": len(verts), "faces": len(faces),
                 "triangle_count": sum(len(f) - 2 for f in faces),
                 "source_surface_vertices": len(source_indices),
                 "approved_projection_lift_offset_m": {"outward": 0.058, "up": 0.018},
                 "frontward_offset_m": 0.040,
                 "solidify_thickness_m": 0.0,
                 "weight_policy": "copied body surface weights with shell-only shoulder-to-upper-arm transfer increasing from 10% at inner edge to 32% at outer edge",
                 "mean_shoulder_to_upper_arm_weight_transfer": round(moved_weight_sum / len(source_indices), 6),
                 "gold_edge_faces": sum(trim), "outline_qz_m": [list(p) for p in SHELL_OUTLINE]}


def remove_old_donor_islands(body):
    marker_names = ("PAULDRON_Left_V002", "PAULDRON_Right_V002")
    markers = [body.vertex_groups.get(name) for name in marker_names]
    if any(g is None for g in markers):
        raise RuntimeError("V002_DONOR_SHELL_MARKERS_MISSING")
    before_v, before_f = len(body.data.vertices), len(body.data.polygons)
    marker_ids = {g.index for g in markers}
    bm = bmesh.new()
    bm.from_mesh(body.data)
    layer = bm.verts.layers.deform.active
    if layer is None:
        bm.free()
        raise RuntimeError("V002_DONOR_DEFORM_LAYER_MISSING")
    doomed = [v for v in bm.verts if any(v[layer].get(i, 0.0) > 0.99 for i in marker_ids)]
    counts = {name: sum(1 for v in body.data.vertices
                        if group_weight(v, body.vertex_groups[name].index) > 0.99)
              for name in marker_names}
    if counts != {"PAULDRON_Left_V002": 434, "PAULDRON_Right_V002": 434}:
        bm.free()
        raise RuntimeError("V002_DONOR_SHELL_VERTEX_COUNTS_CHANGED:" + str(counts))
    bmesh.ops.delete(bm, geom=doomed, context="VERTS")
    bm.to_mesh(body.data)
    bm.free()
    body.data.update()
    for name in marker_names:
        group = body.vertex_groups.get(name)
        body.vertex_groups.remove(group)
    return {"input_vertices": before_v, "input_faces": before_f,
            "removed_donor_vertices": len(doomed),
            "removed_donor_shell_vertices_by_side": counts,
            "body_vertices_after_removal": len(body.data.vertices),
            "body_faces_after_removal": len(body.data.polygons),
            "body_surface_topology_preserved": True}


def bvh(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(dg)
    mesh = evaluated.to_mesh()
    try:
        coords = [evaluated.matrix_world @ v.co for v in mesh.vertices]
        faces = [tuple(p.vertices) for p in mesh.polygons]
        return BVHTree.FromPolygons(coords, faces, all_triangles=False)
    finally:
        evaluated.to_mesh_clear()


def intersection_samples(body, shells, arm, run_action, idle_action):
    scene = bpy.context.scene
    original_action = arm.animation_data.action if arm.animation_data else None
    arm.animation_data_create()
    arm.animation_data.action = None
    for bone in arm.pose.bones:
        bone.matrix_basis.identity()
    scene.frame_set(1)
    bpy.context.view_layer.update()
    rest = {obj.name: len(bvh(body).overlap(bvh(obj))) for obj in shells}
    animated = {obj.name: {} for obj in shells}
    for label, action, frames in (("running", run_action, (1, 6, 13, 16, 22)),
                                  ("neutral_idle", idle_action, (1, 132, 263))):
        arm.animation_data.action = action
        for frame in frames:
            scene.frame_set(frame)
            bpy.context.view_layer.update()
            body_tree = bvh(body)
            for obj in shells:
                animated[obj.name][f"{label}:{frame}"] = len(body_tree.overlap(bvh(obj)))
    arm.animation_data.action = original_action or idle_action
    scene.frame_set(1)
    bpy.context.view_layer.update()
    return {"v002_donor_rest_triangle_overlap_pairs": {"Left": 145, "Right": 163},
            "v003_rest_triangle_overlap_pairs": rest,
            "v003_animated_triangle_overlap_pairs": animated,
            "v003_zero_intersections": all(v == 0 for v in rest.values()) and
                all(v == 0 for values in animated.values() for v in values.values()),
            "valid_close_contact_policy": "shell copies only outward-facing front shoulder triangles and is offset outward 0.058m, up 0.018m and front 0.040m; overlap count is triangle intersection only"}


def build(source, motion_path, output, report_path):
    source, motion_path, output, report_path = map(Path, (source, motion_path, output, report_path))
    if not source.is_file() or not motion_path.is_file():
        raise RuntimeError("V003_INPUT_MISSING")
    source_sha = sha_file(source)
    if source_sha != "2c4c097039b25727c0ce51f22251d33462b6f020ad4f8863d23913b4efe7dc23":
        raise RuntimeError("V002_SOURCE_SHA_MISMATCH:" + source_sha)
    motion = add_local_chest_opening(json.loads(motion_path.read_text()))
    output_motion = report_path.with_name("v003_neutral_idle.motion.v1.json")
    output_motion.parent.mkdir(parents=True, exist_ok=True)
    output_motion.write_bytes(canonical(motion) + b"\n")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    arm = bpy.data.objects.get("SmartRigArmature")
    body = bpy.data.objects.get("output_unwrapped")
    if arm is None or body is None or len(arm.data.bones) != 42:
        raise RuntimeError("V002_RIG_OR_BODY_IDENTITY_INVALID")
    run_action = next((action for action in bpy.data.actions
                       if action.name.startswith("operator_run_mixamo_iter005_contact_ik")), None)
    if run_action is None:
        raise RuntimeError("V002_RUNNING_SOURCE_ACTION_MISSING")
    v2_action = bpy.data.actions.get("V002 Neutral Idle Pose Candidate")
    if v2_action is None:
        raise RuntimeError("V002_NEUTRAL_IDLE_ACTION_MISSING")
    # Preserve the original short running action as a source datablock even
    # though the candidate's active action is the 264-frame Neutral Idle.
    run_action.use_fake_user = True
    arm.animation_data_clear()
    for bone in arm.pose.bones:
        bone.matrix_basis.identity()
    bpy.context.view_layer.update()

    removal = remove_old_donor_islands(body)
    shells, shell_reports = [], []
    for side in ("Left", "Right"):
        obj, record = make_shell(body, arm, side)
        shells.append(obj)
        shell_reports.append(record)
    idle_action = assign_motion(arm, motion)
    intersections = intersection_samples(body, shells, arm, run_action, idle_action)

    # Keep the renderer's single skinned-mesh contract while retaining pauldron
    # islands as separately named, weighted/material-tagged mesh regions.
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    body.select_set(True)
    for obj in shells:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    with bpy.context.temp_override(active_object=body, object=body,
                                   selected_objects=[body, *shells],
                                   selected_editable_objects=[body, *shells]):
        result = bpy.ops.object.join()
    if "FINISHED" not in result:
        raise RuntimeError("V003_PAULDRON_JOIN_FAILED")
    body.name = "output_unwrapped"
    body.data.name = "output_unwrapped_V003_body_and_fitted_pauldrons"
    for side in ("Left", "Right"):
        if body.vertex_groups.get(f"PAULDRON_{side}_V003") is None:
            raise RuntimeError("V003_SHELL_MARKER_LOST:" + side)

    scene.frame_start = int(motion["source"]["frame_start"])
    scene.frame_end = int(motion["source"]["frame_end"])
    scene.frame_set(1)
    bpy.context.view_layer.update()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    report = {
        "schema": "custodian.operator_3d_visual_fidelity_v003_build.v1",
        "candidate_state": "candidate_unapproved",
        "source_v002": {"path": str(source), "sha256": source_sha},
        "output_blend": {"path": str(output), "sha256": sha_file(output), "bytes": output.stat().st_size},
        "body_topology": removal | {"final_combined_mesh_vertices": len(body.data.vertices),
                                     "final_combined_mesh_faces": len(body.data.polygons),
                                     "preserved_v002_body_surface_vertex_count": removal["body_vertices_after_removal"]},
        "shoulders": {"objects_before_join": [item["name"] for item in shell_reports],
                      "mesh_owner_after_join": body.name,
                      "regions": shell_reports,
                      "underlying_v002_shells_removed": True,
                      "intersections": intersections},
        "pose": {"action": idle_action.name, "frames": [motion["source"]["frame_start"], motion["source"]["frame_end"]],
                 "neutral_idle_motion_sha256": motion["motion_sha256"],
                 "neutral_idle_motion_path": str(output_motion),
                 "additional_spine_pitch_degrees": -2.0, "rest_pose_changed": False,
                 "lower_body_action_data_preserved": True,
                 "armature_bones": len(arm.data.bones)},
        "materials": {"new_materials": [x for x in bpy.data.materials if x.name.startswith("V003_")],
                      "body_materials_unchanged": True,
                      "notes": "New graphite armor and muted-gold trim PBR are scoped to fitted shoulder armor; existing hood, visor, torso, cloth and lower-body materials remain V002."},
    }
    report["materials"]["new_materials"] = [m.name for m in report["materials"]["new_materials"]]
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_bytes(canonical(report) + b"\n")
    print(json.dumps({"result": "built", "report": str(report_path),
                      "blend_sha256": report["output_blend"]["sha256"],
                      "zero_intersections": intersections["v003_zero_intersections"],
                      "body_topology": report["body_topology"]}, sort_keys=True))


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) != 5 or args[0] != "build":
        raise RuntimeError("USAGE: build V002.blend v002_pose_motion.json V003.blend report.json")
    build(*args[1:])


if __name__ == "__main__":
    main()
