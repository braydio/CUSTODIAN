#!/usr/bin/env python3
"""Persistent, read-only CUSTODIAN task observer and bounded reasoning operator.

The observer consumes existing lifecycle authorities. It never claims, resumes,
parks, lands, reviews, or removes work. State is private Git-common-dir data.
"""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import signal
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "custodian.task_admin.snapshot.v1"
EVENT_SCHEMA = "custodian.task_admin.event.v1"
MAX_OUTPUT = 8 * 1024 * 1024
MAX_TURNS_PER_POLL = 1
MAX_TURNS_PER_DAY = 3
ALLOWED_ACTIONS = {"INSPECT", "DIAGNOSE", "ESCALATE", "HALT"}


class ObserverError(RuntimeError):
    pass


def _git(repo: Path, *args: str) -> str:
    p = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, timeout=30)
    if p.returncode:
        raise ObserverError("git metadata unavailable")
    return p.stdout.strip()


def common_dir(repo: Path) -> Path:
    path = Path(_git(repo, "rev-parse", "--git-common-dir"))
    return (repo / path).resolve() if not path.is_absolute() else path.resolve()


def private_store(repo: Path) -> Path:
    root = common_dir(repo) / "custodian-task-admin" / "v1"
    current = common_dir(repo)
    for part in ("custodian-task-admin", "v1"):
        current = current / part
        if current.is_symlink():
            raise ObserverError("private store path contains a symlink")
        current.mkdir(mode=0o700, exist_ok=True)
        os.chmod(current, 0o700)
    if not root.resolve().is_relative_to(common_dir(repo)):
        raise ObserverError("private store escaped Git common directory")
    return root


def _command(repo: Path, *args: str, timeout: int = 90) -> tuple[int, str, str]:
    p = subprocess.run([sys.executable, *args], cwd=repo, text=True,
                       capture_output=True, timeout=timeout)
    if len(p.stdout) > MAX_OUTPUT or len(p.stderr) > MAX_OUTPUT:
        return 125, "", "source output exceeded limit"
    return p.returncode, p.stdout, p.stderr[-4000:]


def _json_command(repo: Path, *args: str) -> tuple[dict | None, str | None]:
    code, stdout, _ = _command(repo, *args)
    if code:
        return None, "source command failed"
    try:
        value = json.loads(stdout)
    except (ValueError, TypeError):
        return None, "source returned invalid JSON"
    return (value, None) if isinstance(value, dict) else (None, "source JSON was not an object")


