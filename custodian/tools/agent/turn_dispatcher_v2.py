#!/usr/bin/env python3
"""Turn-scoped dispatcher candidate. No prune, persistent leases or implicit teardown.

This is an opt-in implementation; it does not replace dispatch.py.
"""
from __future__ import annotations
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ID = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
HEADER = re.compile(r"^- ([A-Za-z][A-Za-z /-]+):\s*(.*)$", re.M)
PACKETS = Path("custodian/docs/ai_context/task_packets")


class DispatchError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True) -> str:
    p = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
    if check and p.returncode:
        raise DispatchError(f"git {' '.join(args)}: {p.stderr.strip()}")
    return p.stdout.strip() if p.returncode == 0 else ""


def validate_id(value: str) -> str:
    if not ID.fullmatch(value):
        raise DispatchError(f"invalid workstream: {value}")
    return value


def repo_root(repo: Path) -> Path:
    return Path(git(repo, "rev-parse", "--show-toplevel")).resolve()


def packet(repo: Path, workstream: str) -> tuple[Path, dict]:
    root = repo / PACKETS
    found = []
    for directory in (root, root / "archived"):
        for path in directory.glob("*.md"):
            fields = {k.lower(): v.strip().strip(chr(96))
                      for k, v in HEADER.findall(path.read_text(encoding="utf-8"))}
            if fields.get("workstream") == workstream:
                found.append((path, fields))
    active = [item for item in found if item[0].parent == root]
    if not found or len(active) > 1 or len(found) > 2:
        raise DispatchError("missing or ambiguous packet identity")
    return active[0] if active else found[0]


def inspect(repo: Path, workstream: str, mode: str) -> dict:
    repo = repo_root(repo)
    validate_id(workstream)
    path, fields = packet(repo, workstream)
    if mode == "normal" and (fields.get("status") != "ready"
                             or fields.get("dispatch") != "auto"):
        raise DispatchError("normal claim requires ready/auto packet")
    if mode == "historical" and fields.get("status") == "draft":
        raise DispatchError("draft packet needs user design refresh")
    branch = f"agent/{workstream}"
    response = git(repo, "ls-remote", "--heads", "origin", f"refs/heads/{branch}")
    lines = [x.split()[0] for x in response.splitlines() if x]
    if len(lines) > 1:
        raise DispatchError("ambiguous remote heads")
    return {"workstream": workstream, "mode": mode, "branch": branch,
            "packet": str(path.relative_to(repo)), "remote_head": lines[0] if lines else None,
            "repo": str(repo)}


def attached(repo: Path, branch: str) -> list[Path]:
    rows = []
    for block in git(repo, "worktree", "list", "--porcelain").split("\n\n"):
        lines = block.splitlines()
        if lines and f"branch refs/heads/{branch}" in lines:
            rows.append(Path(lines[0].removeprefix("worktree ")))
    return rows


def allowed_checkout(path: Path, pool: Path) -> None:
    if path.parent.resolve() != pool.resolve() or not path.name.startswith("turn-"):
        raise DispatchError("checkout is not in managed turn pool")


def begin(repo: Path, workstream: str, mode: str, pool: Path) -> dict:
    info = inspect(repo, workstream, mode)
    repo, pool = Path(info["repo"]), pool.expanduser().resolve()
    branch = info["branch"]
    if pool == repo or pool in repo.parents:
        raise DispatchError("invalid turn pool")
    old = attached(repo, branch)
    if old:
        if mode == "normal" or len(old) != 1:
            raise DispatchError("preexisting checkout: historical reconciliation required")
        candidate = old[0]
        if git(candidate, "status", "--porcelain", "--untracked-files=all"):
            raise DispatchError(f"old checkout has unique uncommitted files: {candidate}")
        if git(candidate, "ls-files", "--others", "--ignored", "--exclude-standard"):
            raise DispatchError(f"old checkout has ignored data: {candidate}")
        # The original legacy checkout is still owned by its existing lifecycle.
        # Do not delete or force-migrate that path here.
        return {**info, "existing_checkout": str(candidate),
                "blocked": "legacy checkout must be retired by verified original-owner procedure"}
    if mode == "historical" and not info["remote_head"]:
        raise DispatchError("historical branch unavailable: owner reconciliation required")
    if not info["remote_head"]:
        advertised = git(repo, "ls-remote", "--heads", "origin", "refs/heads/main")
        if not advertised:
            raise DispatchError("remote main unavailable")
        sha = advertised.split()[0]
        git(repo, "fetch", "--no-tags", "origin", "main")
        # Atomic remote ref creation; no branch overwrite or persistent lock.
        git(repo, "push", "origin", f"{sha}:refs/heads/{branch}")
        info["remote_head"] = sha
    git(repo, "fetch", "--no-tags", "origin", f"refs/heads/{branch}")
    local = git(repo, "rev-parse", "--verify", f"refs/heads/{branch}", check=False)
    if local and local != info["remote_head"]:
        raise DispatchError("local branch diverges from advertised remote")
    target = pool / f"turn-{workstream}"
    allowed_checkout(target, pool)
    if target.exists():
        raise DispatchError("turn directory already exists")
    pool.mkdir(parents=True, exist_ok=True)
    if local:
        git(repo, "worktree", "add", str(target), branch)
    else:
        git(repo, "worktree", "add", "-b", branch, str(target), info["remote_head"])
    try:
        git(target, "lfs", "pull", "origin")
    except DispatchError as error:
        raise DispatchError(f"LFS hydration failed; preserve checkout {target}: {error}")
    return {**info, "checkout": str(target), "rehydrated": True}


