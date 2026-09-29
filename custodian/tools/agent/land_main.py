#!/usr/bin/env python3
"""Safely land a clean task branch on origin/main without force-pushing."""

from __future__ import annotations

import argparse
import fcntl
import os
import subprocess
import sys
from pathlib import Path

# TEMP_LFS_DEGRADED_MODE_START expires=2026-10-01T04:00:00Z
from datetime import datetime, timezone

_LFS_DEGRADED_MODE_EXPIRES_UTC = datetime(2026, 10, 1, 4, 0, tzinfo=timezone.utc)
if datetime.now(timezone.utc) < _LFS_DEGRADED_MODE_EXPIRES_UTC:
    os.environ.setdefault("GIT_LFS_SKIP_SMUDGE", "1")
# TEMP_LFS_DEGRADED_MODE_END

class LandingError(RuntimeError):
    pass


def git(*args: str, check: bool = True, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args], cwd=cwd, text=True, capture_output=True, check=False
    )
    if check and result.returncode:
        detail = (result.stderr or result.stdout).strip()
        raise LandingError(f"git {' '.join(args)} failed: {detail}")
    return result


def repo_root() -> Path:
    return Path(git("rev-parse", "--show-toplevel").stdout.strip())


def common_dir(root: Path) -> Path:
    raw = Path(git("rev-parse", "--git-common-dir", cwd=root).stdout.strip())
    return (root / raw).resolve() if not raw.is_absolute() else raw.resolve()


def ensure_clean(root: Path) -> None:
    status = git("status", "--porcelain", "--untracked-files=all", cwd=root).stdout
    if status:
        raise LandingError("worktree must be clean and fully committed before landing")


def branch_name(root: Path) -> str:
    result = git("symbolic-ref", "--quiet", "--short", "HEAD", check=False, cwd=root)
    if result.returncode:
        raise LandingError("detached HEAD cannot be landed")
    return result.stdout.strip()


def commits_to_replay(root: Path, base: str) -> list[str]:
    raw = git("rev-list", "--reverse", f"{base}..HEAD", cwd=root).stdout
    return [line for line in raw.splitlines() if line]


def already_published_elsewhere(root: Path, commits: list[str], target_ref: str) -> str | None:
    remote_refs = git("for-each-ref", "--format=%(refname)", "refs/remotes", cwd=root).stdout.splitlines()
    # A push-first workstream intentionally publishes its own commits before
    # landing. Ignore only that branch's configured upstream; other remote refs
    # remain a blocker because landing rebases the local copy.
    upstream = git("rev-parse", "--symbolic-full-name", "@{upstream}", check=False, cwd=root)
    branch = branch_name(root)
    expected_own_upstream = target_ref.rsplit("/", 1)[0] + f"/{branch}"
    own_upstream = (
        expected_own_upstream
        if upstream.returncode == 0 and upstream.stdout.strip() == expected_own_upstream
        else ""
    )
    for commit in commits:
        for ref in remote_refs:
            if ref in {target_ref, own_upstream}:
                continue
            contained = git("merge-base", "--is-ancestor", commit, ref, check=False, cwd=root)
            if contained.returncode == 0:
                return f"{commit[:12]} is already published on {ref}; refusing to rewrite pushed history"
    return None


def fetch_main(root: Path, remote: str, target: str) -> str:
    local_ref = f"refs/remotes/{remote}/{target}"
    # Refresh the remote's other tracking refs too so the pushed-history guard
    # does not reason from stale knowledge of a previously published task head.
    git("fetch", "--no-tags", remote, cwd=root)
    git("fetch", "--no-tags", remote, f"refs/heads/{target}:{local_ref}", cwd=root)
    return local_ref


