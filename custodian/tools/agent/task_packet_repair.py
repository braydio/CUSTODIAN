#!/usr/bin/env python3
"""Preview/apply the evidence-backed queue metadata repairs in reconciliation v1.

This deliberately narrow migration only normalizes five named packet headers.
It never changes status/dispatch/dependencies, indexes, archive locations,
branches, claims, or packet body acceptance. Every transformation checks the
stable workstream identity and exact expected old value before changing bytes.
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
import hashlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from task_packet_contract import PACKET_ROOT, header_field, parse_packet


class RepairError(RuntimeError):
    pass


MODE_IDS = (
    "vehicle-diagnosis-knowledge-v1",
    "review-vehicle-diagnosis-knowledge-v1",
    "vehicle-part-fabrication-recovery-v1",
    "review-vehicle-part-fabrication-recovery-v1",
)
VISUAL_ID = "sundered-keep-overlook-alternate-vertical-slice"
CANONICAL_MODES = "code, architecture, runtime"
HEADER_RENAMES = {
    "procgen-alpine-cliff-presentation-v1": ("PROCGEN_ALPINE_CLIFF_PRESENTATION_V1.md", "Reviewed base", "Reviewed main"),
    "procgen-alpine-surface-plates-v1": ("PROCGEN_ALPINE_SURFACE_PLATES_V1.md", "Reviewed base", "Reviewed main"),
    "vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1": (
        "VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1_REVIEW_CORRECTIONS_1.md",
        "Current defect/evidence", "Current measured state",
    ),
}
ARCHIVE_START = "<!-- legacy_completed_archive:start -->"
ARCHIVE_END = "<!-- legacy_completed_archive:end -->"


def _mode_path(workstream: str) -> str:
    return {
        "vehicle-diagnosis-knowledge-v1": "VEHICLE_DIAGNOSIS_KNOWLEDGE_V1.md",
        "review-vehicle-diagnosis-knowledge-v1": "REVIEW_VEHICLE_DIAGNOSIS_KNOWLEDGE_V1.md",
        "vehicle-part-fabrication-recovery-v1": "VEHICLE_PART_FABRICATION_RECOVERY_V1.md",
        "review-vehicle-part-fabrication-recovery-v1": "REVIEW_VEHICLE_PART_FABRICATION_RECOVERY_V1.md",
    }[workstream]


def _transform(workstream: str, text: str) -> tuple[str, str]:
    packet = parse_packet("candidate", text)
    if packet.workstream != workstream:
        raise RepairError(f"expected {workstream}, found {packet.workstream or 'no valid identity'}")
    if workstream in MODE_IDS:
        old = "code, architecture, runtime, persistence"
        if packet.review_modes == tuple(CANONICAL_MODES.split(", ")):
            return text, "already canonical"
        if packet.review_modes != tuple(old.split(", ")):
            raise RepairError(f"{workstream}: Review modes changed; expected {old!r}, found {packet.review_modes!r}")
        pattern = re.compile(r"(?m)^(- Review modes: `)code, architecture, runtime, persistence(`\s*)$")
        updated, count = pattern.subn(rf"\g<1>{CANONICAL_MODES}\2", text, count=1)
        if count != 1:
            raise RepairError(f"{workstream}: exact Review modes header was not found")
        return updated, f"Review modes: {old} -> {CANONICAL_MODES}"

    if workstream in HEADER_RENAMES:
        _filename, old_field, new_field = HEADER_RENAMES[workstream]
        if header_field(text, new_field):
            return text, f"already named {new_field}"
        old_value = header_field(text, old_field)
        if not old_value:
            raise RepairError(f"{workstream}: expected non-empty {old_field} field")
        pattern = re.compile(rf"(?m)^(- {re.escape(old_field)}:)\s*(.*)$")
        updated, count = pattern.subn(rf"- {new_field}: \2", text, count=1)
        if count != 1:
            raise RepairError(f"{workstream}: exact {old_field} header was not found")
        return updated, f"rename {old_field} -> {new_field}; preserve value"

    if workstream == VISUAL_ID:
        if packet.visual_review == "required":
            return text, "already required"
        match = re.search(r"(?m)^- Visual review: (.+)$", text)
        if not match:
            raise RepairError(f"{workstream}: Visual review header was not found")
        instructions = match.group(1).strip().strip("`").strip()
        required_phrases = ("publish", "ask:", "approval")
        if not all(phrase in instructions.lower() for phrase in required_phrases):
            raise RepairError(f"{workstream}: human review instructions are not intact in the Visual review field")
        replacement = "- Visual review: required"
        updated = text[:match.start()] + replacement + text[match.end():]
        section = f"\n\n## Visual review plan\n\n{instructions}\n"
        anchor = re.search(r"(?m)^## Completion Truth\s*$", updated)
        if anchor:
            updated = updated[:anchor.start()].rstrip() + section + "\n" + updated[anchor.start():]
        else:
            updated = updated.rstrip() + section
        return updated, "Visual review instructions moved to body; header set to required"
    raise RepairError(f"no allowlisted repair for {workstream}")


def plan(repo: Path) -> list[dict[str, str]]:
    actions = []
    for workstream in (*MODE_IDS, *HEADER_RENAMES, VISUAL_ID):
        filename = (
            _mode_path(workstream) if workstream in MODE_IDS
            else HEADER_RENAMES[workstream][0] if workstream in HEADER_RENAMES
            else "SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md"
        )
        path = repo / PACKET_ROOT / filename
        if not path.is_file():
            raise RepairError(f"missing packet: {path}")
        before = path.read_text()
        after, change = _transform(workstream, before)
        fields = ("Review modes", "Visual review", "Reviewed base", "Reviewed main", "Current defect/evidence", "Current measured state")
        before_values = {field: header_field(before, field) for field in fields if header_field(before, field)}
        after_values = {field: header_field(after, field) for field in fields if header_field(after, field)}
        actions.append({
            "workstream": workstream, "path": path.relative_to(repo).as_posix(),
            "change": change, "changed": str(before != after).lower(),
            "before_sha256": hashlib.sha256(before.encode()).hexdigest(),
            "after_sha256": hashlib.sha256(after.encode()).hexdigest(),
            "before_values": before_values, "after_values": after_values,
        })
    return actions


def legacy_archive_plan(repo: Path) -> list[dict[str, str]]:
    """Select only legacy records with explicit non-empty completion receipts.

    All 24 selected files have a top-level Status: complete, no dispatcher
    identity/dispatch, and a non-empty Completed: field. Existing repository
    references or filename collisions fail closed.
    """
    active = repo / PACKET_ROOT
    archive = active / "archived"
    actions = []
    reference_after: dict[str, tuple[str, str]] = {}
    for path in sorted(active.glob("*.md")):
        if path.name == "README.md":
            continue
        text = path.read_text()
        packet = parse_packet(path.relative_to(repo).as_posix(), text)
        completed = header_field(text, "Completed")
        if packet.status != "complete" or packet.workstream or packet.dispatch_declared or not completed:
            continue
        target = archive / path.name
        if target.exists():
            raise RepairError(f"archive target already exists; preserve both records for manual review: {target.relative_to(repo)}")
        refs = subprocess_check(["git", "grep", "-l", "-F", path.name, "HEAD", "--", "."], repo)
        seen_files = set()
        for line in refs.splitlines():
            source_path = line.removeprefix("HEAD:")
            if source_path == path.relative_to(repo).as_posix() or source_path in seen_files:
                continue
            seen_files.add(source_path)
            # Captured Moment Forge/Repomix reports are historical evidence,
            # not routing authorities; never rewrite generated evidence blobs.
            if source_path.startswith("reports/"):
                continue
            ref_path = repo / source_path
            if source_path in reference_after:
                original_ref, before_ref = reference_after[source_path]
            else:
                original_ref = before_ref = ref_path.read_text()
            pattern = re.compile(rf"((?:custodian/)?docs/ai_context/task_packets/|(?:\.\./)*task_packets/|task_packets/){re.escape(path.name)}")
            after_ref = pattern.sub(rf"\1archived/{path.name}", before_ref)
            reference_after[source_path] = (original_ref, after_ref)
        actions.append({
            "kind": "archive", "path": path.relative_to(repo).as_posix(),
            "target": target.relative_to(repo).as_posix(),
            "workstream": "legacy-unkeyed", "changed": "true",
            "change": "move byte-for-byte completed legacy record; add README archive link",
            "content_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
    for source_path, (before_ref, after_ref) in sorted(reference_after.items()):
        if before_ref != after_ref:
            actions.append({
                "kind": "update_reference", "workstream": "legacy-unkeyed",
                "path": source_path, "changed": "true",
                "before_sha256": hashlib.sha256(before_ref.encode()).hexdigest(),
                "after_sha256": hashlib.sha256(after_ref.encode()).hexdigest(),
                "diff": "".join(difflib.unified_diff(before_ref.splitlines(keepends=True), after_ref.splitlines(keepends=True), fromfile=source_path, tofile=source_path)),
                "after": after_ref, "change": "update archived packet path reference",
            })
    return actions


def render_legacy_archive_section(repo: Path) -> str:
    rows = []
    for path in sorted((repo / PACKET_ROOT / "archived").glob("*.md")):
        text = path.read_text()
        packet = parse_packet(path.relative_to(repo).as_posix(), text)
        completed = header_field(text, "Completed")
        if packet.status != "complete" or packet.workstream or packet.dispatch_declared or not completed:
            continue
        title = next((line[2:].strip() for line in text.splitlines() if line.startswith("# ")), path.stem)
        short = completed if len(completed) <= 180 else completed[:177].rstrip() + "..."
        rows.append(f"- [`{path.name}`](archived/{path.name}) — {title}: {short}")
    return f"{ARCHIVE_START}\n" + ("\n".join(rows) if rows else "_None._") + f"\n{ARCHIVE_END}"


def legacy_archive_apply(repo: Path) -> list[dict[str, str]]:
    actions = legacy_archive_plan(repo)
    readme = repo / PACKET_ROOT / "README.md"
    text = readme.read_text()
    if not re.search(re.escape(ARCHIVE_START), text) and not re.search(r"(?m)^## Workflow\s*$", text):
        raise RepairError("README has no ## Workflow anchor for the legacy archive index")
    for item in actions:
        if item["kind"] == "update_reference":
            target = repo / item["path"]
            current = target.read_text()
            if hashlib.sha256(current.encode()).hexdigest() != item["before_sha256"]:
                raise RepairError(f"reference changed after preview; rerun plan: {item['path']}")
            target.write_text(item["after"])
    for item in actions:
        if item["kind"] != "archive":
            continue
        source = repo / item["path"]
        target = repo / item["target"]
        if hashlib.sha256(source.read_bytes()).hexdigest() != item["content_sha256"]:
            raise RepairError(f"packet changed after archive plan; rerun preview: {item['path']}")
        if target.exists():
            raise RepairError(f"archive target appeared after plan; preserve both records: {item['target']}")
        target.parent.mkdir(parents=True, exist_ok=True)
        source.rename(target)
    text = readme.read_text()
    section = render_legacy_archive_section(repo)
    pattern = re.compile(re.escape(ARCHIVE_START) + r"\n.*?\n" + re.escape(ARCHIVE_END), re.DOTALL)
    if pattern.search(text):
        updated = pattern.sub(lambda _match: section, text, count=1)
    else:
        anchor = re.search(r"(?m)^## Workflow\s*$", text)
        if not anchor:
            raise RepairError("README has no ## Workflow anchor for the legacy archive index")
        updated = text[:anchor.start()] + "## Legacy Completed Records\n\n" + section + "\n\n" + text[anchor.start():]
    if updated != text:
        readme.write_text(updated)
    return actions


def apply(repo: Path) -> list[dict[str, str]]:
    actions = []
    for item in plan(repo):
        path = repo / item["path"]
        before = path.read_text()
        if hashlib.sha256(before.encode()).hexdigest() != item["before_sha256"]:
            raise RepairError(f"packet changed after plan; rerun preview: {item['path']}")
        after, _change = _transform(item["workstream"], before)
        if hashlib.sha256(after.encode()).hexdigest() != item["after_sha256"]:
            raise RepairError(f"repair output changed after plan; rerun preview: {item['path']}")
        if after != before:
            path.write_text(after)
        actions.append(item)
    return actions


def subprocess_check(command: list[str], cwd: Path) -> str:
    import subprocess
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True)
    if result.returncode not in (0, 1):
        raise RepairError(f"git grep failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument("--json", action="store_true", dest="as_json")
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)
    try:
        repo = Path(subprocess_check_output(["git", "rev-parse", "--show-toplevel"], args.repo)).resolve()
        actions = apply(repo) if args.apply else plan(repo)
    except (RepairError, OSError, RuntimeError) as error:
        print(f"task_packet_repair: BLOCKED: {error}", file=sys.stderr)
        return 2
    if args.as_json:
        print(json.dumps({"schema": "custodian.task_packet_repair_plan.v1", "mode": "apply" if args.apply else "plan", "actions": actions}, indent=2, sort_keys=True))
    else:
        for item in actions:
            print(f"{'CHANGE' if item['changed'] == 'true' else 'NOOP'} {item['workstream']} [{item['path']}]: {item['change']}")
        print(f"task_packet_repair: {'applied' if args.apply else 'plan only'}; {sum(item['changed'] == 'true' for item in actions)} file(s) changed")
    return 0


def subprocess_check_output(command: list[str], cwd: Path) -> str:
    import subprocess
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        raise RepairError((result.stderr or result.stdout).strip())
    return result.stdout.strip()


if __name__ == "__main__":
    raise SystemExit(main())
