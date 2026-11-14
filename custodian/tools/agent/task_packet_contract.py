#!/usr/bin/env python3
"""One reusable CUSTODIAN task-packet grammar/validation authority.

Extracted from `dispatch.py` so the dispatcher, `workstream.py` finish-time
completion-truth checks, `check_ai_context.py`, and `task_packet_index.py`
consume exactly one packet parser/validator rather than four competing
grammars. Keep this module free of live-repo side effects beyond the small
`git` helper `validate_packet_validation_references` needs; packet selection,
claiming, and worktree mutation remain `dispatch.py`/`workstream.py`
responsibilities.
"""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

PACKET_ROOT = "custodian/docs/ai_context/task_packets"
FIELDS = (
    "Workstream", "Status", "Dispatch", "Priority", "Depends on", "Locks",
    "Kind", "Review", "Review stage", "Review modes", "Paired review workstream",
    "Review cycle", "Max automatic review cycles",
    "Review target workstream", "Review target packet", "Task overrides",
    "Authoring chat", "Refresh planning chat", "Visual review",
)
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
PRIORITY = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
KINDS = {"implementation", "review", "correction"}
REVIEW_INTENTS = {"auto", "manual", "none"}
REVIEW_MODES = {"code", "architecture", "runtime", "visual", "asset-pipeline", "workflow"}
VISUAL_REVIEW_VALUES = {"none", "conditional", "required"}
BOUNDED_REVIEW_OVERRIDE = (
    "TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, "
    "this review packet's lifecycle/archive metadata, its required closing summary, and bounded "
    "correction/re-review packets; do not edit the reviewed implementation or unrelated work."
)
VALIDATION_SCRIPT_RE = re.compile(r"(?<![A-Za-z0-9_])((?:custodian/tools|res://tools|tools)/[A-Za-z0-9_./-]+\.(?:py|gd|sh))(?=$|[\s`),.;:])")

# V2 packet header fields that AGENT_TASK_PACKET_TEMPLATE.md's Authoring
# Quality Gate requires to be non-empty on a ready `custodian.task_packet.v2`
# packet. Shared by check_ai_context.py so the structural gate matches what
# the template actually promises.
V2_REQUIRED_FIELDS = (
    "Reviewed main", "Goal", "Completion boundary", "Current measured state",
    "Evidence", "Task-specific authority", "Work surface", "Change",
    "Preserve", "Non-goals", "Acceptance", "Validation", "Deferred",
)

# AGENT_CORRECTION_PACKET_TEMPLATE.md's distinct V2 contract for Kind:
# correction packets: same shape as V2_REQUIRED_FIELDS but "Change" is
# replaced by "Required correction" (the narrow delta against cited finding
# IDs, not a fresh feature description).
V2_CORRECTION_REQUIRED_FIELDS = tuple(
    "Required correction" if field == "Change" else field for field in V2_REQUIRED_FIELDS
)
V2_REVIEW_REQUIRED_FIELDS = (
    "Review target workstream", "Review target packet", "Visual review",
    "Reviewer context", "Reviewer provenance", "Review modes",
    "Review cycle", "Max automatic review cycles", "Task overrides",
)

COMPLETION_TRUTH_SCHEMA = "custodian.task_completion.v1"
# Kinds whose `Status: complete` must carry a truthful Completion Truth
# receipt before workstream.py finish may tear the worktree down. Reviews
# verify someone else's implementation rather than claiming an architecture
# outcome themselves, so they are exempt.
COMPLETION_TRUTH_REQUIRED_KINDS = {"implementation", "correction"}
_YES_NO = {"yes", "no"}
_DISPOSITIONS = {"removed", "intentionally-preserved", "n/a"}


class TaskPacketContractError(RuntimeError):
    pass


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
    task_overrides: str | None = None
    validation_scripts: tuple[str, ...] = ()
    schema: str | None = None
    authoring_chat: str | None = None
    refresh_planning_chat: str | None = None
    visual_review: str = "none"


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

    task_overrides = _header_field_with_continuations(text, "Task overrides")
    validation_scripts = _validation_script_references(text)
    schema = _header_field_with_continuations(text, "Packet schema")
    authoring_chat = _header_field_with_continuations(text, "Authoring chat")
    refresh_planning_chat = _header_field_with_continuations(text, "Refresh planning chat")
    visual_review = (_header_field_with_continuations(text, "Visual review") or "none").lower()
    if visual_review not in VISUAL_REVIEW_VALUES:
        errors.append("invalid Visual review metadata")
        visual_review = "none"

    return Packet(
        path, workstream, status, dispatch, dispatch_declared, priority, dependencies, locks,
        "; ".join(errors) or None,
        kind=kind, review=review, review_stage=review_stage, review_modes=review_modes,
        paired_review_workstream=paired_review_workstream, review_cycle=review_cycle,
        max_review_cycles=max_review_cycles, review_target_workstream=review_target_workstream,
        review_target_packet=review_target_packet, task_overrides=task_overrides,
        validation_scripts=validation_scripts, schema=schema,
        authoring_chat=authoring_chat, refresh_planning_chat=refresh_planning_chat,
        visual_review=visual_review,
    )


