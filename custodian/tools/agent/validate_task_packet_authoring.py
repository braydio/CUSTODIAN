#!/usr/bin/env python3
"""Targeted preflight for newly authored or materially refreshed task packets.

This is deliberately narrower than check_ai_context.py / validate_review_pairing.py:
it validates only the packet paths named by the author plus the paired-review
relationship they participate in. Unrelated active-packet drift must not prevent
an author from proving that the packets they are about to mark ready are valid.

All grammar and pairing semantics come from task_packet_contract.py. This file
must never grow a second packet schema.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from task_packet_contract import (
    PACKET_ROOT,
    REVIEW_MODES,
    V2_CORRECTION_REQUIRED_FIELDS,
    V2_REVIEW_REQUIRED_FIELDS,
    V2_REQUIRED_FIELDS,
    is_v2_packet,
    header_field,
    parse_packet,
    validate_review_pairing,
)

AUTO_IMPLEMENTATION_REQUIRED = (
    "Review stage",
    "Review modes",
    "Paired review workstream",
    "Review cycle",
    "Max automatic review cycles",
)
REVIEW_PACKET_REQUIRED = V2_REVIEW_REQUIRED_FIELDS
REVIEWER_PROVENANCE = {"different-agent", "same-agent-fresh-context"}


class AuthoringPreflightError(RuntimeError):
    pass


def _git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=repo, text=True, capture_output=True
    )
    if result.returncode:
        raise AuthoringPreflightError(
            f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}"
        )
    return result.stdout.strip()


def _repo_root(start: Path) -> Path:
    return Path(_git(start, "rev-parse", "--show-toplevel")).resolve()


def _normalize_target(repo: Path, raw: str | Path) -> tuple[str, Path]:
    path = Path(raw)
    if not path.is_absolute():
        path = repo / path
    path = path.resolve()
    try:
        rel = path.relative_to(repo).as_posix()
    except ValueError as exc:
        raise AuthoringPreflightError(f"packet is outside repository: {path}") from exc
    active_root = f"{PACKET_ROOT}/"
    if not rel.startswith(active_root) or rel.startswith(f"{PACKET_ROOT}/archived/"):
        raise AuthoringPreflightError(
            f"authoring preflight accepts active task packets only: {rel}"
        )
    if path.parent != (repo / PACKET_ROOT).resolve() or path.suffix != ".md":
        raise AuthoringPreflightError(
            f"packet must be a top-level active Markdown task packet: {rel}"
        )
    if path.name == "README.md":
        raise AuthoringPreflightError("README.md is not a task packet")
    return rel, path


def _discover_active_packets(repo: Path):
    root = repo / PACKET_ROOT
    packets = []
    by_path = {}
    if not root.is_dir():
        return packets, by_path
    for path in sorted(root.glob("*.md")):
        if path.name == "README.md":
            continue
        rel = path.relative_to(repo).as_posix()
        packet = parse_packet(rel, path.read_text())
        packets.append(packet)
        by_path[rel] = packet
    return packets, by_path


def _missing_headers(text: str, fields: tuple[str, ...]) -> list[str]:
    return [field for field in fields if not header_field(text, field)]


def validate_authoring_paths(repo: Path, packet_paths: list[str | Path]) -> list[str]:
    """Return targeted schema/pairing findings for the supplied active packets."""
    active_packets, by_path = _discover_active_packets(repo)
    findings: list[str] = []
    related_workstreams: set[str] = set()

    for raw in packet_paths:
        try:
            rel, path = _normalize_target(repo, raw)
        except AuthoringPreflightError as error:
            findings.append(str(error))
            continue
        if not path.is_file():
            findings.append(f"{rel}: packet file does not exist")
            continue

        text = path.read_text()
        packet = parse_packet(rel, text)
        # Overlay the exact working-tree candidate so callers can run this before commit.
        by_path[rel] = packet
        active_packets = [p for p in active_packets if p.path != rel] + [packet]

        if packet.workstream:
            related_workstreams.add(packet.workstream)
        if packet.paired_review_workstream:
            related_workstreams.add(packet.paired_review_workstream)
        if packet.review_target_workstream:
            related_workstreams.add(packet.review_target_workstream)

        if packet.error:
            detail = packet.error
            if "Review modes" in detail:
                detail += (
                    "; allowed Review modes are "
                    + ", ".join(sorted(REVIEW_MODES))
                )
            findings.append(f"{rel}: {detail}")

        if is_v2_packet(packet) and packet.status == "ready" and packet.kind != "review":
            required = V2_CORRECTION_REQUIRED_FIELDS if packet.kind == "correction" else V2_REQUIRED_FIELDS
            missing = _missing_headers(text, required)
            if missing:
                findings.append(f"{rel}: ready V2 packet missing explicit " + ", ".join(missing))

        if packet.review == "auto":
            missing = _missing_headers(text, AUTO_IMPLEMENTATION_REQUIRED)
            if missing:
                findings.append(
                    f"{rel}: Review: auto authoring metadata missing explicit "
                    + ", ".join(missing)
                )

        if packet.kind == "review":
            missing = _missing_headers(text, REVIEW_PACKET_REQUIRED)
            if missing:
                findings.append(
                    f"{rel}: review packet missing explicit "
                    + ", ".join(missing)
                )
            reviewer_context = header_field(text, "Reviewer context")
            if reviewer_context and reviewer_context != "fresh":
                findings.append(f"{rel}: Reviewer context must be fresh")
            provenance = header_field(text, "Reviewer provenance")
            if provenance and provenance not in REVIEWER_PROVENANCE:
                findings.append(
                    f"{rel}: Reviewer provenance must be one of "
                    + ", ".join(sorted(REVIEWER_PROVENANCE))
                )

    pairing_errors = validate_review_pairing(active_packets)
    for workstream in sorted(related_workstreams):
        message = pairing_errors.get(workstream)
        if message:
            findings.append(f"{workstream}: {message}")

    # Stable de-duplication keeps CLI/test output deterministic.
    return list(dict.fromkeys(findings))



def print_promotion_handoff(repo: Path, packet_paths: list[str | Path]) -> None:
    """Show the publication boundary after PASS, without changing files or dispatch."""
    packets = []
    for raw in packet_paths:
        _, path = _normalize_target(repo, raw)
        packets.append(parse_packet(str(path), path.read_text()))

    if any(packet.status != "ready" for packet in packets):
        print("PROMOTION REQUIRED: PASS validates the supplied draft/blocked "
              "packet metadata, not approval to make it claimable.")
        print("  Resolve any human/design gates before setting the authorized "
              "implementation and paired review to Status: ready.")
        print("  Use Dispatch: auto unless the user explicitly requested a manual hold.")
    else:
        print("AUTHORING VALID: supplied packets declare Status: ready; "
              "remote publication and dispatch eligibility are NOT established.")

    print("NEXT (required before a newly authorized packet can be claimed):")
    print("  1. After any status/dispatch changes, rerun this targeted "
          "authoring preflight against the implementation AND paired review.")
    print("  2. python3 custodian/tools/agent/task_packet_index.py --write")
    print("     python3 custodian/tools/agent/task_packet_index.py")
    print("  3. Stage only the authorized packet(s) and the managed "
          "task_packets/README.md (plus explicitly scoped changes); "
          "commit and land them on origin/main through the safe repository workflow.")
    print("  4. git fetch origin; verify BOTH packet files and the managed "
          "ready/auto index exist on origin/main before claiming.")
    print("  5. Dispatcher reads origin/main, NOT your local checkout or unmerged "
          "authoring branch. Confirm dependency/review/lock eligibility, then claim.")

    implementation_ids = [
        packet.workstream for packet in packets
        if packet.kind != "review" and packet.workstream
    ]
    if implementation_ids:
        print("     python3 custodian/tools/agent/dispatch.py claim "
              f"{implementation_ids[0]} --agent <agent-id>")
    else:
        print("     python3 custodian/tools/agent/dispatch.py claim "
              "<implementation-workstream-id> --agent <agent-id>")
    print("     (Do not claim the paired post-land review before implementation "
          "lands and archives complete.)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packets", nargs="+", help="active task-packet paths to validate")
    parser.add_argument("--repo", type=Path, default=None)
    args = parser.parse_args(argv)

    try:
        repo = (args.repo.resolve() if args.repo else _repo_root(Path.cwd()))
        findings = validate_authoring_paths(repo, args.packets)
    except AuthoringPreflightError as error:
        print(f"task_packet_authoring_preflight: BLOCKED: {error}", file=sys.stderr)
        return 2

    if findings:
        print("task_packet_authoring_preflight: FAIL", file=sys.stderr)
        for finding in findings:
            print(f"- {finding}", file=sys.stderr)
        return 1

    rendered = ", ".join(str(path) for path in args.packets)
    print(f"task_packet_authoring_preflight: PASS: {rendered}")
    print_promotion_handoff(repo, args.packets)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
