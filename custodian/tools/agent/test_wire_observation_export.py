"""Focused synthetic tests for the sanitized, read-only WIRE observation exporter."""
from __future__ import annotations

import copy
import contextlib
import io
import json
import subprocess
import tempfile
import sys
import unittest
from datetime import datetime, timezone, timedelta
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import wire_observation_export as wire
import task_administrator as admin


NOW = datetime(2026, 11, 1, 18, 0, tzinfo=timezone.utc)
MAIN = "a" * 40


def packet(workstream, *, kind="implementation", status="ready", dispatch="auto",
           actual_class="ready_auto", eligible=True, claimable=True, reasons=None,
           dependencies=None, paired_review=None, review_target=None, claimed=False):
    return {
        "workstream": workstream,
        "path": "/private/checkout/custodian/docs/secret-packet.md",
        "kind": kind,
        "status": status,
        "dispatch": dispatch,
        "actual_class": actual_class,
        "eligible_now": eligible,
        "claim_next_eligible": claimable,
        "reasons": [] if reasons is None else reasons,
        "dependencies": [] if dependencies is None else dependencies,
        "paired_review_workstream": paired_review,
        "review_target_workstream": review_target,
        "claimed": claimed,
    }


def snapshot():
    dispatch_rows = [
        packet("agent-sample", paired_review="review-agent-sample"),
        packet("review-agent-sample", kind="review", actual_class="dependency_lock_blocked",
               eligible=False, claimable=False,
               reasons=["dependency not archived complete: agent-sample"],
               dependencies=["agent-sample"], review_target="agent-sample"),
    ]
    admin_rows = [
        {"workstream": "agent-sample", "classification": "ready_auto", "eligibility": "eligible",
         "claimed": False, "reasons": [], "review_workstream": "review-agent-sample",
         "review_eligibility": False,
         "review_dispatch_reasons": ["dependency not archived complete: agent-sample"],
         "process_evidence": "UNKNOWN", "category_id": "agent-ops"},
        {"workstream": "review-agent-sample", "classification": "dependency_lock_blocked",
         "eligibility": "blocked", "claimed": False,
         "reasons": ["dependency not archived complete: agent-sample"],
         "review_workstream": None, "review_eligibility": None,
         "review_dispatch_reasons": [], "process_evidence": "UNKNOWN",
         "category_id": "agent-ops"},
    ]
    return {
        "schema": "custodian.task_admin.snapshot.v1",
        "revision": 1,
        "generated_utc": "2026-11-01T17:59:30+00:00",
        "repo": "/private/checkout/CUSTODIAN",
        "origin_main_sha": MAIN,
        "origin_main_evidence": {"cached_sha": MAIN, "remote_sha": MAIN, "freshness": "current"},
        "source_health": {"dispatch": "ok", "recovery": "ok", "origin_main": "current", "errors": []},
        "dispatch": {
            "schema": "custodian.task_packet_queue_audit.v1",
            "raw_active_markdown_count": 2,
            "managed_packet_count": 2,
            "claimable_auto_count": 1,
            "class_counts": {"ready_auto": 1, "dependency_lock_blocked": 1},
            "packets": dispatch_rows,
        },
        "recovery": {
            "schema": "custodian.workstream_recovery_audit.v1",
            "generated_utc": "2026-11-01T17:59:20+00:00",
            "host": "private-host-identifier",
            "boot_id": "private-boot-identifier",
            "remote_query_read_only": True,
            "git_fetch_performed": False,
            "cached_origin_main": MAIN,
            "remote_main": MAIN,
            "items": [],
        },
        "packets": admin_rows,
        "private_prompt": "do not export me",
    }


