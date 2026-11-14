"""Atomic candidate orchestration for static, unrigged Operator GLB proofs."""
from __future__ import annotations

import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Iterable

from .glb import ModelToSpriteError, inspect_glb, sha256_file, validate_static_glb


PACKAGE_ROOT = pathlib.Path(__file__).resolve().parent
REPO_ROOT = PACKAGE_ROOT.parents[3]
BLENDER_RENDER_SCRIPT = PACKAGE_ROOT / "render_static_blender.py"
PROFILE_PATH = PACKAGE_ROOT / "profile.v1.json"
MANIFEST_NAME = "candidate_manifest.v1.json"
SAFE_NAME = re.compile(r"^[a-z0-9][a-z0-9._-]{0,62}[a-z0-9]$|^[a-z0-9]$")
MAX_REVIEW_FILES = 12
MAX_REVIEW_BYTES = 50 * 1024 * 1024


def canonical_bytes(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def _json_bytes(value) -> bytes:
    return json.dumps(value, sort_keys=True, indent=2, ensure_ascii=False).encode("utf-8") + b"\n"


def _safe_name(name: str) -> str:
    if not isinstance(name, str) or not SAFE_NAME.fullmatch(name) or ".." in name:
        raise ModelToSpriteError("USAGE_INVALID_NAME", "candidate name must be 1-64 lowercase letters, digits, dot, underscore, or hyphen; no path components")
    return name


def _safe_root(root: str | pathlib.Path, *, create: bool) -> pathlib.Path:
    path = pathlib.Path(root).expanduser()
    if path.is_symlink():
        raise ModelToSpriteError("OUTPUT_UNSAFE_PATH", "output root may not be a symbolic link")
    if create:
        path.mkdir(parents=True, exist_ok=True)
    try:
        resolved = path.resolve(strict=True)
    except OSError as exc:
        raise ModelToSpriteError("OUTPUT_ROOT_MISSING", "output root is unavailable") from exc
    if not resolved.is_dir():
        raise ModelToSpriteError("OUTPUT_ROOT_INVALID", "output root must be a directory")
    return resolved


def _relative_input(input_path: str | pathlib.Path, asset_root: str | pathlib.Path | None):
    source = pathlib.Path(input_path).expanduser()
    root = pathlib.Path(asset_root).expanduser() if asset_root is not None else source.parent
    if root.is_symlink() or source.is_symlink():
        raise ModelToSpriteError("INPUT_UNSAFE_PATH", "input and asset root may not be symbolic links")
    try:
        root_resolved = root.resolve(strict=True)
        source_resolved = source.resolve(strict=True)
        rel = source_resolved.relative_to(root_resolved)
    except (OSError, ValueError) as exc:
        raise ModelToSpriteError("INPUT_UNSAFE_PATH", "input must be within the declared asset root") from exc
    if not source_resolved.is_file() or not rel.parts or any(part in (".", "..") for part in rel.parts):
        raise ModelToSpriteError("INPUT_MISSING", "input must be a readable regular file beneath the asset root")
    return source_resolved, root_resolved, rel.as_posix()


def _safe_asset_file(asset_root: pathlib.Path, relative_path: str) -> pathlib.Path:
    rel = pathlib.PurePosixPath(relative_path)
    if rel.is_absolute() or "\\" in relative_path or any(part in ("", ".", "..") for part in rel.parts):
        raise ModelToSpriteError("MANIFEST_UNSAFE_PATH", "candidate manifest contains an unsafe dependency path")
    candidate = asset_root.joinpath(*rel.parts)
    if candidate.is_symlink():
        raise ModelToSpriteError("INPUT_UNSAFE_PATH", f"dependency may not be a symbolic link: {rel.name}")
    try:
        resolved = candidate.resolve(strict=True)
    except OSError as exc:
        raise ModelToSpriteError("DEPENDENCY_MISSING", f"candidate dependency is missing: {rel.as_posix()}") from exc
    if asset_root not in resolved.parents or not resolved.is_file():
        raise ModelToSpriteError("MANIFEST_UNSAFE_PATH", "candidate dependency escapes the declared asset root")
    return resolved


def _blender_path(blender_executable: str | None) -> str:
    executable = blender_executable or os.environ.get("CUSTODIAN_BLENDER") or shutil.which("blender")
    if not executable or not os.access(executable, os.X_OK):
        raise ModelToSpriteError("BLENDER_MISSING", "Blender was not found; set CUSTODIAN_BLENDER or add blender to PATH")
    return str(pathlib.Path(executable).resolve())


def _blender_version(executable: str) -> str:
    try:
        result = subprocess.run([executable, "--version"], capture_output=True, text=True, timeout=60, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise ModelToSpriteError("BLENDER_VERSION_FAILED", "could not query Blender version") from exc
    first = next((line.strip() for line in result.stdout.splitlines() if line.strip()), None)
    if result.returncode or not first:
        raise ModelToSpriteError("BLENDER_VERSION_FAILED", "Blender did not report a version")
    return first


def _source_dependencies(inspection: dict, asset_root: pathlib.Path, source: pathlib.Path) -> list[dict]:
    dependencies = []
    for item in inspection["dependencies"]:
        dependency = source.parent / item["path"]
        try:
            relative = dependency.resolve(strict=True).relative_to(asset_root).as_posix()
        except (OSError, ValueError) as exc:
            raise ModelToSpriteError("GLB_UNSAFE_DEPENDENCY", "GLB dependency escapes the declared asset root") from exc
        dependencies.append({"path": relative, "sha256": item["sha256"], "bytes": item["bytes"]})
    return dependencies


def _png_metadata_and_bounds(path: pathlib.Path, *, strip_metadata: bool = False) -> dict:
    try:
        from PIL import Image
    except ImportError as exc:
        raise ModelToSpriteError("PILLOW_MISSING", "Pillow is required for candidate raster verification") from exc
    try:
        with Image.open(path) as image:
            image.load()
            if image.mode != "RGBA":
                raise ModelToSpriteError("RASTER_NOT_RGBA", f"{path.name} is {image.mode}, expected RGBA")
            size = image.size
            bounds = image.getchannel("A").getbbox()
            if bounds is None:
                raise ModelToSpriteError("RASTER_EMPTY_ALPHA", f"{path.name} has no visible pixels")
            info = {"width": size[0], "height": size[1], "channels": "RGBA",
                    "alpha_bounds": list(bounds)}
            # Re-encode only to remove Blender's volatile software/date metadata. Decoded pixels are checked unchanged.
            pixels = image.tobytes()
            if strip_metadata and image.info:
                image.save(path, format="PNG", optimize=False, compress_level=9)
            with Image.open(path) as clean:
                clean.load()
                if clean.mode != "RGBA" or clean.size != size or clean.tobytes() != pixels:
                    raise ModelToSpriteError("RASTER_METADATA_STRIP_CHANGED_PIXELS", f"metadata cleanup changed pixels in {path.name}")
            return info
    except OSError as exc:
        raise ModelToSpriteError("RASTER_INVALID", f"PNG cannot be decoded: {path.name}") from exc


def _contact_sheet(candidate_dir: pathlib.Path, size: int) -> pathlib.Path:
    from PIL import Image, ImageDraw

    directions = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
    cell = size
    sheet = Image.new("RGBA", (cell * 4, (cell + 24) * 2), (28, 30, 36, 255))
    draw = ImageDraw.Draw(sheet)
    for index, direction in enumerate(directions):
        row, col = divmod(index, 4)
        frame = Image.open(candidate_dir / "renders" / f"{size}_{direction}.png").convert("RGBA")
        sheet.alpha_composite(frame, (col * cell, row * (cell + 24)))
        draw.text((col * cell + 4, row * (cell + 24) + cell + 3), direction, fill=(245, 245, 245, 255))
    destination = candidate_dir / "review_pack" / f"8dir_{size}.png"
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, format="PNG", optimize=False)
    return destination


def _tool_sources() -> list[dict]:
    paths = (PROFILE_PATH, PACKAGE_ROOT / "glb.py", PACKAGE_ROOT / "pipeline.py", BLENDER_RENDER_SCRIPT)
    return [{"path": p.relative_to(REPO_ROOT).as_posix(), "sha256": sha256_file(p)} for p in paths]


def _candidate_identity(manifest: dict) -> dict:
    """Return every declared render dependency and output covered by the receipt ID."""
    return {
        "candidate_id": manifest["candidate_id"],
        "source": manifest["source"],
        "dependencies": manifest["dependencies"],
        "render_profile_sha256": manifest["render_profile"]["sha256"],
        "tool_sources": manifest["tool_sources"],
        "blender_version": manifest["renderer"]["blender_version"],
        "normalization": manifest["normalization"],
        "camera": manifest["camera"],
        "outputs": manifest["outputs"],
        "review_files": manifest["review_files"],
    }


def _candidate_child(candidate: pathlib.Path, relative: str) -> pathlib.Path:
    rel = pathlib.PurePosixPath(relative) if isinstance(relative, str) else pathlib.PurePosixPath("..")
    if (not isinstance(relative, str) or not relative or rel.is_absolute() or "\\" in relative
            or any(part in ("", ".", "..") for part in rel.parts)):
        raise ModelToSpriteError("CANDIDATE_MANIFEST_INVALID", "candidate output path is unsafe")
    target = candidate.joinpath(*rel.parts)
    if target.is_symlink():
        raise ModelToSpriteError("CANDIDATE_UNSAFE_PATH", "candidate outputs may not be symbolic links")
    try:
        resolved = target.resolve(strict=True)
    except OSError as exc:
        raise ModelToSpriteError("CANDIDATE_OUTPUT_MISSING", "candidate output is missing") from exc
    if candidate not in resolved.parents or not resolved.is_file():
        raise ModelToSpriteError("CANDIDATE_UNSAFE_PATH", "candidate output escapes its directory")
    return resolved


def render_static(
    input_path: str | pathlib.Path,
    output_root: str | pathlib.Path,
    name: str,
    *,
    asset_root: str | pathlib.Path | None = None,
    blender_executable: str | None = None,
    timeout_seconds: int = 1800,
    target_height_px: float = 85.0,
) -> dict:
    """Validate and render one unrigged GLB into a new atomic candidate directory."""
    name = _safe_name(name)
    if not 20.0 <= target_height_px <= 120.0:
        raise ModelToSpriteError("USAGE_INVALID_PARAMETER", "target height must be in [20, 120] pixels")
    if not 30 <= timeout_seconds <= 7200:
        raise ModelToSpriteError("USAGE_INVALID_PARAMETER", "timeout must be in [30, 7200] seconds")
    source, source_root, source_rel = _relative_input(input_path, asset_root)
    inspection = validate_static_glb(source)
    source_sha = inspection["source"]["sha256"]
    source_bytes = inspection["source"]["bytes"]
    dependencies = _source_dependencies(inspection, source_root, source)
    dependency_before = {entry["path"]: entry["sha256"] for entry in dependencies}
    output_parent = _safe_root(output_root, create=True)
    final = output_parent / name
    if os.path.lexists(final):
        raise ModelToSpriteError("OUTPUT_COLLISION", f"refusing to overwrite existing candidate: {name}")
    blender = _blender_path(blender_executable)
    version = _blender_version(blender)
    profile = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
    profile_sha = sha256_file(PROFILE_PATH)
    stage = pathlib.Path(tempfile.mkdtemp(prefix=f".staging-{name}-", dir=output_parent))
    try:
        (stage / "renders").mkdir()
        command = [blender, "-b", "--factory-startup", "--python", str(BLENDER_RENDER_SCRIPT), "--",
                   str(source), str(stage / "renders"), str(profile["elevation_degrees"]),
                   str(profile["pixels_per_meter_at_128"]), str(target_height_px)]
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=timeout_seconds, check=False)
        except subprocess.TimeoutExpired as exc:
            raise ModelToSpriteError("RENDER_TIMEOUT", f"Blender render exceeded {timeout_seconds} seconds") from exc
        except OSError as exc:
            raise ModelToSpriteError("BLENDER_LAUNCH_FAILED", "could not start Blender render process") from exc
        reports = [line.partition(":")[2] for line in result.stdout.splitlines() if line.startswith("MODEL_TO_SPRITE_RENDER_JSON:")]
        failures = [line.partition(":")[2] for line in result.stdout.splitlines() if line.startswith("MODEL_TO_SPRITE_ERROR:")]
        if result.returncode or failures or not reports:
            detail = failures[-1] if failures else (result.stderr + result.stdout).strip()[-1000:]
            raise ModelToSpriteError("RENDER_FAILED", detail or "Blender render did not emit a completion report")
        render_report = json.loads(reports[-1])
        if render_report.get("blender_version") != version.removeprefix("Blender "):
            raise ModelToSpriteError("RENDER_VERSION_DRIFT", "Blender version changed during render")
        if source.stat().st_size != source_bytes or sha256_file(source) != source_sha:
            raise ModelToSpriteError("INPUT_MUTATED", "source GLB changed while rendering")
        for relative, before_hash in dependency_before.items():
            dependency = _safe_asset_file(source_root, relative)
            if sha256_file(dependency) != before_hash:
                raise ModelToSpriteError("INPUT_MUTATED", f"source dependency changed while rendering: {relative}")

        output_records: dict[str, dict] = {}
        for size in (128, 512):
            for direction in profile["directions"]:
                rel = f"renders/{size}_{direction}.png"
                path = stage / rel
                if not path.is_file():
                    raise ModelToSpriteError("RENDER_INCOMPLETE", f"missing required direction output: {rel}")
                raster = _png_metadata_and_bounds(path, strip_metadata=True)
                if raster["width"] != size or raster["height"] != size:
                    raise ModelToSpriteError("RASTER_DIMENSIONS_INVALID", f"{rel} has wrong dimensions")
                output_records[rel] = {"sha256": sha256_file(path), "bytes": path.stat().st_size, **raster}
        for size in (128, 512):
            _contact_sheet(stage, size)
        (stage / "render_info.v1.json").write_bytes(_json_bytes(render_report))
        review_report = (
            "# Static Operator 3D render candidate\n\n"
            "Status: `candidate_unapproved`. This technical proof is not an art approval or runtime publication.\n\n"
            f"- Source GLB SHA-256: `{source_sha}`\n"
            f"- Blender: `{version}`\n"
            f"- Render profile SHA-256: `{profile_sha}`\n"
            f"- Uniform scale: `{render_report['normalization']['applied_uniform_scale']:.9g}` (fit from S once)\n"
            "- Directions: N, NE, E, SE, S, SW, W, NW; no mirroring.\n"
            "- Resolutions: independently rendered 128×128 and 512×512 RGBA.\n"
            "- Fixed projection: 45° orthographic, 50 px/m, 2.56 m ortho scale, root `(64,106)`.\n"
        )
        (stage / "review_pack" / "TECHNICAL_REPORT.md").write_text(review_report, encoding="utf-8")
        review_records = {
            path.relative_to(stage).as_posix(): {"sha256": sha256_file(path), "bytes": path.stat().st_size}
            for path in sorted((stage / "review_pack").iterdir()) if path.is_file()
        }
        source_identity = {"path": source_rel, "sha256": source_sha, "bytes": source_bytes}
        manifest = {
            "schema": "custodian.operator_3d_static_candidate.v1",
            "candidate_id": name,
            "candidate_identity_sha256": "",
            "status": "candidate_unapproved",
            "approved": False,
            "runtime_selection": False,
            "source": source_identity,
            "dependencies": dependencies,
            "render_profile": {"path": PROFILE_PATH.relative_to(REPO_ROOT).as_posix(), "sha256": profile_sha},
            "renderer": {"blender_version": version, "script_sha256": sha256_file(BLENDER_RENDER_SCRIPT),
                         "color_management": render_report["color_management"], "engine": render_report["engine"]},
            "tool_sources": _tool_sources(),
            "normalization": render_report["normalization"],
            "camera": render_report["camera"],
            "outputs": output_records,
            "review_files": review_records,
        }
        manifest["candidate_identity_sha256"] = hashlib.sha256(
            canonical_bytes(_candidate_identity(manifest))
        ).hexdigest()
        (stage / MANIFEST_NAME).write_bytes(_json_bytes(manifest))
        # Check the staged receipt before the only promotion operation.
        staged_check = verify_candidate(stage, source_root)
        if staged_check["status"] != "current":
            raise ModelToSpriteError("CANDIDATE_SELF_CHECK_FAILED", "; ".join(staged_check.get("errors", [])))
        if os.path.lexists(final):
            raise ModelToSpriteError("OUTPUT_COLLISION", f"candidate appeared during render: {name}")
        os.rename(stage, final)
        return {"candidate_path": str(final), "candidate_id": name, "candidate_identity_sha256": manifest["candidate_identity_sha256"],
                "source_sha256": source_sha, "output_count": len(output_records), "status": manifest["status"]}
    except Exception:
        if stage.exists() and stage.parent == output_parent and stage.name.startswith(f".staging-{name}-"):
            shutil.rmtree(stage, ignore_errors=True)
        raise