def _header_field_with_continuations(text: str, field: str) -> str | None:
    """Read one top-level header field, folding its indented Markdown wraps,
    including indented nested sub-bullets (e.g. `- Work surface:` followed by
    `  - Primary: ...`). Only an unindented `- Field:` line starts a new
    top-level field in this grammar; an indented line that happens to look
    like `Key: value` is still a continuation of the field above it.
    """
    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = re.match(rf"^\s*-\s*{re.escape(field)}:\s*(.*)$", line)
        if not match:
            continue
        parts = [match.group(1).strip()]
        for continuation in lines[index + 1:]:
            if re.match(r"^-\s*[A-Z][^:]*:\s*", continuation) or continuation.startswith("## "):
                break
            if continuation.startswith((" ", "\t")):
                parts.append(continuation.strip())
            elif not continuation.strip():
                continue
            else:
                break
        folded = re.sub(r"\s+", " ", " ".join(parts)).strip().strip("`").strip()
        return folded or None
    return None


def header_field(text: str, field: str) -> str | None:
    """Return a folded top-level header field using the shared packet grammar."""
    return _header_field_with_continuations(text, field)


def _validation_script_references(text: str) -> tuple[str, ...]:
    """Collect explicit script paths only from the packet's Validation field/section."""
    blocks: list[str] = []
    header = text.split("\n## ", 1)[0]
    lines = header.splitlines()
    for index, line in enumerate(lines):
        match = re.match(r"^\s*-\s*Validation:\s*(.*)$", line)
        if not match:
            continue
        parts = [match.group(1)]
        for continuation in lines[index + 1:]:
            if re.match(r"^\s*-\s*[A-Z][^:]*:\s*", continuation):
                break
            parts.append(continuation)
        blocks.append("\n".join(parts))

    for section in re.finditer(r"(?ms)^## Validation\s*\n(.*?)(?=^## |\Z)", text):
        blocks.append(section.group(1))
    return tuple(sorted({match.group(1) for block in blocks for match in VALIDATION_SCRIPT_RE.finditer(block)}))


def _validation_reference_candidates(reference: str) -> tuple[str, ...]:
    """Map a packet spelling to its permitted tracked repository path(s)."""
    if reference.startswith("custodian/tools/"):
        return (reference,)
    if reference.startswith("res://tools/"):
        return ("custodian/" + reference.removeprefix("res://"),)
    if reference.startswith("tools/"):
        return (reference, "custodian/" + reference)
    return ()


def validate_review_pairing(packets: list[Packet]) -> dict[str, str]:
    """Fail-fast consistency guard for the paired post-land review contract.

    Every active `Review: auto` packet must have a matching active review
    packet: same declared `Paired review workstream` id, `Kind: review`,
    `Review: none`, a dependency back on the implementation workstream, and
    matching target workstream and canonical archived target-packet path. The
    A ready/auto implementation requires a ready/auto review; a gated
    implementation may pair with ready/auto or blocked/manual. When BOTH
    implementation and review are draft/manual, the intentionally parked pair
    is valid but neither side is claimable. Historical packets
    that omit review metadata (`Review: none`, the default) are never required
    to pair.
    Reusable by dispatcher eligibility, check_ai_context.py, and tooling per
    the single reusable validation authority this contract requires.
    """
    by_workstream = {p.workstream: p for p in packets if p.workstream and not p.error}
    errors: dict[str, list[str]] = {}

    def add(workstream: str | None, message: str) -> None:
        if workstream:
            errors.setdefault(workstream, []).append(message)

    for p in packets:
        if p.kind == "review" and p.dispatch == "auto":
            override_error = _bounded_review_override_error(p.task_overrides)
            if override_error:
                add(p.workstream, override_error)
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
        paired_state = (paired.status, paired.dispatch)
        implementation_is_ready = (p.status, p.dispatch) == ("ready", "auto")
        valid_pair_states = {("ready", "auto"), ("blocked", "manual")}
        # Draft/manual is an intentionally parked, non-claimable planning state.
        # Permit it only when the implementation is also draft/manual, not when
        # a ready or blocked implementation is relying on its paired reviewer.
        if (p.status, p.dispatch) == ("draft", "manual"):
            valid_pair_states.add(("draft", "manual"))
        if implementation_is_ready:
            if paired.status != "ready":
                add(p.workstream, f"paired review '{paired_id}' must declare Status: ready")
            if paired.dispatch != "auto":
                add(p.workstream, f"paired review '{paired_id}' must declare Dispatch: auto")
        elif paired_state not in valid_pair_states:
            add(p.workstream, f"paired review '{paired_id}' must be ready/auto or blocked/manual while its implementation is gated")
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


