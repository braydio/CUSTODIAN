#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run_validation as runner


def test_item(test_id: str, owner: str) -> dict:
    return {"id": test_id, "type": "python", "script": "unused.py", "tier": "unit",
            "owners": [owner], "tags": ["validation"]}


def main() -> int:
    manifest = "custodian/tools/validation/validation_manifest.json"
    npa = test_item("npa_showcase_existing_enemy", "custodian/tools/validation/npa_showcase_existing_enemy_smoke.gd")
    baseline = {"schema_version": 1, "coverage_excludes": [], "tests": [npa]}
    alpine = test_item("procgen_alpine_cliff_presentation", "custodian/tools/validation/alpine_smoke.py")
    current = {"schema_version": 1, "coverage_excludes": [], "tests": [npa, alpine]}
    changed_ids, changed = runner.manifest_change_selection([npa, alpine], base_payload=baseline, current_payload=current)
    selected = runner.select_changed_tests([npa, alpine], [manifest], manifest_ids=changed_ids, manifest_changed=changed)
    assert changed_ids == {"procgen_alpine_cliff_presentation"}
    assert {item["id"] for item in selected} == {"procgen_alpine_cliff_presentation"}

    edited_npa = dict(npa, timeout_sec=40)
    npa_changed, _ = runner.manifest_change_selection([edited_npa, alpine], base_payload=baseline, current_payload={
        "schema_version": 1, "coverage_excludes": [], "tests": [edited_npa, alpine]
    })
    selected = runner.select_changed_tests([edited_npa, alpine], [manifest], manifest_ids=npa_changed, manifest_changed=True)
    assert "npa_showcase_existing_enemy" in {item["id"] for item in selected}

    selected = runner.select_changed_tests([npa], ["custodian/tools/validation/npa_showcase_existing_enemy_smoke.gd"])
    assert {item["id"] for item in selected} == {"npa_showcase_existing_enemy"}

    for invalid in (
        {"schema_version": 2, "coverage_excludes": [], "tests": [npa]},
        {"schema_version": 1, "coverage_excludes": ["new/**"], "tests": [npa]},
    ):
        try:
            runner.manifest_change_selection([npa], base_payload=baseline, current_payload=invalid)
            raise AssertionError("global manifest change accepted")
        except runner.ManifestError:
            pass
    try:
        runner.manifest_change_selection([], base_payload=baseline,
                                         current_payload={"schema_version": 1, "coverage_excludes": [], "tests": []})
        raise AssertionError("removed test accepted")
    except runner.ManifestError:
        pass
    try:
        runner.manifest_change_selection([], base_payload=baseline,
                                         current_payload={"schema_version": 1, "coverage_excludes": [], "tests": [npa, npa]})
        raise AssertionError("duplicate test id accepted")
    except runner.ManifestError:
        pass
    for malformed in ('{"schema_version":1,"schema_version":1,"tests":[]}', '{malformed'):
        try:
            runner.parse_manifest_json(malformed)
            raise AssertionError("ambiguous or malformed JSON accepted")
        except (runner.ManifestError, json.JSONDecodeError):
            pass

    failed = runner.execute_tiered(
        [{"id": "sentinel", "tier": "unit", "selection_reasons": []}], [],
        lambda test, _patterns: {"id": test["id"], "tier": "unit", "status": "failed"},
    )
    assert failed[0]["status"] == "failed"
    print("validation_manifest_diff_selection_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
