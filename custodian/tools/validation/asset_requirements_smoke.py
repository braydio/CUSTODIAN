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

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "tools/assets"
sys.path.insert(0, str(ASSETS))

import asset as cli
from asset_catalog import file_hash
from asset_contract import load_all_families, parse_family
from asset_requirements import (
    check_markdown,
    evaluate_registry,
    migrate_markdown,
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
            "waddle": {"layer": "body", "action_group": "locomotion", "variant": "waddle", "animation": True},
            "scurry": {"layer": "body", "action_group": "locomotion", "variant": "scurry", "animation": True},
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
    mapped = {"id": "mapped-row", "section": "Ambient", "title": "Mapped row", "target": "path", "purpose": "why", "notes": "note", "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle"}, {"family": family.id, "state": "scurry"}]}}
    directional = {"id": "south-only", "section": "Ambient", "title": "South only", "target": "path", "purpose": "why", "notes": "note", "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle", "directions": ["s"]}]}}
    registry = {"schema": "custodian.asset_requirements.v1", "requirements": [manual, mapped, directional]}
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
            assert initial[mapped["id"]]["status"] == "needed"
            assert initial[directional["id"]]["status"] == "needed"
            catalog_add(project, family.id, "waddle", "n")
            state = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert state[manual["id"]]["status"] == "partial"
            assert state[mapped["id"]]["status"] == "partial"
            assert state[directional["id"]]["status"] == "needed"
            catalog_add(project, family.id, "waddle", "s")
            state = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert state[directional["id"]]["status"] == "fulfilled"
            assert state[mapped["id"]]["status"] == "partial"
            catalog_add(project, family.id, "scurry", "w")
            state = {item["id"]: item for item in evaluate_registry(registry, families, project)}
            assert state[mapped["id"]]["status"] == "fulfilled"

            fulfilled_registry = {"schema": registry["schema"], "requirements": [manual, {**directional, "fulfillment": {"type": "asset_v2", "targets": [{"family": family.id, "state": "waddle", "directions": ["s"]}]}}]}
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
        finally:
            cli.PROJECT_DIR, cli.INBOX_ROOT, cli.FAMILIES_DIR = old_project, old_inbox, old_families

    legacy = """# Legacy\n\n## Fixture\n\n| Status | Asset | Target Path | Purpose | Notes |\n|---|---|---|---|---|\n| needed | Pipe row | `one.png` | why | `tree|shrub` note |\n\n## Tiled fixture\n\n| Status | Template | Target canvas |\n|---|---|---|\n| partial | `room.tmj` | 8x8 tiles |\n"""
    migrated = migrate_markdown(legacy)
    source_rows = sum(line.startswith("| needed |") or line.startswith("| partial |") for line in legacy.splitlines())
    assert len(migrated["requirements"]) == source_rows == 2
    assert migrated["requirements"][0]["notes"] == "`tree|shrub` note"
    assert migrated["requirements"][1]["target"] == "`room.tmj`"

    print("PASS: requirement schema, manual tracking, derived states/directions, projection, CLI JSON, and lossless migration parser")


if __name__ == "__main__":
    main()