def validate_queue_contract(
    packets: list[Packet], archived: list[Packet] = (), texts: dict[str, str] | None = None,
) -> dict[str, str]:
    """Validate active queue metadata and dependency identities.

    Archived packets are historical identity evidence only when complete; they
    are deliberately not re-graded against today's queue rules.
    """
    errors: dict[str, list[str]] = {}

    def add(workstream: str | None, message: str) -> None:
        if workstream:
            errors.setdefault(workstream, []).append(message)

    by_id: dict[str, list[Packet]] = {}
    for packet in packets:
        if packet.workstream:
            by_id.setdefault(packet.workstream, []).append(packet)
        if is_v2_packet(packet) and packet.status == "draft" and packet.dispatch == "auto":
            add(packet.workstream,
                "invalid draft/auto queue state; use ready/auto for dependency-gated mechanical work or draft/manual for a genuine refresh/human gate")
        if is_v2_packet(packet) and packet.status == "ready" and texts is not None:
            if packet.kind == "correction":
                required_fields = V2_CORRECTION_REQUIRED_FIELDS
            elif packet.kind == "implementation":
                required_fields = V2_REQUIRED_FIELDS
            else:
                required_fields = ()
            if required_fields:
                text = texts.get(packet.path, "")
                missing = [field for field in required_fields if not _header_field_with_continuations(text, field)]
                if missing:
                    add(packet.workstream, "missing required V2 metadata: " + ", ".join(missing))
        if is_v2_packet(packet) and packet.status == "draft" and packet.dispatch == "manual" and texts is not None:
            body = texts.get(packet.path, "").lower()
            rationale = re.search(
                r"refresh (?:required|instruction|reason)|human(?:-owned)? (?:decision|review|approval)|"
                r"do not claim|must not claim|must not become ready|approval remains human-owned|"
                r"exact art list intentionally remains human-reviewed",
                body,
            )
            if not rationale:
                add(packet.workstream,
                    "draft/manual packet needs a concrete refresh or human-decision reason in its body or handoff")
    for workstream, matches in by_id.items():
        if len(matches) > 1:
            for packet in matches:
                add(workstream, f"duplicate Workstream identity: {workstream}")
    known_ids = set(by_id)
    known_ids.update(
        packet.workstream for packet in archived
        if packet.workstream and not packet.error and packet.status == "complete"
    )
    for packet in packets:
        for dependency in packet.dependencies:
            if dependency not in known_ids:
                add(packet.workstream, f"missing dependency identity: {dependency} (not active or archived complete)")
    return {workstream: "; ".join(dict.fromkeys(messages)) for workstream, messages in errors.items()}


def _bounded_review_override_error(value: str | None) -> str | None:
    if not value or "TASK OVERRIDE:" not in value:
        return "auto review packet requires a bounded TASK OVERRIDE for review-artifact commits"
    normalized = re.sub(r"\s+", " ", value).strip()
    expected = re.sub(r"\s+", " ", BOUNDED_REVIEW_OVERRIDE).strip()
    if normalized != expected:
        return "auto review packet has malformed bounded TASK OVERRIDE; copy the exact authorized scope from AGENT_REVIEW_PACKET_TEMPLATE.md"
    return None


