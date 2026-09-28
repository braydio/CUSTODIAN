#!/usr/bin/env python3
"""Focused acceptance for registry validation, status derivation, and projection."""
from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "tools/assets"
sys.path.insert(0, str(ASSETS))

import asset as cli
from asset_catalog import file_hash
from asset_contract import load_all_families, parse_family
from asset_requirements import (
    check_markdown,
    evaluate_registry,
    render_markdown,
    validate_registry,
    write_markdown,
)
from asset_doctor import _check_requirements, DoctorIssue


def fixture_family():
    return parse_family({
        "schema": "custodian.asset_family.v2",
        "id": "ambient_baby_opossum",
        "kind": "ambient_creature",
        "runtime": {"domain": "sprites/ambient_creatures", "owner": "baby_opossum"},
        "canvas": {"width": 96, "height": 96},
        "direction_policy": "4dir",
        "auto_mirror": True,
        "states": {
            "waddle": {"layer": "body", "action_group": "locomotion", "variant": "waddle", "animation": True, "required": True},
            "scurry": {"layer": "body", "action_group": "locomotion", "variant": "scurry", "animation": True, "required": True},
        },
        "consumers": [],
    })


def catalog_add(project: Path, family_id: str, state: str, direction: str) -> None:
    relative = Path("content/sprites/ambient_creatures/runtime") / f"{state}_{direction}.png"
    output = project / relative
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(f"{state}/{direction}".encode())
    catalog_path = project / "content/metadata/assets/generated/asset_catalog.generated.json"
    catalog_path.parent.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(catalog_path.read_text()) if catalog_path.exists() else {"schema": "custodian.asset_catalog.v2", "families": {}}
    family = catalog["families"].setdefault(family_id, {"assets": {}})
    key = f"{state}::{direction}"
    family["assets"][key] = {
        "state_id": state,
        "direction": direction,
        "path": relative.as_posix(),
        "sha256": file_hash(output),
        "provenance": "authored",
    }
    catalog_path.write_text(json.dumps(catalog), encoding="utf-8")


