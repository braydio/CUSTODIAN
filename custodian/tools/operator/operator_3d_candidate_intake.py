"""Candidate-only intake of 3D-derived Operator animations into the Operator Workbench.

Registers one read-only Workbench session per semantic direction for each staged, contract-verified
character3d action. Sessions point at the immutable staged frames; nothing is copied, rendered,
mirrored, published or written to canonical art. Generation: operator_3d_80 (candidate_unapproved).

CLI (run from any checkout; paths are explicit):
  --plan    read-only validation and the proposed session writes
  --apply   validate the whole request, then register sessions transactionally (idempotent)
  --verify  recheck registered sessions byte-for-byte against the current staged sources

Exit status: 0 success, 1 validation or registration failure, 2 usage error.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

from PIL import Image

GENERATION = "operator_3d_80"
CONTRACT_SCHEMA = "custodian.character3d_contract.v1"
CANDIDATE_SCHEMA = "custodian.operator_3d_workbench_candidate.v1"
PREVIEW_ACTION_SCHEMA = "custodian.operator_3d_preview_action.v1"
PREVIEW_MANIFEST_SCHEMA = "custodian.operator_3d_preview_manifest.v1"
EXPECTED_MASTER_SHA256 = "3004e9b5014450708bab80897a83ae676d27704321d2bc4cacdaf9ef1881c127"
RENDER_DIRECTIONS = ("S", "SE", "E", "NE", "N", "NW", "W", "SW")
WORKBENCH_DIRECTIONS = {"S": "s", "SE": "se", "E": "e", "NE": "ne", "N": "n", "NW": "nw", "W": "w", "SW": "sw"}
LAYER = "full_body"
APPROVAL_STATE = "candidate_unapproved"
PREVIEW_FPS = 24
FRAME_SIZE = (160, 160)
WORKBENCH_RELATIVE = Path(".ai/operator_animation_workbench")
STAGE_RELATIVE = Path("custodian/.ai/operator_3d_animation_preview")
CANDIDATE_FILE = "candidate.json"

# Explicit source-action to Workbench semantic identity. Unknown actions are rejected, never guessed.
ACTION_MAP: dict[str, dict[str, str]] = {
    "walking": {"profile": "unarmed", "group": "locomotion", "action": "walk_01"},
    "running": {"profile": "unarmed", "group": "locomotion", "action": "run_01"},
}


class IntakeError(Exception):
    """A validation or registration failure. Nothing is written when raised before promotion."""


def _load_contract_validator():
    path = Path(__file__).resolve().parents[1] / "character3d" / "validate_contract.py"
    spec = importlib.util.spec_from_file_location("character3d_validate_contract", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_validator = _load_contract_validator()


def _sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _sha_file(path: Path) -> str:
    return _sha_bytes(path.read_bytes())


def repo_root_for(workbench_root: Path) -> Path:
    """The Workbench lives at <repo>/.ai/operator_animation_workbench."""
    return Path(workbench_root).resolve().parents[1]


def _stage_ref(stage_root: Path, repo_root: Path) -> str:
    resolved = Path(stage_root).resolve()
    try:
        return resolved.relative_to(repo_root).as_posix()
    except ValueError:
        return str(resolved)


def resolve_stage_ref(ref: str, repo_root: Path) -> Path:
    path = Path(ref)
    return path if path.is_absolute() else Path(repo_root) / path


def _confined(path: Path, root: Path) -> Path:
    """Return the resolved path, refusing anything under root that is a symlink or escapes root."""
    root = Path(root)
    try:
        relative = path.relative_to(root)
    except ValueError as error:
        raise IntakeError(f"path escapes the stage root: {path}") from error
    current = root
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            raise IntakeError(f"symbolic link inside the stage root refused: {current}")
    resolved = path.resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise IntakeError(f"path escapes the stage root: {path}")
    return resolved


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        data = json.loads(path.read_bytes())
    except (OSError, ValueError) as error:
        raise IntakeError(f"{label} is unreadable: {path}: {error}") from error
    if not isinstance(data, dict):
        raise IntakeError(f"{label} is not a JSON object: {path}")
    return data


def load_contract(contract_path: Path) -> dict[str, Any]:
    contract = _read_json(Path(contract_path), "character3d contract")
    errors = _validator.validate(contract, _validator.load_schema())
    if errors:
        raise IntakeError("character3d contract is invalid:\n" + "\n".join(errors[:20]))
    if contract.get("schema") != CONTRACT_SCHEMA or contract.get("character_id") != "operator":
        raise IntakeError("contract is not the Operator character3d contract")
    if contract["source"]["master"]["sha256"] != EXPECTED_MASTER_SHA256:
        raise IntakeError("contract master SHA-256 does not match the accepted Operator master")
    if list(contract["directions"]["order"]) != list(RENDER_DIRECTIONS):
        raise IntakeError("contract direction order does not match the eight render directions")
    return contract


def _validate_action(contract: dict, stage_root: Path, action: str, stage_manifest: dict) -> dict[str, Any]:
    """Validate one staged action completely. Returns per-direction frame records keyed by render direction."""
    contract_action = contract["actions"].get(action)
    if contract_action is None:
        raise IntakeError(f"action {action} is absent from the character3d contract")
    if action not in stage_manifest.get("actions", []):
        raise IntakeError(f"action {action} is absent from the stage MANIFEST.json")
    meta_path = _confined(stage_root / "meta" / f"{action}.json", stage_root)
    meta = _read_json(meta_path, f"{action} stage metadata")
    if meta.get("schema") != PREVIEW_ACTION_SCHEMA or meta.get("action") != action:
        raise IntakeError(f"{action} stage metadata has the wrong schema or action")
    if meta.get("scale_px_per_m") != contract["render"]["px_per_m"] or meta.get("approval_state") != APPROVAL_STATE:
        raise IntakeError(f"{action} stage metadata has the wrong render density or approval state")
    motion = contract["source"]["motions"].get(action, {})
    if not motion.get("included") or meta.get("source_sha256") != motion.get("sha256"):
        raise IntakeError(f"{action} source motion SHA-256 does not match the contract")
    if list(meta.get("directions", [])) != list(RENDER_DIRECTIONS):
        raise IntakeError(f"{action} does not contain exactly the eight render directions")
    if tuple(meta.get("frame_size", ())) != FRAME_SIZE or list(contract_action.get("viewport_px", [])) != list(FRAME_SIZE):
        raise IntakeError(f"{action} is not {FRAME_SIZE[0]}x{FRAME_SIZE[1]} in both metadata and contract")
    pivot = [int(value) for value in meta.get("pivot", [])]
    if pivot != [int(value) for value in contract_action["root_px"]]:
        raise IntakeError(f"{action} pivot {pivot} does not match the contract root {contract_action['root_px']}")
    count = int(contract_action["frame_count"])
    if int(meta.get("frame_count", -1)) != count:
        raise IntakeError(f"{action} frame count differs between contract ({count}) and metadata")
    if bool(meta.get("loop")) != bool(contract_action["loop"]):
        raise IntakeError(f"{action} loop flag differs between metadata and contract")
    if meta.get("frames_dir") != f"frames80/{action}":
        raise IntakeError(f"{action} frames_dir is not frames80/{action}")
    cells = meta.get("cell_sha256", {})
    expected_keys = {f"{d}/{k:04d}" for d in RENDER_DIRECTIONS for k in range(count)}
    if set(cells) != expected_keys:
        extra = sorted(set(cells) - expected_keys)[:3]
        missing = sorted(expected_keys - set(cells))[:3]
        raise IntakeError(f"{action} frame index set is wrong; missing {missing} extra {extra}")
    clearance = next((item["clearance_px"] for item in contract["canvas_classes"]
                      if item["id"] == contract_action["viewport"]), None)
    if clearance is None:
        raise IntakeError(f"{action} viewport class {contract_action['viewport']} is not in the contract")
    frames_root = _confined(stage_root / "frames80" / action, stage_root)
    if not frames_root.is_dir():
        raise IntakeError(f"{action} frame root is missing: {frames_root}")
    if {entry.name for entry in frames_root.iterdir()} != set(RENDER_DIRECTIONS):
        raise IntakeError(f"{action} frame tree contains missing or unexpected direction folders")
    records: dict[str, list[dict[str, Any]]] = {}
    for direction in RENDER_DIRECTIONS:
        folder = _confined(frames_root / direction, stage_root)
        names = {entry.name for entry in folder.iterdir()}
        if names != {f"{k:04d}.png" for k in range(count)}:
            raise IntakeError(f"{action} {direction} has missing, duplicated or extra frame files")
        rows = []
        for k in range(count):
            path = _confined(folder / f"{k:04d}.png", stage_root)
            data = path.read_bytes()
            digest = _sha_bytes(data)
            if digest != cells[f"{direction}/{k:04d}"]:
                raise IntakeError(f"{action} {direction}/{k:04d} SHA-256 does not match the stage receipt")
            try:
                with Image.open(path) as image:
                    image.load()
                    if image.mode != "RGBA" or image.size != FRAME_SIZE:
                        raise IntakeError(f"{action} {direction}/{k:04d} is {image.mode} {image.size}, expected RGBA {FRAME_SIZE}")
                    bbox = image.getchannel("A").getbbox()
            except OSError as error:
                raise IntakeError(f"{action} {direction}/{k:04d} is not a readable PNG: {error}") from error
            if bbox is None:
                raise IntakeError(f"{action} {direction}/{k:04d} has no visible pixels")
            left, top, right, bottom = bbox
            if left < clearance or top < clearance or right > FRAME_SIZE[0] - clearance or bottom > FRAME_SIZE[1] - clearance:
                raise IntakeError(f"{action} {direction}/{k:04d} alpha {bbox} leaves the {clearance}px clearance")
            rows.append({"index": k, "render_direction": direction,
                         "path": f"frames80/{action}/{direction}/{k:04d}.png", "sha256": digest})
        records[direction] = rows
    return {"contract_action": contract_action, "meta": meta, "meta_sha256": _sha_file(meta_path),
            "motion_sha256": motion["sha256"], "records": records, "count": count}


def build_candidates(contract_path: Path, stage_root: Path, workbench_root: Path,
                     actions: list[str] | tuple[str, ...]) -> list[dict[str, Any]]:
    """Validate the whole request and return one candidate per (action, direction). Writes nothing."""
    if not actions:
        raise IntakeError("no actions requested")
    if len(set(actions)) != len(actions):
        raise IntakeError(f"duplicate actions requested: {list(actions)}")
    unknown = [action for action in actions if action not in ACTION_MAP]
    if unknown:
        raise IntakeError(f"no explicit semantic mapping for {unknown}; known: {sorted(ACTION_MAP)}")
    stage_root = Path(stage_root)
    workbench_root = Path(workbench_root)
    repo_root = repo_root_for(workbench_root)
    contract = load_contract(Path(contract_path))
    contract_sha = _sha_file(Path(contract_path))
    stage_manifest_path = _confined(stage_root / "MANIFEST.json", stage_root)
    stage_manifest = _read_json(stage_manifest_path, "stage MANIFEST.json")
    if stage_manifest.get("schema") != PREVIEW_MANIFEST_SCHEMA:
        raise IntakeError("stage MANIFEST.json has the wrong schema")
    stage_manifest_sha = _sha_file(stage_manifest_path)
    stage_ref = _stage_ref(stage_root, repo_root)
    candidates = []
    for action in actions:
        result = _validate_action(contract, stage_root, action, stage_manifest)
        identity = ACTION_MAP[action]
        for direction in RENDER_DIRECTIONS:
            wb_direction = WORKBENCH_DIRECTIONS[direction]
            frames = result["records"][direction]
            manifest = {
                "schema": CANDIDATE_SCHEMA,
                "generation": GENERATION,
                "identity": {**identity, "direction": wb_direction, "layer": LAYER},
                "source": {
                    "character_id": "operator",
                    "source_action": action,
                    "render_direction": direction,
                    "stage_root": stage_ref,
                    "contract_sha256": contract_sha,
                    "master_sha256": EXPECTED_MASTER_SHA256,
                    "motion_sha256": result["motion_sha256"],
                    "stage_manifest_sha256": stage_manifest_sha,
                    "action_meta_sha256": result["meta_sha256"],
                },
                "frames": {
                    "count": result["count"],
                    "width": FRAME_SIZE[0],
                    "height": FRAME_SIZE[1],
                    "pivot": [int(value) for value in result["meta"]["pivot"]],
                    "render_px_per_m": int(result["meta"]["scale_px_per_m"]),
                    "items": frames,
                },
                "loop": bool(result["meta"]["loop"]),
                "provisional_preview_fps": PREVIEW_FPS,
                "timing_authority": False,
                "approval_state": APPROVAL_STATE,
                "runtime_published": False,
            }
            path = workbench_root / GENERATION / identity["profile"] / identity["group"] / identity["action"] / wb_direction / CANDIDATE_FILE
            payload = (json.dumps(manifest, indent=1, sort_keys=True) + "\n").encode("utf-8")
            candidates.append({"action": action, "direction": direction, "path": path, "payload": payload,
                               "frame_count": result["count"], "identity": identity | {"direction": wb_direction}})
    return candidates


def classify(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows = []
    for candidate in candidates:
        path = candidate["path"]
        if not path.exists():
            status = "NEW"
        elif path.is_file() and path.read_bytes() == candidate["payload"]:
            status = "UNCHANGED"
        else:
            status = "CONFLICT"
        rows.append({"status": status, "path": str(path), "action": candidate["action"],
                     "direction": candidate["direction"], "frames": candidate["frame_count"]})
    return rows


def plan(contract_path, stage_root, workbench_root, actions) -> dict[str, Any]:
    candidates = build_candidates(contract_path, stage_root, workbench_root, actions)
    return _report("plan", actions, candidates, classify(candidates))


def apply(contract_path, stage_root, workbench_root, actions) -> dict[str, Any]:
    candidates = build_candidates(contract_path, stage_root, workbench_root, actions)
    rows = classify(candidates)
    conflicts = [row["path"] for row in rows if row["status"] == "CONFLICT"]
    if conflicts:
        raise IntakeError("existing candidate sessions have different provenance or content; refusing replacement:\n"
                          + "\n".join(conflicts))
    pending = [candidate for candidate, row in zip(candidates, rows) if row["status"] == "NEW"]
    if not pending:
        return _report("apply", actions, candidates, rows, written=0)
    workbench_root = Path(workbench_root)
    workbench_root.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=".operator_3d_candidate_tmp-", dir=workbench_root))
    created_files: list[Path] = []
    created_dirs: list[Path] = []
    try:
        for index, candidate in enumerate(pending):
            temp = staging / str(index) / CANDIDATE_FILE
            temp.parent.mkdir(parents=True)
            temp.write_bytes(candidate["payload"])
        for index, candidate in enumerate(pending):
            target = candidate["path"]
            missing = []
            parent = target.parent
            while not parent.exists():
                missing.append(parent)
                parent = parent.parent
            for directory in reversed(missing):
                directory.mkdir()
                created_dirs.append(directory)
            if target.exists():
                raise IntakeError(f"session appeared during apply, refusing to replace: {target}")
            os.replace(staging / str(index) / CANDIDATE_FILE, target)
            created_files.append(target)
    except (OSError, IntakeError) as error:
        for target in reversed(created_files):
            target.unlink(missing_ok=True)
        for directory in reversed(created_dirs):
            try:
                directory.rmdir()
            except OSError:
                pass
        if isinstance(error, IntakeError):
            raise
        raise IntakeError(f"registration failed and was rolled back: {error}") from error
    finally:
        shutil.rmtree(staging, ignore_errors=True)
    return _report("apply", actions, candidates, rows, written=len(created_files))


def verify(contract_path, stage_root, workbench_root, actions) -> dict[str, Any]:
    candidates = build_candidates(contract_path, stage_root, workbench_root, actions)
    rows = []
    for candidate in candidates:
        path = candidate["path"]
        if not path.is_file():
            status = "MISSING"
        elif path.read_bytes() == candidate["payload"]:
            status = "VERIFIED"
        else:
            status = "MISMATCH"
        rows.append({"status": status, "path": str(path), "action": candidate["action"],
                     "direction": candidate["direction"], "frames": candidate["frame_count"]})
    report = _report("verify", actions, candidates, rows)
    report["ok"] = all(row["status"] == "VERIFIED" for row in rows)
    return report


def _report(operation: str, actions, candidates, rows, written: int = 0) -> dict[str, Any]:
    return {
        "operation": operation,
        "generation": GENERATION,
        "imported_animations": len(actions),
        "directional_sessions": len(candidates),
        "validated_frames": sum(candidate["frame_count"] for candidate in candidates),
        "written": written,
        "sessions": rows,
    }


def candidate_status(workbench_root: Path, repo_root: Path, *, profile: str, group: str,
                     action: str, direction: str) -> dict[str, Any]:
    """Cheap registration check for Workbench discovery. Frame hashes are verified on preview load."""
    path = Path(workbench_root) / GENERATION / profile / group / action / direction / CANDIDATE_FILE
    if not path.is_file():
        return {"registered": False, "reason": "no candidate session registered"}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        return {"registered": False, "reason": f"candidate session unreadable: {error}"}
    if (data.get("schema") != CANDIDATE_SCHEMA or data.get("generation") != GENERATION
            or data.get("approval_state") != APPROVAL_STATE or data.get("runtime_published") is not False):
        return {"registered": False, "reason": "candidate session has the wrong schema or approval flags"}
    stage_root = resolve_stage_ref(data["source"]["stage_root"], repo_root)
    frames = data["frames"]["items"]
    missing = [item["path"] for item in frames if not (stage_root / item["path"]).is_file()]
    if missing:
        return {"registered": False, "reason": f"{len(missing)} staged frames are missing"}
    meta = stage_root / "meta" / f"{data['source']['source_action']}.json"
    if not meta.is_file() or _sha_file(meta) != data["source"]["action_meta_sha256"]:
        return {"registered": False, "reason": "staged action metadata changed since registration"}
    return {"registered": True, "frames": int(data["frames"]["count"]), "path": path, "data": data}


def load_candidate_frames(manifest_path: Path, *, repo_root: Path) -> dict[str, Any]:
    """Load and hash-verify a registered session's staged frames. Fails closed on any mismatch."""
    data = _read_json(Path(manifest_path), "candidate session")
    if data.get("schema") != CANDIDATE_SCHEMA or data.get("generation") != GENERATION:
        raise IntakeError("candidate session has the wrong schema or generation")
    if data.get("approval_state") != APPROVAL_STATE or data.get("runtime_published") is not False:
        raise IntakeError("candidate session must remain candidate_unapproved and unpublished")
    stage_root = resolve_stage_ref(data["source"]["stage_root"], repo_root)
    meta_path = _confined(stage_root / "meta" / f"{data['source']['source_action']}.json", stage_root)
    if _sha_file(meta_path) != data["source"]["action_meta_sha256"]:
        raise IntakeError("staged action metadata changed since registration; run --verify and re-apply")
    frames, paths = [], []
    for item in data["frames"]["items"]:
        path = _confined(stage_root / item["path"], stage_root)
        digest = _sha_file(path)
        if digest != item["sha256"]:
            raise IntakeError(f"staged frame changed since registration: {item['path']}")
        with Image.open(path) as image:
            image.load()
            if image.mode != "RGBA" or image.size != (data["frames"]["width"], data["frames"]["height"]):
                raise IntakeError(f"staged frame has the wrong format: {item['path']}")
            frames.append(image.copy())
        paths.append(str(path))
    if len(frames) != int(data["frames"]["count"]):
        raise IntakeError("candidate session frame count does not match its frame list")
    fingerprint = _sha_bytes("".join(item["sha256"] for item in data["frames"]["items"]).encode("ascii"))
    return {"frames": tuple(frames), "paths": tuple(paths), "fingerprint": fingerprint,
            "size": (int(data["frames"]["width"]), int(data["frames"]["height"])), "pivot": tuple(data["frames"]["pivot"]),
            "loop": bool(data["loop"]), "fps": int(data["provisional_preview_fps"]), "data": data}


def _parse(argv: list[str] | None) -> argparse.Namespace:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true", help="read-only validation and proposed writes")
    mode.add_argument("--apply", action="store_true", help="validate, then register sessions transactionally")
    mode.add_argument("--verify", action="store_true", help="recheck registered sessions against staged sources")
    ap.add_argument("--contract", required=True, type=Path)
    ap.add_argument("--stage-root", required=True, type=Path)
    ap.add_argument("--workbench-root", required=True, type=Path)
    ap.add_argument("--actions", nargs="+", default=sorted(ACTION_MAP), choices=sorted(ACTION_MAP))
    return ap.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse(argv)
    operation = "plan" if args.plan else "apply" if args.apply else "verify"
    run = {"plan": plan, "apply": apply, "verify": verify}[operation]
    try:
        report = run(args.contract, args.stage_root, args.workbench_root, args.actions)
    except IntakeError as error:
        print(json.dumps({"operation": operation, "ok": False, "error": str(error)}, indent=1))
        return 1
    print(json.dumps(report, indent=1, sort_keys=True, default=str))
    return 0 if report.get("ok", True) else 1


if __name__ == "__main__":
    raise SystemExit(main())
