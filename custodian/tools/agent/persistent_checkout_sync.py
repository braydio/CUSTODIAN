#!/usr/bin/env python3
"""Fail-closed synchronization for CUSTODIAN's two persistent checkouts."""
from __future__ import annotations

import argparse
import fcntl
import json
import os
import subprocess
import sys
from contextlib import contextmanager
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Iterator

sys.dont_write_bytecode = True


ROOT_PROFILE = "coordination-main"
ART_PROFILE = "operator-art"
PROFILES = (ROOT_PROFILE, ART_PROFILE)
ART_BRANCH = "workbench/operator-art"
SYNC_LOCK = "custodian-persistent-checkout-sync.lock"


class SyncError(RuntimeError):
    pass


@dataclass
class SyncResult:
    profile: str
    checkout: str
    state: str
    branch: str
    clean: bool
    ahead: int | None
    behind: int | None
    remote_main: str | None
    blockers: list[str]
    changed_paths: list[str]
    action: str

    def as_dict(self) -> dict:
        return asdict(self)


def _git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=root, text=True, capture_output=True, check=False)
    if check and result.returncode:
        raise SyncError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def _top(path: Path) -> Path:
    return Path(_git(path, "rev-parse", "--show-toplevel")).resolve()


def _common_dir(path: Path) -> Path:
    raw = Path(_git(path, "rev-parse", "--git-common-dir"))
    return (path / raw).resolve() if not raw.is_absolute() else raw.resolve()


def _worktrees(path: Path) -> dict[Path, str]:
    result: dict[Path, str] = {}
    current: Path | None = None
    branch = ""
    for line in _git(path, "worktree", "list", "--porcelain").splitlines() + [""]:
        if line.startswith("worktree "):
            current = Path(line.removeprefix("worktree ")).resolve()
            branch = ""
        elif line.startswith("branch "):
            branch = line.removeprefix("branch refs/heads/")
        elif not line and current is not None:
            result[current] = branch
            current = None
    return result


def _status_records(root: Path) -> list[str]:
    raw = subprocess.run(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        cwd=root, capture_output=True, check=True,
    ).stdout
    records: list[str] = []
    fields = raw.split(b"\0")
    index = 0
    while index < len(fields):
        record = fields[index]
        index += 1
        if not record:
            continue
        code = record[:2].decode("ascii", "replace")
        path = record[3:].decode("utf-8", "surrogateescape")
        records.append(f"{code}\t{path}")
        if "R" in code or "C" in code:
            if index < len(fields) and fields[index]:
                records.append("R\t" + fields[index].decode("utf-8", "surrogateescape"))
            index += 1
    return sorted(records)


def _status_paths(records: Iterable[str]) -> list[str]:
    return sorted({record.partition("\t")[2] for record in records if "\t" in record})


def _candidate_paths(paths: Iterable[str]) -> list[str]:
    candidates: set[str] = set()
    for relative in paths:
        normalized = Path(relative)
        candidates.add(normalized.as_posix())
        parent = normalized.parent
        while parent != Path("."):
            candidates.add(parent.as_posix())
            parent = parent.parent
    return sorted(candidates)


def _candidate_state(root: Path, incoming: Iterable[str]) -> tuple[dict[str, str], list[str]]:
    """Inspect only paths that an upcoming fast-forward could touch.

    Ignored siblings are outside Git's mutation set and need no inventory. Exact
    incoming paths and their ancestors are enough to reject overwrite collisions
    and to detect a path appearing during the inspect/apply window.
    """
    incoming_paths = sorted(set(incoming))
    candidates = _candidate_paths(incoming_paths)
    if not candidates:
        return {}, []

    tracked_raw = subprocess.run(
        ["git", "--literal-pathspecs", "ls-files", "-t", "-z", "--", *candidates],
        cwd=root, capture_output=True, check=True,
    ).stdout
    tracked: set[str] = set()
    skip_worktree: set[str] = set()
    for record in tracked_raw.split(b"\0"):
        if len(record) < 3 or record[1:2] != b" ":
            continue
        path = record[2:].decode("utf-8", "surrogateescape")
        tracked.add(path)
        if record[:1] == b"S":
            skip_worktree.add(path)

    state: dict[str, str] = {}
    collisions: list[str] = []
    incoming_set = set(incoming_paths)
    for relative in candidates:
        path = root / relative
        try:
            if not os.path.lexists(path):
                kind = "missing"
            elif path.is_symlink():
                kind = "symlink:" + os.readlink(path)
            elif path.is_dir():
                kind = "directory"
            elif path.is_file():
                kind = "file"
            else:
                kind = "other"
        except OSError as error:
            kind = "unreadable:" + str(error)
        state[relative] = f"{kind}|tracked={relative in tracked}|skip={relative in skip_worktree}"

        if kind == "missing":
            continue
        if relative in incoming_set and (
            kind in {"directory", "other"} or kind.startswith("unreadable")
            or relative not in tracked or relative in skip_worktree
        ):
            collisions.append(f"{relative} (local path {relative})")
            continue
        if relative not in incoming_set and kind != "directory":
            # A non-directory ancestor prevents Git from materializing the
            # incoming descendant. Blocking is safe even when Git could later
            # resolve a tracked file-to-directory transition.
            collisions.append(f"{relative} (local ancestor of incoming path)")
    return state, sorted(set(collisions))


