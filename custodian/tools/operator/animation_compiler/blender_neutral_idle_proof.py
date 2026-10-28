"""Single-clip Blender adapter for the experimental Neutral Idle proof.

Run with Blender 5.2: blender -b --python this_file.py -- <retarget|render> <args...>
It never saves or writes the supplied FBX or master blend.
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))

import bpy
from mathutils import Matrix, Quaternion, Vector
from neutral_idle_proof_contract import blender_quaternion, validate_mapping, validate_motion
from retarget_calibration import (calibrated_target_world_xyzw, source_ground_contact_indices,
                                  stable_contact_frame_indices)

LOOP_DUPLICATE_TOLERANCE = {
    "source_rotation_degrees": 1e-5,
    "source_joint_position_m": 1e-3,
    "target_local_rotation_degrees": 0.1,
    "target_local_location_m": 1e-4,
}


def sha_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def canonical(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sha_json(value) -> str:
    return hashlib.sha256(canonical(value)).hexdigest()


def armature_signature(arm):
    bones = []
    for bone in arm.data.bones:
        bones.append({"name": bone.name, "parent": bone.parent.name if bone.parent else None,
                      "head": [round(float(v), 8) for v in bone.head_local],
                      "tail": [round(float(v), 8) for v in bone.tail_local],
                      "matrix": [[round(float(v), 8) for v in row] for row in bone.matrix_local]})
    return {"armature": arm.name, "bones": bones, "signature_sha256": sha_json(bones)}


def rot3(matrix):
    return matrix.to_3x3().normalized()


def xyzw(quaternion):
    return (float(quaternion.x), float(quaternion.y), float(quaternion.z), float(quaternion.w))


def set_pose_world_rotation(armature, pose_bone, world_rotation):
    arm_world_rot = rot3(armature.matrix_world)
    arm_rotation = arm_world_rot.inverted() @ world_rotation
    pose_bone.matrix = Matrix.Translation(pose_bone.matrix.translation) @ arm_rotation.to_4x4()
    bpy.context.view_layer.update()


def solve_two_bone_leg_from_source(target, source, side, ankle_raise_m=0.0):
    """Fit target thigh/shin directions to source pelvis-relative ankle placement."""
    hip_name, thigh_name, shin_name, foot_name = (
        "mixamorig:Hips", f"mixamorig:{side}UpLeg", f"mixamorig:{side}Leg", f"mixamorig:{side}Foot")
    target_hip = target.matrix_world @ target.pose.bones[thigh_name].head
    source_hip = source.matrix_world @ source.pose.bones[thigh_name].head
    source_ankle = source.matrix_world @ source.pose.bones[foot_name].head
    source_knee = source.matrix_world @ source.pose.bones[shin_name].head
    world_scale = lambda arm, bone: (arm.matrix_world.to_3x3() @ arm.data.bones[bone].vector).length
    source_upper = world_scale(source, thigh_name)
    source_lower = world_scale(source, shin_name)
    target_upper = world_scale(target, thigh_name)
    target_lower = world_scale(target, shin_name)
    scale = (target_upper + target_lower) / (source_upper + source_lower)
    goal = target_hip + (source_ankle - source_hip) * scale
    goal.z += ankle_raise_m
    knee_hint = target_hip + (source_knee - source_hip) * scale
    thigh = target.pose.bones[thigh_name]
    shin = target.pose.bones[shin_name]
    foot = target.pose.bones[foot_name]
    desired_foot_world = rot3(target.matrix_world @ foot.matrix)
    root = target.matrix_world @ thigh.head
    to_goal = goal - root
    raw_distance = to_goal.length
    epsilon = 1e-5
    distance = min(max(raw_distance, abs(target_upper - target_lower) + epsilon),
                   target_upper + target_lower - epsilon)
    axis = to_goal.normalized()
    along = (target_upper * target_upper - target_lower * target_lower + distance * distance) / (2.0 * distance)
    height = math.sqrt(max(0.0, target_upper * target_upper - along * along))
    bend = knee_hint - (root + axis * (knee_hint - root).dot(axis))
    if bend.length < 1e-8:
        raise RuntimeError(f"SOURCE_KNEE_BEND_PLANE_DEGENERATE:{side}")
    bend.normalize()
    knee_goal = root + axis * along + bend * height

    current_thigh_world = rot3(target.matrix_world @ thigh.matrix)
    current_thigh_direction = (target.matrix_world.to_3x3() @ (thigh.tail - thigh.head)).normalized()
    thigh_delta = current_thigh_direction.rotation_difference((knee_goal - root).normalized())
    set_pose_world_rotation(target, thigh, thigh_delta.to_matrix() @ current_thigh_world)

    current_knee = target.matrix_world @ shin.head
    current_shin_world = rot3(target.matrix_world @ shin.matrix)
    current_shin_direction = (target.matrix_world.to_3x3() @ (shin.tail - shin.head)).normalized()
    shin_delta = current_shin_direction.rotation_difference((goal - current_knee).normalized())
    set_pose_world_rotation(target, shin, shin_delta.to_matrix() @ current_shin_world)
    set_pose_world_rotation(target, foot, desired_foot_world)
    actual_ankle = target.matrix_world @ foot.head
    return {"side": side, "source_to_target_chain_scale": round(float(scale), 9),
        "target_goal_m": [round(float(v), 9) for v in goal],
        "actual_ankle_m": [round(float(v), 9) for v in actual_ankle],
        "ankle_goal_error_m": round(float((actual_ankle - goal).length), 9),
        "reach_clamped": abs(raw_distance - distance) > 1e-7,
        "ankle_raise_m": round(float(ankle_raise_m), 9)}


def discover_sole_vertices(mesh, side):
    foot = mesh.vertex_groups.get(f"mixamorig:{side}Foot")
    toe = mesh.vertex_groups.get(f"mixamorig:{side}ToeBase")
    if foot is None or toe is None:
        raise RuntimeError(f"FOOTWEAR_WEIGHT_GROUP_MISSING:{side}")
    result = []
    for vertex in mesh.data.vertices:
        foot_weight = toe_weight = 0.0
        try:
            foot_weight = foot.weight(vertex.index)
        except RuntimeError:
            pass
        try:
            toe_weight = toe.weight(vertex.index)
        except RuntimeError:
            pass
        if max(foot_weight, toe_weight) >= 0.35 and vertex.co.z <= 0.012:
            result.append(vertex.index)
    if not result:
        raise RuntimeError(f"SOLE_LANDMARKS_MISSING:{side}")
    return result


def minimum_sole_z(mesh, vertex_indices):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = mesh.evaluated_get(depsgraph)
    evaluated_mesh = evaluated.to_mesh()
    result = min((mesh.matrix_world @ evaluated_mesh.vertices[index].co).z for index in vertex_indices)
    evaluated.to_mesh_clear()
    return float(result)


def source_contact_frames(source, start, end, side, speed_limit_m=0.005, ground_height_m=0.04):
    """Identify stable source foot/toe landmarks that also lie near source ground."""
    scene = bpy.context.scene
    toe_name = f"mixamorig:{side}ToeBase"
    foot_name = f"mixamorig:{side}Foot"
    hip_name = "mixamorig:Hips"
    if toe_name not in source.pose.bones or foot_name not in source.pose.bones:
        raise RuntimeError(f"SOURCE_CONTACT_LANDMARK_MISSING:{side}")
    relative = []
    for frame in range(start, end + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        hip = source.matrix_world @ source.pose.bones[hip_name].head
        toe = source.matrix_world @ source.pose.bones[toe_name].head
        foot = source.matrix_world @ source.pose.bones[foot_name].head
        toe_tail = source.matrix_world @ source.pose.bones[toe_name].tail
        foot_tail = source.matrix_world @ source.pose.bones[foot_name].tail
        relative.append((toe - hip, foot - hip, min(toe.z, toe_tail.z, foot.z, foot_tail.z)))
    toe_indices = stable_contact_frame_indices([tuple(value[0]) for value in relative], speed_limit_m)
    foot_indices = stable_contact_frame_indices([tuple(value[1]) for value in relative], speed_limit_m)
    stable = toe_indices & foot_indices
    grounded = source_ground_contact_indices(stable, [value[2] for value in relative], ground_height_m)
    return {start + index for index in grounded}


def target_armature():
    matches = [obj for obj in bpy.data.objects if obj.type == "ARMATURE" and obj.name == "SmartRigArmature"]
    if len(matches) != 1:
        raise RuntimeError("TARGET_ARMATURE_IDENTITY_INVALID")
    return matches[0]


def inventory(master_path: Path, fbx_path: Path, output_path: Path):
    bpy.ops.wm.open_mainfile(filepath=str(master_path))
    arm = target_armature()
    mesh_matches = [obj for obj in bpy.data.objects if obj.type == "MESH" and len(obj.vertex_groups)]
    if len(mesh_matches) != 1:
        raise RuntimeError("TARGET_SKINNED_MESH_IDENTITY_INVALID")
    mesh = mesh_matches[0]
    arm_sig = armature_signature(arm)
    rest_pose = [{"name": b.name, "matrix": [[round(float(v), 8) for v in row] for row in b.matrix_local]}
                 for b in arm.data.bones]
    identity = {"object_name": arm.name, "data_name": arm.data.name, "library": arm.library.filepath if arm.library else None}
    mesh_data = {"name": mesh.data.name, "vertices": [[round(float(v), 8) for v in vert.co] for vert in mesh.data.vertices],
                 "polygons": [list(poly.vertices) for poly in mesh.data.polygons],
                 "groups": [group.name for group in mesh.vertex_groups]}
    materials = []
    textures = []
    texture_dir = output_path.parent / "textures"
    texture_dir.mkdir(parents=True, exist_ok=True)
    for material in mesh.data.materials:
        node_graph = []
        if material and material.use_nodes and material.node_tree:
            for node in material.node_tree.nodes:
                item = {"type": node.bl_idname, "name": node.name}
                if node.type == "TEX_IMAGE" and node.image:
                    image = node.image
                    packed = image.packed_file
                    if packed:
                        filename = f"{image.name.replace('/', '_')}_{len(textures):02d}.bin"
                        path = texture_dir / filename
                        path.write_bytes(bytes(packed.data))
                        textures.append({"path": "textures/" + filename, "sha256": sha_file(path),
                                         "image_name": image.name, "size": list(image.size)})
                        item["image_sha256"] = textures[-1]["sha256"]
                    else:
                        item["image_path"] = image.filepath
                node_graph.append(item)
        materials.append({"name": material.name if material else "<none>",
                          "node_graph": node_graph})
    for existing_action in bpy.data.actions:
        if existing_action.name == "Armature|mixamo.com|Layer0":
            existing_action.name = "__preserved_master__Armature_mixamo.com_Layer0"
    before = {obj.name for obj in bpy.data.objects}
    bpy.ops.import_scene.fbx(filepath=str(fbx_path), automatic_bone_orientation=False)
    imported = [obj for obj in bpy.data.objects if obj.name not in before and obj.type == "ARMATURE"]
    if len(imported) != 1:
        raise RuntimeError("SOURCE_ARMATURE_IDENTITY_INVALID")
    source = imported[0]
    action = source.animation_data.action if source.animation_data else None
    if action is None:
        raise RuntimeError("SOURCE_ACTION_MISSING")
    start, end = (int(round(value)) for value in action.frame_range)
    data = {
        "master": {"master_id": "experimental_iter005_baseline", "armature_identity": identity,
            "armature_identity_sha256": sha_json(identity), "armature_rest_pose_sha256": sha_json(rest_pose),
            "armature": arm_sig, "rest_pose": rest_pose, "mesh_name": mesh.name,
            "mesh_data": mesh_data, "mesh_data_sha256": sha_json(mesh_data),
            "materials": materials, "material_sha256": sha_json(materials), "textures": textures},
        "source": {"filename": fbx_path.name, "sha256": sha_file(fbx_path), "armature": armature_signature(source),
            "action": action.name, "fps": int(bpy.context.scene.render.fps), "frame_start": start, "frame_end": end,
            "frame_count": end - start + 1},
        "blender_version": bpy.app.version_string,
        "fbx_import_settings": {"automatic_bone_orientation": False, "use_manual_orientation": False,
            "ignore_leaf_bones": False, "force_connect_children": False, "image_search": True},
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(canonical(data) + b"\n")
    print(json.dumps({"result": "inspected", "master_bones": len(arm.data.bones), "source_bones": len(source.data.bones),
        "action": action.name, "frames": [start, end], "fps": data["source"]["fps"],
        "master_mesh": mesh.name, "material_count": len(materials), "packed_textures": len(textures)}, sort_keys=True))


def retarget(master_path: Path, fbx_path: Path, out_path: Path, policy_path: Path,
             mapping_policy_path: Path, reference_path: Path):
    bpy.ops.wm.open_mainfile(filepath=str(master_path))
    scene = bpy.context.scene
    target = target_armature()
    # The master carries ITER005 Running for inspection. Clear it from this
    # in-memory candidate scene so it cannot contaminate the calibrated pose.
    # The source .blend and its action datablock on disk remain untouched.
    target.animation_data_clear()
    for existing_action in bpy.data.actions:
        if existing_action.name == "Armature|mixamo.com|Layer0":
            existing_action.name = "__preserved_master__Armature_mixamo.com_Layer0"
    target_signature = armature_signature(target)
    target_bones = {bone.name: bone for bone in target.data.bones}
    target_rest_world = {name: rot3(target.matrix_world @ bone.matrix_local) for name, bone in target_bones.items()}
    target_names_before = {obj.name for obj in bpy.data.objects}
    bpy.ops.import_scene.fbx(filepath=str(fbx_path), automatic_bone_orientation=False)
    sources = [obj for obj in bpy.data.objects if obj.name not in target_names_before and obj.type == "ARMATURE"]
    if len(sources) != 1:
        raise RuntimeError("SOURCE_ARMATURE_IDENTITY_INVALID")
    source = sources[0]
    action = source.animation_data.action if source.animation_data else None
    if action is None:
        raise RuntimeError("SOURCE_ACTION_MISSING")
    start, end = (int(round(value)) for value in action.frame_range)
    source_fps = int(scene.render.fps)
    source_fps_base = float(scene.render.fps_base)
    if source_fps <= 0 or abs(source_fps_base - 1.0) > 1e-8:
        raise RuntimeError("SOURCE_FPS_INVALID")
    policy = json.loads(policy_path.read_text())
    if policy.get("schema") != "custodian.operator_3d_retarget_policy.v2":
        raise RuntimeError("REST_FRAME_RETARGET_POLICY_REQUIRED")
    if sha_file(reference_path) != policy.get("reference_pose", {}).get("source_sha256"):
        raise RuntimeError("REFERENCE_POSE_SOURCE_HASH_MISMATCH")
    scene.render.fps = source_fps
    scene.render.fps_base = 1.0
    scene.frame_start, scene.frame_end = start, end
    source_bones = {bone.name: bone for bone in source.data.bones}
    if "mixamorig:Hips" not in source_bones or "mixamorig:Hips" not in target_bones:
        raise RuntimeError("HIPS_BONE_MISSING")
    source_signature = armature_signature(source)
    mapped = sorted(set(source_bones) & set(target_bones))
    inherited = sorted(set(target_bones) - set(source_bones))
    unmapped_source = sorted(set(source_bones) - set(target_bones))
    mapping_policy = json.loads(mapping_policy_path.read_text())
    validate_mapping(sorted(source_bones), sorted(target_bones), mapped, inherited, unmapped_source,
        allowed_inherited=mapping_policy["allowed_hierarchy_inherited_target_bones"],
        allowed_unmapped_source=mapping_policy["allowed_unmapped_source_bones"])
    if len(mapped) < 20 or not inherited:
        raise RuntimeError("SKELETON_MAPPING_UNEXPECTED")
    source_rest_world = {name: rot3(source.matrix_world @ source_bones[name].matrix_local) for name in mapped}
    target_meshes = [obj for obj in bpy.data.objects if obj.type == "MESH" and len(obj.vertex_groups)
                     and any(mod.type == "ARMATURE" and mod.object == target for mod in obj.modifiers)]
    if len(target_meshes) != 1:
        raise RuntimeError("TARGET_SKINNED_MESH_IDENTITY_INVALID")
    target_mesh = target_meshes[0]
    sole_vertices = {side: discover_sole_vertices(target_mesh, side) for side in ("Left", "Right")}
    source_contact = {side: source_contact_frames(source, start, end, side) for side in ("Left", "Right")}
    if sha_file(fbx_path) == sha_file(reference_path):
        reference = source
    else:
        objects_before_reference = {obj.name for obj in bpy.data.objects}
        bpy.ops.import_scene.fbx(filepath=str(reference_path), automatic_bone_orientation=False)
        reference_armatures = [obj for obj in bpy.data.objects
                               if obj.type == "ARMATURE" and obj.name not in objects_before_reference]
        if len(reference_armatures) != 1:
            raise RuntimeError("REFERENCE_ARMATURE_IDENTITY_INVALID")
        reference = reference_armatures[0]
    reference_signature = armature_signature(reference)
    if reference_signature["signature_sha256"] != source_signature["signature_sha256"]:
        raise RuntimeError("REFERENCE_SKELETON_SIGNATURE_MISMATCH")
    reference_action = reference.animation_data.action if reference.animation_data else None
    if reference_action is None:
        raise RuntimeError("REFERENCE_ACTION_MISSING")
    reference_frame = int(policy["reference_pose"]["frame"])
    if not int(round(reference_action.frame_range[0])) <= reference_frame <= int(round(reference_action.frame_range[1])):
        raise RuntimeError("REFERENCE_FRAME_OUT_OF_RANGE")
    scene.frame_set(reference_frame)
    bpy.context.view_layer.update()
    source_reference_world = {name: rot3(reference.matrix_world @ reference.pose.bones[name].matrix) for name in mapped}
    calibration_data = {name: {
        "source_reference_world_xyzw": [round(v, 9) for v in xyzw(source_reference_world[name].to_quaternion())],
        "target_rest_world_xyzw": [round(v, 9) for v in xyzw(target_rest_world[name].to_quaternion())],
        "source_reference_to_target_rest_xyzw": [round(v, 9) for v in xyzw(
            (source_reference_world[name].inverted() @ target_rest_world[name]).to_quaternion())],
    } for name in mapped}
    depth = lambda bone: len(bone.parent_recursive)
    ordered = sorted((target_bones[name] for name in mapped), key=depth)
    rest_hips = target_bones["mixamorig:Hips"].matrix_local.translation.copy()
    frames = []
    leg_ik_diagnostics = []
    trajectory = []
    trajectory_origin = None
    for frame in range(start, end + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        source_hips = source.matrix_world @ source.pose.bones["mixamorig:Hips"].matrix.translation
        if trajectory_origin is None:
            trajectory_origin = source_hips.copy()
        trajectory.append({"source_frame": frame,
            "world_position": [round(float(v), 9) for v in source_hips],
            "displacement_from_first_frame": [round(float(v), 9) for v in source_hips - trajectory_origin]})
        for pose_bone in target.pose.bones:
            pose_bone.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        for bone in ordered:
            name = bone.name
            source_world_pose = rot3(source.matrix_world @ source.pose.bones[name].matrix)
            desired_world_xyzw = calibrated_target_world_xyzw(
                xyzw(source_world_pose.to_quaternion()), xyzw(source_reference_world[name].to_quaternion()),
                xyzw(target_rest_world[name].to_quaternion()),
            )
            desired_world = Quaternion((
                desired_world_xyzw[3], *desired_world_xyzw[:3]
            )).to_matrix()
            desired_local = rot3(rot3(target.matrix_world).inverted() @ desired_world)
            pose_bone = target.pose.bones[name]
            translation = rest_hips if name == "mixamorig:Hips" else pose_bone.matrix.translation.copy()
            pose_bone.matrix = Matrix.Translation(translation) @ desired_local.to_4x4()
            bpy.context.view_layer.update()
        if policy.get("leg_placement_solver", "").startswith("source_thigh_head_relative_ankles_scaled_to_target_chain_length_two_bone_ik"):
            legs = []
            for side in ("Left", "Right"):
                diagnostic = solve_two_bone_leg_from_source(target, source, side)
                sole_z_before = minimum_sole_z(target_mesh, sole_vertices[side])
                ankle_raise = 0.0
                if frame in source_contact[side] and sole_z_before < 0.001:
                    ankle_raise = min(0.030, 0.001 - sole_z_before)
                    diagnostic = solve_two_bone_leg_from_source(target, source, side, ankle_raise)
                    sole_z_after = minimum_sole_z(target_mesh, sole_vertices[side])
                    if sole_z_after < -0.001:
                        ankle_raise = min(0.030, ankle_raise + (0.001 - sole_z_after))
                        diagnostic = solve_two_bone_leg_from_source(target, source, side, ankle_raise)
                        sole_z_after = minimum_sole_z(target_mesh, sole_vertices[side])
                    if sole_z_after < -0.001:
                        raise RuntimeError(f"CONTACT_SOLE_CLEARANCE_UNSATISFIED:{side}:{frame}:{sole_z_after:.6f}")
                diagnostic.update({"source_contact": frame in source_contact[side],
                    "sole_vertex_count": len(sole_vertices[side]),
                    "sole_min_z_before_m": round(sole_z_before, 9),
                    "sole_min_z_after_m": round(minimum_sole_z(target_mesh, sole_vertices[side]), 9),
                    "contact_ankle_raise_m": round(ankle_raise, 9)})
                legs.append(diagnostic)
            leg_ik_diagnostics.append({"source_frame": frame, "legs": legs})
        locals_for_frame = {}
        for pose_bone in target.pose.bones:
            basis = pose_bone.matrix_basis
            q = basis.to_quaternion()
            locals_for_frame[pose_bone.name] = {
                "location": [round(float(v), 9) for v in basis.translation],
                "rotation_xyzw": [round(float(q.x), 9), round(float(q.y), 9), round(float(q.z), 9), round(float(q.w), 9)],
                "scale": [round(float(v), 9) for v in basis.to_scale()],
            }
        frames.append({"source_frame": frame, "bones": locals_for_frame})
    # Action endpoints are compared on the source armature using global rotations.
    scene.frame_set(start)
    first = {n: rot3(source.matrix_world @ source.pose.bones[n].matrix) for n in source_bones}
    first_heads = {n: source.matrix_world @ source.pose.bones[n].head for n in source_bones}
    scene.frame_set(end)
    last = {n: rot3(source.matrix_world @ source.pose.bones[n].matrix) for n in source_bones}
    last_heads = {n: source.matrix_world @ source.pose.bones[n].head for n in source_bones}
    source_seam = max(math.degrees((last[n] @ first[n].inverted()).to_quaternion().angle) for n in source_bones)
    source_position_seam = max((last_heads[n] - first_heads[n]).length for n in source_bones)
    first_target, last_target = frames[0]["bones"], frames[-1]["bones"]
    target_rotation_seam = max(math.degrees(2 * math.acos(min(1.0, abs(sum(
        a*b for a, b in zip(first_target[n]["rotation_xyzw"], last_target[n]["rotation_xyzw"])
    ))))) for n in first_target)
    target_position_seam = max(Vector(last_target[n]["location"]).__sub__(Vector(first_target[n]["location"])).length
                               for n in first_target)
    terminal_duplicate = (
        source_seam <= LOOP_DUPLICATE_TOLERANCE["source_rotation_degrees"] and
        source_position_seam <= LOOP_DUPLICATE_TOLERANCE["source_joint_position_m"] and
        target_rotation_seam <= LOOP_DUPLICATE_TOLERANCE["target_local_rotation_degrees"] and
        target_position_seam <= LOOP_DUPLICATE_TOLERANCE["target_local_location_m"]
    )
    policy_sha = sha_file(policy_path)
    animation_id = "_".join(fbx_path.stem.lower().replace("-", " ").split())
    motion = {
        "schema": "custodian.operator_retargeted_motion.v1",
        "animation_id": animation_id, "source": {"filename": fbx_path.name, "sha256": sha_file(fbx_path),
            "action": action.name, "fps": source_fps, "fps_base": source_fps_base, "frame_start": start, "frame_end": end,
            "frame_count": end - start + 1, "source_skeleton_signature_sha256": source_signature["signature_sha256"]},
        "retarget_policy": {"policy_id": policy["policy_id"], "version": policy["version"], "sha256": policy_sha,
                            "mapping_policy_id": mapping_policy["policy_id"],
                            "mapping_policy_version": mapping_policy["version"],
                            "mapping_policy_sha256": sha_file(mapping_policy_path),
                            "calibration_formula": policy["orientation_transfer"]["formula"],
                            "calibration_space": "validated_armature_world_rotation; source_reference_pose_to_target_rest",
                            "reference_pose": {"source_sha256": sha_file(reference_path),
                                "source_skeleton_signature_sha256": reference_signature["signature_sha256"],
                                "action": reference_action.name, "frame": reference_frame},
                            "leg_placement_solver": policy.get("leg_placement_solver", "none"),
                            "contact_clearance": {side: {"source_contact_frame_count": len(source_contact[side]),
                                "source_contact_frames": sorted(source_contact[side]),
                                "stable_weighted_sole_vertex_indices": sole_vertices[side],
                                "source_landmark_speed_threshold_m_per_frame": 0.005,
                                "source_ground_height_tolerance_m": 0.04,
                                "ground_plane_z_m": 0.0, "target_clearance_m": 0.001,
                                "maximum_ankle_correction_m": 0.03} for side in ("Left", "Right")},
                            "leg_ik_diagnostics": leg_ik_diagnostics,
                            "bone_calibration": calibration_data},
        "target_rig": {"armature_identity": target.name, "skeleton_signature_sha256": target_signature["signature_sha256"],
                       "bone_names": sorted(target_bones)},
        "mapping": {"directly_mapped_bones": mapped, "hierarchy_inherited_target_bones": inherited,
                    "unmapped_source_bones": unmapped_source},
        "root_motion": {"policy": "extract_to_metadata", "source_state": "present",
                        "trajectory_artifact": f"{animation_id}_root_trajectory.v1.json",
                        "sprite_pose_root_translation": "removed", "godot_application": "metadata_only_never_apply"},
        "loop": {"source_endpoint_max_rotation_delta_degrees": round(source_seam, 8),
                 "source_endpoint_max_joint_delta_m": round(float(source_position_seam), 9),
                 "target_endpoint_max_local_rotation_delta_degrees": round(target_rotation_seam, 8),
                 "target_endpoint_max_local_location_delta_m": round(float(target_position_seam), 9),
                 "duplicate_test_tolerance": LOOP_DUPLICATE_TOLERANCE,
                 "terminal_pose_duplicate": terminal_duplicate,
                 "loop_frame_policy": "omit_duplicate_terminal" if terminal_duplicate else "include_authored_terminal"},
        "frames": frames,
    }
    trajectory_doc = {"schema": "custodian.operator_root_trajectory.v1", "animation_id": animation_id,
        "source_sha256": motion["source"]["sha256"], "source_skeleton_signature_sha256": source_signature["signature_sha256"],
        "fps": source_fps, "frame_start": start, "frame_end": end, "coordinates": "source_armature_world_meters",
        "relative_to_first_frame": True, "samples": trajectory}
    trajectory_path = out_path.with_name(f"{animation_id}_root_trajectory.v1.json")
    trajectory_path.write_bytes(canonical(trajectory_doc) + b"\n")
    motion["root_motion"]["trajectory_sha256"] = sha_file(trajectory_path)
    motion["motion_sha256"] = sha_json(motion)
    validate_motion(motion)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(canonical(motion) + b"\n")
    mapping_doc = {"schema": "custodian.operator_skeleton_mapping.v1", "source": source_signature,
        "target": target_signature, "directly_mapped_bones": mapped,
        "hierarchy_inherited_target_bones": inherited, "unmapped_source_bones": sorted(set(source_bones) - set(target_bones)),
        "result": "compatible"}
    mapping_path = out_path.with_name(f"{animation_id}_skeleton_mapping.v1.json")
    mapping_doc["mapping_sha256"] = sha_json(mapping_doc)
    mapping_path.write_bytes(canonical(mapping_doc) + b"\n")
    print(json.dumps({"result": "retargeted", "motion_sha256": motion["motion_sha256"],
        "trajectory_sha256": motion["root_motion"]["trajectory_sha256"], "mapping": {"direct": len(mapped), "inherited": len(inherited),
        "unmapped_source": len(mapping_doc["unmapped_source_bones"])}, "source_action": action.name,
        "frame_range": [start, end], "loop_seam_degrees": source_seam,
        "target_loop_seam_degrees": target_rotation_seam, "target_loop_position_m": target_position_seam}, sort_keys=True))


def render(master_path: Path, motion_path: Path, out_dir: Path, sample_only: bool = False,
           selected_frames=None, selected_directions=None, resolution: int = 128, fixed_scale=None):
    if resolution not in (128, 512):
        raise RuntimeError("RENDER_RESOLUTION_UNSUPPORTED")
    bpy.ops.wm.open_mainfile(filepath=str(master_path))
    scene = bpy.context.scene
    arm = target_armature()
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH" and len(obj.vertex_groups)]
    if len(meshes) != 1:
        raise RuntimeError("TARGET_SKINNED_MESH_IDENTITY_INVALID")
    mesh = meshes[0]
    motion = json.loads(motion_path.read_text())
    if motion["target_rig"]["skeleton_signature_sha256"] != armature_signature(arm)["signature_sha256"]:
        raise RuntimeError("MOTION_TARGET_RIG_SIGNATURE_MISMATCH")
    arm.animation_data_clear()
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = mesh.evaluated_get(depsgraph)
    evaluated_mesh = evaluated.to_mesh()
    vertices = [mesh.matrix_world @ v.co for v in evaluated_mesh.vertices]
    evaluated.to_mesh_clear()
    low = [min(v[i] for v in vertices) for i in range(3)]
    high = [max(v[i] for v in vertices) for i in range(3)]
    raw_height = high[2] - low[2]
    scale = float(fixed_scale) if fixed_scale is not None else 85.0 / (raw_height * 50.0)
    center_x, center_y = (low[0] + high[0]) / 2, (low[1] + high[1]) / 2
    # Preserve each object's world transform while placing it under one fixed master-derived root.
    root = bpy.data.objects.new("NEUTRAL_IDLE_RENDER_ROOT", None)
    scene.collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    for obj in (arm, mesh):
        world = obj.matrix_world.copy()
        obj.parent = root
        obj.matrix_parent_inverse = Matrix.Identity(4)
        obj.matrix_world = world
    def place(value):
        root.scale = (value, value, value)
        root.location = (-center_x * value, -center_y * value, -low[2] * value)
        bpy.context.view_layer.update()
    place(scale)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.display.shading.light = "STUDIO"
    directions = {"N": 180, "NE": -135, "E": -90, "SE": -45, "S": 0, "SW": 45, "W": 90, "NW": 135}
    root_pixels = {}
    camera_data = bpy.data.cameras.new("NeutralIdleCamera")
    camera = bpy.data.objects.new("NeutralIdleCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 128 / 50
    camera_data.shift_y = (106 - 64) / 128
    light_data = bpy.data.lights.new("NeutralIdleKey", "AREA")
    light = bpy.data.objects.new("NeutralIdleKey", light_data)
    scene.collection.objects.link(light)
    light_data.energy = 800
    light_data.shape = "DISK"
    light_data.size = 5
    scene.render.resolution_x = scene.render.resolution_y = resolution
    out_dir.mkdir(parents=True, exist_ok=True)
    # Fit once from the experimental master rest pose in the canonical S view;
    # the resulting scale is fixed for every frame and direction.
    import numpy as np
    for pose_bone in arm.pose.bones:
        pose_bone.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    camera_angle = math.radians(directions["S"])
    camera_elevation = math.radians(45)
    camera.location = (10 * math.sin(camera_angle) * math.cos(camera_elevation),
                       -10 * math.cos(camera_angle) * math.cos(camera_elevation), 10 * math.sin(camera_elevation))
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    if fixed_scale is None:
        probe_path = out_dir / "_scale_probe.png"
        for _ in range(3):
            place(scale)
            scene.render.filepath = str(probe_path)
            bpy.ops.render.render(write_still=True)
            probe = bpy.data.images.load(str(probe_path), check_existing=False)
            pixels = np.empty(len(probe.pixels), dtype=np.float32)
            probe.pixels.foreach_get(pixels)
            alpha = pixels.reshape((resolution, resolution, 4))[:, :, 3]
            rows = np.where((alpha > (32 / 255)).any(axis=1))[0]
            bpy.data.images.remove(probe)
            if not len(rows):
                raise RuntimeError("REST_POSE_RENDER_EMPTY")
            measured_height = int(rows[-1] - rows[0] + 1)
            print(json.dumps({"scale_probe": scale, "measured_height": measured_height}))
            expected_height = 85 * resolution // 128
            if measured_height == expected_height:
                break
            scale *= expected_height / measured_height
    place(scale)
    frames = motion["frames"]
    last_duplicate = motion["loop"]["terminal_pose_duplicate"]
    if last_duplicate:
        frames = frames[:-1]
    if selected_frames:
        by_frame = {record["source_frame"]: record for record in frames}
        if len(selected_frames) != len(set(selected_frames)) or not set(selected_frames).issubset(by_frame):
            raise RuntimeError("REQUESTED_SAMPLE_FRAME_INVALID")
        frames = [by_frame[frame] for frame in selected_frames]
    elif sample_only:
        frames = [frames[index] for index in sorted(set((0, len(frames) // 2, len(frames) - 1)))]
    render_directions = directions if selected_directions is None else {
        direction: directions[direction] for direction in selected_directions
        if direction in directions
    }
    if not render_directions or (selected_directions and len(render_directions) != len(selected_directions)):
        raise RuntimeError("REQUESTED_RENDER_DIRECTION_INVALID")
    for direction, azimuth in render_directions.items():
        angle = math.radians(azimuth)
        elevation = math.radians(45)
        camera.location = (10 * math.sin(angle) * math.cos(elevation),
                           -10 * math.cos(angle) * math.cos(elevation), 10 * math.sin(elevation))
        camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
        from bpy_extras.object_utils import world_to_camera_view
        projected = world_to_camera_view(scene, camera, root.matrix_world.translation)
        root_pixels[direction] = [round(projected.x * resolution, 4), round((1 - projected.y) * resolution, 4)]
        light.location = (4 * math.sin(angle), -4 * math.cos(angle), 6)
        light.rotation_euler = (Vector((0, 0, 1)) - light.location).to_track_quat("-Z", "Y").to_euler()
        for record in frames:
            for pb_name, transform in record["bones"].items():
                pb = arm.pose.bones[pb_name]
                pb.location = transform["location"]
                pb.rotation_mode = "QUATERNION"
                pb.rotation_quaternion = blender_quaternion(transform["rotation_xyzw"])
                pb.scale = transform["scale"]
            bpy.context.view_layer.update()
            scene.render.filepath = str(out_dir / direction / (f"{record['source_frame']:04d}.png"))
            Path(scene.render.filepath).parent.mkdir(parents=True, exist_ok=True)
            bpy.ops.render.render(write_still=True)
    render_info = {"schema": "custodian.operator_neutral_idle_render_metadata.v1",
        "motion_sha256": motion.get("motion_sha256"), "master_sha256": sha_file(master_path),
        "fixed_scale": scale, "rest_bounds_m": {"low": low, "high": high},
        "camera": {"elevation_degrees": 45, "base_pixels_per_meter": 50,
                   "pixels_per_meter": 50 * resolution / 128,
                   "root_pixel": [64 * resolution / 128, 106 * resolution / 128],
                   "orthographic_scale": 128 / 50, "mirroring": False},
        "registered_root_pixels": root_pixels, "rendered_directions": list(directions),
        "sample_count": len(frames), "sample_only": sample_only,
        "resolution": [resolution, resolution], "rendered_directions": list(render_directions)}
    info_path = out_dir / "render_metadata.v1.json"
    info_path.write_bytes(canonical(render_info) + b"\n")
    print(json.dumps({"result": "rendered", "directions": list(directions), "sample_count": len(frames),
                      "fixed_scale": scale, "rest_bounds_m": {"low": low, "high": high},
                      "registered_root_pixels": root_pixels,
                      "camera": {"elevation_degrees": 45, "pixels_per_meter": 50, "root_pixel": [64, 106]},
                      "sample_only": sample_only}, sort_keys=True))


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    mode = args.pop(0)
    if mode == "retarget":
        master, fbx, output, policy, mapping_policy, reference = map(Path, args)
        retarget(master, fbx, output, policy, mapping_policy, reference)
    elif mode == "inventory":
        master, fbx, output = map(Path, args)
        inventory(master, fbx, output)
    elif mode == "render":
        master, motion, output = map(Path, args[:3])
        sample_arg = next((arg.partition("=")[2] for arg in args[3:] if arg.startswith("--sample-frames=")), "")
        selected_frames = [int(value) for value in sample_arg.split(",") if value] or None
        direction_arg = next((arg.partition("=")[2] for arg in args[3:] if arg.startswith("--directions=")), "")
        selected_directions = direction_arg.split(",") if direction_arg else None
        resolution_arg = next((arg.partition("=")[2] for arg in args[3:] if arg.startswith("--resolution=")), "128")
        scale_arg = next((arg.partition("=")[2] for arg in args[3:] if arg.startswith("--fixed-scale=")), "")
        render(master, motion, output, "--sample-only" in args[3:], selected_frames,
               selected_directions, int(resolution_arg), float(scale_arg) if scale_arg else None)
    else:
        raise RuntimeError("MODE_INVALID")


if __name__ == "__main__":
    main()
