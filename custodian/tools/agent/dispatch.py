#!/usr/bin/env python3
"""Discover and claim CUSTODIAN task packets from fetched origin/main."""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import importlib.util
import io
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PACKET_ROOT = "custodian/docs/ai_context/task_packets"
FIELDS = ("Workstream", "Status", "Dispatch", "Priority", "Depends on", "Locks")
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
PRIORITY = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}


class DispatchError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise DispatchError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


@dataclass(frozen=True)
class Packet:
    path: str
    workstream: str | None
    status: str | None
    dispatch: str
    dispatch_declared: bool
    priority: str
    dependencies: tuple[str, ...]
    locks: tuple[str, ...]
    error: str | None = None


def parse_packet(path: str, text: str) -> Packet:
    found: dict[str, list[str]] = {field: [] for field in FIELDS}
    header_started = False
    title_seen = False
    for line in text.splitlines():
        if not title_seen:
            if not line.strip():
                continue
            title_seen = True
            if line.lstrip().startswith("#"):
                continue
        if not line.strip():
            if header_started:
                break
            continue
        if not line.lstrip().startswith("-"):
            if header_started:
                break
            continue
        header_started = True
        match = re.match(r"^\s*-\s*([^:]+):\s*(.*?)\s*$", line)
        if not match:
            continue
        key, value = match.groups()
        key = key.strip()
        if key in found:
            found[key].append(value.strip().strip("`").strip())

    errors: list[str] = []
    values: dict[str, str] = {}
    for key, vals in found.items():
        if len(vals) > 1:
            errors.append(f"duplicate {key} metadata")
        elif vals:
            values[key] = vals[0]
    workstream = values.get("Workstream")
    status = values.get("Status", "").lower() or None
    dispatch_declared = bool(found["Dispatch"])
    dispatch = values.get("Dispatch", "manual").lower()
    priority = values.get("Priority", "P2").upper()

    if not workstream or not ID_RE.fullmatch(workstream):
        errors.append("invalid Workstream metadata")
    if status is None:
        errors.append("missing Status metadata")
    if dispatch not in {"auto", "manual"}:
        errors.append("invalid Dispatch metadata")
    if priority not in PRIORITY:
        errors.append("invalid Priority metadata")

    def csv_ids(key: str) -> tuple[str, ...]:
        raw = values.get(key, "none")
        if raw.lower() == "none":
            return ()
        entries = tuple(part.strip() for part in raw.split(","))
        if not entries or any(not ID_RE.fullmatch(part) for part in entries):
            errors.append(f"invalid {key} metadata")
            return ()
        return entries

    dependencies = csv_ids("Depends on")
    locks = csv_ids("Locks")
    return Packet(path, workstream, status, dispatch, dispatch_declared, priority, dependencies, locks, "; ".join(errors) or None)


def _tree_paths(repo: Path, tree: str, prefix: str) -> list[str]:
    raw = git(repo, "ls-tree", "-r", "--name-only", tree, "--", prefix)
    return [
        p for p in raw.splitlines()
        if p.startswith(prefix + "/")
        and p.endswith(".md")
        and "/" not in p[len(prefix) + 1:]
        and p != f"{prefix}/README.md"
    ]


def _packets(repo: Path, tree: str = "origin/main") -> list[Packet]:
    paths = _tree_paths(repo, tree, PACKET_ROOT)
    return [parse_packet(path, git(repo, "show", f"{tree}:{path}")) for path in paths]


def _archived_packets(repo: Path) -> list[Packet]:
    prefix = f"{PACKET_ROOT}/archived"
    paths = [p for p in git(repo, "ls-tree", "-r", "--name-only", "origin/main", "--", prefix).splitlines() if p.endswith(".md")]
    return [parse_packet(p, git(repo, "show", f"origin/main:{p}")) for p in paths]


def _claimed(repo: Path) -> set[str]:
    # Remote refs are claim authority. A successful dispatcher claim always has
    # either a temporary dispatch-claim ref during acquisition or a published
    # origin/agent/<id> branch after workstream.start(). Local-only worktrees are
    # recovery/residue surfaces and must not poison the global queue.
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/agent").splitlines()
    claimed = {ref.removeprefix("refs/remotes/origin/agent/") for ref in refs}
    claims, branches = _remote_claim_state(repo)
    claimed.update(claims & branches)
    return claimed


def _remote_claim_state(repo: Path) -> tuple[set[str], set[str]]:
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/dispatch-claims").splitlines()
    claims = {ref.removeprefix("refs/remotes/origin/dispatch-claims/") for ref in refs}
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/agent").splitlines()
    branches = {ref.removeprefix("refs/remotes/origin/agent/") for ref in refs}
    return claims, branches


