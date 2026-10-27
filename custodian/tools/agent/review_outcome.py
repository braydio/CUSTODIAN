"""Canonical administrative outcome of a paired review and accepted-review semantics.

A paired review may conclude as ``passed``, ``findings`` or ``human_required``.
Only ``passed`` accepts the reviewed implementation. The outcome is recorded once,
as a flat ``## Review Outcome`` section in the archived *review* packet, and is
bound to the review workstream, reviewed target, pinned reviewed main, immutable
implementation commit, originating run and stable finding IDs.

This module only parses and judges text. It never reads Git or the filesystem, so
the dispatcher, the paired-review runner and workstream closeout share exactly
one definition of "accepted review".
"""
from __future__ import annotations

import re

SCHEMA = "custodian.review_outcome.v1"
OUTCOMES = ("passed", "findings", "human_required")
NONPASSING = ("findings", "human_required")
PROVENANCE = ("different-agent", "same-agent-fresh-context")
FIELDS = (
    "Schema", "Outcome", "Review workstream", "Review target workstream", "Reviewed main",
    "Reviewed implementation commit", "Reviewer context", "Reviewer provenance", "Run ID",
    "Review cycle", "Finding IDs",
)

_SECTION_RE = re.compile(r"(?m)^## Review Outcome[ \t\r]*$")
_NEXT_SECTION_RE = re.compile(r"(?m)^## [^\r]*$")
_LINE_RE = re.compile(r"- ([A-Za-z][A-Za-z ]*): `([^`\r\n]+)`")
_SHA_RE = re.compile(r"^[0-9a-f]{40,64}$")
_RUN_ID_RE = re.compile(r"^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$")
FINDING_ID_RE = re.compile(r"^R(?:0|[1-9][0-9]*)-(?:0[1-9]|[1-9][0-9]*)$")
_CORRECTION_RE = re.compile(r"^(?P<root>.+)-review-corrections-(?P<cycle>[1-9][0-9]*)$")


def parse_review_outcome(text: str) -> tuple[dict[str, str] | None, str | None]:
    """Return ``(outcome, None)``, ``(None, None)`` when absent, or ``(None, error)``.

    Absence is not an error here: legacy archived reviews predate this section and
    are judged by :func:`review_acceptance`. A present-but-defective section always
    fails closed.
    """
    sections = list(_SECTION_RE.finditer(text))
    if not sections:
        return None, None
    if len(sections) != 1:
        return None, "more than one Review Outcome section"
    start = sections[0].end()
    following = _NEXT_SECTION_RE.search(text, start)
    body = text[start:following.start() if following else len(text)]
    values: dict[str, str] = {}
    for line in body.splitlines():
        if not line.strip():
            continue
        match = _LINE_RE.fullmatch(line.rstrip())
        if not match or match.group(1) not in FIELDS:
            return None, "Review Outcome contains non-canonical content"
        if match.group(1) in values:
            return None, f"Review Outcome repeats {match.group(1)}"
        values[match.group(1)] = match.group(2).strip()
    missing = [name for name in FIELDS if name not in values]
    if missing:
        return None, f"Review Outcome is missing {missing[0]}"
    if values["Schema"] != SCHEMA:
        return None, "Review Outcome has an unknown schema"
    if values["Outcome"] not in OUTCOMES:
        return None, "Review Outcome has an unknown outcome"
    for name in ("Reviewed main", "Reviewed implementation commit"):
        if not _SHA_RE.fullmatch(values[name]):
            return None, f"Review Outcome {name} is not a full commit SHA"
    if not _RUN_ID_RE.fullmatch(values["Run ID"]):
        return None, "Review Outcome Run ID is malformed"
    if values["Reviewer context"] != "fresh" or values["Reviewer provenance"] not in PROVENANCE:
        return None, "Review Outcome has invalid reviewer provenance"
    if not re.fullmatch(r"0|[1-9][0-9]*", values["Review cycle"]):
        return None, "Review Outcome review cycle is not a non-negative integer"
    ids = [item.strip() for item in values["Finding IDs"].split(",")]
    if values["Outcome"] == "passed":
        if ids != ["none"]:
            return None, "a passed Review Outcome must record Finding IDs none"
    else:
        if ids == ["none"] or not all(FINDING_ID_RE.fullmatch(item) for item in ids) or len(set(ids)) != len(ids):
            return None, "a nonpassing Review Outcome requires unique stable finding IDs"
        cycle = values["Review cycle"]
        if any(not item.startswith(f"R{cycle}-") for item in ids):
            return None, "finding IDs do not belong to the recorded review cycle"
    return values, None


def finding_ids(outcome: dict[str, str]) -> tuple[str, ...]:
    ids = [item.strip() for item in outcome["Finding IDs"].split(",")]
    return () if ids == ["none"] else tuple(ids)


def finding_evidenced(text: str, finding_id: str) -> bool:
    """True when ``finding_id`` appears as a whole token (``R0-01`` must not match ``R0-011``)."""
    return re.search(rf"(?<![A-Za-z0-9-]){re.escape(finding_id)}(?![A-Za-z0-9-])", text) is not None


