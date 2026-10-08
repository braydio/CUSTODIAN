#!/usr/bin/env python3
"""Temporary-repository fixtures for persistent checkout synchronization."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
from types import SimpleNamespace
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
AGENT_TOOLS = Path(__file__).resolve().parents[1] / "agent"
sys.path.insert(0, str(AGENT_TOOLS))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "operator"))
import persistent_checkout_sync as sync
import operator_art_worktree as art
from ui.service import WorkbenchService

_fixture_path = Path(__file__).with_name("operator_art_worktree_smoke.py")
_fixture_spec = importlib.util.spec_from_file_location("operator_art_fixture", _fixture_path)
_fixture_module = importlib.util.module_from_spec(_fixture_spec)
assert _fixture_spec.loader
_fixture_spec.loader.exec_module(_fixture_module)
fixture = _fixture_module.fixture
SOURCE = _fixture_module.SOURCE


def git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=root, text=True, capture_output=True, check=False)
    if check and result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


def checkout_fingerprint(root: Path) -> tuple:
    head = git(root, "rev-parse", "HEAD")
    branch = git(root, "branch", "--show-current")
    index = Path(git(root, "rev-parse", "--git-path", "index"))
    if not index.is_absolute():
        index = root / index
    index_hash = hashlib.sha256(index.read_bytes()).hexdigest()
    tracked = git(root, "ls-files", "-z").split("\0")
    untracked = git(root, "ls-files", "--others", "--exclude-standard", "-z").split("\0")
    files = {}
    for relative in sorted(set(tracked + untracked) - {""}):
        path = root / relative
        if path.is_symlink():
            files[relative] = "symlink:" + os.readlink(path)
        elif path.is_file():
            files[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
        elif path.exists():
            files[relative] = "exists"
        else:
            files[relative] = "missing"
    return head, branch, index_hash, files, sync._ignored_manifest(root)


def advance_remote(base: Path, bare: Path, relative: str = "README.md", data: bytes = b"remote update\n") -> str:
    donor = base / f"donor-{len(list(base.glob('donor-*')))}"
    subprocess.run(["git", "clone", str(bare), str(donor)], check=True, capture_output=True)
    git(donor, "checkout", "-B", "main", "origin/main")
    git(donor, "config", "user.name", "Sync Fixture")
    git(donor, "config", "user.email", "sync@example.invalid")
    path = donor / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    git(donor, "add", "-f", relative)
    git(donor, "commit", "-m", "advance origin main")
    git(donor, "push", "origin", "main")
    return git(donor, "rev-parse", "HEAD")


def result(profile: str, root: Path, art_root: Path | None = None):
    return sync.inspect_profile(profile, root, art_root)


def root_sync_smoke(base: Path) -> None:
    bare, coordination, _source = fixture(base)
    ignored = coordination / ".ai/operator-ui-venv/preserve.bin"
    ignored.parent.mkdir(parents=True)
    ignored.write_bytes(b"venv bytes\x00keep")
    ignored_hash = hashlib.sha256(ignored.read_bytes()).hexdigest()
    remote_head = advance_remote(base, bare)

    tracking_before = git(coordination, "rev-parse", "origin/main")
    fetch_head_before = (coordination / ".git/FETCH_HEAD").read_bytes()
    before = result(sync.ROOT_PROFILE, coordination)
    assert before.state == "CURRENT", "read-only inspect uses the already-fetched tracking ref"
    assert git(coordination, "rev-parse", "origin/main") == tracking_before
    assert (coordination / ".git/FETCH_HEAD").read_bytes() == fetch_head_before
    destructive: list[list[str]] = []
    merges: list[tuple[list[str], dict]] = []
    run = sync.subprocess.run

    def observe_git(args, **kwargs):
        if args and args[0] == "git":
            if len(args) > 1 and args[1] in {"reset", "stash", "rebase", "clean", "checkout", "switch"}:
                destructive.append(args)
            if "merge" in args:
                merges.append((args, kwargs))
        return run(args, **kwargs)

    with mock.patch.object(sync.subprocess, "run", side_effect=observe_git):
        synced = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert synced.state == "SYNCED", synced
    assert not destructive
    assert len(merges) == 1 and "--ff-only" in merges[0][0]
    assert merges[0][1]["env"]["GIT_LFS_SKIP_SMUDGE"] == "1"
    assert git(coordination, "rev-parse", "HEAD") == remote_head
    assert hashlib.sha256(ignored.read_bytes()).hexdigest() == ignored_hash
    current = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert current.state == "CURRENT" and current.action == "none", current
    assert result(sync.ROOT_PROFILE, coordination).state == "CURRENT"


def root_preservation_smoke(base: Path) -> None:
    bare, coordination, _source = fixture(base)
    advance_remote(base, bare)
    local = coordination / "untracked-user.txt"
    local.write_text("preserve this\n")
    dirty_before = checkout_fingerprint(coordination)
    dirty = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert dirty.state == "DIRTY" and "untracked-user.txt" in dirty.changed_paths
    assert checkout_fingerprint(coordination) == dirty_before and local.read_text() == "preserve this\n"
    local.unlink()
    caught_up = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert caught_up.state == "SYNCED", caught_up
    head = git(coordination, "rev-parse", "HEAD")

    git(coordination, "checkout", "-b", "fixture/wrong")
    wrong_before = checkout_fingerprint(coordination)
    wrong = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert wrong.state == "WRONG BRANCH" and checkout_fingerprint(coordination) == wrong_before
    git(coordination, "checkout", "main")
    git(coordination, "checkout", "--detach", "HEAD")
    detached_before = checkout_fingerprint(coordination)
    detached = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert detached.state == "DETACHED" and checkout_fingerprint(coordination) == detached_before
    git(coordination, "checkout", "main")

    (coordination / "local-ahead.txt").write_text("ahead\n")
    git(coordination, "add", "local-ahead.txt")
    git(coordination, "commit", "-m", "local ahead")
    ahead_head = git(coordination, "rev-parse", "HEAD")
    ahead_before = checkout_fingerprint(coordination)
    ahead = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert ahead.state == "AHEAD" and ahead.ahead == 1 and ahead.behind == 0
    assert git(coordination, "rev-parse", "HEAD") == ahead_head and checkout_fingerprint(coordination) == ahead_before

    advance_remote(base, bare, "README.md", b"remote diverged\n")
    diverged_before = checkout_fingerprint(coordination)
    diverged = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert diverged.state == "DIVERGED" and diverged.ahead == 1 and diverged.behind == 1
    assert git(coordination, "rev-parse", "HEAD") == ahead_head and checkout_fingerprint(coordination) == diverged_before


def art_sync_smoke(base: Path) -> None:
    bare, coordination, _source = fixture(base)
    art_root = art.ensure_art_worktree(coordination)
    local = art_root / ".ai/operator_animation_workbench/frames/session.aseprite"
    local.parent.mkdir(parents=True)
    local.write_bytes(b"ignored document\x00preserved")
    before_hash = hashlib.sha256(local.read_bytes()).hexdigest()
    remote_head = advance_remote(base, bare)
    with mock.patch.object(art, "_running_aseprite_processes", return_value=[]):
        synced = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert synced.state == "SYNCED", synced
    assert git(art_root, "rev-parse", "HEAD") == remote_head
    assert art._sparse_profile_healthy(art_root)
    assert hashlib.sha256(local.read_bytes()).hexdigest() == before_hash

    git(art_root, "sparse-checkout", "disable")
    with mock.patch.object(art, "_running_aseprite_processes", return_value=[]):
        repaired = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert repaired.state == "CURRENT" and art._sparse_profile_healthy(art_root), repaired
    assert hashlib.sha256(local.read_bytes()).hexdigest() == before_hash

    advance_remote(base, bare, "README.md", b"aseprite blocked update\n")
    head = git(art_root, "rev-parse", "HEAD")
    with mock.patch.object(art, "_running_aseprite_processes", return_value=["aseprite --fixture"]):
        blocked = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert blocked.state == "ASEPRITE OPEN" and git(art_root, "rev-parse", "HEAD") == head

    service = object.__new__(WorkbenchService)
    service.checkout_identity = lambda: SimpleNamespace(
        kind="DEDICATED ART", sparse_profile="sparse operator-authoring-v1",
        branch=art.ART_BRANCH, main_relation="behind 1", worktree_state="clean",
    )
    service.readiness = lambda _selection=None: SimpleNamespace(status="ready", pending_land=False)
    old = os.environ.get("CUSTODIAN_SYNC_STATUS")
    os.environ["CUSTODIAN_SYNC_STATUS"] = "operator-art: ASEPRITE OPEN · close Aseprite"
    try:
        label = WorkbenchService.checkout_status_label(service)
    finally:
        if old is None:
            os.environ.pop("CUSTODIAN_SYNC_STATUS", None)
        else:
            os.environ["CUSTODIAN_SYNC_STATUS"] = old
    assert "operator-art: ASEPRITE OPEN" in label and "close Aseprite" in label


def art_blocker_smoke(base: Path) -> None:
    bare, coordination, _source = fixture(base)
    art_root = art.ensure_art_worktree(coordination)
    advance_remote(base, bare)
    head = git(art_root, "rev-parse", "HEAD")

    pending = art_root / art.PENDING_RELATIVE
    pending.parent.mkdir(parents=True)
    pending.write_text('{"state":"LAND PENDING"}\n')
    pending_before = checkout_fingerprint(art_root)
    state = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert state.state == "LAND PENDING" and pending.exists()
    assert git(art_root, "rev-parse", "HEAD") == head and checkout_fingerprint(art_root) == pending_before
    pending.unlink()

    journal = art_root / ".ai/operator_animation_workbench/transactions/fixture/transaction.json"
    journal.parent.mkdir(parents=True, exist_ok=True)
    journal.write_text('{"state":"APPLYING"}\n')
    recovery_before = checkout_fingerprint(art_root)
    state = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert state.state == "RECOVERY REQUIRED" and journal.exists()
    assert git(art_root, "rev-parse", "HEAD") == head and checkout_fingerprint(art_root) == recovery_before
    journal.unlink()

    dirty = art_root / "user-edit.txt"
    dirty.write_text("do not overwrite\n")
    dirty_before = checkout_fingerprint(art_root)
    state = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert state.state == "DIRTY" and dirty.read_text() == "do not overwrite\n"
    assert git(art_root, "rev-parse", "HEAD") == head and checkout_fingerprint(art_root) == dirty_before
    dirty.unlink()

    with mock.patch.object(art, "_running_aseprite_processes", return_value=[]):
        caught_up = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert caught_up.state == "SYNCED", caught_up
    (art_root / "custodian/content/sprites/operator/ahead-fixture.txt").write_text("local commit\n")
    git(art_root, "add", "custodian/content/sprites/operator/ahead-fixture.txt")
    git(art_root, "commit", "-m", "local art ahead")
    ahead_head = git(art_root, "rev-parse", "HEAD")
    ahead_before = checkout_fingerprint(art_root)
    ahead = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert ahead.state == "AHEAD" and ahead.ahead == 1 and ahead.behind == 0
    assert git(art_root, "rev-parse", "HEAD") == ahead_head and checkout_fingerprint(art_root) == ahead_before
    advance_remote(base, bare, "README.md", b"art divergence\n")
    diverged_before = checkout_fingerprint(art_root)
    diverged = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert diverged.state == "DIVERGED" and diverged.ahead == 1 and diverged.behind == 1
    assert git(art_root, "rev-parse", "HEAD") == ahead_head and checkout_fingerprint(art_root) == diverged_before

    git(art_root, "checkout", "-b", "fixture/wrong-art")
    wrong_before = checkout_fingerprint(art_root)
    wrong = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert wrong.state == "WRONG BRANCH" and checkout_fingerprint(art_root) == wrong_before
    git(art_root, "checkout", art.ART_BRANCH)

    git(art_root, "checkout", "--detach", "HEAD")
    detached_before = checkout_fingerprint(art_root)
    detached = sync.apply_profiles([sync.ART_PROFILE], coordination, art_root)[0]
    assert detached.state == "DETACHED" and checkout_fingerprint(art_root) == detached_before


def lock_and_race_smoke(base: Path) -> None:
    bare, coordination, _source = fixture(base)
    advance_remote(base, bare)
    head = git(coordination, "rev-parse", "HEAD")
    entered = threading.Event()
    release = threading.Event()
    real_fetch = sync._fetch_main
    fetch_count = 0

    def pause_first_fetch(root: Path):
        nonlocal fetch_count
        fetch_count += 1
        if fetch_count == 1:
            entered.set()
            assert release.wait(10), "timed out waiting to release first sync"
        return real_fetch(root)

    with mock.patch.object(sync, "_fetch_main", side_effect=pause_first_fetch):
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(sync.apply_profiles, [sync.ROOT_PROFILE], coordination)
            assert entered.wait(10), "first sync did not enter its mutation lock"
            second = pool.submit(sync.apply_profiles, [sync.ROOT_PROFILE], coordination)
            busy = second.result(timeout=10)[0]
            release.set()
            synced = first.result(timeout=10)[0]
    assert busy.state == "SYNC BUSY" and synced.state == "SYNCED"
    assert git(coordination, "rev-parse", "HEAD") == git(coordination, "rev-parse", "origin/main")

    # Remote advancement between the first inspect and the immediate re-fetch
    # must reject the mutation without moving the checkout.
    remote_race = base / "remote-race"
    remote_race.mkdir()
    bare, coordination, _source = fixture(remote_race)
    advance_remote(remote_race, bare)
    head = git(coordination, "rev-parse", "HEAD")
    real_fetch = sync._fetch_main
    calls = 0

    def advance_during_revalidation(root: Path):
        nonlocal calls
        calls += 1
        if calls == 2:
            advance_remote(remote_race, bare, "README.md", b"raced remote advance\n")
        return real_fetch(root)

    with mock.patch.object(sync, "_fetch_main", side_effect=advance_during_revalidation):
        raced = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert raced.state == "STATE CHANGED" and git(coordination, "rev-parse", "HEAD") == head

    # A local edit that appears after inspect is likewise a fail-closed race.
    checkout_race = base / "checkout-race"
    checkout_race.mkdir()
    bare, coordination, _source = fixture(checkout_race)
    advance_remote(checkout_race, bare)
    head = git(coordination, "rev-parse", "HEAD")
    calls = 0

    def dirty_during_revalidation(root: Path):
        nonlocal calls
        calls += 1
        if calls == 2:
            (root / "late-user-edit.txt").write_text("preserve late edit\n")
        return real_fetch(root)

    with mock.patch.object(sync, "_fetch_main", side_effect=dirty_during_revalidation):
        changed = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert changed.state == "STATE CHANGED"
    assert git(coordination, "rev-parse", "HEAD") == head
    assert (coordination / "late-user-edit.txt").read_text() == "preserve late edit\n"


def ignored_collision_smoke(base: Path) -> None:
    bare, coordination, _source = fixture(base)
    local = coordination / ".ai/operator_animation_workbench/preserve.json"
    local.parent.mkdir(parents=True)
    local.write_text('{"local":true}\n')
    before_hash = hashlib.sha256(local.read_bytes()).hexdigest()
    advance_remote(base, bare, local.relative_to(coordination).as_posix(), b'{"remote":true}\n')
    state = sync.apply_profiles([sync.ROOT_PROFILE], coordination)[0]
    assert state.state == "PATH COLLISION" and git(coordination, "rev-parse", "HEAD") != git(coordination, "rev-parse", "origin/main")
    assert hashlib.sha256(local.read_bytes()).hexdigest() == before_hash


def shell_routing_smoke(base: Path) -> None:
    home = base / "home"
    python = home / "Projects/CUSTODIAN/.ai/operator-ui-venv/bin/python"
    python.parent.mkdir(parents=True)
    log = base / "commands.jsonl"
    python.write_text(
        "#!/usr/bin/env python3\n"
        "import json, os, pathlib, sys\n"
        "with open(os.environ['CSYNC_CAPTURE'], 'a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')\n"
        "print('fixture status')\n"
    )
    python.chmod(0o755)
    shell = (
        f"source {ROOT / 'tools/custodian_aliases.sh'}; "
        "csync; csync root; csync art; csync status; opui-sync"
    )
    result = subprocess.run(
        ["bash", "-c", shell], env={**os.environ, "HOME": str(home), "CSYNC_CAPTURE": str(log)},
        text=True, capture_output=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    calls = [json.loads(line) for line in log.read_text().splitlines()]
    assert [call[1:3] for call in calls] == [
        ["apply", "both"], ["apply", "root"], ["apply", "art"],
        ["status", "both"], ["apply", "art"],
    ], calls
    assert all("persistent_checkout_sync.py" in call[0] for call in calls)


def main() -> None:
    cases = [
        root_sync_smoke, root_preservation_smoke, art_sync_smoke,
        art_blocker_smoke, lock_and_race_smoke, ignored_collision_smoke,
        shell_routing_smoke,
    ]
    for case in cases:
        with tempfile.TemporaryDirectory(prefix=f"{case.__name__}-") as temporary:
            case(Path(temporary))
        print(f"PASS: {case.__name__}")
    print("Persistent checkout sync smoke: PASS")


if __name__ == "__main__":
    main()
