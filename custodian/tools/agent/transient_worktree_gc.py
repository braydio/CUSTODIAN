#!/usr/bin/env python3
"""Conservatively retire only already-landed, clean, transient agent checkouts.

This is checkout reclamation, not claim release or review acceptance.  Never
remove an active, detached, dirty, ignored-content, or unlanded worktree.
The normal workstream lifecycle remains the only owner of branch/ref deletion.
"""
from __future__ import annotations

import argparse
import fcntl
import os
import re
import subprocess
import sys
from pathlib import Path

ARCHIVE = Path('custodian/docs/ai_context/task_packets/archived')
ACTIVE = Path('custodian/docs/ai_context/task_packets')
RUN_SUFFIX = re.compile(r'\d{8}T\d{6}Z-[0-9a-f]{12}\Z')
IDENTITY = re.compile(r'[a-z0-9]+(?:-[a-z0-9]+)*\Z')


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(['git', '-C', str(repo), *args], capture_output=True, check=False)


def output(repo: Path, *args: str) -> str | None:
    result = git(repo, *args)
    return result.stdout.decode('utf-8', errors='replace').strip() if result.returncode == 0 else None


def worktrees(repo: Path) -> list[dict[str, str]]:
    raw = output(repo, 'worktree', 'list', '--porcelain')
    if raw is None:
        return []
    rows: list[dict[str, str]] = []
    for block in raw.split('\n\n'):
        fields = {}
        for line in block.splitlines():
            key, _, value = line.partition(' ')
            if key in {'worktree', 'HEAD', 'branch', 'locked', 'prunable', 'detached'}:
                fields[key] = value
        if fields.get('worktree'):
            rows.append(fields)
    return rows


def in_use(path: Path) -> bool:
    """Fail closed if same-UID process ownership cannot be ruled out on Linux."""
    proc = Path('/proc')
    if not proc.is_dir():
        return True
    try:
        for entry in proc.iterdir():
            if not entry.name.isdigit():
                continue
            try:
                if entry.stat().st_uid != os.geteuid():
                    continue
                cwd = (entry / 'cwd').resolve(strict=True)
            except (FileNotFoundError, ProcessLookupError):
                continue
            except (PermissionError, OSError):
                return True
            if cwd == path or path in cwd.parents:
                return True
            # A worker can have another cwd while holding a file in this tree.
            try:
                for fd in (entry / 'fd').iterdir():
                    try:
                        target = fd.resolve(strict=True)
                    except (FileNotFoundError, ProcessLookupError):
                        continue
                    except (PermissionError, OSError):
                        return True
                    if target == path or path in target.parents:
                        return True
            except (FileNotFoundError, ProcessLookupError):
                continue
            except (PermissionError, OSError):
                return True
    except (PermissionError, OSError):
        return True
    return False


def eligible(repo: Path, path: Path, identity: str, pool: Path, head: str) -> bool:
    """All predicates are rechecked while holding the canonical workstream lock."""
    if not IDENTITY.fullmatch(identity) or path.is_symlink() or not path.is_dir():
        return False
    if path.parent != pool or not path.name.startswith(identity + '-'):
        return False
    if not RUN_SUFFIX.fullmatch(path.name[len(identity) + 1:]):
        return False
    if (path / '.git').is_symlink() or not (path / '.git').is_file():
        return False
    # Read from fetched origin/main, not a potentially lagging coordination checkout.
    filename = identity.upper().replace('-', '_') + '.md'
    active_spec = 'refs/remotes/origin/main:' + (ACTIVE / filename).as_posix()
    archive_spec = 'refs/remotes/origin/main:' + (ARCHIVE / filename).as_posix()
    active_lookup = git(repo, 'cat-file', '-e', active_spec)
    if active_lookup.returncode == 0:
        return False
    body = output(repo, 'show', archive_spec)
    if body is None:
        return False
    if not re.search(r'^- Workstream: `?' + re.escape(identity) + r'`?\s*$', body, re.M):
        return False
    if not re.search(r'^- Status: `?complete`?\s*$', body, re.M):
        return False
    if output(path, 'rev-parse', '--abbrev-ref', 'HEAD') != 'agent/' + identity:
        return False
    if output(path, 'rev-parse', 'HEAD') != head:
        return False
    if git(path, 'merge-base', '--is-ancestor', 'HEAD', 'refs/remotes/origin/main').returncode != 0:
        return False
    status = git(path, 'status', '--porcelain=v1', '-z', '--untracked-files=all')
    if status.returncode or status.stdout:
        return False
    ignored = git(path, 'ls-files', '--others', '--ignored', '--exclude-standard', '-z')
    if ignored.returncode or ignored.stdout:
        return False
    claim = 'refs/remotes/origin/dispatch-claims/' + identity
    if git(repo, 'show-ref', '--verify', '--quiet', claim).returncode == 0:
        return False
    remote = 'refs/remotes/origin/agent/' + identity
    remote_head = output(repo, 'rev-parse', '--verify', remote)
    if remote_head is not None and remote_head != head:
        return False
    # Don't trust locally cached worktrees that have changed during this sweep.
    matching = [row for row in worktrees(repo) if row.get('worktree') == str(path)]
    if len(matching) != 1 or matching[0].get('branch') != 'refs/heads/agent/' + identity:
        return False
    if any(key in matching[0] for key in ('locked', 'prunable', 'detached')):
        return False
    return not in_use(path)


def sweep(repo: Path, *, apply: bool = False, limit: int = 4, exclude: set[str] | None = None) -> dict[str, list[str]]:
    """No network or ref deletion. Caller refreshes origin/main before sweeping."""
    repo = repo.resolve()
    result: dict[str, list[str]] = {'eligible': [], 'removed': [], 'blocked': []}
    rows = worktrees(repo)
    if not rows or limit < 1:
        return result
    main_root = Path(rows[0]['worktree']).resolve()
    pool = (main_root.parent / '.custodian-worktrees').resolve()
    common = output(repo, 'rev-parse', '--path-format=absolute', '--git-common-dir')
    if common is None:
        return result
    lock_root = Path(common) / 'custodian-workflow' / 'locks'
    for row in rows[1:]:
        branch = row.get('branch', '')
        if not branch.startswith('refs/heads/agent/') or any(k in row for k in ('locked', 'prunable', 'detached')):
            continue
        identity = branch.removeprefix('refs/heads/agent/')
        if identity in (exclude or set()) or not IDENTITY.fullmatch(identity):
            continue
        candidate = Path(row['worktree'])
        if candidate.is_symlink() or candidate.parent.resolve() != pool:
            continue
        path = candidate.resolve()
        lock_root.mkdir(parents=True, exist_ok=True)
        with (lock_root / (identity + '.lock')).open('a') as lock:
            try:
                fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                continue
            try:
                if not eligible(repo, path, identity, pool, row.get('HEAD', '')):
                    continue
                result['eligible'].append(str(path))
                if apply:
                    removed = git(repo, 'worktree', 'remove', '--', str(path))
                    if removed.returncode == 0:
                        result['removed'].append(str(path))
                    else:
                        result['blocked'].append(str(path))
            except (OSError, UnicodeError, ValueError):
                result['blocked'].append(str(path))
            finally:
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)
        if len(result['removed'] if apply else result['eligible']) >= limit:
            break
    return result


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, default=Path.cwd())
    p.add_argument('--apply', action='store_true', help='remove only proven-safe checkouts, never branch/claim refs')
    p.add_argument('--limit', type=int, default=4)
    a = p.parse_args()
    import json
    print(json.dumps(sweep(a.repo, apply=a.apply, limit=a.limit), indent=2, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
