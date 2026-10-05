#!/usr/bin/env python3
"""Prepare and integrity-verify immutable implementation inputs from Dropbox."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shutil
import tempfile
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit

import dropbox_transport


REMOTE_ROOT = "CUSTODIAN/implementation_inputs"
MANIFEST_NAME = "HANDOFF_MANIFEST.json"
SCHEMA = "custodian.implementation_handoff.v1"
DEFAULT_MAX_BYTES = 256 * 1024 * 1024
MAX_MANIFEST_BYTES = 1024 * 1024
MAX_PURPOSE_CHARS = 280
MAX_PATH_CHARS = 1024
WORKSTREAM_RE = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")
HANDOFF_ID_RE = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")


def _run(args: list[str], *, check: bool = True, capture_output: bool = True):
    return dropbox_transport.run(args, check=check, capture_output=capture_output)


def _resolve_remote(explicit: str | None, env: dict[str, str] | None = None) -> str:
    return dropbox_transport.resolve_remote(
        explicit,
        env,
        env_precedence=("CUSTODIAN_IMPLEMENTATION_REMOTE", "CUSTODIAN_REVIEW_REMOTE"),
        runner=_run,
    )


def _slug(value: str, field: str, pattern: re.Pattern[str]) -> str:
    if not isinstance(value, str) or not pattern.fullmatch(value):
        raise ValueError(f"{field} must be lowercase kebab-case")
    return value


def _remote_path(remote: str, *parts: str) -> str:
    return dropbox_transport.remote_path(remote, REMOTE_ROOT, *parts)


def _json_command(args: list[str]) -> object:
    result = _run(args)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise ValueError("rclone returned malformed JSON") from exc


def doctor(remote: str, *, ensure_root: bool) -> int:
    try:
        _run(["rclone", "lsd", remote])
    except FileNotFoundError:
        print("FAIL: rclone is not installed.")
        return 2
    except Exception:
        print("FAIL: rclone cannot access the configured remote.")
        return 3

    root = _remote_path(remote)
    if ensure_root:
        try:
            _run(["rclone", "mkdir", root])
        except Exception:
            print("FAIL: could not create/access the implementation-input root.")
            return 4

    try:
        _run(["rclone", "lsf", root, "--max-depth", "1"])
    except Exception:
        if ensure_root:
            print("FAIL: implementation-input root is not readable after creation.")
            return 5
        print("REMOTE OK; implementation-input root is not readable yet.")
        print("Run doctor --ensure-root to create it.")
        return 0

    print(f"REMOTE OK: {remote}")
    print(f"IMPLEMENTATION INPUT ROOT OK: /{REMOTE_ROOT}/")
    return 0


def _lsjson_entries(value: object) -> list[dict[str, object]]:
    if not isinstance(value, list) or any(not isinstance(row, dict) for row in value):
        raise ValueError("rclone returned an unexpected listing")
    return value  # type: ignore[return-value]


def _entry_path(row: dict[str, object]) -> str:
    value = row.get("Path")
    if not isinstance(value, str) or not value:
        raise ValueError("rclone listing omitted a file path")
    return value


def prepare(remote: str, workstream: str, handoff_id: str) -> int:
    try:
        workstream = _slug(workstream, "workstream", WORKSTREAM_RE)
        handoff_id = _slug(handoff_id, "handoff_id", HANDOFF_ID_RE)
    except ValueError as exc:
        print(f"FAIL: {exc}")
        return 2

    root = _remote_path(remote)
    workstream_root = _remote_path(remote, workstream)
    handoff_root = _remote_path(remote, workstream, handoff_id)
    try:
        _run(["rclone", "mkdir", root])
        _run(["rclone", "mkdir", workstream_root])
        children = _lsjson_entries(_json_command(["rclone", "lsjson", workstream_root]))
        if any(_entry_path(row).casefold() == handoff_id.casefold() for row in children):
            print("FAIL: handoff ID already exists; handoffs are immutable.")
            return 3

        _run(["rclone", "mkdir", f"{handoff_root}/payload"])
        created = _lsjson_entries(
            _json_command(["rclone", "lsjson", handoff_root, "--recursive", "--files-only"])
        )
        if created:
            _run(["rclone", "rmdir", handoff_root])
            print("FAIL: prepared handoff was not empty; refusing to reuse it.")
            return 4
    except FileNotFoundError:
        print("FAIL: rclone is not installed.")
        return 2
    except Exception:
        print("FAIL: could not safely prepare the requested remote handoff.")
        return 5

    payload = {
        "status": "prepared",
        "schema": SCHEMA,
        "workstream": workstream,
        "handoff_id": handoff_id,
        "remote_path": f"/{REMOTE_ROOT}/{workstream}/{handoff_id}/",
        "payload_path": f"/{REMOTE_ROOT}/{workstream}/{handoff_id}/payload/",
        "manifest_path": f"/{REMOTE_ROOT}/{workstream}/{handoff_id}/{MANIFEST_NAME}",
        "upload_order": ["payload files", MANIFEST_NAME],
    }
    print("CUSTODIAN_IMPLEMENTATION_HANDOFF_JSON:" + json.dumps(payload, sort_keys=True))
    return 0


def validate_manifest(
    value: object,
    *,
    expected_workstream: str,
    expected_handoff_id: str,
    max_bytes: int,
) -> list[dict[str, object]]:
    if not isinstance(value, dict):
        raise ValueError("manifest must be a JSON object")
    required = {"schema", "workstream", "handoff_id", "created_at_utc", "authoring_chat", "payloads"}
    if set(value) - required or required - set(value):
        raise ValueError("manifest has missing or unsupported fields")
    if value["schema"] != SCHEMA:
        raise ValueError("unsupported manifest schema")
    if value["workstream"] != expected_workstream or value["handoff_id"] != expected_handoff_id:
        raise ValueError("manifest identity does not match the requested handoff")

    created = value["created_at_utc"]
    if not isinstance(created, str):
        raise ValueError("created_at_utc must be an ISO-8601 UTC timestamp")
    try:
        created_at = dt.datetime.fromisoformat(created.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError("created_at_utc must be an ISO-8601 UTC timestamp") from exc
    if created_at.tzinfo is None or created_at.utcoffset() != dt.timedelta(0):
        raise ValueError("created_at_utc must use UTC")

    authoring_chat = value["authoring_chat"]
    if not isinstance(authoring_chat, str) or not authoring_chat.strip():
        raise ValueError("authoring_chat must be a URL, not-recorded, or n/a")
    if authoring_chat not in {"not-recorded", "n/a"}:
        parsed = urlsplit(authoring_chat)
        if parsed.scheme != "https" or not parsed.netloc or parsed.username or parsed.password:
            raise ValueError("authoring_chat must be an HTTPS URL, not-recorded, or n/a")

    payloads = value["payloads"]
    if not isinstance(payloads, list) or not payloads:
        raise ValueError("payloads must be a non-empty array")
    records: list[dict[str, object]] = []
    seen: set[str] = set()
    total_bytes = 0
    for item in payloads:
        allowed = {"path", "size_bytes", "sha256", "purpose", "mime_type"}
        required_item = {"path", "size_bytes", "sha256", "purpose"}
        if not isinstance(item, dict) or required_item - set(item) or set(item) - allowed:
            raise ValueError("payload record has missing or unsupported fields")
        path_value = item["path"]
        if (
            not isinstance(path_value, str)
            or len(path_value) > MAX_PATH_CHARS
            or "\\" in path_value
            or "\x00" in path_value
        ):
            raise ValueError("payload path is malformed")
        path = PurePosixPath(path_value)
        if path.is_absolute() or path_value != path.as_posix() or not path_value.startswith("payload/"):
            raise ValueError("payload path must be a normalized relative path under payload/")
        components = path.parts
        if len(components) < 2 or any(
            part in {"", ".", ".."} or ":" in part or part.endswith((".", " "))
            for part in components
        ):
            raise ValueError("payload path contains an unsafe component")
        normalized = path_value.casefold()
        if normalized in seen:
            raise ValueError("duplicate or case-colliding payload path")
        if any(existing.startswith(normalized + "/") or normalized.startswith(existing + "/") for existing in seen):
            raise ValueError("payload paths contain a file/directory collision")
        seen.add(normalized)

        size = item["size_bytes"]
        if type(size) is not int or size < 0:
            raise ValueError("size_bytes must be a non-negative integer")
        digest = item["sha256"]
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
            raise ValueError("sha256 must be 64 lowercase hexadecimal characters")
        purpose = item["purpose"]
        if not isinstance(purpose, str) or not purpose.strip() or len(purpose) > MAX_PURPOSE_CHARS:
            raise ValueError("purpose must be a short non-empty string")
        mime_type = item.get("mime_type")
        if mime_type is not None and (not isinstance(mime_type, str) or len(mime_type) > 128):
            raise ValueError("mime_type must be a short string when provided")

        total_bytes += size
        if total_bytes > max_bytes:
            raise ValueError("declared payload size exceeds the configured limit")
        record = {"path": path_value, "size_bytes": size, "sha256": digest, "purpose": purpose.strip()}
        if mime_type is not None:
            record["mime_type"] = mime_type
        records.append(record)
    return records


def _default_staging_root() -> Path:
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")).expanduser()
    return cache_home / "custodian" / "implementation_inputs"


def _final_destination(staging_root: Path, repo_root: Path, workstream: str, handoff_id: str) -> Path:
    root = staging_root.expanduser().resolve()
    repo = repo_root.resolve()
    try:
        root.relative_to(repo)
    except ValueError:
        pass
    else:
        raise ValueError("staging root must be outside the CUSTODIAN checkout")
    final = root / workstream / handoff_id
    if os.path.lexists(final):
        raise FileExistsError("staging destination already exists")
    return final


def fetch(
    remote: str,
    workstream: str,
    handoff_id: str,
    *,
    staging_root: Path,
    max_bytes: int,
    repo_root: Path,
) -> int:
    try:
        workstream = _slug(workstream, "workstream", WORKSTREAM_RE)
        handoff_id = _slug(handoff_id, "handoff_id", HANDOFF_ID_RE)
        if type(max_bytes) is not int or max_bytes <= 0:
            raise ValueError("max_bytes must be a positive integer")
        final = _final_destination(staging_root, repo_root, workstream, handoff_id)
    except (ValueError, FileExistsError) as exc:
        print(f"FAIL: {exc}")
        return 2

    remote_handoff = _remote_path(remote, workstream, handoff_id)
    remote_manifest = f"{remote_handoff}/{MANIFEST_NAME}"
    try:
        manifest_stat = _json_command(["rclone", "lsjson", remote_manifest, "--stat"])
        if not isinstance(manifest_stat, dict):
            raise ValueError("rclone returned an unexpected manifest stat")
        manifest_size = manifest_stat.get("Size")
        if type(manifest_size) is not int or manifest_size < 1 or manifest_size > MAX_MANIFEST_BYTES:
            raise ValueError("remote manifest is empty or exceeds the 1 MiB limit")
        manifest_result = _run(["rclone", "cat", remote_manifest])
        manifest_bytes = manifest_result.stdout.encode("utf-8")
        if len(manifest_bytes) != manifest_size:
            raise ValueError("remote manifest size changed while fetching")
        manifest = json.loads(manifest_bytes.decode("utf-8"))
        payloads = validate_manifest(
            manifest,
            expected_workstream=workstream,
            expected_handoff_id=handoff_id,
            max_bytes=max_bytes,
        )
        listing = _lsjson_entries(
            _json_command(["rclone", "lsjson", remote_handoff, "--recursive", "--files-only"])
        )
        remote_files = {_entry_path(row) for row in listing}
        declared_files = {record["path"] for record in payloads}
        expected_files = declared_files | {MANIFEST_NAME}
        if remote_files != expected_files:
            raise ValueError("remote handoff file set does not exactly match its manifest")
        listed_sizes = {_entry_path(row): row.get("Size") for row in listing}
        if listed_sizes.get(MANIFEST_NAME) != len(manifest_bytes):
            raise ValueError("remote manifest size changed while fetching")
        for record in payloads:
            if listed_sizes.get(record["path"]) != record["size_bytes"]:
                raise ValueError(f"remote size does not match manifest for {record['path']}")
    except FileNotFoundError:
        print("FAIL: rclone is not installed.")
        return 3
    except Exception as exc:
        print(f"FAIL: handoff manifest/listing rejected: {exc}")
        return 4

    parent = final.parent
    temporary: Path | None = None
    try:
        parent.mkdir(parents=True, exist_ok=True)
        resolved_parent = parent.resolve()
        if not resolved_parent.is_relative_to(staging_root.expanduser().resolve()):
            raise ValueError("staging parent escapes the configured staging root")
        if os.path.lexists(final):
            raise FileExistsError("staging destination already exists")
        temporary = Path(tempfile.mkdtemp(prefix=f".{handoff_id}-", dir=resolved_parent))
        (temporary / MANIFEST_NAME).write_bytes(manifest_bytes)
        for record in payloads:
            relative = PurePosixPath(str(record["path"]))
            destination = temporary.joinpath(*relative.parts)
            destination.parent.mkdir(parents=True, exist_ok=True)
            _run(
                ["rclone", "copyto", f"{remote_handoff}/{record['path']}", str(destination)],
                capture_output=False,
            )
            if not destination.is_file() or destination.is_symlink():
                raise ValueError(f"download did not produce a regular file: {record['path']}")
            if destination.stat().st_size != record["size_bytes"]:
                raise ValueError(f"downloaded size mismatch: {record['path']}")
            if dropbox_transport.sha256_file(destination) != record["sha256"]:
                raise ValueError(f"downloaded SHA-256 mismatch: {record['path']}")
        if os.path.lexists(final):
            raise FileExistsError("staging destination appeared during fetch")
        os.rename(temporary, final)
        temporary = None
    except Exception as exc:
        print(f"FAIL: verified staging was not exposed: {exc}")
        return 5
    finally:
        if temporary is not None:
            shutil.rmtree(temporary, ignore_errors=True)

    payload = {
        "status": "fetched",
        "schema": SCHEMA,
        "workstream": workstream,
        "handoff_id": handoff_id,
        "remote_path": f"/{REMOTE_ROOT}/{workstream}/{handoff_id}/",
        "local_path": str(final),
        "payloads": [
            {"path": item["path"], "size_bytes": item["size_bytes"], "sha256": item["sha256"]}
            for item in payloads
        ],
        "extracted": False,
    }
    print("CUSTODIAN_IMPLEMENTATION_HANDOFF_JSON:" + json.dumps(payload, sort_keys=True))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Prepare and verify immutable CUSTODIAN implementation handoffs through rclone."
    )
    parser.add_argument("--remote", help="rclone remote; otherwise resolve from environment/config.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    doctor_parser = subparsers.add_parser("doctor", help="Check access to the canonical inbound root.")
    doctor_parser.add_argument("--ensure-root", action="store_true", help="Create the root when absent.")
    prepare_parser = subparsers.add_parser("prepare", help="Create a new immutable handoff payload folder.")
    prepare_parser.add_argument("--workstream", required=True)
    prepare_parser.add_argument("--handoff-id", required=True)
    fetch_parser = subparsers.add_parser("fetch", help="Verify a remote handoff into local staging.")
    fetch_parser.add_argument("--workstream", required=True)
    fetch_parser.add_argument("--handoff-id", required=True)
    fetch_parser.add_argument("--staging-root", type=Path, default=_default_staging_root())
    fetch_parser.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        remote = _resolve_remote(args.remote)
    except RuntimeError as exc:
        print(f"FAIL: {exc}")
        return 2
    if shutil.which("rclone") is None:
        print("FAIL: rclone is not installed or not on PATH.")
        return 2
    if args.command == "doctor":
        return doctor(remote, ensure_root=args.ensure_root)
    if args.command == "prepare":
        return prepare(remote, args.workstream, args.handoff_id)
    repo_root = Path(__file__).resolve().parents[3]
    return fetch(
        remote,
        args.workstream,
        args.handoff_id,
        staging_root=args.staging_root,
        max_bytes=args.max_bytes,
        repo_root=repo_root,
    )


if __name__ == "__main__":
    raise SystemExit(main())
