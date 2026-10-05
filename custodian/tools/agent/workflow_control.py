#!/usr/bin/env python3
"""Shared atomic workstream claims, local coordination locks, and run traces."""
from __future__ import annotations

import fcntl
import json
import math
import os
import re
import socket
import subprocess
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator

TRACE_SCHEMA = "custodian.workflow_trace_event.v1"
TRACE_VERSION = 1
DIAGNOSTIC_PREFIX = "refs/heads/agent-diagnostics"
CLAIM_PREFIX = "refs/heads/dispatch-claims"
DIAGNOSTIC_NETWORK_TIMEOUT_SECONDS = 15.0
SECRET_KEY = re.compile(r"(authorization|api.?key|access.?token|refresh.?token|password|secret|credential|private.?key)", re.I)
SECRET_VALUE = re.compile(r"(?i)(bearer\s+|(?:gh[pousr]_|github_pat_|glpat-|xox[baprs]-)[A-Za-z0-9_./-]+|(?:token|password|secret|authorization)=)[^\s,;]+")
URL_CREDENTIALS = re.compile(r"(?i)(https?://)[^/@\s:]+:[^/@\s]+@")


class WorkflowControlError(RuntimeError):
    pass


DEFAULT_AGENT_ID = "unspecified"


def resolve_agent_id(explicit: str | None) -> str:
    """Truthful agent identity shared by dispatch.py and workstream.py: an
    explicit flag wins, then a documented environment identity, then a
    neutral default. Never silently attribute an unspecified caller to any
    one specific agent brand (traces and remote-claim commit authorship both
    depend on this)."""
    if explicit:
        return explicit
    env_value = os.environ.get("CUSTODIAN_AGENT_ID", "").strip()
    return env_value or DEFAULT_AGENT_ID


