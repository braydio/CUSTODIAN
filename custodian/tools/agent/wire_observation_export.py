#!/usr/bin/env python3
"""Export a sanitized WIRE document from an already-collected task-admin snapshot.

This module has no collector, subprocess, Git, network, Dropbox, or write path.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA = "custodian.wire.observation.v1"
SNAPSHOT_SCHEMA = "custodian.task_admin.snapshot.v1"
DISPATCH_SCHEMA = "custodian.task_packet_queue_audit.v1"
RECOVERY_SCHEMA = "custodian.workstream_recovery_audit.v1"
SCHEMA_PATH = Path(__file__).resolve().parent / "schemas" / "wire_observation.v1.schema.json"
MAX_INPUT_BYTES = 16 * 1024 * 1024
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$")

DISPATCH_CLASSES = {
    "legacy_quarantined", "claimed", "invalid_recovery", "parked_draft",
    "dependency_lock_blocked", "manual_ready", "ready_auto",
}
REASON_PREFIXES = (
    ("invalid review pairing:", "invalid_review_pairing"),
    ("invalid validation references:", "invalid_validation_references"),
    ("invalid queue contract:", "invalid_queue_contract"),
    ("invalid packet metadata:", "invalid_packet_metadata"),
    ("duplicate active identity:", "duplicate_identity"),
    ("legacy_quarantined;", "legacy_quarantined"),
    ("already claimed by", "already_claimed"),
    ("remote dispatch claim interrupted", "interrupted_claim"),
    ("status is ", "status_not_ready"),
    ("manual dispatch;", "manual_dispatch"),
    ("dependency not archived complete:", "dependency_not_complete"),
    ("dependency review not accepted:", "dependency_review_not_accepted"),
    ("dependency:", "dependency_blocked"),
    ("lock:", "lock_blocked"),
)
REASON_CODES = {value for _, value in REASON_PREFIXES} | {"unclassified_reason"}


class ObservationError(ValueError):
    """Input evidence is incomplete, inconsistent, stale, or unsafe to export."""


def _object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ObservationError("source evidence is unavailable or malformed")
    return value


def _integer(value: Any) -> bool:
    return type(value) is int


def _timestamp(value: Any) -> datetime:
    if not isinstance(value, str) or not DATE_RE.fullmatch(value):
        raise ObservationError("source timestamp is missing or invalid")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ObservationError("source timestamp is missing or invalid") from exc
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ObservationError("source timestamp has no timezone")
    return parsed.astimezone(timezone.utc)


def _workstream(value: Any) -> str:
    if not isinstance(value, str) or not ID_RE.fullmatch(value):
        raise ObservationError("workstream identity is missing or unsafe")
    return value


def _reason_codes(value: Any) -> list[str]:
    if not isinstance(value, list) or any(not isinstance(item, str) for item in value):
        raise ObservationError("dispatcher eligibility evidence is incomplete")
    result = set()
    for reason in value:
        result.add(next((code for prefix, code in REASON_PREFIXES if reason.startswith(prefix)),
                        "unclassified_reason"))
    return sorted(result)


def _process_evidence(value: Any) -> dict[str, Any]:
    if value == "UNKNOWN":
        return {"availability": "unknown", "scan_complete": None}
    if not isinstance(value, list):
        raise ObservationError("process evidence is malformed")
    if not value:
        return {"availability": "unknown", "scan_complete": None}
    scan_values = []
    for item in value:
        if not isinstance(item, dict):
            raise ObservationError("process evidence is malformed")
        scan = item.get("process_scan_complete")
        if scan is not None and type(scan) is not bool:
            raise ObservationError("process evidence is malformed")
        scan_values.append(scan)
    if any(value is False for value in scan_values):
        return {"availability": "incomplete", "scan_complete": False}
    if scan_values and all(value is True for value in scan_values):
        return {"availability": "available", "scan_complete": True}
    return {"availability": "unknown", "scan_complete": None}


def _validate_sources(snapshot: Any, now: datetime, max_age: int) -> tuple[dict, dict, dict, dict, datetime, datetime]:
    source = _object(snapshot, "snapshot")
    if source.get("schema") != SNAPSHOT_SCHEMA or type(source.get("revision")) is not int or source.get("revision") != 1:
        raise ObservationError("task-administrator snapshot schema is unsupported")
    dispatch = _object(source.get("dispatch"), "dispatcher")
    recovery = _object(source.get("recovery"), "recovery")
    health = _object(source.get("source_health"), "source health")
    origin = _object(source.get("origin_main_evidence"), "origin evidence")
    if dispatch.get("schema") != DISPATCH_SCHEMA or recovery.get("schema") != RECOVERY_SCHEMA:
        raise ObservationError("source audit schema is unsupported")
    if (health.get("dispatch") != "ok" or health.get("recovery") != "ok"
            or health.get("origin_main") != "current" or health.get("errors") != []):
        raise ObservationError("one or more required sources are unavailable")
    if recovery.get("remote_query_read_only") is not True or recovery.get("git_fetch_performed") is not False:
        raise ObservationError("recovery evidence does not match the read-only source contract")
    if not isinstance(source.get("packets"), list) or not isinstance(dispatch.get("packets"), list):
        raise ObservationError("complete active packet inventory is unavailable")
    if not isinstance(recovery.get("items"), list):
        raise ObservationError("recovery inventory is unavailable")

    source_revision = source.get("origin_main_sha")
    cached_sha = origin.get("cached_sha")
    remote_sha = origin.get("remote_sha")
    if (not isinstance(source_revision, str) or not SHA_RE.fullmatch(source_revision)
            or source_revision != cached_sha or source_revision != remote_sha
            or recovery.get("cached_origin_main") != source_revision
            or recovery.get("remote_main") != source_revision
            or origin.get("freshness") != "current"):
        raise ObservationError("origin/main evidence is stale or conflicting")

    snapshot_time = _timestamp(source.get("generated_utc"))
    recovery_time = _timestamp(recovery.get("generated_utc"))
    if snapshot_time > now or recovery_time > now or recovery_time > snapshot_time:
        raise ObservationError("source timestamp is in the future")
    if (now - snapshot_time).total_seconds() > max_age or (now - recovery_time).total_seconds() > max_age:
        raise ObservationError("source observation is stale")
    return source, dispatch, recovery, health, snapshot_time, recovery_time


def _build_packet_rows(source: dict, dispatch: dict) -> tuple[list[dict], dict[str, int], dict[str, dict], int, int, set[str]]:
    audit_rows = dispatch["packets"]
    admin_rows = source["packets"]
    raw_count = dispatch.get("raw_active_markdown_count")
    managed_count = dispatch.get("managed_packet_count")
    claimable_count = dispatch.get("claimable_auto_count")
    if (not _integer(raw_count) or not _integer(managed_count) or not _integer(claimable_count)
            or raw_count < 0 or managed_count < 0 or managed_count > raw_count or claimable_count < 0
            or raw_count != len(audit_rows)):
        raise ObservationError("dispatcher inventory totals are incomplete or inconsistent")

    audit_by_id: dict[str, dict] = {}
    class_counts: dict[str, int] = {}
    claimable_total = 0
    unidentified_count = 0
    aggregate_only_count = 0
    aggregate_only_ids: set[str] = set()
    for row in audit_rows:
        if not isinstance(row, dict):
            raise ObservationError("dispatcher inventory contains a malformed record")
        actual_class = row.get("actual_class")
        status = row.get("status")
        dispatch_mode = row.get("dispatch")
        eligible_now = row.get("eligible_now")
        claim_next = row.get("claim_next_eligible")
        claimed = row.get("claimed")
        wid = row.get("workstream")
        identified = isinstance(wid, str)
        if identified:
            wid = _workstream(wid)
        if not isinstance(actual_class, str) or actual_class not in DISPATCH_CLASSES:
            raise ObservationError("dispatcher inventory contains an unsupported classification")
        if any(type(value) is not bool for value in (eligible_now, claim_next, claimed)):
            raise ObservationError("dispatcher eligibility evidence is incomplete")
        class_counts[actual_class] = class_counts.get(actual_class, 0) + 1
        claimable_total += int(claim_next)

        if identified:
            if wid in audit_by_id:
                raise ObservationError("duplicate workstream identity in dispatcher inventory")
            audit_by_id[wid] = row
            state_valid = (
                isinstance(status, str) and status in {"draft", "ready", "in_progress", "blocked"}
                and isinstance(dispatch_mode, str) and dispatch_mode in {"auto", "manual"}
                and row.get("kind") in {"implementation", "review", "correction"}
            )
            if not state_valid:
                if actual_class != "invalid_recovery" or eligible_now or claim_next or claimed:
                    raise ObservationError("malformed identified dispatcher record is not safely aggregate-only")
                aggregate_only_count += 1
                aggregate_only_ids.add(wid)
            continue
        if (actual_class != "invalid_recovery" or eligible_now or claim_next or claimed):
            raise ObservationError("unidentified dispatcher record has contradictory identity or eligibility evidence")
        unidentified_count += 1
        aggregate_only_count += 1

    if claimable_total != claimable_count:
        raise ObservationError("dispatcher claimable aggregate does not reconcile")

    admin_by_id: dict[str, dict] = {}
    for row in admin_rows:
        if not isinstance(row, dict):
            raise ObservationError("task-administrator inventory contains a malformed record")
        wid = _workstream(row.get("workstream"))
        if wid in admin_by_id:
            raise ObservationError("duplicate workstream identity in task-administrator inventory")
        admin_by_id[wid] = row
    if set(audit_by_id) != set(admin_by_id) or len(admin_rows) != len(audit_by_id):
        raise ObservationError("dispatcher and task-administrator inventories conflict")

    supplied_classes = dispatch.get("class_counts")
    if not isinstance(supplied_classes, dict):
        raise ObservationError("dispatcher class totals are unavailable")
    normalized_classes = {}
    for label, count in supplied_classes.items():
        if not isinstance(label, str) or label not in DISPATCH_CLASSES or not _integer(count) or count < 0:
            raise ObservationError("dispatcher class totals are malformed")
        normalized_classes[label] = count
    if normalized_classes != class_counts:
        raise ObservationError("dispatcher class totals do not reconcile")

    result = []
    for wid in sorted(audit_by_id):
        row = audit_by_id[wid]
        admin = admin_by_id[wid]
        actual_class = row.get("actual_class")
        kind = row.get("kind")
        status = row.get("status")
        dispatch_mode = row.get("dispatch")
        eligible_now = row.get("eligible_now")
        claim_next = row.get("claim_next_eligible")
        claimed = row.get("claimed")
        if kind not in {"implementation", "review", "correction"}:
            raise ObservationError("dispatcher inventory contains an unsupported classification")
        if (admin.get("classification") != actual_class
                or admin.get("eligibility") != ("eligible" if claim_next else "blocked")
                or admin.get("claimed") is not claimed):
            raise ObservationError("task-administrator and dispatcher evidence conflict")
        state_valid = (
            isinstance(status, str) and status in {"draft", "ready", "in_progress", "blocked"}
            and isinstance(dispatch_mode, str) and dispatch_mode in {"auto", "manual"}
            and kind in {"implementation", "review", "correction"}
        )
        if not state_valid:
            continue

        dependencies = row.get("dependencies")
        if not isinstance(dependencies, list):
            raise ObservationError("dependency evidence is unavailable")
        safe_dependencies = []
        for value in dependencies:
            dependency = _workstream(value)
            if dependency not in aggregate_only_ids:
                safe_dependencies.append(dependency)
        if len(set(safe_dependencies)) != len(safe_dependencies):
            raise ObservationError("duplicate dependency identity")
        pair_id = row.get("paired_review_workstream")
        target_id = row.get("review_target_workstream")
        if pair_id is not None:
            pair_id = _workstream(pair_id)
        if target_id is not None:
            target_id = _workstream(target_id)
        admin_pair = admin.get("review_workstream")
        if isinstance(admin_pair, str) and admin_pair.lower() == "none":
            admin_pair = None
        elif admin_pair is not None:
            admin_pair = _workstream(admin_pair)
        if pair_id != admin_pair:
            raise ObservationError("paired review evidence conflicts")
        if pair_id in aggregate_only_ids:
            pair_id = None
        if target_id in aggregate_only_ids:
            target_id = None

        category = admin.get("category_id")
        if category is not None and (not isinstance(category, str) or not ID_RE.fullmatch(category)):
            raise ObservationError("packet category identity is unsafe")
        result.append({
            "workstream": wid,
            "category_id": category,
            "kind": kind,
            "status": status,
            "dispatch": dispatch_mode,
            "classification": actual_class,
            "claim_eligibility": {"eligible_now": eligible_now,
                                  "claim_next_eligible": claim_next},
            "claimed": claimed,
            "eligibility_reason_codes": _reason_codes(row.get("reasons")),
            "dependency_workstreams": sorted(safe_dependencies),
            "paired_review_workstream": pair_id,
            "review_target_workstream": target_id,
            "review_acceptance": "not_observed",
            "process_evidence": _process_evidence(admin.get("process_evidence")),
        })
    return result, class_counts, audit_by_id, unidentified_count, aggregate_only_count, aggregate_only_ids

def _schema_value_type(value: Any, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "integer":
        return type(value) is int
    if expected == "number":
        return type(value) in {int, float}
    if expected == "boolean":
        return type(value) is bool
    if expected == "null":
        return value is None
    return False


def _validate_schema(value: Any, schema: dict, location: str = "$ ") -> None:
    expected = schema.get("type")
    if expected is not None:
        types = expected if isinstance(expected, list) else [expected]
        if not any(_schema_value_type(value, item) for item in types):
            raise ObservationError("observation does not match the published schema")
    if "const" in schema and value != schema["const"]:
        raise ObservationError("observation does not match the published schema")
    if "enum" in schema and value not in schema["enum"]:
        raise ObservationError("observation does not match the published schema")
    if isinstance(value, str):
        if "pattern" in schema and not re.fullmatch(schema["pattern"], value):
            raise ObservationError("observation does not match the published schema")
        if "format" in schema and schema["format"] == "date-time":
            _timestamp(value)
        if "maxLength" in schema and len(value) > schema["maxLength"]:
            raise ObservationError("observation does not match the published schema")
    if type(value) in {int, float}:
        if "minimum" in schema and value < schema["minimum"]:
            raise ObservationError("observation does not match the published schema")
    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0) or len(value) > schema.get("maxItems", MAX_INPUT_BYTES):
            raise ObservationError("observation does not match the published schema")
        if schema.get("uniqueItems"):
            canonical = [json.dumps(item, sort_keys=True, separators=(",", ":")) for item in value]
            if len(canonical) != len(set(canonical)):
                raise ObservationError("observation does not match the published schema")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for index, item in enumerate(value):
                _validate_schema(item, item_schema, f"{location}[{index}]")
    if isinstance(value, dict):
        required = schema.get("required", [])
        if any(key not in value for key in required):
            raise ObservationError("observation does not match the published schema")
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False and any(key not in properties for key in value):
            raise ObservationError("observation does not match the published schema")
        for key, item in value.items():
            child = properties.get(key)
            if isinstance(child, dict):
                _validate_schema(item, child, f"{location}.{key}")


def validate_observation(document: Any) -> None:
    """Validate a document against the colocated strict JSON Schema subset."""
    try:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ObservationError("published observation schema is unavailable") from exc
    if not isinstance(schema, dict) or schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        raise ObservationError("published observation schema is invalid")
    _validate_schema(document, schema)
    scope = document["scope"]
    packets = document["packets"]
    coverage = document["coverage"]
    raw_count = scope["active_packet_records"]
    managed_count = scope["managed_packet_records"]
    detailed_count = scope["detailed_packet_records"]
    identified_count = scope["distinct_workstreams"]
    unidentified_count = scope["unidentified_packet_records"]
    aggregate_only_count = scope["aggregate_only_packet_records"]
    malformed_count = aggregate_only_count - unidentified_count
    if (managed_count > raw_count or detailed_count != len(packets)
            or identified_count + unidentified_count != raw_count
            or detailed_count + aggregate_only_count != raw_count
            or malformed_count < 0
            or identified_count < detailed_count
            or identified_count != len({row["workstream"] for row in packets}) + malformed_count
            or coverage["raw_dispatch_inventory"] != "complete"
            or coverage["active_inventory"] != ("partial" if aggregate_only_count else "complete")
            or (("unidentified_packet_records_aggregate_only" in coverage["limitations"]) != bool(unidentified_count))
            or (("malformed_packet_records_aggregate_only" in coverage["limitations"]) != bool(malformed_count))
            or sum(item["packet_count"] for item in document["classification_counts"]) != raw_count
            or sum(row["claim_eligibility"]["claim_next_eligible"] for row in packets)
               != scope["claimable_auto_packets"]):
        raise ObservationError("observation aggregate coverage is inconsistent")


def export_observation(snapshot: Any, *, now: datetime | None = None,
                       max_source_age_seconds: int) -> dict[str, Any]:
    """Build a sanitized observation from a supplied snapshot without collecting sources."""
    if not _integer(max_source_age_seconds) or max_source_age_seconds <= 0:
        raise ObservationError("an explicit positive maximum source age is required")
    observed = datetime.now(timezone.utc) if now is None else now
    if not isinstance(observed, datetime) or observed.tzinfo is None or observed.utcoffset() is None:
        raise ObservationError("observation clock must be timezone-aware")
    observed = observed.astimezone(timezone.utc)
    source, dispatch, recovery, health, snapshot_time, recovery_time = _validate_sources(
        snapshot, observed, max_source_age_seconds
    )
    records, class_counts, audit_by_id, unidentified_count, aggregate_only_count, _ = _build_packet_rows(source, dispatch)
    managed_count = dispatch["managed_packet_count"]
    scope = {
        "active_packet_records": dispatch["raw_active_markdown_count"],
        "managed_packet_records": managed_count,
        "distinct_workstreams": len(audit_by_id),
        "detailed_packet_records": len(records),
        "claimable_auto_packets": dispatch["claimable_auto_count"],
        "unidentified_packet_records": unidentified_count,
        "aggregate_only_packet_records": aggregate_only_count,
    }
    limitations = [
        "dispatcher_audit_does_not_supply_its_own_timestamp",
        "process_identifiers_and_host_details_are_redacted",
        "review_acceptance_is_not_observed_by_this_snapshot",
    ]
    if unidentified_count:
        limitations.append("unidentified_packet_records_aggregate_only")
    if aggregate_only_count > unidentified_count:
        limitations.append("malformed_packet_records_aggregate_only")
    stable_evidence = {
        "schema": SCHEMA,
        "revision": 1,
        "source_revision": source["origin_main_sha"],
        "source_timestamps": {
            "snapshot_generated_utc": source["generated_utc"],
            "dispatcher_audit_generated_utc": None,
            "recovery_audit_generated_utc": recovery["generated_utc"],
        },
        "source_health": {
            "snapshot": "ok", "dispatch": health["dispatch"],
            "recovery": health["recovery"], "origin_main": health["origin_main"],
        },
        "max_source_age_seconds": max_source_age_seconds,
        "scope": scope,
        "classification_counts": [
            {"classification": label, "packet_count": class_counts[label]}
            for label in sorted(class_counts)
        ],
        "packets": records,
        "coverage": {
            "active_inventory": "partial" if aggregate_only_count else "complete",
            "raw_dispatch_inventory": "complete",
            "limitations": limitations,
        },
    }
    digest = hashlib.sha256(json.dumps(stable_evidence, sort_keys=True,
                                       separators=(",", ":"), ensure_ascii=True).encode("ascii")).hexdigest()
    result = {
        **stable_evidence,
        "observed_at": observed.isoformat(timespec="seconds").replace("+00:00", "Z"),
        "freshness": {
            "state": "fresh",
            "max_source_age_seconds": max_source_age_seconds,
            "snapshot_age_seconds": int((observed - snapshot_time).total_seconds()),
            "dispatcher_audit_age_seconds": None,
            "recovery_audit_age_seconds": int((observed - recovery_time).total_seconds()),
        },
        "evidence_sha256": digest,
    }
    validate_observation(result)
    return result


def _read_snapshot(input_name: str) -> Any:
    try:
        if input_name == "-":
            raw = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
        else:
            path = Path(input_name)
            if not path.is_file() or path.stat().st_size > MAX_INPUT_BYTES:
                raise ObservationError("input snapshot is unavailable or exceeds the size limit")
            with path.open("rb") as handle:
                raw = handle.read(MAX_INPUT_BYTES + 1)
    except OSError as exc:
        raise ObservationError("input snapshot is unavailable") from exc
    if len(raw) > MAX_INPUT_BYTES:
        raise ObservationError("input snapshot exceeds the size limit")

    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ObservationError("input snapshot contains duplicate object keys")
            result[key] = value
        return result

    def reject_constant(_value):
        raise ObservationError("input snapshot contains a non-JSON number")

    try:
        return json.loads(raw, object_pairs_hook=unique_object, parse_constant=reject_constant)
    except (UnicodeDecodeError, json.JSONDecodeError, RecursionError) as exc:
        raise ObservationError("input snapshot is not valid JSON") from exc


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="-", help="snapshot JSON file, or - for stdin")
    parser.add_argument("--max-source-age-seconds", type=int, required=True)
    args = parser.parse_args(argv)
    try:
        result = export_observation(
            _read_snapshot(args.input), max_source_age_seconds=args.max_source_age_seconds
        )
    except ObservationError:
        print("wire_observation_export: BLOCKED: source evidence is invalid, stale, incomplete, or unsafe",
              file=sys.stderr)
        return 2
    sys.stdout.write(json.dumps(result, indent=2, sort_keys=True) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
