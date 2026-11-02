#!/usr/bin/env python3
"""Explicitly supervise one already-dispatched Codex workstream.

The journal is local-only Git-common-dir metadata. It records process identity
and lifecycle facts, never prompts, command arguments, output, or repository
contents. This module observes ownership; it does not acquire/release claims or
change any Git ref.
"""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import signal
import socket
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_control import common_dir

SCHEMA = "custodian.agent_session_event.v1"
JOURNAL_ROOT = Path("custodian-workflow/session-supervisor/v1")
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
RUN_RE = re.compile(r"^[0-9]{8}T[0-9]{6}Z-[a-f0-9]{16}$")


class SupervisorError(RuntimeError):
    pass


def _git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, timeout=20)
    if check and result.returncode:
        raise SupervisorError(f"git {args[0]} could not verify the dispatched workstream")
    return result.stdout.strip()


def _secure_dir(path: Path) -> None:
    if path.is_symlink():
        raise SupervisorError("supervisor metadata path contains a symlink")
    if path.exists():
        if not path.is_dir():
            raise SupervisorError("supervisor metadata path is not a directory")
        os.chmod(path, 0o700)
    else:
        path.mkdir(mode=0o700, parents=True)
    if path.stat().st_mode & 0o077:
        raise SupervisorError("supervisor metadata directory is not private")


def journal_dir(repo: Path, workstream: str) -> Path:
    if not ID_RE.fullmatch(workstream):
        raise SupervisorError("workstream ID must be lowercase kebab-case")
    common = common_dir(repo).resolve()
    parent = common / JOURNAL_ROOT
    current = common
    for part in JOURNAL_ROOT.parts + (workstream,):
        current = current / part
        if current.is_symlink():
            raise SupervisorError("supervisor metadata path contains a symlink")
        if current.exists() and not current.is_dir():
            raise SupervisorError("supervisor metadata path is not a directory")
    _secure_dir(parent)
    _secure_dir(parent / workstream)
    if not (parent / workstream).resolve().is_relative_to(common):
        raise SupervisorError("supervisor metadata path escapes the Git common directory")
    return parent / workstream


def _journal_path(repo: Path, workstream: str, run_id: str) -> Path:
    if not RUN_RE.fullmatch(run_id):
        raise SupervisorError("invalid supervisor run ID")
    return journal_dir(repo, workstream) / f"{run_id}.jsonl"


