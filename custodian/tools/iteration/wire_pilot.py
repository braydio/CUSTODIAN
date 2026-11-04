#!/usr/bin/env python3
"""Opt-in CUSTODIAN WIRE pilot: read-only observation -> private Dropbox readback.

No task packet claims, review runs, dispatcher mutations, public feed writes,
service installation, or schedule changes. Requires existing repo exporter and rclone.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from typing import Any

SCHEMA = "custodian.wire.observation.v1"
POINTER_SCHEMA = "custodian.wire.pilot.latest.v1"
DESTINATION = "CUSTODIAN/wire/operational_observations/v1"
MAX_BYTES = 16 * 1024 * 1024
POINTER_MAX_BYTES = 4096
SHA256 = re.compile(r"^[a-f0-9]{64}$")
REVISION = re.compile(r"^[a-f0-9]{40}$")
ISO_UTC = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")


class PilotError(RuntimeError):
    """Safe, non-secret status suitable for display."""


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def parse_timestamp(value: Any, *, strictly_utc: bool = False) -> datetime:
    if not isinstance(value, str):
        raise PilotError("missing or invalid timestamp")
    if strictly_utc and not ISO_UTC.fullmatch(value):
        raise PilotError("observation timestamp is not canonical UTC")
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise PilotError("missing or invalid timestamp") from exc
    if dt.tzinfo is None or dt.utcoffset() is None:
        raise PilotError("timestamp has no timezone")
    return dt.astimezone(timezone.utc)


def load_repo_module(repo: Path, name: str, relpath: str):
    path = (repo / relpath).resolve()
    if not path.is_file() or not path.is_relative_to(repo.resolve()):
        raise PilotError(f"required CUSTODIAN {name} module is unavailable")
    spec = importlib.util.spec_from_file_location(f"wire_pilot_{name}", path)
    if spec is None or spec.loader is None:
        raise PilotError(f"cannot load CUSTODIAN {name} module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def safe_json(raw: bytes, *, max_bytes: int = MAX_BYTES) -> Any:
    if len(raw) > max_bytes:
        raise PilotError("document exceeds size bound")
    def unique_keys(pairs):
        out = {}
        for k, v in pairs:
            if k in out:
                raise PilotError("duplicate JSON object key")
            out[k] = v
        return out
    def invalid_constant(_value):
        raise PilotError("non-finite JSON number")
    try:
        return json.loads(raw, object_pairs_hook=unique_keys, parse_constant=invalid_constant)
    except (ValueError, UnicodeDecodeError, RecursionError) as exc:
        raise PilotError("malformed JSON document") from exc


def canonical(document: Any) -> bytes:
    return (json.dumps(document, sort_keys=True, separators=(",", ":"),
                       ensure_ascii=True, allow_nan=False) + "\n").encode("ascii")


def content_sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def validate_observation(document: Any, exporter, *, now: datetime | None = None,
                         max_observation_age_seconds: int = 600) -> bytes:
    """Validate exact source schema, stable evidence digest, and fresh source times."""
    if not isinstance(document, dict) or document.get("schema") != SCHEMA:
        raise PilotError("input is not a sanitized CUSTODIAN WIRE observation")
    if not isinstance(max_observation_age_seconds, int) or max_observation_age_seconds < 1:
        raise PilotError("maximum observation age must be positive")
    try:
        exporter.validate_observation(document)
    except (ValueError, TypeError, KeyError, RecursionError) as exc:
        raise PilotError("observation violates the published strict schema") from exc
    digest = document.get("evidence_sha256")
    if not isinstance(digest, str) or not SHA256.fullmatch(digest):
        raise PilotError("observation evidence digest is missing")
    stable = {k: v for k, v in document.items()
              if k not in {"observed_at", "freshness", "evidence_sha256"}}
    if hashlib.sha256(json.dumps(stable, sort_keys=True, separators=(",", ":"),
                                 ensure_ascii=True).encode("ascii")).hexdigest() != digest:
        raise PilotError("observation evidence digest does not match")
    now = utc_now() if now is None else now.astimezone(timezone.utc)
    observed = parse_timestamp(document["observed_at"], strictly_utc=True)
    age = (now - observed).total_seconds()
    if not 0 <= age <= max_observation_age_seconds:
        raise PilotError("observation is stale or future-dated")
    if document.get("source_health") != {"snapshot": "ok", "dispatch": "ok",
                                         "recovery": "ok", "origin_main": "current"}:
        raise PilotError("source health is not complete/current")
    coverage = document["coverage"]
    if coverage.get("active_inventory") not in {"partial", "complete"}:
        raise PilotError("detailed inventory coverage is unsupported")
    if coverage.get("raw_dispatch_inventory") != "complete":
        raise PilotError("raw dispatcher inventory is not complete")
    if not isinstance(document.get("source_revision"), str) or not REVISION.fullmatch(document["source_revision"]):
        raise PilotError("source revision is invalid")
    stamps = document["source_timestamps"]
    freshness = document["freshness"]
    source_limit = document["max_source_age_seconds"]
    if type(source_limit) is not int or source_limit < 1 or freshness["max_source_age_seconds"] != source_limit:
        raise PilotError("source freshness bounds disagree")
    for stamp_key, age_key in (("snapshot_generated_utc", "snapshot_age_seconds"),
                               ("recovery_audit_generated_utc", "recovery_audit_age_seconds")):
        source_date = parse_timestamp(stamps[stamp_key])
        measured = (observed - source_date).total_seconds()
        if measured < 0 or measured > source_limit:
            raise PilotError("source evidence was stale when observed")
        if abs(int(measured) - freshness[age_key]) > 1:
            raise PilotError("source freshness metadata is inconsistent")
        current_age = (now - source_date).total_seconds()
        if current_age < 0 or current_age > max_observation_age_seconds + source_limit:
            raise PilotError("source evidence is no longer fresh enough for this pilot")
    if stamps["dispatcher_audit_generated_utc"] is not None or freshness["dispatcher_audit_age_seconds"] is not None:
        raise PilotError("unsupported dispatcher timestamp claim")
    raw = canonical(document)
    if len(raw) > MAX_BYTES:
        raise PilotError("sanitized observation exceeds size bound")
    return raw


def remote_root(remote: str) -> str:
    if not isinstance(remote, str) or not re.fullmatch(r"[A-Za-z0-9_.-]+:", remote):
        raise PilotError("invalid rclone remote name")
    return remote + DESTINATION


def rclone(args: list[str], *, allow_missing: bool = False, timeout: int = 120) -> bytes | None:
    try:
        run = subprocess.run(["rclone", *args], stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, check=False, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PilotError("rclone command unavailable, timed out, or could not connect") from exc
    if run.returncode:
        if allow_missing:
            # Only treat an explicit not-found report as missing. Any other error fails closed.
            stderr = run.stderr.decode("utf-8", "replace").lower()
            if any(item in stderr for item in ("not found", "directory not found", "object not found",
                                               "doesn't exist", "does not exist", "404")):
                return None
        raise PilotError("private rclone operation failed; check remote configuration/access")
    return run.stdout


def cat(remote_path: str, *, allow_missing: bool = False, max_bytes: int = MAX_BYTES) -> bytes | None:
    raw = rclone(["cat", remote_path], allow_missing=allow_missing, timeout=120)
    if raw is not None and len(raw) > max_bytes:
        raise PilotError("private remote document exceeds size bound")
    return raw


def upload_bytes(raw: bytes, destination: str) -> None:
    with tempfile.TemporaryDirectory(prefix="wire-pilot-") as temp:
        local = Path(temp) / "payload.json"
        local.write_bytes(raw)
        local.chmod(0o600)
        rclone(["copyto", str(local), destination], timeout=120)


def resolve_remote(repo: Path, explicit: str | None) -> str:
    helper = load_repo_module(repo, "dropbox_transport", "custodian/tools/iteration/dropbox_transport.py")
    try:
        value = helper.resolve_remote(explicit, env_precedence=("CUSTODIAN_WIRE_REMOTE",))
    except RuntimeError as exc:
        raise PilotError("no usable private rclone remote; configure Dropbox or pass --remote") from exc
    return value


def validate_pointer(pointer: Any) -> dict:
    if not isinstance(pointer, dict) or set(pointer) != {
        "schema", "observation_path", "content_sha256", "content_bytes",
        "evidence_sha256", "observed_at", "source_revision", "published_at"}:
        raise PilotError("latest pointer is not the expected pilot format")
    if pointer["schema"] != POINTER_SCHEMA:
        raise PilotError("latest pointer has the wrong schema")
    h = pointer["content_sha256"]
    ev = pointer["evidence_sha256"]
    if not isinstance(h, str) or not SHA256.fullmatch(h) or not isinstance(ev, str) or not SHA256.fullmatch(ev):
        raise PilotError("latest pointer contains an invalid digest")
    if pointer["observation_path"] != f"observations/{h}.json":
        raise PilotError("latest pointer references an unexpected destination")
    if type(pointer["content_bytes"]) is not int or not 0 < pointer["content_bytes"] <= MAX_BYTES:
        raise PilotError("latest pointer has an invalid size")
    if not isinstance(pointer["source_revision"], str) or not REVISION.fullmatch(pointer["source_revision"]):
        raise PilotError("latest pointer has an invalid source revision")
    parse_timestamp(pointer["observed_at"], strictly_utc=True)
    parse_timestamp(pointer["published_at"], strictly_utc=True)
    return pointer


def read_pointer(root: str, *, optional: bool = False) -> dict | None:
    raw = cat(root + "/latest.json", allow_missing=optional, max_bytes=POINTER_MAX_BYTES)
    if raw is None:
        return None
    return validate_pointer(safe_json(raw, max_bytes=POINTER_MAX_BYTES))


def read_verified(root: str, exporter, *, max_age: int, optional: bool = False):
    pointer = read_pointer(root, optional=optional)
    if pointer is None:
        return None
    path = root + "/" + pointer["observation_path"]
    raw = cat(path)
    if raw is None or len(raw) != pointer["content_bytes"] or content_sha(raw) != pointer["content_sha256"]:
        raise PilotError("latest referenced observation bytes do not match the pointer")
    doc = safe_json(raw)
    validate_observation(doc, exporter, max_observation_age_seconds=max_age)
    if (doc["evidence_sha256"] != pointer["evidence_sha256"] or
        doc["observed_at"] != pointer["observed_at"] or
        doc["source_revision"] != pointer["source_revision"]):
        raise PilotError("latest pointer metadata conflicts with observation")
    return pointer, doc


def publish(document: dict, exporter, remote: str, *, max_age: int = 600) -> dict:
    raw = validate_observation(document, exporter, max_observation_age_seconds=max_age)
    root = remote_root(remote)
    content_digest = content_sha(raw)
    target = root + "/observations/" + content_digest + ".json"
    old = read_pointer(root, optional=True)
    if old and old["evidence_sha256"] == document["evidence_sha256"]:
        # Verify referenced content, not merely untrusted pointer metadata.
        read_verified(root, exporter, max_age=max_age)
        return {"result": "unchanged", "sha256": old["content_sha256"],
                "observed_at": old["observed_at"], "source_revision": old["source_revision"]}
    existing = cat(target, allow_missing=True)
    if existing is not None and existing != raw:
        raise PilotError("immutable content address conflicts with existing remote content")
    if existing is None:
        upload_bytes(raw, target)
    readback = cat(target)
    if readback != raw:
        raise PilotError("versioned observation readback failed; latest pointer NOT updated")
    stamp = utc_now().isoformat(timespec="seconds").replace("+00:00", "Z")
    pointer = {
        "schema": POINTER_SCHEMA, "observation_path": f"observations/{content_digest}.json",
        "content_sha256": content_digest, "content_bytes": len(raw),
        "evidence_sha256": document["evidence_sha256"],
        "observed_at": document["observed_at"],
        "source_revision": document["source_revision"], "published_at": stamp,
    }
    pointer_raw = canonical(pointer)
    if len(pointer_raw) > POINTER_MAX_BYTES:
        raise PilotError("latest pointer exceeds size limit")
    # Stage+readback before moving. Rclone moveto is a single destination operation;
    # remote-specific overwrite atomicity is NOT guaranteed by this implementation.
    token = content_digest[:20] + "-" + os.urandom(8).hex()
    staged = root + "/staging/" + token + ".json"
    try:
        upload_bytes(pointer_raw, staged)
        if cat(staged, max_bytes=POINTER_MAX_BYTES) != pointer_raw:
            raise PilotError("staged pointer readback failed; latest pointer NOT updated")
        rclone(["moveto", staged, root + "/latest.json"])
    finally:
        try:
            rclone(["deletefile", staged], allow_missing=True, timeout=30)
        except PilotError:
            pass
    latest = read_pointer(root)
    if latest != pointer:
        raise PilotError("latest pointer did not verify after update")
    if cat(target) != raw:
        raise PilotError("observation readback changed unexpectedly")
    return {"result": "published", "sha256": content_digest,
            "observed_at": document["observed_at"],
            "source_revision": document["source_revision"]}


def observation_from_host(repo: Path, *, max_source_age: int) -> dict:
    # Call the *read-only collector* directly. Do not invoke `observe()`, which
    # writes local task-administrator event history, or any claim/review action.
    administrator = load_repo_module(repo, "task_administrator", "custodian/tools/agent/task_administrator.py")
    exporter = load_repo_module(repo, "wire_observation_export", "custodian/tools/agent/wire_observation_export.py")
    try:
        snap = administrator.collect(repo)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        raise PilotError("collector failed; run 'doctor' to inspect source availability") from exc
    try:
        return exporter.export_observation(snap, max_source_age_seconds=max_source_age)
    except exporter.ObservationError as exc:
        # Exporter messages are fixed, source-safe invariant descriptions; no raw
        # audit rows, paths, process ids, or private identifiers are printed.
        raise PilotError(f"exporter rejected source: {exc}; run 'doctor'") from exc
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        raise PilotError("source export failed; run 'doctor' for source checks") from exc


def doctor(repo: Path, *, max_source_age: int = 180) -> dict:
    """Read-only local source diagnostic. No Dropbox, no packet/ref modifications."""
    administrator = load_repo_module(repo, "task_administrator", "custodian/tools/agent/task_administrator.py")
    exporter = load_repo_module(repo, "wire_observation_export", "custodian/tools/agent/wire_observation_export.py")
    try:
        snap = administrator.collect(repo)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        return {"status": "blocked", "stage": "collector",
                "problem": "collector could not gather source audits",
                "next": "Run the dispatcher and recovery audit commands independently; do not bypass source checks"}
    if not isinstance(snap, dict):
        return {"status": "blocked", "stage": "collector",
                "problem": "collector returned an invalid source snapshot"}
    dispatch = snap.get("dispatch") if isinstance(snap.get("dispatch"), dict) else {}
    recovery = snap.get("recovery") if isinstance(snap.get("recovery"), dict) else {}
    health = snap.get("source_health") if isinstance(snap.get("source_health"), dict) else {}
    origin = snap.get("origin_main_evidence") if isinstance(snap.get("origin_main_evidence"), dict) else {}
    admin_packets = snap.get("packets")
    audited_packets = dispatch.get("packets")
    rev = snap.get("origin_main_sha")
    cached = origin.get("cached_sha")
    remote = origin.get("remote_sha")
    origin_current = (isinstance(rev, str) and len(rev) == 40 and
                      rev == cached == remote == recovery.get("cached_origin_main") == recovery.get("remote_main") and
                      health.get("origin_main") == "current")
    def short_ref(value):
        return value[:12] if isinstance(value, str) and REVISION.fullmatch(value) else "unavailable"
    def age(key):
        try:
            return round((utc_now() - parse_timestamp(recovery[key] if key == "generated_utc" else snap[key])).total_seconds())
        except (KeyError, ValueError, TypeError, PilotError):
            return None
    result = {
        "status": "blocked", "stage": "exporter", "network_upload": "not attempted",
        "source_health": {
            "dispatch": health.get("dispatch", "unknown"),
            "recovery": health.get("recovery", "unknown"),
            "origin_main": health.get("origin_main", "unknown"),
            "errors_count": len(health.get("errors", [])) if isinstance(health.get("errors"), list) else None,
        },
        "origin": {"cached": short_ref(cached), "remote": short_ref(remote),
                   "collector": short_ref(rev), "consistent": origin_current},
        "counts": {"dispatcher_packet_rows": len(audited_packets) if isinstance(audited_packets, list) else None,
                   "collector_packet_rows": len(admin_packets) if isinstance(admin_packets, list) else None,
                   "declared_raw_active": dispatch.get("raw_active_markdown_count"),
                   "declared_managed": dispatch.get("managed_packet_count")},
        "source_ages_seconds": {"snapshot": age("generated_utc"), "recovery": None},
        "recovery_contract": {"remote_query_read_only": recovery.get("remote_query_read_only"),
                              "git_fetch_performed": recovery.get("git_fetch_performed")},
    }
    try:
        result["source_ages_seconds"]["recovery"] = round((utc_now() - parse_timestamp(recovery["generated_utc"])).total_seconds())
    except (KeyError, ValueError, TypeError, PilotError):
        pass
    try:
        exporter.export_observation(snap, max_source_age_seconds=max_source_age)
        result["status"] = "ready"
        result["problem"] = "all source validation checks passed"
        result["next"] = "Run 'once' then 'verify' to publish and inspect private observations"
    except exporter.ObservationError as exc:
        result["problem"] = str(exc)
        if not origin_current and isinstance(remote, str) and REVISION.fullmatch(remote):
            result["next"] = "Run 'git fetch origin main' in the checkout (safe with uncommitted edits), then rerun 'doctor'"
        elif result["source_health"]["dispatch"] != "ok":
            result["next"] = "Run 'python3 custodian/tools/agent/dispatch.py audit --json >/dev/null' to inspect its exit status"
        elif result["source_health"]["recovery"] != "ok":
            result["next"] = "Run 'python3 custodian/tools/agent/workstream_recovery.py audit --json >/dev/null' to inspect its exit status"
        else:
            result["next"] = "Investigate the exact exporter invariant; do not weaken or bypass it"
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError):
        result["problem"] = "unexpected exporter failure"
        result["next"] = "Inspect collector and exporter locally without uploading a snapshot"
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="local CUSTODIAN checkout")
    parser.add_argument("--remote", default=None, help="existing private rclone remote name")
    parser.add_argument("--max-observation-age-seconds", type=int, default=600)
    sub = parser.add_subparsers(dest="action", required=True)
    once = sub.add_parser("once", help="collect read-only snapshot, sanitize and publish")
    once.add_argument("--max-source-age-seconds", type=int, default=180)
    diag = sub.add_parser("doctor", help="read-only diagnosis of the collector/exporter; never accesses Dropbox")
    diag.add_argument("--max-source-age-seconds", type=int, default=180)
    pub = sub.add_parser("publish", help="publish an existing sanitized observation")
    pub.add_argument("--input", type=Path, required=True)
    sub.add_parser("verify", help="read latest private observation and verify")
    args = parser.parse_args(argv)
    try:
        repo = args.repo.expanduser().resolve(strict=True)
        if args.action == "doctor":
            result = doctor(repo, max_source_age=args.max_source_age_seconds)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["status"] == "ready" else 2
        exporter = load_repo_module(repo, "wire_observation_export", "custodian/tools/agent/wire_observation_export.py")
        remote = resolve_remote(repo, args.remote)
        if args.action == "once":
            document = observation_from_host(repo, max_source_age=args.max_source_age_seconds)
            result = publish(document, exporter, remote, max_age=args.max_observation_age_seconds)
        elif args.action == "publish":
            if not args.input.is_file() or args.input.stat().st_size > MAX_BYTES:
                raise PilotError("input file missing or oversized")
            document = safe_json(args.input.read_bytes())
            result = publish(document, exporter, remote, max_age=args.max_observation_age_seconds)
        else:
            record = read_verified(remote_root(remote), exporter,
                                   max_age=args.max_observation_age_seconds)
            if record is None:
                raise PilotError("private latest observation is missing")
            pointer, document = record
            result = {"result": "verified", "sha256": pointer["content_sha256"],
                      "observed_at": document["observed_at"],
                      "source_revision": document["source_revision"],
                      "scope": document["scope"],
                      "classification_counts": document["classification_counts"],
                      "coverage": document["coverage"]}
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except PilotError as exc:
        print(f"wire-pilot: BLOCKED: {exc}", file=sys.stderr)
        return 2
    except (OSError, ValueError, TypeError) as exc:
        print("wire-pilot: BLOCKED: local configuration or input is invalid", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
