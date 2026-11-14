"""Focused integrity tests for the private WIRE pilot observation boundary."""
from __future__ import annotations

import copy
import sys
import unittest
from datetime import datetime, timezone, timedelta
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_wire_observation_export as exporter_fixtures
import wire_observation_export as exporter
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "iteration"))
import wire_pilot


NOW = exporter_fixtures.NOW


def make_observation(*, partial=False):
    source = exporter_fixtures.snapshot()
    if partial:
        source["dispatch"]["packets"].append(exporter_fixtures.unidentified_packet())
        source["dispatch"]["raw_active_markdown_count"] = 3
        source["dispatch"]["class_counts"]["invalid_recovery"] = 1
    return exporter.export_observation(source, now=NOW, max_source_age_seconds=120)


class WirePilotValidationTests(unittest.TestCase):
    def validate(self, document):
        return wire_pilot.validate_observation(document, exporter, now=NOW,
                                               max_observation_age_seconds=120)

    def test_partial_detail_is_accepted_only_with_complete_raw_inventory(self):
        document = make_observation(partial=True)
        self.assertEqual(document["coverage"]["active_inventory"], "partial")
        self.assertEqual(document["coverage"]["raw_dispatch_inventory"], "complete")
        with patch.object(wire_pilot, "rclone", side_effect=AssertionError("network call")), \
             patch.object(wire_pilot, "upload_bytes", side_effect=AssertionError("publication")):
            self.assertTrue(self.validate(document))

    def test_complete_detail_remains_accepted(self):
        document = make_observation()
        self.assertEqual(document["coverage"]["active_inventory"], "complete")
        self.assertTrue(self.validate(document))

    def test_incomplete_missing_or_unsupported_coverage_is_rejected(self):
        for mutate in (
            lambda d: d["coverage"].update(raw_dispatch_inventory="partial"),
            lambda d: d["coverage"].pop("raw_dispatch_inventory"),
            lambda d: d["coverage"].update(active_inventory="unknown"),
        ):
            document = make_observation(partial=True)
            mutate(document)
            with self.subTest(coverage=document["coverage"]), self.assertRaises(wire_pilot.PilotError):
                self.validate(document)

    def test_schema_aggregate_identity_health_digest_and_freshness_gates_remain(self):
        changes = (
            lambda d: d["scope"].update(aggregate_only_packet_records=9),
            lambda d: d["packets"][0].update(workstream="../unsafe"),
            lambda d: d["source_health"].update(dispatch="error"),
            lambda d: d.update(evidence_sha256="0" * 64),
        )
        for mutate in changes:
            document = make_observation(partial=True)
            mutate(document)
            with self.subTest(document=document), self.assertRaises(wire_pilot.PilotError):
                self.validate(document)

        stale = make_observation(partial=True)
        with self.assertRaises(wire_pilot.PilotError):
            wire_pilot.validate_observation(stale, exporter,
                now=NOW + timedelta(seconds=121), max_observation_age_seconds=120)


if __name__ == "__main__":
    unittest.main()

