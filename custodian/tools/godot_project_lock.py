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
* The lock file lives in the system temp directory, keyed by the resolved
  project path — never inside the repository (it would show up in `git status`)
  and never inside `.godot/` (a full reimport deletes that directory, which would
  silently unlink the inode every waiter is queued on).
* Acquisition is reentrant across process boundaries via an environment variable,
  so a locked run can shell out to another locked tool without deadlocking.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import tempfile
import time
from pathlib import Path

try:
    import fcntl
except ImportError:  # pragma: no cover - POSIX only; see acquire() degradation
    fcntl = None

#: Set to the lock file path while held, so nested tools skip re-acquiring.
REENTRANCY_ENV = "CUSTODIAN_GODOT_PROJECT_LOCK"
#: Set to "1" to bypass locking entirely. For debugging a hung lock only.
DISABLE_ENV = "CUSTODIAN_GODOT_LOCK_DISABLE"
#: Overrides the derived lock path, so cooperating processes can be pinned.
PATH_ENV = "CUSTODIAN_GODOT_LOCK_PATH"

DEFAULT_TIMEOUT_SEC = 900.0
POLL_INTERVAL_SEC = 0.5


class GodotProjectBusy(RuntimeError):
    """Raised when the project lock could not be acquired within the timeout."""


def lock_path_for(project_dir: Path) -> Path:
    override = os.environ.get(PATH_ENV)
    if override:
        return Path(override)
    digest = hashlib.sha256(str(Path(project_dir).resolve()).encode()).hexdigest()[:12]
    return Path(tempfile.gettempdir()) / f"custodian-godot-project-{digest}.lock"


def _describe_self(purpose: str) -> str:
    return json.dumps({
        "pid": os.getpid(),
        "purpose": purpose,
        "argv": sys.argv[:6],
        "acquired_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
    })


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
        self.path.parent.mkdir(parents=True, exist_ok=True)
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
        self._owns_env = True
        self.acquired = True
        return self

    def __exit__(self, *_exc) -> None:
        if self._owns_env:
            os.environ.pop(REENTRANCY_ENV, None)
            self._owns_env = False
        if self._handle is None:
            return
        try:
            self._handle.seek(0)
            self._handle.truncate()
            self._handle.flush()
            fcntl.flock(self._handle, fcntl.LOCK_UN)
        except OSError:
            pass
        finally:
            self._handle.close()
            self._handle = None
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