def collect(repo: Path) -> dict:
    """Build one current evidence snapshot; never fetch or mutate Git refs."""
    repo = Path(_git(repo, "rev-parse", "--show-toplevel")).resolve()
    dispatch, de = _json_command(repo, "custodian/tools/agent/dispatch.py", "audit", "--json")
    recovery, re = _json_command(repo, "custodian/tools/agent/workstream_recovery.py", "audit", "--json")
    disk, _ = _json_command(repo, "custodian/tools/agent/transient_worktree_gc.py", "--repo", str(repo), "--limit", "32")
    # The GC utility's read-only inventory is its default mode.
    try:
        st = os.statvfs(repo)
        total, free = st.f_blocks * st.f_frsize, st.f_bavail * st.f_frsize
        disk_pressure = {"total_bytes": total, "available_bytes": free,
                         "used_percent": round(100 * (total - free) / total, 2) if total else None,
                         "severity": "critical" if total and free / total < .05 else
                                     "high" if total and free / total < .10 else "normal"}
    except OSError:
        disk_pressure = {"severity": "unknown", "available_bytes": None}
    categories = {}
    registry_version = None
    registry_path = repo / "custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json"
    try:
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
        registry_version = registry.get("schema")
        categories = {x["id"]: x["label"] for x in registry["categories"]}
    except (OSError, ValueError, KeyError, TypeError):
        pass
    packets = (dispatch or {}).get("packets", [])
    if not isinstance(packets, list):
        packets = []
        de = de or "dispatcher packet list unavailable"
    recovery_items = (recovery or {}).get("items", [])
    recovery_by_id = {}
    for entry in recovery_items if isinstance(recovery_items, list) else []:
        if isinstance(entry, dict) and isinstance(entry.get("workstream"), str):
            recovery_by_id.setdefault(entry["workstream"], []).append(entry)
    rows = []
    dispatch_by_id = {x.get("workstream"): x for x in packets if isinstance(x, dict) and x.get("workstream")}
    for item in packets:
        if not isinstance(item, dict):
            continue
        wid = item.get("workstream")
        if not isinstance(wid, str):
            continue
        path = item.get("path")
        packet = {}
        if isinstance(path, str) and ".." not in Path(path).parts:
            try:
                raw = (repo / path).read_text(encoding="utf-8")
                for line in raw.splitlines()[:40]:
                    if line.startswith("- Category:"):
                        packet["category_id"] = line.partition(":")[2].strip().strip("`")
                    elif line.startswith("- Authoring chat:"):
                        packet["authoring_chat"] = line.partition(":")[2].strip().strip("`")
                    elif line.startswith("- Priority:"):
                        packet["priority"] = line.partition(":")[2].strip().strip("`")
                    elif line.startswith("- Paired review workstream:"):
                        packet["review_workstream"] = line.partition(":")[2].strip().strip("`")
            except OSError:
                pass
        cat = packet.get("category_id")
        observations = recovery_by_id.get(wid, [])
        process_rows = [{"classification": x.get("classification"),
                         "live_processes": x.get("live_processes"),
                         "process_scan_complete": x.get("process_scan_complete"),
                         "evidence_gap": x.get("evidence_gap")}
                        for x in observations]
        classification = item.get("actual_class")
        phase = ("correction" if "correction" in wid else "review" if "review" in wid
                 else "claimed" if item.get("claimed") else "implementation")
        review_id = packet.get("review_workstream")
        review_row = dispatch_by_id.get(review_id, {}) if review_id else {}
        review_observations = recovery_by_id.get(review_id, []) if review_id else []
        rows.append({"workstream": wid, "packet": path,
                     "category_id": cat if cat in categories else None,
                     "category_label": categories.get(cat, "Uncategorized"),
                     "category_registry": registry_version,
                     "priority": packet.get("priority", item.get("priority")),
                     "campaign_order": None,
                     "eligibility": "eligible" if item.get("claim_next_eligible") else "blocked",
                     "reasons": item.get("reasons", []),
                     "classification": classification, "phase": phase,
                     "claimed": bool(item.get("claimed")),
                     "process_evidence": process_rows or "UNKNOWN",
                     "review_workstream": review_id,
                     "review_eligibility": review_row.get("claim_next_eligible"),
                     "review_dispatch_reasons": review_row.get("reasons", []),
                     "review_outcomes": [x.get("classification") for x in review_observations],
                     "authoring_chat": packet.get("authoring_chat"),
                     "links": {"branch": item.get("branch"), "review": packet.get("review_workstream")}})
    frontier = None
    if dispatch is not None:
        try:
            from custodian.tools.agent.queue_frontier import analyze
            frontier = analyze(dispatch)
        except (ImportError, ValueError, KeyError, TypeError):
            frontier = None
    try:
        main_sha = _git(repo, "rev-parse", "refs/remotes/origin/main")
    except ObserverError:
        main_sha = None
    cached_main = (recovery or {}).get("cached_origin_main")
    remote_main = (recovery or {}).get("remote_main")
    origin_health = "current" if cached_main and remote_main and cached_main == remote_main else "stale_or_unknown"
    payload = {"schema": SCHEMA, "revision": 1,
        "generated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "repo": str(repo), "origin_main_sha": main_sha,
        "origin_main_evidence": {"cached_sha": cached_main, "remote_sha": remote_main,
                                 "freshness": origin_health},
        "source_health": {"dispatch": "ok" if dispatch is not None else "unknown",
                           "recovery": "ok" if recovery is not None else "unknown",
                           "origin_main": origin_health,
                           "errors": [x for x in (de, re) if x]},
        "dispatch": dispatch, "recovery": recovery, "queue_frontier": frontier,
        "disk": {"pressure": disk_pressure,
                 "retirement": disk if disk is not None else {"status": "unknown", "eligible": [], "blocked": []}},
        "packets": sorted(rows, key=lambda x: x["workstream"]),
        "process_evidence": "per-workstream recovery evidence; absence remains UNKNOWN",
        "mutation_authority": "none"}
    return payload