def _relation(root: Path) -> tuple[int | None, int | None, str | None]:
    remote = _git(root, "rev-parse", "--verify", "refs/remotes/origin/main", check=False)
    if not remote:
        return None, None, None
    counts = _git(root, "rev-list", "--left-right", "--count", "HEAD...origin/main").split()
    if len(counts) != 2:
        return None, None, remote
    return int(counts[0]), int(counts[1]), remote


def _fetch_main(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-c", "core.hooksPath=/dev/null", "fetch", "origin", "main"],
        cwd=root, text=True, capture_output=True, check=False,
    )


def _refresh_coordination_graph(root: Path) -> None:
    """Best-effort shared CRG refresh after a successful root fast-forward.

    Agent worktrees intentionally do not maintain independent graphs by default.
    This keeps the persistent coordination checkout useful as the shared baseline
    without making synchronization fail when CRG is unavailable or slow.
    """
    script = root / "tools/crg-refresh.sh"
    if not script.is_file():
        return
    try:
        subprocess.run(
            ["bash", str(script)],
            cwd=root,
            text=True,
            capture_output=True,
            check=False,
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired):
        return


def _art_context(coordination_root: Path):
    operator_dir = Path(__file__).resolve().parents[1] / "operator"
    if str(operator_dir) not in sys.path:
        sys.path.insert(0, str(operator_dir))
    import operator_art_worktree as art
    root = art._top(coordination_root)
    return art, art.default_art_path(root)


def _aseprite_processes(art) -> list[str]:
    return art._running_aseprite_processes()