def verify_candidate(candidate_dir: str | pathlib.Path, asset_root: str | pathlib.Path | None) -> dict:
    """Verify receipt, exact input/dependency/tool hashes, and every generated RGBA raster."""
    candidate = pathlib.Path(candidate_dir).expanduser()
    if candidate.is_symlink():
        raise ModelToSpriteError("CANDIDATE_UNSAFE_PATH", "candidate directory may not be a symbolic link")
    candidate = candidate.resolve(strict=True)
    if not candidate.is_dir():
        raise ModelToSpriteError("CANDIDATE_INVALID", "candidate path must be a directory")
    try:
        manifest = json.loads((candidate / MANIFEST_NAME).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ModelToSpriteError("CANDIDATE_MANIFEST_INVALID", "candidate manifest is missing or invalid JSON") from exc
    if not isinstance(manifest, dict):
        raise ModelToSpriteError("CANDIDATE_MANIFEST_INVALID", "candidate manifest must be a JSON object")
    if manifest.get("schema") != "custodian.operator_3d_static_candidate.v1":
        raise ModelToSpriteError("CANDIDATE_MANIFEST_INVALID", "candidate schema is not supported")
    schema_path = PACKAGE_ROOT / "schemas" / "static_candidate.v1.schema.json"
    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        from custodian.tools.operator.animation_compiler.cli import schema_findings
        findings = schema_findings(manifest, schema)
    except (OSError, json.JSONDecodeError, ImportError, KeyError, TypeError) as exc:
        raise ModelToSpriteError("CANDIDATE_SCHEMA_UNAVAILABLE", "candidate schema could not be loaded") from exc
    if findings:
        raise ModelToSpriteError("CANDIDATE_MANIFEST_INVALID", "candidate manifest does not satisfy its schema")
    if manifest.get("status") != "candidate_unapproved" or manifest.get("approved") is not False or manifest.get("runtime_selection") is not False:
        raise ModelToSpriteError("CANDIDATE_APPROVAL_INVALID", "candidate status and approval fields must remain unapproved/unselected")
    errors: list[str] = []
    if asset_root is None:
        raise ModelToSpriteError("ASSET_ROOT_REQUIRED", "verify requires --asset-root to recheck source and dependency bytes")
    root = pathlib.Path(asset_root).expanduser()
    if root.is_symlink():
        raise ModelToSpriteError("INPUT_UNSAFE_PATH", "asset root may not be a symbolic link")
    try:
        root = root.resolve(strict=True)
    except OSError as exc:
        raise ModelToSpriteError("INPUT_ROOT_MISSING", "asset root is unavailable") from exc
    source = _safe_asset_file(root, manifest.get("source", {}).get("path", ""))
    if source.stat().st_size != manifest["source"].get("bytes") or sha256_file(source) != manifest["source"].get("sha256"):
        errors.append("SOURCE_HASH_MISMATCH")
    for entry in manifest.get("dependencies", []):
        dependency = _safe_asset_file(root, entry.get("path", ""))
        if dependency.stat().st_size != entry.get("bytes") or sha256_file(dependency) != entry.get("sha256"):
            errors.append("DEPENDENCY_HASH_MISMATCH:" + entry.get("path", ""))
    tool_root = REPO_ROOT
    current_sources = {entry["path"]: entry["sha256"] for entry in _tool_sources()}
    for entry in manifest.get("tool_sources", []):
        try:
            tool_path = _safe_asset_file(tool_root, entry["path"])
        except ModelToSpriteError:
            errors.append("TOOL_SOURCE_MISSING:" + entry.get("path", ""))
            continue
        actual = sha256_file(tool_path)
        if actual != entry.get("sha256") or current_sources.get(entry["path"]) != entry.get("sha256"):
            errors.append("TOOL_SOURCE_STALE:" + entry.get("path", ""))
    if manifest.get("render_profile", {}).get("sha256") != sha256_file(PROFILE_PATH):
        errors.append("RENDER_PROFILE_STALE")
    expected = {f"renders/{size}_{direction}.png" for size in (128, 512)
                for direction in ("N", "NE", "E", "SE", "S", "SW", "W", "NW")}
    if set(manifest.get("outputs", {})) != expected:
        errors.append("DIRECTION_OUTPUT_SET_INVALID")
    try:
        identity_hash = hashlib.sha256(canonical_bytes(_candidate_identity(manifest))).hexdigest()
    except (KeyError, TypeError):
        raise ModelToSpriteError("CANDIDATE_MANIFEST_INVALID", "candidate manifest is missing identity fields")
    if identity_hash != manifest.get("candidate_identity_sha256"):
        errors.append("CANDIDATE_IDENTITY_MISMATCH")
    from .glb import _regular_file
    # Also validate the source remains a supported static GLB, rather than a hash-valid rigged replacement.
    try:
        validate_static_glb(source)
    except ModelToSpriteError as exc:
        errors.append(exc.code)
    for relative in sorted(expected):
        record = manifest.get("outputs", {}).get(relative)
        try:
            path = _candidate_child(candidate, relative)
        except ModelToSpriteError:
            errors.append("OUTPUT_MISSING:" + relative)
            continue
        if sha256_file(path) != record.get("sha256") or path.stat().st_size != record.get("bytes"):
            errors.append("OUTPUT_HASH_MISMATCH:" + relative)
            continue
        try:
            raster = _png_metadata_and_bounds(path)
        except ModelToSpriteError as exc:
            errors.append(exc.code + ":" + relative)
            continue
        size = int(relative.split("/")[1].split("_")[0])
        if (raster["width"], raster["height"], raster["channels"]) != (size, size, "RGBA"):
            errors.append("OUTPUT_RASTER_MISMATCH:" + relative)
        if raster["alpha_bounds"] != record.get("alpha_bounds"):
            errors.append("OUTPUT_ALPHA_BOUNDS_MISMATCH:" + relative)
    for relative, record in manifest.get("review_files", {}).items():
        try:
            path = _candidate_child(candidate, relative)
        except ModelToSpriteError:
            errors.append("REVIEW_OUTPUT_MISMATCH:" + relative)
            continue
        if sha256_file(path) != record.get("sha256") or path.stat().st_size != record.get("bytes"):
            errors.append("REVIEW_OUTPUT_MISMATCH:" + relative)
    return {"status": "current" if not errors else "stale", "errors": sorted(set(errors)),
            "candidate_id": manifest.get("candidate_id"), "candidate_identity_sha256": manifest.get("candidate_identity_sha256"),
            "output_count": len(manifest.get("outputs", {}))}


def publish_review(
    candidate_dir: str | pathlib.Path,
    asset_root: str | pathlib.Path,
    *,
    reason: str,
    questions: Iterable[str],
    workstream: str,
    authoring_chat: str | None = None,
    dry_run: bool = False,
    publisher: str | pathlib.Path | None = None,
    rclone: str | None = None,
) -> dict:
    """Publish a verified compact proof using the existing CUSTODIAN review publisher."""
    candidate = pathlib.Path(candidate_dir).resolve(strict=True)
    verification = verify_candidate(candidate, asset_root)
    if verification["status"] != "current":
        raise ModelToSpriteError("CANDIDATE_STALE", "; ".join(verification["errors"]))
    questions = list(questions)
    if not reason.strip() or not questions:
        raise ModelToSpriteError("PUBLISH_ARGUMENTS_REQUIRED", "publish-review requires a reason and at least one reviewer question")
    files = sorted(path for path in (candidate / "review_pack").iterdir() if path.is_file())
    if not files or len(files) > MAX_REVIEW_FILES or sum(path.stat().st_size for path in files) > MAX_REVIEW_BYTES:
        raise ModelToSpriteError("REVIEW_PACK_SIZE_INVALID", "review package must contain files and remain within 12 files / 50 MiB")
    if not any(path.suffix.lower() == ".png" for path in files):
        raise ModelToSpriteError("REVIEW_PACK_IMAGES_MISSING", "review package must include at least one PNG")
    publisher_path = pathlib.Path(publisher) if publisher else REPO_ROOT / "custodian/tools/iteration/publish_review_artifacts.py"
    if not publisher_path.is_file():
        raise ModelToSpriteError("PUBLISHER_MISSING", "existing CUSTODIAN visual review publisher was not found")
    rclone_path = rclone or shutil.which("rclone")
    if not dry_run and not rclone_path:
        raise ModelToSpriteError("RCLONE_MISSING", "rclone is required to verify uploaded artifact bytes")
    stage = pathlib.Path(tempfile.mkdtemp(prefix="custodian-model-sprite-review-"))
    try:
        staged: list[pathlib.Path] = []
        for source_file in files:
            destination = stage / source_file.name
            shutil.copyfile(source_file, destination)
            staged.append(destination)
        images = [path for path in staged if path.suffix.lower() == ".png"]
        command = [sys.executable, str(publisher_path), "--important", "--reason", reason,
                   "--workstream", workstream, "--scenario", "operator/model-to-sprite", "--source", str(images[0])]
        if authoring_chat:
            command += ["--authoring-chat", authoring_chat]
        if dry_run:
            command.append("--dry-run")
        for question in questions:
            command += ["--question", question]
        for artifact in staged:
            if artifact != images[0]:
                command += ["--artifact", str(artifact)]
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=1800, check=False)
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise ModelToSpriteError("PUBLISH_FAILED", "existing review publisher could not complete") from exc
        lines = [line.partition(":")[2] for line in result.stdout.splitlines() if line.startswith("CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON:")]
        if result.returncode or not lines:
            raise ModelToSpriteError("PUBLISH_FAILED", (result.stderr + result.stdout).strip()[-1000:])
        report = json.loads(lines[-1])
        if dry_run:
            count = len(report.get("manifest", {}).get("artifacts", []))
            if count != len(files):
                raise ModelToSpriteError("PUBLISH_SELECTION_MISMATCH", "publisher dry-run did not include every staged review artifact")
            return {"status": "dry_run_verified", "selected_count": count, "candidate_id": verification["candidate_id"]}
        if report.get("status") != "uploaded":
            raise ModelToSpriteError("PUBLISH_FAILED", "publisher did not confirm uploaded state")
        remote = report.get("remote", "git-dropbox-sync:") + report["dropbox_path"].strip("/") + "/artifacts"
        check = subprocess.run([rclone_path, "check", str(stage), remote, "--one-way"], capture_output=True, text=True,
                               timeout=900, check=False)
        if check.returncode:
            raise ModelToSpriteError("PUBLISH_VERIFY_FAILED", (check.stderr + check.stdout).strip()[-1000:])
        return {"status": "uploaded_verified", "manifest_path": report.get("manifest_path"),
                "dropbox_path": report.get("dropbox_path"), "candidate_id": verification["candidate_id"]}
    finally:
        shutil.rmtree(stage, ignore_errors=True)