def _event_path(repo: Path) -> Path:
    return private_store(repo) / "events.jsonl"


def acquire_observer_lock(repo: Path) -> int:
    path = private_store(repo) / "observer.lock"
    fd = os.open(path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as exc:
        os.close(fd)
        raise ObserverError("another task administrator observer is already running") from exc
    return fd


def _read_events(path: Path) -> list[dict]:
    if not path.exists():
        return []
    if path.is_symlink() or path.stat().st_mode & 0o077:
        raise ObserverError("event ledger is not private or is a symlink")
    events, previous = [], "0" * 64
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        event = json.loads(line)
        digest = event.pop("event_sha256", None)
        if event.get("sequence") != n or event.get("previous_sha256") != previous:
            raise ObserverError("event ledger sequence/hash chain is corrupt")
        expected = hashlib.sha256(json.dumps(event, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        if digest != expected or event.get("schema") != EVENT_SCHEMA:
            raise ObserverError("event ledger digest/schema is corrupt")
        event["event_sha256"] = digest
        events.append(event); previous = digest
    return events


def _stable_evidence(value):
    """Strip clock-only fields so unchanged polls deduplicate across time."""
    volatile = {"generated_utc", "generated_at", "timestamp_utc", "observed_at", "checked_at"}
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            if key in volatile or key == "used_percent":
                continue
            if key == "available_bytes" and isinstance(item, int):
                item = (item // (1024 ** 3)) * (1024 ** 3)
            result[key] = _stable_evidence(item)
        return result
    if isinstance(value, list):
        return [_stable_evidence(item) for item in value]
    return value


def record_snapshot(repo: Path, snapshot: dict) -> tuple[list[dict], bool]:
    path = _event_path(repo)
    lock_path = path.with_suffix(".lock")
    fd = os.open(lock_path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        events = _read_events(path)
        stable = _stable_evidence(snapshot)
        digest = hashlib.sha256(json.dumps(stable, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        if events and events[-1].get("evidence_sha256") == digest:
            return events, False
        body = {"schema": EVENT_SCHEMA, "sequence": len(events) + 1,
                "previous_sha256": events[-1]["event_sha256"] if events else "0" * 64,
                "event_id": f"{len(events)+1:08d}-{digest[:12]}",
                "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "evidence_sha256": digest,
                "attention": _attention(snapshot)}
        body["event_sha256"] = hashlib.sha256(json.dumps(body, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        out = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0), 0o600)
        with os.fdopen(out, "ab") as stream:
            stream.write((json.dumps(body, sort_keys=True) + "\n").encode()); stream.flush(); os.fsync(stream.fileno())
        os.chmod(path, 0o600)
        dfd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)); os.fsync(dfd); os.close(dfd)
        events.append(body)
        return events, True
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN); os.close(fd)


def _attention(snapshot: dict) -> list[dict]:
    result = []
    pressure = snapshot.get("disk", {}).get("pressure", {})
    retirement = snapshot.get("disk", {}).get("retirement", {})
    if pressure.get("severity") in {"high", "critical"}:
        result.append({"kind": "DISK_PRESSURE", "severity": pressure["severity"],
                       "available_bytes": pressure.get("available_bytes"),
                       "safe_retirement_candidates": len(retirement.get("eligible", [])),
                       "retirement_blockers": len(retirement.get("blocked", [])),
                       "cause": "Only the existing GC authority may retire proven clean, landed, archived transient worktrees."})
    return result


def validate_proposal(value: object) -> dict:
    """Validate a model result as a typed, non-executable proposal."""
    if not isinstance(value, dict) or value.get("schema") != "custodian.task_admin.proposal.v1":
        raise ValueError("unsupported proposal schema")
    if value.get("action") not in ALLOWED_ACTIONS:
        raise ValueError("proposal action is not allowed in observe-only slice A")
    required = ("workstream", "evidence_sha256", "reason", "next_check")
    if any(not isinstance(value.get(k), str) or not value[k] for k in required):
        raise ValueError("proposal is missing required typed evidence fields")
    if len(value["workstream"]) > 120 or len(value["reason"]) > 1000 or len(value["next_check"]) > 500:
        raise ValueError("proposal field exceeds its size bound")
    if not __import__("re").fullmatch(r"[0-9a-f]{64}", value["evidence_sha256"]):
        raise ValueError("proposal evidence digest is malformed")
    if any(k in value for k in ("command", "shell", "argv", "execute", "mutation")):
        raise ValueError("executable instructions are forbidden")
    return {k: value[k] for k in ("schema", "action", *required)}


def run_operator(repo: Path, snapshot: dict, *, max_tokens: int = 1200, timeout: int = 90) -> dict:
    if not 1 <= max_tokens <= 4000 or not 1 <= timeout <= 180:
        raise ObserverError("operator budget is outside supported bounds")
    codex = shutil.which("codex")
    if not codex:
        return {"status": "unavailable", "reason": "codex executable not found"}
    today = datetime.now(timezone.utc).date().isoformat()
    history = _read_events(_event_path(repo))
    turns_today = sum(e.get("event_type") == "operator_turn" and
                      str(e.get("timestamp_utc", "")).startswith(today) for e in history)
    if turns_today >= MAX_TURNS_PER_DAY:
        return {"status": "budget_exhausted", "reason": "daily diagnostic turn budget exhausted"}
    schema = {"type": "object", "additionalProperties": False, "required": ["schema", "action", "workstream", "evidence_sha256", "reason", "next_check"],
              "properties": {"schema": {"const": "custodian.task_admin.proposal.v1"}, "action": {"enum": sorted(ALLOWED_ACTIONS)},
                "workstream": {"type": "string", "maxLength": 120}, "evidence_sha256": {"type": "string", "maxLength": 64},
                "reason": {"type": "string", "maxLength": 1000}, "next_check": {"type": "string", "maxLength": 500}}}
    store = private_store(repo)
    schema_path = store / "proposal.schema.json"
    schema_path.write_text(json.dumps(schema), encoding="utf-8"); os.chmod(schema_path, 0o600)
    evidence = _stable_evidence({"source_health": snapshot["source_health"], "queue_frontier": snapshot["queue_frontier"], "disk": snapshot["disk"], "packets": snapshot["packets"], "origin_main_sha": snapshot["origin_main_sha"]})
    digest = hashlib.sha256(json.dumps(evidence, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    prompt = (f"Read-only diagnosis only. Limit the final response to {max_tokens} tokens. Return exactly one JSON object matching the supplied schema. "
              "Never request or emit commands, claims, lock changes, cleanup, review decisions, or arbitrary mutations. "
              f"Evidence SHA256: {digest}\nEvidence: {json.dumps(evidence, separators=(',', ':'))}")
    cmd = [codex, "exec", "--ephemeral", "--sandbox", "read-only", "-c", 'model_reasoning_effort="low"', "--cd", str(repo),
           "--output-schema", str(schema_path), "--json", "--", prompt]
    try:
        p = subprocess.run(cmd, text=True, capture_output=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return {"status": "interrupted", "reason": "bounded Codex turn timed out"}
    if p.returncode or len(p.stdout) > 1_000_000:
        return {"status": "failed", "reason": "Codex turn failed or exceeded output bound"}
    # Codex JSONL contains event envelopes; accept only a final assistant JSON payload.
    try:
        messages = [json.loads(line) for line in p.stdout.splitlines() if line.strip()]
        text = next((x.get("item", {}).get("text") for x in reversed(messages)
                     if isinstance(x, dict) and x.get("item", {}).get("type") == "agent_message"), None)
        proposal = validate_proposal(json.loads(text))
        if proposal["evidence_sha256"] != digest:
            raise ValueError("proposal digest does not match supplied evidence")
        known_ids = {row["workstream"] for row in snapshot.get("packets", []) if isinstance(row, dict)}
        if proposal["workstream"] not in known_ids and proposal["workstream"] != "system":
            raise ValueError("proposal names a workstream absent from the supplied snapshot")
        return {"status": "proposal", "proposal": proposal}
    except (ValueError, TypeError, AttributeError, StopIteration):
        return {"status": "rejected", "reason": "Codex output did not satisfy the strict proposal contract"}


def observe(repo: Path, *, reason: bool = False) -> dict:
    snapshot = collect(repo)
    events, changed = record_snapshot(repo, snapshot)
    snapshot["events"] = [{"event_id": x["event_id"], "timestamp_utc": x["timestamp_utc"], "attention": x.get("attention", [])} for x in events[-100:]]
    snapshot["operator"] = {"status": "not_called", "reason": "unchanged evidence" if not changed else "observer-only default"}
    if reason and changed:
        snapshot["operator"] = run_operator(repo, snapshot)
        _record_operator(repo, snapshot["operator"], events[-1]["evidence_sha256"] if events else "")
    return snapshot


def _record_operator(repo: Path, result: dict, evidence_sha256: str) -> None:
    """Persist only the bounded typed decision and evidence link, never prompts."""
    path = _event_path(repo)
    fd = os.open(path.with_suffix(".lock"), os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        events = _read_events(path)
        body = {"schema": EVENT_SCHEMA, "event_type": "operator_turn",
                "sequence": len(events) + 1,
                "previous_sha256": events[-1]["event_sha256"] if events else "0" * 64,
                "event_id": f"{len(events)+1:08d}-operator",
                "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "evidence_sha256": evidence_sha256, "decision": result}
        body["event_sha256"] = hashlib.sha256(json.dumps(body, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        out = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0), 0o600)
        with os.fdopen(out, "ab") as stream:
            stream.write((json.dumps(body, sort_keys=True) + "\n").encode()); stream.flush(); os.fsync(stream.fileno())
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN); os.close(fd)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("snapshot", "status", "queue", "why", "history"):
        item = sub.add_parser(name); item.add_argument("--json", action="store_true")
        item.add_argument("--reason", action="store_true", help="allow one bounded read-only Codex diagnostic turn on changed evidence")
    daemon = sub.add_parser("run", help="poll read-only sources until stopped")
    daemon.add_argument("--interval", type=int, default=60)
    daemon.add_argument("--reason", action="store_true")
    args = parser.parse_args(argv)
    repo = Path.cwd()
    try:
        if args.command == "run":
            if not 15 <= args.interval <= 3600:
                parser.error("--interval must be between 15 and 3600 seconds")
            fd = acquire_observer_lock(repo)
            stopped = False
            def stop(*_):
                nonlocal stopped
                stopped = True
            signal.signal(signal.SIGTERM, stop); signal.signal(signal.SIGINT, stop)
            while not stopped:
                snapshot = observe(repo, reason=args.reason)
                print(json.dumps({"schema": SCHEMA, "generated_utc": snapshot["generated_utc"],
                                  "source_health": snapshot["source_health"], "operator": snapshot["operator"]}), flush=True)
                for _ in range(args.interval):
                    if stopped: break
                    time.sleep(1)
            os.close(fd)
            return 0
        if args.command == "history":
            events = _read_events(_event_path(repo))
            result = {"schema": SCHEMA, "events": events}
            if args.json:
                print(json.dumps(result, indent=2, sort_keys=True))
            else:
                print(f"{len(events)} durable observer/operator events")
            return 0
        result = observe(repo, reason=args.reason)
        if args.command == "queue":
            result = {"schema": SCHEMA, "packets": result["packets"], "queue_frontier": result["queue_frontier"]}
        elif args.command == "why":
            result = {"schema": SCHEMA, "attention": result["events"][-1].get("attention", []) if result["events"] else [], "operator": result["operator"]}
        if args.json:
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            print(f"{SCHEMA} | main={result.get('origin_main_sha')} | packets={len(result.get('packets', []))} | mutation authority=none")
        return 0
    except (ObserverError, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"task_administrator: BLOCKED: {exc}", file=sys.stderr); return 2


if __name__ == "__main__":
    raise SystemExit(main())
