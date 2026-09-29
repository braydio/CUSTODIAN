#!/usr/bin/env python3
"""Discover and claim CUSTODIAN task packets from fetched origin/main."""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import importlib.util
import inspect
import io
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PACKET_ROOT = "custodian/docs/ai_context/task_packets"
FIELDS = (
    "Workstream", "Status", "Dispatch", "Priority", "Depends on", "Locks",
    "Kind", "Review", "Review stage", "Review modes", "Paired review workstream",
    "Review cycle", "Max automatic review cycles",
    "Review target workstream", "Review target packet",
)
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
PRIORITY = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
KINDS = {"implementation", "review", "correction"}
REVIEW_INTENTS = {"auto", "manual", "none"}
REVIEW_MODES = {"code", "architecture", "runtime", "visual", "asset-pipeline", "workflow"}


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
    kind: str = "implementation"
    review: str = "none"
    review_stage: str | None = None
    review_modes: tuple[str, ...] = ()
    paired_review_workstream: str | None = None
    review_cycle: int = 0
    max_review_cycles: int = 2
    review_target_workstream: str | None = None
    review_target_packet: str | None = None


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

    # Review metadata contract. Safe defaults keep historical packets valid:
    # missing Kind is implementation, missing Review is none, and missing
    # Review stage defaults to post-land only when review is actually auto.
    kind = values.get("Kind", "implementation").lower()
    if kind not in KINDS:
        errors.append("invalid Kind metadata")
    review = values.get("Review", "none").lower()
    if review not in REVIEW_INTENTS:
        errors.append("invalid Review metadata")
    review_stage_raw = values.get("Review stage")
    if review_stage_raw is not None and review_stage_raw.lower() != "post-land":
        errors.append("invalid Review stage metadata")
    review_stage = "post-land" if review == "auto" else (review_stage_raw.lower() if review_stage_raw else None)
    review_modes = csv_ids("Review modes")
    if any(mode not in REVIEW_MODES for mode in review_modes):
        errors.append("invalid Review modes metadata")
    paired_raw = values.get("Paired review workstream", "none")
    paired_review_workstream = None if paired_raw.lower() == "none" else paired_raw
    if paired_review_workstream is not None and not ID_RE.fullmatch(paired_review_workstream):
        errors.append("invalid Paired review workstream metadata")
    if review == "auto" and paired_review_workstream is None:
        errors.append("Review: auto requires a Paired review workstream")

    def non_negative_int(key: str, default: int) -> int:
        raw = values.get(key)
        if raw is None:
            return default
        try:
            parsed = int(raw)
        except ValueError:
            errors.append(f"invalid {key} metadata")
            return default
        if parsed < 0:
            errors.append(f"invalid {key} metadata")
            return default
        return parsed

    review_cycle = non_negative_int("Review cycle", 0)
    max_review_cycles = non_negative_int("Max automatic review cycles", 2)

    review_target_workstream = values.get("Review target workstream")
    if review_target_workstream is not None and review_target_workstream.lower() == "none":
        review_target_workstream = None
    if review_target_workstream is not None and not ID_RE.fullmatch(review_target_workstream):
        errors.append("invalid Review target workstream metadata")
    review_target_packet = values.get("Review target packet") or None

    return Packet(
        path, workstream, status, dispatch, dispatch_declared, priority, dependencies, locks,
        "; ".join(errors) or None,
        kind=kind, review=review, review_stage=review_stage, review_modes=review_modes,
        paired_review_workstream=paired_review_workstream, review_cycle=review_cycle,
        max_review_cycles=max_review_cycles, review_target_workstream=review_target_workstream,
        review_target_packet=review_target_packet,
    )


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


