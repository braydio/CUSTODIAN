#!/usr/bin/env python3
"""Read-only validator for CUSTODIAN AI-context and task-packet coordination truth.

Absorbs the scope of the superseded `AI_CONTEXT_TASK_PACKET_VALIDATOR.md`
packet. Reuses `task_packet_contract.py` for all packet grammar rather than
duplicating it, and never mutates the repository or main. Catches
coordination-document drift (missing context, packet/index inconsistency,
malformed V2 contracts, missing completion receipts); it does not replace
semantic human review of packet content.

Deferred (see TASK_PACKET_PIPELINE_EXECUTION_HARDENING_V1.md Deferred): the
full `Kind: review`/`Kind: correction` structural finding-ID/disposition
contract is not validated here yet; only the checks enumerated in this
packet's own Acceptance/Focused Tests are implemented.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from task_packet_contract import (
    COMPLETION_TRUTH_REQUIRED_KINDS, PACKET_ROOT, V2_CORRECTION_REQUIRED_FIELDS,
    V2_REQUIRED_FIELDS, Packet, completion_truth_required, is_v2_packet,
    parse_completion_truth, parse_packet, v2_required_field_values,
    validate_queue_contract,
)

REQUIRED_CONTEXT_FILES = (
    "custodian/AGENTS.md",
    "custodian/docs/ai_context/CONTEXT.md",
    "custodian/docs/ai_context/CURRENT_STATE.md",
    "custodian/docs/ai_context/FILE_INDEX.md",
    "custodian/docs/ai_context/VALIDATION_RECIPES.md",
    "custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md",
    f"{PACKET_ROOT}/README.md",
    "custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md",
)

# A small, explicit manifest of tooling paths the AI-context docs depend on.
# Keep this intentionally bounded; do not grep every archived document.
AUTHORITY_PATHS = (
    "custodian/tools/agent/dispatch.py",
    "custodian/tools/agent/workstream.py",
    "custodian/tools/agent/workflow_control.py",
    "custodian/tools/agent/task_packet_contract.py",
    "custodian/tools/agent/validate_review_pairing.py",
    "custodian/tools/agent/land_main.py",
)

PLACEHOLDER_MARKERS = ("<lowercase-kebab-id>", "<short SHA>", "[TASK NAME]")

EXECUTION_FEEDBACK_SCHEMA = "custodian.task_feedback.v1"
_OUTCOME_VALUES = {"success", "partial", "blocked"}
_FRICTION_VALUES = {"none", "low", "medium", "high"}
EXECUTION_FEEDBACK_NON_EMPTY_FIELDS = (
    "What went wrong", "Root cause / contributing factors",
    "Prevention / pipeline improvement", "Tooling / docs drift discovered",
    "Follow-up",
)


class CheckError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise CheckError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


@dataclass(frozen=True)
class Finding:
    check: str
    path: str
    message: str


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)

    def add(self, check: str, path: str, message: str) -> None:
        self.findings.append(Finding(check, path, message))

    @property
    def ok(self) -> bool:
        return not self.findings

    def sorted_findings(self) -> list[Finding]:
        return sorted(self.findings, key=lambda f: (f.check, f.path, f.message))

    def to_json(self) -> dict:
        return {
            "schema": "custodian.ai_context_check.v1",
            "ok": self.ok,
            "finding_count": len(self.findings),
            "findings": [
                {"check": f.check, "path": f.path, "message": f.message}
                for f in self.sorted_findings()
            ],
        }


@dataclass(frozen=True)
class DiscoveredPacket:
    file_path: Path
    rel_path: str
    archived: bool
    text: str
    packet: Packet


def discover_packets(repo: Path) -> list[DiscoveredPacket]:
    active_root = repo / PACKET_ROOT
    archive_root = active_root / "archived"
    discovered: list[DiscoveredPacket] = []
    for root, archived in ((active_root, False), (archive_root, True)):
        if not root.is_dir():
            continue
        for md in sorted(root.glob("*.md")):
            if md.name == "README.md":
                continue
            text = md.read_text()
            rel = md.relative_to(repo).as_posix()
            discovered.append(DiscoveredPacket(md, rel, archived, text, parse_packet(rel, text)))
    return discovered


def check_required_context(repo: Path, report: Report) -> None:
    for rel in REQUIRED_CONTEXT_FILES:
        if not (repo / rel).is_file():
            report.add("required-context", rel, "required AI-context file is missing")


def check_authority_paths(repo: Path, report: Report) -> None:
    for rel in AUTHORITY_PATHS:
        if not (repo / rel).is_file():
            report.add("authority-path", rel, "authority path referenced by AI-context docs no longer exists")


def check_packet_grammar(packets: list[DiscoveredPacket], report: Report) -> None:
    """Flag malformed dispatcher metadata only for packets that actually
    declare a `Dispatch:` field. dispatch.py's own status rendering treats a
    packet with no declared Dispatch as inert MANUAL regardless of any other
    parse error (see _render_status), tolerating the many pre-dispatcher
    narrative docs that live under task_packets/ without ever adopting the
    Workstream/Status/Dispatch contract. Mirror that same tolerance here
    rather than flagging every historical document as broken.
    """
    for entry in packets:
        if not entry.archived and entry.packet.error and entry.packet.dispatch_declared:
            report.add("packet-grammar", entry.rel_path, entry.packet.error)


def check_packet_queue_contract(packets: list[DiscoveredPacket], report: Report) -> None:
    active = [entry for entry in packets if not entry.archived]
    archived = [entry for entry in packets if entry.archived]
    errors = validate_queue_contract(
        [entry.packet for entry in active], [entry.packet for entry in archived],
        {entry.rel_path: entry.text for entry in active},
    )
    paths_by_id: dict[str, list[str]] = {}
    for entry in active:
        if entry.packet.workstream:
            paths_by_id.setdefault(entry.packet.workstream, []).append(entry.rel_path)
    for workstream, message in errors.items():
        for path in paths_by_id.get(workstream, [workstream]):
            report.add("packet-queue", path, message)


_SHA_RE = re.compile(r"^[0-9a-f]{7,40}$")


def check_v2_contract(entry: DiscoveredPacket, report: Report) -> None:
    """Structural V2 field contract, current packets only.

    Archived packets are historical record. The template's exact field
    names evolve over time (e.g. correction packets moved from `Change` to
    `Required correction`); re-grading old archived packets against today's
    field names would retroactively invalidate settled history rather than
    catch real current drift.
    """
    if entry.archived:
        return
    if not is_v2_packet(entry.packet):
        return
    if entry.packet.kind not in COMPLETION_TRUTH_REQUIRED_KINDS:
        return  # review packets use AGENT_REVIEW_PACKET_TEMPLATE.md's distinct field contract
    if entry.packet.status not in {"ready", "in_progress", "complete"}:
        return  # blocked/draft packets may remain incomplete until their gate clears
    required_fields = V2_CORRECTION_REQUIRED_FIELDS if entry.packet.kind == "correction" else V2_REQUIRED_FIELDS
    values = v2_required_field_values(entry.text, required_fields)
    for field_name in required_fields:
        if not values.get(field_name):
            report.add("v2-required-field", entry.rel_path, f"missing or empty required V2 field: {field_name}")
    reviewed_main = values.get("Reviewed main")
    if reviewed_main and not _SHA_RE.match(reviewed_main.strip("`")):
        report.add("v2-required-field", entry.rel_path, f"Reviewed main is not SHA-like: {reviewed_main!r}")
    if entry.packet.status == "ready":
        for marker in PLACEHOLDER_MARKERS:
            if marker in entry.text:
                report.add("v2-placeholder", entry.rel_path, f"ready V2 packet still contains template placeholder {marker!r}")


def _receipt_section(text: str, heading: str) -> str | None:
    match = re.search(rf"(?ms)^## {re.escape(heading)}\s*\n(.*?)(?=^## |\Z)", text)
    return match.group(1) if match else None


def _receipt_field(body: str, name: str) -> str | None:
    match = re.search(rf"^\s*-\s*{re.escape(name)}:\s*(.*?)\s*$", body, re.MULTILINE)
    if not match:
        return None
    return match.group(1).strip().strip("`").strip() or None


def check_completion_truth(entry: DiscoveredPacket, report: Report) -> None:
    """Structural Completion Truth check for a packet still on its way to
    archival. Never retroactive: once a packet is already sitting in
    archived/, it is historical settled state (exactly the packets
    workstream.py's finish-time gate never re-litigates either), so this
    does not flag it just because it predates the receipt's introduction.
    """
    if entry.archived:
        return
    if not completion_truth_required(entry.packet):
        return
    if entry.packet.status != "complete":
        return
    truth = parse_completion_truth(entry.text)
    if truth is None:
        report.add("completion-truth", entry.rel_path, "Status: complete but ## Completion Truth receipt is missing")
        return
    if truth.error:
        report.add("completion-truth", entry.rel_path, f"malformed ## Completion Truth receipt: {truth.error}")
        return
    if not truth.all_yes:
        report.add(
            "completion-truth",
            entry.rel_path,
            "Status: complete but ## Completion Truth receipt declares Goal/Completion boundary/Acceptance not all satisfied",
        )


def check_execution_feedback(entry: DiscoveredPacket, report: Report) -> None:
    # Archived packets are durable history; only active packets are held to
    # the current receipt schema (matching the other packet contract checks).
    if entry.archived:
        return
    if not is_v2_packet(entry.packet) or entry.packet.status != "complete":
        return
    body = _receipt_section(entry.text, "Execution Feedback")
    if body is None:
        report.add("execution-feedback", entry.rel_path, "Status: complete V2 packet is missing ## Execution Feedback")
        return
    schema = _receipt_field(body, "Feedback schema")
    if schema != EXECUTION_FEEDBACK_SCHEMA:
        report.add("execution-feedback", entry.rel_path, f"Feedback schema must be {EXECUTION_FEEDBACK_SCHEMA!r}")
    outcome = _receipt_field(body, "Outcome")
    if outcome not in _OUTCOME_VALUES:
        report.add("execution-feedback", entry.rel_path, "Outcome must be success, partial, or blocked")
    friction = _receipt_field(body, "Friction severity")
    if friction not in _FRICTION_VALUES:
        report.add("execution-feedback", entry.rel_path, "Friction severity must be none, low, medium, or high")
    for name in EXECUTION_FEEDBACK_NON_EMPTY_FIELDS:
        if not _receipt_field(body, name):
            report.add("execution-feedback", entry.rel_path, f"{name} must be non-empty (use 'none' when nothing occurred)")


_README_SUBSECTION_RE = re.compile(r"(?ms)^### (.+?)\s*\n(.*?)(?=^### |^## |\Z)")
_README_BULLET_RE = re.compile(r"^-\s*`([A-Z0-9_]+\.md)`", re.MULTILINE)


def check_readme_index(repo: Path, packets: list[DiscoveredPacket], report: Report) -> None:
    readme_path = repo / PACKET_ROOT / "README.md"
    if not readme_path.is_file():
        return  # already reported by check_required_context
    text = readme_path.read_text()
    active_match = re.search(r"(?ms)^## Active Packets\s*\n(.*)", text)
    if not active_match:
        report.add("readme-index", f"{PACKET_ROOT}/README.md", "missing ## Active Packets section")
        return
    active_section = active_match.group(1)

    by_name: dict[str, DiscoveredPacket] = {entry.file_path.name: entry for entry in packets}
    archived_names = {entry.file_path.name for entry in packets if entry.archived}
    active_names = {entry.file_path.name for entry in packets if not entry.archived}

    for heading, body in _README_SUBSECTION_RE.findall(active_section + "\n### __end__\n"):
        names = _README_BULLET_RE.findall(body)
        seen_in_subsection: set[str] = set()
        for name in names:
            if name in seen_in_subsection:
                report.add("readme-index", name, f"duplicate entry within README section '{heading}'")
            seen_in_subsection.add(name)

            if name not in active_names and name not in archived_names:
                report.add("readme-index", name, f"README section '{heading}' indexes a packet file that does not exist")
                continue
            if name in archived_names and name not in active_names:
                report.add("readme-index", name, f"README section '{heading}' indexes an archived packet as active")
                continue

            entry = by_name[name]
            if heading.strip() == "Ready / Auto Dispatch":
                if entry.packet.status != "ready" or entry.packet.dispatch != "auto":
                    report.add(
                        "readme-index", name,
                        f"listed under Ready / Auto Dispatch but packet declares Status={entry.packet.status!r} Dispatch={entry.packet.dispatch!r}",
                    )
            elif heading.strip() == "In Progress":
                if entry.packet.status in (None, "complete"):
                    report.add(
                        "readme-index", name,
                        f"listed under In Progress but packet declares Status={entry.packet.status!r}",
                    )


def run_checks(repo: Path) -> Report:
    report = Report()
    check_required_context(repo, report)
    check_authority_paths(repo, report)
    packets = discover_packets(repo)
    check_packet_grammar(packets, report)
    check_packet_queue_contract(packets, report)
    for entry in packets:
        check_v2_contract(entry, report)
        check_completion_truth(entry, report)
        check_execution_feedback(entry, report)
    check_readme_index(repo, packets, report)
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--repo", type=Path, default=None)
    args = parser.parse_args(argv)
    try:
        repo = (args.repo or Path(git(Path.cwd(), "rev-parse", "--show-toplevel"))).resolve()
        report = run_checks(repo)
    except CheckError as error:
        print(f"check_ai_context: BLOCKED: {error}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(report.to_json(), indent=2, sort_keys=True))
    else:
        if report.ok:
            print("check_ai_context: PASS")
        else:
            print(f"check_ai_context: FAIL ({len(report.findings)} finding(s))")
            for f in report.sorted_findings():
                print(f"  [{f.check}] {f.path}: {f.message}")
    return 0 if report.ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
