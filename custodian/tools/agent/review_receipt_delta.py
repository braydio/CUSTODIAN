"""Fail-closed validation for the one authorized paired-review receipt delta."""
from __future__ import annotations

import re


_SECTION_RE = re.compile(r"(?m)^## Independent Review[ \t]*$")
_NEXT_SECTION_RE = re.compile(r"(?m)^## [^\r]*$")
_SHA_RE = re.compile(r"^[0-9a-f]{40,64}$")


def _section(text: str) -> tuple[int, int, str] | None:
    matches = list(_SECTION_RE.finditer(text))
    if len(matches) != 1:
        return None
    match = matches[0]
    next_section = _NEXT_SECTION_RE.search(text, match.end())
    end = next_section.start() if next_section else len(text)
    return match.start(), end, text[match.start():end]


def _field(receipt: str, name: str) -> str | None:
    matches = re.findall(rf"(?m)^- {re.escape(name)}: `?([^`\r\n]+)`?\s*$", receipt)
    return matches[0].strip() if len(matches) == 1 else None


def verify_review_receipt_delta(
    baseline: str,
    candidate: str,
    *,
    review_workstream: str,
    target_workstream: str,
    reviewed_main: str,
    target_implementation_commit: str | None = None,
) -> tuple[dict[str, str] | None, str | None]:
    """Return the appended receipt only when all non-receipt bytes are immutable."""
    if not review_workstream or not target_workstream or not _SHA_RE.fullmatch(reviewed_main):
        return None, "review receipt identity or pinned main SHA is invalid"

    old = _section(baseline)
    new = _section(candidate)
    if new is None:
        return None, "candidate must contain exactly one Independent Review section"

    start, end, new_section = new
    receipt_heading = f"### Review Receipt: {review_workstream}\n"
    if old is None:
        if _SECTION_RE.search(baseline) or not baseline.endswith("\n") or candidate[:len(baseline)] != baseline:
            return None, "new review receipt must append after the exact baseline packet bytes"
        if candidate[len(baseline):start] != "\n" or candidate[end:] != "":
            return None, "new Independent Review section is not canonically appended at packet end"
        expected_section_start = "## Independent Review\n\n"
        if not new_section.startswith(expected_section_start + receipt_heading):
            return None, "new Independent Review section must contain the canonical receipt heading"
        delta = new_section[len(expected_section_start + receipt_heading):]
    else:
        old_start, old_end, old_section = old
        if baseline[:old_start] != candidate[:start] or baseline[old_end:] != candidate[end:]:
            return None, "packet bytes outside the Independent Review section changed"
        if not new_section.startswith(old_section):
            return None, "existing Independent Review receipt bytes were rewritten"
        separator = "\n" if old_section.endswith("\n") else "\n\n"
        expected_prefix = old_section + separator + receipt_heading
        if not new_section.startswith(expected_prefix):
            return None, "candidate must append exactly one canonical review receipt"
        delta = new_section[len(expected_prefix):]

    if delta.count(receipt_heading) != 0:
        return None, "candidate contains duplicate or ambiguous review receipts"
    if re.search(r"(?m)^### Review Receipt:", delta) or _SECTION_RE.search(delta):
        return None, "candidate contains duplicate or ambiguous review receipts"

    required = {
        "Schema": "custodian.paired_review.v1",
        "Review workstream": review_workstream,
        "Review target workstream": target_workstream,
        "Status": "passed",
        "Blocking defects": "0",
        "Material gaps": "0",
        "Reviewer context": "fresh",
        "Reviewed main": reviewed_main,
    }
    values: dict[str, str] = {}
    for key, expected in required.items():
        value = _field(delta, key)
        if value != expected:
            return None, f"review receipt has missing or mismatched {key}"
        values[key] = value
    provenance = _field(delta, "Reviewer provenance")
    if provenance not in {"different-agent", "same-agent-fresh-context"}:
        return None, "review receipt has missing or invalid Reviewer provenance"
    values["Reviewer provenance"] = provenance

    implementation_commit = _field(delta, "Reviewed implementation commit")
    if not implementation_commit or not _SHA_RE.fullmatch(implementation_commit):
        return None, "review receipt has missing or invalid Reviewed implementation commit"
    if not target_implementation_commit or not _SHA_RE.fullmatch(target_implementation_commit):
        return None, "pinned target baseline has no unique full Implementation commit"
    if implementation_commit != target_implementation_commit:
        return None, "review receipt names a different implementation commit than the baseline target"
    values["Reviewed implementation commit"] = implementation_commit
    allowed = set(required) | {"Reviewer provenance", "Reviewed implementation commit"}
    receipt_lines = [line for line in delta.splitlines() if line.strip()]
    for line in receipt_lines:
        match = re.fullmatch(r"- ([A-Za-z][A-Za-z ]*): `([^`\r\n]+)`", line)
        if not match or match.group(1) not in allowed:
            return None, "review receipt contains non-canonical or unauthorized content"
    if len(receipt_lines) != len(allowed):
        return None, "review receipt must contain exactly one canonical value for every required field"
    return values, None
