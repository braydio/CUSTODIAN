#!/usr/bin/env python3
"""Deterministic read-only planning and validation for Operator 3D animation candidates."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path, PurePosixPath
from typing import Any

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[3]
SCHEMA_DIR = HERE / "schemas"
BATCH_SCHEMA = json.loads((SCHEMA_DIR / "batch.v1.schema.json").read_text(encoding="utf-8"))
MASTER_SCHEMA = json.loads((SCHEMA_DIR / "master.v1.schema.json").read_text(encoding="utf-8"))
PROOF_SCHEMA = json.loads((SCHEMA_DIR / "inspection_proof.v1.schema.json").read_text(encoding="utf-8"))
PLAN_SCHEMA = json.loads((SCHEMA_DIR / "plan.v1.schema.json").read_text(encoding="utf-8"))
RECEIPT_SCHEMA = json.loads((SCHEMA_DIR / "candidate_receipt.v1.schema.json").read_text(encoding="utf-8"))
RUNTIME_AUTHORITY_SCHEMA = json.loads((SCHEMA_DIR / "runtime_timing_authority.v1.schema.json").read_text(encoding="utf-8"))
DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
EXIT_OK = 0
EXIT_INVALID = 2
EXIT_STALE = 3
EXIT_IO = 4
SHA_RE = re.compile(r"^[a-f0-9]{64}$")


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def digest_file(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            sha.update(block)
    return sha.hexdigest()


def _type_matches(value: Any, expected: str) -> bool:
    return {
        "object": lambda: isinstance(value, dict),
        "array": lambda: isinstance(value, list),
        "string": lambda: isinstance(value, str),
        "integer": lambda: isinstance(value, int) and not isinstance(value, bool),
        "number": lambda: isinstance(value, (int, float)) and not isinstance(value, bool),
        "boolean": lambda: isinstance(value, bool),
        "null": lambda: value is None,
    }[expected]()


def _resolve_ref(root_schema: dict[str, Any], ref: str) -> dict[str, Any]:
    if not ref.startswith("#/"):
        raise ValueError("unsupported schema reference")
    value: Any = root_schema
    for component in ref[2:].split("/"):
        value = value[component.replace("~1", "/").replace("~0", "~")]
    return value


def schema_findings(value: Any, schema: dict[str, Any], root_schema: dict[str, Any] | None = None,
                    path: str = "$") -> list[dict[str, str]]:
    """Validate the JSON Schema subset used here, without a third-party dependency."""
    root_schema = root_schema or schema
    if "$ref" in schema:
        return schema_findings(value, _resolve_ref(root_schema, schema["$ref"]), root_schema, path)
    findings: list[dict[str, str]] = []
    if "oneOf" in schema:
        branches = [schema_findings(value, item, root_schema, path) for item in schema["oneOf"]]
        if sum(not branch for branch in branches) != 1:
            findings.append({"code": "SCHEMA_ONE_OF", "path": path, "message": "value must match exactly one schema branch"})
        return findings
    if "const" in schema and value != schema["const"]:
        findings.append({"code": "SCHEMA_CONST", "path": path, "message": f"must equal {schema['const']!r}"})
    if "enum" in schema and value not in schema["enum"]:
        findings.append({"code": "SCHEMA_ENUM", "path": path, "message": "value is outside the declared enum"})
    expected = schema.get("type")
    if expected is not None:
        expected_types = expected if isinstance(expected, list) else [expected]
        if not any(_type_matches(value, kind) for kind in expected_types):
            findings.append({"code": "SCHEMA_TYPE", "path": path, "message": f"expected type {' or '.join(expected_types)}"})
            return findings
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            findings.append({"code": "SCHEMA_MIN_LENGTH", "path": path, "message": "string is shorter than minLength"})
        if "pattern" in schema and re.search(schema["pattern"], value) is None:
            findings.append({"code": "SCHEMA_PATTERN", "path": path, "message": "string does not match the declared pattern"})
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if not math.isfinite(float(value)):
            findings.append({"code": "SCHEMA_NUMBER_FINITE", "path": path, "message": "number must be finite"})
        if "minimum" in schema and value < schema["minimum"]:
            findings.append({"code": "SCHEMA_MINIMUM", "path": path, "message": "number is below minimum"})
        if "maximum" in schema and value > schema["maximum"]:
            findings.append({"code": "SCHEMA_MAXIMUM", "path": path, "message": "number is above maximum"})
    if isinstance(value, dict):
        for field in schema.get("required", []):
            if field not in value:
                findings.append({"code": "SCHEMA_REQUIRED", "path": f"{path}.{field}", "message": "required property is missing"})
        props = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            for field in sorted(set(value) - set(props)):
                findings.append({"code": "SCHEMA_ADDITIONAL_PROPERTY", "path": f"{path}.{field}", "message": "additional property is not allowed"})
        for field, child in props.items():
            if field in value:
                findings.extend(schema_findings(value[field], child, root_schema, f"{path}.{field}"))
    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            findings.append({"code": "SCHEMA_MIN_ITEMS", "path": path, "message": "array has fewer than minItems"})
        if schema.get("uniqueItems") and len({canonical_bytes(item) for item in value}) != len(value):
            findings.append({"code": "SCHEMA_UNIQUE_ITEMS", "path": path, "message": "array items must be unique"})
        if "items" in schema:
            for index, child_value in enumerate(value):
                findings.extend(schema_findings(child_value, schema["items"], root_schema, f"{path}[{index}]"))
    return findings


def read_json(path: Path, code: str) -> tuple[Any | None, list[dict[str, str]]]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), []
    except FileNotFoundError:
        return None, [{"code": code, "path": str(path), "message": "file does not exist"}]
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None, [{"code": "JSON_UNREADABLE", "path": str(path), "message": "file is not readable UTF-8 JSON"}]


def safe_relative(root: Path, relative: str | None) -> tuple[Path | None, str | None]:
    if (not isinstance(relative, str) or not relative or "\\" in relative or "\x00" in relative
            or re.match(r"^[A-Za-z]:", relative)):
        return None, "PATH_INVALID"
    posix = PurePosixPath(relative)
    if posix.is_absolute() or any(part in {"", ".", ".."} for part in posix.parts):
        return None, "PATH_TRAVERSAL"
    root_resolved = root.resolve()
    try:
        candidate = (root_resolved / Path(*posix.parts)).resolve(strict=False)
    except (OSError, RuntimeError):
        return None, "PATH_INVALID"
    try:
        candidate.relative_to(root_resolved)
    except ValueError:
        return None, "PATH_TRAVERSAL"
    return candidate, None


def _record_dependency(dependencies: list[dict[str, Any]], *, label: str, root: Path,
                       relative: str | None, expected: str | None, code_prefix: str,
                       errors: list[dict[str, str]], require_file: bool = True) -> tuple[Path | None, str | None]:
    path, path_error = safe_relative(root, relative)
    if path_error:
        errors.append({"code": path_error, "path": label, "message": "dependency path must be confined, relative, and traversal-free"})
        dependencies.append({"id": label, "path": relative, "expected_sha256": expected, "observed_sha256": None, "state": "invalid_path"})
        return None, None
    if path is None or not path.is_file():
        dependencies.append({"id": label, "path": relative, "expected_sha256": expected, "observed_sha256": None, "state": "missing"})
        if require_file:
            errors.append({"code": f"{code_prefix}_MISSING", "path": label, "message": "declared dependency is unavailable"})
        return path, None
    actual = digest_file(path)
    dependencies.append({"id": label, "path": relative, "expected_sha256": expected, "observed_sha256": actual, "state": "present"})
    if expected is None or not SHA_RE.fullmatch(str(expected)):
        errors.append({"code": f"{code_prefix}_HASH_MISSING", "path": label, "message": "dependency must declare a valid SHA-256"})
    elif actual != expected:
        errors.append({"code": f"{code_prefix}_HASH_MISMATCH", "path": label, "message": "dependency bytes do not match the declared SHA-256"})
    return path, actual


def _schema_report(manifest: Any) -> list[dict[str, str]]:
    return schema_findings(manifest, BATCH_SCHEMA)


def _master_report(manifest: Any, asset_root: Path, repo_root: Path,
                   dependencies: list[dict[str, Any]], errors: list[dict[str, str]],
                   warnings: list[dict[str, str]]) -> dict[str, Any] | None:
    ref = manifest["master_reference"]
    if ref["availability"] != "available":
        dependencies.append({"id": "master_contract", "path": ref.get("contract_path"), "expected_sha256": ref.get("contract_sha256"), "observed_sha256": None, "state": "unavailable"})
        if any(ref.get(field) is not None for field in ("master_id", "contract_path", "contract_sha256")):
            errors.append({"code": "MASTER_AVAILABILITY_MISMATCH", "path": "$.master_reference", "message": "unavailable master must not claim an identity, path, or hash"})
        errors.append({"code": "MASTER_UNAVAILABLE", "path": "$.master_reference", "message": "a content-addressed master contract is required"})
        return None
    master_path, _ = _record_dependency(dependencies, label="master_contract", root=asset_root,
        relative=ref["contract_path"], expected=ref["contract_sha256"], code_prefix="MASTER_CONTRACT",
        errors=errors)
    if master_path is None or not master_path.is_file():
        return None
    master, parse_errors = read_json(master_path, "MASTER_CONTRACT_MISSING")
    errors.extend(parse_errors)
    if master is None:
        return None
    master_errors = schema_findings(master, MASTER_SCHEMA)
    for finding in master_errors:
        errors.append({"code": "MASTER_" + finding["code"], "path": finding["path"], "message": finding["message"]})
    if master_errors:
        return None
    if master["master_id"] != ref["master_id"]:
        errors.append({"code": "MASTER_ID_MISMATCH", "path": "$.master_reference.master_id", "message": "master id does not match the referenced contract"})
    if master["approval_state"] == "experimental":
        warnings.append({"code": "MASTER_EXPERIMENTAL", "path": "$.master_reference", "message": "experimental master can produce candidates but is not production-approved"})
    blender = master["blender"]
    _record_dependency(dependencies, label="master_blender_project", root=asset_root,
        relative=blender["project_path"], expected=blender["project_sha256"], code_prefix="MASTER_MODEL", errors=errors)
    retarget = master["retarget_policy"]
    _record_dependency(dependencies, label="master_retarget_config", root=asset_root,
        relative=retarget["config_path"], expected=retarget["config_sha256"], code_prefix="MASTER_RETARGET_CONFIG", errors=errors)
    for i, texture in enumerate(master["textures"]):
        _record_dependency(dependencies, label=f"master_texture_{i:03d}", root=asset_root,
            relative=texture["path"], expected=texture["sha256"], code_prefix="MASTER_TEXTURE", errors=errors)
    batch_policy = manifest["retarget_policy"]
    if (retarget["policy_id"], retarget["version"]) != (batch_policy["policy_id"], batch_policy["version"]):
        errors.append({"code": "RETARGET_POLICY_MISMATCH", "path": "$.retarget_policy", "message": "batch and master retarget policy identity/version differ"})
    if retarget["config_sha256"] != batch_policy["config_sha256"]:
        errors.append({"code": "RETARGET_CONFIG_MISMATCH", "path": "$.retarget_policy.config_sha256", "message": "master and batch retarget configuration hashes differ"})
    if master["camera_registration"]["profile_sha256"] != manifest["rendering_contract"]["profile_sha256"]:
        errors.append({"code": "RENDER_PROFILE_MISMATCH", "path": "$.rendering_contract.profile_sha256", "message": "master and batch rendering profile hashes differ"})
    return master


def _proof_report(animation: dict[str, Any], index: int, manifest: dict[str, Any], master: dict[str, Any] | None,
                  asset_root: Path, dependencies: list[dict[str, Any]], errors: list[dict[str, str]],
                  allow_test_fixtures: bool) -> None:
    prefix = f"$.animations[{index}]"
    source = animation["source"]
    if source["availability"] != "available":
        dependencies.append({"id": f"source_{animation['animation_id']}", "path": source.get("relative_path"), "expected_sha256": source.get("sha256"), "observed_sha256": None, "state": "unavailable"})
        if any(source.get(field) is not None for field in ("original_filename", "relative_path", "sha256", "import_metadata")):
            errors.append({"code": "SOURCE_AVAILABILITY_MISMATCH", "path": prefix + ".source", "message": "unavailable source must not claim a filename, path, hash, or import metadata"})
        errors.append({"code": "SOURCE_UNAVAILABLE", "path": prefix + ".source", "message": "source FBX is explicitly unavailable"})
        return
    if not source.get("original_filename") or Path(source["original_filename"]).name != source["original_filename"]:
        errors.append({"code": "SOURCE_FILENAME_INVALID", "path": prefix + ".source.original_filename", "message": "original filename must be a basename"})
    if not str(source.get("original_filename", "")).lower().endswith(".fbx"):
        errors.append({"code": "SOURCE_NOT_FBX", "path": prefix + ".source.original_filename", "message": "source filename must have an .fbx extension"})
    source_path, source_hash = _record_dependency(dependencies, label=f"source_{animation['animation_id']}", root=asset_root,
        relative=source["relative_path"], expected=source["sha256"], code_prefix="SOURCE", errors=errors)
    if source_path is not None and source_path.is_file() and source_path.name != source["original_filename"]:
        errors.append({"code": "SOURCE_FILENAME_PATH_MISMATCH", "path": prefix + ".source.relative_path", "message": "original filename must match the final path component"})
    if source["import_metadata"] is None:
        errors.append({"code": "IMPORT_METADATA_MISSING", "path": prefix + ".source.import_metadata", "message": "available FBX requires explicit importer and settings hash"})
    action = animation["source_action"]
    proof_path, _ = _record_dependency(dependencies, label=f"inspection_{animation['animation_id']}", root=asset_root,
        relative=action.get("inspection_proof_path"), expected=action.get("inspection_proof_sha256"),
        code_prefix="INSPECTION_PROOF", errors=errors)
    if proof_path is None or not proof_path.is_file() or source_hash is None:
        return
    proof, parse_errors = read_json(proof_path, "INSPECTION_PROOF_MISSING")
    errors.extend(parse_errors)
    if not isinstance(proof, dict):
        return
    for finding in schema_findings(proof, PROOF_SCHEMA):
        errors.append({"code": "PROOF_" + finding["code"], "path": finding["path"], "message": finding["message"]})
    expected_proof_id = animation["source_skeleton"].get("compatibility_proof_id")
    if proof.get("proof_id") != expected_proof_id:
        errors.append({"code": "COMPATIBILITY_PROOF_ID_MISMATCH", "path": prefix + ".source_skeleton.compatibility_proof_id", "message": "proof id does not match the declared compatibility proof"})
    kind = proof.get("evidence_kind")
    if kind != "blender_inspector" and not (kind == "synthetic_test" and allow_test_fixtures):
        errors.append({"code": "INSPECTION_PROOF_NOT_AUTHORITATIVE", "path": prefix + ".source_action.inspection_proof_path", "message": "compatibility evidence must come from the declared Blender inspector"})
    expected_master_id = manifest["master_reference"].get("master_id")
    expected_master_sha = manifest["master_reference"].get("contract_sha256")
    import_metadata = source.get("import_metadata") or {}
    master_blender_sha = master.get("blender", {}).get("project_sha256") if master else None
    master_armature = master.get("armature", {}) if master else {}
    mesh_materials_sha = digest_bytes(canonical_bytes(master.get("mesh_materials"))) if master else None
    expected = {
        "source_sha256": source_hash,
        "source_importer": import_metadata.get("importer"),
        "source_importer_version": import_metadata.get("importer_version"),
        "source_import_settings_sha256": import_metadata.get("settings_sha256"),
        "master_id": expected_master_id,
        "master_contract_sha256": expected_master_sha,
        "master_blender_project_sha256": master_blender_sha,
        "master_armature_identity_sha256": master_armature.get("identity_sha256"),
        "master_rest_pose_sha256": master_armature.get("rest_pose_sha256"),
        "master_skeleton_signature_sha256": master_armature.get("skeleton_signature_sha256"),
        "master_mesh_materials_sha256": mesh_materials_sha,
        "action_identity": action.get("identity"),
        "skeleton_identity": animation["source_skeleton"].get("identity"),
        "skeleton_signature_sha256": animation["source_skeleton"].get("signature_sha256"),
        "retarget_policy_id": manifest["retarget_policy"]["policy_id"],
        "retarget_policy_version": manifest["retarget_policy"]["version"],
        "retarget_config_sha256": manifest["retarget_policy"]["config_sha256"],
        "root_motion_state": animation["root_motion"]["source_state"],
        "source_trajectory_sha256": animation["root_motion"]["source_trajectory_sha256"],
    }
    proof_actual = {
        "source_sha256": proof.get("source", {}).get("sha256"),
        "source_importer": proof.get("source", {}).get("importer"),
        "source_importer_version": proof.get("source", {}).get("importer_version"),
        "source_import_settings_sha256": proof.get("source", {}).get("import_settings_sha256"),
        "master_id": proof.get("master", {}).get("master_id"),
        "master_contract_sha256": proof.get("master", {}).get("contract_sha256"),
        "master_blender_project_sha256": proof.get("master", {}).get("blender_project_sha256"),
        "master_armature_identity_sha256": proof.get("master", {}).get("armature_identity_sha256"),
        "master_rest_pose_sha256": proof.get("master", {}).get("rest_pose_sha256"),
        "master_skeleton_signature_sha256": proof.get("master", {}).get("skeleton_signature_sha256"),
        "master_mesh_materials_sha256": proof.get("master", {}).get("mesh_materials_sha256"),
        "action_identity": proof.get("action", {}).get("identity"),
        "skeleton_identity": proof.get("skeleton", {}).get("identity"),
        "skeleton_signature_sha256": proof.get("skeleton", {}).get("signature_sha256"),
        "retarget_policy_id": proof.get("retarget_policy", {}).get("policy_id"),
        "retarget_policy_version": proof.get("retarget_policy", {}).get("version"),
        "retarget_config_sha256": proof.get("retarget_policy", {}).get("config_sha256"),
        "root_motion_state": proof.get("root_motion", {}).get("source_state"),
        "source_trajectory_sha256": proof.get("root_motion", {}).get("trajectory_sha256"),
    }
    for field, expected_value in expected.items():
        if proof_actual[field] != expected_value:
            errors.append({"code": "INSPECTION_PROOF_BINDING_MISMATCH", "path": prefix + ".source_action.inspection_proof_path", "message": f"inspection proof {field} does not match the manifest"})
    if proof.get("compatibility", {}).get("result") != "compatible":
        errors.append({"code": "SKELETON_INCOMPATIBLE", "path": prefix + ".source_skeleton", "message": "inspection proof does not establish compatible source and target skeletons"})
    if master is not None and proof.get("compatibility", {}).get("target_skeleton_signature_sha256") != master["armature"]["skeleton_signature_sha256"]:
        errors.append({"code": "TARGET_SKELETON_MISMATCH", "path": prefix + ".source_skeleton", "message": "proof target skeleton does not match the current master rest rig"})
    timing = animation["authored_timing"]
    proof_timing = proof.get("action", {})
    for field in ("fps", "frame_start", "frame_end", "duration_seconds"):
        if timing.get(field) != proof_timing.get(field):
            errors.append({"code": "AUTHORED_TIMING_PROOF_MISMATCH", "path": prefix + ".authored_timing." + field, "message": "declared source timing differs from the inspection proof"})
    if action.get("identity") != proof_timing.get("identity"):
        errors.append({"code": "ACTION_IDENTITY_MISMATCH", "path": prefix + ".source_action.identity", "message": "declared action identity differs from the inspected action"})
    endpoint_policy = animation["sampling"]["loop_endpoint_policy"]
    if animation["playback"]["classification"] == "one_shot" and endpoint_policy == "omit_declared_duplicate_terminal":
        errors.append({"code": "LOOP_ENDPOINT_POLICY_INVALID", "path": prefix + ".sampling.loop_endpoint_policy", "message": "one-shot actions must preserve their authored terminal frame"})
    elif (animation["playback"]["classification"] == "loop"
          and endpoint_policy == "omit_declared_duplicate_terminal"
          and proof_timing.get("loop_endpoint_duplicate") is not True):
        errors.append({"code": "LOOP_ENDPOINT_NOT_PROVEN_DUPLICATE", "path": prefix + ".sampling.loop_endpoint_policy", "message": "terminal frame may be omitted only when inspection proves it duplicates the loop start"})


def _validate_root_policy(animation: dict[str, Any], index: int, errors: list[dict[str, str]]) -> None:
    motion = animation["root_motion"]
    expected = {
        "preserve_world_displacement": ("retained", "pose_only"),
        "extract_to_metadata": ("removed", "trajectory_once_separately"),
        "in_place": ("removed", "pose_only"),
    }
    pose, godot = expected[motion["policy"]]
    if motion["pose_root_translation"] != pose or motion["godot_application"] != godot:
        errors.append({"code": "ROOT_MOTION_DOUBLE_APPLICATION_RISK", "path": f"$.animations[{index}].root_motion", "message": "root-motion policy, sprite pose and Godot application are inconsistent"})
    if motion["source_state"] == "unknown":
        errors.append({"code": "ROOT_MOTION_STATE_UNKNOWN", "path": f"$.animations[{index}].root_motion.source_state", "message": "source root-motion state must be inspected before validation"})
    if motion["source_state"] == "present" and not SHA_RE.fullmatch(str(motion["source_trajectory_sha256"])):
        errors.append({"code": "ROOT_TRAJECTORY_HASH_MISSING", "path": f"$.animations[{index}].root_motion.source_trajectory_sha256", "message": "present source displacement requires a hash-bound original trajectory"})
    if motion["source_state"] == "absent" and motion["source_trajectory_sha256"] is not None:
        errors.append({"code": "ROOT_TRAJECTORY_AVAILABILITY_MISMATCH", "path": f"$.animations[{index}].root_motion.source_trajectory_sha256", "message": "absent source displacement cannot declare a trajectory hash"})
    if motion["policy"] == "extract_to_metadata" and motion["source_state"] == "absent":
        errors.append({"code": "ROOT_MOTION_POLICY_INAPPLICABLE", "path": f"$.animations[{index}].root_motion.policy", "message": "cannot extract a trajectory when source root motion is absent"})


def _validate_batch(manifest: dict[str, Any], asset_root: Path, repo_root: Path,
                    *, allow_test_fixtures: bool = False, candidate_only: bool = False) -> dict[str, Any]:
    errors = _schema_report(manifest)
    if errors:
        return {"valid": False, "errors": errors, "warnings": [], "dependencies": []}
    errors = []
    warnings: list[dict[str, str]] = []
    dependencies: list[dict[str, Any]] = []
    master = _master_report(manifest, asset_root, repo_root, dependencies, errors, warnings)
    render = manifest["rendering_contract"]
    contract_path, contract_hash = _record_dependency(dependencies, label="rendering_contract", root=repo_root,
        relative=render["contract_path"], expected=render["contract_sha256"], code_prefix="RENDER_CONTRACT", errors=errors)
    if contract_hash is not None:
        if render["profile_sha256"] != contract_hash:
            errors.append({"code": "RENDER_PROFILE_HASH_MISMATCH", "path": "$.rendering_contract.profile_sha256", "message": "profile hash must equal the rendering contract file SHA-256"})
        if contract_path is not None:
            contract, parse_errors = read_json(contract_path, "RENDER_CONTRACT_MISSING")
            errors.extend(parse_errors)
            if isinstance(contract, dict):
                projection = {
                    "contract_id": contract.get("contract_id"),
                    "directions": contract.get("directions"),
                    "width": contract.get("frame", {}).get("width"),
                    "height": contract.get("frame", {}).get("height"),
                    "channels": contract.get("frame", {}).get("channels"),
                    "elevation_degrees": contract.get("camera", {}).get("elevation_degrees"),
                    "pixels_per_meter": contract.get("camera", {}).get("pixels_per_meter"),
                    "root_pixel": contract.get("registration", {}).get("root_pixel"),
                    "scale_policy": contract.get("registration", {}).get("scale_policy"),
                    "registration_policy": contract.get("registration", {}).get("registration_policy"),
                    "mirroring": contract.get("direction_policy", {}).get("mirroring"),
                    "diagnostic_size_px": contract.get("diagnostic_size_px"),
                    "candidate_state": contract.get("approval_state"),
                }
                for field, actual in projection.items():
                    if render.get(field) != actual:
                        errors.append({"code": "RENDER_CONTRACT_FIELD_MISMATCH", "path": "$.rendering_contract." + field, "message": "declared rendering contract field differs from the pinned contract file"})
                if contract.get("body_policy") != "full_body_only" or contract.get("direction_policy", {}).get("independent_renders") is not True:
                    errors.append({"code": "RENDER_CONTRACT_POLICY_INVALID", "path": "$.rendering_contract", "message": "render contract must declare full-body independent directional renders"})
                if render["diagnostic_size_px"] is not None and render["diagnostic_size_px"] not in contract.get("diagnostic_size_options_px", []):
                    errors.append({"code": "DIAGNOSTIC_SIZE_UNSUPPORTED", "path": "$.rendering_contract.diagnostic_size_px", "message": "requested diagnostic size is not supported by the pinned rendering contract"})
    policy = manifest["retarget_policy"]
    policy_path, policy_hash = _record_dependency(dependencies, label="batch_retarget_policy", root=repo_root,
        relative=policy["config_path"], expected=policy["config_sha256"], code_prefix="RETARGET_POLICY", errors=errors)
    if policy_path is not None and policy_path.is_file():
        policy_doc, parse_errors = read_json(policy_path, "RETARGET_POLICY_UNREADABLE")
        errors.extend(parse_errors)
        if isinstance(policy_doc, dict) and (policy_doc.get("policy_id"), policy_doc.get("version")) != (policy["policy_id"], policy["version"]):
            errors.append({"code": "RETARGET_POLICY_IDENTITY_MISMATCH", "path": "$.retarget_policy", "message": "retarget policy id/version differs from the pinned policy document"})
    semantic_ids: dict[tuple[str, str, str], int] = {}
    animation_ids: dict[str, int] = {}
    output_paths: dict[str, str] = {}
    for i, animation in enumerate(manifest["animations"]):
        animation_id = animation["animation_id"]
        if animation_id in animation_ids:
            errors.append({"code": "DUPLICATE_ANIMATION_ID", "path": f"$.animations[{i}].animation_id", "message": f"animation id duplicates animations[{animation_ids[animation_id]}]"})
        else:
            animation_ids[animation_id] = i
        semantic = animation["semantic"]
        is_reaction = semantic["group"] == "reaction"
        impact = animation["playback"]["character_local_impact_direction"]
        if is_reaction and impact is None:
            errors.append({"code": "REACTION_IMPACT_DIRECTION_MISSING", "path": f"$.animations[{i}].playback.character_local_impact_direction", "message": "reaction semantics require character-local impact direction"})
        if not is_reaction and impact is not None:
            errors.append({"code": "REACTION_IMPACT_DIRECTION_UNEXPECTED", "path": f"$.animations[{i}].playback.character_local_impact_direction", "message": "character-local impact direction is only valid for reaction semantics"})
        identity = (semantic["profile"], semantic["group"], semantic["action"])
        if identity in semantic_ids:
            errors.append({"code": "DUPLICATE_SEMANTIC_OUTPUT", "path": f"$.animations[{i}].semantic", "message": f"semantic output identity duplicates animations[{semantic_ids[identity]}]"})
        else:
            semantic_ids[identity] = i
        output_subpath, path_error = safe_relative(Path("/candidate-root"), animation["output_path"])
        if path_error or output_subpath is None:
            errors.append({"code": path_error or "PATH_INVALID", "path": f"$.animations[{i}].output_path", "message": "output path must be confined, relative, and traversal-free"})
        output_root_path, output_root_error = safe_relative(Path("/candidate-root"), manifest["output_root"])
        if output_root_error or output_root_path is None:
            errors.append({"code": output_root_error or "PATH_INVALID", "path": "$.output_root", "message": "output root must be confined, relative, and traversal-free"})
        root_key = output_root_path.relative_to(Path("/candidate-root")).as_posix() if output_root_path else manifest["output_root"]
        subpath_key = output_subpath.relative_to(Path("/candidate-root")).as_posix() if output_subpath else animation["output_path"]
        path = "/".join((root_key, subpath_key))
        if path in output_paths:
            errors.append({"code": "OUTPUT_PATH_COLLISION", "path": f"$.animations[{i}].semantic", "message": f"candidate output path collides with animation {output_paths[path]}"})
        else:
            output_paths[path] = animation["animation_id"]
        _validate_root_policy(animation, i, errors)
        contact = animation["foot_contact"]
        if contact["policy"] == "not_assessed":
            if contact["evidence_path"] is not None or contact["evidence_sha256"] is not None:
                errors.append({"code": "FOOT_CONTACT_AVAILABILITY_MISMATCH", "path": f"$.animations[{i}].foot_contact", "message": "not_assessed contact policy cannot claim evidence"})
        elif contact["evidence_path"] is None or contact["evidence_sha256"] is None:
            errors.append({"code": "FOOT_CONTACT_EVIDENCE_MISSING", "path": f"$.animations[{i}].foot_contact", "message": "declared contact policy requires hash-bound evidence"})
        else:
            _record_dependency(dependencies, label=f"foot_contact_{animation['animation_id']}", root=asset_root,
                relative=contact["evidence_path"], expected=contact["evidence_sha256"], code_prefix="FOOT_CONTACT_EVIDENCE", errors=errors)
        timing = animation["authored_timing"]
        if timing["availability"] == "available":
            if timing["fps"] is None or not math.isfinite(float(timing["fps"])) or timing["fps"] <= 0:
                errors.append({"code": "SOURCE_FPS_INVALID", "path": f"$.animations[{i}].authored_timing.fps", "message": "available source timing requires finite positive FPS"})
            if timing["frame_start"] is None or timing["frame_end"] is None or timing["frame_end"] < timing["frame_start"]:
                errors.append({"code": "SOURCE_FRAME_RANGE_INVALID", "path": f"$.animations[{i}].authored_timing", "message": "available timing requires an ordered inclusive keyframe range"})
            if timing["duration_seconds"] is None or timing["duration_seconds"] <= 0:
                errors.append({"code": "SOURCE_DURATION_INVALID", "path": f"$.animations[{i}].authored_timing.duration_seconds", "message": "available source timing requires positive authored duration"})
        elif any(timing[field] is not None for field in ("duration_seconds", "fps", "frame_start", "frame_end")):
            errors.append({"code": "SOURCE_TIMING_AVAILABILITY_MISMATCH", "path": f"$.animations[{i}].authored_timing", "message": "unavailable timing must not contain inferred values"})
        runtime = animation["runtime_timing_authority"]
        if runtime["status"] != "approved":
            if any(runtime.get(field) is not None for field in ("authority_id", "authority_path", "authority_sha256", "fps", "loop")):
                errors.append({"code": "RUNTIME_TIMING_AVAILABILITY_MISMATCH", "path": f"$.animations[{i}].runtime_timing_authority", "message": "unavailable runtime authority must not contain inferred timing values"})
            if not candidate_only:
                errors.append({"code": "RUNTIME_TIMING_AUTHORITY_MISSING", "path": f"$.animations[{i}].runtime_timing_authority", "message": "FBX timing is not runtime timing; an explicit authority record is required to validate for production use"})
        elif (not runtime["authority_id"] or not runtime["authority_path"] or not runtime["authority_sha256"] or runtime["fps"] is None or runtime["fps"] <= 0 or runtime["loop"] is None):
            errors.append({"code": "RUNTIME_TIMING_AUTHORITY_INVALID", "path": f"$.animations[{i}].runtime_timing_authority", "message": "approved runtime timing must bind an authority ID/path/hash, FPS and loop choice"})
        else:
            authority_path, _ = _record_dependency(dependencies, label=f"runtime_timing_{animation['animation_id']}", root=asset_root,
                relative=runtime["authority_path"], expected=runtime["authority_sha256"], code_prefix="RUNTIME_TIMING_AUTHORITY", errors=errors)
            if authority_path is not None and authority_path.is_file():
                authority, authority_errors = read_json(authority_path, "RUNTIME_TIMING_AUTHORITY_MISSING")
                errors.extend(authority_errors)
                if isinstance(authority, dict):
                    for finding in schema_findings(authority, RUNTIME_AUTHORITY_SCHEMA):
                        errors.append({"code": "RUNTIME_AUTHORITY_" + finding["code"], "path": finding["path"], "message": finding["message"]})
                expected_semantic = animation["semantic"]
                if isinstance(authority, dict) and (
                    authority.get("schema") != "custodian.operator_runtime_timing_authority.v1"
                    or authority.get("authority_id") != runtime["authority_id"]
                    or authority.get("semantic") != {k: expected_semantic[k] for k in ("profile", "group", "action")}
                    or authority.get("source_sha256") != animation["source"]["sha256"]
                    or authority.get("master_contract_sha256") != manifest["master_reference"]["contract_sha256"]
                    or authority.get("fps") != runtime["fps"]
                    or authority.get("loop") != runtime["loop"]
                ):
                    errors.append({"code": "RUNTIME_TIMING_AUTHORITY_BINDING_MISMATCH", "path": f"$.animations[{i}].runtime_timing_authority", "message": "timing authority record differs from the declared semantic/FPS/loop values"})
        _proof_report(animation, i, manifest, master, asset_root, dependencies, errors, allow_test_fixtures)
    for error in errors:
        error["_sort"] = error["code"] + "\0" + error["path"] + "\0" + error["message"]
    errors.sort(key=lambda x: x.pop("_sort"))
    warnings.sort(key=lambda x: (x["code"], x["path"], x["message"]))
    dependencies.sort(key=lambda x: (x["id"], x.get("path") or ""))
    return {"valid": not errors, "errors": errors, "warnings": warnings, "dependencies": dependencies}


def _job_id(animation: dict[str, Any], manifest: dict[str, Any]) -> str:
    identity = {
        "animation": animation,
        "master_reference": manifest["master_reference"],
        "retarget_policy": manifest["retarget_policy"],
        "rendering_contract": manifest["rendering_contract"],
    }
    return "op3d-" + digest_bytes(canonical_bytes(identity))[:24]


def _sample_indices(animation: dict[str, Any]) -> list[int] | None:
    timing = animation["authored_timing"]
    if timing["availability"] != "available" or timing["frame_start"] is None or timing["frame_end"] is None:
        return None
    start, end = int(timing["frame_start"]), int(timing["frame_end"])
    indices = list(range(start, end + 1, int(animation["sampling"]["stride"])))
    if (animation["playback"]["classification"] == "loop"
            and animation["sampling"]["loop_endpoint_policy"] == "omit_declared_duplicate_terminal"
            and indices and indices[-1] == end):
        indices.pop()
    return indices


def _sample_count(animation: dict[str, Any]) -> int | None:
    indices = _sample_indices(animation)
    return None if indices is None else len(indices)


def _build_plan(manifest: dict[str, Any], manifest_path: Path, asset_root: Path,
                repo_root: Path, *, candidate_only: bool = False) -> dict[str, Any]:
    report = _validate_batch(manifest, asset_root, repo_root, candidate_only=candidate_only)
    manifest_sha = digest_file(manifest_path)
    jobs = []
    total_frames = 0
    frames_known = True
    total_renders = 0
    total_pixels = 0
    for animation in manifest["animations"]:
        frames = _sample_count(animation)
        renders = None if frames is None else frames * len(DIRECTIONS)
        pixels = None if renders is None else renders * manifest["rendering_contract"]["width"] * manifest["rendering_contract"]["height"]
        if manifest["rendering_contract"]["diagnostic_size_px"]:
            pixels = None if pixels is None else pixels + renders * manifest["rendering_contract"]["diagnostic_size_px"] ** 2
        if frames is None:
            frames_known = False
        else:
            total_frames += frames
            total_renders += renders or 0
            total_pixels += pixels or 0
        jobs.append({
            "job_id": _job_id(animation, manifest),
            "animation_id": animation["animation_id"],
            "semantic_output": animation["semantic"],
            "output_path": PurePosixPath(manifest["output_root"], animation["output_path"]).as_posix(),
            "source_state": animation["source"]["availability"],
            "master_state": manifest["master_reference"]["availability"],
            "sampled_frames_per_direction": frames,
            "direction_count": len(DIRECTIONS),
            "directional_frame_renders": renders,
            "output_dimensions": [manifest["rendering_contract"]["width"], manifest["rendering_contract"]["height"], manifest["rendering_contract"]["channels"]],
            "diagnostic_dimensions": ([manifest["rendering_contract"]["diagnostic_size_px"]] * 2 if manifest["rendering_contract"]["diagnostic_size_px"] else None),
            "estimated_pixel_work": pixels,
            "status": "blocked_by_declared_inputs" if not report["valid"] else "candidate_plan_only",
            "execution_nodes": [
                {"id": "verify_inputs", "depends_on": []},
                {"id": "inspect_compatibility", "depends_on": ["verify_inputs"]},
                {"id": "retarget_and_sample", "depends_on": ["inspect_compatibility"]},
                {"id": "render_eight_views", "depends_on": ["retarget_and_sample"]},
                {"id": "technical_qa_and_review_package", "depends_on": ["render_eight_views"]},
            ],
        })
    dependency_state = [{"id": d["id"], "path": d.get("path"), "expected_sha256": d.get("expected_sha256"),
                        "observed_sha256": d.get("observed_sha256"), "state": d["state"]}
                       for d in report["dependencies"]]
    plan_id = digest_bytes(canonical_bytes({"manifest_sha256": manifest_sha, "dependencies": dependency_state}))
    return {
        "schema": "custodian.operator_3d_animation_plan.v1",
        "command": "plan",
        "plan_id": plan_id,
        "batch_id": manifest["batch_id"],
        "input_manifest_sha256": manifest_sha,
        "master_reference": manifest["master_reference"],
        "retarget_policy": manifest["retarget_policy"],
        "rendering_contract": manifest["rendering_contract"],
        "candidate_state": "candidate_unapproved",
        "validation": report,
        "estimate": {
            "animation_count": len(jobs),
            "sampled_frames_total": total_frames if frames_known else None,
            "directional_frame_renders_total": total_renders if frames_known else None,
            "estimated_pixel_work_total": total_pixels if frames_known else None,
            "estimated_work_state": "known_from_declared_ranges" if frames_known else "incomplete_source_timing",
            "directions": list(DIRECTIONS),
            "full_body_only": True,
            "expected_frame_dimensions": [128, 128, "RGBA"],
        },
        "jobs": jobs,
    }


def _load_manifest(path: Path) -> tuple[dict[str, Any] | None, list[dict[str, str]]]:
    document, errors = read_json(path, "MANIFEST_MISSING")
    if errors:
        return None, errors
    findings = _schema_report(document)
    return (document if not findings else None), findings


def command_validate(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    manifest_path = args.manifest.resolve()
    manifest, errors = _load_manifest(manifest_path)
    if errors:
        return ({"schema": "custodian.operator_3d_animation_validation.v1", "command": "validate", "valid": False, "errors": errors, "warnings": [], "dependencies": []}, EXIT_INVALID)
    report = _validate_batch(manifest, Path(args.asset_root or manifest_path.parent), Path(args.repo_root or REPO_ROOT), candidate_only=getattr(args, "candidate_only", False))
    return ({"schema": "custodian.operator_3d_animation_validation.v1", "command": "validate", **report}, EXIT_OK if report["valid"] else EXIT_INVALID)


def command_plan(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    manifest_path = args.manifest.resolve()
    manifest, errors = _load_manifest(manifest_path)
    if errors:
        return ({"schema": "custodian.operator_3d_animation_plan.v1", "command": "plan", "valid": False, "errors": errors}, EXIT_INVALID)
    plan = _build_plan(manifest, manifest_path, Path(args.asset_root or manifest_path.parent), Path(args.repo_root or REPO_ROOT), candidate_only=getattr(args, "candidate_only", False))
    plan_errors = schema_findings(plan, PLAN_SCHEMA)
    if plan_errors:
        return ({"schema": "custodian.operator_3d_animation_plan.v1", "command": "plan", "valid": False, "errors": plan_errors}, EXIT_IO)
    return plan, EXIT_OK


def _check_candidate_receipt(receipt: dict[str, Any], manifest: dict[str, Any], manifest_path: Path,
                             asset_root: Path, repo_root: Path, *, candidate_only: bool = False) -> tuple[dict[str, Any], int]:
    findings = schema_findings(receipt, RECEIPT_SCHEMA)
    if findings:
        return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": True,
                 "errors": findings}, EXIT_INVALID)
    current = _build_plan(manifest, manifest_path, asset_root, repo_root, candidate_only=candidate_only)
    changes: list[dict[str, str]] = []

    def changed(code: str, path: str, message: str) -> None:
        changes.append({"code": code, "path": path, "message": message})

    actual_manifest_sha = current["input_manifest_sha256"]
    if receipt["batch_id"] != manifest["batch_id"]:
        changed("RECEIPT_BATCH_MISMATCH", "$.batch_id", "candidate receipt belongs to a different batch")
    if receipt["input_manifest_sha256"] != actual_manifest_sha:
        changed("MANIFEST_CHANGED", str(manifest_path), "manifest bytes changed since the candidate was created")
    if receipt["plan_id"] != current["plan_id"]:
        changed("PLAN_CHANGED", "$.plan_id", "candidate plan identity differs from current inputs")
    job = next((item for item in current["jobs"] if item["job_id"] == receipt["job_id"]), None)
    if job is None:
        changed("JOB_ID_UNKNOWN", "$.job_id", "job id is not present in the current batch plan")
    elif receipt["output_path"] != job["output_path"]:
        changed("OUTPUT_PATH_CHANGED", "$.output_path", "candidate output path differs from the planned job")

    ref = manifest["master_reference"]
    if (receipt["master"]["master_id"] != ref.get("master_id")
            or receipt["master"]["contract_sha256"] != ref.get("contract_sha256")):
        changed("MASTER_BINDING_CHANGED", "$.master", "candidate master identity/contract differs from the current batch")
    master = _master_report(manifest, asset_root, repo_root, [], [], [])
    if master is not None:
        armature = master["armature"]
        if (receipt["master"]["blender_project_sha256"] != master["blender"]["project_sha256"]
                or receipt["master"]["armature_identity_sha256"] != armature["identity_sha256"]
                or receipt["master"]["rest_pose_sha256"] != armature["rest_pose_sha256"]
                or receipt["master"]["skeleton_signature_sha256"] != armature["skeleton_signature_sha256"]):
            changed("MASTER_MODEL_CHANGED", "$.master", "candidate master model or rig identity differs from the current master contract")

    animation = next((item for item in manifest["animations"] if item["animation_id"] == receipt["source"]["animation_id"]), None)
    if animation is None:
        changed("SOURCE_ANIMATION_UNKNOWN", "$.source.animation_id", "source animation id is not present in the current manifest")
    else:
        source = animation["source"]
        timing = animation["authored_timing"]
        proof_sha = animation["source_action"]["inspection_proof_sha256"]
        if (receipt["source"]["original_filename"] != source["original_filename"]
                or receipt["source"]["fbx_sha256"] != source["sha256"]
                or receipt["source"]["inspection_proof_sha256"] != proof_sha
                or receipt["source"]["authored_fps"] != timing["fps"]
                or receipt["source"]["frame_start"] != timing["frame_start"]
                or receipt["source"]["frame_end"] != timing["frame_end"]
                or receipt["source"]["duration_seconds"] != timing["duration_seconds"]):
            changed("SOURCE_BINDING_CHANGED", "$.source", "candidate source/action timing differs from the current batch manifest")
        root = animation["root_motion"]
        if (receipt["root_motion"]["policy"] != root["policy"]
                or receipt["root_motion"]["source_state"] != root["source_state"]
                or receipt["root_motion"]["pose_root_translation"] != root["pose_root_translation"]
                or receipt["root_motion"]["godot_application"] != root["godot_application"]
                or (root["source_state"] == "present" and receipt["root_motion"]["original_trajectory_sha256"] != root["source_trajectory_sha256"])):
            changed("ROOT_MOTION_BINDING_CHANGED", "$.root_motion", "candidate root-motion metadata differs from current source policy")
        sampling = animation["sampling"]
        expected_indices = _sample_indices(animation)
        actual_indices = [[frame["source_frame"] for frame in direction["frames"]] for direction in receipt["directions"]]
        if (receipt["sampling"]["loop_endpoint_policy"] != sampling["loop_endpoint_policy"]
                or receipt["sampling"]["source_timing_preserved"] is not True
                or expected_indices is None or any(indices != expected_indices for indices in actual_indices)):
            changed("SAMPLE_SET_CHANGED", "$.sampling", "candidate sampled frames differ from the current source-range policy")
        runtime = animation["runtime_timing_authority"]
        if receipt["sampling"]["runtime_timing_authority"].get("sha256") != runtime["authority_sha256"]:
            changed("RUNTIME_TIMING_AUTHORITY_CHANGED", "$.sampling.runtime_timing_authority", "candidate runtime timing authority hash differs from the manifest")

    rendering = manifest["rendering_contract"]
    if (receipt["rendering_contract"]["contract_id"] != rendering["contract_id"]
            or receipt["rendering_contract"]["contract_sha256"] != rendering["contract_sha256"]
            or receipt["rendering_contract"]["directions"] != list(DIRECTIONS)):
        changed("RENDERING_CONTRACT_CHANGED", "$.rendering_contract", "candidate rendering identity differs from the pinned contract")
    if [item["direction"] for item in receipt["directions"]] != list(DIRECTIONS):
        changed("DIRECTION_SET_INVALID", "$.directions", "candidate must contain exactly one independently rendered entry in canonical direction order")

    checked: list[dict[str, Any]] = []
    hash_errors: list[dict[str, str]] = []

    def check_file(label: str, scope: str, path: str | None, expected: str | None, prefix: str) -> None:
        root = repo_root if scope == "repository" else asset_root
        _record_dependency(checked, label=label, root=root, relative=path, expected=expected,
                           code_prefix=prefix, errors=hash_errors)

    seen_dependencies: dict[tuple[str, str], str] = {}
    for i, dependency in enumerate(receipt["dependencies"]):
        key = (dependency["scope"], dependency["path"])
        if key in seen_dependencies and seen_dependencies[key] != dependency["sha256"]:
            changed("RECEIPT_DEPENDENCY_CONFLICT", f"$.dependencies[{i}]", "same dependency path has conflicting hashes")
        seen_dependencies[key] = dependency["sha256"]
        check_file(f"receipt_dependency_{i:04d}", dependency["scope"], dependency["path"], dependency["sha256"], "RECEIPT_DEPENDENCY")
    for d_index, direction in enumerate(receipt["directions"]):
        for f_index, frame in enumerate(direction["frames"]):
            check_file(f"direction_{d_index:02d}_frame_{f_index:05d}", "asset_root", frame["path"], frame["sha256"], "CANDIDATE_OUTPUT")
    for i, diagnostic in enumerate(receipt["diagnostics"]):
        check_file(f"diagnostic_{i:04d}", "asset_root", diagnostic["path"], diagnostic["sha256"], "CANDIDATE_OUTPUT")
    root_motion_receipt = receipt["root_motion"]
    if root_motion_receipt["source_state"] == "present":
        check_file("root_trajectory", "asset_root", root_motion_receipt["original_trajectory_path"],
                   root_motion_receipt["original_trajectory_sha256"], "CANDIDATE_TRAJECTORY")
    elif root_motion_receipt["original_trajectory_path"] is not None or root_motion_receipt["original_trajectory_sha256"] is not None:
        changed("ROOT_TRAJECTORY_AVAILABILITY_MISMATCH", "$.root_motion", "absent source displacement cannot declare an output trajectory")
    qa = receipt["technical_qa"]
    check_file("technical_qa", "asset_root", qa["report_path"], qa["report_sha256"], "CANDIDATE_QA")
    for error in hash_errors:
        changes.append({"code": error["code"], "path": error["path"], "message": error["message"]})
    changes.sort(key=lambda item: (item["code"], item["path"], item["message"]))
    return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": bool(changes),
             "job_id": receipt["job_id"], "plan_id": receipt["plan_id"], "current_plan_id": current["plan_id"],
             "changes": changes, "current_validation": current["validation"]}, EXIT_STALE if changes else EXIT_OK)


def command_check(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    plan_path = args.artifact.resolve()
    old_plan, errors = read_json(plan_path, "PLAN_OR_RECEIPT_MISSING")
    if errors:
        return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": True, "errors": errors}, EXIT_INVALID)
    if not isinstance(old_plan, dict):
        return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": True,
                 "errors": [{"code": "ARTIFACT_FORMAT_INVALID", "path": str(plan_path), "message": "input is not a supported plan or candidate receipt"}]}, EXIT_INVALID)
    manifest_path = args.manifest.resolve()
    manifest, errors = _load_manifest(manifest_path)
    if errors:
        return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": True, "errors": errors}, EXIT_INVALID)
    artifact_schema = old_plan.get("schema")
    asset_root = Path(args.asset_root or manifest_path.parent)
    repo_root = Path(args.repo_root or REPO_ROOT)
    if artifact_schema == "custodian.operator_3d_animation_candidate_receipt.v1":
        return _check_candidate_receipt(old_plan, manifest, manifest_path, asset_root, repo_root, candidate_only=getattr(args, "candidate_only", False))
    if schema_findings(old_plan, PLAN_SCHEMA):
        return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": True,
                 "errors": [{"code": "PLAN_FORMAT_INVALID", "path": str(plan_path), "message": "input is not a supported animation plan"}]}, EXIT_INVALID)
    current = _build_plan(manifest, manifest_path, asset_root, repo_root, candidate_only=getattr(args, "candidate_only", False))
    stale = canonical_bytes(old_plan) != canonical_bytes(current)
    changes = []
    if old_plan.get("input_manifest_sha256") != current["input_manifest_sha256"]:
        changes.append({"code": "MANIFEST_CHANGED", "path": str(manifest_path), "message": "manifest bytes changed since the plan was created"})
    if old_plan.get("validation", {}).get("dependencies") != current["validation"]["dependencies"]:
        changes.append({"code": "DEPENDENCIES_CHANGED", "path": "$.validation.dependencies", "message": "declared dependency presence or hashes changed"})
    if stale and not changes:
        changes.append({"code": "PLAN_CONTENT_CHANGED", "path": str(plan_path), "message": "plan identity does not match current declared inputs"})
    return ({"schema": "custodian.operator_3d_animation_check.v1", "command": "check", "stale": stale,
             "plan_id": old_plan["plan_id"], "current_plan_id": current["plan_id"], "changes": changes,
             "current_validation": current["validation"]}, EXIT_STALE if stale else EXIT_OK)


def emit(payload: dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(payload, sort_keys=True, indent=2, ensure_ascii=False) + "\n")


class JsonArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> None:
        del message
        emit({"schema": "custodian.operator_3d_animation_error.v1", "command": "arguments",
              "errors": [{"code": "INVALID_ARGUMENTS", "path": "$", "message": "command arguments are invalid"}]})
        raise SystemExit(EXIT_INVALID)


def build_parser() -> argparse.ArgumentParser:
    parser = JsonArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True, parser_class=JsonArgumentParser)
    for name in ("plan", "validate"):
        child = sub.add_parser(name)
        child.add_argument("manifest", type=Path)
        child.add_argument("--asset-root", type=Path, help="authorized root for external FBX/master dependencies (defaults to manifest directory)")
        child.add_argument("--repo-root", type=Path, help=argparse.SUPPRESS)
        child.add_argument("--candidate-only", action="store_true", help="allow unavailable runtime timing authority for an unapproved candidate; never supplies timing values")
        child.set_defaults(run=command_plan if name == "plan" else command_validate)
    check = sub.add_parser("check")
    check.add_argument("artifact", type=Path, help="saved plan or candidate receipt JSON")
    check.add_argument("manifest", type=Path)
    check.add_argument("--asset-root", type=Path)
    check.add_argument("--repo-root", type=Path, help=argparse.SUPPRESS)
    check.add_argument("--candidate-only", action="store_true", help="check an unapproved candidate without runtime timing authority")
    check.set_defaults(run=command_check)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        payload, code = args.run(args)
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        emit({"schema": "custodian.operator_3d_animation_error.v1", "command": args.command,
              "errors": [{"code": "INPUT_PROCESSING_ERROR", "path": "$", "message": type(error).__name__}]})
        return EXIT_IO
    emit(payload)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
