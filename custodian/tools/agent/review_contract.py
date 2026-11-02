"""Structural helpers for review findings and delta correction packets."""
from __future__ import annotations

import re
from collections.abc import Mapping


FINDING_ID_RE = re.compile(r"^R(?:0|[1-9][0-9]*)-(?:0[1-9]|[1-9][0-9]*)$")
FINDING_CLASSES = {"blocking_defect", "evidence_gap", "non_blocking_issue", "optional_improvement"}
FINDING_DOMAINS = {"implementation", "pipeline"}
FINDING_DISPOSITIONS = {"correction", "next_slice", "deferred", "human_required", "no_action"}
FINDING_FIELDS = (
    "ID", "Class", "Domain", "Acceptance affected", "Evidence", "Disposition", "Rationale",
)
CORRECTION_FIELDS = (
    "Parent implementation", "Parent review", "Findings addressed", "Affected acceptance",
    "Current defect/evidence", "Required correction", "Work surface", "Preserve", "Non-goals",
    "Acceptance", "Validation", "Deferred",
)


def validate_finding_record(record: Mapping[str, str]) -> list[str]:
    """Check only record shape and enum/ID values; never grade prose quality."""
    errors = [f"missing finding field: {field}" for field in FINDING_FIELDS if not record.get(field, "").strip()]
    finding_id = record.get("ID", "").strip()
    if finding_id and not FINDING_ID_RE.fullmatch(finding_id):
        errors.append(f"malformed finding ID: {finding_id}")
    if record.get("Class") and record["Class"] not in FINDING_CLASSES:
        errors.append(f"invalid finding class: {record['Class']}")
    if record.get("Domain") and record["Domain"] not in FINDING_DOMAINS:
        errors.append(f"invalid finding domain: {record['Domain']}")
    if record.get("Disposition") and record["Disposition"] not in FINDING_DISPOSITIONS:
        errors.append(f"invalid finding disposition: {record['Disposition']}")
    return errors


def validate_correction_delta(fields: Mapping[str, str]) -> list[str]:
    """Require correction ancestry, acceptance linkage, and at least one stable finding ID."""
    errors = [f"missing correction field: {field}" for field in CORRECTION_FIELDS if not fields.get(field, "").strip()]
    raw_ids = fields.get("Findings addressed", "")
    ids = [part.strip() for part in raw_ids.split(",") if part.strip()]
    if not ids:
        errors.append("correction must address at least one finding ID")
    for finding_id in ids:
        if not FINDING_ID_RE.fullmatch(finding_id):
            errors.append(f"malformed correction finding ID: {finding_id}")
    return errors
