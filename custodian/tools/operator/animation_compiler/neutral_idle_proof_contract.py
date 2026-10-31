"""Pure contract checks shared by the Blender adapter and focused tests."""
from __future__ import annotations

import math


def sampled_frames(start: int, end: int, duplicate_terminal: bool) -> list[int]:
    if start < 0 or end < start:
        raise ValueError("SOURCE_FRAME_RANGE_INVALID")
    result = list(range(start, end + 1))
    if duplicate_terminal and len(result) > 1:
        result.pop()
    return result


def validate_mapping(source_names: list[str], target_names: list[str], mapped: list[str],
                     inherited: list[str], unmapped_source: list[str], *,
                     allowed_inherited: list[str] | None = None,
                     allowed_unmapped_source: list[str] | None = None) -> None:
    source, target = set(source_names), set(target_names)
    direct, inherited_set, ignored = set(mapped), set(inherited), set(unmapped_source)
    if direct & inherited_set or direct & ignored or inherited_set & ignored:
        raise ValueError("SKELETON_MAPPING_OVERLAP")
    if direct != source & target or inherited_set != target - source or ignored != source - target:
        raise ValueError("SKELETON_MAPPING_PARTITION_INVALID")
    if len(direct) < 20:
        raise ValueError("SKELETON_MAPPING_INSUFFICIENT")
    if allowed_inherited is not None and inherited_set != set(allowed_inherited):
        raise ValueError("SKELETON_MAPPING_UNAPPROVED_TARGET_GAP")
    if allowed_unmapped_source is not None and ignored != set(allowed_unmapped_source):
        raise ValueError("SKELETON_MAPPING_UNAPPROVED_SOURCE_GAP")


def validate_motion(motion: dict) -> None:
    if motion.get("schema") != "custodian.operator_retargeted_motion.v1":
        raise ValueError("MOTION_SCHEMA_INVALID")
    source = motion.get("source", {})
    start, end = source.get("frame_start"), source.get("frame_end")
    if (not isinstance(start, int) or not isinstance(end, int) or end < start
            or source.get("frame_count") != end - start + 1
            or len(motion.get("frames", [])) != end - start + 1):
        raise ValueError("MOTION_AUTHORED_TIMING_MISMATCH")
    indices = [frame.get("source_frame") for frame in motion["frames"]]
    if indices != list(range(start, end + 1)):
        raise ValueError("MOTION_SOURCE_FRAME_SEQUENCE_INVALID")
    forbidden = {"master_sha256", "master_file_sha256", "mesh_sha256", "material_sha256", "texture_sha256", "camera_sha256"}
    def scan(value):
        if isinstance(value, dict):
            if forbidden & set(value):
                raise ValueError("MOTION_MODEL_DEPENDENCY_FORBIDDEN")
            for child in value.values():
                scan(child)
        elif isinstance(value, list):
            for child in value:
                scan(child)
    scan(motion)
    root = motion.get("root_motion", {})
    if (root.get("policy") != "extract_to_metadata" or root.get("sprite_pose_root_translation") != "removed"
            or root.get("godot_application") != "metadata_only_never_apply"):
        raise ValueError("ROOT_MOTION_DOUBLE_APPLICATION_RISK")
    target_bones = motion.get("target_rig", {}).get("bone_names", [])
    for frame in motion["frames"]:
        bones = frame.get("bones", {})
        if set(bones) != set(target_bones):
            raise ValueError("MOTION_TARGET_BONE_SET_MISMATCH")
        hips = bones.get("mixamorig:Hips", {})
        if any(abs(float(v)) > 1e-7 for v in hips.get("location", [])):
            raise ValueError("ROOT_MOTION_PRESENT_IN_SPRITE_POSE")
        for transform in bones.values():
            q = transform.get("rotation_xyzw", [])
            if len(q) != 4 or not all(math.isfinite(float(v)) for v in q):
                raise ValueError("MOTION_QUATERNION_INVALID")
            if abs(sum(float(v) ** 2 for v in q) - 1.0) > 1e-4:
                raise ValueError("MOTION_QUATERNION_NOT_NORMALIZED")


def blender_quaternion(xyzw: list[float]) -> tuple[float, float, float, float]:
    if len(xyzw) != 4:
        raise ValueError("MOTION_QUATERNION_INVALID")
    x, y, z, w = xyzw
    return (w, x, y, z)
