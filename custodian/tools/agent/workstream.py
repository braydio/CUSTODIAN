#!/usr/bin/env python3
"""Manage disposable CUSTODIAN agent workstreams and their safe landing lifecycle."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


class WorkstreamError(RuntimeError):
    pass


ID_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def git(*args: str, cwd: Path | None = None, check: bool = True) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check and p.returncode:
        raise WorkstreamError(f"git {' '.join(args)} failed: {(p.stderr or p.stdout).strip()}")
    return p.stdout.strip()


def validate_id(value: str) -> str:
    if not ID_PATTERN.fullmatch(value):
        raise WorkstreamError("workstream ID must be lowercase kebab-case")
    return value


def root_repo(cwd: Path | None = None) -> Path:
    return Path(git("rev-parse", "--show-toplevel", cwd=cwd)).resolve()


def branch_for(workstream_id: str) -> str:
    return f"agent/{validate_id(workstream_id)}"


def worktree_records(repo: Path) -> list[dict[str, str]]:
    raw = git("worktree", "list", "--porcelain", cwd=repo)
    records: list[dict[str, str]] = []
    current: dict[str, str] = {}
    for line in raw.splitlines() + [""]:
        if not line:
            if current:
                records.append(current)
                current = {}
            continue
        key, _, value = line.partition(" ")
        current[key] = value
    return records


def status_clean(path: Path) -> bool:
    return not git("status", "--porcelain", "--untracked-files=all", cwd=path)


def fetch(repo: Path) -> None:
    git("fetch", "--prune", "origin", cwd=repo)
    git("worktree", "prune", cwd=repo)


def tracking_branch(repo: Path, branch: str) -> None:
    git("branch", "--set-upstream-to", f"origin/{branch}", branch, cwd=repo)


def sync_main(path: Path) -> bool:
    """Merge latest origin/main into a published workstream without rewriting it."""
    head = git("rev-parse", "HEAD", cwd=path)
    main = git("rev-parse", "origin/main", cwd=path)
    ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", main, head], cwd=path)
    if ancestor.returncode == 0:
        return False
    if ancestor.returncode != 1:
        raise WorkstreamError("could not compare workstream with origin/main")
    # If workstream is behind and has no unique commits, this is a fast-forward.
    unique = git("rev-list", "origin/main..HEAD", cwd=path).splitlines()
    if not unique:
        git("merge", "--ff-only", "origin/main", cwd=path)
    else:
        merge = subprocess.run(["git", "merge", "--no-edit", "origin/main"], cwd=path, text=True, capture_output=True)
        if merge.returncode:
            raise WorkstreamError("origin/main merge conflicted; resolve in the preserved worktree")
    return True


def sync_remote_branch(path: Path, branch: str) -> bool:
    remote = f"origin/{branch}"
    head = git("rev-parse", "HEAD", cwd=path)
    remote_head = git("rev-parse", remote, cwd=path)
    if subprocess.run(["git", "merge-base", "--is-ancestor", remote_head, head], cwd=path).returncode == 0:
        return False
    if subprocess.run(["git", "merge-base", "--is-ancestor", head, remote_head], cwd=path).returncode == 0:
        git("merge", "--ff-only", remote, cwd=path)
    else:
        merge = subprocess.run(["git", "merge", "--no-edit", remote], cwd=path, text=True, capture_output=True)
        if merge.returncode:
            raise WorkstreamError("local and remote workstream histories diverged; merge conflicted and worktree was preserved")
    return True


def start(workstream_id: str, repo: Path | None = None) -> Path:
    repo = (repo or root_repo()).resolve()
    branch = branch_for(workstream_id)
    fetch(repo)
    records = worktree_records(repo)
    attached = [r for r in records if r.get("branch") == f"refs/heads/{branch}"]
    if attached:
        path = Path(attached[0]["worktree"]).resolve()
        if path == repo:
            raise WorkstreamError(f"matching branch is attached to the coordination checkout {path}; do not implement there")
        if not status_clean(path):
            raise WorkstreamError(f"branch is attached to a dirty worktree; preserved at {path}")
        # A clean attached checkout is reused rather than duplicated.
        fetch(path)
        remote_changed = sync_remote_branch(path, branch)
        main_changed = sync_main(path)
        if remote_changed or main_changed:
            git("push", "origin", branch, cwd=path)
        print(f"reusing clean attached worktree: {path}")
        return path

    local_exists = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], cwd=repo).returncode == 0
    remote_exists = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo).returncode == 0
    if local_exists:
        raise WorkstreamError(f"local branch {branch} exists but is not attached; inspect/remove it explicitly before start")
    parent = repo.parent
    pool = parent / ".custodian-worktrees"
    pool.mkdir(parents=True, exist_ok=True)
    run_id = datetime.now().strftime("%Y%m%dT%H%M%S")
    path = pool / f"{workstream_id}-{run_id}"
    if path.exists():
        raise WorkstreamError(f"worktree path already exists: {path}")
    if remote_exists:
        git("worktree", "add", "--track", "-b", branch, str(path), f"origin/{branch}", cwd=repo)
        if sync_main(path):
            git("push", "origin", branch, cwd=path)
    else:
        git("worktree", "add", "-b", branch, str(path), "origin/main", cwd=repo)
        git("push", "-u", "origin", branch, cwd=path)
    print(f"workstream: {branch}\nworktree: {path}")
    return path


def validation_green(report: Path) -> bool:
    try:
        data = json.loads(report.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkstreamError(f"cannot read validation report {report}: {exc}") from exc
    if data.get("schema") != "custodian.validation.result.v1" or not data.get("passed", False):
        return False
    tests = data.get("tests", [])
    return bool(tests) and all(isinstance(test, dict) and test.get("status") == "passed" for test in tests)


def find_worktree(repo: Path, branch: str) -> Path:
    for item in worktree_records(repo):
        if item.get("branch") == f"refs/heads/{branch}":
            return Path(item["worktree"]).resolve()
    raise WorkstreamError(f"no attached worktree found for {branch}")


def administrative_worktree(repo: Path, excluded: Path) -> Path:
    candidates = [
        (Path(item["worktree"]).resolve(), item.get("branch", ""))
        for item in worktree_records(repo)
        if Path(item["worktree"]).resolve() != excluded
        and Path(item["worktree"]).resolve().is_dir()
    ]
    main = next((path for path, branch in candidates if branch == "refs/heads/main"), None)
    if main is not None:
        return main
    if candidates:
        return candidates[0][0]
    raise WorkstreamError("cannot find a surviving worktree for safe task teardown")


def checkpoint(workstream_id: str, remove_worktree: bool = False, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    branch = branch_for(workstream_id)
    path = find_worktree(repo, branch)
    if git("branch", "--show-current", cwd=path) != branch:
        raise WorkstreamError("worktree is not on the requested workstream branch")
    git("push", "-u", "origin", branch, cwd=path)
    fetch(repo)
    local = git("rev-parse", "HEAD", cwd=path)
    remote = git("rev-parse", f"origin/{branch}", cwd=repo)
    if local != remote:
        raise WorkstreamError("remote checkpoint verification failed; worktree retained")
    if remove_worktree:
        if not status_clean(path):
            raise WorkstreamError("cannot remove a dirty checkpoint worktree; dirty work is preserved")
        git("worktree", "remove", str(path), cwd=repo)
    print(f"checkpoint retained: origin/{branch} at {remote}; workstream remains active")


def finish(workstream_id: str, validation_report: Path, validation_report_after_sync: Path | None = None, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    branch = branch_for(workstream_id)
    path = find_worktree(repo, branch)
    if git("branch", "--show-current", cwd=path) != branch:
        raise WorkstreamError("finish must run for its matching agent/<workstream-id> branch")
    if not status_clean(path):
        raise WorkstreamError("finish requires a clean worktree and committed task files")
    committed_files = git("diff", "--name-only", "origin/main...HEAD", cwd=path).splitlines()
    if not any(Path(name).name.endswith("_CLAUDE_SUMMARY.md") for name in committed_files):
        raise WorkstreamError("required task closing summary is not committed")
    if not validation_green(validation_report):
        raise WorkstreamError("focused validation report is not green")

    git("push", "-u", "origin", branch, cwd=path)
    fetch(path)
    before = git("rev-parse", "HEAD", cwd=path)
    changed = sync_main(path)
    if changed:
        if validation_report_after_sync is None or not validation_green(validation_report_after_sync):
            raise WorkstreamError("main synchronization changed the tree; provide a green --validation-report-after-sync; recovery state retained")
    git("push", "origin", branch, cwd=path)
    landed = subprocess.run([sys.executable, str(Path(__file__).with_name("land_main.py"))], cwd=path, text=True, capture_output=True)
    if landed.returncode:
        raise WorkstreamError(f"land_main blocked; workstream preserved: {(landed.stderr or landed.stdout).strip()}")
    fetch(path)
    head = git("rev-parse", "HEAD", cwd=path)
    reachable = subprocess.run(["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=path).returncode == 0
    if not reachable:
        raise WorkstreamError("landing did not verify as reachable from origin/main; recovery branch retained")
    admin_repo = administrative_worktree(repo, path)
    git("push", "origin", "--delete", branch, cwd=path)
    git("worktree", "remove", str(path), cwd=admin_repo)
    # The local main branch may intentionally lag origin/main in the coordination
    # checkout. Reachability was proven above against freshly fetched origin/main.
    git("branch", "-D", branch, cwd=admin_repo)
    git("worktree", "prune", cwd=admin_repo)
    git("fetch", "--prune", "origin", cwd=admin_repo)

    # Root checkout sync is subordinate and never alters user state.
    for item in worktree_records(admin_repo):
        root_path = Path(item["worktree"]).resolve()
        if root_path == path:
            continue
        if git("branch", "--show-current", cwd=root_path, check=False) != "main":
            continue
        if status_clean(root_path):
            git("pull", "--ff-only", "origin", "main", cwd=root_path)
            print(f"persistent main checkout synchronized: {root_path}")
        else:
            print(f"persistent root synchronization pending (dirty): {root_path}")
        break
    print(f"finished {branch}; verified {head} reachable from origin/main; remote and local workstream removed")


def status(workstream_id: str | None = None, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    fetch(repo)
    for item in worktree_records(repo):
        branch = item.get("branch", "detached")
        if workstream_id and branch != f"refs/heads/{branch_for(workstream_id)}":
            continue
        path = Path(item["worktree"])
        print(f"{branch}\t{'clean' if status_clean(path) else 'dirty'}\t{path}")
    if workstream_id:
        branch = branch_for(workstream_id)
        print(f"remote {branch}: {'present' if subprocess.run(['git','show-ref','--verify','--quiet',f'refs/remotes/origin/{branch}'],cwd=repo).returncode == 0 else 'absent'}")


def gc(repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    fetch(repo)
    script = Path(__file__).with_name("branch_hygiene.py")
    subprocess.run([sys.executable, str(script)], cwd=repo, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    p = subs.add_parser("start"); p.add_argument("workstream_id")
    p = subs.add_parser("status"); p.add_argument("workstream_id", nargs="?")
    p = subs.add_parser("checkpoint"); p.add_argument("workstream_id"); p.add_argument("--remove-worktree", action="store_true")
    p = subs.add_parser("finish"); p.add_argument("workstream_id"); p.add_argument("--validation-report", type=Path, required=True); p.add_argument("--validation-report-after-sync", type=Path)
    subs.add_parser("gc")
    args = parser.parse_args()
    try:
        if args.command == "start": start(args.workstream_id)
        elif args.command == "status": status(args.workstream_id)
        elif args.command == "checkpoint": checkpoint(args.workstream_id, args.remove_worktree)
        elif args.command == "finish": finish(args.workstream_id, args.validation_report, args.validation_report_after_sync)
        else: gc()
        return 0
    except WorkstreamError as error:
        print(f"workstream: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
