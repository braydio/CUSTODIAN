#!/usr/bin/env python3
"""Read-only census of CUSTODIAN worktrees, packet identities and claims.

This tool deliberately inventories evidence. It does not decide that a checkout
is abandoned and never changes a worktree, branch, claim, or packet.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


SCHEMA = "custodian.worktree_backlog_census.v1"
CLASSIFICATIONS = {
    "ACTIVE_PROTECT", "RECOVERABLE_ORIGINAL_CLAIM", "DIRTY_OR_UNIQUE_PRESERVE_FIRST",
    "DRAFT_PARK_NO_MUTATION", "BLOCKED_REVIEW_DISPOSITION", "ARCHIVED_RESIDUE_CANDIDATE",
    "DETACHED_SUPPORT_PRESERVE", "CLAIM_ONLY_INTERRUPTED", "INVALID_QUEUE_RECORD", "UNKNOWN_PROTECT",
}


class CensusError(RuntimeError):
    pass


def run(args: list[str], cwd: Path) -> bytes:
    result = subprocess.run(["git", *args], cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        detail = result.stderr.decode("utf-8", "replace").strip()
        raise CensusError(f"git {' '.join(args)} failed ({result.returncode}): {detail}")
    return result.stdout


def git_text(args: list[str], cwd: Path) -> str:
    return run(args, cwd).decode("utf-8", "replace").strip()


def parse_worktrees(raw: bytes) -> list[dict]:
    records: list[dict] = []
    current: dict[str, str | bool] = {}
    for line in raw.decode("utf-8", "surrogateescape").splitlines() + [""]:
        if not line:
            if current:
                if "worktree" not in current or "HEAD" not in current:
                    raise CensusError("malformed git worktree porcelain record")
                current["worktree_path"] = str(Path(str(current.pop("worktree"))).expanduser().resolve(strict=False))
                records.append(current)
                current = {}
            continue
        if line.startswith("worktree "):
            if "worktree" in current:
                raise CensusError("duplicate worktree path field")
            current["worktree"] = line[9:]
        elif line == "detached":
            current["detached"] = True
        elif line == "bare":
            current["bare"] = True
        elif line.startswith(("HEAD ", "branch ", "locked ", "prunable ")):
            key, value = line.split(" ", 1)
            current[key] = value
        else:
            raise CensusError("unknown worktree porcelain field")
    paths = [row["worktree_path"] for row in records]
    if len(set(paths)) != len(paths):
        raise CensusError("duplicate canonical worktree path; UNKNOWN_PROTECT")
    return sorted(records, key=lambda row: str(row["worktree_path"]))


def status_counts(raw: bytes) -> tuple[int, int, int, str]:
    """Count v2 entries and hash exact bytes without recording private names."""
    staged = unstaged = untracked = 0
    records = raw.split(b"\0")
    skip_original_path = False
    for record in records:
        if not record:
            continue
        if skip_original_path:
            skip_original_path = False
            continue
        if record.startswith(b"? "):
            untracked += 1
        elif record.startswith((b"1 ", b"2 ", b"u ")):
            fields = record.split(b" ", 8)
            if len(fields) < 9:
                raise CensusError("malformed porcelain v2 entry; UNKNOWN_PROTECT")
            xy = fields[1]
            if len(xy) != 2:
                raise CensusError("malformed porcelain v2 XY state; UNKNOWN_PROTECT")
            staged += int(xy[0:1] != b".")
            unstaged += int(xy[1:2] != b".")
            skip_original_path = record.startswith(b"2 ")
        elif record.startswith(b"! "):
            continue
        else:
            raise CensusError("malformed porcelain v2 record; UNKNOWN_PROTECT")
    return staged, unstaged, untracked, hashlib.sha256(raw).hexdigest()


def packet_index(repo: Path, audit: dict) -> tuple[dict[str, dict], list[dict]]:
    identities: dict[str, dict] = {}
    invalid: list[dict] = []
    for row in audit.get("packets", []):
        workstream = row.get("workstream")
        packet_path = row.get("path")
        item = {"packet_workstream": workstream, "packet_path": packet_path,
                "kind": row.get("kind"), "packet_status": row.get("status"),
                "dispatch_class": row.get("actual_class")}
        if not workstream or not packet_path:
            invalid.append({**item, "classification": "INVALID_QUEUE_RECORD"})
            continue
        if workstream in identities:
            invalid.append({**item, "classification": "INVALID_QUEUE_RECORD", "reason": "duplicate active identity"})
            identities[workstream] = {"ambiguous": True}
        else:
            identities[workstream] = item
        if row.get("actual_class") == "invalid_recovery":
            invalid.append({**item, "classification": "INVALID_QUEUE_RECORD"})
    archive_root = repo / "custodian/docs/ai_context/task_packets/archived"
    for path in sorted(archive_root.glob("*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        workstream_match = re.search(r"(?m)^- Workstream:\s*`?([^`\s]+)", text)
        if not workstream_match:
            continue
        workstream = workstream_match.group(1)
        if workstream in identities:
            continue
        status_match = re.search(r"(?m)^- Status:\s*`?([^`\s]+)", text)
        kind_match = re.search(r"(?m)^- Kind:\s*`?([^`\s]+)", text)
        identities[workstream] = {"packet_workstream": workstream,
                                  "packet_path": str(path.relative_to(repo)),
                                  "kind": kind_match.group(1) if kind_match else None,
                                  "packet_status": status_match.group(1) if status_match else "unknown",
                                  "dispatch_class": "archived", "archived": True,
                                  "review_outcome": "not established by packet status alone"}
    return identities, invalid


def census(repo: Path) -> dict:
    repo = repo.resolve(strict=True)
    top = Path(git_text(["rev-parse", "--show-toplevel"], repo)).resolve(strict=True)
    if top != repo:
        raise CensusError(f"repo must be the coordination checkout root: {top}")
    main_sha = git_text(["rev-parse", "refs/remotes/origin/main"], repo)
    # The dispatcher's own audit is authoritative for queue eligibility. It may
    # refresh origin tracking refs, as documented by dispatch.py audit.
    audit_process = subprocess.run([sys.executable, str(repo / "custodian/tools/agent/dispatch.py"), "audit", "--json"],
                                   cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if audit_process.returncode:
        raise CensusError("dispatch.py audit --json failed: " + audit_process.stderr.decode("utf-8", "replace").strip())
    try:
        audit = json.loads(audit_process.stdout)
    except json.JSONDecodeError as error:
        raise CensusError(f"dispatcher audit returned malformed JSON: {error}") from error
    if audit.get("schema") != "custodian.task_packet_queue_audit.v1":
        raise CensusError("unexpected dispatcher audit schema")
    packets, invalid = packet_index(repo, audit)
    trace_process = subprocess.run([sys.executable, str(repo / "custodian/tools/agent/run_trace.py"), "list"],
                                   cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    traces: dict[str, str] = {}
    if trace_process.returncode == 0:
        try:
            for trace in json.loads(trace_process.stdout):
                workstream = trace.get("workstream")
                if workstream and (workstream not in traces or trace.get("run_id", "") > traces[workstream]):
                    traces[workstream] = trace.get("run_id")
        except (json.JSONDecodeError, TypeError):
            traces = {}
    rows = []
    for identity in parse_worktrees(run(["worktree", "list", "--porcelain"], repo)):
        path = Path(str(identity["worktree_path"]))
        row = {key: identity.get(key) for key in ("worktree_path", "HEAD", "branch", "detached", "locked", "prunable")}
        row["worktree_porcelain_identity"] = str(identity.get("branch") or ("detached:" + str(identity["HEAD"])))
        row["attached_HEAD"] = identity["HEAD"]
        row["main_SHA"] = main_sha
        row["packet_workstream"] = None
        row["packet_path"] = None
        row["kind"] = None
        row["packet_status"] = None
        row["archived_packet"] = False
        row["dispatch_class"] = None
        row["claim_ref"] = None
        row["claim_sha"] = None
        row["remote_agent_branch_sha"] = None
        row["merge_base"] = None
        row["ahead_count"] = None
        row["behind_count"] = None
        row["staged_count"] = row["unstaged_count"] = row["untracked_count"] = None
        row["dirtiness_fingerprint_or_blocker"] = None
        row["unique_commits_proven"] = False
        row["execution_process_provenance"] = "UNKNOWN; no supervisor evidence inferred"
        row["last_run_id"] = None
        row["review_outcome"] = None
        row["reviewer_receipt_provenance"] = None
        row["protected_user_files"] = "uninspected; no file contents read"
        row["preservation_receipt"] = None
        row["next_workstream"] = None
        branch = str(identity.get("branch", ""))
        workstream = branch.removeprefix("refs/heads/agent/") if branch.startswith("refs/heads/agent/") else None
        row["packet_workstream"] = workstream
        row["last_run_id"] = traces.get(workstream)
        packet = packets.get(workstream) if workstream else None
        if packet:
            row.update({key: packet.get(source) for key, source in (("packet_path", "packet_path"), ("kind", "kind"),
                                                                    ("packet_status", "packet_status"), ("dispatch_class", "dispatch_class"))})
            row["archived_packet"] = bool(packet.get("archived"))
            row["review_outcome"] = packet.get("review_outcome")
            row["next_workstream"] = packet.get("paired_review_workstream") if packet.get("kind") == "implementation" else None
        try:
            if not path.is_dir():
                raise CensusError("worktree path missing")
            status = run(["-C", str(path), "status", "--porcelain=v2", "-z", "--untracked-files=all"], repo)
            row["staged_count"], row["unstaged_count"], row["untracked_count"], row["dirtiness_fingerprint_or_blocker"] = status_counts(status)
            branch_ref = branch if branch else str(identity["HEAD"])
            merge = subprocess.run(["git", "-C", str(path), "merge-base", "origin/main", "HEAD"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if merge.returncode == 0:
                row["merge_base"] = merge.stdout.decode().strip()
            elif merge.returncode != 1:
                raise CensusError("merge-base failed")
            counts = subprocess.run(["git", "-C", str(path), "rev-list", "--left-right", "--count", "origin/main...HEAD"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if counts.returncode:
                raise CensusError("rev-list ancestry check failed")
            values = counts.stdout.decode().split()
            if len(values) != 2:
                raise CensusError("malformed rev-list count")
            row["behind_count"], row["ahead_count"] = map(int, values)
            row["unique_commits_proven"] = row["ahead_count"] > 0
            if workstream:
                row["claim_ref"] = f"refs/heads/dispatch-claims/{workstream}" if any(c.get("workstream") == workstream for c in audit.get("remote_dispatch_claims", [])) else None
                claim = next((c for c in audit.get("remote_dispatch_claims", []) if c.get("workstream") == workstream), None)
                row["claim_sha"] = claim.get("head") if claim else None
                remote = next((b for b in audit.get("remote_agent_branches", []) if b.get("workstream") == workstream and b.get("remote_branch_exists")), None)
                row["remote_agent_branch_sha"] = remote.get("head") if remote else None
            dirty = row["staged_count"] + row["unstaged_count"] + row["untracked_count"] > 0
            if packet and packet.get("ambiguous"):
                classification, action = "UNKNOWN_PROTECT", "preserve; resolve duplicate packet identity"
            elif packet and packet.get("archived"):
                classification, action = "ARCHIVED_RESIDUE_CANDIDATE", "preserve; archive completion alone does not authorize retirement"
            elif packet and packet.get("dispatch_class") == "invalid_recovery":
                classification, action = "INVALID_QUEUE_RECORD", "preserve; bounded queue triage required"
            elif identity.get("detached"):
                classification, action = "DETACHED_SUPPORT_PRESERVE", "preserve; no retirement in census"
            elif packet and dirty:
                classification, action = "DIRTY_OR_UNIQUE_PRESERVE_FIRST", "preserve dirty bytes and history"
            elif packet and packet.get("kind") == "review":
                classification, action = "BLOCKED_REVIEW_DISPOSITION", "preserve review evidence and disposition"
            elif packet:
                classification, action = "ACTIVE_PROTECT", "preserve active claim; no mutation"
            else:
                classification, action = "UNKNOWN_PROTECT", "preserve; identity unresolved"
            row["classification"], row["action"] = classification, action
            row["authority"] = "W1 read-only census; later action requires its own packet and lifecycle"
            row["approval_required"] = True
        except (OSError, CensusError) as error:
            row["classification"] = "UNKNOWN_PROTECT"
            row["action"] = "preserve; census evidence incomplete"
            row["authority"] = "W1 fail-closed ambiguity"
            row["approval_required"] = True
            row["dirtiness_fingerprint_or_blocker"] = f"BLOCKED: {error}"
        rows.append(row)
    claim_only = [claim for claim in audit.get("remote_dispatch_claims", []) if not claim.get("agent_branch_exists")]
    return {"schema": SCHEMA, "captured_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "coordination_repo": str(repo), "origin_main_sha": main_sha,
            "dispatcher_audit": {key: audit.get(key) for key in ("schema", "raw_active_markdown_count", "managed_packet_count", "claimable_auto_count", "class_counts", "interrupted_dispatch_claim_count", "claim_only_orphan_dispatch_claim_count")},
            "worktree_count": len(rows), "worktrees": rows, "invalid_queue_records": invalid,
            "claim_only_or_interrupted_claims": claim_only,
            "reported_baselines": {"unfinished_attached": 36, "dirty": 17, "clean": 19, "named_dirty": 17, "named_clean": 18,
                                   "unique_ahead_heads": 10, "archived_residue": 2, "detached": 11, "invalid_recovery": 65, "claim_only": 2}}


def markdown(report: dict) -> str:
    audit = report["dispatcher_audit"]
    out = ["# Read-only worktree backlog census", "", f"- Schema: `{report['schema']}`",
           f"- Captured UTC: `{report['captured_at_utc']}`", f"- Coordination checkout: `{report['coordination_repo']}`", f"- origin/main: `{report['origin_main_sha']}`",
           f"- Captured worktree rows: {report['worktree_count']}",
           f"- Dispatcher active/managed: {audit['raw_active_markdown_count']}/{audit['managed_packet_count']}",
           f"- Dispatcher classes: `{json.dumps(audit['class_counts'], sort_keys=True)}`", "",
           "Paths and file names from dirty status are excluded; each fingerprint hashes the exact NUL-delimited porcelain bytes.", "",
           "| Worktree | Workstream | HEAD | Ahead/behind | Dirty counts S/U/? | Classification | Action |", "|---|---|---|---:|---:|---|---|"]
    for row in report["worktrees"]:
        counts = f"{row.get('staged_count')}/{row.get('unstaged_count')}/{row.get('untracked_count')}"
        ahead_behind = f"{row.get('ahead_count')}/{row.get('behind_count')}"
        out.append(f"| `{row['worktree_path']}` | `{row.get('packet_workstream') or 'detached/unknown'}` | `{row['attached_HEAD']}` | {ahead_behind} | {counts} | `{row['classification']}` | {row['action']} |")
    out.extend(["", "## Queue and interrupted claim counts", "", f"- Invalid queue records: {len(report['invalid_queue_records'])}",
                f"- Claim-only/interrupted refs: {len(report['claim_only_or_interrupted_claims'])}",
                "- Process ownership: unknown unless separate supervised provenance exists; a missing PID or old checkout is not proof of exit.",
                "- Census actions: none. All rows remain protected pending their own authorized lifecycle.", ""])
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="clean CUSTODIAN coordination checkout")
    parser.add_argument("--json", action="store_true", help="emit normalized JSON")
    args = parser.parse_args()
    try:
        report = census(args.repo)
        print(json.dumps(report, indent=2, sort_keys=True) if args.json else markdown(report), end="\n")
        return 0
    except (CensusError, OSError) as error:
        print(f"worktree_backlog_census: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
