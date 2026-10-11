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
    BUDGET_REENTRANCY_ENV, DEFAULT_MAX_JOBS, DISABLE_ENV, MAX_JOBS_ENV, PATH_ENV, REENTRANCY_ENV,
    SCRATCH_ENV, GodotJobBudget, GodotProjectBusy, GodotProjectLock,
    godot_home, inherited_job_budget_fds, lock_path_for, scratch_root,
)

HOLDER = """
import os, sys, time
sys.path.insert(0, %r)
from godot_project_lock import GodotProjectLock
with GodotProjectLock(%r, "smoke-holder", timeout_sec=30):
    sys.stdout.write("HELD\\n"); sys.stdout.flush()
    time.sleep(float(sys.argv[1]))
"""

BUDGET_HOLDER = """
import sys, time
sys.path.insert(0, %r)
from godot_project_lock import GodotJobBudget
with GodotJobBudget("smoke-holder", timeout_sec=10):
    print("HELD", flush=True)
    time.sleep(float(sys.argv[1]))
"""

BUDGET_ORPHAN = """
import os, subprocess, sys
sys.path.insert(0, %r)
from godot_project_lock import GodotJobBudget, inherited_job_budget_fds
with GodotJobBudget("smoke-orphan-parent", timeout_sec=10):
    subprocess.Popen([sys.executable, "-c", "import time; time.sleep(2)"],
                     env=os.environ.copy(), pass_fds=inherited_job_budget_fds(),
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("SPAWNED", flush=True)
"""

LOCK_PATH_PROBE = """
import sys
sys.path.insert(0, %r)
from godot_project_lock import lock_path_for
print(lock_path_for(__import__('pathlib').Path(sys.argv[1])))
"""


