#!/usr/bin/env python3
"""Build a bounded, non-production Operator 3D visual-fidelity derivative.

This Blender adapter only writes the output paths passed to it. Source masters,
Task 017 inputs, retarget actions and motion receipts are read-only inputs.
Run with Blender 5.2: blender -b --python this_file.py -- build <args...>
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


def canonical(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sha_json(value) -> str:
    return hashlib.sha256(canonical(value)).hexdigest()


def sha_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def qnormalize(q):
    length = math.sqrt(sum(float(v) * float(v) for v in q))
    if length <= 1e-12:
        raise RuntimeError("ZERO_LENGTH_QUATERNION")
    return tuple(float(v) / length for v in q)


def qmultiply(a, b):
    x1, y1, z1, w1 = qnormalize(a)
    x2, y2, z2, w2 = qnormalize(b)
    return qnormalize((w1*x2 + x1*w2 + y1*z2 - z1*y2,
                       w1*y2 - x1*z2 + y1*w2 + z1*x2,
                       w1*z2 + x1*y2 - y1*x2 + z1*w2,
                       w1*w2 - x1*x2 - y1*y2 - z1*z2))


def qinverse(q):
    x, y, z, w = qnormalize(q)
    return (-x, -y, -z, w)


def qaxis(axis, angle_degrees):
    angle = math.radians(angle_degrees) / 2.0
    scale = math.sin(angle)
    return qnormalize((axis[0] * scale, axis[1] * scale, axis[2] * scale, math.cos(angle)))


def _apply_motion_frame(arm, frame):
    for name, transform in frame["bones"].items():
        pose_bone = arm.pose.bones[name]
        q = transform["rotation_xyzw"]
        pose_bone.location = transform["location"]
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = (q[3], q[0], q[1], q[2])
        pose_bone.scale = transform["scale"]
    bpy.context.view_layer.update()


def _set_world_rotation(arm, pose_bone, world_rotation):
    arm_rotation = arm.matrix_world.to_3x3().normalized()
    local_rotation = arm_rotation.inverted() @ world_rotation
    pose_bone.matrix = Matrix.Translation(pose_bone.matrix.translation) @ local_rotation.to_4x4()
    bpy.context.view_layer.update()


def _solve_leg_to_goal(arm, side, goal, knee_hint):
    thigh = arm.pose.bones[f"mixamorig:{side}UpLeg"]
    shin = arm.pose.bones[f"mixamorig:{side}Leg"]
    foot = arm.pose.bones[f"mixamorig:{side}Foot"]
    upper = (arm.matrix_world.to_3x3() @ arm.data.bones[thigh.name].vector).length
    lower = (arm.matrix_world.to_3x3() @ arm.data.bones[shin.name].vector).length
    root = arm.matrix_world @ thigh.head
    to_goal = goal - root
    raw_distance = to_goal.length
    distance = min(max(raw_distance, abs(upper - lower) + 1e-5), upper + lower - 1e-5)
    axis = to_goal.normalized()
    along = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
    height = math.sqrt(max(0.0, upper * upper - along * along))
    bend = knee_hint - (root + axis * (knee_hint - root).dot(axis))
    if bend.length < 1e-8:
        raise RuntimeError(f"STANCE_KNEE_BEND_DEGENERATE:{side}")
    bend.normalize()
    knee_goal = root + axis * along + bend * height

    desired_foot_world = (arm.matrix_world @ foot.matrix).to_3x3().normalized()
    current_direction = (arm.matrix_world.to_3x3() @ (thigh.tail - thigh.head)).normalized()
    current_world = (arm.matrix_world @ thigh.matrix).to_3x3().normalized()
    delta = current_direction.rotation_difference((knee_goal - root).normalized())
    _set_world_rotation(arm, thigh, delta.to_matrix() @ current_world)

    current_knee = arm.matrix_world @ shin.head
    current_direction = (arm.matrix_world.to_3x3() @ (shin.tail - shin.head)).normalized()
    current_world = (arm.matrix_world @ shin.matrix).to_3x3().normalized()
    delta = current_direction.rotation_difference((goal - current_knee).normalized())
    _set_world_rotation(arm, shin, delta.to_matrix() @ current_world)
    _set_world_rotation(arm, foot, desired_foot_world)
    return arm.matrix_world @ foot.head


def pose_overlay(base_path: Path, calibration_path: Path, output_path: Path, arm) -> dict:
    base = json.loads(base_path.read_text())
    calibration = json.loads(calibration_path.read_text())
    if base["source"]["sha256"] != calibration["source"]["sha256"]:
        raise RuntimeError("POSE_OVERLAY_SOURCE_FBXS_DIFFER")
    if base["target_rig"]["skeleton_signature_sha256"] != calibration["target_rig"]["skeleton_signature_sha256"]:
        raise RuntimeError("POSE_OVERLAY_TARGET_RIG_DIFFER")
    if len(base["frames"]) != len(calibration["frames"]):
        raise RuntimeError("POSE_OVERLAY_FRAME_COUNT_DIFFER")
    calibration_frames = {item["source_frame"]: item for item in calibration["frames"]}
    if set(calibration_frames) != {item["source_frame"] for item in base["frames"]}:
        raise RuntimeError("POSE_OVERLAY_FRAME_SET_DIFFER")

    torso_offsets = {
        "mixamorig:Spine": qaxis((1.0, 0.0, 0.0), -1.0),
        "mixamorig:Spine1": qaxis((1.0, 0.0, 0.0), -1.0),
        "mixamorig:Spine2": qaxis((1.0, 0.0, 0.0), -1.0),
        "mixamorig:Neck": qaxis((1.0, 0.0, 0.0), 1.5),
        "mixamorig:Head": qaxis((1.0, 0.0, 0.0), 1.5),
    }
    first = base["frames"][0]
    _apply_motion_frame(arm, first)
    pelvis = arm.matrix_world @ arm.pose.bones["mixamorig:Hips"].head
    first_offsets = {}
    for side in ("Left", "Right"):
        ankle = arm.matrix_world @ arm.pose.bones[f"mixamorig:{side}Foot"].head
        knee = arm.matrix_world @ arm.pose.bones[f"mixamorig:{side}Leg"].head
        first_offsets[side] = {"ankle": ankle - pelvis, "knee": knee - pelvis}
    target_depth = sum(first_offsets[s]["ankle"].y for s in ("Left", "Right")) / 2.0
    target_height = sum(first_offsets[s]["ankle"].z for s in ("Left", "Right")) / 2.0
    targets = {"Left": Vector((0.16, target_depth, target_height)),
               "Right": Vector((-0.16, target_depth, target_height))}
    measurements = []
    for frame in base["frames"]:
        _apply_motion_frame(arm, frame)
        pelvis = arm.matrix_world @ arm.pose.bones["mixamorig:Hips"].head
        original_offsets = {}
        for side in ("Left", "Right"):
            original_offsets[side] = (arm.matrix_world @ arm.pose.bones[f"mixamorig:{side}Foot"].head) - pelvis
        actual = {}
        for side in ("Left", "Right"):
            goal_offset = targets[side] + original_offsets[side] - first_offsets[side]["ankle"]
            goal = pelvis + goal_offset
            knee_hint = pelvis + first_offsets[side]["knee"] + (original_offsets[side] - first_offsets[side]["ankle"])
            actual[side] = _solve_leg_to_goal(arm, side, goal, knee_hint)
        for name, offset in torso_offsets.items():
            transform = frame["bones"][name]
            transform["rotation_xyzw"] = list(qmultiply(offset, transform["rotation_xyzw"]))
        for side in ("Left", "Right"):
            pose_bone = arm.pose.bones[f"mixamorig:{side}UpLeg"]
            q = pose_bone.rotation_quaternion
            frame["bones"][pose_bone.name]["rotation_xyzw"] = [float(q.x), float(q.y), float(q.z), float(q.w)]
            pose_bone = arm.pose.bones[f"mixamorig:{side}Leg"]
            q = pose_bone.rotation_quaternion
            frame["bones"][pose_bone.name]["rotation_xyzw"] = [float(q.x), float(q.y), float(q.z), float(q.w)]
            pose_bone = arm.pose.bones[f"mixamorig:{side}Foot"]
            q = pose_bone.rotation_quaternion
            frame["bones"][pose_bone.name]["rotation_xyzw"] = [float(q.x), float(q.y), float(q.z), float(q.w)]
        if frame["source_frame"] in (1, 132, 263):
            measurements.append({"source_frame": frame["source_frame"],
                "ankle_separation_m": round((actual["Left"] - actual["Right"]).length, 6),
                "left_ankle_pelvis_relative_m": [round(v, 6) for v in actual["Left"] - pelvis],
                "right_ankle_pelvis_relative_m": [round(v, 6) for v in actual["Right"] - pelvis]})

    base.pop("motion_sha256", None)
    base["pose_candidate"] = {
        "id": "operator_neutral_idle_visual_pose_v002",
        "source_motion_sha256": json.loads(base_path.read_text())["motion_sha256"],
        "stance_reference_motion_sha256": calibration["motion_sha256"],
        "method": "per_frame_two_bone_ik_scoped_idle_pose_overlay",
        "rest_pose_changed": False,
        "source_timing_preserved": True,
        "arm_alignment_offsets": "none",
        "leg_offset_bones": ["mixamorig:LeftUpLeg", "mixamorig:LeftLeg", "mixamorig:LeftFoot",
                             "mixamorig:RightUpLeg", "mixamorig:RightLeg", "mixamorig:RightFoot"],
        "ankle_targets_m_relative_to_pelvis": {side: [round(v, 6) for v in target]
                                                 for side, target in targets.items()},
        "measured_ankle_separation": measurements,
        "torso_local_pitch_offsets_degrees": {
            "mixamorig:Spine": -1.0,
            "mixamorig:Spine1": -1.0,
            "mixamorig:Spine2": -1.0,
            "mixamorig:Neck": 1.5,
            "mixamorig:Head": 1.5,
        },
        "torso_rotation_axis": "local_x",
    }
    base["motion_sha256"] = sha_json(base)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(canonical(base) + b"\n")
    return base


def assign_pose_action(arm, motion: dict) -> str:
    scene = bpy.context.scene
    arm.animation_data_create()
    prior_action = arm.animation_data.action
    action = bpy.data.actions.new("V002 Neutral Idle Pose Candidate")
    arm.animation_data.action = action
    for record in motion["frames"]:
        frame = record["source_frame"]
        scene.frame_set(frame)
        for name, transform in record["bones"].items():
            pose_bone = arm.pose.bones.get(name)
            if pose_bone is None:
                raise RuntimeError(f"POSE_ACTION_BONE_MISSING:{name}")
            pose_bone.rotation_mode = "QUATERNION"
            q = transform["rotation_xyzw"]
            pose_bone.location = transform["location"]
            pose_bone.rotation_quaternion = (q[3], q[0], q[1], q[2])
            pose_bone.scale = transform["scale"]
            pose_bone.keyframe_insert(data_path="location", frame=frame, group=name)
            pose_bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=name)
            pose_bone.keyframe_insert(data_path="scale", frame=frame, group=name)
    action.name = "V002 Neutral Idle Pose Candidate"
    if prior_action is not None and prior_action.name not in bpy.data.actions:
        raise RuntimeError("SOURCE_ACTION_NOT_PRESERVED")
    scene.frame_start = motion["source"]["frame_start"]
    scene.frame_end = motion["source"]["frame_end"]
    scene.render.fps = int(motion["source"]["fps"])
    return action.name


def group_weight(vertex, group_index: int) -> float:
    return next((assignment.weight for assignment in vertex.groups
                 if assignment.group == group_index), 0.0)


def apply_scoped_mesh_changes(body, arm) -> dict:
    mesh = body.data
    group = {vg.name: vg.index for vg in body.vertex_groups}
    required = ("mixamorig:Spine", "mixamorig:Spine1", "mixamorig:Spine2",
                "mixamorig:LeftLeg", "mixamorig:RightLeg", "mixamorig:LeftFoot",
                "mixamorig:RightFoot", "Bone_013", "Bone_005", "Bone_004",
                "Bone_007", "Bone_006", "Bone_012", "Bone_011")
    if any(name not in group for name in required):
        raise RuntimeError("SCOPED_GEOMETRY_VERTEX_GROUP_MISSING")
    center_x = 0.01
    counts = {"torso": 0, "lower_leg": 0, "boot": 0, "cloak": 0}
    for vertex in mesh.vertices:
        x, y, z = vertex.co
        spine_weight = max(group_weight(vertex, group[name])
                           for name in ("mixamorig:Spine", "mixamorig:Spine1", "mixamorig:Spine2"))
        if spine_weight > 0.2 and 0.98 <= z <= 1.35:
            t = max(0.0, min(1.0, (z - 0.98) / 0.37))
            t = t * t * (3.0 - 2.0 * t)
            factor = 0.97 + 0.06 * t
            vertex.co.x = center_x + (x - center_x) * (1.0 + (factor - 1.0) * spine_weight)
            counts["torso"] += 1

        cloth_weight = min(1.0, sum(group_weight(vertex, group[name]) for name in
                                   ("Bone_013", "Bone_005", "Bone_004", "Bone_007",
                                    "Bone_006", "Bone_012", "Bone_011")))
        if cloth_weight > 0.15 and 0.34 <= z <= 0.96:
            t = max(0.0, min(1.0, (0.96 - z) / 0.62))
            t = t * t * (3.0 - 2.0 * t)
            factor = 1.0 + 0.16 * t * cloth_weight
            vertex.co.x = center_x + (vertex.co.x - center_x) * factor
            counts["cloak"] += 1

        for side in ("Left", "Right"):
            leg_index = group[f"mixamorig:{side}Leg"]
            foot_index = group[f"mixamorig:{side}Foot"]
            leg_weight = group_weight(vertex, leg_index)
            foot_weight = group_weight(vertex, foot_index)
            bone_name = f"mixamorig:{side}Leg" if side == "Left" else f"mixamorig:{side}Leg"
            axis_x = arm.data.bones[bone_name].head_local.x
            if leg_weight > 0.25 and 0.08 <= z <= 0.52:
                vertex.co.x = axis_x + (vertex.co.x - axis_x) * (1.0 + 0.04 * leg_weight)
                counts["lower_leg"] += 1
            if foot_weight > 0.25 and z <= 0.20:
                foot_x = arm.data.bones[f"mixamorig:{side}Foot"].head_local.x
                vertex.co.x = foot_x + (vertex.co.x - foot_x) * (1.0 + 0.03 * foot_weight)
                counts["boot"] += 1
    mesh.update()
    return {"modified_vertex_counts": counts,
            "torso_width_profile": {"waist_factor": 0.97, "upper_torso_factor": 1.03,
                                    "vertex_groups": ["mixamorig:Spine", "mixamorig:Spine1", "mixamorig:Spine2"]},
            "cloak_lower_flare_factor": 1.16,
            "cloak_vertex_groups": ["Bone_013", "Bone_005", "Bone_004", "Bone_007", "Bone_006", "Bone_012", "Bone_011"],
            "lower_leg_width_factor": 1.04, "boot_width_factor": 1.03,
            "rest_pose_changed": False}


def clone_task017_shells(task017_path: Path, body, arm, material):
    required_names = ("PAULDRON_Left_TASK017", "PAULDRON_Right_TASK017")
    with bpy.data.libraries.load(str(task017_path), link=False) as (data_from, data_to):
        if any(name not in data_from.objects for name in required_names):
            raise RuntimeError("TASK017_PAULDRON_OBJECT_MISSING")
        data_to.objects = list(required_names)
    shells = []
    for source_name, side in zip(required_names, ("Left", "Right")):
        source_obj = bpy.data.objects.get(source_name)
        if source_obj is None or source_obj.type != "MESH":
            raise RuntimeError(f"TASK017_PAULDRON_INVALID:{source_name}")
        source_obj.name = f"PAULDRON_{side}_V002"
        source_obj.data = source_obj.data.copy()
        bpy.context.scene.collection.objects.link(source_obj)
        source_obj.hide_render = False
        for modifier in list(source_obj.modifiers):
            source_obj.modifiers.remove(modifier)
        armature = source_obj.modifiers.new("Armature", "ARMATURE")
        armature.object = arm
        source_obj.data.materials.clear()
        source_obj.data.materials.append(material)
        pauldron_group = source_obj.vertex_groups.get(f"PAULDRON_{side}_V002")
        if pauldron_group is None:
            pauldron_group = source_obj.vertex_groups.new(name=f"PAULDRON_{side}_V002")
            if len(source_obj.data.vertices):
                pauldron_group.add(list(range(len(source_obj.data.vertices))), 1.0, "REPLACE")
        bone_group = source_obj.vertex_groups.get(f"mixamorig:{side}Shoulder")
        if bone_group is None:
            raise RuntimeError(f"TASK017_RIG_GROUP_MISSING:{side}")
        shells.append(source_obj)
    return shells


def bvh_for_object(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    try:
        vertices = [evaluated.matrix_world @ v.co for v in mesh.vertices]
        polygons = [tuple(p.vertices) for p in mesh.polygons]
        return BVHTree.FromPolygons(vertices, polygons, all_triangles=False)
    finally:
        evaluated.to_mesh_clear()


def check_shell_body_intersections(body, arm, shells, action) -> dict:
    scene = bpy.context.scene
    prior_action = arm.animation_data.action if arm.animation_data else None
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = None
    scene.frame_set(1)
    bpy.context.view_layer.update()
    rest_counts = {}
    for shell in shells:
        rest_counts[shell.name] = len(bvh_for_object(body).overlap(bvh_for_object(shell)))

    arm.animation_data.action = action
    run_action = bpy.data.actions.get("operator_run_mixamo_iter005_contact_ik")
    if run_action is None:
        raise RuntimeError("ITER005_RUNNING_ACTION_MISSING")
    arm.animation_data.action = run_action
    temporal_counts = {shell.name: {} for shell in shells}
    for frame in (1, 6, 13, 16, 22):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        body_tree = bvh_for_object(body)
        for shell in shells:
            temporal_counts[shell.name][str(frame)] = len(body_tree.overlap(bvh_for_object(shell)))
    arm.animation_data.action = prior_action or action
    scene.frame_set(1)
    bpy.context.view_layer.update()
    return {"rest_triangle_overlap_pairs": rest_counts,
            "running_sample_triangle_overlap_pairs": temporal_counts,
            "running_sample_frames": [1, 6, 13, 16, 22],
            "zero_intersections": all(value == 0 for value in rest_counts.values()) and
                all(value == 0 for per_shell in temporal_counts.values() for value in per_shell.values())}


def apply_boolean_clearance(body, shells) -> dict:
    original_count = len(body.data.vertices)
    original_faces = len(body.data.polygons)
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    for shell in shells:
        mod = body.modifiers.new(f"V002_Clearance_{shell.name}", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.solver = "EXACT"
        mod.object = shell
        # The cut is authored in bind space; applying it after the skin modifier
        # would bake a posed body and then skin the result a second time.
        body.modifiers.move(body.modifiers.find(mod.name), 0)
        with bpy.context.temp_override(object=body, active_object=body,
                                       selected_objects=[body], selected_editable_objects=[body]):
            result = bpy.ops.object.modifier_apply(modifier=mod.name)
        if "FINISHED" not in result:
            raise RuntimeError(f"PAULDRON_CLEARANCE_BOOLEAN_FAILED:{shell.name}")
    body.data.name = "output_unwrapped_V002_with_integrated_pauldrons"
    return {"input_body_vertices": original_count, "input_body_faces": original_faces,
            "output_vertices": len(body.data.vertices), "output_faces": len(body.data.polygons),
            "boolean_clearance_applied": True}


def join_shells_into_body(body, shells) -> dict:
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    body.select_set(True)
    for shell in shells:
        shell.select_set(True)
    bpy.context.view_layer.objects.active = body
    with bpy.context.temp_override(active_object=body, object=body,
                                   selected_objects=[body, *shells], selected_editable_objects=[body, *shells]):
        result = bpy.ops.object.join()
    if "FINISHED" not in result:
        raise RuntimeError("PAULDRON_JOIN_FAILED")
    body.data.name = "output_unwrapped_V002_with_integrated_pauldrons"
    if any(body.vertex_groups.get(name) is None for name in
           ("PAULDRON_Left_V002", "PAULDRON_Right_V002",
            "mixamorig:LeftShoulder", "mixamorig:RightShoulder")):
        raise RuntimeError("PAULDRON_VERTEX_GROUPS_NOT_JOINED")
    return {"integrated_task017_objects": ["PAULDRON_Left_TASK017", "PAULDRON_Right_TASK017"],
            "result_mesh_object": body.name,
            "shell_vertex_groups": ["PAULDRON_Left_V002", "PAULDRON_Right_V002"],
            "shell_bone_groups": ["mixamorig:LeftShoulder", "mixamorig:RightShoulder"]}


def material_texture(material):
    if not material or not material.use_nodes:
        raise RuntimeError("BAKED_MATERIAL_NODE_GRAPH_MISSING")
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image and node.image.name.startswith("texture_0"):
            return node
    raise RuntimeError("ALBEDO_IMAGE_NODE_MISSING")


def make_material_variant(source, name, contrast: float, emission_strength: float = 0.0):
    material = source.copy()
    material.name = name
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    principled = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
    tex = material_texture(material)
    if principled is None:
        raise RuntimeError("PRINCIPLED_SHADER_MISSING")
    base_socket = principled.inputs.get("Base Color")
    if base_socket is None:
        raise RuntimeError("BASE_COLOR_SOCKET_MISSING")
    original_output = next((link.from_socket for link in links if link.to_socket == base_socket), None)
    if original_output is None:
        raise RuntimeError("BASE_COLOR_IMAGE_LINK_MISSING")
    if contrast != 0.0:
        contrast_node = nodes.new("ShaderNodeBrightContrast")
        contrast_node.name = f"{name}_Contrast"
        contrast_node.inputs["Bright"].default_value = -0.005
        contrast_node.inputs["Contrast"].default_value = contrast
        links.new(original_output, contrast_node.inputs["Color"])
        for link in list(links):
            if link.to_socket == base_socket:
                links.remove(link)
        links.new(contrast_node.outputs["Color"], base_socket)
    if emission_strength > 0:
        color_socket = principled.inputs.get("Emission Color") or principled.inputs.get("Emission")
        strength_socket = principled.inputs.get("Emission Strength")
        if color_socket is None or strength_socket is None:
            raise RuntimeError("EMISSION_SOCKET_MISSING")
        for link in list(links):
            if link.to_socket == color_socket:
                links.remove(link)
        color_socket.default_value = (1.0, 0.22, 0.025, 1.0)
        strength_socket.default_value = emission_strength
    return material


def apply_materials(body, mode: str) -> dict:
    source = bpy.data.materials.get("BakedMaterial")
    if source is None:
        raise RuntimeError("SOURCE_BAKED_MATERIAL_MISSING")
    if mode not in ("material", "final"):
        return {"changed": False, "reason": "pose-only variant"}
    body_material = make_material_variant(source, "V002_Graphite_Gold_Cloth_PBR", 0.16)
    slots = body.data.materials
    for index, material in enumerate(slots):
        if material and material.name == "BakedMaterial":
            slots[index] = body_material
    if body_material.name not in {m.name for m in slots if m}:
        slots.append(body_material)
    for polygon in body.data.polygons:
        if polygon.material_index < len(slots) and slots[polygon.material_index] is source:
            polygon.material_index = slots.find(body_material.name)

    tex = material_texture(source)
    image_path = Path(tex.image.filepath_from_user()) if tex.image else None
    if image_path is None or not image_path.is_file():
        image_path = Path("custodian/asset_drop/source_work/operator/operator_3d_master/masters/experimental_iter005_baseline_a0bdf6c1/textures/texture_0.png")
    from PIL import Image
    image = Image.open(image_path).convert("RGB")
    pixels = image.load()
    width, height = image.size
    uv_layer = body.data.uv_layers.active
    if uv_layer is None:
        raise RuntimeError("BODY_UV_MAP_MISSING")
    head_group = body.vertex_groups.get("mixamorig:Head")
    if head_group is None:
        raise RuntimeError("HEAD_VERTEX_GROUP_MISSING")
    core_faces, glow_faces = set(), set()
    for polygon in body.data.polygons:
        uvs = [uv_layer.data[index].uv for index in polygon.loop_indices]
        u, v = sum(value.x for value in uvs) / len(uvs), sum(value.y for value in uvs) / len(uvs)
        rgb = pixels[min(width - 1, max(0, int(u * width))),
                     min(height - 1, max(0, int((1.0 - v) * height)))]
        vertices = [body.data.vertices[index] for index in polygon.vertices]
        x = sum(vertex.co.x for vertex in vertices) / len(vertices)
        y = sum(vertex.co.y for vertex in vertices) / len(vertices)
        z = sum(vertex.co.z for vertex in vertices) / len(vertices)
        head = sum(group_weight(vertex, head_group.index) for vertex in vertices) / len(vertices)
        r, g, b = rgb
        if (head >= 0.72 and y < -0.11 and 1.51 <= z <= 1.56 and abs(x) <= 0.035
                and r >= 70 and g >= 35 and r >= 1.25 * g and b <= 90):
            core_faces.add(polygon.index)
    if not core_faces:
        raise RuntimeError("DIRECTIONAL_VISOR_FACE_SELECTION_EMPTY")
    core_centers = []
    for face_id in core_faces:
        polygon = body.data.polygons[face_id]
        core_centers.append(sum((body.data.vertices[index].co for index in polygon.vertices),
                                Vector((0.0, 0.0, 0.0))) / len(polygon.vertices))
    core_material = make_material_variant(source, "V002_Amber_Visor_Core", 0.0, 0.85)
    core_shader = next((node for node in core_material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if core_shader is None:
        raise RuntimeError("VISOR_CORE_SHADER_MISSING")
    core_base = core_shader.inputs.get("Base Color")
    for link in list(core_material.node_tree.links):
        if link.to_socket == core_base:
            core_material.node_tree.links.remove(link)
    core_base.default_value = (0.9, 0.2, 0.025, 1.0)
    core_shader.inputs["Metallic"].default_value = 0.15
    core_shader.inputs["Roughness"].default_value = 0.28
    glow_material = make_material_variant(source, "V002_Amber_Visor_Local_Glow", 0.0, 0.06)
    slots.append(core_material)
    slots.append(glow_material)
    glow_faces = {polygon.index for polygon in body.data.polygons
                  if polygon.index not in core_faces
                  and min((sum((body.data.vertices[index].co for index in polygon.vertices),
                               Vector((0.0, 0.0, 0.0))) / len(polygon.vertices) - center).length
                          for center in core_centers) <= 0.025
                  and 1.46 <= sum(body.data.vertices[index].co.z for index in polygon.vertices) / len(polygon.vertices) <= 1.58
                  and abs(sum(body.data.vertices[index].co.x for index in polygon.vertices) / len(polygon.vertices)) <= 0.08}
    for face_id in core_faces:
        body.data.polygons[face_id].material_index = slots.find(core_material.name)
    for face_id in glow_faces:
        body.data.polygons[face_id].material_index = slots.find(glow_material.name)
    return {"changed": True,
            "body_material": body_material.name,
            "albedo_contrast": 0.16,
            "roughness_metallic_maps_preserved": True,
            "visor_core_faces": sorted(core_faces),
            "visor_core_face_count": len(core_faces),
            "visor_local_glow_face_count": len(glow_faces),
            "visor_emission_core_strength": 0.85,
            "visor_emission_local_strength": 0.06,
            "visor_glow_radius_m": 0.025,
            "global_bloom": False,
            "directional_geometry_visibility": "front-facing source surfaces only"}


def build(mode: str, source: Path, task017: Path, motion_path: Path,
          pose_motion_path: Path, calibration_motion_path: Path, output: Path, report_path: Path):
    if mode not in ("pose", "material", "final"):
        raise RuntimeError("CANDIDATE_MODE_INVALID")
    if not source.is_file() or not task017.is_file() or not motion_path.is_file() or not calibration_motion_path.is_file():
        raise RuntimeError("CANDIDATE_INPUT_MISSING")
    motion = json.loads(motion_path.read_text())
    if motion["target_rig"]["skeleton_signature_sha256"] != "abcadb2f29bb273b25d8db278b5e33af27597a8a68a1c90550a92e2b7da7bbd2":
        raise RuntimeError("SOURCE_MOTION_RIG_SIGNATURE_MISMATCH")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    arm = bpy.data.objects.get("SmartRigArmature")
    body = bpy.data.objects.get("output_unwrapped")
    source_material = bpy.data.materials.get("BakedMaterial")
    if arm is None or body is None or source_material is None:
        raise RuntimeError("SOURCE_MASTER_OBJECTS_MISSING")
    if len(arm.data.bones) != 42:
        raise RuntimeError("SOURCE_MASTER_BONE_COUNT_MISMATCH")
    run_action = bpy.data.actions.get("operator_run_mixamo_iter005_contact_ik")
    if run_action is None:
        raise RuntimeError("SOURCE_ITER005_ACTION_MISSING")
    source_frame_range = [int(round(run_action.frame_range[0])), int(round(run_action.frame_range[1]))]

    arm.animation_data_clear()
    scene.frame_set(1)
    for pose_bone in arm.pose.bones:
        pose_bone.matrix_basis.identity()
    bpy.context.view_layer.update()

    geometry_report = apply_scoped_mesh_changes(body, arm) if mode in ("pose", "final") else {"changed": False}
    shells = []
    pauldron_report = {"included": False}
    if mode in ("pose", "final"):
        shells = clone_task017_shells(task017, body, arm, source_material)
        pauldron_check = check_shell_body_intersections(body, arm, shells, run_action)
        join_report = join_shells_into_body(body, shells)
        pauldron_report = {**join_report, "body_intersection_measurement": pauldron_check,
                           "clearance_status": "unresolved_preserved_task017_geometry",
                           "body_shell_boolean": "not_applied_to_preserve_source_topology"}
        joined_left = body.vertex_groups["PAULDRON_Left_V002"]
        joined_right = body.vertex_groups["PAULDRON_Right_V002"]
        pauldron_report["integrated_shell_vertex_counts"] = {
            "Left": sum(1 for v in body.data.vertices if group_weight(v, joined_left.index) > 0.99),
            "Right": sum(1 for v in body.data.vertices if group_weight(v, joined_right.index) > 0.99),
        }
        pauldron_report["approved_geometry_reference"] = {
            "task017_candidate_sha256": sha_file(task017),
            "outer_projection_m": 0.295,
            "baseline_projection_m": 0.255,
            "projection_delta_m": 0.040,
            "top_ridge_lift_m": 0.015,
            "left_right_construction_symmetric": True,
        }

    material_report = apply_materials(body, mode)
    if mode in ("pose", "final"):
        corrected_motion = pose_overlay(motion_path, calibration_motion_path, pose_motion_path, arm)
        neutral_action_name = assign_pose_action(arm, corrected_motion)
        arm.animation_data.action = bpy.data.actions[neutral_action_name]
        scene.frame_start = corrected_motion["source"]["frame_start"]
        scene.frame_end = corrected_motion["source"]["frame_end"]
    else:
        corrected_motion = None
        neutral_action_name = None
        arm.animation_data_create()
        arm.animation_data.action = run_action

    if run_action.name not in bpy.data.actions:
        raise RuntimeError("ITER005_ACTION_REMOVED")
    scene.frame_start, scene.frame_end = source_frame_range
    scene.frame_set(1)
    bpy.context.view_layer.update()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))

    report = {
        "schema": "custodian.operator_3d_visual_fidelity_candidate_build.v1",
        "mode": mode,
        "candidate_state": "candidate_unapproved",
        "source": {"path": str(source), "sha256": sha_file(source)},
        "task017_pauldron_source": {"path": str(task017), "sha256": sha_file(task017)},
        "motion_source": {"path": str(motion_path), "sha256": sha_file(motion_path),
                          "motion_sha256": motion.get("motion_sha256")},
        "calibration_source": {"path": str(calibration_motion_path),
                                "sha256": sha_file(calibration_motion_path),
                                "motion_sha256": json.loads(calibration_motion_path.read_text())["motion_sha256"]},
        "pose_motion": ({"path": str(pose_motion_path), "sha256": sha_file(pose_motion_path),
                         "motion_sha256": corrected_motion["motion_sha256"]} if corrected_motion else None),
        "output_blend": {"path": str(output), "sha256": sha_file(output), "bytes": output.stat().st_size},
        "armature": {"name": arm.name, "bone_count": len(arm.data.bones),
                     "rest_pose_changed": False, "source_action": run_action.name,
                     "source_action_frame_range": source_frame_range,
                     "candidate_action": neutral_action_name,
                     "neutral_action_frame_range": ([motion["source"]["frame_start"], motion["source"]["frame_end"]]
                                                      if corrected_motion else None)},
        "geometry": geometry_report,
        "pauldrons": pauldron_report,
        "materials": material_report,
        "approval_state": "experimental",
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_bytes(canonical(report) + b"\n")
    print(json.dumps({"result": "built", "mode": mode,
                      "output_sha256": report["output_blend"]["sha256"],
                      "bytes": report["output_blend"]["bytes"],
                      "bones": report["armature"]["bone_count"],
                      "geometry": geometry_report,
                      "pauldrons": pauldron_report,
                      "materials": material_report}, sort_keys=True))


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if not args or args.pop(0) != "build":
        raise RuntimeError("USAGE: build <mode> <source.blend> <task017.blend> <motion.json> <pose-motion.json> <calibration-motion.json> <output.blend> <report.json>")
    mode, source, task017, motion, pose_motion, calibration, output, report = args
    build(mode, Path(source), Path(task017), Path(motion), Path(pose_motion),
          Path(calibration), Path(output), Path(report))


if __name__ == "__main__":
    main()