def land(remote: str = "origin", target: str = "main", attempts: int = 3, dry_run: bool = False) -> int:
    if not dry_run and os.environ.get("CUSTODIAN_WORKSTREAM_FINISH") != "1":
        raise LandingError(
            "direct landing is disabled; complete implementation work with "
            "workstream.py finish <workstream-id> --validation-report <report>"
        )
    root = repo_root()
    branch = branch_name(root)
    if branch == target:
        raise LandingError("run from a task branch, not the target branch")
    ensure_clean(root)
    shared = common_dir(root)
    lock_path = shared / "agent-land-main.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)

    with lock_path.open("a+") as lock_file:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
        if dry_run:
            print(f"inspection: clean branch {branch} in {root}")
            print(f"shared git directory: {shared}")
            print(f"would fetch {remote}/{target}, rebase, and push HEAD:refs/heads/{target}")
            print(f"local landing lock: {lock_path}")
            return 0

        target_ref = fetch_main(root, remote, target)
        original_commits = commits_to_replay(root, target_ref)
        if not original_commits:
            print(f"already up to date with {remote}/{target}; nothing to land")
            return 0

        published = already_published_elsewhere(root, original_commits, target_ref)
        if published:
            raise LandingError(published)

        head = git("rev-parse", "HEAD", cwd=root).stdout.strip()
        if git("merge-base", "--is-ancestor", target_ref, head, check=False, cwd=root).returncode == 0:
            # A synchronized workstream may already contain main as a merge
            # parent. Preserve that history and fast-forward main directly;
            # rebasing such a branch can replay stale packet-index edits and
            # conflict even though the complete tree is already resolved.
            for attempt in range(1, attempts + 1):
                push = git("push", remote, f"HEAD:refs/heads/{target}", check=False, cwd=root)
                if push.returncode == 0:
                    print(f"landed {branch} on {remote}/{target}: {head}")
                    return 0

                try:
                    target_ref = fetch_main(root, remote, target)
                except LandingError:
                    raise LandingError(f"push failed and refresh failed: {(push.stderr or push.stdout).strip()}")
                if git("merge-base", "--is-ancestor", head, target_ref, check=False, cwd=root).returncode == 0:
                    print(f"already landed on {remote}/{target} after concurrent push")
                    return 0
                if git("merge-base", "--is-ancestor", target_ref, head, check=False, cwd=root).returncode != 0:
                    print(f"{remote}/{target} advanced beyond the synchronized head; retrying with a rebase")
                    break
                if attempt == attempts:
                    raise LandingError(f"remote main kept advancing after {attempts} fast-forward attempts")
                print(f"{remote}/{target} advanced during push; retrying ({attempt + 1}/{attempts})")
        original_commits = commits_to_replay(root, target_ref)
        published = already_published_elsewhere(root, original_commits, target_ref)
        if published:
            raise LandingError(published)

        for attempt in range(1, attempts + 1):
            rebase = git("rebase", target_ref, check=False, cwd=root)
            if rebase.returncode:
                git("rebase", "--abort", check=False, cwd=root)
                raise LandingError("rebase conflict; automated rebase was aborted; resolve manually")

            push = git("push", remote, f"HEAD:refs/heads/{target}", check=False, cwd=root)
            if push.returncode == 0:
                print(f"landed {branch} on {remote}/{target}: {git('rev-parse', 'HEAD', cwd=root).stdout.strip()}")
                return 0

            prior_ref_oid = git("rev-parse", target_ref, cwd=root).stdout.strip()
            try:
                fetch_main(root, remote, target)
            except LandingError:
                raise LandingError(f"push failed and refresh failed: {(push.stderr or push.stdout).strip()}")
            new_ref_oid = git("rev-parse", target_ref, cwd=root).stdout.strip()
            if new_ref_oid == prior_ref_oid:
                raise LandingError(f"push failed without a remote main race: {(push.stderr or push.stdout).strip()}")

            # A lost push response can mean the task already landed. Avoid rebasing
            # or rewriting it again when remote main now contains HEAD.
            head = git("rev-parse", "HEAD", cwd=root).stdout.strip()
            if git("merge-base", "--is-ancestor", head, target_ref, check=False, cwd=root).returncode == 0:
                print(f"already landed on {remote}/{target} after concurrent push")
                return 0
            remaining = commits_to_replay(root, target_ref)
            published = already_published_elsewhere(root, remaining, target_ref)
            if published:
                raise LandingError(published)
            if attempt == attempts:
                raise LandingError(f"remote main kept advancing after {attempts} attempts")
            print(f"{remote}/{target} advanced during push; retrying ({attempt + 1}/{attempts})")

    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--remote", default="origin")
    parser.add_argument("--target", default="main")
    parser.add_argument("--max-attempts", type=int, default=3)
    parser.add_argument("--dry-run", action="store_true", help="inspect the plan without fetching, rebasing, or pushing")
    args = parser.parse_args()
    if args.max_attempts < 1:
        parser.error("--max-attempts must be at least 1")
    try:
        return land(args.remote, args.target, args.max_attempts, args.dry_run)
    except LandingError as error:
        print(f"land_main: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())