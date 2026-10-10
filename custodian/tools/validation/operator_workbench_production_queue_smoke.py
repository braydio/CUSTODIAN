#!/usr/bin/env python3
"""Derived queue totals, deterministic NEXT, filters, and fail-closed review proof."""
from __future__ import annotations

import sys
import tempfile
from dataclasses import replace
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "custodian/tools/operator"), str(ROOT / "custodian/tools/operator/ui"),
                str(ROOT / "custodian/tools/pipelines")]

import operator_animation_targets
import operator_2_5d_review
from ui.service import WorkbenchService


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="operator_queue_workspace_") as raw:
        service = WorkbenchService(repo_root=ROOT, workspace_root=Path(raw) / ".ai/operator_animation_workbench")
        queue = service.animation_queue("ALL")
        assert queue["families"] == 69 and queue["direction_slots"] == 552
        assert queue["priority_counts"] == {"P0": 4, "P1": 65}
        assert sum(queue["primary_counts"].values()) == 552
        assert queue["primary_counts"]["VERIFIED"] == 0
        assert queue["primary_counts"]["CANONICAL SOURCE"] == 8
        assert queue["primary_counts"]["LOCAL CANONICAL"] == 0
        assert queue["next"]["id"].endswith("unarmed/posture/idle_relaxed_01")
        assert queue["next"]["direction"] == "n"
        assert queue["next"]["selection"].authoring_identity.endswith("idle_relaxed_01/n")
        next_row = service.animation_queue("NEXT")["rows"][0]
        assert next_row["id"] == queue["next"]["id"]
        assert next_row["next_selection"].authoring_identity == queue["next"]["selection"].authoring_identity

        expected_minimums = {"MISSING": 0, "INTAKE": 1, "EDITING": 0, "REVIEW": 0,
                             "STALE": 0, "FALLBACK/PROJECTED": 1, "VERIFIED": 0, "PUBLISHED": 0}
        for name, minimum in expected_minimums.items():
            snapshot = service.animation_queue(name)
            assert len(snapshot["rows"]) >= minimum
            if name == "PUBLISHED":
                assert not snapshot["published_supported"] and snapshot["rows"] == []
        assert len(service.animation_queue("INTAKE")["rows"]) == 1
        discover = service.discover_browser_records
        service.discover_browser_records = lambda **_kwargs: (_ for _ in ()).throw(ValueError("unsupported legacy filename"))
        try:
            unavailable = service.animation_queue("ALL")
            assert unavailable["families"] == 69 and unavailable["direction_slots"] == 552
            assert unavailable["legacy_projection"] == {
                "status": "UNAVAILABLE", "reason": "unsupported legacy filename"}
        finally:
            service.discover_browser_records = discover

        # A genuinely blocked first direction is visibly skipped for the next
        # direction in the same authored family; the rank/priority never move.
        original_project = operator_animation_targets.project_targets
        def stale_north(*args, **kwargs):
            rows = original_project(*args, **kwargs)
            return tuple(replace(row, stale_reference=True)
                         if row.selection.action == "idle_relaxed_01" and row.selection.direction == "n" else row
                         for row in rows)
        operator_animation_targets.project_targets = stale_north
        try:
            blocked = service.animation_queue("NEXT")
            assert blocked["next"]["direction"] == "ne"
            assert blocked["next"]["rank"] == 1 and blocked["next"]["priority"] == "P0"
            assert blocked["skipped_before_next"] == [{
                "target": blocked["next"]["id"],
                "reason": "n: profile/reference authority is stale",
            }]
        finally:
            operator_animation_targets.project_targets = original_project

        # Current receipts, not cached plan/source coverage, own verification.
        original_receipt = operator_2_5d_review.Operator2DReview.current_receipt
        def verified_idle(self, selection):
            if selection.action == "idle_relaxed_01":
                return {"runtime_verified": True, "receipt_sha256": "live-fixture"}
            return original_receipt(self, selection)
        operator_2_5d_review.Operator2DReview.current_receipt = verified_idle
        try:
            verified = service.animation_queue("VERIFIED")
            assert len(verified["rows"]) == 1 and verified["rows"][0]["complete"]
            assert verified["rows"][0]["verified"] == 8
            assert service.animation_queue("NEXT")["next"]["id"] != verified["rows"][0]["id"]
        finally:
            operator_2_5d_review.Operator2DReview.current_receipt = original_receipt

    print("operator_workbench_production_queue_smoke: PASS")


if __name__ == "__main__":
    main()
