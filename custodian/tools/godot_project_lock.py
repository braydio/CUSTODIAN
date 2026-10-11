#!/usr/bin/env python3
"""Machine-wide exclusive lock over one Godot project's generated spine.

Two processes must not import or rebuild the same Godot project at once. The
import step writes `.godot/imported/`, the `.import` sidecars and the UID cache;
the Operator pipeline writes the runtime manifest and
`operator_runtime_frames.tres` on top of those. Concurrent writers corrupt each
other's view, and the observed symptom is not a clean error but a stalled import:
two overlapping `run_validation.py` runs reproduce
`infrastructure_failure: import` with the import step timing out.

Engine errors under concurrent mutation are real failures, so the fix belongs
here — preventing the concurrency — rather than in a laxer validation gate.

Design notes:

* `fcntl.flock` is used deliberately. The kernel releases it when the holding
  process dies, which matters because agent sessions get killed mid-run and a
  PID-file lock would strand the project behind a lock nobody holds.
* Lock files live in the user cache namespace, keyed by the resolved project
  path — independent of TMPDIR, never inside the repository (it would show up
  in `git status`) and never inside `.godot/` (a full reimport deletes that
  directory, which would silently unlink the inode every waiter is queued on).
* Acquisition is reentrant across process boundaries via an environment variable,
  so a locked run can shell out to another locked tool without deadlocking.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import time
from pathlib import Path

try:
    import fcntl
except ImportError:  # pragma: no cover - POSIX only; see acquire() degradation
    fcntl = None

#: Set to the lock file path while held, so nested tools skip re-acquiring.
REENTRANCY_ENV = "CUSTODIAN_GODOT_PROJECT_LOCK"
PROJECT_FD_ENV = "CUSTODIAN_GODOT_PROJECT_LOCK_FD"
#: Set to "1" to bypass locking entirely. For debugging a hung lock only.
DISABLE_ENV = "CUSTODIAN_GODOT_LOCK_DISABLE"
#: Overrides the derived lock path, so cooperating processes can be pinned.
PATH_ENV = "CUSTODIAN_GODOT_LOCK_PATH"
SCRATCH_ENV = "CUSTODIAN_SCRATCH_DIR"
MAX_JOBS_ENV = "CUSTODIAN_GODOT_MAX_JOBS"
BUDGET_REENTRANCY_ENV = "CUSTODIAN_GODOT_JOB_BUDGET"
BUDGET_FD_ENV = "CUSTODIAN_GODOT_JOB_BUDGET_FD"

DEFAULT_TIMEOUT_SEC = 900.0
POLL_INTERVAL_SEC = 0.5
DEFAULT_MAX_JOBS = 2


def scratch_root(*, create: bool = True) -> Path:
    """Resolve the configurable, disk-backed home for large disposable state."""
    configured = os.environ.get(SCRATCH_ENV)
    path = Path(configured).expanduser() if configured else Path.home() / ".cache" / "custodian"
    path = path.resolve()
    if create:
        path.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            path.chmod(0o700)
        except OSError:
            pass
    return path


def godot_home(*, create: bool = True) -> Path:
    path = scratch_root(create=create) / "godot-home"
    if create:
        path.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            path.chmod(0o700)
        except OSError:
            pass
    return path


def _lock_root() -> Path:
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))).expanduser()
    return cache_home / "custodian" / "locks"


def _ensure_lock_root() -> Path:
    root = _lock_root()
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        root.chmod(0o700)
    except OSError:
        pass
    return root


class GodotProjectBusy(RuntimeError):
    """Raised when the project lock could not be acquired within the timeout."""


def lock_path_for(project_dir: Path) -> Path:
    override = os.environ.get(PATH_ENV)
    if override:
        return Path(override)
    digest = hashlib.sha256(str(Path(project_dir).resolve()).encode()).hexdigest()[:12]
    return _lock_root() / f"custodian-godot-project-{digest}.lock"


def _describe_self(purpose: str) -> str:
    return json.dumps({
        "pid": os.getpid(),
        "purpose": purpose,
        "argv": sys.argv[:6],
        "acquired_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
    })


def inherited_job_budget_fds() -> tuple[int, ...]:
    """Keep the counting slot held if a validation parent exits before its child."""
    raw = os.environ.get(BUDGET_FD_ENV, "")
    return (int(raw),) if raw.isdigit() else ()


def inherited_godot_lock_fds() -> tuple[int, ...]:
    """Return held project and job-budget descriptors for launched children."""
    values = (os.environ.get(PROJECT_FD_ENV, ""), os.environ.get(BUDGET_FD_ENV, ""))
    return tuple(int(value) for value in values if value.isdigit())


def _read_holder(path: Path) -> str:
    """Best-effort description of the current holder, for a useful wait message."""
    try:
        text = path.read_text(encoding="utf-8").strip()
    except OSError:
        return "unknown holder"
    if not text:
        return "unknown holder"
    try:
        holder = json.loads(text)
    except json.JSONDecodeError:
        return text[:200]
    return "pid %s (%s) since %s" % (
        holder.get("pid", "?"), holder.get("purpose", "?"), holder.get("acquired_at", "?"),
    )


class GodotProjectLock:
    """Context manager holding the exclusive project lock.

    Use it around anything that imports the project or rewrites generated
    resources. Readers that merely load already-imported resources do not need
    it, but `run_validation.py` does: it runs the import step itself.
    """

    def __init__(
        self,
        project_dir: Path,
        purpose: str,
        timeout_sec: float = DEFAULT_TIMEOUT_SEC,
        on_wait=None,
    ) -> None:
        self.project_dir = Path(project_dir)
        self.purpose = purpose
        self.timeout_sec = timeout_sec
        self.path = lock_path_for(self.project_dir)
        self._on_wait = on_wait
        self._handle = None
        self._owns_env = False
        #: False when the lock was skipped: disabled, already held, or no fcntl.
        self.acquired = False

    def __enter__(self) -> "GodotProjectLock":
        if os.environ.get(DISABLE_ENV) == "1":
            return self
        # A nested tool inside an already-locked run must not queue behind itself.
        if os.environ.get(REENTRANCY_ENV) == str(self.path):
            return self
        if fcntl is None:
            # Degrade loudly rather than pretending the project is protected.
            print(
                "[godot-lock] fcntl unavailable on this platform; running without"
                " the project lock",
                file=sys.stderr,
            )
            return self
        self.path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        self._handle = open(self.path, "a+", encoding="utf-8")
        deadline = time.monotonic() + self.timeout_sec
        announced = False
        while True:
            try:
                fcntl.flock(self._handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if not announced:
                    message = (
                        "[godot-lock] waiting for the Godot project lock held by %s"
                        % _read_holder(self.path)
                    )
                    if self._on_wait is not None:
                        self._on_wait(message)
                    else:
                        print(message, file=sys.stderr)
                    announced = True
                if time.monotonic() >= deadline:
                    holder = _read_holder(self.path)
                    self._handle.close()
                    self._handle = None
                    raise GodotProjectBusy(
                        "another process is importing or rebuilding %s: %s"
                        % (self.project_dir, holder)
                    )
                time.sleep(POLL_INTERVAL_SEC)
        self._handle.seek(0)
        self._handle.truncate()
        self._handle.write(_describe_self(self.purpose))
        self._handle.flush()
        os.environ[REENTRANCY_ENV] = str(self.path)
        os.environ[PROJECT_FD_ENV] = str(self._handle.fileno())
        self._owns_env = True
        self.acquired = True
        return self

    def __exit__(self, *_exc) -> None:
        if self._owns_env:
            os.environ.pop(REENTRANCY_ENV, None)
            os.environ.pop(PROJECT_FD_ENV, None)
            self._owns_env = False
        if self._handle is None:
            return
        # A child launched by the locked runner may still be using the project.
        # Closing preserves the lock until inherited descriptors close; an
        # explicit LOCK_UN would release it too early.
        self._handle.close()
        self._handle = None
        self.acquired = False


class GodotJobBudget:
    """Machine-wide counting semaphore implemented with crash-safe flock slots."""

    def __init__(self, purpose: str, timeout_sec: float = DEFAULT_TIMEOUT_SEC, on_wait=None) -> None:
        raw_limit = os.environ.get(MAX_JOBS_ENV, str(DEFAULT_MAX_JOBS))
        try:
            self.limit = int(raw_limit)
        except ValueError as error:
            raise ValueError(f"{MAX_JOBS_ENV} must be a positive integer") from error
        if self.limit < 1:
            raise ValueError(f"{MAX_JOBS_ENV} must be a positive integer")
        self.purpose = purpose
        self.timeout_sec = timeout_sec
        self._on_wait = on_wait
        self._handle = None
        self.path: Path | None = None
        self._owns_env = False
        self.acquired = False

    def __enter__(self) -> "GodotJobBudget":
        if os.environ.get(BUDGET_REENTRANCY_ENV):
            return self
        if fcntl is None:
            raise RuntimeError("fcntl unavailable; machine-wide Godot job budget cannot be enforced")
        root = _ensure_lock_root()
        deadline = time.monotonic() + self.timeout_sec
        announced = False
        while True:
            for slot in range(self.limit):
                path = root / f"custodian-godot-job-{slot:02d}.lock"
                handle = open(path, "a+", encoding="utf-8")
                try:
                    fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                except BlockingIOError:
                    handle.close()
                    continue
                handle.seek(0)
                handle.truncate()
                handle.write(_describe_self(self.purpose))
                handle.flush()
                self.path = path
                self._handle = handle
                os.environ[BUDGET_REENTRANCY_ENV] = str(path)
                os.environ[BUDGET_FD_ENV] = str(handle.fileno())
                self._owns_env = True
                self.acquired = True
                return self
            if not announced:
                occupied = [
                    f"slot {slot}: {_read_holder(root / f'custodian-godot-job-{slot:02d}.lock')}"
                    for slot in range(self.limit)
                ]
                message = (
                    f"[godot-budget] waiting for a machine-wide Godot slot (limit {self.limit}; "
                    + "; ".join(occupied) + ")"
                )
                if self._on_wait is not None:
                    self._on_wait(message)
                else:
                    print(message, file=sys.stderr)
                announced = True
            if time.monotonic() >= deadline:
                raise GodotProjectBusy(f"all {self.limit} machine-wide Godot job slots are occupied")
            time.sleep(POLL_INTERVAL_SEC)

    def __exit__(self, *_exc) -> None:
        if self._owns_env:
            os.environ.pop(BUDGET_REENTRANCY_ENV, None)
            os.environ.pop(BUDGET_FD_ENV, None)
            self._owns_env = False
        if self._handle is None:
            return
        # Do not truncate or explicitly unlock: a launched child may inherit
        # this open file description and must keep the slot and holder details
        # until it exits. Close releases the slot when the final child exits.
        self._handle.close()
        self._handle = None
        self.path = None
        self.acquired = False


def detect_external_editor(project_dir: Path) -> list[int]:
    """PIDs of Godot editors open on this project.

    The editor is a writer this lock cannot capture: it holds the project and
    reimports on filesystem change. It is harmless for ordinary validation — the
    B-final sweeps all passed with one open — but it is worth warning about
    before a run that rewrites the generated runtime spine.
    """
    resolved = str(Path(project_dir).resolve())
    found: list[int] = []
    proc = Path("/proc")
    if not proc.is_dir():
        return found
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            argv = (entry / "cmdline").read_bytes().decode(errors="replace").split("\0")
        except OSError:
            continue
        if not argv or "godot" not in Path(argv[0]).name:
            continue
        if "--editor" not in argv and "-e" not in argv:
            continue
        if any(resolved in part for part in argv):
            found.append(int(entry.name))
    return found