def git(
    repo: Path,
    *args: str,
    check: bool = True,
    input_text: str | None = None,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(["git", *args], cwd=repo, input=input_text, text=True, capture_output=True, timeout=timeout)
    if check and result.returncode:
        raise WorkflowControlError(f"git {' '.join(sanitize_argv(args))} failed: {redact(result.stderr or result.stdout)}")
    return result


def common_dir(repo: Path) -> Path:
    raw = Path(git(repo, "rev-parse", "--git-common-dir").stdout.strip())
    return (repo / raw).resolve() if not raw.is_absolute() else raw.resolve()


def _valid_id(value: str) -> str:
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", value):
        raise WorkflowControlError("workstream ID must be lowercase kebab-case")
    return value


def dispatch_mutex_path(repo: Path) -> Path:
    return common_dir(repo) / "custodian-workflow" / "dispatch.lock"


@contextmanager
def common_mutex(
    repo: Path,
    *,
    trace: "RunTrace | None" = None,
    timeout_seconds: float = 0.0,
) -> Iterator[None]:
    if not math.isfinite(timeout_seconds):
        raise WorkflowControlError("dispatch mutex wait timeout must be finite")
    path = dispatch_mutex_path(repo)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as handle:
        started = time.monotonic()
        deadline = started + max(0.0, timeout_seconds)
        while True:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError as exc:
                if time.monotonic() >= deadline:
                    raise WorkflowControlError(
                        "LOCAL DISPATCH BUSY: another local dispatcher is currently in the "
                        "assignment-critical section.\n\n"
                        f"lock: {path.resolve()}\n\n"
                        "Do not delete the lock file or terminate the holder solely to obtain it. "
                        "Retry after the active claim finishes."
                    ) from exc
                time.sleep(min(0.1, max(0.0, deadline - time.monotonic())))
        try:
            if trace:
                trace.record("mutex_acquired", scope="dispatch", wait_ms=round((time.monotonic() - started) * 1000))
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


@contextmanager
def workstream_mutex(repo: Path, workstream_id: str, *, trace: "RunTrace | None" = None) -> Iterator[None]:
    workstream_id = _valid_id(workstream_id)
    path = common_dir(repo) / "custodian-workflow" / "locks" / f"{workstream_id}.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as handle:
        started = time.monotonic()
        fcntl.flock(handle, fcntl.LOCK_EX)
        if trace:
            trace.record("mutex_acquired", scope="workstream", wait_ms=round((time.monotonic() - started) * 1000))
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


@dataclass(frozen=True)
class RemoteClaim:
    workstream_id: str
    ref: str
    local_ref: str
    oid: str
    run_id: str


def acquire_remote_claim(repo: Path, workstream_id: str, agent: str, run_id: str, *, trace: "RunTrace | None" = None) -> RemoteClaim:
    workstream_id = _valid_id(workstream_id)
    claim_ref = f"{CLAIM_PREFIX}/{workstream_id}"
    local_ref = f"refs/custodian/claims/{workstream_id}/{run_id}"
    existing = git(repo, "ls-remote", "--heads", "origin", claim_ref, check=False)
    if existing.stdout.strip():
        raise WorkflowControlError(
            f"remote claim exists without a completed assignment; recovery required at origin/{claim_ref}; "
            "verify there is no live claimant before explicit recovery"
        )
    packet_main = git(repo, "rev-parse", "origin/main").stdout.strip()
    tree = git(repo, "rev-parse", f"{packet_main}^{{tree}}").stdout.strip()
    claimant = f"{agent}:{os.getpid()}:{run_id}"
    claim = git(
        repo, "-c", f"user.name={agent}", "-c", f"user.email={agent}@workflow.invalid",
        "commit-tree", tree, "-p", packet_main, "-m", f"workstream claim {workstream_id} {claimant}",
    ).stdout.strip()
    git(repo, "update-ref", local_ref, claim)
    started = time.monotonic()
    pushed = git(repo, "push", "origin", f"{claim}:{claim_ref}", check=False)
    if trace:
        trace.command(["git", "push", "origin", f"{claim}:<claim-ref>"], pushed, started)
    if pushed.returncode:
        git(repo, "update-ref", "-d", local_ref, check=False)
        raise WorkflowControlError(f"remote claim acquisition lost or failed for {workstream_id}: {redact(pushed.stderr or pushed.stdout)}")
    remote = RemoteClaim(workstream_id, claim_ref, local_ref, claim, run_id)
    if trace:
        trace.record("remote_claim_acquired", remote_ref=claim_ref, claim_oid=claim, main_sha=packet_main, local_ref=local_ref)
    return remote


def release_remote_claim(repo: Path, claim: RemoteClaim, *, trace: "RunTrace | None" = None) -> bool:
    published = git(repo, "ls-remote", "--heads", "origin", f"refs/heads/agent/{claim.workstream_id}", check=False)
    if not published.stdout.strip():
        if trace:
            trace.record("claim_release_blocked", reason="agent branch is not published", remote_ref=claim.ref)
        return False
    started = time.monotonic()
    result = git(repo, "push", "origin", f":{claim.ref}", check=False)
    if trace:
        trace.command(["git", "push", "origin", f":{claim.ref}"], result, started)
    if result.returncode:
        if trace:
            trace.record("remote_claim_cleanup_pending", remote_ref=claim.ref, detail=redact(result.stderr or result.stdout))
        return False
    git(repo, "update-ref", "-d", claim.local_ref, check=False)
    if trace:
        trace.record("remote_claim_released", remote_ref=claim.ref)
    return True


def redact(value: str, *, limit: int = 1200) -> str:
    text = URL_CREDENTIALS.sub(r"\1<redacted>@", str(value))
    text = SECRET_VALUE.sub(lambda m: m.group(0)[:max(8, len(m.group(0)) // 3)] + "<redacted>", text)
    return text[:limit]


def sanitize_argv(argv: list[str] | tuple[str, ...]) -> list[str]:
    safe: list[str] = []
    redact_next = False
    for raw in argv:
        arg = str(raw)
        if redact_next:
            safe.append("<redacted>")
            redact_next = False
            continue
        if SECRET_KEY.search(arg) and "=" not in arg:
            safe.append(arg)
            redact_next = True
        elif SECRET_KEY.search(arg) and "=" in arg:
            safe.append(arg.split("=", 1)[0] + "=<redacted>")
        else:
            safe.append(redact(arg, limit=240))
    return safe


def _sanitize(value):
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            if SECRET_KEY.search(str(key)):
                result[str(key)] = "<redacted>"
            else:
                result[str(key)] = _sanitize(item)
        return result
    if isinstance(value, (list, tuple)):
        return [_sanitize(item) for item in value]
    if isinstance(value, str):
        return redact(value, limit=1200)
    if value is None or isinstance(value, (int, float, bool)):
        return value
    return redact(str(value), limit=240)


class RunTrace:
    def __init__(self, repo: Path, workstream_id: str, run_id: str, packet: str | None = None, agent: str | None = None):
        common = common_dir(repo)
        self.repo = common.parent if common.name == ".git" else repo.resolve()
        self.workstream_id = _valid_id(workstream_id)
        self.run_id = run_id
        self.packet = packet
        self.agent = agent
        self.started = time.monotonic()
        self.path = common_dir(repo) / "custodian-workflow" / "traces" / self.workstream_id / f"{run_id}.jsonl"
        self.active_path = common_dir(repo) / "custodian-workflow" / "active" / f"{self.workstream_id}.json"

    @property
    def diagnostic_ref(self) -> str:
        return f"{DIAGNOSTIC_PREFIX}/{self.workstream_id}/{self.run_id}"

    @classmethod
    def start(cls, repo: Path, workstream_id: str, *, packet: str | None = None, agent: str | None = None, run_id: str | None = None) -> "RunTrace":
        trace = cls(repo, workstream_id, run_id or f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:12]}", packet, agent)
        trace.path.parent.mkdir(parents=True, exist_ok=True)
        trace.active_path.parent.mkdir(parents=True, exist_ok=True)
        pointer = {"run_id": trace.run_id, "workstream": trace.workstream_id, "trace_path": str(trace.path), "diagnostic_ref": trace.diagnostic_ref}
        if not trace.active_path.exists():
            temp = trace.active_path.with_suffix(".tmp")
            temp.write_text(json.dumps(pointer, sort_keys=True) + "\n")
            try:
                os.link(temp, trace.active_path)
            except FileExistsError:
                pass
            finally:
                temp.unlink(missing_ok=True)
        trace.record("run_started", packet=packet, agent=agent)
        return trace

    @classmethod
    def resume(cls, repo: Path, workstream_id: str) -> "RunTrace":
        common = common_dir(repo)
        active = common / "custodian-workflow" / "active" / f"{_valid_id(workstream_id)}.json"
        try:
            pointer = json.loads(active.read_text())
            run_id = pointer["run_id"]
        except (OSError, ValueError, KeyError, TypeError):
            return cls.start(repo, workstream_id)
        trace = cls(repo, workstream_id, run_id)
        if trace.path.is_file():
            try:
                with trace.path.open(encoding="utf-8") as events:
                    first = json.loads(events.readline())
                started_at = datetime.fromisoformat(first["timestamp_utc"])
                elapsed = (datetime.now(timezone.utc) - started_at).total_seconds()
                trace.started = time.monotonic() - max(0.0, elapsed)
                trace.packet = first.get("packet")
            except (OSError, ValueError, KeyError, TypeError):
                pass
        return trace

    def record(self, event: str, **data) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        base = {
            "schema": TRACE_SCHEMA,
            "schema_version": TRACE_VERSION,
            "event": event,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
            "elapsed_ms": round((time.monotonic() - self.started) * 1000),
            "pid": os.getpid(),
            "host": socket.gethostname(),
            "workstream": self.workstream_id,
            "run_id": self.run_id,
            "packet": _sanitize(self.packet),
            "agent": _sanitize(self.agent),
            "data": _sanitize(data),
        }
        with self.path.open("a", encoding="utf-8") as stream:
            fcntl.flock(stream.fileno(), fcntl.LOCK_EX)
            stream.write(json.dumps(base, sort_keys=True, separators=(",", ":")) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
            fcntl.flock(stream.fileno(), fcntl.LOCK_UN)

    def command(self, argv: list[str], result: subprocess.CompletedProcess[str], started: float) -> None:
        self.record(
            "subprocess",
            argv=sanitize_argv(argv),
            return_code=result.returncode,
            duration_ms=round((time.monotonic() - started) * 1000),
            stdout=redact(result.stdout or "", limit=500),
            stderr=redact(result.stderr or "", limit=500),
        )

    def summary(self) -> dict:
        data = self.path.read_bytes() if self.path.exists() else b""
        events = [json.loads(line) for line in data.decode("utf-8").splitlines() if line.strip()]
        return {"run_id": self.run_id, "workstream": self.workstream_id, "events": len(events), "sha256": __import__("hashlib").sha256(data).hexdigest()}

    def publish(self) -> bool:
        """Best-effort publish a diagnostics-only snapshot outside task refs/main."""
        try:
            ref = self.diagnostic_ref
            remote = git(
                self.repo, "ls-remote", "--heads", "origin", ref, check=False,
                timeout=DIAGNOSTIC_NETWORK_TIMEOUT_SECONDS,
            ).stdout.strip()
            parent = None
            if remote:
                tracking = f"refs/custodian/diagnostics/{self.workstream_id}/{self.run_id}"
                fetched = git(
                    self.repo, "fetch", "origin", f"{ref}:{tracking}", check=False,
                    timeout=DIAGNOSTIC_NETWORK_TIMEOUT_SECONDS,
                )
                if fetched.returncode:
                    raise WorkflowControlError(f"cannot fetch existing diagnostic ref {ref}")
                parent = git(self.repo, "rev-parse", tracking).stdout.strip()
            blob = git(self.repo, "hash-object", "-w", "--stdin", input_text=self.path.read_text()).stdout.strip()
            tree = git(self.repo, "mktree", input_text=f"100644 blob {blob}\ttrace.jsonl\n").stdout.strip()
            args = ["-c", "user.name=CUSTODIAN Diagnostics", "-c", "user.email=diagnostics@workflow.invalid", "commit-tree", tree]
            if parent:
                args.extend(["-p", parent])
            args.extend(["-m", f"diagnostic trace {self.workstream_id} {self.run_id}"])
            commit = git(self.repo, *args, check=True).stdout.strip()
            started = time.monotonic()
            pushed = git(
                self.repo, "push", "origin", f"{commit}:{ref}", check=False,
                timeout=DIAGNOSTIC_NETWORK_TIMEOUT_SECONDS,
            )
            self.command(["git", "push", "origin", f"{commit}:{ref}"], pushed, started)
            if pushed.returncode:
                self._local_publish_failure(redact(pushed.stderr or pushed.stdout))
                return False
            local = f"refs/custodian/diagnostics/{self.workstream_id}/{self.run_id}"
            git(self.repo, "update-ref", local, commit)
            return True
        except Exception as exc:  # diagnostic export cannot change task outcome
            self._local_publish_failure(redact(str(exc)))
            return False

    def _local_publish_failure(self, reason: str) -> None:
        # Avoid recursive export attempts. This still preserves the failure locally.
        self.record("diagnostic_publish_failed", reason=reason)

    def complete(self, outcome: str, *, clear_active: bool = False, publish: bool = True) -> None:
        self.record("run_completed", outcome=outcome)
        if publish:
            self.publish()
        if clear_active:
            try:
                self.active_path.unlink()
            except FileNotFoundError:
                pass

    def finish_blocked(self, error: str, *, publish: bool = True) -> None:
        self.record("run_blocked", reason=error)
        if publish:
            self.publish()


def find_local_trace(repo: Path, run_id: str) -> Path | None:
    root = common_dir(repo) / "custodian-workflow" / "traces"
    if not root.exists():
        return None
    return next(root.glob(f"*/{run_id}.jsonl"), None)
