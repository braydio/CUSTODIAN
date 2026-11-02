#!/usr/bin/env python3
"""Read-only evidence inventory for supervised and historical workstreams.

This tool deliberately avoids ``dispatch.py audit``'s fetch step: audit must
not update FETCH_HEAD or remote-tracking refs. Remote facts are read with
``git ls-remote`` and local dispatcher packet/branch evidence is read in place.
No classification releases a claim or changes a checkout.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import socket
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from session_supervisor import (JOURNAL_ROOT, SupervisorError, _boot_id, _proc_stat,
                                common_dir, process_snapshot, read_journal)
from task_packet_contract import PACKET_ROOT, parse_packet

SCHEMA = "custodian.workstream_recovery_audit.v1"


class RecoveryAuditError(RuntimeError):
    pass


def _git(repo: Path, *args: str, check: bool = True, timeout: float = 30.0) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, timeout=timeout)
    if check and result.returncode:
        raise RecoveryAuditError(f"git {args[0]} could not supply read-only recovery evidence")
    return result.stdout.strip()


def _remote_heads(repo: Path) -> tuple[dict[str, str], bool]:
    result = subprocess.run(["git", "ls-remote", "--heads", "origin", "refs/heads/agent/*",
                             "refs/heads/dispatch-claims/*", "refs/heads/main"],
                            cwd=repo, text=True, capture_output=True, timeout=30)
    if result.returncode:
        return {}, False
    refs: dict[str, str] = {}
    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[1].startswith("refs/heads/"):
            refs[fields[1].removeprefix("refs/heads/")] = fields[0]
    return refs, True


def _packets(repo: Path) -> tuple[dict[str, object], dict[str, str]]:
    result: dict[str, object] = {}
    paths: dict[str, str] = {}
    roots = (repo / PACKET_ROOT, repo / PACKET_ROOT / "archived")
    for root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.glob("*.md")):
            if path.name == "README.md" or path.is_symlink():
                continue
            relative = path.relative_to(repo).as_posix()
            try:
                packet = parse_packet(relative, path.read_text(encoding="utf-8"))
            except (OSError, UnicodeDecodeError):
                continue
            if packet.workstream:
                result[packet.workstream] = packet
                paths[packet.workstream] = relative
    return result, paths


def _worktrees(repo: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    current = None
    for line in _git(repo, "worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            current = line.removeprefix("worktree ")
        elif line.startswith("branch refs/heads/agent/") and current:
            result[line.removeprefix("branch refs/heads/")] = current
    return result


def _dirty(worktree: Path) -> tuple[bool | None, int | None, int | None, str | None]:
    if not worktree.is_dir():
        return None, None, None, None
    result = subprocess.run(["git", "status", "--porcelain=v2", "-z", "--untracked-files=all"],
                            cwd=worktree, capture_output=True, timeout=20)
    if result.returncode:
        return None, None, None, None
    rows = [row for row in result.stdout.split(b"\0") if row]
    tracked = untracked = 0
    index = 0
    while index < len(rows):
        row = rows[index]
        if row.startswith(b"? "):
            untracked += 1
        elif row.startswith((b"1 ", b"2 ", b"u ")):
            tracked += 1
            if row.startswith(b"2 ") and index + 1 < len(rows):
                index += 1  # porcelain v2 places the original rename path in its own NUL field
        index += 1
    return bool(tracked or untracked), untracked, tracked, hashlib.sha256(result.stdout).hexdigest()


def _exact_live_identities(event: dict, host: str, boot_id: str) -> tuple[list[dict], bool]:
    if event.get("host") != host:
        return [], False
    if boot_id == "unavailable":
        return [], False
    recorded_boot = event.get("boot_id")
    if recorded_boot != boot_id:
        return [], True  # Same host rebooted: all processes from the prior boot are gone.
    child = event.get("child") or {}
    try:
        root_pid, pgid = int(child["pid"]), int(event["process_group"])
    except (KeyError, TypeError, ValueError):
        return [], False
    current, complete = process_snapshot(root_pid, pgid)
    recorded: dict[int, int] = {}
    identities = event.get("observed_processes", event.get("processes", []))
    for identity in identities:
        if isinstance(identity, dict):
            try:
                recorded[int(identity["pid"])] = int(identity["start_ticks"])
            except (KeyError, TypeError, ValueError):
                continue
    exact_live = [item for item in current if recorded.get(item["pid"]) == item["start_ticks"]]
    reused = [item for item in current if item["pid"] in recorded and recorded[item["pid"]] != item["start_ticks"]]
    unknown_current = any(item["pid"] not in recorded for item in current)
    return exact_live, complete and not reused and not unknown_current


def _journal_rows(repo: Path, host: str, boot_id: str, packet_map: dict[str, object],
                  worktree_map: dict[str, str], remote: dict[str, str], remote_ok: bool) -> list[dict]:
    root = common_dir(repo) / JOURNAL_ROOT
    if not root.is_dir():
        return []
    rows = []
    for path in sorted(root.glob("*/*.jsonl")):
        workstream = path.parent.name
        evidence = [{"kind": "supervisor_journal", "path": str(path)}]
        try:
            if not path.resolve().is_relative_to(root.resolve()):
                raise SupervisorError("journal path escapes the supervisor metadata root")
            events = read_journal(path)
            latest = events[-1]
            observed = {}
            for event in events:
                for identity in event.get("processes", []):
                    if isinstance(identity, dict):
                        try:
                            observed[int(identity["pid"])] = int(identity["start_ticks"])
                        except (KeyError, TypeError, ValueError):
                            continue
            latest["observed_processes"] = [{"pid": pid, "start_ticks": ticks}
                                            for pid, ticks in sorted(observed.items())]
        except SupervisorError as exc:
            rows.append({"workstream": workstream, "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                         "evidence": evidence, "recommended_action": "Preserve the record and inspect its hash-chain error.",
                         "evidence_gap": str(exc), "affected_locks": list(getattr(packet_map.get(workstream), "locks", ()))})
            continue
        evidence.append({"kind": "journal_event", "sequence": latest["sequence"],
                         "event": latest["event"], "sha256": latest["event_sha256"]})
        trace_ref = latest.get("dispatch_trace_ref")
        dispatch_run_id = latest.get("dispatch_run_id")
        if dispatch_run_id:
            trace_path = common_dir(repo) / "custodian-workflow" / "traces" / workstream / f"{dispatch_run_id}.jsonl"
            if trace_path.is_file() and not trace_path.is_symlink() and trace_path.stat().st_size <= 2 * 1024 * 1024:
                try:
                    trace_bytes = trace_path.read_bytes()
                    trace_events = [json.loads(line) for line in trace_bytes.decode("utf-8").splitlines() if line.strip()]
                    trace_valid = bool(trace_events) and all(
                        item.get("workstream") == workstream and item.get("run_id") == dispatch_run_id
                        for item in trace_events
                    )
                    evidence.append({"kind": "dispatch_run_trace", "path": str(trace_path),
                                     "trace_ref": trace_ref, "event_count": len(trace_events),
                                     "sha256": hashlib.sha256(trace_bytes).hexdigest(), "identity_valid": trace_valid})
                except (OSError, UnicodeDecodeError, json.JSONDecodeError):
                    evidence.append({"kind": "dispatch_run_trace", "path": str(trace_path),
                                     "trace_ref": trace_ref, "identity_valid": False})
            else:
                evidence.append({"kind": "dispatch_run_trace", "trace_ref": trace_ref,
                                 "identity_valid": False, "availability": "local trace not present"})
        base = {key: latest.get(key) for key in ("run_id", "branch", "worktree", "packet", "branch_sha",
               "remote_branch_sha", "dispatch_run_id", "claim_receipt_sha256", "host", "boot_id")}
        row = {"workstream": workstream, **base, "evidence": evidence,
               "affected_locks": list(getattr(packet_map.get(workstream), "locks", ())),
               "dirty": None, "untracked_count": None}
        if latest.get("host") != host:
            row.update(classification="FOREIGN_HOST_UNKNOWN", recommended_action="Resume or inspect only on the recorded host.",
                       evidence_gap="process state on the recorded host is unavailable")
            rows.append(row)
            continue
        live, scan_complete = _exact_live_identities(latest, host, boot_id)
        if live:
            row.update(classification="LIVE", live_processes=[{"pid": item["pid"], "start_ticks": item["start_ticks"]} for item in live],
                       recommended_action="Keep the original claim and worktree; do not park or reassign in OR1.",
                       evidence_gap=None if scan_complete else "process scan had unreadable entries")
            rows.append(row)
            continue
        exit_proven = (latest.get("event") == "EXITED_CONFIRMED"
                       or (latest.get("boot_id") != boot_id and scan_complete)
                       or (scan_complete and latest.get("boot_id") == boot_id
                           and latest.get("event") not in {"LAUNCH_INTENT", "LAUNCH_FAILED"}))
        if exit_proven:
            row["process_classification"] = "EXITED_CONFIRMED"
            if not scan_complete or not remote_ok:
                row.update(classification="REMOTE_RACE_OR_AMBIGUOUS", recommended_action="Preserve claim; repeat audit after evidence is available.",
                           evidence_gap="process or remote evidence is incomplete")
            else:
                workstream = str(latest.get("workstream"))
                branch_sha = remote.get(f"agent/{workstream}")
                main_sha = remote.get("main")
                if branch_sha is None or branch_sha != latest.get("branch_head"):
                    row.update(classification="REMOTE_RACE_OR_AMBIGUOUS", recommended_action="Preserve claim and reconcile exact branch SHA.",
                               evidence_gap="remote branch is absent or differs from the last supervised branch head")
                else:
                    worktree = Path(str(latest.get("worktree", "")))
                    dirty, untracked, tracked, status_hash = _dirty(worktree)
                    row["dirty"], row["untracked_count"], row["tracked_change_count"] = dirty, untracked, tracked
                    if status_hash:
                        evidence.append({"kind": "git_status_porcelain_sha256", "sha256": status_hash})
                    available = subprocess.run(["git", "cat-file", "-e", f"{main_sha}^{{commit}}"],
                                                cwd=repo, capture_output=True, timeout=20).returncode == 0 if main_sha else False
                    merged = (available and subprocess.run(
                        ["git", "merge-base", "--is-ancestor", branch_sha, main_sha],
                        cwd=repo, capture_output=True, timeout=20).returncode == 0)
                    if merged:
                        classification, action = "LANDED_PENDING_TEARDOWN", "Use normal workstream finish/teardown evidence; do not remove files from audit."
                    elif dirty is False:
                        classification, action = "RECOVERABLE_CLEAN", "Resume the exact same worktree through workstream lifecycle after ownership review."
                    elif dirty is True:
                        classification, action = "RECOVERABLE_DIRTY", "Preserve the exact existing worktree; no reset, stash, or cleanup is authorized."
                    else:
                        classification, action = "REMOTE_RACE_OR_AMBIGUOUS", "Preserve claim and worktree until status can be read."
                    row.update(classification=classification, recommended_action=action,
                               evidence_gap=None if dirty is not None else "worktree status is unavailable")
        else:
            row["process_classification"] = "REMOTE_RACE_OR_AMBIGUOUS"
            row.update(classification="REMOTE_RACE_OR_AMBIGUOUS", recommended_action="Preserve the claim and inspect process identity evidence.",
                       evidence_gap="no final exit event and exact process absence was not proven")
        rows.append(row)
    return rows


def _review_recovery_rows(repo: Path, packet_map: dict[str, object], remote: dict[str, str]) -> list[dict]:
    root = common_dir(repo) / "custodian-review-runs"
    if root.is_symlink() or not root.is_dir():
        return []
    rows = []
    for path in sorted(root.glob("*/*/metadata.json")):
        workstream = path.parents[1].name
        run_id = path.parent.name
        evidence = [{"kind": "paired_review_metadata", "path": str(path)}]
        try:
            if (path.is_symlink() or path.stat().st_size > 256 * 1024
                    or not path.resolve().is_relative_to(common_dir(repo).resolve())):
                rows.append({"workstream": workstream, "run_id": run_id,
                             "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                             "affected_locks": list(getattr(packet_map.get(workstream), "locks", ())),
                             "evidence": evidence,
                             "recommended_action": "Preserve the review run and inspect its metadata boundary.",
                             "evidence_gap": "review metadata is oversized, symlinked, or outside the Git common directory"})
                continue
            metadata = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError, UnicodeDecodeError):
            rows.append({"workstream": workstream, "run_id": run_id,
                         "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                         "affected_locks": list(getattr(packet_map.get(workstream), "locks", ())),
                         "evidence": evidence,
                         "recommended_action": "Preserve the review run and investigate the malformed metadata.",
                         "evidence_gap": "review metadata could not be parsed"})
            continue
        if (not isinstance(metadata, dict) or metadata.get("schema") != "custodian.paired_review_run.v1"
                or metadata.get("workstream") != workstream or metadata.get("run_id") != run_id):
            rows.append({"workstream": workstream, "run_id": run_id,
                         "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                         "affected_locks": list(getattr(packet_map.get(workstream), "locks", ())),
                         "evidence": evidence,
                         "recommended_action": "Preserve the review run and verify its recorded identity.",
                         "evidence_gap": "review metadata schema or workstream/run identity does not match its path"})
            continue
        phase = metadata.get("phase")
        interesting = (phase in {"post_exit_recovery", "codex_running", "claimed", "codex_exited"}
                       or "recovery" in str(phase) or str(phase).startswith(("failed_", "reviewer_blocked")))
        if not interesting:
            continue
        run_dir = path.parent.resolve()
        if not run_dir.is_relative_to(common_dir(repo).resolve()):
            continue
        marker = str(run_dir / "last-message.txt").encode()
        receipt_path = run_dir / "claim-receipt.json"
        claim_receipt = None
        claim_receipt_sha = None
        if receipt_path.is_file() and not receipt_path.is_symlink():
            try:
                raw_receipt = receipt_path.read_bytes()
                parsed_receipt = json.loads(raw_receipt)
                if (isinstance(parsed_receipt, dict)
                        and parsed_receipt.get("schema") == "custodian.dispatch.claim.v1"
                        and parsed_receipt.get("result") == "claimed"
                        and parsed_receipt.get("verified") is True
                        and parsed_receipt.get("workstream") == workstream):
                    claim_receipt = parsed_receipt
                    claim_receipt_sha = hashlib.sha256(raw_receipt).hexdigest()
            except (OSError, json.JSONDecodeError, UnicodeDecodeError):
                claim_receipt = None
        exact_processes = []
        proc_root = Path("/proc")
        scan_complete = proc_root.is_dir()
        if phase == "codex_running" and scan_complete:
            for entry in proc_root.iterdir():
                if not entry.name.isdigit():
                    continue
                try:
                    argv = (entry / "cmdline").read_bytes().split(b"\0")
                    if marker in argv:
                        process = _proc_stat(int(entry.name))
                        if process and process["state"] != "Z":
                            exact_processes.append(process)
                except FileNotFoundError:
                    continue
                except (PermissionError, OSError):
                    scan_complete = False
        if phase != "codex_running" and scan_complete:
            for entry in proc_root.iterdir():
                if not entry.name.isdigit():
                    continue
                try:
                    argv = [item.decode("utf-8", errors="replace") for item in
                            (entry / "cmdline").read_bytes().split(b"\0") if item]
                    script_match = any(Path(item).name == "paired_review_runner.py" for item in argv)
                    if script_match and workstream in argv:
                        process = _proc_stat(int(entry.name))
                        if process and process["state"] != "Z":
                            exact_processes.append(process)
                except FileNotFoundError:
                    continue
                except (PermissionError, OSError):
                    scan_complete = False
        live = []
        for process in exact_processes:
            tree, complete = process_snapshot(process["pid"], process["pgid"])
            scan_complete = scan_complete and complete
            live.extend(tree or [process])
        if live:
            classification = "LIVE"
            action = "Keep the original review claim and evidence; do not infer a verdict or release ownership."
            gap = None if scan_complete else "some process entries were unreadable"
        else:
            classification = "REVIEW_FINDINGS_OR_BLOCKED"
            action = "Preserve original reviewer evidence; resume only through the paired-review recovery path."
            gap = ("Codex-running metadata has no matching live process; exit/outcome is not authenticated"
                   if phase == "codex_running" else
                   "reviewer outcome is unresolved and must not be inferred as PASS")
        branch = claim_receipt.get("branch") if claim_receipt else metadata.get("branch")
        remote_sha = remote.get(str(branch).removeprefix("refs/heads/")) if branch else None
        if claim_receipt and (branch != f"agent/{workstream}" or remote_sha is None):
            gap = "review claim receipt is valid but its exact remote agent branch is unavailable"
        rows.append({"workstream": workstream, "run_id": metadata.get("run_id"),
                     "branch": branch, "remote_branch_sha": remote_sha,
                     "worktree": claim_receipt.get("worktree") if claim_receipt else metadata.get("worktree"),
                     "claim_receipt_sha256": claim_receipt_sha,
                     "review_phase": phase, "review_outcome": "unresolved",
                     "classification": classification,
                     "live_processes": [{"pid": item["pid"], "start_ticks": item["start_ticks"]} for item in live],
                     "affected_locks": list(getattr(packet_map.get(workstream), "locks", ())),
                     "evidence": [{"kind": "paired_review_metadata", "path": str(path), "phase": phase},
                                  *([{"kind": "paired_review_claim_receipt", "path": str(receipt_path),
                                     "sha256": claim_receipt_sha, "branch": claim_receipt.get("branch"),
                                     "worktree": claim_receipt.get("worktree")}] if claim_receipt else [])],
                     "recommended_action": action, "evidence_gap": gap})
    return rows


def _unmanaged_codex_processes(worktrees: dict[str, str], packet_map: dict[str, object],
                               known_live: set[tuple[int, int]]) -> tuple[list[dict], bool]:
    proc_root = Path("/proc")
    if not proc_root.is_dir():
        return [], False
    path_to_branch = {str(Path(path).resolve()): branch for branch, path in worktrees.items()}
    rows = []
    complete = True
    for entry in proc_root.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            argv = (entry / "cmdline").read_bytes().split(b"\0")
            first = argv[0].decode("utf-8", errors="replace") if argv and argv[0] else ""
            if Path(first).name.lower() != "codex":
                continue
            process = _proc_stat(int(entry.name))
            if process is None or process["state"] == "Z":
                continue
            identity = (process["pid"], process["start_ticks"])
            if identity in known_live:
                continue
            try:
                cwd = str((entry / "cwd").resolve())
            except (FileNotFoundError, PermissionError, OSError):
                cwd = None
                complete = False
            match = next(((branch, path) for path, branch in path_to_branch.items()
                          if cwd and (cwd == path or cwd.startswith(path + os.sep))), None)
            rows.append({"workstream": None, "classification": "UNMANAGED_UNKNOWN",
                         "pid": process["pid"], "start_ticks": process["start_ticks"],
                         "host": socket.gethostname(),
                         "candidate_workstream": match[0].removeprefix("agent/") if match else None,
                         "candidate_worktree": match[1] if match else None,
                         "affected_locks": list(getattr(packet_map.get(match[0].removeprefix("agent/")),
                                                       "locks", ())) if match else [],
                         "evidence": [{"kind": "local_codex_process", "pid": process["pid"],
                                       "start_ticks": process["start_ticks"], "executable": "codex",
                                       "cwd": cwd}],
                         "recommended_action": "Do not attach or terminate an unmanaged session; verify its owner and exact claim locally.",
                         "evidence_gap": "no matching verified supervisor journal or paired-review run marker"})
        except FileNotFoundError:
            continue
        except (PermissionError, OSError):
            complete = False
    return rows, complete


def audit(repo: Path) -> dict:
    repo = Path(_git(repo, "rev-parse", "--show-toplevel")).resolve()
    packet_map, packet_paths = _packets(repo)
    worktree_map = _worktrees(repo)
    remote, remote_ok = _remote_heads(repo)
    cached_main = _git(repo, "rev-parse", "--verify", "refs/remotes/origin/main", check=False) or None
    remote_main = remote.get("main")
    current_host = socket.gethostname()
    try:
        boot_id = _boot_id()
    except SupervisorError:
        boot_id = "unavailable"
    rows = _journal_rows(repo, current_host, boot_id, packet_map, worktree_map, remote, remote_ok)
    rows.extend(_review_recovery_rows(repo, packet_map, remote))
    observed = {row["workstream"] for row in rows if row.get("workstream")}
    known_live = set()
    for row in rows:
        for process in row.get("live_processes", []):
            try:
                known_live.add((int(process["pid"]), int(process["start_ticks"])))
            except (KeyError, TypeError, ValueError):
                continue
    unmanaged, process_scan_complete = _unmanaged_codex_processes(worktree_map, packet_map, known_live)
    rows.extend(unmanaged)
    # Journal absence is not an additional veto for the existing same-claim
    # workstream resume lifecycle. A live unmanaged process may still own the
    # checkout, so suppress the resume hint when that process is observed.
    unmanaged_candidate_workstreams = {
        item.get("candidate_workstream") for item in unmanaged
        if item.get("candidate_workstream")
    }
    if not process_scan_complete:
        rows.append({"workstream": None, "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                     "evidence": [{"kind": "local_process_scan", "complete": False}],
                     "recommended_action": "Treat unobserved local Codex ownership as unknown; rerun with complete /proc access.",
                     "evidence_gap": "one or more process identities or working directories were unreadable"})
    if remote_ok:
        local_agent_refs = {}
        for line in _git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads/agent").splitlines():
            fields = line.split()
            if len(fields) == 2:
                local_agent_refs[fields[0].removeprefix("agent/")] = fields[1]
        branch_rows = {key.removeprefix("agent/"): value for key, value in remote.items() if key.startswith("agent/")}
        for workstream, local_sha in sorted(local_agent_refs.items()):
            branch_rows.setdefault(workstream, local_sha)
        for workstream, sha in sorted(branch_rows.items()):
            branch = f"agent/{workstream}"
            if workstream in observed:
                continue
            worktree_value = worktree_map.get(branch)
            dirty, untracked, tracked, status_hash = _dirty(Path(worktree_value)) if worktree_value else (None, None, None, None)
            packet = packet_map.get(workstream)
            classification = "UNMANAGED_UNKNOWN" if f"agent/{workstream}" in remote else "REMOTE_RACE_OR_AMBIGUOUS"
            recommendation = "Do not infer liveness or release its claim from branch age; preserve and investigate owner locally."
            if (classification == "UNMANAGED_UNKNOWN" and worktree_value
                    and dirty is False and process_scan_complete
                    and workstream not in unmanaged_candidate_workstreams):
                recommendation = (
                    "Missing supervisor journal is not a standalone resume veto. "
                    "With explicit project-owner authorization, recheck the exact "
                    "claim, clean checkout and absence of competing live writers; "
                    "then attempt python3 custodian/tools/agent/workstream.py "
                    f"resume {workstream}. The audit itself does not authorize "
                    "claim release, force-removal, or review acceptance."
                )
            row = {"workstream": workstream, "classification": classification,
                   "branch": branch, "remote_branch_sha": sha, "worktree": worktree_value,
                   "dirty": dirty, "untracked_count": untracked, "tracked_change_count": tracked,
                   "affected_locks": list(getattr(packet, "locks", ())),
                   "packet": packet_paths.get(workstream),
                   "evidence": [{"kind": "remote_agent_branch", "ref": f"refs/heads/{branch}", "sha": sha}],
                   "recommended_action": recommendation,
                   "evidence_gap": ("no verified supervised process journal for this workstream"
                                    if classification == "UNMANAGED_UNKNOWN"
                                    else "local agent branch has not been verified on origin")}
            if worktree_value:
                row["evidence"].append({"kind": "attached_worktree", "path": worktree_value,
                                         "dirty": dirty, "untracked_count": untracked,
                                         "tracked_change_count": tracked})
            if status_hash:
                row["evidence"].append({"kind": "git_status_porcelain_sha256", "sha256": status_hash})
            rows.append(row)
        for branch, sha in sorted(remote.items()):
            if not branch.startswith("dispatch-claims/"):
                continue
            workstream = branch.removeprefix("dispatch-claims/")
            if f"agent/{workstream}" not in remote:
                rows.append({"workstream": workstream, "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                             "remote_claim_sha": sha, "affected_locks": list(getattr(packet_map.get(workstream), "locks", ())),
                             "evidence": [{"kind": "remote_dispatch_claim", "ref": f"refs/heads/{branch}", "sha": sha}],
                             "recommended_action": "Preserve the claim ref and use dispatcher recovery evidence; do not delete it from OR1.",
                             "evidence_gap": "dispatch assignment ref exists without a verified agent branch"})
    else:
        rows.append({"workstream": None, "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                     "evidence": [{"kind": "origin_query", "result": "unavailable"}],
                     "recommended_action": "Retry after origin is reachable; do not infer remote ownership.",
                     "evidence_gap": "origin ls-remote failed"})
    if remote_main and cached_main != remote_main:
        rows.append({"workstream": None, "classification": "REMOTE_RACE_OR_AMBIGUOUS",
                     "evidence": [{"kind": "main_ref_comparison", "cached_origin_main": cached_main,
                                   "remote_main": remote_main}],
                     "recommended_action": "Refresh through normal coordination workflow before comparing branch ancestry.",
                     "evidence_gap": "cached origin/main differs from origin; audit intentionally did not fetch"})
    rows.sort(key=lambda item: (str(item.get("workstream") or ""), item["classification"]))
    return {"schema": SCHEMA, "generated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "host": current_host, "boot_id": boot_id, "remote_query_read_only": True,
            "git_fetch_performed": False, "cached_origin_main": cached_main, "remote_main": remote_main,
            "items": rows}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    audit_cmd = subs.add_parser("audit")
    audit_cmd.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        repo = Path(_git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        result = audit(repo)
        if args.json:
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            print("WORKSTREAM RECOVERY AUDIT (read-only; no fetch or Git-ref writes)")
            counts: dict[str, int] = {}
            for item in result["items"]:
                label = item["classification"]
                counts[label] = counts.get(label, 0) + 1
                if item.get("workstream"):
                    print(f"{label}: {item['workstream']} — {item.get('recommended_action', '')}")
            for label, count in sorted(counts.items()):
                print(f"{label}: {count}")
        return 0
    except (RecoveryAuditError, SupervisorError, OSError, subprocess.SubprocessError) as exc:
        print(f"workstream_recovery: BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