def validate_review_pairing(packets: list[Packet]) -> dict[str, str]:
    """Fail-fast consistency guard for the paired post-land review contract.

    Every active `Review: auto` packet must have a matching active review
    packet: same declared `Paired review workstream` id, `Kind: review`,
    `Review: none`, `Status: ready`, `Dispatch: auto`, a dependency back on the
    implementation workstream, and matching target workstream and canonical
    archived target-packet path. Historical packets that omit review metadata
    (`Review: none`, the default) are never required to pair.
    Reusable by both dispatcher eligibility and standalone tooling/tests, per
    the single reusable validation authority this contract requires.
    """
    by_workstream = {p.workstream: p for p in packets if p.workstream and not p.error}
    errors: dict[str, list[str]] = {}

    def add(workstream: str | None, message: str) -> None:
        if workstream:
            errors.setdefault(workstream, []).append(message)

    for p in packets:
        if p.error or p.review != "auto" or not p.workstream or p.paired_review_workstream is None:
            continue
        paired_id = p.paired_review_workstream
        paired = by_workstream.get(paired_id)
        if paired is None:
            add(p.workstream, f"paired review workstream '{paired_id}' has no matching active packet")
            continue
        if paired.kind != "review":
            add(p.workstream, f"paired review '{paired_id}' must declare Kind: review")
        if paired.review != "none":
            add(p.workstream, f"paired review '{paired_id}' must declare Review: none")
        if paired.status != "ready":
            add(p.workstream, f"paired review '{paired_id}' must declare Status: ready")
        if paired.dispatch != "auto":
            add(p.workstream, f"paired review '{paired_id}' must declare Dispatch: auto")
        if p.workstream not in paired.dependencies:
            add(p.workstream, f"paired review '{paired_id}' must depend on '{p.workstream}'")
        if paired.review_target_workstream != p.workstream:
            add(p.workstream, f"paired review '{paired_id}' Review target workstream must be '{p.workstream}'")
        expected_target = f"{PACKET_ROOT}/archived/{Path(p.path).name}"
        if paired.review_target_packet != expected_target:
            add(
                p.workstream,
                f"paired review '{paired_id}' Review target packet must be '{expected_target}'",
            )

    return {workstream: "; ".join(messages) for workstream, messages in errors.items()}


def review_cycle_exhausted(packet: Packet) -> bool:
    """True once a review/correction packet has reached its finite-loop cap.

    Original implementation review is cycle 0; each automatic correction's
    paired review increments the cycle. A reviewer at the cap escalates to
    `human_required` in the durable review receipt instead of scaffolding
    another automatic correction.
    """
    return packet.review_cycle >= packet.max_review_cycles


def _decision(
    packet: Packet, packets: list[Packet], archived: list[Packet], claimed: set[str],
    *, auto_only: bool, pairing_errors: dict[str, str] | None = None,
) -> tuple[bool, str | None]:
    if packet.error:
        return False, f"invalid packet metadata: {packet.error}"
    if pairing_errors and packet.workstream in pairing_errors:
        return False, f"invalid review pairing: {pairing_errors[packet.workstream]}"
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


def _git_common_dir(repo: Path) -> Path:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    return common


def _mutex(repo: Path):
    common = _git_common_dir(repo)
    common.mkdir(parents=True, exist_ok=True)
    handle = (common / "custodian-dispatch.lock").open("a")
    fcntl.flock(handle, fcntl.LOCK_EX)
    return handle


def _last_claim_path(repo: Path) -> Path:
    return _git_common_dir(repo) / "custodian-dispatch" / "last-claim.json"


def _write_last_claim_receipt(repo: Path, receipt: dict) -> None:
    """Persist the latest successful claim outside the worktree for stdout-loss recovery."""
    path = _last_claim_path(repo)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(receipt, indent=2) + "\n")
    os.replace(tmp, path)


def _attached_local_worktree(repo: Path, branch: str) -> str | None:
    for record in git(repo, "worktree", "list", "--porcelain").split("\n\n"):
        lines = record.splitlines()
        if lines and f"branch refs/heads/{branch}" in lines:
            return lines[0].removeprefix("worktree ")
    return None


def _start_workstream(module, workstream_id: str, repo: Path) -> tuple[Path, str | None]:
    """Call workstream.start(), passing a disposition side-channel only if supported.

    Test doubles that mock module.start with a plain (work_id, repo) callable must
    keep working unmodified, so the receiver capability is probed rather than assumed.
    """
    report: dict[str, str] = {}
    try:
        accepts_report = "report" in inspect.signature(module.start).parameters
    except (TypeError, ValueError):
        accepts_report = False
    if accepts_report:
        worktree = module.start(workstream_id, repo, report=report)
    else:
        worktree = module.start(workstream_id, repo)
    return Path(worktree), report.get("checkout")


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