def render_review_outcome(*, outcome: str, review_workstream: str, target_workstream: str,
                          reviewed_main: str, implementation_commit: str, provenance: str,
                          run_id: str, review_cycle: int, ids: tuple[str, ...]) -> str:
    """Render the one canonical section; the parser must accept exactly this output."""
    rendered = (
        "## Review Outcome\n\n"
        f"- Schema: `{SCHEMA}`\n- Outcome: `{outcome}`\n"
        f"- Review workstream: `{review_workstream}`\n- Review target workstream: `{target_workstream}`\n"
        f"- Reviewed main: `{reviewed_main}`\n- Reviewed implementation commit: `{implementation_commit}`\n"
        f"- Reviewer context: `fresh`\n- Reviewer provenance: `{provenance}`\n"
        f"- Run ID: `{run_id}`\n- Review cycle: `{review_cycle}`\n"
        f"- Finding IDs: `{', '.join(ids) if ids else 'none'}`\n"
    )
    parsed, error = parse_review_outcome(rendered)
    if error or parsed is None:
        raise ValueError(f"refusing to render a non-canonical Review Outcome: {error}")
    return rendered


def outcome_identity_error(outcome: dict[str, str], *, review_workstream: str, target_workstream: str,
                           reviewed_main: str, implementation_commit: str | None,
                           run_id: str | None = None, review_cycle: int | None = None) -> str | None:
    """Bind a parsed outcome to the exact pinned review. ``None`` means every binding holds."""
    expected = {
        "Review workstream": review_workstream, "Review target workstream": target_workstream,
        "Reviewed main": reviewed_main,
    }
    if implementation_commit is None:
        return "pinned implementation commit is unresolved"
    expected["Reviewed implementation commit"] = implementation_commit
    if run_id is not None:
        expected["Run ID"] = run_id
    if review_cycle is not None:
        expected["Review cycle"] = str(review_cycle)
    for name, value in expected.items():
        if outcome.get(name) != value:
            return f"Review Outcome {name} does not match the pinned review"
    return None


def target_receipt_passed(target_text: str | None, review_workstream: str) -> bool:
    """True only for exactly one canonical passing receipt for this review in the target."""
    if not target_text:
        return False
    heading = f"### Review Receipt: {review_workstream}\n"
    if target_text.count(heading) != 1:
        return False
    start = target_text.index(heading) + len(heading)
    end = re.search(r"(?m)^#{2,3} ", target_text[start:])
    body = target_text[start:start + end.start() if end else len(target_text)]
    return all(re.search(rf"(?m)^- {field}: `{value}`\s*$", body)
               for field, value in (("Status", "passed"), ("Blocking defects", "0"), ("Material gaps", "0")))


def _legacy_field_values(body: str, field: str) -> list[str]:
    """Read legacy review fields without treating unrelated prose as a receipt."""
    return re.findall(rf"(?m)^\s*-\s*{re.escape(field)}:\s*([^\r\n]+)$", body)


def _legacy_pin(values: list[str]) -> set[str] | None:
    """Extract the exact abbreviated/full Git token from each recorded pin."""
    pins: set[str] = set()
    for value in values:
        match = re.fullmatch(r"`?([0-9a-f]{7,64})`?(?:\s+\([^\r\n]*\))?", value.strip())
        if match is None:
            return None
        pins.add(match.group(1))
    return pins


