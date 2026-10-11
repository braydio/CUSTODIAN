"""Deterministic, local-only generation briefs for exact Operator 2.5D targets."""
from __future__ import annotations

import hashlib
import io
import json
import os
import re
import shutil
import tempfile
from pathlib import Path
from typing import Any

import operator_animation_targets as targets
from PIL import Image, ImageDraw
from ui.state import AnimationSelection


BRIEF_ROOT = ".ai/operator_animation_workbench/generation_briefs"
SCHEMA = "custodian.operator_generation_brief.v1"


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(Path(path).read_bytes())


def _safe_file(root: Path, path: Path) -> Path:
    candidate = path.resolve(strict=True)
    if not candidate.is_relative_to(root.resolve(strict=True)) or not candidate.is_file():
        raise ValueError(f"brief input is outside its authorized root: {path}")
    return candidate


def _safe_directory(root: Path, path: Path) -> Path:
    candidate = path.resolve(strict=True)
    if not candidate.is_relative_to(root.resolve(strict=True)) or not candidate.is_dir():
        raise ValueError(f"brief input directory is outside its authorized root: {path}")
    return candidate


def _guide_overlay_bytes(registration: dict[str, Any]) -> bytes:
    """Render a tiny transparent registration overlay from accepted guide data."""
    image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    center = registration.get("guide", {}).get("vertical", {}).get("center")
    ground = registration.get("guide", {}).get("horizontal", {}).get("ground")
    points = registration.get("guide", {}).get("points", {})
    if isinstance(center, int):
        for y in range(0, 128, 4):
            draw.point((center, y), fill=(64, 220, 255, 180))
    if isinstance(ground, int):
        for x in range(0, 128, 4):
            draw.point((x, ground), fill=(255, 210, 64, 210))
    anchor = points.get("foot_anchor")
    if (isinstance(anchor, list) and len(anchor) == 2
            and all(isinstance(value, int) for value in anchor)):
        x, y = anchor
        draw.line((x - 3, y, x + 3, y), fill=(255, 96, 96, 230), width=1)
        draw.line((x, y - 3, x, y + 3), fill=(255, 96, 96, 230), width=1)
    stream = io.BytesIO()
    image.save(stream, format="PNG", optimize=False)
    return stream.getvalue()


def _authority(repo_root: Path, selection: AnimationSelection) -> tuple[dict[str, Any], dict[str, Path]]:
    if selection.art_generation != "operator_2_5d_128":
        raise ValueError("generation briefs require an exact operator_2_5d_128 target")
    root = Path(repo_root).resolve()
    plan_path = root / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
    profile_path = root / "custodian/content/data/operator/authoring/operator_art_profile.json"
    plan = targets.load_plan(plan_path)
    family = next((row for row in targets.target_families(plan)
                   if (row.profile, row.group, row.action) == (selection.profile, selection.group, selection.action)), None)
    if family is None or selection.direction not in family.directions:
        raise ValueError("selection is not an exact leaf in the current target plan")
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    profile_id = profile.get("active_authoring_profile", "")
    profile_row = profile.get("profiles", {}).get(profile_id, {})
    reference = profile.get("canonical_visual_reference", {})
    profile_sha = str(profile_row.get("profile_sha256", ""))
    reference_sha = str(reference.get("sha256", ""))
    if (profile_id != "operator_2_5d_128" or not profile_sha or not reference_sha
            or family.canonical_profile_sha256 != profile_sha
            or family.normalized_reference_sha256 != reference_sha):
        raise ValueError("target plan profile/reference authority is stale")
    reference_path = _safe_file(root, root / str(reference.get("path", "")))
    if sha256_file(reference_path) != reference_sha:
        raise ValueError("canonical profile reference bytes do not match their advertised SHA-256")
    direction_root = _safe_directory(root, root / str(profile_row.get("canonical_reference", {}).get("directions_path", "")))
    direction_reference = _safe_file(direction_root, direction_root / f"{selection.direction}.png")
    direction_order = ("n", "ne", "e", "se", "s", "sw", "w", "nw")
    direction_index = direction_order.index(selection.direction)
    adjacent = sorted({direction_order[(direction_index - 1) % len(direction_order)],
                       direction_order[(direction_index + 1) % len(direction_order)]})
    bundled_references = {f"references/directions/{selection.direction}.png": direction_reference}
    bundled_references.update({f"references/directions/{direction}.png": _safe_file(direction_root, direction_root / f"{direction}.png")
                               for direction in adjacent})
    guide = profile_row.get("registration")
    if not isinstance(guide, dict) or guide.get("status") != "accepted":
        raise ValueError("accepted registration guide is unavailable")
    contract = dict(family.frame_contract)
    size = contract.get("frame_size")
    if size is not None and list(size) != [128, 128]:
        raise ValueError("target frame contract does not use the accepted 128x128 canvas")
    authority = {
        "target": {"art_generation": family.generation, "profile": family.profile,
                   "group": family.group, "action": family.action,
                   "direction": selection.direction, "layer": family.required_layers[0] if len(family.required_layers) == 1 else None,
                   "required_layers": list(family.required_layers), "authoring_identity": selection.authoring_identity},
        "plan_sha256": sha256_file(plan_path),
        "profile_sha256": profile_sha,
        "reference_sha256": reference_sha,
        "direction_reference_sha256": sha256_file(direction_reference),
        "bundled_reference_sha256": {name: sha256_file(path) for name, path in sorted(bundled_references.items())},
        "frame_contract": contract,
        "source_sha256": family.source_sha256,
        "registration": guide,
        "registration_sha256": sha256_bytes(canonical_json(guide)),
        "registration_overlay_sha256": sha256_bytes(_guide_overlay_bytes(guide)),
        "optional_context": {"motion_donor": None, "presentation_events": None},
    }
    authority["authority_digest"] = sha256_bytes(canonical_json(authority))
    return authority, {"plan": plan_path, "profile": profile_path,
                      "reference": reference_path, "direction_reference": direction_reference}