def _decision(packet: Packet, packets: list[Packet], archived: list[Packet], claimed: set[str], *, auto_only: bool) -> tuple[bool, str | None]:
    if packet.error:
        return False, f"invalid packet metadata: {packet.error}"
    if packet.status != "ready":
        return False, f"status: {packet.status or 'missing'}"
    if auto_only and packet.dispatch != "auto":
        return False, "manual dispatch"
    if packet.workstream in claimed:
        return False, "already claimed"
    same_id = [p for p in packets if p.workstream == packet.workstream]
    if len(same_id) > 1:
        return False, f"duplicate Workstream identity: {packet.workstream}"
    complete = {p.workstream for p in archived if not p.error and p.status == "complete"}
    for dependency in packet.dependencies:
        if dependency not in complete:
            return False, f"dependency: {dependency}"
    by_id = {p.workstream: p for p in packets if p.workstream and not p.error}
    for holder in sorted(claimed):
        claimed_packet = next((p for p in packets if p.workstream == holder), None)
        if claimed_packet and claimed_packet.dispatch == "auto" and claimed_packet.error and "Locks" in claimed_packet.error:
            return False, f"lock: unknown held by {holder} (malformed lock declaration)"
    claimed_packet_locks = [(work_id, by_id[work_id].locks) for work_id in sorted(claimed) if work_id in by_id]
    for holder, locks in claimed_packet_locks:
        overlap = sorted(set(packet.locks) & set(locks))
        if overlap:
            return False, f"lock: {overlap[0]} held by {holder}"
    return True, None


def _fetch(repo: Path) -> None:
    git(repo, "fetch", "--prune", "origin")


def _mutex(repo: Path):
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    common.mkdir(parents=True, exist_ok=True)
    handle = (common / "custodian-dispatch.lock").open("a")
    fcntl.flock(handle, fcntl.LOCK_EX)
    return handle


def _load_workstream(repo: Path):
    script = repo / "custodian/tools/agent/workstream.py"
    spec = importlib.util.spec_from_file_location("custodian_workstream", script)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _coordination_repo(repo: Path) -> Path:
    """Resolve the attached main checkout used to create sibling task worktrees."""
    for record in git(repo, "worktree", "list", "--porcelain").split("\n\n"):
        lines = record.splitlines()
        if "branch refs/heads/main" in lines:
            return Path(lines[0].removeprefix("worktree ")).resolve()
    return repo


def _render_status(repo: Path, packets: list[Packet], archived: list[Packet], claimed: set[str]) -> str:
    groups: dict[str, list[str]] = {key: [] for key in ("READY", "CLAIMED", "BLOCKED", "MANUAL")}
    claims, branches = _remote_claim_state(repo)
    for work_id in sorted(claims - branches):
        groups["BLOCKED"].append(
            f"{work_id} — remote dispatch claim interrupted; recovery required. "
            f"Inspect refs/heads/dispatch-claims/{work_id}; after verifying no live claimant, "
            f"an operator may explicitly delete it with git push origin :refs/heads/dispatch-claims/{work_id}."
        )
    for packet in sorted(packets, key=lambda item: (PRIORITY.get(item.priority, 9), item.path)):
        name = packet.workstream or packet.path
        if packet.workstream in claims - branches:
            continue
        if packet.workstream in claimed:
            cleanup_note = " (remote claim cleanup pending)" if packet.workstream in claims else ""
            groups["CLAIMED"].append(f"{name}{cleanup_note} [{packet.path}]")
        elif not packet.dispatch_declared:
            groups["MANUAL"].append(f"{name} [{packet.path}]")
        elif packet.error:
            groups["BLOCKED"].append(f"{name} — invalid packet metadata: {packet.error} [{packet.path}]")
        elif packet.dispatch == "manual":
            groups["MANUAL"].append(f"{name} [{packet.path}]")
        else:
            ok, reason = _decision(packet, packets, archived, claimed, auto_only=True)
            if ok:
                groups["READY"].append(f"{packet.priority} {name} [{packet.path}]")
            else:
                groups["BLOCKED"].append(f"{name} — {reason} [{packet.path}]")
    for label in ("CLAIMED", "BLOCKED", "MANUAL"):
        groups[label].sort()
    sections = []
    for label, values in groups.items():
        shown = values[:20]
        if len(values) > len(shown):
            shown.append(f"... {len(values) - len(shown)} more")
        sections.append(f"{label} ({len(values)})\n" + ("\n".join(shown) if shown else "(none)"))
    return "\n".join(sections)


def status(repo: Path, *, output=True) -> str:
    repo = _coordination_repo(repo)
    _fetch(repo)
    rendered = _render_status(repo, _packets(repo), _archived_packets(repo), _claimed(repo))
    if output:
        print(rendered)
    return rendered