def _packet_label(packet: Packet) -> str:
    name = packet.workstream or packet.path
    if packet.kind == "review" and packet.review_target_workstream:
        return f"{name} (review of {packet.review_target_workstream})"
    if packet.kind == "correction":
        return f"{name} (correction)"
    return name


def _render_status(repo: Path, packets: list[Packet], archived: list[Packet], claimed: set[str]) -> str:
    groups: dict[str, list[str]] = {key: [] for key in ("READY", "CLAIMED", "BLOCKED", "MANUAL")}
    claims, branches = _remote_claim_state(repo)
    pairing_errors = validate_review_pairing(packets)
    for work_id in sorted(claims - branches):
        groups["BLOCKED"].append(
            f"{work_id} — remote dispatch claim interrupted; recovery required. "
            f"Inspect refs/heads/dispatch-claims/{work_id}; after verifying no live claimant, "
            f"an operator may explicitly delete it with git push origin :refs/heads/dispatch-claims/{work_id}."
        )
    for packet in sorted(packets, key=lambda item: (PRIORITY.get(item.priority, 9), item.path)):
        name = _packet_label(packet)
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
            ok, reason = _decision(packet, packets, archived, claimed, auto_only=True, pairing_errors=pairing_errors)
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
        pairing_errors = validate_review_pairing(packets)
        ordered = sorted(packets, key=lambda p: (PRIORITY.get(p.priority, 9), p.path))
        if workstream_id:
            candidates = [p for p in ordered if p.workstream == workstream_id]
        else:
            candidates = ordered
        selected = None
        reasons: list[str] = []
        for packet in candidates:
            ok, reason = _decision(packet, packets, archived, claimed, auto_only=auto_only, pairing_errors=pairing_errors)
            if ok:
                selected = packet
                break
            if reason:
                reasons.append(f"{packet.workstream or packet.path}: {reason}")
        if selected is None:
            if workstream_id and not candidates:
                raise DispatchError(f"packet for workstream {workstream_id} does not exist on origin/main")
            if workstream_id and workstream_id in claimed:
                branch = f"agent/{workstream_id}"
                attached = _attached_local_worktree(repo, branch)
                raise DispatchError(
                    "ALREADY CLAIMED\n"
                    f"workstream: {workstream_id}\n"
                    f"branch: {branch}\n"
                    f"worktree: {attached or 'not attached locally'}"
                )
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
                worktree, checkout = _start_workstream(module, selected.workstream, repo)
        except module.WorkstreamError as error:
            raise DispatchError(f"workstream start blocked: {error}") from error

        # Post-start identity verification: the receipt is the assignment authority,
        # so nothing is printed/persisted as CLAIMED unless the checkout returned by
        # workstream.py is actually the one selected, not merely some worktree that
        # happens to exist. Any failure here leaves the recovery claim ref intact.
        expected_branch = f"agent/{selected.workstream}"
        if not worktree.is_dir():
            raise DispatchError(
                f"post-start verification failed: worktree does not exist at {worktree}; "
                f"recovery claim retained at origin/{claim_ref}"
            )
        actual_branch = git(worktree, "branch", "--show-current", check=False)
        if actual_branch != expected_branch:
            raise DispatchError(
                f"post-start verification failed: worktree {worktree} is on branch "
                f"{actual_branch!r}, expected {expected_branch!r}; "
                f"recovery claim retained at origin/{claim_ref}"
            )
        _fetch(repo)
        published = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{expected_branch}"], cwd=repo).returncode == 0
        if not published:
            raise DispatchError(f"workstream branch was not confirmed published; recovery claim retained at origin/{claim_ref}")
        claimed_after = _claimed(repo)
        if selected.workstream not in claimed_after:
            raise DispatchError(
                f"post-start verification failed: dispatcher claimed-state logic does not yet "
                f"recognize {selected.workstream} as claimed; recovery claim retained at origin/{claim_ref}"
            )
        # The canonical workstream branch is now durable; deleting the temporary
        # claim is safe. If cleanup fails, both refs remain and status explains it.
        subprocess.run(["git", "push", "origin", f":{claim_ref}"], cwd=repo, text=True, capture_output=True)
        git(repo, "update-ref", "-d", local_claim_ref, check=False)

        receipt = {
            "schema": "custodian.dispatch.claim.v1",
            "result": "claimed",
            "workstream": selected.workstream,
            "prior_status": selected.status,
            "branch": expected_branch,
            "worktree": str(worktree),
            "packet": selected.path,
            "checkout": checkout,
            "verified": True,
            "agent": agent,
        }
        _write_last_claim_receipt(repo, receipt)

        print("CLAIMED")
        print(f"workstream: {selected.workstream}")
        print(f"branch: {expected_branch}")
        print(f"worktree: {worktree}")
        print(f"packet: {selected.path}")
        print("\nNEXT:")
        print(f"cd {worktree}")
        print(f"Read AGENTS.md, custodian/AGENTS.md, then {selected.path}.")
        print("Implement only this workstream and finish through workstream.py.")
        print(f"agent: {agent}")
        print("CUSTODIAN_DISPATCH_RESULT_JSON:" + json.dumps(receipt))
        return 0


