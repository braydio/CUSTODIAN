from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def append_critique(path: Path, critique: dict) -> dict:
    required={"frame","severity","category","part","bounds","issue","repair_intent","confidence"}
    missing=required-set(critique)
    if missing: raise ValueError(f"critique missing: {sorted(missing)}")
    with path.open("a",encoding="utf-8") as stream: stream.write(json.dumps(critique,sort_keys=True)+"\n")
    return critique


def critiques(path: Path) -> list[dict]:
    return [json.loads(x) for x in path.read_text().splitlines() if x] if path.exists() else []


def _status_summary(items: list[dict[str, Any]], statuses: tuple[str, ...]) -> dict[str, int]:
    summary = {"total": len(items)}
    for status in statuses:
        summary[status.lower()] = sum(1 for item in items if item.get("status") == status)
    return summary


def packet(
    path: Path,
    *,
    task: str,
    constraints: list[str],
    artifacts: dict,
    metrics: str,
    qa: str,
    references: list[dict],
    findings: list[dict],
    masks: list[dict[str, Any]] | None = None,
    drafts: list[dict[str, Any]] | None = None,
    landmarks: list[dict[str, Any]] | None = None,
    workbench_sha256: str = "",
    operations: list[dict[str, Any]] | None = None,
) -> dict:
    masks = masks or []
    drafts = drafts or []
    landmarks = landmarks or []
    operations = operations or []
    draft_status_summary = _status_summary(drafts, ("ACTIVE", "BAKED", "DISCARDED", "STALE"))
    draft_status_summary["needs_gap_repair"] = sum(1 for item in drafts if item.get("needs_gap_repair"))
    value = {
        "schema": "custodian.operator_art_review_packet.v2",
        "task": task,
        "constraints": constraints,
        "artifacts": artifacts,
        "metrics": metrics,
        "qa": qa,
        "references": references,
        "open_findings": findings,
        "masks": masks,
        "mask_status_summary": _status_summary(masks, ("CURRENT", "STALE")),
        "drafts": drafts,
        "draft_status_summary": draft_status_summary,
        "landmarks": landmarks,
        "landmark_status_summary": _status_summary(landmarks, ("CURRENT", "STALE")),
        "workbench_sha256": workbench_sha256,
        "operation_journal_summary": {"count": len(operations), "types": [item.get("type") for item in operations]},
    }
    path.write_text(json.dumps(value, indent=2) + "\n")
    return value
