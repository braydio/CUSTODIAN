#!/usr/bin/env python3
"""Opt-in, push-triggered V2 packet-pair authoring handoff.

An author explicitly opts a *newly authorized* implementation+review pair into
mechanical promotion with `- Authoring handoff: `auto`` on BOTH packets.

The preflight and index tools remain the source of truth. This script does NOT
claim workstreams, bypass dependency/lock gates, or touch unrelated drafts.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

from task_packet_contract import (
    PACKET_ROOT, parse_packet, validate_packet_validation_references,
    validate_queue_contract,
)
from validate_task_packet_authoring import validate_authoring_paths
import task_packet_index

PACKET_DIR = Path(PACKET_ROOT)
MARKER = "Authoring handoff"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


class HandoffError(RuntimeError):
    pass


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if result.returncode:
        raise HandoffError(f"git {' '.join(args)}: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def exact_header(text: str, key: str) -> str | None:
    matches = re.findall(rf"(?m)^- {re.escape(key)}:\s*(.*?)\s*$", text)
    if len(matches) > 1:
        raise HandoffError(f"ambiguous duplicate '{key}' metadata")
    return matches[0].strip().strip("`") if matches else None


def discover_pairs(repo: Path, changed_paths: list[str]) -> list[tuple[Path, Path]]:
    """Only select complete, explicitly opted-in implementation/review pairs."""
    root = repo / PACKET_DIR
    texts = {p.relative_to(repo).as_posix(): p.read_text() for p in root.glob("*.md") if p.name != "README.md"}
    packets = {path: parse_packet(path, content) for path, content in texts.items()}
    by_id = {}
    for path, packet in packets.items():
        if packet.workstream:
            if packet.workstream in by_id:
                raise HandoffError(f"duplicate active workstream: {packet.workstream}")
            by_id[packet.workstream] = (path, packet)
    pairs: dict[str, tuple[Path, Path]] = {}
    for path in changed_paths:
        rel = Path(path)
        if rel.parent != PACKET_DIR or rel.suffix != ".md" or rel.name == "README.md":
            continue
        content = texts.get(path)
        if content is None or exact_header(content, MARKER) != "auto":
            continue
        packet = packets[path]
        if packet.error:
            raise HandoffError(f"{path}: {packet.error}")
        if packet.kind == "review":
            impl_id = packet.review_target_workstream
        elif packet.review == "auto":
            impl_id = packet.workstream
        else:
            raise HandoffError(f"{path}: opted-in packet must be an auto-reviewed implementation/correction or its review")
        if not impl_id or impl_id not in by_id:
            raise HandoffError(f"{path}: implementation packet missing for {impl_id}")
        impl_path, impl = by_id[impl_id]
        rev_id = impl.paired_review_workstream
        if not rev_id or rev_id not in by_id:
            raise HandoffError(f"{path}: paired review missing for {impl_id}")
        rev_path, review = by_id[rev_id]
        if review.kind != "review" or review.review_target_workstream != impl_id:
            raise HandoffError(f"{path}: invalid review binding")
        if exact_header(texts[impl_path], MARKER) != "auto" or exact_header(texts[rev_path], MARKER) != "auto":
            raise HandoffError(f"{path}: both implementation and review must explicitly authorize automatic handoff")
        states = {(impl.status, impl.dispatch), (review.status, review.dispatch)}
        if states == {("ready", "auto")}:
            continue  # idempotent on the bot-generated promotion commit
        if states != {("draft", "manual")}:
            raise HandoffError(f"{path}: expected both draft/manual or both ready/auto; got {sorted(states)}")
        pairs[impl_id] = (repo / impl_path, repo / rev_path)
    return [pairs[key] for key in sorted(pairs)]


def promote_field(text: str, field: str, old: str, new: str) -> str:
    pattern = re.compile(rf"(?m)^(- {re.escape(field)}:\s*)`?{re.escape(old)}`?(\s*)$")
    revised, count = pattern.subn(lambda m: f"{m.group(1)}`{new}`{m.group(2)}", text)
    if count != 1:
        raise HandoffError(f"expected one {field}: {old} field; got {count}")
    return revised


def promote(repo: Path, pairs: list[tuple[Path, Path]]) -> list[str]:
    """Validate before and after, and update only the nominated packets/index."""
    paths = [p for pair in pairs for p in pair]
    if not paths:
        return []
    findings = validate_authoring_paths(repo, paths)
    if findings:
        raise HandoffError("draft preflight failed:\n" + "\n".join(findings))
    original = {p: p.read_text() for p in paths}
    readme = repo / PACKET_DIR / "README.md"
    old_readme = readme.read_text()
    try:
        for path in paths:
            current = promote_field(original[path], "Status", "draft", "ready")
            current = promote_field(current, "Dispatch", "manual", "auto")
            path.write_text(current)
        findings = validate_authoring_paths(repo, paths)
        if findings:
            raise HandoffError("ready preflight failed:\n" + "\n".join(findings))
        active_texts = {p.relative_to(repo).as_posix(): p.read_text() for p in (repo / PACKET_DIR).glob("*.md") if p.name != "README.md"}
        active = [parse_packet(path, text) for path, text in active_texts.items()]
        archived = [parse_packet(p.relative_to(repo).as_posix(), p.read_text()) for p in (repo / PACKET_DIR / "archived").glob("*.md")]
        queue_errors = validate_queue_contract(active, archived, active_texts)
        ids = {parse_packet(p.relative_to(repo).as_posix(), p.read_text()).workstream for p in paths}
        relevant = {w: e for w, e in queue_errors.items() if w in ids}
        if relevant:
            raise HandoffError("queue contract failed: " + str(relevant))
        validation_errors = validate_packet_validation_references(repo, [p for p in active if p.workstream in ids], tree="HEAD")
        if validation_errors:
            raise HandoffError("validation reference failure: " + str(validation_errors))
        task_packet_index.write(repo)
        good, message = task_packet_index.check(repo)
        if not good:
            raise HandoffError("managed index failed: " + message)
    except Exception:
        for path, contents in original.items():
            path.write_text(contents)
        readme.write_text(old_readme)
        raise
    return [p.relative_to(repo).as_posix() for p in paths] + [readme.relative_to(repo).as_posix()]


def all_active_packets(repo: Path) -> list[str]:
    """Recheck explicit opt-ins after a main-branch race or interrupted CI run."""
    return [p.relative_to(repo).as_posix() for p in sorted((repo / PACKET_DIR).glob("*.md")) if p.name != "README.md"]


def changed_packets(repo: Path, base: str) -> list[str]:
    if not SHA_RE.fullmatch(base):
        raise HandoffError("--base must be an exact 40-character commit SHA")
    git(repo, "cat-file", "-e", f"{base}^{{commit}}")
    return git(repo, "diff", "--name-only", "--diff-filter=ACMRT", f"{base}..HEAD", "--", str(PACKET_DIR)).splitlines()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--base", help="exact before-push main commit")
    source.add_argument("--scan-opted", action="store_true", help="retry all remaining explicitly opted-in draft pairs")
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--check-only", action="store_true", help="inspect authorization without modifying files")
    args = parser.parse_args(argv)
    repo = args.repo.resolve()
    try:
        if git(repo, "status", "--porcelain"):
            raise HandoffError("checkout is dirty: refusing to overwrite other work")
        if git(repo, "rev-parse", "--abbrev-ref", "HEAD") != "main":
            raise HandoffError("only an isolated main checkout may perform automatic promotion")
        if git(repo, "rev-parse", "HEAD") != git(repo, "rev-parse", "refs/remotes/origin/main"):
            raise HandoffError("main moved since checkout; retry on a fresh main")
        pairs = discover_pairs(repo, all_active_packets(repo) if args.scan_opted else changed_packets(repo, args.base))
        if not pairs:
            print("packet_authoring_handoff: no authorized draft/manual pairs in this push")
            return 0
        print("packet_authoring_handoff: selected " + ", ".join(pair[0].stem for pair in pairs))
        if args.check_only:
            return 0
        touched = promote(repo, pairs)
        git(repo, "add", "--", *touched)
        staged = set(git(repo, "diff", "--cached", "--name-only").splitlines())
        if staged != set(touched) and staged != set(touched[:-1]):
            raise HandoffError(f"unexpected staged paths: {staged ^ set(touched)}")
        git(repo, "commit", "-m", "agent workflow, automatic task packet handoff")
        # Never rewrite remote history or race-push over someone else's main.
        git(repo, "fetch", "origin", "main")
        if git(repo, "rev-parse", "HEAD^") != git(repo, "rev-parse", "refs/remotes/origin/main"):
            raise HandoffError("remote main advanced during promotion; stop without pushing")
        git(repo, "push", "origin", "HEAD:refs/heads/main")
        print("packet_authoring_handoff: PROMOTED: " + ", ".join(p[0].stem for p in pairs))
        return 0
    except HandoffError as exc:
        print(f"packet_authoring_handoff: BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())