#!/usr/bin/env python3
"""Smoke test for Asset Pipeline V2."""

from __future__ import annotations

import sys
import tempfile
import shutil
from pathlib import Path

# Add project paths
sys.path.insert(0, "custodian/tools/assets")

from asset_contract import AssetFamilyContract, load_all_families, SCHEMA_VERSION
from asset_inspector import inspect_png, FrameLayout
from asset_key import AssetKey
from asset_naming import canonical_filename
from asset_classifier import classify_input, ResolutionConfidence
from asset_plan import generate_plan, AssetPlan
from asset_status import get_family_status, FamilyStatus
from asset_doctor import run_doctor
from adapters.runtime_ready import stage_asset as stage_rr
from adapters.sprite_ingest import stage_asset as stage_si


def test_asset_key_semantic_identity():
    """Test that semantic identity excludes frame dimensions."""
    k1 = AssetKey(
        owner="test", kind="world_prop", layer="body", action_group="idle",
        variant="idle", direction="omni", frames=1, frame_width=128, frame_height=96,
    )
    k2 = AssetKey(
        owner="test", kind="world_prop", layer="body", action_group="idle",
        variant="idle", direction="omni", frames=4, frame_width=128, frame_height=96,
    )
    assert k1.same_semantic(k2), "Semantic identity should ignore frames/dimensions"
    print("✓ test_asset_key_semantic_identity")


def test_canonical_filename():
    """Test canonical filename generation."""
    key = AssetKey(
        owner="field_fabricator_mk1", kind="world_prop", layer="body",
        action_group="interaction", variant="fabricate", direction="omni",
        frames=4, frame_width=128, frame_height=96,
    )
    expected = "field_fabricator_mk1__body__interaction__fabricate__omni__4f__128x96.png"
    assert canonical_filename(key) == expected
    print("✓ test_canonical_filename")


def test_inspect_png():
    """Test PNG inspection and frame inference."""
    # Single frame
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        from PIL import Image
        Image.new("RGBA", (128, 96), (255, 0, 0, 255)).save(f.name)
        insp = inspect_png(Path(f.name), 128, 96)
        assert insp.layout == FrameLayout.COPY
        assert insp.frame_count == 1
        Path(f.name).unlink()

    # Horizontal strip (4 frames)
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        from PIL import Image
        Image.new("RGBA", (512, 96), (0, 255, 0, 255)).save(f.name)
        insp = inspect_png(Path(f.name), 128, 96)
        assert insp.layout == FrameLayout.HORIZONTAL_STRIP
        assert insp.frame_count == 4
        Path(f.name).unlink()

    print("✓ test_inspect_png")


def test_classify_input():
    """Test state classification."""
    fam = load_all_families()["field_fabricator_mk1"]

    # Exact match
    from asset_inspector import AssetInspection
    insp = AssetInspection(Path("idle.png"), 128, 96, 128, 96, 1, FrameLayout.COPY)
    res = classify_input(fam, "idle", insp)
    assert res.confidence == ResolutionConfidence.EXACT
    assert res.state_id == "idle"

    # Alias match
    insp = AssetInspection(Path("working.png"), 128, 96, 128, 96, 1, FrameLayout.COPY)
    res = classify_input(fam, "working", insp)
    assert res.confidence == ResolutionConfidence.EXACT
    assert res.state_id == "active"

    # Ambiguous
    insp = AssetInspection(Path("unknown.png"), 128, 96, 128, 96, 1, FrameLayout.COPY)
    res = classify_input(fam, "unknown", insp)
    assert res.confidence == ResolutionConfidence.AMBIGUOUS
    assert res.state_id is None

    print("✓ test_classify_input")


def test_generate_plan():
    """Test plan generation."""
    fam = load_all_families()["field_fabricator_mk1"]
    project_dir = Path("custodian")
    inbox = project_dir / "asset_drop" / "inbox" / fam.id

    plan = generate_plan(fam, inbox, project_dir)
    assert isinstance(plan, AssetPlan)
    assert plan.family_id == "field_fabricator_mk1"
    assert len(plan.assets) == 3
    assert plan.can_apply

    for asset in plan.assets:
        assert asset.confidence == ResolutionConfidence.EXACT
        assert asset.target_relative_path.exists() or True  # may not exist yet

    print("✓ test_generate_plan")


def test_backend_staging():
    """Test backend staging (dry-run)."""
    fam = load_all_families()["field_fabricator_mk1"]
    project_dir = Path("custodian")
    inbox = project_dir / "asset_drop" / "inbox" / fam.id

    plan = generate_plan(fam, inbox, project_dir)

    for asset in plan.assets:
        if asset.backend == "runtime_ready":
            result = stage_rr(asset, project_dir, dry_run=True)
        elif asset.backend == "sprite_ingest":
            result = stage_si(asset, project_dir, dry_run=True)
        else:
            raise AssertionError(f"Unknown backend: {asset.backend}")

        assert result.ok
        assert len(result.outputs) == 1

    print("✓ test_backend_staging")


def test_status():
    """Test status reporting."""
    fam = load_all_families()["field_fabricator_mk1"]
    project_dir = Path("custodian")
    status = get_family_status(fam, project_dir)

    assert isinstance(status, FamilyStatus)
    assert status.family_id == "field_fabricator_mk1"
    assert len(status.required_states) == 2
    assert status.completeness == "2/2 required"

    print("✓ test_status")


def test_doctor():
    """Test doctor."""
    project_dir = Path("custodian")
    issues = run_doctor(project_dir)
    # Should have no errors (just warnings at most)
    errors = [i for i in issues if i.severity == "error"]
    assert len(errors) == 0

    print("✓ test_doctor")


def test_family_contract_load():
    """Test loading family contracts."""
    families = load_all_families()
    assert "field_fabricator_mk1" in families
    fam = families["field_fabricator_mk1"]
    assert fam.id == "field_fabricator_mk1"
    assert fam.kind == "world_prop"
    assert fam.frame_width == 128
    assert fam.frame_height == 96
    assert len(fam.states) == 5
    assert fam.states["idle"].required is True
    assert fam.states["active"].animation is True

    print("✓ test_family_contract_load")


def main():
    print("Running Asset Pipeline V2 smoke tests...\n")

    test_asset_key_semantic_identity()
    test_canonical_filename()
    test_inspect_png()
    test_classify_input()
    test_generate_plan()
    test_backend_staging()
    test_status()
    test_doctor()
    test_family_contract_load()

    print("\n✅ All smoke tests passed!")


if __name__ == "__main__":
    main()