def checkpoint(repo: Path, workstream: str, checkout: Path, handoff: Path,
               message: str, pool: Path, retire: bool = True) -> dict:
    repo, checkout = repo_root(repo), checkout.resolve()
    pool = pool.expanduser().resolve()
    validate_id(workstream)
    allowed_checkout(checkout, pool)
    branch = f"agent/{workstream}"
    if git(checkout, "symbolic-ref", "--short", "HEAD") != branch:
        raise DispatchError("unexpected worktree branch")
    if checkout not in attached(repo, branch):
        raise DispatchError("worktree not attached to expected common directory")
    if not handoff.is_file() or handoff.is_symlink():
        raise DispatchError("handoff missing or symbolic")
    rel = Path("custodian/docs/ai_context/turn_handoffs") / f"{workstream}.md"
    target = (checkout / rel).resolve()
    if not target.is_relative_to(checkout):
        raise DispatchError("handoff escapes worktree")
    if handoff.resolve() != target:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(handoff, target)
    body = target.read_text(encoding="utf-8")
    for label in ("Original goal:", "Implemented:", "Remaining:", "Validation:", "Resume:"):
        if label not in body:
            raise DispatchError(f"missing handoff field: {label}")
    pending = subprocess.run(["git", "-C", str(checkout), "ls-files",
                              "--others", "--exclude-standard", "-z"],
                             capture_output=True, check=True).stdout
    untracked = [os.fsdecode(raw) for raw in pending.split(b"\0") if raw]
    secret = re.compile(r"(^|/)(\.env($|\.)|id_(rsa|ed25519)|.*\.(pem|key|p12|pfx)$)", re.I)
    unsafe = [path for path in untracked if secret.search(path)]
    if unsafe:
        raise DispatchError(f"potential secrets require explicit review: {unsafe[:10]}")
    ignored = git(checkout, "ls-files", "--others", "--ignored", "--exclude-standard")
    if ignored:
        raise DispatchError("ignored data must be reviewed/preserved before retirement")
    git(checkout, "add", "-u")
    for path in untracked:
        git(checkout, "add", "--", path)
    git(checkout, "add", "--", str(rel))
    if git(checkout, "diff", "--cached", "--name-only"):
        git(checkout, "commit", "-m", f"{message} [skip render]")
    sha = git(checkout, "rev-parse", "HEAD")
    # Push must be non-forced, and the advertised remote must exactly equal HEAD.
    git(checkout, "push", "origin", f"HEAD:refs/heads/{branch}")
    remote = git(repo, "ls-remote", "--heads", "origin", f"refs/heads/{branch}")
    if not remote or remote.split()[0] != sha:
        raise DispatchError("remote SHA mismatch; retain checkout")
    if git(checkout, "status", "--porcelain", "--untracked-files=all"):
        raise DispatchError("dirty after push; retain checkout")
    if retire:
        git(repo, "worktree", "remove", str(checkout))
        if checkout.exists():
            raise DispatchError("retired worktree path still exists")
    return {"workstream": workstream, "head": sha,
            "handoff": str(rel), "retired": retire}


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repo", type=Path, default=Path.cwd())
    p.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    subs = p.add_subparsers(dest="action", required=True)
    for name in ("inspect", "begin"):
        s = subs.add_parser(name)
        s.add_argument("workstream")
        s.add_argument("--mode", choices=("normal", "historical"), default="normal")
    s = subs.add_parser("checkpoint")
    s.add_argument("workstream")
    s.add_argument("--checkout", type=Path, required=True)
    s.add_argument("--handoff", type=Path, required=True)
    s.add_argument("--message", required=True)
    s.add_argument("--keep", action="store_true")
    args = p.parse_args(argv)
    try:
        if args.action == "inspect":
            result = inspect(args.repo, args.workstream, args.mode)
        elif args.action == "begin":
            result = begin(args.repo, args.workstream, args.mode, args.pool)
        else:
            result = checkpoint(args.repo, args.workstream, args.checkout,
                                args.handoff, args.message, args.pool, not args.keep)
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (DispatchError, subprocess.CalledProcessError) as exc:
        print(f"turn_dispatcher_v2: BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