def main() -> int:
    failures: list[str] = []

    def check(condition: bool, message: str) -> None:
        if not condition:
            failures.append(message)

    with tempfile.TemporaryDirectory(prefix="godot-lock-cache-") as cache, \
            tempfile.TemporaryDirectory(prefix="godot-lock-tmp-a-") as tmp_a, \
            tempfile.TemporaryDirectory(prefix="godot-lock-tmp-b-") as tmp_b:
        old_cache = os.environ.get("XDG_CACHE_HOME")
        old_tmp = os.environ.get("TMPDIR")
        old_temp = tempfile.tempdir
        project = str(Path(cache) / "project")
        env_a = os.environ.copy()
        env_a["XDG_CACHE_HOME"] = cache
        env_a["TMPDIR"] = tmp_a
        env_a.pop(PATH_ENV, None)
        env_b = dict(env_a, TMPDIR=tmp_b)
        lock_a = subprocess.run(
            [sys.executable, "-c", LOCK_PATH_PROBE % str(CUSTODIAN_ROOT), project],
            capture_output=True, text=True, check=True, env=env_a,
        ).stdout.strip()
        lock_b = subprocess.run(
            [sys.executable, "-c", LOCK_PATH_PROBE % str(CUSTODIAN_ROOT), project],
            capture_output=True, text=True, check=True, env=env_b,
        ).stdout.strip()
        check(lock_a == lock_b, "project lock path must not split when TMPDIR changes")
        tempfile.tempdir = old_temp
        if old_cache is None:
            os.environ.pop("XDG_CACHE_HOME", None)
        else:
            os.environ["XDG_CACHE_HOME"] = old_cache
        if old_tmp is None:
            os.environ.pop("TMPDIR", None)
        else:
            os.environ["TMPDIR"] = old_tmp

    with tempfile.TemporaryDirectory(prefix="godot-scratch-smoke-") as temp:
        root = Path(temp) / "scratch"
        os.environ[SCRATCH_ENV] = str(root)
        resolved = scratch_root()
        home = godot_home()
        check(resolved == root and home == root / "godot-home", "Godot home must resolve under configured scratch")
        check(root.stat().st_mode & 0o777 == 0o700, "scratch root must be mode 0700")
        check(home.stat().st_mode & 0o777 == 0o700, "Godot home must be mode 0700")
        os.environ.pop(SCRATCH_ENV, None)

    with tempfile.TemporaryDirectory(prefix="godot-budget-smoke-") as cache:
        old_cache = os.environ.get("XDG_CACHE_HOME")
        old_limit = os.environ.get(MAX_JOBS_ENV)
        os.environ["XDG_CACHE_HOME"] = cache
        os.environ.pop(MAX_JOBS_ENV, None)
        check(GodotJobBudget("smoke-default").limit == DEFAULT_MAX_JOBS == 2,
              "default machine-wide budget must be two jobs")
        os.environ[MAX_JOBS_ENV] = "2"
        os.environ.pop(BUDGET_REENTRANCY_ENV, None)
        os.environ.pop(REENTRANCY_ENV, None)
        holders = [subprocess.Popen(
            [sys.executable, "-c", BUDGET_HOLDER % str(CUSTODIAN_ROOT), "2"],
            stdout=subprocess.PIPE, text=True, env=os.environ.copy(),
        ) for _ in range(2)]
        try:
            for holder in holders:
                assert holder.stdout is not None
                check(holder.stdout.readline().strip() == "HELD", "budget holder failed to acquire a slot")
            waiter = subprocess.run(
                [sys.executable, "-c", BUDGET_HOLDER % str(CUSTODIAN_ROOT), "0"],
                capture_output=True, text=True, env=os.environ.copy(), timeout=10,
            )
            check(waiter.returncode == 0, "N+1 job must acquire a released slot")
            check("waiting for a machine-wide Godot slot" in waiter.stderr,
                  "N+1 job must print a clear slot wait message")
            outer = GodotJobBudget("smoke-reentrant", timeout_sec=2)
            with outer:
                check(outer.acquired, "budget must acquire a free slot")
                inner = GodotJobBudget("smoke-nested", timeout_sec=1)
                with inner:
                    check(not inner.acquired, "nested run must reuse the held budget slot")
        finally:
            for holder in holders:
                holder.wait(timeout=10)

        stranded = subprocess.Popen(
            [sys.executable, "-c", BUDGET_HOLDER % str(CUSTODIAN_ROOT), "60"],
            stdout=subprocess.PIPE, text=True, env=os.environ.copy(),
        )
        assert stranded.stdout is not None
        check(stranded.stdout.readline().strip() == "HELD", "stale-holder fixture failed to acquire a slot")
        stranded.kill()
        stranded.wait(timeout=10)
        recovered = GodotJobBudget("smoke-stale-recovery", timeout_sec=2)
        with recovered:
            check(recovered.acquired, "a dead holder must release its budget slot")

        os.environ[MAX_JOBS_ENV] = "1"
        orphan = subprocess.run(
            [sys.executable, "-c", BUDGET_ORPHAN % str(CUSTODIAN_ROOT)],
            capture_output=True, text=True, env=os.environ.copy(), timeout=10,
        )
        check(orphan.returncode == 0 and "SPAWNED" in orphan.stdout,
              "budget holder fixture must spawn an inherited child")
        try:
            with GodotJobBudget("smoke-child-retention", timeout_sec=0.5):
                failures.append("a child outlived its parent but did not retain the budget slot")
        except GodotProjectBusy:
            pass
        time.sleep(2.0)
        with GodotJobBudget("smoke-child-released", timeout_sec=2) as after_child:
            check(after_child.acquired, "child exit must release the inherited budget slot")
        os.environ[MAX_JOBS_ENV] = "2"

        project = Path(cache) / "project"
        project.mkdir()
        with GodotProjectLock(project, "project-lock-with-budget", timeout_sec=2) as project_lock:
            with GodotJobBudget("budget-with-project-lock", timeout_sec=2) as budget:
                check(project_lock.acquired and budget.acquired,
                      "job budget must layer on top of the per-project lock")
        if old_cache is None:
            os.environ.pop("XDG_CACHE_HOME", None)
        else:
            os.environ["XDG_CACHE_HOME"] = old_cache
        if old_limit is None:
            os.environ.pop(MAX_JOBS_ENV, None)
        else:
            os.environ[MAX_JOBS_ENV] = old_limit

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
