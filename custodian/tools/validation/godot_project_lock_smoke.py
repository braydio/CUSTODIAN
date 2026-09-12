#!/usr/bin/env python3
"""Prove the Godot project lock actually serializes concurrent writers.

Two overlapping `run_validation.py` runs reproducibly stalled the import step
until it timed out. A lock is only worth having if mutual exclusion is real, so
this asserts the behaviour rather than the presence of the code: a second
acquirer must block, must time out with a message naming the holder, and must
succeed once the holder releases.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CUSTODIAN_ROOT))
from godot_project_lock import (  # noqa: E402
    DISABLE_ENV, PATH_ENV, REENTRANCY_ENV, GodotProjectBusy, GodotProjectLock,
    lock_path_for,
)

HOLDER = """
import os, sys, time
sys.path.insert(0, %r)
from godot_project_lock import GodotProjectLock
with GodotProjectLock(%r, "smoke-holder", timeout_sec=30):
    sys.stdout.write("HELD\\n"); sys.stdout.flush()
    time.sleep(float(sys.argv[1]))
"""


def main() -> int:
    failures: list[str] = []

    def check(condition: bool, message: str) -> None:
        if not condition:
            failures.append(message)

    with tempfile.TemporaryDirectory(prefix="godot-lock-smoke-") as temp:
        project = Path(temp) / "project"
        project.mkdir()
        lock_file = Path(temp) / "smoke.lock"
        env_overrides = {PATH_ENV: str(lock_file)}
        os.environ.update(env_overrides)
        os.environ.pop(REENTRANCY_ENV, None)
        os.environ.pop(DISABLE_ENV, None)

        # Derived paths are stable and outside the repository.
        os.environ.pop(PATH_ENV)
        derived = lock_path_for(Path(temp) / "other")
        check(
            derived == lock_path_for(Path(temp) / "other"),
            "lock path must be deterministic for one project",
        )
        check(
            derived != lock_path_for(Path(temp) / "another"),
            "different projects must not share a lock file",
        )
        check(
            CUSTODIAN_ROOT.parent not in derived.parents,
            "the lock file must live outside the repository",
        )
        os.environ[PATH_ENV] = str(lock_file)

        # A second in-process acquirer must be refused while the first holds it.
        holder = subprocess.Popen(
            [sys.executable, "-c", HOLDER % (str(CUSTODIAN_ROOT), str(project)), "3"],
            stdout=subprocess.PIPE, text=True, env=os.environ.copy(),
        )
        try:
            assert holder.stdout is not None
            if holder.stdout.readline().strip() != "HELD":
                failures.append("holder process never acquired the lock")
                holder.kill()
                return _report(failures)

            started = time.monotonic()
            try:
                with GodotProjectLock(project, "smoke-contender", timeout_sec=1.0):
                    failures.append("a second process acquired a lock already held")
            except GodotProjectBusy as error:
                waited = time.monotonic() - started
                check(waited >= 1.0, "contender gave up before its timeout elapsed")
                check(
                    "smoke-holder" in str(error),
                    "the busy error must name the holder, got: %s" % error,
                )

            # Reentrancy: a nested tool inside a locked run must not deadlock.
            os.environ[REENTRANCY_ENV] = str(lock_file)
            nested = GodotProjectLock(project, "smoke-nested", timeout_sec=1.0)
            with nested:
                check(not nested.acquired, "a reentrant acquire must not re-lock")
            os.environ.pop(REENTRANCY_ENV, None)

            # The bypass must be honoured, for debugging a stuck lock.
            os.environ[DISABLE_ENV] = "1"
            disabled = GodotProjectLock(project, "smoke-disabled", timeout_sec=1.0)
            with disabled:
                check(not disabled.acquired, "the disable env var must skip locking")
            os.environ.pop(DISABLE_ENV)
        finally:
            holder.wait(timeout=30)

        # Once the holder exits, the lock is free again.
        acquired_after_release = GodotProjectLock(project, "smoke-after", timeout_sec=10.0)
        with acquired_after_release:
            check(
                acquired_after_release.acquired,
                "the lock must be acquirable once the holder releases it",
            )

        # A killed holder must not strand the project: flock dies with the process.
        stranded = subprocess.Popen(
            [sys.executable, "-c", HOLDER % (str(CUSTODIAN_ROOT), str(project)), "60"],
            stdout=subprocess.PIPE, text=True, env=os.environ.copy(),
        )
        assert stranded.stdout is not None
        if stranded.stdout.readline().strip() != "HELD":
            failures.append("stranded-holder process never acquired the lock")
        stranded.kill()
        stranded.wait(timeout=30)
        recovered = GodotProjectLock(project, "smoke-recovered", timeout_sec=10.0)
        with recovered:
            check(
                recovered.acquired,
                "a killed holder must release the lock, not strand the project",
            )

    return _report(failures)


def _report(failures: list[str]) -> int:
    if failures:
        for message in failures:
            print("FAIL %s" % message, file=sys.stderr)
        return 1
    print("godot project lock smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