class WireObservationExportTests(unittest.TestCase):
    def export(self, source=None, *, now=NOW, max_age=120):
        return wire.export_observation(snapshot() if source is None else source,
                                       now=now, max_source_age_seconds=max_age)

    def test_valid_observation_reconciles_counts_and_preserves_source_identity(self):
        result = self.export()
        self.assertEqual(result["schema"], wire.SCHEMA)
        self.assertEqual(result["source_revision"], MAIN)
        self.assertEqual(result["source_timestamps"]["snapshot_generated_utc"],
                         "2026-11-01T17:59:30+00:00")
        self.assertIsNone(result["source_timestamps"]["dispatcher_audit_generated_utc"])
        self.assertEqual(result["scope"]["active_packet_records"], 2)
        self.assertEqual(result["scope"]["distinct_workstreams"], 2)
        self.assertEqual(result["scope"]["managed_packet_records"], 2)
        self.assertEqual(result["classification_counts"], [
            {"classification": "dependency_lock_blocked", "packet_count": 1},
            {"classification": "ready_auto", "packet_count": 1},
        ])
        self.assertEqual(len(result["packets"]), result["scope"]["active_packet_records"])
        wire.validate_observation(result)

    def test_unavailable_process_evidence_stays_unknown_and_claim_is_not_running(self):
        result = self.export()
        row = result["packets"][0]
        self.assertEqual(row["process_evidence"], {"availability": "unknown", "scan_complete": None})
        self.assertNotIn("running", json.dumps(result).lower())
        self.assertFalse(row["claimed"])

    def test_complete_empty_audit_is_zero_but_unavailable_audit_fails(self):
        empty = snapshot()
        empty["dispatch"].update(raw_active_markdown_count=0, managed_packet_count=0,
                                 claimable_auto_count=0, class_counts={}, packets=[])
        empty["packets"] = []
        result = self.export(empty)
        self.assertEqual(result["scope"]["active_packet_records"], 0)
        self.assertEqual(result["scope"]["distinct_workstreams"], 0)
        unavailable = snapshot()
        unavailable["dispatch"] = None
        unavailable["source_health"]["dispatch"] = "unknown"
        with self.assertRaises(wire.ObservationError):
            self.export(unavailable)

    def test_failed_or_incomplete_dispatch_audit_fails_closed(self):
        for mutate in (
            lambda s: s["source_health"].update(dispatch="failed"),
            lambda s: s["dispatch"].update(raw_active_markdown_count=3),
            lambda s: s["dispatch"].update(claimable_auto_count=2),
            lambda s: s["dispatch"].update(class_counts={"ready_auto": 2}),
            lambda s: s["dispatch"].update(packets=s["dispatch"]["packets"][:1]),
        ):
            source = snapshot()
            mutate(source)
            with self.subTest(mutate=mutate), self.assertRaises(wire.ObservationError):
                self.export(source)

    def test_stale_or_future_snapshot_and_recovery_timestamps_fail(self):
        source = snapshot()
        with self.assertRaises(wire.ObservationError):
            self.export(source, now=NOW, max_age=10)
        source = snapshot()
        source["recovery"]["generated_utc"] = "2026-11-01T18:01:00+00:00"
        with self.assertRaises(wire.ObservationError):
            self.export(source)

    def test_mismatched_origin_main_fails(self):
        source = snapshot()
        source["recovery"]["remote_main"] = "b" * 40
        source["origin_main_evidence"]["freshness"] = "stale_or_unknown"
        source["source_health"]["origin_main"] = "stale_or_unknown"
        with self.assertRaises(wire.ObservationError):
            self.export(source)

    def test_missing_or_invalid_source_evidence_fails(self):
        for key in ("dispatch", "recovery", "packets", "origin_main_evidence"):
            source = snapshot()
            del source[key]
            with self.subTest(key=key), self.assertRaises(wire.ObservationError):
                self.export(source)
        source = snapshot()
        source["source_health"]["errors"] = ["private failure details"]
        with self.assertRaises(wire.ObservationError):
            self.export(source)

    def test_duplicate_workstream_identity_and_inconsistent_admin_rows_fail(self):
        source = snapshot()
        source["dispatch"]["packets"][1]["workstream"] = "agent-sample"
        source["packets"][1]["workstream"] = "agent-sample"
        with self.assertRaises(wire.ObservationError):
            self.export(source)
        source = snapshot()
        source["packets"].pop()
        with self.assertRaises(wire.ObservationError):
            self.export(source)
        source = snapshot()
        source["packets"][0]["category_id"] = "/private/category"
        with self.assertRaises(wire.ObservationError):
            self.export(source)

    def test_redaction_allowlist_excludes_paths_credentials_prompts_and_host_ids(self):
        source = snapshot()
        source["dispatch"]["packets"][0]["reasons"] = ["unknown: token=PRIVATE_TOKEN"]
        source["recovery"]["items"] = [{
            "workstream": "agent-sample", "classification": "LIVE",
            "live_processes": [{"pid": 123, "command_line": "private prompt"}],
            "process_scan_complete": True,
            "host": "private-host-identifier", "worktree": "/private/checkout",
        }]
        source["packets"][0]["process_evidence"] = [{
            "classification": "LIVE", "process_scan_complete": True,
            "live_processes": [{"pid": 123, "command_line": "private prompt"}],
        }]
        result = self.export(source)
        encoded = json.dumps(result, sort_keys=True)
        for secret in ("/private", "PRIVATE_TOKEN", "private prompt", "private-host-identifier",
                       "private-boot-identifier", "command_line", "\"pid\"", "private_prompt",
                       "custodian/docs/secret-packet.md"):
            self.assertNotIn(secret, encoded)
        self.assertIn("unclassified_reason", result["packets"][0]["eligibility_reason_codes"])
        self.assertEqual(result["packets"][0]["process_evidence"],
                         {"availability": "available", "scan_complete": True})

    def test_digest_is_stable_across_export_times(self):
        first = self.export(now=NOW)
        second = self.export(now=NOW + timedelta(seconds=15))
        self.assertNotEqual(first["observed_at"], second["observed_at"])
        self.assertEqual(first["evidence_sha256"], second["evidence_sha256"])

    def test_export_never_calls_collector_or_subprocess(self):
        with patch.object(admin, "collect", side_effect=AssertionError("collector called")) as collect, \
             patch.object(subprocess, "run", side_effect=AssertionError("subprocess called")) as run:
            self.export()
        collect.assert_not_called()
        run.assert_not_called()

    def test_snapshot_reader_rejects_duplicate_keys_and_oversize_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "snapshot.json"
            path.write_text('{"schema":"one","schema":"two"}', encoding="utf-8")
            with self.assertRaises(wire.ObservationError):
                wire._read_snapshot(str(path))
            path.write_text("x" * 17, encoding="utf-8")
            with patch.object(wire, "MAX_INPUT_BYTES", 16), self.assertRaises(wire.ObservationError):
                wire._read_snapshot(str(path))

    def test_cli_exports_supplied_snapshot_without_collector(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "input.json"
            source = snapshot()
            current = datetime.now(timezone.utc)
            source["generated_utc"] = (current - timedelta(seconds=10)).isoformat(timespec="seconds")
            source["recovery"]["generated_utc"] = (current - timedelta(seconds=20)).isoformat(timespec="seconds")
            path.write_text(json.dumps(source), encoding="utf-8")
            output = io.StringIO()
            with patch.object(admin, "collect", side_effect=AssertionError("collector called")), \
                 patch.object(subprocess, "run", side_effect=AssertionError("subprocess called")), \
                 contextlib.redirect_stdout(output):
                code = wire.main(["--input", str(path), "--max-source-age-seconds", "120"])
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(output.getvalue())["schema"], wire.SCHEMA)

    def test_invalid_schema_and_additional_fields_are_rejected(self):
        result = self.export()
        wire.validate_observation(result)
        invalid = copy.deepcopy(result)
        invalid["private_path"] = "/private"
        with self.assertRaises(wire.ObservationError):
            wire.validate_observation(invalid)
        invalid = copy.deepcopy(result)
        invalid["packets"][0]["dispatch"] = "invented"
        with self.assertRaises(wire.ObservationError):
            wire.validate_observation(invalid)
        schema_path = Path(wire.SCHEMA_PATH)
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        self.assertEqual(schema["additionalProperties"], False)
        self.assertEqual(schema["properties"]["schema"]["const"], wire.SCHEMA)

    def test_failed_review_evidence_is_not_promoted_to_acceptance(self):
        result = self.export()
        self.assertNotIn("review_outcome", result["packets"][0])
        self.assertEqual(result["packets"][0]["review_acceptance"], "not_observed")
        self.assertEqual(result["packets"][1]["review_acceptance"], "not_observed")
        self.assertFalse(result["packets"][1]["claim_eligibility"]["claim_next_eligible"])


if __name__ == "__main__":
    unittest.main()