def claim(repo: Path, workstream_id: str | None, agent: str, auto_only: bool) -> int:
    # Keep selection, branch publication, and worktree creation/resume serialized
    # for terminals sharing the local Git common directory.
    repo = _coordination_repo(repo)
    with _mutex(repo):
        _fetch(repo)
        packets = _packets(repo)
        archived = _archived_packets(repo)
        claimed = _claimed(repo)
        remote_claims, remote_branches = _remote_claim_state(repo)
        ordered = sorted(packets, key=lambda p: (PRIORITY.get(p.priority, 9), p.path))
        if workstream_id:
            candidates = [p for p in ordered if p.workstream == workstream_id]
        else:
            candidates = ordered
        selected = None
        reasons: list[str] = []
        for packet in candidates:
            ok, reason = _decision(packet, packets, archived, claimed, auto_only=auto_only)
            if ok:
                selected = packet
                break
            if reason:
                reasons.append(f"{packet.workstream or packet.path}: {reason}")
        if selected is None:
            if workstream_id and not candidates:
                raise DispatchError(f"packet for workstream {workstream_id} does not exist on origin/main")
            if workstream_id:
                raise DispatchError("claim blocked: " + (reasons[0] if reasons else "not eligible"))
            print("NO ELIGIBLE AUTO TASK")
            print(f"considered: {len(candidates)}; blocked: {len(reasons)}")
            for reason in reasons[:20]:
                print(f"- {reason}")
            if len(reasons) > 20:
                print(f"- ... {len(reasons) - 20} more")
            return 0

        claim_ref = f"refs/heads/dispatch-claims/{selected.workstream}"
        if selected.workstream in remote_claims and selected.workstream not in remote_branches:
            raise DispatchError(
                f"remote dispatch claim for {selected.workstream} exists without its agent branch; "
                f"recovery required. Inspect origin/{claim_ref} and only after verifying no live "
                f"claimant explicitly remove it with git push origin :{claim_ref}"
            )

        # A unique claimant-specific commit makes remote creation a compare-and-set:
        # unlike pushing the common main OID, a concurrent loser proposes a different OID.
        claimant = f"{agent}:{os.getpid()}:{os.urandom(16).hex()}"
        tree = git(repo, "rev-parse", "origin/main^{tree}")
        parent = git(repo, "rev-parse", "origin/main")
        claim_oid = git(repo, "-c", f"user.name={agent}", "-c", f"user.email={agent}@dispatch.invalid",
                        "commit-tree", tree, "-p", parent, "-m", f"dispatch claim {selected.workstream} {claimant}")
        local_claim_ref = f"refs/dispatch-claims/{selected.workstream}"
        git(repo, "update-ref", local_claim_ref, claim_oid)
        result = subprocess.run(["git", "push", "origin", f"{claim_oid}:{claim_ref}"], cwd=repo, text=True, capture_output=True)
        if result.returncode:
            git(repo, "update-ref", "-d", local_claim_ref, check=False)
            _fetch(repo)
            raise DispatchError(f"remote claim acquisition lost or failed for {selected.workstream}: {(result.stderr or result.stdout).strip()}")

        module = _load_workstream(repo)
        # Suppress the legacy start banner so this command emits one stable result.
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                worktree = module.start(selected.workstream, repo)
        except module.WorkstreamError as error:
            raise DispatchError(f"workstream start blocked: {error}") from error
        _fetch(repo)
        published = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/agent/{selected.workstream}"], cwd=repo).returncode == 0
        if not published:
            raise DispatchError(f"workstream branch was not confirmed published; recovery claim retained at origin/{claim_ref}")
        # The canonical workstream branch is now durable; deleting the temporary
        # claim is safe. If cleanup fails, both refs remain and status explains it.
        subprocess.run(["git", "push", "origin", f":{claim_ref}"], cwd=repo, text=True, capture_output=True)
        git(repo, "update-ref", "-d", local_claim_ref, check=False)
        print("CLAIMED")
        print(f"workstream: {selected.workstream}")
        print(f"branch: agent/{selected.workstream}")
        print(f"worktree: {worktree}")
        print(f"packet: {selected.path}")
        print("\nNEXT:")
        print(f"cd {worktree}")
        print(f"Read AGENTS.md, custodian/AGENTS.md, then {selected.path}.")
        print("Implement only this workstream and finish through workstream.py.")
        print(f"agent: {agent}")
        return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    subs.add_parser("status")
    p = subs.add_parser("claim-next"); p.add_argument("--agent", default="codex")
    p = subs.add_parser("claim"); p.add_argument("workstream_id"); p.add_argument("--agent", default="codex")
    args = parser.parse_args(argv)
    try:
        repo = Path(git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        if args.command == "status":
            status(repo)
            return 0
        return claim(repo, getattr(args, "workstream_id", None), args.agent, args.command == "claim-next")
    except DispatchError as error:
        print(f"dispatch: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())