def _snapshot(profile: str, coordination_root: Path, art_root: Path | None = None) -> tuple[SyncResult, dict]:
    if profile == ROOT_PROFILE:
        requested = coordination_root.resolve()
        root = _top(requested)
        records = _status_records(root)
        branch = _git(root, "branch", "--show-current")
        attached = _worktrees(root).get(root)
        ahead, behind, remote = _relation(root)
        blockers: list[str] = []
        if root != requested:
            blockers.append(f"configured path resolves to a different checkout: {root}")
        if not branch:
            blockers.append("checkout is detached")
            state = "DETACHED"
        elif branch != "main":
            blockers.append(f"checkout is on {branch}, expected main")
            state = "WRONG BRANCH"
        elif attached != "main" or root != requested:
            blockers.append("configured coordination checkout is not present in live Git worktree metadata")
            state = "WRONG CHECKOUT"
        elif records:
            blockers.append("checkout has local tracked or untracked changes")
            blockers.extend(_status_paths(records))
            state = "DIRTY"
        elif ahead is None or behind is None:
            blockers.append("origin/main tracking ref is unavailable")
            state = "UNKNOWN"
        elif ahead and behind:
            blockers.append(f"checkout diverged from origin/main by {ahead} ahead / {behind} behind")
            state = "DIVERGED"
        elif ahead:
            blockers.append(f"checkout has {ahead} local commit(s) ahead of origin/main")
            state = "AHEAD"
        elif behind:
            state = "BEHIND"
        else:
            state = "CURRENT"
        result = SyncResult(profile, str(root), state, branch or "detached", not records,
                            ahead, behind, remote or None, blockers, _status_paths(records), "none")
        incoming = _changed_paths(root, _git(root, "rev-parse", "HEAD"), remote) if behind and remote else []
        candidate_state, _collisions = _candidate_state(root, incoming)
        signature = {"root": str(root), "branch": branch, "records": records, "ahead": ahead,
                     "behind": behind, "remote": remote, "incoming": incoming,
                     "candidate_state": candidate_state}
        return result, signature

    if profile != ART_PROFILE:
        raise SyncError(f"unknown synchronization profile: {profile}")
    art, expected_path = _art_context(coordination_root)
    requested_root = art_root.resolve() if art_root is not None else expected_path.resolve()
    if not requested_root.is_dir():
        result = SyncResult(profile, str(requested_root), "NOT FOUND", "unknown", False,
                            None, None, None, ["persistent Operator art checkout is not attached"], [], "none")
        return result, {"root": str(requested_root), "missing": True}
    root = _top(requested_root)
    requested = root
    records = _status_records(root)
    branch = _git(root, "branch", "--show-current")
    attached = _worktrees(coordination_root).get(root)
    ahead, behind, remote = _relation(root)
    pending = root / art.PENDING_RELATIVE
    workspace = root / ".ai/operator_animation_workbench"
    transaction = art._transaction_status(workspace)
    processes = _aseprite_processes(art)
    sparse_healthy = art._sparse_profile_healthy(root)
    blockers = []
    if not branch:
        blockers.append(f"checkout is detached (expected attached branch {ART_BRANCH})")
        state = "DETACHED"
    elif branch != ART_BRANCH:
        blockers.append(f"checkout is on {branch}, expected {ART_BRANCH}")
        state = "WRONG BRANCH"
    elif attached != ART_BRANCH or requested != expected_path.resolve():
        if attached != ART_BRANCH:
            blockers.append(f"Operator art checkout is not attached to {ART_BRANCH} in live Git worktree metadata")
        if requested != expected_path.resolve():
            blockers.append(f"Operator art path is not the configured persistent checkout: expected {expected_path}")
        state = "WRONG CHECKOUT"
    elif pending.exists():
        blockers.append(f"LAND PENDING receipt exists: {pending}")
        state = "LAND PENDING"
    elif transaction:
        blockers.append(f"Workbench transaction {transaction['state']} requires recovery: {transaction['journal']}")
        state = "RECOVERY REQUIRED"
    elif records:
        blockers.append("checkout has local tracked or untracked changes")
        blockers.extend(_status_paths(records))
        state = "DIRTY"
    elif ahead is None or behind is None:
        blockers.append("origin/main tracking ref is unavailable")
        state = "UNKNOWN"
    elif ahead and behind:
        blockers.append(f"checkout diverged from origin/main by {ahead} ahead / {behind} behind")
        state = "DIVERGED"
    elif ahead:
        blockers.append(f"checkout has {ahead} local commit(s) ahead of origin/main")
        state = "AHEAD"
    elif behind:
        state = "BEHIND"
    elif not sparse_healthy:
        state = "SPARSE PROFILE REPAIR"
    else:
        state = "CURRENT"
    if processes:
        blockers.append("Aseprite is open; synchronization is blocked to protect Workbench documents: " + "; ".join(processes))
        if state in {"BEHIND", "SPARSE PROFILE REPAIR", "CURRENT"}:
            state = "ASEPRITE OPEN"
    incoming = _changed_paths(root, _git(root, "rev-parse", "HEAD"), remote) if behind and remote else []
    candidate_state, _collisions = _candidate_state(root, incoming)
    result = SyncResult(profile, str(root), state, branch or "detached", not records,
                        ahead, behind, remote or None, blockers, _status_paths(records), "none")
    signature = {"root": str(root), "branch": branch, "records": records, "ahead": ahead,
                 "behind": behind, "remote": remote, "pending": pending.exists(),
                 "transaction": transaction, "processes": processes,
                 "sparse_healthy": sparse_healthy, "incoming": incoming,
                 "candidate_state": candidate_state}
    return result, signature


def inspect_profile(profile: str, coordination_root: Path, art_root: Path | None = None) -> SyncResult:
    return _snapshot(profile, coordination_root, art_root)[0]