def _prompt(selection: AnimationSelection) -> str:
    return (f"Create Operator animation art for {selection.profile}/{selection.group}/{selection.action}, "
            f"direction {selection.direction}, generation operator_2_5d_128.\n"
            f"Follow references/canonical_rotation.png and references/directions/{selection.direction}.png.\n"
            "Preserve the accepted profile registration guide exactly. Do not infer any unknown frame, loop, or timing fields; see manifest.json.\n")


def export_generation_brief(repo_root: Path, workspace_root: Path, selection: AnimationSelection) -> dict[str, Any]:
    """Atomically create or reuse a byte-identical content-addressed brief."""
    root = Path(repo_root).resolve()
    authority, sources = _authority(root, selection)
    brief_id = authority["authority_digest"]
    bundle_root = Path(workspace_root).resolve() / "generation_briefs"
    bundle_root.mkdir(parents=True, exist_ok=True)
    final = bundle_root / brief_id
    direction_root = sources["direction_reference"].parent
    files = {
        "references/canonical_rotation.png": sources["reference"],
        **{name: _safe_file(root, direction_root / Path(name).name)
           for name in authority["bundled_reference_sha256"]},
    }
    guide_bytes = json.dumps(authority["registration"], indent=2, ensure_ascii=False).encode("utf-8") + b"\n"
    overlay_bytes = _guide_overlay_bytes(authority["registration"])
    hashes = {name: sha256_file(path) for name, path in sorted(files.items())}
    hashes["registration_guide.json"] = sha256_bytes(guide_bytes)
    hashes["registration_overlay.png"] = sha256_bytes(overlay_bytes)
    manifest = {"schema": SCHEMA, "brief_id": brief_id, "target": authority["target"],
                "authority": {key: value for key, value in authority.items() if key != "target"},
                "frame_contract": authority["frame_contract"], "files": hashes,
                "readiness": "GENERATION_READY" if authority["frame_contract"].get("frames") else "PLANNING_ONLY",
                "unknown_authoring_fields": [field for field in ("frames", "loop", "fps")
                    if authority["frame_contract"].get(field) is None]}
    prompt = _prompt(selection)
    hashes["PROMPT.txt"] = sha256_bytes(prompt.encode("utf-8"))
    if final.exists():
        _validate_bundle(final, brief_id, sha256_file(final / "manifest.json"), selection,
                         root, Path(workspace_root).resolve())
        expected = {"manifest.json": json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
                    "PROMPT.txt": prompt, "registration_guide.json": guide_bytes,
                    "registration_overlay.png": overlay_bytes,
                    **{name: path.read_bytes() for name, path in files.items()}}
        for name, content in expected.items():
            if not (final / name).is_file() or (final / name).read_bytes() != (content if isinstance(content, bytes) else content.encode()):
                raise ValueError("immutable brief ID already exists with different bundle bytes")
        return {"brief_id": brief_id, "manifest_sha256": sha256_file(final / "manifest.json"), "path": final}
    staging = Path(tempfile.mkdtemp(prefix=f".{brief_id}.", dir=bundle_root))
    try:
        (staging / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        (staging / "PROMPT.txt").write_text(prompt, encoding="utf-8")
        (staging / "registration_guide.json").write_bytes(guide_bytes)
        (staging / "registration_overlay.png").write_bytes(overlay_bytes)
        for relative, source in files.items():
            destination = staging / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(_safe_file(root, source), destination)
            if sha256_file(destination) != hashes[relative]:
                raise ValueError("brief input changed while it was being copied")
        current, _ = _authority(root, selection)
        if current != authority:
            raise ValueError("target/profile/reference authority changed while exporting brief")
        for relative, expected in hashes.items():
            if sha256_file(staging / relative) != expected:
                raise ValueError("brief bundle content changed before publication")
        if final.exists():
            raise ValueError("brief destination appeared during atomic export")
        os.replace(staging, final)
    except Exception:
        shutil.rmtree(staging, ignore_errors=True)
        raise
    return {"brief_id": brief_id, "manifest_sha256": sha256_file(final / "manifest.json"), "path": final}


def _validate_bundle(bundle: Path, brief_id: str, expected_manifest_sha256: str,
                     selection: AnimationSelection, repo_root: Path,
                     workspace_root: Path) -> dict[str, Any]:
    base = (Path(workspace_root).resolve() / "generation_briefs").resolve()
    path = Path(bundle).resolve(strict=True)
    if not path.is_relative_to(base) or path.name != brief_id or not re.fullmatch(r"[0-9a-f]{64}", brief_id):
        raise ValueError("generation brief path or ID is invalid")
    manifest_path = _safe_file(base, path / "manifest.json")
    if sha256_file(manifest_path) != expected_manifest_sha256:
        raise ValueError("generation brief manifest hash mismatch")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema") != SCHEMA or manifest.get("brief_id") != brief_id:
        raise ValueError("generation brief schema or identity mismatch")
    expected_identity = {"art_generation": selection.art_generation, "profile": selection.profile,
                         "group": selection.group, "action": selection.action,
                         "direction": selection.direction}
    target = manifest.get("target", {})
    if any(target.get(key) != value for key, value in expected_identity.items()):
        raise ValueError("generation brief target does not match the requested selection")
    current, sources = _authority(repo_root, selection)
    if current["authority_digest"] != brief_id:
        raise ValueError("generation brief target/profile/reference authority is stale")
    expected_target = current["target"]
    expected_authority = {key: value for key, value in current.items() if key != "target"}
    expected_guide = json.dumps(current["registration"], indent=2, ensure_ascii=False).encode("utf-8") + b"\n"
    expected_overlay = _guide_overlay_bytes(current["registration"])
    expected_files = {"references/canonical_rotation.png": current["reference_sha256"],
                      **current["bundled_reference_sha256"],
                      "registration_guide.json": sha256_bytes(expected_guide),
                      "registration_overlay.png": sha256_bytes(expected_overlay),
                      "PROMPT.txt": sha256_bytes(_prompt(selection).encode("utf-8"))}
    expected_contract = current["frame_contract"]
    expected_unknown = [field for field in ("frames", "loop", "fps") if expected_contract.get(field) is None]
    expected_readiness = "GENERATION_READY" if expected_contract.get("frames") else "PLANNING_ONLY"
    if (target != expected_target or manifest.get("authority") != expected_authority
            or manifest.get("frame_contract") != expected_contract
            or manifest.get("files") != expected_files
            or manifest.get("unknown_authoring_fields") != expected_unknown
            or manifest.get("readiness") != expected_readiness):
        raise ValueError("generation brief manifest fields do not match current target authority")
    for relative, digest in expected_files.items():
        item = _safe_file(path, path / relative)
        if sha256_file(item) != digest:
            raise ValueError("generation brief bundled file hash mismatch")
    if ((path / "PROMPT.txt").read_bytes() != _prompt(selection).encode("utf-8")
            or (path / "registration_guide.json").read_bytes() != expected_guide
            or (path / "registration_overlay.png").read_bytes() != expected_overlay):
        raise ValueError("generation brief prompt or registration guide is not the deterministic current bundle")
    actual_files = {item.relative_to(path).as_posix() for item in path.rglob("*")
                    if item.is_file() and item.name != "manifest.json"}
    if actual_files != set(expected_files):
        raise ValueError("generation brief contains missing or unexpected bundle files")
    if manifest.get("authority", {}).get("plan_sha256") != sha256_file(sources["plan"]):
        raise ValueError("generation brief plan hash is stale")
    return manifest


def validate_generation_brief(repo_root: Path, workspace_root: Path, selection: AnimationSelection,
                              brief_id: str, manifest_sha256: str) -> dict[str, Any]:
    """Revalidate exact bundle identity and live authorities for inbound correlation."""
    if not re.fullmatch(r"[0-9a-f]{64}", str(brief_id)) or not re.fullmatch(r"[0-9a-f]{64}", str(manifest_sha256)):
        raise ValueError("generation brief identity and manifest SHA-256 are required")
    bundle = Path(workspace_root).resolve() / "generation_briefs" / brief_id
    return _validate_bundle(bundle, brief_id, manifest_sha256, selection,
                            Path(repo_root).resolve(), Path(workspace_root).resolve())