def _contract_git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if result.returncode:
        raise TaskPacketContractError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def validate_packet_validation_references(
    repo: Path, packets: list[Packet], tree: str = "origin/main",
    exclude_workstreams: set[str] | None = None,
) -> dict[str, str]:
    """Reject ready packets whose explicit validation scripts do not exist in the authority tree."""
    import difflib

    tool_paths = set(_contract_git(repo, "ls-tree", "-r", "--name-only", tree, "--", "custodian/tools", "tools").splitlines())
    errors: dict[str, str] = {}
    for packet in packets:
        if exclude_workstreams and packet.workstream in exclude_workstreams:
            continue
        if packet.status != "ready" or not packet.validation_scripts or not packet.workstream:
            continue
        missing = [
            path for path in packet.validation_scripts
            if not any(candidate in tool_paths for candidate in _validation_reference_candidates(path))
        ]
        if not missing:
            continue
        repo_tools = sorted(path for path in tool_paths if path.endswith((".py", ".gd", ".sh")))
        details = []
        for path in missing:
            nearest = difflib.get_close_matches(path, repo_tools, n=1, cutoff=0.45)
            suggestion = f"; nearest live path: {nearest[0]}" if nearest else ""
            details.append(f"missing validation script '{path}'{suggestion}")
        errors[packet.workstream] = "; ".join(details)
    return errors


def review_cycle_exhausted(packet: Packet) -> bool:
    """True once a review/correction packet has reached its finite-loop cap.

    Original implementation review is cycle 0; each automatic correction's
    paired review increments the cycle. A reviewer at the cap escalates to
    `human_required` in the durable review receipt instead of scaffolding
    another automatic correction.
    """
    return packet.review_cycle >= packet.max_review_cycles


def is_v2_packet(packet: Packet) -> bool:
    return packet.schema == "custodian.task_packet.v2"


def v2_required_field_values(text: str, fields: tuple[str, ...] = V2_REQUIRED_FIELDS) -> dict[str, str | None]:
    """Read each required top-level field's raw folded value, or None if absent/blank.

    Defaults to the implementation contract (V2_REQUIRED_FIELDS); pass
    V2_CORRECTION_REQUIRED_FIELDS for Kind: correction packets, which use
    AGENT_CORRECTION_PACKET_TEMPLATE.md's distinct field contract.
    """
    return {field: _header_field_with_continuations(text, field) for field in fields}


@dataclass(frozen=True)
class CompletionTruth:
    schema: str | None
    goal_satisfied: str | None
    completion_boundary_satisfied: str | None
    acceptance_satisfied: str | None
    disposition: str | None
    evidence: str | None
    error: str | None = None

    @property
    def all_yes(self) -> bool:
        return (
            self.error is None
            and self.schema == COMPLETION_TRUTH_SCHEMA
            and self.goal_satisfied == "yes"
            and self.completion_boundary_satisfied == "yes"
            and self.acceptance_satisfied == "yes"
        )


def parse_completion_truth(text: str) -> CompletionTruth | None:
    """Parse the `## Completion Truth` receipt, or None if the section is absent.

    A present-but-malformed section returns a CompletionTruth with `error`
    set rather than None, so callers can distinguish "missing" from "present
    but untrustworthy" and fail closed on both for packets that require it.
    """
    match = re.search(r"(?ms)^## Completion Truth\s*\n(.*?)(?=^## |\Z)", text)
    if not match:
        return None
    body = match.group(1)

    def field(name: str) -> str | None:
        found = re.search(rf"^\s*-\s*{re.escape(name)}:\s*(.*?)\s*$", body, re.MULTILINE)
        if not found:
            return None
        return found.group(1).strip().strip("`").strip() or None

    schema = field("Completion schema")
    goal = field("Goal satisfied")
    boundary = field("Completion boundary satisfied")
    acceptance = field("Acceptance satisfied")
    disposition = field("Superseded/legacy production path disposition")
    evidence = field("Evidence")

    errors: list[str] = []
    if schema != COMPLETION_TRUTH_SCHEMA:
        errors.append("invalid or missing Completion schema")
    for name, value in (("Goal satisfied", goal), ("Completion boundary satisfied", boundary), ("Acceptance satisfied", acceptance)):
        if value not in _YES_NO:
            errors.append(f"{name} must be yes or no")
    if disposition is not None and disposition not in _DISPOSITIONS:
        errors.append("Superseded/legacy production path disposition must be removed, intentionally-preserved, or n/a")
    if not evidence:
        errors.append("Evidence must be non-empty")

    return CompletionTruth(
        schema=schema, goal_satisfied=goal, completion_boundary_satisfied=boundary,
        acceptance_satisfied=acceptance, disposition=disposition, evidence=evidence,
        error="; ".join(errors) or None,
    )


def completion_truth_required(packet: Packet) -> bool:
    """True when `workstream.py finish` must enforce a truthful Completion Truth receipt.

    Only current V2 implementation/correction packets are covered. Review
    packets verify someone else's claim rather than making one; legacy
    (non-V2) packets are never bulk-migrated into this requirement.
    """
    return is_v2_packet(packet) and packet.kind in COMPLETION_TRUTH_REQUIRED_KINDS