@contextmanager
def _sync_lock(coordination_root: Path) -> Iterator[None]:
    common = _common_dir(_top(coordination_root))
    path = common / SYNC_LOCK
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a+") as handle:
        try:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise SyncError("SYNC BUSY: another persistent-checkout synchronization is active") from error
        yield


@contextmanager
def _art_creation_guard(coordination_root: Path) -> Iterator[bool]:
    """Serialize against art creation after taking the shared sync lock.

    Art creation never waits for the sync lock while holding this lock, so the
    lock order is always shared-sync then art-creation during synchronization.
    """
    common = _common_dir(_top(coordination_root))
    path = common / "operator-art-worktree.lock"
    with path.open("a+") as handle:
        try:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            yield False
            return
        try:
            yield True
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def _changed_paths(root: Path, old: str, new: str) -> list[str]:
    raw = _git(root, "diff", "--name-only", "-z", old, new)
    return sorted(path for path in raw.split("\0") if path)


def _incoming_collision_paths(root: Path, changed: list[str]) -> list[str]:
    return _candidate_state(root, changed)[1]


def _apply_one(profile: str, coordination_root: Path, art_root: Path | None) -> SyncResult:
    if profile == ART_PROFILE:
        candidate = art_root or _art_context(coordination_root)[1]
        if not candidate.is_dir():
            return _snapshot(profile, coordination_root, art_root)[0]
        root = _top(candidate)
    else:
        root = _top(coordination_root)
    fetched = _fetch_main(root)
    if fetched.returncode:
        before, _signature = _snapshot(profile, coordination_root, art_root)
        before.state = "FETCH FAILED"
        before.blockers.append((fetched.stderr or fetched.stdout).strip())
        before.action = "blocked"
        return before
    before, signature = _snapshot(profile, coordination_root, art_root)
    if before.state == "CURRENT":
        return before
    if before.state == "ASEPRITE OPEN":
        if (profile == ART_PROFILE and before.ahead == 0 and before.behind == 0
                and signature.get("sparse_healthy")):
            before.state = "CURRENT"
            before.blockers.clear()
            return before
        before.action = "blocked"
        return before
    art = _art_context(coordination_root)[0] if profile == ART_PROFILE else None
    can_repair_sparse = profile == ART_PROFILE and before.state == "SPARSE PROFILE REPAIR"
    if before.blockers:
        before.action = "blocked"
        return before
    if before.ahead != 0 or before.behind is None or before.behind < 0:
        before.action = "blocked"
        return before
    if before.behind == 0 and not can_repair_sparse:
        before.action = "none"
        return before
    if profile == ART_PROFILE and signature.get("processes"):
        before.state = "ASEPRITE OPEN"
        before.blockers.append("Aseprite is open; close it before synchronization can change the art checkout")
        before.action = "blocked"
        return before

    old_head = _git(root, "rev-parse", "HEAD")
    target = signature["remote"]
    changed = _changed_paths(root, old_head, target) if before.behind else []
    collisions = _incoming_collision_paths(root, changed)
    if collisions:
        before.state = "PATH COLLISION"
        before.blockers.extend(f"incoming tracked path collides with local untracked/ignored data: {path}" for path in collisions)
        before.action = "blocked"
        return before

    # Re-fetch immediately before mutation. Any remote or checkout movement
    # invalidates the inspected authority; --ff-only remains the final guard.
    fetched = _fetch_main(root)
    if fetched.returncode:
        before.state = "FETCH FAILED"
        before.blockers.append((fetched.stderr or fetched.stdout).strip())
        before.action = "blocked"
        return before
    current, current_signature = _snapshot(profile, coordination_root, art_root)
    if current_signature != signature:
        before.state = "STATE CHANGED"
        before.blockers.append("checkout or origin/main changed after inspection; no synchronization mutation was attempted")
        before.action = "blocked"
        return before

    if before.behind:
        merged = subprocess.run(
            ["git", "-c", "core.hooksPath=/dev/null", "merge", "--ff-only", "origin/main"],
            cwd=root, text=True, capture_output=True, check=False,
            env={**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"},
        )
        if merged.returncode:
            before.state = "FAST-FORWARD FAILED"
            before.blockers.append((merged.stderr or merged.stdout).strip())
            before.action = "blocked"
            return before
        if profile == ROOT_PROFILE:
            _refresh_coordination_graph(root)
    if can_repair_sparse and art is not None:
        try:
            art._apply_sparse_profile(root)
        except Exception as error:
            before.state = "SPARSE PROFILE FAILED"
            before.blockers.append(str(error))
            before.action = "blocked"
            return before
    after, _after_signature = _snapshot(profile, coordination_root, art_root)
    after.changed_paths = changed
    after.action = f"synced {len(changed)} path(s)" if changed else "sparse profile repaired"
    if after.state != "CURRENT":
        after.blockers.append("post-sync verification did not reach CURRENT")
        after.action = "blocked"
    else:
        after.state = "SYNCED" if changed else "CURRENT"
    return after


def apply_profiles(
    profiles: Iterable[str], coordination_root: Path, art_root: Path | None = None,
) -> list[SyncResult]:
    root = _top(coordination_root.resolve())
    selected = list(profiles)
    if not selected or any(profile not in PROFILES for profile in selected):
        raise SyncError(f"profiles must be selected from {', '.join(PROFILES)}")
    try:
        with _sync_lock(root):
            results = []
            for profile in selected:
                if profile == ART_PROFILE:
                    with _art_creation_guard(root) as acquired:
                        if not acquired:
                            results.append(SyncResult(
                                profile, str(art_root or _art_context(root)[1]), "WORKTREE BUSY",
                                "unknown", False, None, None, None,
                                ["Operator art worktree creation is active; retry synchronization after it completes"],
                                [], "blocked",
                            ))
                        else:
                            results.append(_apply_one(profile, root, art_root))
                else:
                    results.append(_apply_one(profile, root, art_root))
            return results
    except SyncError as error:
        if not str(error).startswith("SYNC BUSY"):
            raise
        return [
            SyncResult(profile, str(root if profile == ROOT_PROFILE else (art_root or _art_context(root)[1])),
                       "SYNC BUSY", "unknown", False, None, None, None, [str(error)], [], "blocked")
            for profile in selected
        ]


def format_result(result: SyncResult) -> str:
    relation = ""
    if result.ahead is not None and result.behind is not None:
        relation = f" · ahead {result.ahead}/behind {result.behind}"
    tracking = f" · tracking origin/main {result.remote_main[:12]}" if result.remote_main else ""
    paths = f" · paths: {', '.join(result.changed_paths)}" if result.changed_paths else ""
    blocker = f" · {'; '.join(result.blockers)}" if result.blockers else ""
    action = f" · {result.action}" if result.action != "none" else ""
    return f"{result.profile}: {result.state}{relation}{tracking}{action}{paths}{blocker}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for command in ("status", "apply"):
        item = sub.add_parser(command)
        item.add_argument("target", choices=("both", "root", "art"), nargs="?", default="both")
        item.add_argument("--coordination-root", type=Path, default=None)
        item.add_argument("--art-root", type=Path, default=None)
        item.add_argument("--json", action="store_true")
        item.add_argument("--brief", action="store_true")
    args = parser.parse_args(argv)
    configured = args.coordination_root or (Path(os.environ["CUSTODIAN_REPO"]) if os.environ.get("CUSTODIAN_REPO") else Path.cwd())
    coordination_root = _top(configured.resolve())
    profiles = {
        "both": PROFILES,
        "root": (ROOT_PROFILE,),
        "art": (ART_PROFILE,),
    }[args.target]
    try:
        if args.command == "status":
            results = [inspect_profile(profile, coordination_root, args.art_root) for profile in profiles]
        else:
            results = apply_profiles(profiles, coordination_root, args.art_root)
    except (OSError, SyncError) as error:
        print(f"persistent-checkout-sync: ERROR: {error}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps({"schema": "custodian.persistent_checkout_sync.v1", "results": [item.as_dict() for item in results]}, sort_keys=True))
    else:
        print("\n".join(format_result(item) for item in results))
    if any(item.state in {"FETCH FAILED", "FAST-FORWARD FAILED", "SPARSE PROFILE FAILED", "IGNORED STATE CHANGED"} for item in results):
        return 2
    if any(item.action == "blocked" or item.state == "NOT FOUND" for item in results):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