def last_claim(repo: Path, *, as_json: bool) -> int:
    """Recover the last successful claim's identity after stdout loss.

    Read-only: refreshes remote-tracking refs to judge freshness but never
    mutates, re-claims, or recreates anything, even when the receipt is stale.
    """
    repo = _coordination_repo(repo)
    path = _last_claim_path(repo)
    if not path.is_file():
        if as_json:
            print(json.dumps({"schema": "custodian.dispatch.claim.v1", "result": "no-receipt"}))
        else:
            print("NO LAST CLAIM RECEIPT")
        return 1

    try:
        receipt = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise DispatchError(f"last-claim receipt is unreadable: {error}") from error

    _fetch(repo)
    branch = receipt.get("branch")
    worktree = receipt.get("worktree")
    stale_reasons: list[str] = []
    if worktree:
        worktree_path = Path(worktree)
        if not worktree_path.is_dir():
            stale_reasons.append("worktree path no longer exists locally")
        elif branch:
            actual_branch = git(worktree_path, "branch", "--show-current", check=False)
            if actual_branch != branch:
                stale_reasons.append(f"worktree is now on branch {actual_branch!r}, not {branch!r}")
    if branch:
        published = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo
        ).returncode == 0
        if not published:
            stale_reasons.append(f"remote {branch} no longer exists")

    freshness = "stale" if stale_reasons else "current"
    if as_json:
        output = dict(receipt)
        output["freshness"] = freshness
        output["freshness_reasons"] = stale_reasons
        print(json.dumps(output))
    else:
        print("LAST CLAIM")
        print(f"workstream: {receipt.get('workstream')}")
        print(f"branch: {branch}")
        print(f"worktree: {worktree}")
        print(f"packet: {receipt.get('packet')}")
        print(f"checkout: {receipt.get('checkout')}")
        suffix = f" ({'; '.join(stale_reasons)})" if stale_reasons else ""
        print(f"freshness: {freshness}{suffix}")
        print("\nNEXT:")
        print(f"cd {worktree}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    subs.add_parser("status")
    p = subs.add_parser("claim-next"); p.add_argument("--agent", default="codex")
    p = subs.add_parser("claim"); p.add_argument("workstream_id"); p.add_argument("--agent", default="codex")
    p = subs.add_parser("last-claim"); p.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args(argv)
    try:
        repo = Path(git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        if args.command == "last-claim":
            return last_claim(repo, as_json=args.as_json)
        if args.command == "status":
            status(repo)
            return 0
        return claim(repo, getattr(args, "workstream_id", None), args.agent, args.command == "claim-next")
    except DispatchError as error:
        print(f"dispatch: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