def read_journal(path: Path) -> list[dict]:
    if path.is_symlink() or not path.is_file() or path.stat().st_mode & 0o077:
        raise SupervisorError("journal is missing, unsafe, or not private")
    events: list[dict] = []
    previous = "0" * 64
    try:
        with path.open(encoding="utf-8") as stream:
            for sequence, line in enumerate(stream, 1):
                event = json.loads(line)
                if not isinstance(event, dict):
                    raise SupervisorError("journal event is not an object")
                claimed_hash = event.pop("event_sha256", None)
                canonical = json.dumps(event, sort_keys=True, separators=(",", ":")).encode()
                if (event.get("schema") != SCHEMA or event.get("sequence") != sequence
                        or event.get("previous_sha256") != previous
                        or claimed_hash != hashlib.sha256(canonical).hexdigest()
                        or event.get("event") not in {"LAUNCH_INTENT", "LAUNCH_FAILED", "STARTED", "HEARTBEAT",
                                                       "PAUSE_REQUESTED", "EXITED_CONFIRMED",
                                                       "PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN"}
                        or not ID_RE.fullmatch(str(event.get("workstream", "")))
                        or not RUN_RE.fullmatch(str(event.get("run_id", "")))):
                    raise SupervisorError("journal hash chain or sequence is invalid")
                event["event_sha256"] = claimed_hash
                events.append(event)
                previous = claimed_hash
    except (OSError, json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise SupervisorError("journal is unreadable or malformed") from exc
    if (not events or events[0].get("event") != "LAUNCH_INTENT"
            or not events[0].get("branch", "").startswith("agent/")
            or not isinstance(events[0].get("claim_receipt_sha256"), str)
            or not re.fullmatch(r"[0-9a-f]{64}", events[0]["claim_receipt_sha256"])):
        raise SupervisorError("journal does not begin with a durable launch intent")
    identity_fields = ("workstream", "run_id", "host", "boot_id", "branch", "worktree", "packet",
                       "dispatch_run_id", "dispatch_trace_ref", "claim_receipt_sha256")
    if any(any(event.get(key) != events[0].get(key) for key in identity_fields) for event in events[1:]):
        raise SupervisorError("journal event identity differs from its launch intent")
    if len(events) > 1:
        if events[1]["event"] not in {"STARTED", "LAUNCH_FAILED", "PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN"}:
            raise SupervisorError("journal must record process start or launch failure after intent")
        if events[1]["event"] in {"LAUNCH_FAILED", "PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN"} and len(events) != 2:
            raise SupervisorError("failed launch journal contains later process events")
        if events[1]["event"] == "STARTED":
            tail = events[2:]
            allowed_tail = {"HEARTBEAT", "PAUSE_REQUESTED", "EXITED_CONFIRMED",
                            "PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN"}
            if any(event["event"] not in allowed_tail for event in tail):
                raise SupervisorError("journal contains an invalid process-event transition")
            if sum(event["event"] == "EXITED_CONFIRMED" for event in tail) > 1:
                raise SupervisorError("journal records process exit more than once")
            if any(event["event"] == "EXITED_CONFIRMED" for event in tail[:-1]):
                raise SupervisorError("journal continues after confirmed process exit")
    return events


def append_event(path: Path, event: dict) -> dict:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    lock_path = path.with_suffix(".lock")
    if lock_path.is_symlink():
        raise SupervisorError("supervisor lock path is a symlink")
    fd = os.open(lock_path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    with os.fdopen(fd, "a+b") as lock:
        os.chmod(lock_path, 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        events = read_journal(path) if path.exists() else []
        payload = {**event, "schema": SCHEMA, "sequence": len(events) + 1,
                   "previous_sha256": events[-1]["event_sha256"] if events else "0" * 64}
        payload["event_sha256"] = hashlib.sha256(
            json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
        ).hexdigest()
        flags = os.O_WRONLY | os.O_APPEND | getattr(os, "O_NOFOLLOW", 0)
        flags |= os.O_CREAT if not events else 0
        out_fd = os.open(path, flags, 0o600)
        with os.fdopen(out_fd, "ab") as out:
            out.write((json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n").encode())
            out.flush()
            os.fsync(out.fileno())
        os.chmod(path, 0o600)
        if len(events) == 0:
            dir_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
            try:
                os.fsync(dir_fd)
            finally:
                os.close(dir_fd)
        fcntl.flock(lock.fileno(), fcntl.LOCK_UN)
        return payload


def _proc_stat(pid: int) -> dict | None:
    try:
        raw = Path(f"/proc/{pid}/stat").read_text()
        end = raw.rfind(")")
        if end < 0:
            return None
        fields = raw[end + 2:].split()
        return {"pid": pid, "state": fields[0], "ppid": int(fields[1]),
                "pgid": int(fields[2]), "start_ticks": int(fields[19])}
    except (FileNotFoundError, ProcessLookupError, PermissionError, OSError, ValueError, IndexError):
        return None


def process_snapshot(root_pid: int, pgid: int) -> tuple[list[dict], bool]:
    """Return identities in the child tree/group; never read process arguments."""
    proc = Path("/proc")
    if not proc.is_dir():
        return [], False
    rows: dict[int, dict] = {}
    complete = True
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        item = _proc_stat(int(entry.name))
        if item is not None:
            rows[item["pid"]] = item
        elif Path(entry).exists():
            complete = False
    selected = {root_pid}
    changed = True
    while changed:
        changed = False
        for pid, item in rows.items():
            if (pid in selected or item["pgid"] == pgid or item["ppid"] in selected) and pid not in selected:
                selected.add(pid)
                changed = True
    return [rows[pid] for pid in sorted(selected) if pid in rows and rows[pid]["state"] != "Z"], complete


def _boot_id() -> str:
    try:
        value = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
    except OSError as exc:
        raise SupervisorError("host boot identity is unavailable") from exc
    if not re.fullmatch(r"[0-9a-fA-F-]{16,64}", value):
        raise SupervisorError("host boot identity is malformed")
    return value


def _identity(pid: int) -> dict:
    item = _proc_stat(pid)
    if item is None:
        raise SupervisorError("could not capture exact process start identity")
    return {"pid": pid, "start_ticks": item["start_ticks"], "pgid": item["pgid"]}


def _claim_identity(repo: Path, workstream: str) -> dict:
    common = common_dir(repo).resolve()
    receipt_path = common / "custodian-dispatch" / "last-claim.json"
    if (receipt_path.is_symlink() or not receipt_path.is_file()
            or not receipt_path.resolve().is_relative_to(common)):
        raise SupervisorError("no verified dispatcher claim receipt is available")
    try:
        receipt_bytes = receipt_path.read_bytes()
        receipt = json.loads(receipt_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise SupervisorError("dispatcher claim receipt is unreadable") from exc
    if (receipt.get("schema") != "custodian.dispatch.claim.v1" or receipt.get("result") != "claimed"
            or receipt.get("workstream") != workstream or receipt.get("verified") is not True):
        raise SupervisorError("latest dispatcher receipt does not verify this workstream")
    worktree = Path(str(receipt.get("worktree", ""))).resolve()
    branch = str(receipt.get("branch", ""))
    packet = str(receipt.get("packet", ""))
    if (branch != f"agent/{workstream}" or not worktree.is_dir()
            or _git(worktree, "branch", "--show-current") != branch
            or common_dir(worktree) != common_dir(repo)):
        raise SupervisorError("dispatcher receipt worktree or branch identity is stale")
    attached = _git(repo, "worktree", "list", "--porcelain")
    if f"worktree {worktree}\n" not in attached or f"branch refs/heads/{branch}" not in attached:
        raise SupervisorError("dispatcher receipt path is not the attached Git worktree for this branch")
    if not packet.startswith("custodian/docs/ai_context/task_packets/") or ".." in Path(packet).parts:
        raise SupervisorError("dispatcher receipt packet path is unsafe")
    packet_file = worktree / packet
    if (not packet_file.is_file() or packet_file.is_symlink()
            or not packet_file.resolve().is_relative_to(worktree)):
        raise SupervisorError("dispatched task packet is unavailable in the claimed worktree")
    local_head = _git(worktree, "rev-parse", "HEAD")
    remote = subprocess.run(["git", "ls-remote", "--heads", "origin", f"refs/heads/{branch}"],
                            cwd=worktree, text=True, capture_output=True, timeout=20)
    rows = [line.split() for line in remote.stdout.splitlines() if line.split()]
    if remote.returncode or len(rows) != 1 or rows[0][1] != f"refs/heads/{branch}":
        raise SupervisorError("remote claim branch could not be read without ambiguity")
    if rows[0][0] != local_head:
        raise SupervisorError("local and remote claimed branch heads differ; supervised launch is blocked")
    return {
        "workstream": workstream, "branch": branch, "worktree": str(worktree),
        "packet": packet, "packet_sha256": hashlib.sha256(packet_file.read_bytes()).hexdigest(),
        "branch_sha": local_head, "remote_branch_sha": rows[0][0],
        "dispatch_run_id": str(receipt.get("run_id", "")),
        "dispatch_trace_ref": str(receipt.get("trace_ref", "")),
        "claim_receipt_sha256": hashlib.sha256(receipt_bytes).hexdigest(),
    }


def supervise(repo: Path, workstream: str, argv: list[str], *, heartbeat_seconds: float = 2.0,
              popen_factory=subprocess.Popen, stop_event=None) -> int:
    if not argv or not argv[0] or heartbeat_seconds <= 0 or heartbeat_seconds > 60:
        raise SupervisorError("a command and heartbeat interval from 0–60 seconds are required")
    claim = _claim_identity(repo, workstream)
    if Path(argv[0]).name == "codex":
        if len(argv) < 2 or argv[1] != "exec":
            raise SupervisorError("supervised Codex launch requires the explicit `codex exec` command")
        worktree = Path(claim["worktree"]).resolve()
        for index, value in enumerate(argv):
            if value in {"--cd", "-C"}:
                if index + 1 >= len(argv) or Path(argv[index + 1]).resolve() != worktree:
                    raise SupervisorError("Codex --cd must match the exact dispatched worktree")
            elif value.startswith("--cd=") and Path(value.partition("=")[2]).resolve() != worktree:
                raise SupervisorError("Codex --cd must match the exact dispatched worktree")
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:16]
    path = _journal_path(repo, workstream, run_id)
    lock_path = path.parent / ".owner.lock"
    if lock_path.is_symlink():
        raise SupervisorError("supervisor owner lock is a symlink")
    lock_fd = os.open(lock_path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    owner_lock = os.fdopen(lock_fd, "a+b")
    try:
        fcntl.flock(owner_lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as exc:
        owner_lock.close()
        raise SupervisorError("another supervisor already owns this workstream run") from exc
    os.chmod(lock_path, 0o600)
    try:
        for prior_path in sorted(path.parent.glob("*.jsonl")):
            try:
                prior_events = read_journal(prior_path)
            except SupervisorError as exc:
                raise SupervisorError("prior supervisor journal is ambiguous; preserve and audit before relaunch") from exc
            if prior_events[-1]["event"] not in {"EXITED_CONFIRMED", "LAUNCH_FAILED"}:
                raise SupervisorError("prior supervisor run is unresolved; preserve and audit before relaunch")
    except BaseException:
        owner_lock.close()
        raise
    worktree = Path(claim["worktree"])
    boot = _boot_id()
    host = socket.gethostname()
    parent = _identity(os.getpid())
    intent = {**claim, "run_id": run_id, "event": "LAUNCH_INTENT",
              "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
              "monotonic_ns": time.monotonic_ns(), "host": host, "boot_id": boot,
              "supervisor": parent, "command_executable": Path(argv[0]).name}
    try:
        append_event(path, intent)
    except BaseException:
        owner_lock.close()
        raise
    try:
        child = popen_factory(argv, cwd=worktree, start_new_session=True)
    except BaseException as exc:
        append_event(path, {**intent, "event": "LAUNCH_FAILED",
                            "error_type": type(exc).__name__})
        owner_lock.close()
        raise
    try:
        child_identity = _identity(child.pid)
    except SupervisorError:
        try:
            os.killpg(child.pid, signal.SIGTERM)
            child.wait(timeout=5)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            pass
        append_event(path, {**intent, "event": "PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN",
                            "child_pid": child.pid, "process_group": child.pid,
                            "processes": [], "process_scan_complete": False,
                            "error_type": "ProcessIdentityUnavailable"})
        owner_lock.close()
        raise
    latest_signal: list[int | None] = [None]
    old_handlers: dict[int, object] = {}

    def request_pause(signum, _frame):
        latest_signal[0] = signum

    for sig in (signal.SIGINT, signal.SIGHUP, signal.SIGTERM):
        try:
            old_handlers[sig] = signal.signal(sig, request_pause)
        except (ValueError, OSError):
            pass

    def record(kind: str, snapshot: list[dict], complete: bool, **extra) -> None:
        append_event(path, {
            **claim, "run_id": run_id, "event": kind,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
            "monotonic_ns": time.monotonic_ns(), "host": host, "boot_id": boot,
            "supervisor": parent, "child": child_identity, "process_group": child_identity["pgid"],
            "processes": snapshot, "process_scan_complete": complete,
            "branch_head": _git(worktree, "rev-parse", "HEAD"),
            "command_executable": Path(argv[0]).name,
            **extra,
        })

    try:
        snapshot, complete = process_snapshot(child.pid, child_identity["pgid"])
        record("STARTED", snapshot, complete)
        while child.poll() is None:
            if latest_signal[0] is not None:
                sig = latest_signal[0]
                latest_signal[0] = None
                snapshot, complete = process_snapshot(child.pid, child_identity["pgid"])
                record("PAUSE_REQUESTED", snapshot, complete, signal=int(sig))
                try:
                    os.killpg(child_identity["pgid"], sig)
                except ProcessLookupError:
                    pass
            if stop_event is not None and stop_event.is_set():
                snapshot, complete = process_snapshot(child.pid, child_identity["pgid"])
                record("PAUSE_REQUESTED", snapshot, complete, signal="test-stop")
                try:
                    os.killpg(child_identity["pgid"], signal.SIGTERM)
                except ProcessLookupError:
                    pass
                stop_event.clear()
            try:
                child.wait(timeout=heartbeat_seconds)
            except subprocess.TimeoutExpired:
                snapshot, complete = process_snapshot(child.pid, child_identity["pgid"])
                record("HEARTBEAT", snapshot, complete)
        return_code = child.returncode
        seen: dict[int, int] = {}
        while True:
            snapshot, complete = process_snapshot(child.pid, child_identity["pgid"])
            for item in snapshot:
                seen[item["pid"]] = item["start_ticks"]
            historic_live = []
            reused = False
            for pid, start_ticks in seen.items():
                current = _proc_stat(pid)
                if current is None or current["state"] == "Z":
                    continue
                if current["start_ticks"] == start_ticks:
                    historic_live.append(current)
                else:
                    reused = True
            if not historic_live and complete and not reused:
                record("EXITED_CONFIRMED", snapshot, complete, return_code=return_code,
                       observed_process_count=len(seen))
                break
            record("PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN", snapshot, complete,
                   return_code=return_code, observed_process_count=len(seen), pid_reuse_observed=reused)
            if not historic_live:
                break
            time.sleep(heartbeat_seconds)
        return return_code
    finally:
        for sig, handler in old_handlers.items():
            signal.signal(sig, handler)
        owner_lock.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    run = subs.add_parser("run", help="run one exact dispatched Codex session under local supervision")
    run.add_argument("workstream")
    run.add_argument("--heartbeat-seconds", type=float, default=2.0)
    run.add_argument("argv", nargs=argparse.REMAINDER, help="command after --; normally codex exec ...")
    args = parser.parse_args(argv)
    command = args.argv[1:] if args.argv[:1] == ["--"] else args.argv
    if not command:
        parser.error("run requires -- <codex command>")
    if Path(command[0]).name != "codex":
        parser.error("supervised CLI launch currently accepts only the explicit codex executable")
    try:
        repo = Path(_git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        return supervise(repo, args.workstream, command, heartbeat_seconds=args.heartbeat_seconds)
    except (SupervisorError, OSError, subprocess.SubprocessError) as exc:
        print(f"session_supervisor: BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