def main() -> None:
    family = fixture_family()
    families = {family.id: family}
    manual = {"id": "manual-row", "section": "Manual", "title": "Manual row", "target": "path", "purpose": "why", "notes": "note", "fulfillment": {"type": "manual", "status": "partial"}}
    completed = {"id": "manual-complete", "section": "Manual", "title": "Completed manual row", "target": "path", "purpose": "why", "notes": "history", "fulfillment": {"type": "manual", "status": "fulfilled"}}
    mapped = {"id": "mapped-row", "section": "Ambient", "title": "Mapped row", "target": "path", "purpose": "why", "notes": "note", "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle"}, {"family": family.id, "state": "scurry"}]}}
    directional = {"id": "south-only", "section": "Ambient", "title": "South only", "target": "path", "purpose": "why", "notes": "note", "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle", "directions": ["s"]}]}}
    source_actions = {"id": "source-actions", "section": "Ambient", "title": "Source-aware actions", "target": "path", "purpose": "why", "notes": "note", "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle", "directions": ["e"]}, {"family": family.id, "state": "scurry", "directions": ["e"]}]}}
    registry = {"schema": "custodian.asset_requirements.v1", "section_notes": {"Manual": "Keep fulfilled history here."}, "requirements": [manual, completed, mapped, directional, source_actions]}
    assert validate_registry(registry, families) == []

    invalids = []
    invalids.append(validate_registry({"schema": "unknown", "requirements": []}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [manual, manual]}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**manual, "fulfillment": {"type": "bogus", "status": "needed"}}]}, families))
    for broken_target in (
        {"family": "missing_family", "state": "waddle"},
        {"family": family.id, "state": "missing_state"},
        {"family": family.id, "state": "waddle", "directions": ["omni"]},
    ):
        invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**mapped, "fulfillment": {"type": "asset_v2", "targets": [broken_target]}}]}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**mapped, "fulfillment": {"type": "asset_v2", "targets": []}}]}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**mapped, "id": "Not_Kebab", "section": " ", "title": "", "target": 4, "purpose": None, "notes": []}]}, families))
    duplicate_directions = [{"family": family.id, "state": "waddle", "directions": ["s", "n"]}, {"family": family.id, "state": "waddle", "directions": ["n", "s"]}]
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**mapped, "fulfillment": {"type": "asset_v2", "targets": duplicate_directions}}]}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "section_notes": {"Missing": "note"}, "requirements": [manual]}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "section_notes": {"Manual": 3}, "requirements": [manual]}, families))
    invalids.append(validate_registry({"schema": registry["schema"], "section_notes": [], "requirements": [manual]}, families))
    no_required = parse_family({"schema": "custodian.asset_family.v2", "id": "empty_scope", "kind": "ambient_creature", "runtime": {"domain": "sprites/ambient_creatures", "owner": "empty_scope"}, "canvas": {"width": 32, "height": 32}, "direction_policy": "omni", "states": {"idle": {"layer": "body", "action_group": "idle", "variant": "idle"}}})
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**mapped, "fulfillment": {"type": "asset_v2", "targets": [{"family": no_required.id, "scope": "required_states"}]}}]}, {no_required.id: no_required}))
    invalids.append(validate_registry({"schema": registry["schema"], "requirements": [{**mapped, "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "scope": "required_states", "directions": ["s"]}]}}]}, families))
    assert all(errors for errors in invalids)

    with tempfile.TemporaryDirectory() as directory:
        repository = Path(directory)
        project = repository / "custodian"
        project.mkdir()
        old_project, old_inbox, old_families = cli.PROJECT_DIR, cli.INBOX_ROOT, cli.FAMILIES_DIR
        cli.PROJECT_DIR = project
        cli.INBOX_ROOT = project / "asset_drop/inbox"
        cli.FAMILIES_DIR = project / "content/metadata/assets/families"
        try:
            initial = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert initial[completed["id"]]["status"] == "fulfilled"
            assert initial[mapped["id"]]["status"] == "needed"
            assert initial[directional["id"]]["status"] == "needed"
            scope = {"id": "scope", "section": "Ambient", "title": "Required states", "target": "all required", "purpose": "all", "notes": "", "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "scope": "required_states"}]}}
            status_module = sys.modules["asset_requirements"]
            with mock.patch.object(status_module, "get_family_status", wraps=status_module.get_family_status) as status_lookup:
                scope_initial = evaluate_registry({"schema": registry["schema"], "requirements": [scope, mapped]}, families, project)
                assert status_lookup.call_count == 1
            scope_evidence = scope_initial[0]["targets_status"][0]
            assert scope_evidence["satisfied_states"] == []
            assert set(scope_evidence["missing_states"]) == {"waddle", "scurry"}
            assert not scope_evidence["source_pending"]
            first_projection = render_markdown(registry, families, project)
            assert "Keep fulfilled history here." in first_projection
            assert "Completed manual row" not in first_projection
            assert first_projection == render_markdown(registry, families, project)
            catalog_add(project, family.id, "waddle", "n")
            state = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert state[manual["id"]]["status"] == "partial"
            scope_after = evaluate_registry({"schema": registry["schema"], "requirements": [scope]}, families, project)[0]["targets_status"][0]
            assert scope_after["satisfied_states"] == ["waddle"]
            assert scope_after["missing_states"] == ["scurry"]
            assert state[mapped["id"]]["status"] == "partial"
            assert state[directional["id"]]["status"] == "needed"
            catalog_add(project, family.id, "waddle", "s")
            state = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert state[directional["id"]]["status"] == "fulfilled"
            assert state[mapped["id"]]["status"] == "partial"
            catalog_add(project, family.id, "scurry", "w")
            state = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert state[mapped["id"]]["status"] == "fulfilled"

            fulfilled_registry = {"schema": registry["schema"], "section_notes": registry["section_notes"], "requirements": [manual, completed, mapped, source_actions, {**directional, "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle", "directions": ["s"]}]}}]}
            projection = render_markdown(fulfilled_registry, families, project)
            assert "Manual row" in projection and "South only" not in projection
            assert any(item["id"] == directional["id"] for item in fulfilled_registry["requirements"])

            registry_path = project / "content/metadata/assets/required_assets.registry.json"
            registry_path.parent.mkdir(parents=True, exist_ok=True)
            registry_path.write_text(json.dumps(fulfilled_registry), encoding="utf-8")
            assert not check_markdown(fulfilled_registry, families, project)
            args = SimpleNamespace(requirement_id=None, write=True, check=False, json=False)
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                assert cli.cmd_needs(args, families) == 0
            generated_path = project.parent / "REQUIRED_ASSETS.md"
            first = generated_path.read_text(encoding="utf-8")
            assert check_markdown(fulfilled_registry, families, project)
            args = SimpleNamespace(requirement_id=None, write=False, check=True, json=False)
            with contextlib.redirect_stdout(io.StringIO()):
                assert cli.cmd_needs(args, families) == 0
            write_markdown(fulfilled_registry, families, project)
            assert generated_path.read_text(encoding="utf-8") == first
            doctor_issues: list[DoctorIssue] = []
            _check_requirements(project, families, doctor_issues)
            assert doctor_issues == []  # absent production art is not a doctor error

            args = SimpleNamespace(requirement_id=None, write=False, check=False, json=True)
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                assert cli.cmd_needs(args, families) == 0
            payload = json.loads(stream.getvalue())
            assert payload["schema"] == "custodian.asset_requirements_cli.v1"
            assert payload["requirements"][0]["fulfillment"]["type"] == "manual"

            args = SimpleNamespace(requirement_id=completed["id"], write=False, check=False, json=False)
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                assert cli.cmd_needs(args, families) == 0
            assert "No production action required" in stream.getvalue()

            args = SimpleNamespace(requirement_id="manual-row", write=True, check=False, json=False)
            with contextlib.redirect_stdout(io.StringIO()):
                assert cli.cmd_needs(args, families) == 2
            args = SimpleNamespace(requirement_id=None, write=True, check=False, json=True)
            with contextlib.redirect_stdout(io.StringIO()):
                assert cli.cmd_needs(args, families) == 2

            args = SimpleNamespace(requirement_id="source-actions", write=False, check=False, json=False)
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                cli.cmd_needs(args, families)
            assert "asset request ambient_baby_opossum" in stream.getvalue()
            inbox = project / "asset_drop/inbox" / family.id
            inbox.mkdir(parents=True, exist_ok=True)
            (inbox / "scurry__e.png").write_bytes(b"staged source")
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                cli.cmd_needs(args, families)
            assert "asset plan ambient_baby_opossum" in stream.getvalue()
            assert "asset request ambient_baby_opossum" in stream.getvalue()

            broken_registry = {"schema": registry["schema"], "requirements": [{**manual, "id": "Bad_ID"}]}
            registry_path.write_text(json.dumps(broken_registry), encoding="utf-8")
            args = SimpleNamespace(requirement_id=None, write=False, check=False, json=True)
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                assert cli.cmd_needs(args, families) == 2
            assert ".id must be a non-empty kebab-case string" in stream.getvalue() and "Traceback" not in stream.getvalue()
            broken_issues: list[DoctorIssue] = []
            _check_requirements(project, families, broken_issues)
            assert broken_issues and all("projection is stale" not in issue.message for issue in broken_issues)
        finally:
            cli.PROJECT_DIR, cli.INBOX_ROOT, cli.FAMILIES_DIR = old_project, old_inbox, old_families

    print("PASS: requirement lifecycle/schema, family scopes/cache, source-aware actions, section notes, CLI validation, and projection")


if __name__ == "__main__":
    main()
