#!/usr/bin/env python3
"""Package a verified 3D animation candidate for the isolated Godot preview.

This adapter only copies candidate frames into ignored ``custodian/.ai`` and
writes a hash-bound preview request. It never writes runtime or Asset V2 paths.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

SCHEMA = "custodian.operator_3d_animation_candidate_receipt.v1"
PREVIEW_SCHEMA = "custodian.operator_3d_animation_preview_request.v1"
QA_SCHEMA = "custodian.operator_neutral_idle_technical_qa.v1"
DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
ROOT_PIXEL = (64.0, 106.0)
PREVIEW_SCALE = 0.75
PREVIEW_ROOT_Y = -31.5


class PackageError(ValueError):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _load_json(path: Path, code: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise PackageError(code, f"cannot read JSON: {path}") from exc
    if not isinstance(value, dict):
        raise PackageError(code, f"expected JSON object: {path}")
    return value


def _safe_file(root: Path, relative: Any, code: str) -> Path:
    if not isinstance(relative, str) or not relative or "\\" in relative or "\x00" in relative:
        raise PackageError(code, "dependency path must be a non-empty confined relative path")
    parsed = PurePosixPath(relative)
    if parsed.is_absolute() or any(part in {"", ".", ".."} for part in parsed.parts):
        raise PackageError("PATH_UNSAFE", f"unsafe relative path: {relative}")
    candidate = root.joinpath(*parsed.parts)
    try:
        resolved = candidate.resolve(strict=False)
        resolved.relative_to(root.resolve(strict=True))
    except (OSError, ValueError, RuntimeError) as exc:
        raise PackageError("PATH_UNSAFE", f"path escapes proof root: {relative}") from exc
    if not resolved.is_file():
        raise PackageError("INPUT_MISSING", f"required file is missing: {relative}")
    return resolved


def _png_rgba_pixels(path: Path) -> tuple[int, int, bytes]:
    """Decode a 128px, non-interlaced PNG to canonical RGBA bytes."""
    try:
        from PIL import Image
    except ImportError as exc:  # pragma: no cover - host tool dependency guard
        raise PackageError("PNG_DECODER_MISSING", "Pillow is required to verify PNG pixels") from exc
    try:
        with Image.open(path) as image:
            if image.format != "PNG":
                raise PackageError("FRAME_FORMAT", f"frame is not PNG: {path}")
            if image.size != (128, 128):
                raise PackageError("FRAME_DIMENSIONS", f"frame is not exact 128x128: {path}")
            rgba = image.convert("RGBA")
            return rgba.width, rgba.height, rgba.tobytes()
    except PackageError:
        raise
    except Exception as exc:
        raise PackageError("FRAME_DECODE", f"cannot decode frame: {path}") from exc


def _validate_source_and_master(proof_root: Path, receipt: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    source = receipt.get("source")
    master = receipt.get("master")
    if not isinstance(source, dict) or not isinstance(master, dict):
        raise PackageError("PROVENANCE_INVALID", "candidate receipt must bind source and master identities")
    if not SHA_RE.fullmatch(str(source.get("fbx_sha256", ""))):
        raise PackageError("SOURCE_HASH_INVALID", "candidate receipt has no valid source FBX hash")
    if not SHA_RE.fullmatch(str(master.get("blender_project_sha256", ""))):
        raise PackageError("MASTER_HASH_INVALID", "candidate receipt has no valid master project hash")
    dependencies = receipt.get("dependencies")
    if not isinstance(dependencies, list):
        raise PackageError("PROVENANCE_INVALID", "candidate receipt dependencies are missing")
    required = {
        "fbx": source["fbx_sha256"],
        "blender_project": master["blender_project_sha256"],
        "technical_qa_report": receipt.get("technical_qa", {}).get("report_sha256"),
    }
    found: set[str] = set()
    for dependency in dependencies:
        if not isinstance(dependency, dict):
            continue
        kind = dependency.get("kind")
        if kind not in required:
            continue
        if kind in found:
            raise PackageError("PROVENANCE_DUPLICATE", f"duplicate {kind} dependency in receipt")
        found.add(kind)
        expected = required[kind]
        if dependency.get("sha256") != expected or not SHA_RE.fullmatch(str(expected or "")):
            raise PackageError("PROVENANCE_MISMATCH", f"{kind} identity differs from candidate receipt")
        path = _safe_file(proof_root, dependency.get("path"), "INPUT_PATH_INVALID")
        if sha256_file(path) != expected:
            raise PackageError("PROVENANCE_HASH_MISMATCH", f"{kind} bytes differ from candidate receipt")
    if found != set(required):
        raise PackageError("PROVENANCE_MISSING", "FBX, master project, and technical QA dependencies are required")
    return source, master


def validate_candidate(proof_root: Path, receipt_path: Path) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any], dict[str, Any]]:
    proof_root = proof_root.resolve(strict=True)
    receipt_relative = receipt_path.relative_to(proof_root).as_posix() if receipt_path.is_absolute() else receipt_path.as_posix()
    receipt_path = _safe_file(proof_root, receipt_relative, "RECEIPT_PATH_INVALID")
    receipt = _load_json(receipt_path, "RECEIPT_INVALID")
    if receipt.get("schema") != SCHEMA:
        raise PackageError("RECEIPT_SCHEMA", f"unsupported candidate receipt schema: {receipt.get('schema')!r}")
    if receipt.get("candidate_state") != "candidate_unapproved" or receipt.get("production_approval", {}).get("approved") is not False:
        raise PackageError("CANDIDATE_AUTHORITY", "preview adapter accepts only explicitly unapproved candidates")
    source, master = _validate_source_and_master(proof_root, receipt)

    qa_ref = receipt.get("technical_qa")
    qa_path = _safe_file(proof_root, qa_ref.get("report_path") if isinstance(qa_ref, dict) else None, "QA_PATH_INVALID")
    if sha256_file(qa_path) != qa_ref.get("report_sha256"):
        raise PackageError("QA_HASH_MISMATCH", "technical QA report bytes differ from candidate receipt")
    qa = _load_json(qa_path, "QA_INVALID")
    if qa.get("schema") != QA_SCHEMA or qa.get("status") != "pass" or qa.get("candidate_state") != "candidate_unapproved":
        raise PackageError("QA_NOT_PASSED", "candidate technical QA must pass while retaining unapproved state")
    if qa.get("production_approval") is not False:
        raise PackageError("QA_AUTHORITY", "technical QA must not grant production approval")

    contract = receipt.get("rendering_contract")
    if not isinstance(contract, dict):
        raise PackageError("RENDER_CONTRACT_INVALID", "candidate rendering contract is missing")
    if contract.get("directions") != list(DIRECTIONS):
        raise PackageError("DIRECTION_CONTRACT", "candidate directions must be N, NE, E, SE, S, SW, W, NW in that order")
    if (contract.get("width"), contract.get("height"), contract.get("channels")) != (128, 128, "RGBA"):
        raise PackageError("RENDER_CONTRACT_INVALID", "candidate frames must be 128x128 RGBA")
    if contract.get("mirroring") is not False or contract.get("scale_policy") != "fixed_from_master":
        raise PackageError("RENDER_CONTRACT_INVALID", "candidate must use fixed scale and no directional mirroring")
    root_pixel = qa.get("render_contract", {}).get("root_pixel")
    if root_pixel != list(ROOT_PIXEL):
        raise PackageError("ROOT_REGISTRATION", "technical QA root pixel must be canonical (64,106)")
    registrations = qa.get("registered_root_pixels")
    if not isinstance(registrations, dict):
        raise PackageError("ROOT_REGISTRATION", "technical QA root registration data is missing")
    for direction in DIRECTIONS:
        point = registrations.get(direction)
        if not isinstance(point, list) or len(point) != 2 or any(abs(float(point[i]) - ROOT_PIXEL[i]) > 0.001 for i in range(2)):
            raise PackageError("ROOT_REGISTRATION", f"{direction} root registration differs from canonical (64,106)")

    sampling = receipt.get("sampling")
    qa_source = qa.get("source")
    if not isinstance(sampling, dict) or sampling.get("source_timing_preserved") is not True:
        raise PackageError("SOURCE_TIMING", "candidate must preserve authored source timing")
    if sampling.get("loop_endpoint_policy") != "omit_declared_duplicate_terminal":
        raise PackageError("LOOP_POLICY", "candidate must explicitly omit only its declared duplicate loop endpoint")
    fps = source.get("authored_fps")
    if not isinstance(fps, (int, float)) or fps <= 0 or qa_source.get("fps") != fps:
        raise PackageError("SOURCE_TIMING", "source-authored FPS must match QA")
    start, end = source.get("frame_start"), source.get("frame_end")
    rendered_indices = qa_source.get("rendered_frame_indices")
    if not isinstance(start, int) or not isinstance(end, int) or end <= start or not isinstance(rendered_indices, list):
        raise PackageError("SOURCE_TIMING", "source key range or rendered frame indices are invalid")
    if qa_source.get("loop_endpoint_duplicate") is not True:
        raise PackageError("LOOP_POLICY", "QA must verify the duplicate terminal loop frame")
    expected_frames = list(range(start, end))
    if rendered_indices != expected_frames:
        raise PackageError("FRAME_ORDER", "rendered source frames must preserve the full range except the verified duplicate endpoint")

    directions = receipt.get("directions")
    if not isinstance(directions, list) or [item.get("direction") for item in directions if isinstance(item, dict)] != list(DIRECTIONS):
        raise PackageError("DIRECTION_CONTRACT", "candidate must provide exactly eight independently rendered directions")
    qa_hashes = qa.get("frame_hashes")
    if not isinstance(qa_hashes, dict):
        raise PackageError("QA_FRAME_HASHES", "technical QA frame hashes are missing")

    for direction in directions:
        name = direction["direction"]
        rows = direction.get("frames")
        qa_rows = qa_hashes.get(name)
        if not isinstance(rows, list) or not isinstance(qa_rows, list) or len(rows) != len(expected_frames) or len(qa_rows) != len(expected_frames):
            raise PackageError("FRAME_COUNT", f"{name} frame count differs from authored loop sampling")
        for index, (row, qa_row, source_frame) in enumerate(zip(rows, qa_rows, expected_frames), start=1):
            if not isinstance(row, dict) or row.get("source_frame") != source_frame or qa_row.get("source_frame") != source_frame:
                raise PackageError("FRAME_ORDER", f"{name} frame {index} does not map to source frame {source_frame}")
            if row.get("width") != 128 or row.get("height") != 128 or row.get("channels") != "RGBA":
                raise PackageError("FRAME_DIMENSIONS", f"{name} frame {index} is not 128x128 RGBA")
            relative = row.get("path")
            source_path = _safe_file(proof_root, relative, "FRAME_PATH_INVALID")
            if qa_row.get("path") != relative or qa_row.get("sha256") != row.get("sha256"):
                raise PackageError("QA_FRAME_HASHES", f"{name} frame {index} disagrees with technical QA")
            if not SHA_RE.fullmatch(str(row.get("sha256", ""))):
                raise PackageError("FRAME_HASH_INVALID", f"{name} frame {index} has no valid SHA-256")
            if sha256_file(source_path) != row["sha256"]:
                raise PackageError("FRAME_HASH_MISMATCH", f"{name} frame {index} bytes differ from receipt")
            _png_rgba_pixels(source_path)
    return receipt, qa, source, master


def _canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def build_package(proof_root: Path, project_root: Path, receipt_path: Path, *, run_import: bool = True,
                  godot: str = "godot", smoke_script: str = "res://tools/validation/operator_3d_animation_preview_smoke.gd") -> dict[str, Any]:
    project_root = project_root.resolve(strict=True)
    proof_root = proof_root.resolve(strict=True)
    if receipt_path.is_absolute():
        try:
            receipt_relative = receipt_path.relative_to(proof_root)
        except ValueError as exc:
            raise PackageError("RECEIPT_PATH_INVALID", "candidate receipt must be inside proof root") from exc
    else:
        receipt_relative = receipt_path
    receipt_path = _safe_file(proof_root, receipt_relative.as_posix(), "RECEIPT_PATH_INVALID")
    if not (project_root / "project.godot").is_file():
        raise PackageError("GODOT_PROJECT_INVALID", f"project.godot missing under {project_root}")
    receipt, qa, source, master = validate_candidate(proof_root, receipt_path)
    receipt_sha = sha256_file(receipt_path)
    job_id = str(receipt.get("job_id", ""))
    if not job_id or not re.fullmatch(r"[A-Za-z0-9_.-]{1,96}", job_id):
        raise PackageError("JOB_ID_INVALID", "candidate receipt job_id is not a safe path component")
    package_id = f"{job_id}-{receipt_sha[:12]}"
    relative_package = Path(".ai") / "operator_3d_animation_preview" / package_id
    output_root = project_root / relative_package
    try:
        output_root.resolve(strict=False).relative_to(project_root)
    except ValueError as exc:
        raise PackageError("OUTPUT_PATH_UNSAFE", "preview output escapes the Godot project") from exc
    if output_root.is_symlink() or any(parent.is_symlink() for parent in output_root.parents if parent != project_root.parent):
        raise PackageError("OUTPUT_PATH_UNSAFE", "preview output may not traverse symlinks")

    if output_root.exists():
        request_file = output_root / "request.json"
        if not request_file.is_file():
            raise PackageError("OUTPUT_COLLISION", f"preview output already exists without a request: {output_root}")
        existing = _load_json(request_file, "REQUEST_INVALID")
        if existing.get("candidate_receipt_sha256") != receipt_sha:
            raise PackageError("OUTPUT_COLLISION", "existing preview package identity differs")
    else:
        output_root.mkdir(parents=True, exist_ok=False)

    request_directions: list[dict[str, Any]] = []
    for direction in receipt["directions"]:
        output_frames: list[dict[str, Any]] = []
        for row in direction["frames"]:
            source_path = _safe_file(proof_root, row["path"], "FRAME_PATH_INVALID")
            width, height, rgba = _png_rgba_pixels(source_path)
            target_relative = Path("frames") / direction["direction"] / f"{row['source_frame']:04d}.png"
            target = output_root / target_relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                if sha256_file(target) != row["sha256"]:
                    raise PackageError("OUTPUT_COLLISION", f"existing preview frame differs: {target_relative}")
            else:
                shutil.copyfile(source_path, target)
            if sha256_file(target) != row["sha256"]:
                raise PackageError("COPY_HASH_MISMATCH", f"copied preview frame differs: {target_relative}")
            output_frames.append({
                "source_frame": row["source_frame"],
                "path": f"res://{(relative_package / target_relative).as_posix()}",
                "sha256": row["sha256"],
                "pixel_sha256": sha256_bytes(rgba),
                "width": width,
                "height": height,
                "channels": "RGBA",
            })
        request_directions.append({"direction": direction["direction"], "frames": output_frames})

    payload: dict[str, Any] = {
        "schema": PREVIEW_SCHEMA,
        "candidate_state": "candidate_unapproved",
        "production_approval": False,
        "timing_authority_granted": False,
        "candidate_receipt_path": str(receipt_path.resolve()),
        "candidate_receipt_sha256": receipt_sha,
        "candidate_job_id": job_id,
        "candidate_version": receipt.get("candidate_version", job_id),
        "preview_scene": "res://scenes/debug/operator_3d_animation_preview_awakening.tscn"
        if "awakening" in smoke_script else "res://scenes/debug/operator_3d_animation_preview.tscn",
        "animation_id": source.get("animation_id"),
        "source": {
            "filename": source.get("original_filename"),
            "fbx_sha256": source.get("fbx_sha256"),
            "authored_fps": source.get("authored_fps"),
            "frame_start": source.get("frame_start"),
            "frame_end": source.get("frame_end"),
            "rendered_source_frames": qa["source"]["rendered_frame_indices"],
            "loop_endpoint_duplicate_omitted": True,
        },
        "master": master,
        "render_contract": {
            "contract_id": receipt["rendering_contract"]["contract_id"],
            "directions": list(DIRECTIONS),
            "root_pixel": list(ROOT_PIXEL),
            "ground_sprite_scale": PREVIEW_SCALE,
            "ground_sprite_offset_y": PREVIEW_ROOT_Y,
        },
        "root_registration": {key: qa["registered_root_pixels"][key] for key in DIRECTIONS},
        "directions": request_directions,
        "approved_runtime_animation_template": "unarmed/locomotion/idle_01/{direction}/full_body",
        "staging": "ignored-dev-only",
    }
    request_path = output_root / "request.json"
    encoded = _canonical_json_bytes(payload)
    if request_path.exists() and request_path.read_bytes() != encoded:
        raise PackageError("OUTPUT_COLLISION", "existing preview request differs from current verified inputs")
    request_path.write_bytes(encoded)
    request_sha = sha256_bytes(encoded)
    (output_root / "request.json.sha256").write_text(request_sha + "\n", encoding="ascii")
    manifest = {
        "schema": "custodian.operator_3d_animation_preview_package.v1",
        "candidate_receipt_sha256": receipt_sha,
        "request_sha256": request_sha,
        "package_path": f"res://{relative_package.as_posix()}",
        "frame_count_per_direction": len(request_directions[0]["frames"]),
        "direction_count": len(DIRECTIONS),
        "authored_fps": source["authored_fps"],
        "timing_authority_granted": False,
        "candidate_state": "candidate_unapproved",
    }
    (output_root / "package_manifest.json").write_bytes(_canonical_json_bytes(manifest))

    prior_manifest_path = output_root / "package_manifest.json"
    prior_import = "not_requested"
    if prior_manifest_path.is_file():
        try:
            prior_import = str(_load_json(prior_manifest_path, "PACKAGE_MANIFEST_INVALID").get("godot_import", "not_requested"))
        except PackageError:
            prior_import = "not_requested"
    import_result = prior_import if not run_import else "not_requested"
    if run_import:
        resolved_godot = shutil.which(godot) or (godot if Path(godot).is_file() else None)
        if resolved_godot is None:
            raise PackageError("GODOT_NOT_FOUND", f"Godot executable not found: {godot}")
        result = subprocess.run(
            [
                str(resolved_godot), "--headless", "--path", str(project_root),
                "--script", smoke_script,
                "--", "--request", manifest["package_path"] + "/request.json",
            ],
            cwd=project_root,
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise PackageError("GODOT_PREVIEW_SMOKE_FAILED", (result.stderr or result.stdout)[-3000:])
        import_result = "passed"
    manifest["godot_import"] = import_result
    (output_root / "package_manifest.json").write_bytes(_canonical_json_bytes(manifest))
    return manifest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    prepare = sub.add_parser("prepare", help="verify a candidate and stage it under ignored custodian/.ai")
    prepare.add_argument("--proof-root", type=Path, required=True)
    prepare.add_argument("--project-root", type=Path, default=Path("custodian"))
    prepare.add_argument("--receipt", type=Path, default=Path("candidate/neutral_idle_candidate_receipt.v1.json"))
    prepare.add_argument("--godot", default="godot")
    prepare.add_argument("--smoke-script", default="res://tools/validation/operator_3d_animation_preview_smoke.gd")
    prepare.add_argument("--skip-import", action="store_true", help="package only; do not run the Godot editor import pass")
    args = parser.parse_args(argv)
    try:
        result = build_package(args.proof_root, args.project_root, args.receipt, run_import=not args.skip_import,
                               godot=args.godot, smoke_script=args.smoke_script)
        print(json.dumps({"ok": True, **result}, sort_keys=True))
        return 0
    except PackageError as exc:
        print(json.dumps({"ok": False, "error": {"code": exc.code, "message": exc.message}}, sort_keys=True))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
