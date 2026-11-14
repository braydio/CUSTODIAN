#!/usr/bin/env python3
"""Read-only deterministic inventory of CUSTODIAN process-feedback receipts."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from task_packet_contract import PACKET_ROOT, parse_packet

SCHEMA = "custodian.task_feedback.v1"
FIELDS = (
    "Feedback schema", "Outcome", "Friction severity", "What went wrong",
    "Root cause / contributing factors", "Prevention / pipeline improvement",
    "Tooling / docs drift discovered", "Follow-up", "What worked",
)
SECTION_HEADINGS = {"Process Feedback", "Execution Feedback"}
FENCE_RE = re.compile(r"(?m)^\s*(`{3,}|~{3,}).*$")
HEADING_RE = re.compile(r"(?m)^##\s+(.+?)\s*$")
FIELD_RE = re.compile(r"^\s*[-*]\s*([^:]+):\s*(.*?)\s*$")


def mask_fences(text: str) -> str:
    lines = text.splitlines(keepends=True)
    out, fence, char, width = [], False, "", 0
    for line in lines:
        match = FENCE_RE.match(line)
        if match:
            marker = match.group(1)
            if not fence:
                fence, char, width = True, marker[0], len(marker)
            elif marker[0] == char and len(marker) >= width:
                fence = False
            out.append("\n" if line.endswith("\n") else "")
        else:
            out.append("\n" if fence and line.endswith("\n") else "" if fence else line)
    return "".join(out)


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "`":
        return value[1:-1].strip()
    return value


def feedback_section(text: str) -> tuple[str | None, dict[str, str]]:
    clean = mask_fences(text)
    matches = list(HEADING_RE.finditer(clean))
    sections = []
    for i, match in enumerate(matches):
        title = match.group(1).strip().strip("#").strip()
        if title not in SECTION_HEADINGS:
            continue
        end = matches[i + 1].start() if i + 1 < len(matches) else len(clean)
        sections.append((title, clean[match.end():end]))
    if not sections:
        return None, {}
    title, body = sections[0]
    fields: dict[str, str] = {}
    current = None
    for line in body.splitlines():
        match = FIELD_RE.match(line)
        if match:
            key = match.group(1).strip()
            if key in FIELDS and key not in fields:
                current = key
                fields[key] = unquote(match.group(2))
            else:
                current = None
        elif current and line.startswith(("  ", "\t")) and line.strip():
            fields[current] += " " + line.strip()
    return title, fields


def summary_workstream(text: str) -> str | None:
    masked = mask_fences(text)
    preamble = re.split(r"(?m)^##\s+", masked, maxsplit=1)[0]
    for line in preamble.splitlines():
        m = re.match(r"^\s*(?:[-*]\s*)?Workstream:\s*`?([a-z0-9]+(?:-[a-z0-9]+)*)`?\s*$", line)
        if m:
            return m.group(1)
    return None


def classify_followup(value: str | None, known_workstreams: set[str] | None = None) -> str:
    if not value:
        return "missing"
    normalized = value.strip().strip("` ").lower()
    if normalized == "none":
        return "none"
    if normalized == "fixed-in-scope":
        return "author-reported-in-scope"
    if normalized == "manual-follow-up":
        return "unowned"
    if re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", normalized) and (known_workstreams is None or normalized in known_workstreams):
        return "linked-workstream"
    return "unclassified"


def discover(repo: Path) -> list[dict]:
    sources: list[tuple[Path, str, str, str | None]] = []
    for path in sorted(repo.glob("*_CLAUDE_SUMMARY.md")):
        text = path.read_text(encoding="utf-8")
        sources.append((path, "summary", "", summary_workstream(text)))
    packet_root = repo / PACKET_ROOT
    packet_paths = sorted(packet_root.glob("*.md")) + sorted((packet_root / "archived").glob("*.md"))
    for path in packet_paths:
        if path.name == "README.md":
            continue
        text = path.read_text(encoding="utf-8")
        packet = parse_packet(path.relative_to(repo).as_posix(), text)
        sources.append((path, "packet", packet.schema or "", packet.workstream))
    known_workstreams = {workstream for _path, source_type, _schema, workstream in sources
                         if source_type == "packet" and workstream}
    observations = []
    for path, source_type, schema, workstream in sources:
        text = path.read_text(encoding="utf-8")
        section, fields = feedback_section(text)
        status = "missing" if section is None else "complete" if all(k in fields for k in FIELDS if k != "What worked") else "partial"
        if section is not None and not fields:
            status = "unparsed"
        observations.append({
            "source": path.relative_to(repo).as_posix(), "source_type": source_type,
            "section": section, "schema": fields.get("Feedback schema", schema or None),
            "workstream": workstream, "receipt_status": status,
            "fields": {k: fields[k] for k in FIELDS if k in fields},
            "missing_fields": [k for k in FIELDS if k != "What worked" and k not in fields] if section else list(FIELDS),
            "follow_up_class": classify_followup(fields.get("Follow-up"), known_workstreams),
            "outcome_class": fields.get("Outcome", "").lower() if fields.get("Outcome", "").lower() in {"success", "partial", "blocked"} else "unclassified",
            "friction_class": fields.get("Friction severity", "").lower() if fields.get("Friction severity", "").lower() in {"none", "low", "medium", "high"} else "unclassified",
            "provenance": "explicit-workstream" if workstream else "identity-unknown",
        })
    observations.sort(key=lambda o: o["source"])
    return observations


def build_report(repo: Path) -> dict:
    observations = discover(repo)
    grouped: dict[str, list[dict]] = {}
    for item in observations:
        if item["workstream"]:
            grouped.setdefault(item["workstream"], []).append(item)
    mirrors, ambiguous = [], []
    for workstream, items in sorted(grouped.items()):
        packets = [x for x in items if x["source_type"] == "packet"]
        summaries = [x for x in items if x["source_type"] == "summary"]
        if len(packets) == len(summaries) == 1:
            mirrors.append({"workstream": workstream, "packet": packets[0]["source"], "summary": summaries[0]["source"],
                            "status": "identity-linked", "field_agreement": packets[0]["fields"] == summaries[0]["fields"]})
        elif len(items) > 1 and packets and summaries:
            ambiguous.append({"workstream": workstream, "sources": [x["source"] for x in items], "reason": "non-unique mirror candidates"})
    mirrored_sources = {source for mirror in mirrors for source in (mirror["packet"], mirror["summary"])}
    logical = []
    for mirror in mirrors:
        packet = next(x for x in observations if x["source"] == mirror["packet"])
        summary = next(x for x in observations if x["source"] == mirror["summary"])
        logical.append({"workstream": mirror["workstream"], "sources": [packet["source"], summary["source"]],
                        "receipt_status": packet["receipt_status"] if mirror["field_agreement"] else "conflicting-mirror",
                        "fields": packet["fields"] if mirror["field_agreement"] else {},
                        "follow_up_class": packet["follow_up_class"] if mirror["field_agreement"] else "unclassified"})
    logical.extend({"workstream": x["workstream"], "sources": [x["source"]], "receipt_status": x["receipt_status"],
                    "fields": x["fields"], "follow_up_class": x["follow_up_class"]}
                   for x in observations if x["source"] not in mirrored_sources)
    logical.sort(key=lambda x: (x["workstream"] or "", x["sources"]))
    outcomes = Counter((x["fields"].get("Outcome", "").lower() if x["fields"].get("Outcome", "").lower() in {"success", "partial", "blocked"} else "unclassified") for x in logical)
    frictions = Counter((x["fields"].get("Friction severity", "").lower() if x["fields"].get("Friction severity", "").lower() in {"none", "low", "medium", "high"} else "unclassified") for x in logical)
    owners = Counter(x["follow_up_class"] for x in logical)
    report = {
        "schema": "custodian.process_feedback_ledger.v1",
        "repo": ".",
        "sources": observations,
        "logical_receipts": logical,
        "mirrors": mirrors,
        "ambiguous_identity_groups": ambiguous,
        "metrics": {
            "source_count": len(observations), "logical_receipt_count": len(logical),
            "summary_count": sum(x["source_type"] == "summary" for x in observations),
            "packet_count": sum(x["source_type"] == "packet" for x in observations),
            "mirror_pair_count": len(mirrors), "ambiguous_identity_group_count": len(ambiguous),
            "receipt_status": dict(sorted(Counter(x["receipt_status"] for x in logical).items())),
            "outcomes": dict(sorted(outcomes.items())), "friction": dict(sorted(frictions.items())),
            "follow_up_ownership": dict(sorted(owners.items())),
            "unowned_medium_high": sum(x["follow_up_class"] == "unowned" and x["fields"].get("Friction severity", "").lower() in {"medium", "high"} for x in logical),
        },
    }
    return report


def render_markdown(report: dict) -> str:
    m = report["metrics"]
    lines = ["# CUSTODIAN Process Feedback Ledger", "", f"Sources: {m['source_count']} ({m['summary_count']} summaries, {m['packet_count']} packets).", "",
             f"Identity-linked mirrors: {m['mirror_pair_count']}; ambiguous groups: {m['ambiguous_identity_group_count']}.",
             f"Unowned medium/high follow-ups: {m['unowned_medium_high']}", "", "## Receipt status", "",
             "| Status | Count |", "|---|---:|"]
    lines.extend(f"| {k} | {v} |" for k, v in m["receipt_status"].items())
    lines += ["", "## Sources", "", "| Source | Workstream | Status | Outcome | Friction | Follow-up ownership |", "|---|---|---|---|---|---|"]
    def cell(value: str) -> str:
        return value.replace("|", "\\|").replace("\n", " ").replace("\r", " ")
    for x in report["sources"]:
        f = x["fields"]
        lines.append(f"| `{cell(x['source'])}` | `{cell(x['workstream'] or 'unknown')}` | {cell(x['receipt_status'])} | {cell(f.get('Outcome', 'missing'))} | {cell(f.get('Friction severity', 'missing'))} | {cell(x['follow_up_class'])} |")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="command", required=True)
    scan = sub.add_parser("scan"); scan.add_argument("--json", action="store_true")
    md = sub.add_parser("report"); md.add_argument("--markdown", action="store_true")
    for cmd in (scan, md): cmd.add_argument("--repo", type=Path, default=None)
    args = p.parse_args(argv)
    repo = (args.repo or Path(__file__).resolve().parents[3]).resolve()
    report = build_report(repo)
    if args.command == "scan": print(json.dumps(report, sort_keys=True, indent=2, ensure_ascii=False))
    else: print(render_markdown(report), end="")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
