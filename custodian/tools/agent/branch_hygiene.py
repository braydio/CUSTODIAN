#!/usr/bin/env python3
"""Report or safely retire obsolete origin branches; report-only by default."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


class HygieneError(RuntimeError):
    pass


FULL_SHA_RE = re.compile(r"[0-9a-f]{40}\Z")


def git(*args: str, cwd: Path, check: bool = True) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check and p.returncode:
        raise HygieneError(f"git {' '.join(args)} failed: {(p.stderr or p.stdout).strip()}")
    return p.stdout.strip()


def classify(repo: Path, branch: str, protected: set[str]) -> tuple[str, str, int, int]:
    if branch.startswith("agent-diagnostics/"):
        return "DIAGNOSTIC_PRESERVE", git("rev-parse", f"refs/remotes/origin/{branch}", cwd=repo), 0, 0
    ref = f"refs/remotes/origin/{branch}"
    if branch in protected or branch.startswith(("release/", "hotfix/")):
        return "PROTECTED", git("rev-parse", ref, cwd=repo), 0, 0
    head = git("rev-parse", ref, cwd=repo)
    counts = git("rev-list", "--left-right", "--count", f"origin/main...{ref}", cwd=repo).split()
    behind, ahead = map(int, counts)
    if ahead == 0:
        if behind == 0:
            return "IDENTICAL_SAFE_DELETE", head, behind, ahead
        return "LANDED_SAFE_DELETE", head, behind, ahead
    if branch.startswith("agent/"):
        return "ACTIVE", head, behind, ahead
    exact = subprocess.run(["git", "merge-base", "--is-ancestor", ref, "origin/main"], cwd=repo).returncode == 0
    if exact:
        return "IDENTICAL_SAFE_DELETE", head, behind, ahead
    if behind > 0:
        return "ARCHIVE_CANDIDATE", head, behind, ahead
    return "RECONCILE_REQUIRED", head, behind, ahead


def archive_tag(repo: Path, branch: str, head: str, date: str) -> str:
    name = "archive/" + branch.replace("/", "-").replace("_", "-") + "-" + date
    existing = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/tags/{name}"], cwd=repo).returncode == 0
    if existing and git("rev-parse", name, cwd=repo) != head:
        raise HygieneError(f"archive tag {name} already exists at another commit")
    if not existing:
        git("tag", "-a", name, head, "-m", f"Archive retired branch {branch}", cwd=repo)
    git("push", "origin", f"refs/tags/{name}:refs/tags/{name}", cwd=repo)
    remote = git("ls-remote", "origin", f"refs/tags/{name}^{{}}", f"refs/tags/{name}", cwd=repo).splitlines()
    if not any(line.split()[0] == head for line in remote):
        raise HygieneError(f"remote archive tag {name} did not verify at {head}")
    return name


def record(ledger: Path, branch: str, head: str, disposition: str, tag: str, note: str) -> None:
    ledger.parent.mkdir(parents=True, exist_ok=True)
    if not ledger.exists():
        ledger.write_text("# Branch Archive\n\n| Retired branch | Head SHA | Retirement date | Disposition | Archive tag | Notes / successor workstream |\n|---|---|---|---|---|---|\n")
    row = f"| `{branch}` | `{head}` | {datetime.now().astimezone().strftime('%Y-%m-%d')} | {disposition} | {f'`{tag}`' if tag else '—'} | {note or '—'} |\n"
    with ledger.open("a") as stream:
        stream.write(row)


def retire(
    repo: Path,
    branch: str,
    ledger: Path,
    note: str = "",
    *,
    expected_head: str | None = None,
    protected: set[str] | None = None,
) -> None:
    # Re-fetch and reclassify immediately before deletion.
    git("fetch", "--prune", "origin", cwd=repo)
    state, head, _, ahead = classify(repo, branch, {"main", *(protected or set())})
    if expected_head is not None and head != expected_head:
        raise HygieneError(
            f"approved retirement head mismatch for {branch}: expected {expected_head}, found {head}"
        )
    if state == "PROTECTED":
        raise HygieneError(f"refusing to retire protected branch {branch}")
    if state == "DIAGNOSTIC_PRESERVE":
        raise HygieneError(f"refusing to retire unresolved diagnostic ref {branch}; cleanup is explicit")
    raw_worktrees = git("worktree", "list", "--porcelain", cwd=repo)
    attached: list[Path] = []
    current: dict[str, str] = {}
    for line in raw_worktrees.splitlines() + [""]:
        if not line:
            if current.get("branch") == f"refs/heads/{branch}":
                attached.append(Path(current["worktree"]).resolve())
            current = {}
        else:
            key, _, value = line.partition(" ")
            current[key] = value
    for path in attached:
        dirty = git("status", "--porcelain", "--untracked-files=all", cwd=path)
        local_head = git("rev-parse", "HEAD", cwd=path)
        if dirty:
            raise HygieneError(f"{branch} is attached to a dirty worktree; preserved at {path}")
        if local_head != head:
            raise HygieneError(f"{branch} has attached local commits/state beyond its remote head; preserved at {path}")
    tag = ""
    if ahead or expected_head is not None:
        tag = archive_tag(repo, branch, head, datetime.now().astimezone().strftime("%Y%m%d"))
        disposition = "archived unique history" if ahead else "approved head preserved; already contained by main"
    else:
        disposition = "fully contained by main"
    try:
        record(ledger, branch, head, disposition, tag, note)
    except OSError as error:
        raise HygieneError(f"could not write branch archive ledger for {branch}: {error}") from error
    if expected_head is None:
        git("push", "origin", "--delete", branch, cwd=repo)
    else:
        # Conditional deletion prevents a branch that advances after fetch from
        # being removed under an approval for its former head.
        git(
            "push",
            f"--force-with-lease=refs/heads/{branch}:{expected_head}",
            "origin",
            f":refs/heads/{branch}",
            cwd=repo,
        )
    git("fetch", "--prune", "origin", cwd=repo)


def parse_approved_retirement(value: str) -> tuple[str, str]:
    branch, separator, head = value.partition("=")
    if not separator or not branch.startswith("agent/") or branch.startswith("agent-diagnostics/"):
        raise HygieneError("approved retirement must name one non-diagnostic agent/<branch>=<40-char-sha>")
    if not FULL_SHA_RE.fullmatch(head):
        raise HygieneError("approved retirement SHA must be exactly 40 lowercase hexadecimal characters")
    check = subprocess.run(
        ["git", "check-ref-format", f"refs/heads/{branch}"], capture_output=True, text=True
    )
    if check.returncode:
        raise HygieneError(f"invalid approved branch ref: {branch}")
    return branch, head


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--apply", action="store_true", help="retire landed/identical branches and archive unique candidates")
    modes.add_argument(
        "--retire-approved",
        action="append",
        default=[],
        metavar="BRANCH=SHA",
        help="retire one operator-approved divergent agent branch at its exact audited SHA (repeatable)",
    )
    parser.add_argument("--ledger", type=Path, default=Path("custodian/docs/ai_context/BRANCH_ARCHIVE.md"))
    parser.add_argument("--protected", action="append", default=[], help="additional protected remote branch name")
    parser.add_argument("--note", default="", help="ledger note applied to branches retired in this invocation")
    parser.add_argument("branches", nargs="*", help="remote branches to inspect (default: all origin branches)")
    args = parser.parse_args()
    try:
        repo = Path(git("rev-parse", "--show-toplevel", cwd=Path.cwd())).resolve()
        if args.retire_approved:
            if args.branches:
                raise HygieneError("positional branches cannot be combined with --retire-approved")
            approved = [parse_approved_retirement(value) for value in args.retire_approved]
            if len({branch for branch, _ in approved}) != len(approved):
                raise HygieneError("each branch may appear only once in --retire-approved")
            ledger = (repo / args.ledger).resolve() if not args.ledger.is_absolute() else args.ledger
            for branch, expected_head in approved:
                retire(
                    repo,
                    branch,
                    ledger,
                    args.note,
                    expected_head=expected_head,
                    protected=set(args.protected),
                )
                print(f"RETIRED_APPROVED\t{branch}\t{expected_head}")
            return 0
        if args.apply:
            git("fetch", "--prune", "origin", cwd=repo)
        names = args.branches or [line.removeprefix("origin/") for line in git("branch", "-r", "--format=%(refname:short)", cwd=repo).splitlines() if line.startswith("origin/") and line != "origin/HEAD -> origin/main"]
        protected = {"main", *args.protected}
        print("CLASSIFICATION\tBRANCH\tHEAD\tBEHIND\tAHEAD")
        for branch in names:
            state, head, behind, ahead = classify(repo, branch, protected)
            print(f"{state}\t{branch}\t{head}\t{behind}\t{ahead}")
            if args.apply and state in {"LANDED_SAFE_DELETE", "IDENTICAL_SAFE_DELETE", "ARCHIVE_CANDIDATE"}:
                retire(repo, branch, (repo / args.ledger).resolve() if not args.ledger.is_absolute() else args.ledger, args.note)
        return 0
    except HygieneError as error:
        print(f"branch_hygiene: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
