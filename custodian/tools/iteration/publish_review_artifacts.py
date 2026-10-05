#!/usr/bin/env python3
"""Publish compact CUSTODIAN visual-review evidence to Dropbox through rclone.

This is an opt-in last-mile handoff. It does not replace deterministic validation
and it does not authorize agents to make subjective art-direction decisions.

Typical upload:

    python3 custodian/tools/iteration/publish_review_artifacts.py \
      --important \
      --reason "subjective art/readability review remains after objective checks passed" \
      --workstream awakening-detail-assets \
      --source reports/moment_forge/traversal/awakening_production_environments_zones_01_09/<run-id> \
      --scenario traversal/awakening_production_environments_zones_01_09 \
      --question "Does the new fixture read clearly at gameplay scale?"

Remote resolution:
  1. --remote
  2. CUSTODIAN_REVIEW_REMOTE
  3. rclone remote named "dropbox:"

Credentials remain in the user's rclone config and are never read or written by
this script beyond invoking rclone.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Iterable

import dropbox_transport

DEFAULT_REMOTE_ROOT = "CUSTODIAN/visual_review"
DEFAULT_MAX_FILES = 12
DEFAULT_MAX_MIB = 50.0
DEFAULT_MAX_KEYFRAMES = 6
VISUAL_REVIEW_SCHEMA = "custodian.visual_review_handoff.v2"
LATEST_SCHEMA = "custodian.visual_review_latest.v1"
DELETE_AFTER_REVIEW = "delete_after_review"
RETAIN_AFTER_REVIEW = "retain"
PACKET_ROOT = Path("custodian/docs/ai_context/task_packets")

METADATA_NAMES = (
    "metrics.json",
    "assertions.json",
    "run_result.json",
    "manifest.json",
    "metric_deltas.json",
    "probes.json",
)

PREFERRED_IMAGE_PATTERNS = (
    "*roi*.png",
    "*contact_sheet*.png",
    "*contact-sheet*.png",
    "*review*.png",
    "*comparison*.png",
    "*visual_diff*.png",
)


def _run(
    args: list[str],
    *,
    check: bool = True,
    capture_output: bool = True,
) -> subprocess.CompletedProcess[str]:
    return dropbox_transport.run(args, check=check, capture_output=capture_output)


def _repo_root() -> Path:
    try:
        result = _run(["git", "rev-parse", "--show-toplevel"])
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise SystemExit("error: run from inside a CUSTODIAN git checkout") from exc
    return Path(result.stdout.strip()).resolve()


def _git_value(repo: Path, *args: str, fallback: str = "") -> str:
    try:
        result = _run(["git", "-C", str(repo), *args])
    except (FileNotFoundError, subprocess.CalledProcessError):
        return fallback
    return result.stdout.strip() or fallback


def _slug(value: str, field: str = "value") -> str:
    value = value.strip().lower()
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", value):
        raise ValueError(f"{field} must be lowercase kebab-case: {value!r}")
    return value


def _sha256(path: Path) -> str:
    return dropbox_transport.sha256_file(path)

def _validate_authoring_chat(value: str) -> str:
    value = value.strip()
    if value in {"not-recorded", "n/a"}:
        return value
    if not re.fullmatch(r"https://[^\s]+", value):
        raise ValueError("authoring chat must be an https URL, not-recorded, or n/a")
    return value


def _packet_authoring_chat(repo: Path, workstream: str) -> str:
    """Resolve exact durable authoring-chat metadata for one workstream."""
    workstream_line = re.compile(
        rf"(?m)^\\s*-\\s*Workstream:\\s*`?{re.escape(workstream)}`?\\s*$"
    )
    chat_line = re.compile(r"(?m)^\\s*-\\s*Authoring chat:\\s*`?([^`\\n]+)`?\\s*$")
    matches: list[str] = []
    for root in (repo / PACKET_ROOT, repo / PACKET_ROOT / "archived"):
        if not root.is_dir():
            continue
        for packet in sorted(root.glob("*.md")):
            if packet.name == "README.md":
                continue
            try:
                text = packet.read_text(encoding="utf-8")
            except OSError:
                continue
            if not workstream_line.search(text):
                continue
            match = chat_line.search(text)
            if match:
                chat = _validate_authoring_chat(match.group(1))
                if chat not in matches:
                    matches.append(chat)
    if not matches:
        return "not-recorded"
    concrete = [item for item in matches if item not in {"not-recorded", "n/a"}]
    if len(set(concrete)) > 1:
        raise ValueError(
            f"conflicting authoring chat metadata for {workstream}: " + ", ".join(concrete)
        )
    return concrete[0] if concrete else matches[0]


def _remote_json(remote_path: str) -> tuple[dict[str, object] | None, bool]:
    """Return parsed JSON and existence; malformed JSON is a hard failure."""
    result = _run(["rclone", "cat", remote_path], check=False)
    if result.returncode:
        return None, False
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise ValueError(f"remote JSON is malformed: {remote_path}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"remote JSON is not an object: {remote_path}")
    return value, True


def cleanup_reviewed(
    remote: str,
    remote_root: str,
    workstream: str,
    run_id: str,
) -> int:
    """Delete exactly one reviewed v2 evidence run when its manifest permits it."""
    try:
        workstream = _slug(workstream, "workstream")
    except ValueError as exc:
        print(f"FAIL: {exc}")
        return 2
    if not re.fullmatch(r"[A-Za-z0-9._-]+", run_id):
        print("FAIL: --run-id contains unsupported path characters.")
        return 2

    remote_root = remote_root.strip("/")
    destination = _remote_path(remote, remote_root, workstream, run_id)
    manifest_path = f"{destination}/REVIEW_MANIFEST.json"
    latest_destination = _remote_path(remote, remote_root, workstream, "LATEST.json")

    try:
        manifest, exists = _remote_json(manifest_path)
    except ValueError as exc:
        print(f"FAIL: {exc}")
        return 3

    if not exists:
        listing = _run(
            ["rclone", "lsf", destination, "--recursive", "--files-only"],
            check=False,
        )
        if listing.returncode or not listing.stdout.strip():
            payload = {
                "status": "already_deleted",
                "workstream": workstream,
                "run_id": run_id,
                "dropbox_path": f"/{remote_root}/{workstream}/{run_id}/",
            }
            print("CUSTODIAN_VISUAL_REVIEW_CLEANUP_JSON:" + json.dumps(payload, sort_keys=True))
            return 0
        print("FAIL: review run exists without a readable manifest; refusing cleanup.")
        return 3

    assert manifest is not None
    if manifest.get("schema") != VISUAL_REVIEW_SCHEMA:
        print("FAIL: cleanup accepts only v2 visual-review manifests.")
        return 3
    if manifest.get("workstream") != workstream or manifest.get("run_id") != run_id:
        print("FAIL: manifest identity does not match requested workstream/run.")
        return 3
    retention = manifest.get("retention")
    if not isinstance(retention, dict):
        print("FAIL: v2 manifest is missing retention policy.")
        return 3
    if retention.get("policy") != DELETE_AFTER_REVIEW:
        print("FAIL: review evidence is marked for retention; refusing cleanup.")
        return 4

    try:
        _run(["rclone", "purge", destination], capture_output=False)
        verify = _run(
            ["rclone", "lsf", destination, "--recursive", "--files-only"],
            check=False,
        )
        if verify.returncode == 0 and verify.stdout.strip():
            print("FAIL: review run still contains files after purge.")
            return 5

        latest, latest_exists = _remote_json(latest_destination)
        latest_cleared = False
        if latest_exists and latest is not None:
            if latest.get("workstream") == workstream and latest.get("run_id") == run_id:
                _run(["rclone", "deletefile", latest_destination], capture_output=False)
                latest_cleared = True
    except (subprocess.CalledProcessError, ValueError) as exc:
        print(f"FAIL: cleanup failed: {exc}")
        return 5

    payload = {
        "status": "deleted",
        "workstream": workstream,
        "run_id": run_id,
        "dropbox_path": f"/{remote_root}/{workstream}/{run_id}/",
        "latest_cleared": latest_cleared,
    }
    print("CUSTODIAN_VISUAL_REVIEW_CLEANUP_JSON:" + json.dumps(payload, sort_keys=True))
    return 0


def _unique_files(paths: Iterable[Path]) -> list[Path]:
    seen: set[Path] = set()
    output: list[Path] = []
    for path in paths:
        if not path.is_file():
            continue
        resolved = path.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        output.append(path)
    return output


def _sample_evenly(paths: list[Path], limit: int) -> list[Path]:
    if limit <= 0:
        return []
    if len(paths) <= limit:
        return paths
    if limit == 1:
        return [paths[len(paths) // 2]]
    indices = {
        round(i * (len(paths) - 1) / (limit - 1))
        for i in range(limit)
    }
    return [paths[index] for index in sorted(indices)]


def discover_artifacts(
    source: Path,
    *,
    max_keyframes: int = DEFAULT_MAX_KEYFRAMES,
    include_video: bool = False,
) -> list[Path]:
    """Select compact review surfaces from a Moment Forge/report directory."""
    if source.is_file():
        return [source]
    if not source.is_dir():
        raise FileNotFoundError(source)

    selected: list[Path] = []

    for pattern in PREFERRED_IMAGE_PATTERNS:
        selected.extend(sorted(source.rglob(pattern)))

    keyframes = sorted(
        path
        for path in source.rglob("*.png")
        if "keyframes" in {part.lower() for part in path.parts}
    )
    selected.extend(_sample_evenly(keyframes, max_keyframes))

    for name in METADATA_NAMES:
        selected.extend(sorted(source.rglob(name)))

    if include_video:
        videos = sorted(source.rglob("*.mp4"))
        if videos:
            selected.append(videos[0])

    return _unique_files(selected)


def resolve_remote(explicit: str | None, env: dict[str, str] | None = None) -> str:
    """Resolve the rclone remote without reading or storing credentials.

    Resolution intentionally favors explicit configuration, then a conventional
    exact `dropbox:` remote, then one unambiguous configured remote whose name
    contains `dropbox`. That last rule keeps existing user remotes such as
    `git-dropbox-sync:` zero-config without guessing when multiple Dropbox-like
    remotes exist.
    """
    return dropbox_transport.resolve_remote(
        explicit,
        env,
        env_precedence=("CUSTODIAN_REVIEW_REMOTE",),
        runner=_run,
    )


def _remote_path(remote: str, remote_root: str, *parts: str) -> str:
    return dropbox_transport.remote_path(remote, remote_root, *parts)


def _safe_name(path: Path, used: set[str]) -> str:
    candidate = path.name
    if candidate not in used:
        used.add(candidate)
        return candidate
    stem, suffix = path.stem, path.suffix
    index = 2
    while f"{stem}_{index}{suffix}" in used:
        index += 1
    candidate = f"{stem}_{index}{suffix}"
    used.add(candidate)
    return candidate


def _stage_bundle(files: list[Path], staging: Path) -> list[dict[str, object]]:
    artifacts_dir = staging / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    used: set[str] = set()
    records: list[dict[str, object]] = []
    for source in files:
        name = _safe_name(source, used)
        destination = artifacts_dir / name
        shutil.copy2(source, destination)
        records.append(
            {
                "name": name,
                "source_path": str(source.resolve()),
                "size_bytes": destination.stat().st_size,
                "sha256": _sha256(destination),
            }
        )
    return records


def doctor(remote: str, remote_root: str, *, ensure_root: bool) -> int:
    """Check the rclone remote and optionally create the review root."""
    try:
        _run(["rclone", "lsd", remote])
    except FileNotFoundError:
        print("FAIL: rclone is not installed.")
        return 2
    except subprocess.CalledProcessError:
        print(f"FAIL: rclone cannot access {remote}")
        return 3

    root = _remote_path(remote, remote_root)
    if ensure_root:
        try:
            _run(["rclone", "mkdir", root])
        except subprocess.CalledProcessError:
            print(f"FAIL: could not create/access review root {root}")
            return 4

    try:
        _run(["rclone", "lsf", root, "--max-depth", "1"])
    except subprocess.CalledProcessError:
        if ensure_root:
            print(f"FAIL: review root is not readable after creation: {root}")
            return 5
        print(
            f"REMOTE OK: {remote}\n"
            f"Review root is not readable yet: {root}\n"
            "Run again with --doctor --ensure-root to create it."
        )
        return 0

    print(f"REMOTE OK: {remote}")
    print(f"REVIEW ROOT OK: {root}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Publish important CUSTODIAN visual-review evidence through rclone."
    )
    parser.add_argument("--doctor", action="store_true", help="Check rclone/remote access and exit.")
    parser.add_argument(
        "--ensure-root",
        action="store_true",
        help="With --doctor, create the configured review root when missing.",
    )
    parser.add_argument("--important", action="store_true", help="Required gate for an actual upload.")
    parser.add_argument(
        "--cleanup-reviewed",
        action="store_true",
        help="Delete exactly one reviewed v2 run when its manifest policy permits cleanup.",
    )
    parser.add_argument("--reason", help="Why subjective human/ChatGPT visual review is warranted.")
    parser.add_argument("--workstream", help="Stable lowercase kebab-case Workstream ID.")
    parser.add_argument("--source", type=Path, help="Moment Forge/report directory or one file.")
    parser.add_argument(
        "--artifact",
        type=Path,
        action="append",
        default=[],
        help="Additional explicit artifact. Repeat as needed.",
    )
    parser.add_argument(
        "--question",
        action="append",
        default=[],
        help="Specific question for the external visual reviewer. Repeat as needed.",
    )
    parser.add_argument("--scenario", default="", help="Optional Moment Forge scenario id/context.")
    parser.add_argument(
        "--authoring-chat",
        help="Exact ChatGPT authoring/review chat URL; defaults to packet metadata.",
    )
    parser.add_argument(
        "--retain-after-review",
        action="store_true",
        help="Retain this review bundle after review instead of the default delete-after-review policy.",
    )
    parser.add_argument("--remote", help="rclone remote, e.g. dropbox:.")
    parser.add_argument("--remote-root", default=DEFAULT_REMOTE_ROOT)
    parser.add_argument("--run-id", help="Optional conservative path-safe run id override.")
    parser.add_argument("--max-files", type=int, default=DEFAULT_MAX_FILES)
    parser.add_argument("--max-mib", type=float, default=DEFAULT_MAX_MIB)
    parser.add_argument("--max-keyframes", type=int, default=DEFAULT_MAX_KEYFRAMES)
    parser.add_argument(
        "--include-video",
        action="store_true",
        help="Allow one MP4 only when motion/timing/game feel requires it.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Build manifest and selection without uploading.")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    # The opt-in gate is intentionally evaluated before any rclone discovery so
    # routine agent runs do not touch provider configuration or fail merely
    # because external review is unnecessary.
    if not args.doctor and not args.important and not args.cleanup_reviewed:
        print(
            "SKIP: review artifact publication is opt-in. "
            "Re-run with --important --reason only when objective validation cannot "
            "settle a meaningful subjective visual question."
        )
        return 0

    try:
        remote = resolve_remote(args.remote)
    except RuntimeError as exc:
        print(f"FAIL: {exc}")
        return 2

    if shutil.which("rclone") is None:
        print("FAIL: rclone is not installed or not on PATH.")
        return 2

    if args.doctor:
        return doctor(remote, args.remote_root, ensure_root=args.ensure_root)

    if args.cleanup_reviewed:
        if not args.workstream or not args.run_id:
            print("FAIL: --cleanup-reviewed requires --workstream and --run-id.")
            return 2
        return cleanup_reviewed(remote, args.remote_root, args.workstream, args.run_id)

    if not args.reason or not args.reason.strip():
        print("FAIL: --important requires --reason.")
        return 2
    if not args.workstream or not args.source:
        print("FAIL: upload mode requires --workstream and --source.")
        return 2
    if args.max_files < 1 or args.max_keyframes < 0 or args.max_mib <= 0:
        print("FAIL: invalid review bundle limits.")
        return 2

    try:
        workstream = _slug(args.workstream, "workstream")
    except ValueError as exc:
        print(f"FAIL: {exc}")
        return 2

    repo = _repo_root()
    try:
        authoring_chat = _validate_authoring_chat(
            args.authoring_chat or _packet_authoring_chat(repo, workstream)
        )
    except ValueError as exc:
        print(f"FAIL: {exc}")
        return 2
    retention_policy = RETAIN_AFTER_REVIEW if args.retain_after_review else DELETE_AFTER_REVIEW
    source = args.source if args.source.is_absolute() else repo / args.source
    explicit = [
        item if item.is_absolute() else repo / item
        for item in args.artifact
    ]

    try:
        selected = discover_artifacts(
            source,
            max_keyframes=args.max_keyframes,
            include_video=args.include_video,
        )
    except FileNotFoundError:
        print(f"FAIL: source does not exist: {source}")
        return 2
    selected.extend(path for path in explicit if path.is_file())
    selected = _unique_files(selected)[: args.max_files]
    if not selected:
        print("FAIL: no review artifacts found. Add --artifact paths or use a richer source directory.")
        return 2

    total_bytes = sum(path.stat().st_size for path in selected)
    max_bytes = int(args.max_mib * 1024 * 1024)
    if total_bytes > max_bytes:
        print(
            f"FAIL: selected bundle is {total_bytes / 1024 / 1024:.1f} MiB, "
            f"above the {args.max_mib:.1f} MiB cap."
        )
        return 2

    run_id = args.run_id or dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", run_id):
        print("FAIL: --run-id contains unsupported path characters.")
        return 2

    commit = _git_value(repo, "rev-parse", "HEAD", fallback="unknown")
    branch = _git_value(repo, "branch", "--show-current", fallback="detached")
    remote_root = args.remote_root.strip("/")
    destination = _remote_path(remote, remote_root, workstream, run_id)
    latest_destination = _remote_path(remote, remote_root, workstream, "LATEST.json")

    with tempfile.TemporaryDirectory(prefix="custodian-visual-review-") as temp:
        staging = Path(temp) / "review_bundle"
        staging.mkdir(parents=True)
        artifacts = _stage_bundle(selected, staging)
        manifest = {
            "schema": VISUAL_REVIEW_SCHEMA,
            "workstream": workstream,
            "run_id": run_id,
            "created_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
            "git": {"commit": commit, "branch": branch},
            "scenario": args.scenario.strip(),
            "reason": args.reason.strip(),
            "authoring_chat": authoring_chat,
            "questions": [question.strip() for question in args.question if question.strip()],
            "retention": {
                "policy": retention_policy,
                "cleanup_owner": "execution-agent",
            },
            "artifacts": artifacts,
            "limits": {
                "max_files": args.max_files,
                "max_bytes": max_bytes,
                "max_keyframes": args.max_keyframes,
                "include_video": bool(args.include_video),
            },
            "remote_relative_path": f"/{remote_root}/{workstream}/{run_id}/",
        }
        manifest_path = staging / "REVIEW_MANIFEST.json"
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

        if args.dry_run:
            payload = {
                "status": "dry_run",
                "remote": remote,
                "destination": destination,
                "manifest": manifest,
            }
            print("CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON:" + json.dumps(payload, sort_keys=True))
            return 0

        try:
            _run(
                [
                    "rclone",
                    "copy",
                    str(staging),
                    destination,
                    "--immutable",
                    "--checksum",
                    "--create-empty-src-dirs",
                ],
                capture_output=False,
            )
        except subprocess.CalledProcessError as exc:
            print(f"FAIL: rclone upload failed with exit {exc.returncode}.")
            return exc.returncode or 3

        latest = {
            "schema": LATEST_SCHEMA,
            "workstream": workstream,
            "run_id": run_id,
            "commit": commit,
            "manifest": f"/{remote_root}/{workstream}/{run_id}/REVIEW_MANIFEST.json",
            "updated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        }
        latest_path = Path(temp) / "LATEST.json"
        latest_path.write_text(json.dumps(latest, indent=2) + "\n", encoding="utf-8")
        try:
            _run(
                ["rclone", "copyto", str(latest_path), latest_destination, "--checksum"],
                capture_output=False,
            )
            verify = _run(["rclone", "lsf", destination, "--recursive", "--files-only"])
        except subprocess.CalledProcessError as exc:
            print(f"FAIL: upload verification/latest-pointer step failed with exit {exc.returncode}.")
            return exc.returncode or 4

        remote_files = {
            line.strip() for line in verify.stdout.splitlines() if line.strip()
        }
        if "REVIEW_MANIFEST.json" not in remote_files:
            print("FAIL: upload verification did not find REVIEW_MANIFEST.json.")
            return 5

        payload = {
            "status": "uploaded",
            "workstream": workstream,
            "run_id": run_id,
            "commit": commit,
            "branch": branch,
            "dropbox_path": f"/{remote_root}/{workstream}/{run_id}/",
            "manifest_path": f"/{remote_root}/{workstream}/{run_id}/REVIEW_MANIFEST.json",
            "latest_path": f"/{remote_root}/{workstream}/LATEST.json",
            "file_count": len(remote_files),
            "questions": manifest["questions"],
            "authoring_chat": authoring_chat,
            "visual_review_root": f"/{remote_root}/{workstream}/",
            "cleanup_policy": retention_policy,
            "cleanup_command": (
                "python3 custodian/tools/iteration/publish_review_artifacts.py "
                f"--cleanup-reviewed --workstream {workstream} --run-id {run_id}"
            ),
        }
        print("CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON:" + json.dumps(payload, sort_keys=True))
        print(
            "External review handoff: "
            f"open the authoring chat {authoring_chat}, review Dropbox "
            f"{payload['manifest_path']} and answer the listed questions. "
            "After the verdict reaches the execution agent, run the emitted cleanup command "
            "unless the manifest retention policy is retain."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