def legacy_target_passed(target_text: str | None, review_workstream: str | None = None,
                         review_text: str | None = None) -> bool:
    """Accept one ordinary legacy PASS or two independently corroborated duplicate records.

    Historical packets sometimes appended the same passing review twice with
    different levels of detail. Two sections are accepted ONLY when they both
    pass, identify one review and one pinned target, contain fresh independent
    reviewer evidence and zero blockers/gaps, and agree with the separate
    archived review. Contradictory, incomplete, or more numerous sections fail.
    A present canonical Review Outcome is always handled separately first.
    """
    if not target_text:
        return False
    sections = list(re.finditer(r"(?m)^## Independent Review[^\r\n]*$", target_text))
    if len(sections) == 1:
        start = sections[0].end()
        following = _NEXT_SECTION_RE.search(target_text, start)
        body = target_text[start:start + following.start() if following else len(target_text)]
        statuses = re.findall(r"(?m)^\s*-\s*Status:\s*`?([A-Za-z_]+)`?\s*$", body)
        return bool(statuses) and all(item in {"passed", "pass"} for item in statuses)

    if len(sections) != 2 or not review_workstream or not review_text:
        return False

    bodies: list[str] = []
    for index, match in enumerate(sections):
        start = match.end()
        boundary = _NEXT_SECTION_RE.search(target_text, start)
        end = boundary.start() + start if boundary else len(target_text)
        bodies.append(target_text[start:end])

    reviewed_mains: set[str] = set()
    implementation_commits: set[str] = set()
    has_matching_review = False
    has_fresh_context = False
    has_independent_provenance = False
    has_zero_blockers = False
    has_zero_gaps = False
    for body in bodies:
        statuses = re.findall(r"(?m)^\s*-\s*Status:\s*`?([A-Za-z_]+)`?\s*$", body)
        if len(statuses) != 1 or statuses[0] not in {"passed", "pass"}:
            return False
        if any(value.strip("` ").lower() not in {"passed", "pass"}
               for value in _legacy_field_values(body, "Result")):
            return False
        for value in _legacy_field_values(body, "Findings"):
            if not re.match(r"(?i)^none(?:\s*;|\s*$)", value.strip("` ")):
                return False

        names = _legacy_field_values(body, "Review workstream")
        if any(value.strip("` ") != review_workstream for value in names):
            return False
        has_matching_review |= bool(names)
        contexts = _legacy_field_values(body, "Reviewer context")
        if any(value.strip("` ") != "fresh" for value in contexts):
            return False
        has_fresh_context |= bool(contexts)
        provenances = _legacy_field_values(body, "Reviewer provenance")
        if any(value.strip("` ") not in PROVENANCE for value in provenances):
            return False
        has_independent_provenance |= bool(provenances)

        for field in ("Blocking defects", "Material evidence gaps", "Material gaps"):
            values = _legacy_field_values(body, field)
            if any(value.strip("` ") != "0" for value in values):
                return False
            if field == "Blocking defects":
                has_zero_blockers |= bool(values)
            else:
                has_zero_gaps |= bool(values)

        main_pins = _legacy_pin(_legacy_field_values(body, "Reviewed main") +
                                _legacy_field_values(body, "Reviewed on main"))
        target_pins = _legacy_pin(_legacy_field_values(body, "Reviewed implementation commit"))
        if main_pins is None or target_pins is None:
            return False
        reviewed_mains.update(main_pins)
        implementation_commits.update(target_pins)

    if not (has_matching_review and has_fresh_context and has_independent_provenance and
            has_zero_blockers and has_zero_gaps and
            len(reviewed_mains) == 1 and len(implementation_commits) == 1):
        return False
    reviewed_main = next(iter(reviewed_mains))
    implementation_commit = next(iter(implementation_commits))
    review_sections = list(re.finditer(r"(?m)^## Independent Review[^\r\n]*$", review_text))
    if len(review_sections) != 1:
        return False
    review_statuses = re.findall(r"(?m)^\s*-\s*Status:\s*`?([A-Za-z_]+)`?\s*$",
                                 review_text[review_sections[0].end():])
    if review_statuses != ["passed"]:
        return False
    return (review_workstream in review_text and reviewed_main in review_text and
            implementation_commit in review_text)




def review_acceptance(review_text: str, target_text: str | None, review_workstream: str,
                      ) -> tuple[bool, str | None, str]:
    """Decide whether an archived review releases ordinary accepted-review dependents.

    Returns ``(accepted, outcome, reason)``. Nothing but a verified pass accepts:
    findings, human_required, malformed or contradictory outcomes, and legacy
    reviews with no verifiable passing target receipt all stay unaccepted.
    """
    outcome, error = parse_review_outcome(review_text)
    if error:
        return False, None, f"malformed review outcome: {error}"
    if outcome is not None:
        if outcome["Review workstream"] != review_workstream:
            return False, outcome["Outcome"], "review outcome names a different review workstream"
        if outcome["Outcome"] != "passed":
            return False, outcome["Outcome"], f"review concluded {outcome['Outcome']}"
        if not target_receipt_passed(target_text, review_workstream):
            return False, "passed", "passed outcome has no canonical target receipt"
        return True, "passed", "passed"
    if target_receipt_passed(target_text, review_workstream) or legacy_target_passed(target_text, review_workstream, review_text):
        return True, None, "legacy passing target receipt"
    return False, None, "no verified passing outcome or target receipt"


def correction_lineage_error(correction_workstream: str, correction_text: str, review_workstream: str,
                             outcome: dict[str, str] | None) -> str | None:
    """Allow a bounded correction to consume a concluded *findings* review, and only that."""
    if outcome is None or outcome["Outcome"] != "findings":
        return "dependency review did not conclude with findings"
    if outcome["Review workstream"] != review_workstream:
        return "review outcome names a different review workstream"
    target = outcome["Review target workstream"]
    if review_workstream != f"review-{target}":
        return "review workstream does not review its recorded target"
    target_match = _CORRECTION_RE.fullmatch(target)
    root = target_match.group("root") if target_match else target
    cycle = int(target_match.group("cycle")) if target_match else 0
    if int(outcome["Review cycle"]) != cycle:
        return "review cycle does not match the reviewed target lineage"
    if correction_workstream != f"{root}-review-corrections-{cycle + 1}":
        return "correction is not the next bounded correction of the reviewed lineage"
    addressed = re.search(r"(?m)^\s*-\s*Findings addressed:\s*`?([^`\n]+)", correction_text)
    ids = [item.strip().strip("`") for item in addressed.group(1).split(",")] if addressed else []
    if not ids or not all(FINDING_ID_RE.fullmatch(item) for item in ids):
        return "correction lacks stable Findings addressed IDs"
    if not set(ids) <= set(finding_ids(outcome)):
        return "correction addresses findings the review did not record"
    return None
